#ifndef ELSCI_CHEMIKAZE_ERROR_H
#define ELSCI_CHEMIKAZE_ERROR_H
#include <stddef.h>

typedef enum : unsigned {
	/*Must not be used. If encountered - means we have a bug creating ChemikazeErrorCode.*/
	ChemikazeErrorCode_UNKNOWN,
	ChemikazeErrorCode_PARSE,
	ChemikazeErrorCode_OOM,
	ChemikazeErrorCode_NPE,
	/*Not an error - just a constant telling us how many elements there are in the enum, must always go last.*/
	ChemikazeErrorCode_SIZE
} ChemikazeErrorCode;

typedef struct {
	char* msg;
	ChemikazeErrorCode code;
} ChemikazeError;

/**
 * @param code
 * @param msg is owned by the error itself now, so the function owning the error must call the respective destructor
 * @return
 */
ChemikazeError* ChemikazeError_new(ChemikazeErrorCode code, char *msg);
ChemikazeError* ChemikazeError_newParsing(const char *staticMsg, const char *mf, size_t mfLen);
void ChemikazeError_destroy(ChemikazeError *e);
void ChemikazeError_log(const ChemikazeError *e);
void ChemikazeError_logAndDestroy(ChemikazeError *e);

char* Chemikaze_toString(const char *str);
#endif //ELSCI_CHEMIKAZE_ERROR_H