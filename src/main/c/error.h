//
// Created by Stanislav Bashkyrtsev on 10/20/25.
//

#ifndef ELSCI_CHEMIKAZE_ERROR_H
#define ELSCI_CHEMIKAZE_ERROR_H
#include <stddef.h>

#include "periodic_table.h"

typedef enum ChemikazeErrorCode {
	PARSE,
	OOM
} ChemikazeErrorCode;

typedef struct ChemikazeError {
	ChemikazeErrorCode code;
	char* msg;
} ChemikazeError;

/**
 * @param code
 * @param msg is owned by the error itself now, so the function owning the error must call the respective destructor
 * @return
 */
ChemikazeError* ChemikazeError_new(ChemikazeErrorCode code, char *msg);
ChemikazeError* ChemikazeError_newParsing(const char *staticMsg, const Ascii *mf, size_t mfLen);
void ChemikazeError_free(ChemikazeError *e);
#endif //ELSCI_CHEMIKAZE_ERROR_H