#ifndef ELSCI_CHEMIKAZE_MF_PARSER_H
#define ELSCI_CHEMIKAZE_MF_PARSER_H
#include "AtomCounts.h"
#include "error.h"

AtomCounts* parseMfChunk(const char *mf, const char *mfEnd, ChemikazeError **error);
AtomCounts* parseMf(const char *mf, ChemikazeError **error);
AtomCounts* parseMfOrPanic(const char *mf);
#endif //ELSCI_CHEMIKAZE_MF_PARSER_H
