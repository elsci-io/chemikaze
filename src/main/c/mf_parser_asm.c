#include <stdio.h>
#include <string.h>

#include "error.h"
#include "mf_parser.h"
#include "periodic_table.h"
// This implementation uses a hand written Assembly MfParser. It's written only for Mac ARM. To compile it:
//  cc -c mf_parser.armv8.asm mf_parser_asm.c && cc -o mf_parser_asm mf_parser.armv8.o mf_parser_asm.o && ./mf_parser_asm

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

int main() {
	// testConsumeCoeff();
	testConsumeSymbolAndCoeff();
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
