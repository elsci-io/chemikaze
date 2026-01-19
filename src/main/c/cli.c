#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "mf_parser.h"
#include "signals.h"

size_t getFileSize(FILE *f) {
	fseek(f, 0, SEEK_END);
	size_t size = ftell(f);
	rewind(f);
	if (ferror(f)) {
		perror("Failed to rewind the file");
		exit(1);
	}
	return size;
}

size_t readAllBytes(char *filepath, char **buf) {
	FILE *f = fopen(filepath, "r");
	if (!f) {
		perror("Couldn't open the MF file");
		exit(1);
	}
	size_t size = getFileSize(f);
	*buf = malloc(size);
	if (*buf == NULL) {
		perror("Couldn't allocate memory for the file content");
		exit(1);
	}
	size_t actuallyRead = fread(*buf, size, 1, f);
	if (actuallyRead != 1) {
		fprintf(stderr, "Needed to read %lu, instead read %lu. ", size, actuallyRead);
		if (feof(f))
			fprintf(stderr, "Unexpected end of file");
		else if (ferror(f))
			fprintf(stderr, "Error reading the file: %d\n", ferror(f));
		exit(1);
	}
	fclose(f);
	return size;
}

typedef struct { char *start, *end/*exclusive*/; } MfBounds;

size_t parseAllMfs(MfParser *parser, MfBounds *buf, size_t size, int repeats) {
	size_t hcount = 0;
	ChemikazeError *error = nullptr;
	for (int r = 0; r < repeats; r++) {
		for (size_t i = 0; i < size; i++) {
			MfBounds *currMf = buf+i;
			AtomCounts *counts = MfParser_parseSanitized(parser, currMf->start, currMf->end, &error);
			if (counts == nullptr) {
				ChemikazeError_logAndDestroy(error);
				exit(1);
			}
			hcount += counts->counts[0];
			AtomCounts_free(counts);
		}
	}
	return hcount;
}

/**
 * Reads the file with molecular formulas and fills the specified variables with the data and locations. Exits
 * if any error happens.
 *
 * @param fileStart start of the data that was read from the file
 * @param fileSize the number of bytes in the file
 * @param mfs will point to the allocated memory with all the MFs that must be parsed eventually
 * @param mfBounds an array of start and end positions of each MF in the *mfs
 * @return the number of MFs
 */
unsigned findMfBounds(char *fileStart, size_t fileSize, char **mfs, MfBounds **mfBounds) {
	unsigned lines = 0;
	for (size_t i = 0; i < fileSize; lines++, i++) //calculate mfcount
		while (*(fileStart + i) != '\n' && i != fileSize)
			i++;
	// now let's go through the bytes again, fill the MF strings and their bounds:
	*mfs = malloc(sizeof(char) * (fileSize*2/* w/ and w/o parentheses */ + lines * 4/*parentheses and 2 digits after them*/));
	*mfBounds = malloc(2* lines * sizeof(MfBounds));
	if (mfBounds == nullptr || mfs == nullptr) {
		perror("Couldn't allocate mem for the bounds");
		exit(13);
	}
	MfBounds *currentBound = *mfBounds;
	char *resultPos = *mfs - 1; // Always use ++resultPos when writing to it, so before each operation it points to a byte BEFORE the needed address
	for (size_t i = 0, lineIdx = 0; i < fileSize; i++, lineIdx++) {
		char *lineStart = fileStart + i;
		currentBound->start = resultPos+1;
		while (*(fileStart + i) != '\n' && i != fileSize)
			i++;
		size_t len = fileStart+i - lineStart;
		currentBound->end = currentBound->start+len;
		// First, write the MF as it is, including \n at the end
		memcpy(++resultPos, lineStart, len+1);
		resultPos += len;

		// Now repeat the same MF, but inside (...)
		*++resultPos = '(';
		memcpy(++resultPos, lineStart, len);
		resultPos += len-1;
		*++resultPos = ')';

		// If the coefficient > 1, then add it after the closing parenthesis:
		char coeff = lineIdx % 20; // NOLINT(*-narrowing-conversions)
		if (coeff > 1) {
			char coeffStr[3];
			int coeffLen = snprintf(coeffStr, 3,"%d", coeff);
			strcpy(++resultPos, coeffStr);
			resultPos += coeffLen - 1;
		}
		*++resultPos = '\n';
		// And finally fill the bounds for the MF in the parentheses
		MfBounds *nextBound = currentBound + 1;
		nextBound->start = currentBound->end + 1;
		nextBound->end = resultPos;
		currentBound = nextBound + 1;
	}
	return lines * 2;
}

int main(int argc, char **argv) {
	register_signals();
	if (argc <= 1) {
		fprintf(stderr, "Provider the file with Molecular Formulas as the 1st parameter\n");
		exit(1);
	}
	char *buf = nullptr;
	size_t size = readAllBytes(argv[1], &buf);

	int repeats = 50;
	// Read MFs from the file, fill the resulting *mfs with 2 lines for each line in the file:
	// with the original MF, and with the MF in parentheses with some coefficient. As a result
	// we gather MfBounds that point to the beginning and the end of each of the MF in side the *mfs.
	MfBounds *mfBounds = nullptr;
	char *mfs = nullptr;
	unsigned mfCnt = findMfBounds(buf, size, &mfs, &mfBounds);
	unsigned totalParsed = repeats * mfCnt;
	MfParser *parser = MfParser_new();

	// START WARMUP:
	clock_t start = clock();
	parseAllMfs(parser, mfBounds, mfCnt, 10);
	printf("Warmed up in %f sec\n", (double)(clock() - start)/CLOCKS_PER_SEC);
	// START BENCHMARK:
	start = clock();
	size_t hcount = parseAllMfs(parser, mfBounds, mfCnt, repeats);
	double elapsed = (double)(clock()-start)/CLOCKS_PER_SEC;
	printf("[C BENCHMARK] %d MFs in %f sec (%d MF/s). Hydrogens: %lu\n",
		totalParsed, elapsed, (int) (totalParsed/elapsed), hcount);

	free(mfBounds);
	free(mfs);
	free(buf);
	MfParser_destroy(parser);
	return 0;
}
