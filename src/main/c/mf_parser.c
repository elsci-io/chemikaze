#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "periodic_table.h"
#include "mf_parser.h"

#include <string.h>

#include "AtomCounts.h"
#include "error.h"

struct MfParser {
	ChemElement *elements;
	unsigned *coeffs;
	size_t len;
};

void MfParser_destroy(MfParser *parser) {
	if (parser) {
		if (parser->coeffs)
			free(parser->coeffs);
		if (parser->elements)
			free(parser->elements);
		free(parser);
	}
}

MfParser* MfParser_new() {
	MfParser *parser = calloc(sizeof(MfParser), 1);
	if (!parser)
		return nullptr;
	parser->len = 20;
	parser->coeffs = calloc(sizeof(*parser->coeffs), parser->len);
	parser->elements = calloc(sizeof(*parser->elements), parser->len);
	if (parser->coeffs == NULL || parser->elements == NULL) {
		MfParser_destroy(parser);
		return nullptr;
	}
	return parser;
}

ChemikazeError* reallocOrErr(void **oldPointer, size_t newLen) {
	void *newPointer = realloc(*oldPointer, newLen);
	if (newPointer == NULL) {
		// free(*oldPointer);
		return ChemikazeError_new(OOM, nullptr);
	}
	*oldPointer = newPointer;
	return nullptr;
}
ChemikazeError* MfParser_ensureLengths(MfParser *parser, size_t mfLen) {
	if (mfLen > parser->len) {
		ChemikazeError *error;
		if ((error = reallocOrErr((void **)&parser->coeffs, sizeof(*parser->coeffs) * mfLen)) != NULL)
			return error;
		if ((error = reallocOrErr((void **)&parser->elements, sizeof(*parser->elements) * mfLen)) != NULL)
			return error;
		parser->len = mfLen;
	}
	memset(parser->coeffs, 0, sizeof(*parser->coeffs)*mfLen);
	memset(parser->elements, 0, sizeof(*parser->elements)*mfLen);
	return nullptr;
}

constexpr unsigned MF_PUNCTUATION_LEN = 7;
constexpr char MF_PUNCTUATION[MF_PUNCTUATION_LEN] = {'(', ')', '+', '-', '.', '[', ']'};

bool isBigLetter(char c) {
	return 'A' <= c && c <= 'Z';
}
bool isSmallLetter(char c) {
	return 'a' <= c && c <= 'z';
}
bool isDigit(char c) {
	return '0' <= c && c <= '9';
}
bool isAlphanumeric(char c) {
	return isBigLetter(c) || isSmallLetter(c) || isDigit(c);
}
bool isPunctuation(char c) {
	for (unsigned i = 0; i < MF_PUNCTUATION_LEN; i++)
		if (c == MF_PUNCTUATION[i])
			return true;
	return false;
}

int consumeCoeff(const char **i, const char *mfEnd) {
	if (*i >= mfEnd || !isDigit(**i))
		return 1;
	int result = 0;
	for (; *i < mfEnd && isDigit(**i); (*i)++)
		result = result * 10 + (**i - '0');
	return result;
}

void consumeSymbolAndCoeff(const char *mf, const char **i, const char *mfEnd/*exclusive*/,
						   ChemElement *resultElements, unsigned *resultCoeff, ChemikazeError **error) {
	size_t resultPos = *i - mf;
	char symbol[2] = {**i, 0};
	if (++(*i) < mfEnd && isSmallLetter(**i)) {
		symbol[1] = **i;
		++*i;
	}
	if ((resultElements[resultPos] = ptable_getElementBySymbol(symbol)) == INVALID_CHEM_ELEMENT) {
		char *msg = malloc(30);
		sprintf(msg, "Unknown chemical symbol: %c%c", symbol[0], symbol[1]);
		*error = ChemikazeError_newParsing(msg, mf, mfEnd-mf);
		return;
	}
	resultCoeff[resultPos] = consumeCoeff(i, mfEnd);
}

void readSymbolsAndCoeffs(const char *mf, const char *mfEnd/*exclusive*/, ChemElement *elements, unsigned *coeff,
						  ChemikazeError **error) {
	for (const char *i = mf; i < mfEnd;) {
		if (isBigLetter(*i)) {
			consumeSymbolAndCoeff(mf, &i, mfEnd, elements, coeff, error);
			if (*error)
				return;
		} else if (isPunctuation(*i) || isDigit(*i))
			i++;
		else {
			char *msg = malloc(22);
			sprintf(msg, "Unexpected symbol: %c", *i);
			*error = ChemikazeError_newParsing(msg, mf, mfEnd-mf);
			return;
		}
	}
}
/**
 * Scales whatever follows a number in situations like {@code 2H2O}, {@code Cl.2H}.
 *
 * @param mf the start of the MF string
 * @param mfEnd the end of the MF string, exclusive
 * @param lo the position inside mf where we start applying {@code groupCoeff} and go right from there
 * @param currStackDepth how deep in () we are
 * @param resultCoeff which coefficients to scale (only a specific region of MF will be scaled)
 * @param groupCoeff the coefficient to scale the whole group of symbols
 */
