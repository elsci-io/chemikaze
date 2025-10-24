#include <ctype.h>
#include <stdio.h>
#include "parser.hpp"

constexpr static const char *EARTH_SYMBOLS[85] __attribute__((aligned(64))) = {
    "H",  "C",  "O",  "N",  "P",  "F",  "S",  "Br", "Cl", "Na", "Li", "Fe", "K",  "Ca",
    "Mg", "Ni", "Al", "Pd", "Sc", "V",  "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge",
    "As", "Se", "Ti", "Si", "Be", "B",  "Kr", "Rb", "Sr", "Y",  "Zr", "Nb", "Mo",
    "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I",  "Xe", "Cs", "Ba", "La",
    "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu",
    "Hf", "Ta", "Tc", "W",  "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi",
    "Th", "Pa", "U",  "He", "Ne", "Ar"
};

constexpr static const u16 ELEMENT_INDEX[26][27] __attribute__((aligned(64))) = {
    {0, 0, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 85, 28, 0, 75, 0, 0, 0, 0, 0},
    {33, 52, 0, 0, 0, 32, 0, 0, 0, 79, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0},
    {2, 14, 0, 0, 44, 54, 0, 0, 0, 0, 0, 0, 9, 0, 0, 24, 0, 0, 22, 51, 0, 21, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 61, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 58, 0, 0, 0, 0, 0},
    {6, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 26, 0, 0, 59, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, 0, 0, 0, 0, 83, 67, 76, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 0, 0, 0, 73, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 34, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 53, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 23, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {4, 10, 39, 0, 56, 84, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 0},
    {5, 81, 78, 0, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 55, 0, 74, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 35, 0, 0, 71, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0},
    {7, 0, 47, 19, 0, 29, 0, 0, 0, 31, 0, 0, 0, 57, 46, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 68, 60, 69, 0, 48, 0, 0, 80, 30, 0, 0, 77, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {70, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {37, 0, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 25, 0, 0, 0, 38, 0, 0, 0, 0, 0, 0, 0, 0}
};

static inline u16 get_element_index(u16 l1, u16 l2) {
    return ELEMENT_INDEX[l1 - 'A'][l2 ? l2-'a'+1 : 0]-1;
}

const char* get_element_by_index(u16 index) {
    return EARTH_SYMBOLS[index];
}

inline u16 read_coeff(const char** p) {
    const char* s = *p;
    unsigned v = 0;
    unsigned c = (unsigned char)*s;
    if (c < '0' || c > '9') {
        *p = s;
        return 1;
    }

    do {
        v = v * 10 + (c - '0');
        c = (unsigned char)*++s;
    } while (c - '0' < 10);

    *p = s;
    return (u16)v;
}

AtomCount parse_mf(const char** p, const char closing) {
    AtomCount atomCount{};
    AtomCount segmentCount{};

    u16 globalCoeff = read_coeff(p);
    while (**p) {
        if (isupper(**p)) {
            u16 l1 = (**p);
            u16 l2 = 0;

            unsigned c = (unsigned char)*(*p+1);
            if (c >= 'a' && c <= 'z') {
                l2 = c;
                (*p)++;
            }

            u16 index = get_element_index(l1, l2);
            if (index == 0xFFFF) {
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

            for (u16 i = 0; i < 88; i+=4) {
                segmentCount.atoms[i] += atomCountGr.atoms[i] * coeff;
                segmentCount.atoms[i+1] += atomCountGr.atoms[i+1] * coeff;
                segmentCount.atoms[i+2] += atomCountGr.atoms[i+2] * coeff;
                segmentCount.atoms[i+3] += atomCountGr.atoms[i+3] * coeff;
            }
        } else if (**p == '.') {
            for (u16 i = 0; i < 88; i+=4) {
                atomCount.atoms[i] += segmentCount.atoms[i] * globalCoeff;
                atomCount.atoms[i+1] += segmentCount.atoms[i+1] * globalCoeff;
                atomCount.atoms[i+2] += segmentCount.atoms[i+2] * globalCoeff;
                atomCount.atoms[i+3] += segmentCount.atoms[i+3] * globalCoeff;
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

    for (u16 i = 0; i < 88; i+=4) {
        atomCount.atoms[i] += segmentCount.atoms[i] * globalCoeff;
        atomCount.atoms[i+1] += segmentCount.atoms[i+1] * globalCoeff;
        atomCount.atoms[i+2] += segmentCount.atoms[i+2] * globalCoeff;
        atomCount.atoms[i+3] += segmentCount.atoms[i+3] * globalCoeff;
    }

    return atomCount;
}
