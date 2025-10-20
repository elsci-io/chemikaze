#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "periodic_table.h"
#include "mf_parser.h"

#include <string.h>

#include "AtomCounts.h"

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
bool isPunctuation(Ascii c) {
	for (unsigned i = 0; i < MF_PUNCTUATION_LEN; i++)
		if (c == MF_PUNCTUATION[i])
			return true;
	return false;
}

int consumeCoeff(const Ascii **i, const Ascii *mfEnd) {
	if (*i >= mfEnd || !isDigit(**i))
		return 1;
	int result = 0;
	for (; *i < mfEnd && isDigit(**i); (*i)++)
		result = result * 10 + (**i - '0');
	return result;
}

void consumeSymbolAndCoeff(const Ascii *mf, const Ascii **i, const Ascii *mfEnd/*exclusive*/,
                           ChemElement *resultElements, unsigned *resultCoeff) {
	size_t resultPos = *i - mf;
	Ascii symbol[2] = {**i, 0};
	if (++(*i) < mfEnd && isSmallLetter(**i)) {
		symbol[1] = **i;
		++(*i);
	}
	resultElements[resultPos] = ptable_getElementBySymbol(symbol);//todo: handle error
	resultCoeff[resultPos] = consumeCoeff(i, mfEnd);
}

void readSymbolsAndCoeffs(const Ascii *mf, const Ascii *mfEnd/*exclusive*/, ChemElement *elements, unsigned *coeff) {
	for (const Ascii *i = mf; i < mfEnd;) {
		if (isBigLetter(*i))
			consumeSymbolAndCoeff(mf, &i, mfEnd, elements, coeff);
		else if (isPunctuation(*i) || isDigit(*i))
			i++;
		else {
			fprintf(stderr, "Unexpected symbol");// TODO: log the actual symbol
			return;
		}
	}
}
/**
 * @param lo the position inside mf where we start applying {@code groupCoeff} and go right from there
 */
void scaleForward(const Ascii *mf, const Ascii *mfEnd, const Ascii *lo,
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
void scaleBackward(const Ascii *mf, const Ascii *hi/*inclusive*/, int currStackDepth, unsigned *resultCoeff, int groupCoeff) {
	int depth = currStackDepth;
	for (; hi >= mf && depth <= currStackDepth; hi--) {
		if     (*hi == '(') depth++;
		else if(*hi == ')') depth--;
		resultCoeff[hi - mf] *= groupCoeff;
	}
}
void findAndApplyGroupCoeffs(const Ascii *mf, const Ascii *mfEnd/*exclusive*/, unsigned *resultCoeffs) {
	int currStackDepth = 0;
	const Ascii *i = mf;
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
			const Ascii *chunkEnd = i - 1;
			i++;
			scaleBackward(mf, chunkEnd, currStackDepth, resultCoeffs, consumeCoeff(&i, mfEnd));
			continue;
		}
		i++;// happens on these: (.[]+
	}
	out:
	if (currStackDepth) {
		fprintf(stderr, "The opening and closing parentheses don't match");
		return;
	}

}

AtomCounts* combineIntoAtomCounts(const ChemElement *elements, const unsigned *coeffs, size_t len, AtomCounts *result) {
	for (size_t i = 0; i < len; i++)
		if (coeffs[i] > 0)
			result->counts[elements[i]] += coeffs[i];
	return result;
}

AtomCounts* parseMf(const Ascii *mf) {
	while (*mf == ' ')
		mf++;
	const Ascii *mfEnd = mf + strlen(mf) - 1;
	while (*mfEnd == ' ')
		mfEnd--;
	return parseMfChunk(mf, mfEnd + 1/*eclusive*/);
}
AtomCounts* parseMfChunk(const Ascii *mfStart, const Ascii *mfEnd) {
	AtomCounts *result = nullptr;
	size_t mfLen = mfEnd - mfStart;
	if (mfLen <= 0) {
		fprintf(stderr, "Empty Molecular Formula");
		return nullptr;
	}
	void *tmpMem = malloc(mfLen * (sizeof(int) + sizeof(ChemElement)));
	if (tmpMem == NULL) {
		fprintf(stderr, "Couldn't allocate memory");// TODO: return error?
		goto free;
	}
	unsigned *coeff = tmpMem;
	ChemElement *elements = tmpMem + mfLen * sizeof(int);

	readSymbolsAndCoeffs(mfStart, mfEnd, elements, coeff);
	findAndApplyGroupCoeffs(mfStart, mfEnd, coeff);
	if ((result = AtomCounts_new()) == nullptr) {
		fprintf(stderr, "Couldn't allocate memory");// TODO: return error?
		goto free;
	}
	combineIntoAtomCounts(elements, coeff, mfLen, result);
free:
	free(tmpMem);
	return result;
}
