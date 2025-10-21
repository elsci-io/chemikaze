cmake_minimum_required(VERSION 4.0)
project(elsci_chemikaze C)

set(CMAKE_C_FLAGS "-Wall -Werror -Wextra")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS} -O0 -ggdb")
set(CMAKE_C_STANDARD 23)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/target/cmake/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/target/cmake/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/target/cmake/bin)

set(SRC_ROOT src/main/c)
set(TST_ROOT src/test/c)
set(COMMON_SRCS
        ${SRC_ROOT}/periodic_table.c
        ${SRC_ROOT}/periodic_table.h
        ${SRC_ROOT}/mf_parser.c
        ${SRC_ROOT}/mf_parser.h
        ${SRC_ROOT}/AtomCounts.c
        ${SRC_ROOT}/AtomCounts.h
        ${SRC_ROOT}/error.c
        ${SRC_ROOT}/error.h
)
set(TEST_SRCS
        ${TST_ROOT}/log.c
        ${TST_ROOT}/asserts.h
        ${TST_ROOT}/asserts.c
        ${TST_ROOT}/signals.c
)

add_executable(chemikaze ${COMMON_SRCS} ${SRC_ROOT}/cli.c)
add_executable(chemikaze_tests ${COMMON_SRCS} ${TEST_SRCS} ${TST_ROOT}/chemikaze_test.c)
