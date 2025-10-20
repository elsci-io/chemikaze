#include "error.h"

#include <stdlib.h>
#include <string.h>

#include "periodic_table.h"

ChemikazeError* ChemikazeError_newParsing(const char *staticMsg, const Ascii *mf, size_t mfLen) {
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