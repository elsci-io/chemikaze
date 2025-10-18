cmake_minimum_required(VERSION 4.0)
project(elsci_chemikaze C)

set(CMAKE_C_FLAGS "-Wall -Werror -Wextra")
set(CMAKE_C_FLAGS_DEBUG "-Wall -Werror -Wextra -O0 -ggdb")

set(CMAKE_C_STANDARD 23)

include_directories(src/main/c)

add_executable(chemikaze
        src/main/c/cli.c
        src/main/c/periodic_table.c
        src/main/c/periodic_table.h
        src/main/c/mf_parser.c
        src/main/c/mf_parser.h
        src/main/c/AtomCounts.c
        src/main/c/AtomCounts.h
)

add_executable(chemikaze_tests
        src/main/c/AtomCounts.c
        src/main/c/periodic_table.c
        src/main/c/periodic_table.h
        src/main/c/mf_parser.c
        src/main/c/mf_parser.h

        src/test/c/log.c
        src/test/c/asserts.h
        src/test/c/asserts.c
        src/test/c/signals.c

        src/test/c/chemikaze_test.c
)
