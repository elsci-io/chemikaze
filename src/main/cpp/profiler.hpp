#ifndef PROFILER_HPP
#define PROFILER_HPP

#include "types.hpp"
#include <stdio.h>
#include <sys/time.h>

u64 readOSTimer() {
    struct timeval value;
    gettimeofday(&value, 0);

    u64 result = 1e6 * (u64)value.tv_sec + (u64)value.tv_usec;
    return result;
}

inline u64 readCPUTimer() {
	return __builtin_ia32_rdtsc();
}

u64 estimateCPUFreq(u64 ms) {
    u64 cpuStart  = readCPUTimer();
    u64 osStart   = readOSTimer();
    u64 osEnd     = 0;
    u64 osElapsed = 0;

    u64 osWaitTime = 1e6 * ms / 1000;

    while (osElapsed < osWaitTime) {
        osEnd = readOSTimer();
        osElapsed = osEnd - osStart;
    }

    u64 cpuEnd     = readCPUTimer();
    u64 cpuElapsed = cpuEnd - cpuStart;
    u64 cpuFreq    = 0;

    if (osElapsed) {
        cpuFreq = 1e6 * cpuElapsed / osElapsed;
    }

    return cpuFreq;
}

#ifndef PROFILE
#define PROFILE 1
#endif

#define ArrayCount(Array) (sizeof(Array)/sizeof((Array)[0]))

struct Anchor {
    const char* label;
    u64 hitCount;

    u64 processedData;
    u64 tscElapsedExclusive;
    u64 tscElapsedInclusive;
};

#if PROFILE

struct Profiler {
    Anchor anchors[4096];

    u64 startTSC;
    u64 endTSC;
};

static u32 globalProfilerParent;
static Profiler globalProfiler;

struct TimeScope {
    TimeScope(const char* label_, u32 anchorIndex_, u64 processedData_) {
        parentIndex = globalProfilerParent;

        anchorIndex = anchorIndex_;
        label = label_;
        processedData = processedData_;

        Anchor *anchor = globalProfiler.anchors + anchorIndex;
        oldTSCElapsedInclusive = anchor->tscElapsedInclusive;
        anchor->processedData += processedData;

        globalProfilerParent = anchorIndex;
        startTSC = readCPUTimer();
    }

    ~TimeScope() {
        u64 elapsed = readCPUTimer() - startTSC;
        globalProfilerParent = parentIndex;

        Anchor *parent = globalProfiler.anchors + parentIndex;
        Anchor *anchor = globalProfiler.anchors + anchorIndex;

        parent->tscElapsedExclusive -= elapsed;
        anchor->tscElapsedExclusive += elapsed;
        anchor->tscElapsedInclusive = oldTSCElapsedInclusive + elapsed;
        ++anchor->hitCount;

        anchor->label = label;
    }

    const char *label;
    u64 processedData;
    u64 oldTSCElapsedInclusive;
    u64 startTSC;
    u32 parentIndex;
    u64 anchorIndex;
};

#define TimeThroughput(name, size) TimeScope NameConcat(Block, __LINE__)(name, __COUNTER__ + 1, size);
#define NameConcat2(A, B) A##B
#define NameConcat(A, B) NameConcat2(A, B)
#define TimeBlock(name) TimeThroughput(name, 0);
#define TimeFunction() TimeBlock(__func__)

#else

#define TimeThroughput(...)
#define TimeBlock(...)
#define TimeFunction(...)

struct Profiler {
    Anchor anchors[1];

    u64 startTSC;
    u64 endTSC;
};

static Profiler globalProfiler;

#endif

static void printTimeElapsed(u64 totalTSCElapsed, Anchor *anchor, u64 cpuFreq) {
    f64 percent = 100.0 * ((f64)anchor->tscElapsedExclusive / (f64)totalTSCElapsed);
    printf("   %s[%lu]: %lu (%fms) (%.2f%%",
           anchor->label, anchor->hitCount,
           anchor->tscElapsedExclusive,
           (f64)anchor->tscElapsedExclusive / cpuFreq * 1000.,
           percent
    );

    if(anchor->tscElapsedInclusive != anchor->tscElapsedExclusive) {
        f64 percentWithChildren = 100.0 * ((f64)anchor->tscElapsedInclusive / (f64)totalTSCElapsed);
        printf(", %.2f%% w/children", percentWithChildren);
    }

    if(anchor->processedData) {
        f64 megabyte = 1024. * 1024.;
        f64 gigabyte = megabyte * 1024.;

        f64 seconds = (f64)anchor->tscElapsedInclusive / (f64)cpuFreq;
        f64 bytesPerSecond = (f64)anchor->processedData / seconds;
        f64 megabytes = (f64)anchor->processedData / (f64) megabyte;
        f64 gigabytesPerSecond = bytesPerSecond / gigabyte;

        printf("   %.3fmb at %.2fgb/s", megabytes, gigabytesPerSecond);
    }

    printf(")\n");
}

void startProfiling() {
    globalProfiler.startTSC = readCPUTimer();
}

f64 endProfilingAndPrint() {
    globalProfiler.endTSC = readCPUTimer();
    u64 cpuFreq = estimateCPUFreq(1000);

    u64 totalCPUElapsed = globalProfiler.endTSC - globalProfiler.startTSC;

    if(cpuFreq) {
        printf("\n Total time: %0.fms (CPU freq %lu)\n", 1000.0 * (f64)totalCPUElapsed / (f64)cpuFreq, cpuFreq);
    }

    for (u32 index = 0; index < ArrayCount(globalProfiler.anchors); ++index) {
        Anchor *anchor = globalProfiler.anchors + index;
        if (anchor->tscElapsedInclusive) {
            printTimeElapsed(totalCPUElapsed, anchor, cpuFreq);
        }
    }

    return (f64)totalCPUElapsed / (f64)cpuFreq;
}

#endif
