#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
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

size_t parseAllMfs(MfParser *parser, MfBounds *buf, size_t size) {
	size_t hcount = 0;
	ChemikazeError *error = nullptr;
	for (size_t i = 0; i < size; buf++, i++) {
		AtomCounts *counts = parseMfSanitized(parser, buf->start, buf->end, &error);
		if (counts == nullptr) {
			ChemikazeError_logAndDestroy(error);
			exit(1);
		}
		hcount += counts->counts[0];
		AtomCounts_free(counts);
	}
	return hcount;
}


unsigned findMfBounds(char *buf, size_t size, MfBounds **mfBounds) {
	unsigned mfcount = 0;
	for (size_t i = 0; i < size; mfcount++, i++)//calculate mfcount
		while (*(buf + i) != '\n' && i != size)
			i++;
	// now let's go through the bytes again and fill the bounds:
	*mfBounds = malloc(mfcount * sizeof(MfBounds));
	if (mfBounds == nullptr) {
		perror("Couldn't allocate mem for the bounds");
		exit(13);
	}
	MfBounds *current = *mfBounds;
	for (size_t i = 0; i < size; current++, i++) {
		current->start = buf + i++;
		while (*(buf + i) != '\n' && i != size)
			i++;
		current->end = buf + i;
	}
	return mfcount;
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
	// Go through the data once to calculate MF end and start offsets, so that these calcs aren't part of the benchmark:
	MfBounds *mfs = nullptr;
	unsigned mfCnt = findMfBounds(buf, size, &mfs);
	unsigned totalParsed = repeats * mfCnt;

	MfParser *parser = MfParser_new();
	// START BENCHMARK:
	clock_t start = clock();
	for (int i = 0; i < 10; i++)
		parseAllMfs(parser, mfs, mfCnt);
	printf("Warmed up in %f sec\n", (double)(clock() - start)/CLOCKS_PER_SEC);
	start = clock();
	for (int i = 0; i < repeats; i++)
		parseAllMfs(parser, mfs, mfCnt);
	double elapsed = (double)(clock()-start)/CLOCKS_PER_SEC;
	printf("[C BENCHMARK] %d MFs in %f sec (%d MF/s)\n", totalParsed, elapsed, (int) (totalParsed/elapsed));

	free(mfs);
	free(buf);
	MfParser_destroy(parser);
	return 0;
}
