#pragma once
#include "types.hpp"

typedef struct {
    u16 atoms[85];
} AtomCount;


AtomCount parse_mf(const char** formula, const char closing = -1);
void init_element_index(void);
const char* get_element_by_index(u8 index);
