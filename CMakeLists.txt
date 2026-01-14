cmake_minimum_required(VERSION 4.0)
project(elsci_chemikaze C ASM)

#set(CMAKE_OSX_ARCHITECTURES "arm64")
set(CMAKE_C_FLAGS "-Wall -Werror -Wextra -O3")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS} -O0 -ggdb")
set(CMAKE_C_STANDARD 23)

# brew install llvm
# brew info llvm - for the path for clang
include(CheckCCompilerFlag)
check_c_compiler_flag("-std=c23" HAS_C23)
if(NOT HAS_C23)
    message(FATAL_ERROR "Compiler does not support C23")
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/target/cmake/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/target/cmake/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/target/cmake/bin)

set(SRC_ROOT src/main/c)
set(TST_ROOT src/test/c)
set(HEADERS
        ${SRC_ROOT}/periodic_table.h
        ${SRC_ROOT}/mf_parser.h
        ${SRC_ROOT}/AtomCounts.h
        ${SRC_ROOT}/error.h
        ${SRC_ROOT}/signals.c # not a header, but we need it for both C and Assembly
)
set(C_SRCS
        ${SRC_ROOT}/periodic_table.c
        ${SRC_ROOT}/AtomCounts.c
        ${SRC_ROOT}/mf_parser.c
        ${SRC_ROOT}/error.c
)
set(TEST_SRCS
        ${TST_ROOT}/log.c
        ${TST_ROOT}/asserts.c
        ${TST_ROOT}/asserts.h
        ${TST_ROOT}/chemikaze_test.c
)

add_executable(chemikaze ${HEADERS} ${C_SRCS} ${SRC_ROOT}/cli.c)
add_executable(chemikaze_asm ${HEADERS} ${SRC_ROOT}/mf_parser.armv8.asm ${SRC_ROOT}/cli.c)
add_executable(chemikaze_tests ${HEADERS} ${C_SRCS} ${TEST_SRCS})
add_executable(chemikaze_asm_tests ${HEADERS} ${SRC_ROOT}/mf_parser.armv8.asm ${TEST_SRCS})
