#include <stdio.h>
#include <stdlib.h>

// This implementation uses a hand written Assembly MfParser. It's written only for Mac ARM. To compile it:
//  cc -c mf_parser.armv8.asm mf_parser_asm.c && cc -o mf_parser_asm mf_parser.armv8.o mf_parser_asm.o && ./mf_parser_asm

int isNumeric(unsigned char c);
int isBigLetter(unsigned char c);

typedef unsigned char ChemElement;
typedef struct MfParser {
	ChemElement *elements;
	unsigned *coeffs;
	size_t len;
} MfParser;
extern MfParser* MfParser_new();
extern void MfParser_destroy(MfParser*);

int main() {
	printf("Is numeric=%d\n", isBigLetter('c'));
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
	return 0;
}
