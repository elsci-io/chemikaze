//
// Created by Stanislav Bashkyrtsev on 10/18/25.
//

#include "AtomCounts.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "periodic_table.h"

AtomCounts *AtomCounts_new() {
	AtomCounts *result = malloc(sizeof(AtomCounts));
	if (result == NULL)
		return nullptr;
	if((result->counts = calloc(EARTH_ELEMENT_CNT, sizeof(unsigned))) == NULL)
		return nullptr;
	return result;;
}

char* AtomCounts_toString(AtomCounts *obj) {// TODO: FINISH
	int bufsize = 8;
	char *result = calloc(bufsize, sizeof(char));
	// int strlen = 0;
	int i = 0;
	for (ChemElement e = 0; e < EARTH_ELEMENT_CNT; e++) {
		unsigned coeff = obj->counts[e];
		if (coeff > 0) {
			const Ascii *symbol = EARTH_SYMBOLS[e];
			do {
				if (i == bufsize-1) {
					bufsize *= 2;
					result = realloc(result, bufsize);// todo: handle null
				}
				result[i++] = *symbol;
				symbol++;
			} while (*symbol != '\0');
			if (coeff > 1) {
				int order = 1;
				int power = 1;//TODO: fix
				int coefTmp = coeff;
				while (coefTmp > 0) {
					coeff /= 10;
					order++;
					power *= 10;
				}

				if (i+order+1 >= bufsize-1) {
					bufsize = i+order+1 - bufsize;
					result = realloc(result, bufsize);// todo: handle null
				}
				for (; power != 0; power /= 10)
					result[i++] = '0' + (char)(coeff / power);
			}
		}
	}
	result[i] = '\0';
	return result;
}