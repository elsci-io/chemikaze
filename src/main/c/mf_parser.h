#ifndef ELSCI_CHEMIKAZE_MF_PARSER_H
#define ELSCI_CHEMIKAZE_MF_PARSER_H
#include "AtomCounts.h"
#include "error.h"

AtomCounts* parseMfChunk(const Ascii *mf, const Ascii *mfEnd, ChemikazeError **error);
AtomCounts* parseMf(const Ascii *mf, ChemikazeError **error);
AtomCounts* parseMfOrPanic(const Ascii *mf);
#endif //ELSCI_CHEMIKAZE_MF_PARSER_H
