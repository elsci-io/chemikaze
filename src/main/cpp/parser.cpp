#include "parser.hpp"
#include <ctype.h>
#include <stdio.h>

static const char *EARTH_SYMBOLS[85] = {
    "H",  "C",  "O",  "N",  "P",  "F",  "S",  "Br", "Cl", "Na", "Li", "Fe", "K",  "Ca",
    "Mg", "Ni", "Al", "Pd", "Sc", "V",  "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge",
    "As", "Se", "Ti", "Si", "Be", "B",  "Kr", "Rb", "Sr", "Y",  "Zr", "Nb", "Mo",
    "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I",  "Xe", "Cs", "Ba", "La",
    "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu",
    "Hf", "Ta", "Tc", "W",  "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi",
    "Th", "Pa", "U",  "He", "Ne", "Ar"
};
static u8 ELEMENT_INDEX[26][27] = {0};
static inline u8 get_element_index(u8 l1, u8 l2) {
    return ELEMENT_INDEX[l1 - 'A'][l2 ? l2-'a'+1 : 0]-1;
}

void init_element_index(void) {
    for (u8 i = 0; i < 85; ++i) {
        unsigned char c1 = EARTH_SYMBOLS[i][0];
        unsigned char c2 = EARTH_SYMBOLS[i][1];
        ELEMENT_INDEX[c1-'A'][c2 ? c2-'a'+1 : 0] = i+1;
    }
}

const char* get_element_by_index(u8 index) {
    return EARTH_SYMBOLS[index];
}

inline u16 read_coeff(const char** p) {
    u16 coeff = 0;
    bool any_digit = false;

    while (isdigit(**p)) {
        any_digit = true;
        coeff = coeff * 10 + (u16)(**p - '0');
        (*p)++;
    }

    if (!any_digit && !coeff) { coeff = 1; }
    return coeff;
}

AtomCount parse_mf(const char** p, const char closing) {
    AtomCount atomCount{};
    AtomCount segmentCount{};

    u16 globalCoeff = read_coeff(p);
    while (**p) {
        if (isupper(**p)) {
            u8 l1 = (**p);
            u8 l2 = 0;
            if (*(*p+1) && islower(*(*p+1))) {
                l2 = *(*p + 1);
                (*p)++;
            }

            u8 index = get_element_index(l1, l2);
            if (index == 255) {
                printf("Unknown element: %c%c \n", l1, l2);
                return AtomCount{};
            }

            (*p)++;

            u16 coeff = read_coeff(p);
            segmentCount.atoms[index] += coeff;
        } else if (**p == '(' || **p == '[') {
            const char closing = **p == '(' ? ')' : ']';
            (*p)++;
            AtomCount atomCountGr = parse_mf(p, closing);
            if (!**p) return AtomCount{};
            (*p)++;

            u16 coeff = read_coeff(p);
            if (**p == '+' || **p == '-') coeff = 1;

            #pragma GCC unroll 8
            for (u8 i = 0; i < 85; ++i) {
                segmentCount.atoms[i] += atomCountGr.atoms[i] * coeff;
            }
        } else if (**p == '.') {
            #pragma GCC unroll 8
            for (u8 i = 0; i < 85; ++i) {
                atomCount.atoms[i] += segmentCount.atoms[i] * globalCoeff;
            }

            segmentCount = AtomCount{};
            (*p)++;
            globalCoeff = read_coeff(p);
        } else if (**p == ')' || **p == ']') {
            if (**p == closing) {
                break;
            } else {
                printf("Expected %c got %c\n", closing, **p);
                return AtomCount{};
            }
        } else if (**p == '-' || **p == '+' || **p == ' ') {
            (*p)++;
        } else {
            printf("Unknown token: %c \n", **p);
            return AtomCount{};
        }
    }

    #pragma GCC unroll 8
    for (u8 i = 0; i < 85; ++i) {
        atomCount.atoms[i] += segmentCount.atoms[i] * globalCoeff;
    }

    return atomCount;
}
