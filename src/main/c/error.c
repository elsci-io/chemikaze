#include "error.h"

#include <stdlib.h>

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