void scaleForward(const char *mf, const char *mfEnd, const char *lo,
				  int currStackDepth, unsigned *resultCoeff, unsigned groupCoeff) {
	if (groupCoeff == 1)
		return;// usually the case, as people rarely put coefficients in front of MF
	// Might be faster to increment resultCoeff within the loop. The initial val:
	// resultCoeff = resultCoeff + (lo - mf);
	for (int depth = currStackDepth; lo < mfEnd && depth >= currStackDepth; lo++) {
		if     (*lo == '(') depth++;
		else if(*lo == ')') depth--;
		else if(*lo == '.' && depth == currStackDepth)
			break;
		resultCoeff[lo - mf] *= groupCoeff;// will multiply parentheses too, but those have 0 coeffs
	}
}

/**
 * Scales whatever is in the parentheses like {@code (H2O)2}.
 *
 * @param mf the start of the MF string
 * @param hi current position (inclusive) of the closing parenthesis - to go back and find where it starts
 * @param currStackDepth how deep in () we are
 * @param resultCoeff which coefficients to scale (only a specific region of MF will be scaled)
 * @param groupCoeff the coefficient to scale the whole group of symbols
 */
void scaleBackward(const char *mf, const char *hi/*inclusive*/, int currStackDepth, unsigned *resultCoeff, int groupCoeff) {
	int depth = currStackDepth;
	for (; hi >= mf && depth <= currStackDepth; hi--) {
		if     (*hi == '(') depth++;
		else if(*hi == ')') depth--;
		resultCoeff[hi - mf] *= groupCoeff;
	}
}
ChemikazeError* findAndApplyGroupCoeffs(const char *mf, const char *mfEnd/*exclusive*/, unsigned *resultCoeffs) {
	int currStackDepth = 0;
	const char *i = mf;
	while (i < mfEnd) {
		scaleForward(mf, mfEnd, i, currStackDepth, resultCoeffs, consumeCoeff(&i, mfEnd));
		if (i == mfEnd)
			break;
		while (isAlphanumeric(*i)) // skip all letters, numbers, dots
			if (i++ >= mfEnd)
				goto out;
		if (*i == '(')
			currStackDepth++;
		else if (*i == ')') {
			const char *chunkEnd = i - 1;
			i++;
			scaleBackward(mf, chunkEnd, currStackDepth--, resultCoeffs, consumeCoeff(&i, mfEnd));
			continue;
		}
		i++;// happens on these: (.[]+
	}
out:
	if (currStackDepth)
		return ChemikazeError_newParsing("The opening and closing parentheses don't match.", mf, mfEnd - mf);
	return nullptr;
}

AtomCounts* combineIntoAtomCounts(const ChemElement *elements, const unsigned *coeffs, size_t len, AtomCounts *result) {
	for (size_t i = 0; i < len; i++)
		if (coeffs[i] > 0)
			result->counts[elements[i]] += coeffs[i];
	return result;
}

AtomCounts* MfParser_parse(MfParser *parser, const char *mf, ChemikazeError **error) {
	if (mf == nullptr) {
		*error = ChemikazeError_new(NULL_POINTER, Chemikaze_toString("MF is null"));
		return nullptr;
	}
	while (*mf == ' ')
		mf++;// trim left
	const char *mfEnd = mf + strlen(mf) - 1;
	while (*mfEnd == ' ')
		mfEnd--;// trim right
	return MfParser_parseSanitized(parser, mf, mfEnd + 1/*exclusive*/, error);
}

AtomCounts* MfParser_parseSanitized(MfParser *parser, const char *mf, const char *mfEnd, ChemikazeError **error) {
	AtomCounts *result = nullptr;
	if (mf >= mfEnd) {
		*error = ChemikazeError_new(PARSE, Chemikaze_toString("Empty Molecular Formula"));
		return nullptr;
	}
	size_t mfLen = mfEnd - mf;
	if ((*error = MfParser_ensureLengths(parser, mfLen)) != nullptr)
		goto free;

	readSymbolsAndCoeffs(mf, mfEnd, parser->elements, parser->coeffs, error);
	if (*error)
		goto free;
	if ((*error = findAndApplyGroupCoeffs(mf, mfEnd, parser->coeffs)))
		goto free;
	if ((result = AtomCounts_new()) == nullptr) {
		*error = ChemikazeError_new(OOM, nullptr);
		goto free;
	}
	combineIntoAtomCounts(parser->elements, parser->coeffs, mfLen, result);
free: // Still playing between allocating tmp memory on heap vs arrays on stack. stack seems to be a little better.
	// free(tmpMem);
	return result;
}

AtomCounts* MfParser_parseOrPanic(MfParser *parser, const char *mf) {
	ChemikazeError *error = nullptr;
	AtomCounts *atoms = MfParser_parse(parser, mf, &error);
	if (error) {
		fputs(error->msg, stderr);
		ChemikazeError_destroy(error);
		exit(1);
	}
	return atoms;
}