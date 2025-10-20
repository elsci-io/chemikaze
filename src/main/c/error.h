//
// Created by Stanislav Bashkyrtsev on 10/20/25.
//

#ifndef ELSCI_CHEMIKAZE_ERROR_H
#define ELSCI_CHEMIKAZE_ERROR_H

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
void ChemikazeError_free(ChemikazeError *e);
#endif //ELSCI_CHEMIKAZE_ERROR_H