#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "error.h"
#include "mf_parser.h"
#include "periodic_table.h"
#include "../../../../../../../../Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/stdlib.h"
#include "../../test/c/asserts.h"
// This implementation uses a handwritten Assembly MfParser. It's written only for Mac ARM, and there's no CMake config
// for it.
//
// To compile:
//  cc -c mf_parser.armv8.asm mf_parser_asm.c && cc -o mf_parser_asm mf_parser.armv8.o mf_parser_asm.o && ./mf_parser_asm
//
// Or if the newer version of Clang is installed with brew:
//  /opt/homebrew/opt/llvm/bin/clang -std=c23 -Wno-nullability-completeness -isysroot $(xcrun --sdk macosx --show-sdk-path) -c mf_parser.armv8.asm mf_parser_asm.c && cc -o mf_parser_asm mf_parser.armv8.o mf_parser_asm.o && ./mf_parser_asm

int isNumeric(unsigned char c);
int isBigLetter(unsigned char c);
struct MfParser {
	ChemElement *elements;
	unsigned *coeffs;
	size_t len;
};

// typedef unsigned char ChemElement;
// typedef struct MfParser {
// 	ChemElement *elements;
// 	unsigned *coeffs;
// 	size_t len;
// } MfParser;
// extern MfParser* MfParser_new();
// extern void MfParser_destroy(MfParser*);

int log_if_error(ChemikazeError* error, AtomCounts* counts) {
	if (counts == NULL) {
		printf("Error code: %d\n", error->code);
		if (error->msg != NULL)
			printf("Error msg: %s\n", error->msg);
		return 1;
	}
	return 0;
}
extern ChemElement ptable_getElementBySymbol_short(int symbol);
extern int MfParser_consumeCoeff(const char **i, const char *mfEnd);
extern int MfParser_consumeSymbolAndCoeff(
	const char *mf, const char **i, const char *mfEnd/*exclusive*/,
	ChemElement *resultElements, unsigned *resultCoeff);
extern void MfParser_readSymbolsAndCoeffs(
	const char *mf, const char *mfEnd/*exclusive*/, ChemElement *elements, unsigned *coeff,
	ChemikazeError **error);
extern void MfParser_scaleForward(const char *mf, const char *mfEnd, const char *lo,
								  int currStackDepth, unsigned *resultCoeff, unsigned groupCoeff);
void MfParser_scaleBackward(const char *mf, const char *hi/*inclusive*/,
						    int currStackDepth, unsigned *resultCoeff, int groupCoeff);
void MfParser_findAndApplyGroupCoeffs(const char *mf, const char *mfEnd/*exclusive*/, unsigned *resultCoeffs);
AtomCounts* MfParser_combineIntoAtomCounts(const ChemElement *elements, const unsigned *coeffs, size_t len, AtomCounts *result);
ChemikazeError* MfParser_ensureLengths(MfParser *parser, size_t mfLen);
char* AtomCounts_toString(AtomCounts*);

void printUnsignedChars(const unsigned char chars[], size_t len) {
	for (size_t i = 0; i < len; i++)
		printf("%c ", chars[i]);
}
void printUnsigned(const unsigned resultCoeff[], size_t len) {
	for (unsigned i = 0; i < len; i++)
		printf("%d ", resultCoeff[i]);
}
void assertEqualSize(size_t expected, size_t actual) {
	if (expected != actual) {
		printf(" \033[31m[ERROR] Values are not equal: %lu (expected) != %lu (actual)\033[0m\n", expected, actual);
		exit(109);
	}
}
void assertEqualU8Array(const unsigned char expected[], const unsigned char actual[], size_t len) {
	for (size_t i = 0; i < len; i++) {
		if (expected[i] != actual[i]) {
			printf(" \033[31m[ERROR] Assertion failed for unsigned char[]: \n Expected: ");
			printUnsignedChars(expected, len);
			printf("\n Actual:   ");
			printUnsignedChars(actual, len);
			printf("\033[0m\n");
			exit(109);
		}
	}
}
void assertEqualU32Array(const unsigned expected[], const unsigned actual[], size_t len) {
	for (size_t i = 0; i < len; i++) {
		if (expected[i] != actual[i]) {
			printf(" \033[31m[ERROR] Assertion failed for unsigned[]: \n Expected: ");
			printUnsigned(expected, len);
			printf("\n Actual:   ");
			printUnsigned(actual, len);
			printf("\033[0m\n");
			exit(109);
		}
	}
}
void assertEqualsString(const char* expected, const char* actual) {
	if (strcmp(expected, actual) != 0) {
		printf("\033[31mTest failed:");
		char errorMsg[strlen(expected) + strlen(actual) + 50];
		sprintf(errorMsg, "Strings are not equal:\nExpected (%lu): %s\n  Actual (%lu): %s\n",
				strlen(expected), expected, strlen(actual), actual);
		puts(errorMsg);
		printf("\033[0m");
		exit(109);
	}
}

