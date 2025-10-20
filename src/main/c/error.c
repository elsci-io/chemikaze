#include "error.h"

#include <stdlib.h>
#include <string.h>

char* Chemikaze_toString(const char *str) {
	size_t len = strlen(str);
	char *buf = malloc(len+1);
	strcpy(buf, str);
	return buf;
}

ChemikazeError* ChemikazeError_newParsing(const char *staticMsg, const char *mf, size_t mfLen) {
	char *msg = malloc(50 + strlen(staticMsg) + mfLen);
	strcpy(msg, "Couldn't parse ");
	strncat(msg, mf, mfLen);
	strcat(msg, ". Details: ");
	strcat(msg, staticMsg);
	return ChemikazeError_new(PARSE, msg);
}
ChemikazeError* ChemikazeError_new(ChemikazeErrorCode code, char *msg) {
	ChemikazeError *e = calloc(sizeof(ChemikazeError), 1);
	e->code = code;
	e->msg = msg;
	return e;
}
void ChemikazeError_free(ChemikazeError *e) {
	free(e->msg);
	free(e);
}