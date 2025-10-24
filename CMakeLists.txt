cmake_minimum_required(VERSION 3.10)
project(ChemParser CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB_RECURSE SOURCES "src/main/cpp/*.cpp")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native -mtune=native -flto -fno-exceptions -fno-rtti -DNDEBUG")
set_source_files_properties(src/main/cpp/main.cpp PROPERTIES COMPILE_FLAGS "-fexceptions")

add_executable(${PROJECT_NAME} ${SOURCES})

