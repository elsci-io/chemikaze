#include <stdio.h>
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

int main() {
	printf("Is numeric=%d\n", isBigLetter('c'));
	printf("ptable_getElementBySymbol=%u\n", ptable_getElementBySymbol_short(('l' << 8) + 'C'));
	MfParser *parser = MfParser_new();
	printf("sizeof(MfParser)=%lu\n", sizeof(MfParser));
	printf("parser->len=%lu\n", parser->len);
	for (size_t i = 0; i < parser->len; i++)
		printf("%d ", parser->elements[i]);
	printf("\n");
	for (size_t i = 0; i < parser->len; i++)
		printf("%d ", parser->coeffs[i]);
	printf("\n");
	printf("Destroying:\n");
	MfParser_destroy(parser);

#define MF_LEN 4
	char *mf = "H2O4";
	ChemikazeError *error = NULL;

	AtomCounts* counts = MfParser_parseSanitized(parser, mf, mf, &error);
	log_if_error(error, counts);

	counts = MfParser_parseSanitized(parser, mf, mf+MF_LEN+1, &error);
	if (!log_if_error(error, counts)) {
		printf("Symbols: %p\n", counts);
	}

	return 0;
}
