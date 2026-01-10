#include "error.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

constexpr char ChemikazeErrorCode_NAMES[ChemikazeErrorCode_SIZE][14] = {
	[ChemikazeErrorCode_UNKNOWN] = "UNKNOWN_ERROR",
	[ChemikazeErrorCode_PARSE] = "PARSE_ERROR",
	[ChemikazeErrorCode_OOM] = "OOM",
	[ChemikazeErrorCode_NPE] = "NPE"
};
const inline char* ChemikazeErrorCode_getLogMsg(ChemikazeErrorCode code) {
	int errorCode = code >= ChemikazeErrorCode_SIZE ? ChemikazeErrorCode_UNKNOWN : code;
	return ChemikazeErrorCode_NAMES[errorCode];
}

char* Chemikaze_toString(const char *str) {
	size_t len = strlen(str);
	char *buf = malloc(len+1);
	strcpy(buf, str);
	return buf;
}

void ChemikazeError_log(const ChemikazeError *e) {
	fputs("[ERROR] ", stderr);
	fputs(ChemikazeErrorCode_getLogMsg(e->code), stderr);
	if (e->msg != NULL && strlen(e->msg) > 0)
		fprintf(stderr, ": %s", e->msg);
	fprintf(stderr, "\n");
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
	return ChemikazeError_new(ChemikazeErrorCode_PARSE, msg);
}
// TODO: it doesn't make sense to allocate more memory if we got OOM, need to create a constant for OOM error
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