void printResultCoeffs(size_t len, unsigned resultCoeff[]) {
	printf("  Result coeffs:   ");
	for (unsigned i = 0; i < len; i++)
		printf("%d ", resultCoeff[i]);
	printf("\n");
}
void printResultElements(size_t len, ChemElement resultElements[]) {
	printf("  Result elements: ");
	for (unsigned i = 0; i < len; i++)
		printf("%d ", resultElements[i]);
	printf("\n");
}
void testMfParser_ensureLengths() {
	MfParser* p = MfParser_new();
	assertEqualSize(20, p->len);
	p->coeffs[0] = 1;
	p->coeffs[19] = 2;
	p->elements[0] = 3;
	p->elements[19] = 4;

	MfParser_ensureLengths(p, 10);
	assertEqualSize(20, p->len);
	assertEqualU32Array((unsigned[20]){[0]=0, [19]=2}, p->coeffs, 20);
	assertEqualU8Array((unsigned char[20]){[0]=0, [19]=4}, p->elements, 20);

	MfParser_ensureLengths(p, 20);
	assertEqualSize(20, p->len);
	assertEqualU32Array((unsigned[20]){0}, p->coeffs, 20);
	assertEqualU8Array((unsigned char[20]){0}, p->elements, 20);

	MfParser_ensureLengths(p, 21);
	assertEqualSize(21, p->len);
	assertEqualU32Array((unsigned[21]){0}, p->coeffs, 21);
	assertEqualU8Array((unsigned char[21]){0}, p->elements, 21);
}
void testAtomCounts_toString() {
	printf("Testing atomCounts_toString()\n");
	AtomCounts *atoms = AtomCounts_new();
	atoms->counts[ELEMENT_H] = 2;
	atoms->counts[ELEMENT_O] = 1;
	atoms->counts[ELEMENT_O] = 1;
	atoms->counts[ELEMENT_Cl] = 135;
	assertEqualsString("H2OCl135", AtomCounts_toString(atoms));
	AtomCounts_free(atoms);
}
void testCombineIntoAtomCounts() {
	printf("Testing combineIntoAtomCounts()\n");
	ChemElement elements[6] = {0, 1, 2, 3, 0, 1};
	unsigned      coeffs[6] = {2, 0, 1, 2, 1, 0};
	AtomCounts *counts = AtomCounts_new();
	MfParser_combineIntoAtomCounts(elements, coeffs, 6, counts);
	assertEqualU32Array((unsigned[EARTH_ELEMENT_CNT]){3, 0, 1, 2}, counts->counts, EARTH_ELEMENT_CNT);
	AtomCounts_free(counts);
}
void testParseSanitized() {
	printf("Testing parseSanitized():\n");
	const char *mf = "4H2O.2(HCl4)4";
	size_t len = strlen(mf);
	const char *mfEnd = mf + len;

	ChemikazeError *error = NULL;
	MfParser *parser = MfParser_new();
	AtomCounts* counts = MfParser_parseSanitized(parser, mf, mfEnd, &error);
	printResultCoeffs(len, parser->coeffs);
	printResultElements(len, parser->elements);
	assertEqualU32Array((unsigned[EARTH_ELEMENT_CNT]){[ELEMENT_H]=16, [ELEMENT_O]=4, [ELEMENT_Cl]=32},
		counts->counts, EARTH_ELEMENT_CNT);
}

void testFindAndApplyGroupCoeffs() {
	puts("Testing findAndApplyGroupCoeffs():\n");
	const char *mf = "4H2O.2(HCl4)4";
	unsigned resultCoeff[13] = {0, 2, 0, 1, 0, 0, 0, 1, 4, 0, 0, 0, 0};
	size_t len = strlen(mf);
	const char *mfEnd = mf + len;

	MfParser_findAndApplyGroupCoeffs(mf, mfEnd, resultCoeff);
	assertEqualU32Array((unsigned[13]){0, 8, 0, 4, 0, 0, 0, 8, 32}, resultCoeff, 13);
}

