#include <stdio.h>
#include <string.h>

#include "error.h"
#include "mf_parser.h"
#include "periodic_table.h"
// This implementation uses a handwritten Assembly MfParser. It's written only for Mac ARM, and there's no CMake config
// for it.
//
// To compile:
//  cc -c mf_parser.armv8.asm mf_parser_asm.c && cc -o mf_parser_asm mf_parser.armv8.o mf_parser_asm.o && ./mf_parser_asm
//
// Or if the newer version of Clang is installed with brew:
//  /opt/homebrew/opt/llvm/bin/clang -isysroot $(xcrun --sdk macosx --show-sdk-path) -c mf_parser.armv8.asm mf_parser_asm.c && cc -o mf_parser_asm mf_parser.armv8.o mf_parser_asm.o && ./mf_parser_asm

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

void testParseSanitized() {
	printf("Testing parseSanitized():\n");
	const char *mf = "4H2O.2(HCl4)4";
	size_t len = strlen(mf);
	const char *mfEnd = mf + len + 1;

	ChemikazeError *error = NULL;
	MfParser *parser = MfParser_new();
	AtomCounts* counts = MfParser_parseSanitized(parser, mf, mfEnd, &error);
	printResultCoeffs(len, parser->coeffs);
	printResultElements(len, parser->elements);

	// if (!log_if_error(error, counts))
	// 	printf("Symbols: %p\n", counts);

}

void testFindAndApplyGroupCoeffs() {
	printf("Testing findAndApplyGroupCoeffs():\n");
	const char *mf = "4H2O.2(HCl4)4";
	unsigned resultCoeff[13] = {0, 2, 0, 1, 0, 0, 0, 1, 4, 0, 0, 0, 0};
	size_t len = strlen(mf);
	const char *mfEnd = mf + len + 1;

	MfParser_findAndApplyGroupCoeffs(mf, mfEnd, resultCoeff);
	printResultCoeffs(len, resultCoeff); // 0 8 0 4 0 0 8 32 0 0 0 0
}

void testScaleBackward() {
	printf("Testing scaleBackward():\n");
	const char *mf = "(HCl4)4";
	unsigned resultCoeff[10] = {0, 1, 4, 0, 0, 0};
	size_t len = strlen(mf);
	const char *mfEnd = mf + len + 1;
	MfParser_scaleBackward(mf, mfEnd-3, 0, resultCoeff, 1); // 0 1 4 0 0 0
	printResultCoeffs(len, resultCoeff);

	MfParser_scaleBackward(mf, mfEnd-4, 0, resultCoeff, 4); // 0 4 16 0 0 0
	printResultCoeffs(len, resultCoeff);
}

void testScaleForward() {
	const char *mf = "(HCl4)4O";
	size_t len = strlen(mf);
	const char *mfEnd = mf + len+1;
	unsigned resultCoeff[10];
	for (unsigned i = 0; i < len; i++)
		resultCoeff[i] = 1;

	MfParser_scaleForward(mf, mfEnd+1, mf, 0, resultCoeff, 1);
	printResultCoeffs(len, resultCoeff);

	MfParser_scaleForward(mf, mfEnd+1, mf, 0, resultCoeff, 5);
	printResultCoeffs(len, resultCoeff);

	MfParser_scaleForward(mf, mfEnd+1, mf+1, 0, resultCoeff, 5);
	printResultCoeffs(len, resultCoeff);

	MfParser_scaleForward(mf, mfEnd+1, mf+1, 1, resultCoeff, 5);
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
	// testScaleBackward();
	// testFindAndApplyGroupCoeffs();
	testParseSanitized();
// 	printf("Is numeric=%d\n", isBigL	etter('c'));
// 	printf("ptable_getElementBySymbol=%u\n", ptable_getElementBySymbol_short(('l' << 8) + 'C'));
// 	MfParser *parser = MfParser_new();
// 	printf("sizeof(MfParser)=%lu\n", sizeof(MfParser));
// 	printf("parser->len=%lu\n", parser->len);
// 	for (size_t i = 0; i < parser->len; i++)
// 		printf("%d ", parser->elements[i]);
// 	printf("\n");
// 	for (size_t i = 0; i < parser->len; i++)
// 		printf("%d ", parser->coeffs[i]);
// 	printf("\n");
// 	printf("Destroying:\n");
// 	MfParser_destroy(parser);
//
// #define MF_LEN 4
// 	char *mf = "H2O4";
// 	ChemikazeError *error = NULL;
//
// 	AtomCounts* counts = MfParser_parseSanitized(parser, mf, mf, &error);
// 	log_if_error(error, counts);
//
// 	counts = MfParser_parseSanitized(parser, mf, mf+MF_LEN+1, &error);
// 	if (!log_if_error(error, counts)) {
// 		printf("Symbols: %p\n", counts);
// 	}

	return 0;
}
