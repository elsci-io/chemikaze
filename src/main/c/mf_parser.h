#ifndef ELSCI_CHEMIKAZE_MF_PARSER_H
#define ELSCI_CHEMIKAZE_MF_PARSER_H
#include "AtomCounts.h"
#include "error.h"

typedef struct MfParser MfParser;
MfParser* MfParser_new();
void MfParser_destroy(MfParser *parser);

/**
 * Assumes you already trimmed the MF, and you're passing the right boundaries. If you didn't do this, then call
 * a non-sanitized method.
 *
 * @param parser
 * @param mf start of the molecular formula
 * @param mfEnd end of the formula, exclusive
 * @param error is nullptr if no error happened
 * @return if null, then check the error
 */
AtomCounts* parseMfSanitized(MfParser *parser, const char *mf, const char *mfEnd, ChemikazeError **error);
AtomCounts* parseMf(MfParser *parser, const char *mf, ChemikazeError **error);
AtomCounts* parseMfOrPanic(MfParser *parser, const char *mf);
#endif //ELSCI_CHEMIKAZE_MF_PARSER_H
