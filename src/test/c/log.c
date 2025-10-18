#include <stdio.h>

#include "xterm.h"

void logInfo(char* str) {
	printf("%s[INFO] %s%s\n", GREEN, str, RESET);
}
void logError(char* str) {
	printf("%s[ERROR] %s%s\n", RED, str, RESET);
}