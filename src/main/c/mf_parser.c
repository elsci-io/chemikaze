#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "periodic_table.h"
#include "mf_parser.h"

#include <string.h>

#include "AtomCounts.h"
#include "error.h"

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
		++(*i);
	}
	if ((resultElements[resultPos] = ptable_getElementBySymbol(symbol, error)) == INVALID_CHEM_ELEMENT)
		return;
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
			char *msg = malloc(21);
			strcpy(msg, "Unexpected symbol ");
			msg[19] = *i;
			msg[20] = '\0';
			*error = ChemikazeError_new(PARSE, msg);
			return;
		}
	}
}
/**
 * @param lo the position inside mf where we start applying {@code groupCoeff} and go right from there
 */
void scaleForward(const char *mf, const char *mfEnd, const char *lo,
				  int currStackDepth, unsigned *resultCoeff, unsigned groupCoeff) {
	if (groupCoeff == 1)
		return;// usually the case, as people rarely put coefficients in front of MF
	for (int depth = currStackDepth; lo < mfEnd && depth >= currStackDepth; lo++) {
		if     (*lo == '(') depth++;
		else if(*lo == ')') depth--;
		else if(*lo == '.' && depth == currStackDepth)
			break;
		resultCoeff[lo - mf] *= groupCoeff;
	}
}
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
		return ChemikazeError_newParsing("the opening and closing parentheses don't match.", mf, mfEnd - mf);
	return nullptr;
}

AtomCounts* combineIntoAtomCounts(const ChemElement *elements, const unsigned *coeffs, size_t len, AtomCounts *result) {
	for (size_t i = 0; i < len; i++)
		if (coeffs[i] > 0)
			result->counts[elements[i]] += coeffs[i];
	return result;
}

AtomCounts* parseMf(const char *mf, ChemikazeError **error) {
	if (mf == nullptr) {
		*error = ChemikazeError_new(NULL_POINTER, Chemikaze_toString("MF is null"));
		return nullptr;
	}
	while (*mf == ' ')
		mf++;// trim left
	const char *mfEnd = mf + strlen(mf) - 1;
	while (*mfEnd == ' ')
		mfEnd--;// trim right
	return parseMfChunk(mf, mfEnd + 1/*exclusive*/, error);
}
AtomCounts* parseMfChunk(const char *mf, const char *mfEnd, ChemikazeError **error) {
	AtomCounts *result = nullptr;
	if (mf >= mfEnd) {
		*error = ChemikazeError_new(PARSE, Chemikaze_toString("Empty Molecular Formula"));
		goto free;
	}
	size_t mfLen = mfEnd - mf;
	// unsigned coeff[mfLen] = {};
	// ChemElement elements[mfLen] = {};
	void *tmpMem = malloc(mfLen * (sizeof(int) + sizeof(ChemElement)));

	if (tmpMem == NULL) {
		*error = ChemikazeError_new(OOM, nullptr);
		goto free;
	}
	unsigned *coeff = tmpMem;
	ChemElement *elements = tmpMem + mfLen * sizeof(int);

	readSymbolsAndCoeffs(mf, mfEnd, elements, coeff, error);
	if (*error)
		goto free;
	if ((*error = findAndApplyGroupCoeffs(mf, mfEnd, coeff)))
		goto free;
	if ((result = AtomCounts_new()) == nullptr) {
		*error = ChemikazeError_new(OOM, nullptr);
		goto free;
	}
	combineIntoAtomCounts(elements, coeff, mfLen, result);
free:
	// free(tmpMem);
	return result;
}

AtomCounts* parseMfOrPanic(const char *mf) {
	ChemikazeError *error = nullptr;
	AtomCounts *atoms = parseMf(mf, &error);
	if (error) {
		fputs(error->msg, stderr);
		ChemikazeError_free(error);
		exit(1);
	}
	return atoms;
}