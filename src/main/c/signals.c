#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>


void signal_handler_log_stacktrace(int sig) { // There's also /lib/libSegFault.so which you can use with LD_PRELOAD.
	fprintf(stderr, "Received signal %d\n", sig);
	void *array[10];

	// get void*'s for all entries on the stack
	size_t size = backtrace(array, 10);

	// print out all the frames to stderr
	fprintf(stderr, "Error: signal %d:\n", sig);
	backtrace_symbols_fd(array, size, STDERR_FILENO); // NOLINT(*-narrowing-conversions)
	exit(139);
}

void register_signals(void) {
	signal(SIGSEGV, signal_handler_log_stacktrace);
	signal(SIGABRT, signal_handler_log_stacktrace);
}