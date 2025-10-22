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

unsigned parseAllMfs(char *buf, size_t size) {
	unsigned mfcount = 0;
	for (size_t i = 0; i < size; mfcount++, i++) {
		char *mf = buf + i++;
		while (*(buf + i) != '\n' && i != size)
			i++;
		ChemikazeError *error = nullptr;
		AtomCounts *counts = parseMfChunk(mf, buf + i, &error);
		if (counts == nullptr) {
			perror(error->msg);
			exit(1);
		}
		AtomCounts_free(counts);
	}
	return mfcount;
}

int main(int argc, [[maybe_unused]] char **argv) {
	register_signals();
	if (argc <= 1) {
		fprintf(stderr, "Provider the file with Molecular Formulas as the 1st parameter\n");
		exit(1);
	}
	char *buf = nullptr;
	size_t size = readAllBytes(argv[1], &buf);

	int repeats = 50;
	unsigned mfInFile = 0;

	clock_t start = clock();
	for (int i = 0; i < repeats; i++)
		mfInFile = parseAllMfs(buf, size);
	printf("Finished warmup in %f sec\n", (double)(clock()-start)/CLOCKS_PER_SEC);

	unsigned mfCnt = repeats * mfInFile;
	start = clock();
	for (int i = 0; i < repeats; i++)
		parseAllMfs(buf, size);
	double elapsed = (double)(clock()-start)/CLOCKS_PER_SEC;
	printf("[C BENCHMARK] %d MFs in %f sec (%d MF/s)\n", mfCnt, elapsed, (int) (mfCnt/elapsed));

	free(buf);
	return 0;
}