void testScaleBackward() {
	printf("Testing scaleBackward():\n");
	const char *mf = "(HCl4)4";
	unsigned resultCoeff[10] = {0, 1, 4, 0, 0, 0};
	size_t len = strlen(mf);
	const char *mfEnd = mf + len;

	MfParser_scaleBackward(mf, mfEnd-3, 0, resultCoeff, 1); // 0 1 4 0 0 0
	assertEqualU32Array((unsigned[10]){0, 1, 4}, resultCoeff, 10);

	MfParser_scaleBackward(mf, mfEnd-4, 0, resultCoeff, 4); // 0 4 16 0 0 0
	assertEqualU32Array((unsigned[10]){0, 4, 16}, resultCoeff, 10);
}

void testScaleForward() {
	const char *mf = "(HCl4)4O";
	size_t len = strlen(mf);
	const char *mfEnd = mf + len;
	unsigned resultCoeff[10];
	for (unsigned i = 0; i < len; i++)
		resultCoeff[i] = 1;

	MfParser_scaleForward(mf, mfEnd, mf, 0, resultCoeff, 1);
	printResultCoeffs(len, resultCoeff);

	MfParser_scaleForward(mf, mfEnd, mf, 0, resultCoeff, 5);
	printResultCoeffs(len, resultCoeff);

	MfParser_scaleForward(mf, mfEnd, mf+1, 0, resultCoeff, 5);
	printResultCoeffs(len, resultCoeff);

	MfParser_scaleForward(mf, mfEnd, mf, 1, resultCoeff, 5);
	printResultCoeffs(len, resultCoeff);
}
void testConsumeCoeff() {
	const char *num = "H1O12Cl";
	const char *start = num;
	printf("Consume: %d\n", MfParser_consumeCoeff(&start, num));
	printf("i: %ld\n", (start-num));
	start = num;
	printf("Consume: %d\n", MfParser_consumeCoeff(&start, num+1));
	printf("i: %ld\n", (start-num));
	start = num+1;
	printf("Consume: %d\n", MfParser_consumeCoeff(&start, num+1));
	printf("i: %ld\n", (start-num));
	start = num+1;
	printf("Consume: %d\n", MfParser_consumeCoeff(&start, num+3));
	printf("i: %ld\n", (start-num));
	start = num+3;
	printf("Consume: %d\n", MfParser_consumeCoeff(&start, num+5));
	printf("i: %ld\n", (start-num));
}
void testConsumeSymbolAndCoeff() {
	const char *mf = "H1O12Cl991";
	unsigned len = strlen(mf);
	const char *i = mf+2;
	const char *mfEnd = mf+strlen(mf);
	ChemElement resultElements[len] = {};
	unsigned resultCoeff[len] = {};
	MfParser_consumeSymbolAndCoeff(mf, &i, mfEnd, resultElements, resultCoeff);
	printf("Elements: ");
	for (unsigned j = 0; j < len; j++)
		printf("%d, ", resultElements[j]);
	printf("\nCoeffs:   ");
	for (unsigned j = 0; j < len; j++)
		printf("%d, ", resultCoeff[j]);
	printf("\n");
}
void testReadSymbolsAndCoeffs() {
	char *mf = "10[H2O3Cl]+";
	unsigned len = strlen(mf);
	ChemElement resultElements[len] = {};
	unsigned resultCoeff[len] = {};
	ChemikazeError *error = NULL;
	MfParser_readSymbolsAndCoeffs(mf, mf+len, resultElements, resultCoeff, &error);
	printf("Elements: ");
	for (unsigned j = 0; j < len; j++)
		printf("%d, ", resultElements[j]);
	printf("\nCoeffs:   ");
	for (unsigned j = 0; j < len; j++)
		printf("%d, ", resultCoeff[j]);
	printf("\n");
}

int main() {
	// testConsumeCoeff();
	// testConsumeSymbolAndCoeff();
	// testReadSymbolsAndCoeffs();
	// testScaleForward();
	testScaleBackward();
	// testFindAndApplyGroupCoeffs();
	// testCombineIntoAtomCounts();
	// testAtomCounts_toString();
	testParseSanitized();
	testMfParser_ensureLengths();
	return 0;
}
