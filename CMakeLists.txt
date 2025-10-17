cmake_minimum_required(VERSION 4.0)
project(elsci_chemikaze C)

set(CMAKE_C_STANDARD 11)

include_directories(src/main/c)

add_executable(chemikaze
        src/main/c/periodict_table.c
        src/main/c/periodict_table.h)
