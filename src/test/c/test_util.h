#ifndef CMAKE_PET_TEST_UTIL_H
#define CMAKE_PET_TEST_UTIL_H

#define RUN_TEST(testFunction) ({logInfo(" "#testFunction"()"); testFunction();})

#endif //CMAKE_PET_TEST_UTIL_H