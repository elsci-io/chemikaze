cmake_minimum_required(VERSION 4.0)
project(elsci_chemikaze C)

set(CMAKE_C_FLAGS "-Wall -Werror -Wextra")
set(CMAKE_C_FLAGS_DEBUG "-Wall -Werror -Wextra -O0 -ggdb")

set(CMAKE_C_STANDARD 23)

include_directories(src/main/c)

add_executable(chemikaze
        src/main/c/cli.c
        src/main/c/mf_parser.c
        src/main/c/periodic_table.c
)

add_executable(chemikaze_tests
        src/test/c/periodic_table_test.c

        src/main/c/periodic_table.c
        src/main/c/mf_parser.c

        src/test/c/log.c
        src/test/c/asserts.c
)
