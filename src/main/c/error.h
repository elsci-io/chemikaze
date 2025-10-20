#ifndef ELSCI_CHEMIKAZE_ERROR_H
#define ELSCI_CHEMIKAZE_ERROR_H
#include <stddef.h>

typedef enum {
	PARSE,
	OOM,
	NULL_POINTER,
} ChemikazeErrorCode;

typedef struct {
	ChemikazeErrorCode code;
	char* msg;
} ChemikazeError;

/**
 * @param code
 * @param msg is owned by the error itself now, so the function owning the error must call the respective destructor
 * @return
 */
ChemikazeError* ChemikazeError_new(ChemikazeErrorCode code, char *msg);
ChemikazeError* ChemikazeError_newParsing(const char *staticMsg, const char *mf, size_t mfLen);
void ChemikazeError_free(ChemikazeError *e);
char* Chemikaze_toString(const char *str);
#endif //ELSCI_CHEMIKAZE_ERROR_H