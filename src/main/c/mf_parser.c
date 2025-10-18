#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "periodic_table.h"
#include "mf_parser.h"

#include <string.h>

#include "AtomCounts.h"

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

int consumeCoeff(const Ascii **i, const Ascii *mfEnd) {
	if (*i >= mfEnd || !isDigit(**i))
		return 1;
	int result = 0;
	for (; *i < mfEnd && isDigit(**i); (*i)++)
		result = result * 10 + (**i - '0');
	return result;
}

void consumeSymbolAndCoeff(const Ascii *mfStart, const Ascii **i, const Ascii *mfEnd/*exclusive*/,
                           ChemElement *resultElements, unsigned *resultCoeff) {
	size_t resultPos = *i - mfStart;
	Ascii symbol[2] = {**i, 0};
	if (++(*i) < mfEnd && isSmallLetter(**i)) {
		symbol[1] = **i;
		++(*i);
	}
	resultElements[resultPos] = get_element_by_symbol(symbol);//todo: handle error
	resultCoeff[resultPos] = consumeCoeff(i, mfEnd);
}

void readSymbolsAndCoeffs(const Ascii *mfStart, const Ascii *mfEnd/*exclusive*/, ChemElement *elements, unsigned *coeff) {
	for (const Ascii *i = mfStart; i < mfEnd;) {
		if (isBigLetter(*i))
			consumeSymbolAndCoeff(mfStart, &i, mfEnd, elements, coeff);
		else if (1) // TODO
			i++;
		else {
			fprintf(stderr, "Unexpected symbol");// TODO: log the actual symbol
		}
	}
}

AtomCounts* combineIntoAtomCounts(const ChemElement *elements, const unsigned *coeffs, size_t len, AtomCounts *result) {
	for (size_t i = 0; i < len; i++)
		if (coeffs[i] > 0)
			result->counts[elements[i]] += coeffs[i];
	return result;
}

AtomCounts* parseMf(const Ascii *mf) {
	return parseMfChunk(mf, mf + strlen(mf));
}
AtomCounts* parseMfChunk(const Ascii *mfStart, const Ascii *mfEnd) {
	AtomCounts *result = nullptr;
	size_t mfLen = mfEnd - mfStart;
	if (mfLen <= 0) {
		fprintf(stderr, "Empty Molecular Formula");
		return nullptr;
	}
	unsigned *coeff = calloc(mfLen, sizeof(int));
	ChemElement *elements = calloc(mfLen, sizeof(ChemElement));
	if (coeff == NULL || elements == NULL) {
		fprintf(stderr, "Couldn't allocate memory");// TODO: return error?
		goto free;
	}

	readSymbolsAndCoeffs(mfStart, mfEnd, elements, coeff);
	if ((result = AtomCounts_new()) == nullptr) {
		fprintf(stderr, "Couldn't allocate memory");// TODO: return error?
		goto free;
	}
	combineIntoAtomCounts(elements, coeff, mfLen, result);
free:
	free(coeff);
	free(elements);
	return result;
}
