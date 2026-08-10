#ifndef CMAKE_PET_ASSERTS_H
#define CMAKE_PET_ASSERTS_H

void assertEqualsDouble(double expected, double actual, double absTolerance);
void assertEqualsString(const char* expected, const char* actual);
void assertEqualsUnsigned(unsigned expected, unsigned actual);

#endif //CMAKE_PET_ASSERTS_H
