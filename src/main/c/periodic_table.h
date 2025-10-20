//
// Created by Stanislav Bashkyrtsev on 10/17/25.
//

#ifndef CHEMIKAZE_PERIODICT_TABLE_H
#define CHEMIKAZE_PERIODICT_TABLE_H
#include "error.h"

typedef unsigned char ChemElement;

#define EARTH_ELEMENT_CNT 85
#define INVALID_CHEM_ELEMENT 255
static const char EARTH_SYMBOLS[EARTH_ELEMENT_CNT][3] = {
	"H", "C", "O", "N", "P", "F", "S", "Br", "Cl", "Na", "Li", "Fe", "K", "Ca", "Mg", "Ni", "Al",
	"Pd", "Sc", "V", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B",
	"Kr", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I",
	"Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb",
	"Lu", "Hf", "Ta", "Tc", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa",
	"U", "He", "Ne", "Ar",
};

ChemElement ptable_getElementBySymbol(char symbol[static 2], ChemikazeError **error);

#endif //CHEMIKAZE_PERIODICT_TABLE_H