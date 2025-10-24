#pragma once
#include "types.hpp"

typedef struct __attribute__((aligned(64))){
    u16 atoms[88];
} AtomCount;


AtomCount parse_mf(const char** formula, const char closing = -1);
const char* get_element_by_index(u16 index);
