#include <assert.h>
#include <stdbool.h>
#include "log.h"
#include "asserts.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

void assertEqualsDouble(double expected, double actual, double absError) {
	if (fabs(expected - actual) > absError) {
		logError("Test failed:");
		char errorMsg[1024];
		sprintf(errorMsg, "Expected: %f,\n  Actual: %f\n", expected, actual);
		logError(errorMsg);
		assert(false);
	}
}
void assertEqualsString(const char* expected, const char* actual) {
	if (strcmp(expected, actual) != 0) {
		logError("Test failed:");
		char errorMsg[strlen(expected) + strlen(actual) + 50];
		sprintf(errorMsg, "Strings are not equal:\nExpected (%lu): %s\n  Actual (%lu): %s\n", strlen(expected), expected, strlen(actual), actual);
		logError(errorMsg);
		assert(false);
	}
}

void assertEqualsUnsigned(unsigned expected, unsigned actual) {
	if (expected != actual) {
		logError("Test failed:");
		int errorMsgSize = 512;
		char errorMsg[errorMsgSize];
		sprintf(errorMsg, "Expected: %d,", expected);
		logError(errorMsg);

		memset(errorMsg, 0, errorMsgSize);
		sprintf(errorMsg, "  Actual: %d", actual);
		logError(errorMsg);
		assert(false);
	}
}