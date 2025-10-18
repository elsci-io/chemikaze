#ifndef ELSCI_CHEMIKAZE_MF_PARSER_H
#define ELSCI_CHEMIKAZE_MF_PARSER_H
#include "AtomCounts.h"

AtomCounts* parseMfChunk(const Ascii *mfStart, const Ascii *mfEnd);
AtomCounts* parseMf(const Ascii *mf);

#endif //ELSCI_CHEMIKAZE_MF_PARSER_H
