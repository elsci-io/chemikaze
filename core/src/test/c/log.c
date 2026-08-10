#include <stdio.h>

#include "xterm.h"

void logSuccess(char* str) {
	fprintf(stderr, "%s[INFO] %s%s\n", GREEN, str, RESET);
}
void logError(char* str) {
	fprintf(stderr, "%s[ERROR] %s%s\n", RED, str, RESET);
}
void logNorm(char* str) {
	fprintf(stderr, "[INFO] %s\n", str);
}