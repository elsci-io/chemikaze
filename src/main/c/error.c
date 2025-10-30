#include "error.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* Chemikaze_toString(const char *str) {
	size_t len = strlen(str);
	char *buf = malloc(len+1);
	strcpy(buf, str);
	return buf;
}

void ChemikazeError_log(ChemikazeError *e) {
	if (e->code == OOM)
		fprintf(stderr, "OOM");
	else if (e->code == NULL_POINTER)
		fprintf(stderr, "NULL_POINTER");
	else if (e->code == PARSE)
		fprintf(stderr, "Parsing error: ");
	if (e->msg != NULL && strlen(e->msg) > 0)
		fprintf(stderr, "%s", e->msg);
}
void ChemikazeError_logAndDestroy(ChemikazeError *e) {
	ChemikazeError_log(e);
	ChemikazeError_destroy(e);
}

ChemikazeError* ChemikazeError_newParsing(const char *staticMsg, const char *mf, size_t mfLen) {
	char *msg = malloc(50 + strlen(staticMsg) + mfLen);
	strcpy(msg, "Couldn't parse ");
	strncat(msg, mf, mfLen);
	strcat(msg, ". ");
	strcat(msg, staticMsg);
	return ChemikazeError_new(PARSE, msg);
}
ChemikazeError* ChemikazeError_new(ChemikazeErrorCode code, char *msg) {
	ChemikazeError *e = calloc(sizeof(ChemikazeError), 1);
	e->code = code;
	e->msg = msg;
	return e;
}
void ChemikazeError_destroy(ChemikazeError *e) {
	free(e->msg);
	free(e);
}