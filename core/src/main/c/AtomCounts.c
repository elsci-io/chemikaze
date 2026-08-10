//
// Created by Stanislav Bashkyrtsev on 10/18/25.
//

#include "AtomCounts.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "periodic_table.h"

int numOfLetters(unsigned val);
int orderOf(unsigned val);

AtomCounts *AtomCounts_new() {
	size_t len = sizeof(AtomCounts) + sizeof(unsigned) * EARTH_ELEMENT_CNT;
	AtomCounts *result = malloc(len);
	if (result == NULL)
		return nullptr;
	memset(result, 0, len);
	result->counts = (void*) result + sizeof(AtomCounts);
	return result;
}
void AtomCounts_free(AtomCounts *a) {
	free(a);
}


char* AtomCounts_toString(AtomCounts *obj) {
	int len = 1;// start with 1 for the extra \0 at the end
	for (ChemElement e = 0; e < EARTH_ELEMENT_CNT; e++) {
		unsigned coeff = obj->counts[e];
		if (coeff <= 0)
			continue;
		for (const char *symbol = EARTH_SYMBOLS[e]; *symbol != '\0'; symbol++)
			len++;
		len += numOfLetters(coeff);
	}

	unsigned strPos = 0;
	char *result = malloc(len * sizeof(char));
	for (ChemElement e = 0; e < EARTH_ELEMENT_CNT; e++) {
		unsigned coeff = obj->counts[e];
		if (coeff <= 0)
			continue;
		for (const char *symbol = EARTH_SYMBOLS[e]; *symbol != '\0'; symbol++)
			result[strPos++] = *symbol;
		for (unsigned o = orderOf(coeff); o > 0; o /= 10) {// go one digit at a time from left to right
			result[strPos++] = '0' + coeff / o; // NOLINT(*-narrowing-conversions), coeff/o is always between 0 and 9
			coeff %= o;
		}
	}
	result[strPos] = '\0';
	return result;
}

int numOfLetters(unsigned val) {
	if (val <= 1)
		return 0;
	int result = 0;
	for (; val > 0; val /= 10)
		result++;
	return result;
}
int orderOf(unsigned val) {
	if (val <= 1)
		return 0;
	int result = 1;
	for (; val >= 10; val /= 10)
		result *= 10;
	return result;
}
