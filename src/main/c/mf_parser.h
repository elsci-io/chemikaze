#ifndef ELSCI_CHEMIKAZE_MF_PARSER_H
#define ELSCI_CHEMIKAZE_MF_PARSER_H
#include "AtomCounts.h"
#include "error.h"

typedef struct MfParser MfParser;
MfParser* MfParser_new();
void MfParser_destroy(MfParser *parser);

AtomCounts* parseMfSanitized(MfParser *parser, const char *mf, const char *mfEnd, ChemikazeError **error);
AtomCounts* parseMf(MfParser *parser, const char *mf, ChemikazeError **error);
AtomCounts* parseMfOrPanic(MfParser *parser, const char *mf);
#endif //ELSCI_CHEMIKAZE_MF_PARSER_H
