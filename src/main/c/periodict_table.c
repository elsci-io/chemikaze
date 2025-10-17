#include "periodict_table.h"

#include <stdio.h>

static const Ascii EARTH_SYMBOLS[EARTH_ELEMENT_CNT][3] = {
	"H", "C", "O", "N", "P", "F", "S", "Br", "Cl", "Na", "Li", "Fe", "K", "Ca", "Mg", "Ni", "Al",
	"Pd", "Sc", "V", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B",
	"Kr", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I",
	"Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb",
	"Lu", "Hf", "Ta", "Tc", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa",
	"U", "He", "Ne", "Ar",
};
static const Ascii EARTH_SYMBOLS_PADDED[EARTH_ELEMENT_CNT][2] = {
	"H\0", "C\0", "O\0", "N\0", "P\0", "F\0", "S\0", "Br", "Cl", "Na", "Li", "Fe", "K\0", "Ca", "Mg", "Ni", "Al",
	"Pd", "Sc", "V\0", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B\0",
	"Kr", "Rb", "Sr", "Y\0", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I\0",
	"Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb",
	"Lu", "Hf", "Ta", "Tc", "W\0", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa",
	"U\0", "He", "Ne", "Ar",
};

#define INDEX_BUCKET_CNT 512
#define INDEX_HASH_MASK (INDEX_BUCKET_CNT-1)

unsigned ptable_hash(Ascii b0, Ascii b1) {
	// Ran an experiment, and 277 is one of few multipliers that gave no collisions in 512-sized hash table.
	// Couldn't achieve the same with subtractions or shifts, no matter the order of b0 and b1.
	return ((b0 * 277) ^ b1) & INDEX_HASH_MASK;
}

// precomputed hash table of `hash(EARTH_SYMBOL_PADDED) -> ChemElement`. See main() for the precomputing.
const ChemElement ELEMENTHASH_TO_ELEMENT[INDEX_BUCKET_CNT] = {
	[488]=0,[127]=1,[379]=2,[102]=3,[144]=4,[446]=5,[463]=6,[280]=7,[19]=8,[7]=9,[85]=10,[475]=11,[295]=12,[30]=13,
	[310]=14,[15]=15,[57]=16,[244]=17,[428]=18,[270]=19,[10]=20,[13]=21,[319]=22,[16]=23,[268]=24,[178]=25,[182]=26,
	[38]=27,[426]=28,[141]=29,[422]=30,[271]=31,[362]=32,[341]=33,[216]=34,[445]=35,[77]=36,[272]=37,[4]=38,[318]=39,
	[207]=40,[210]=41,[50]=42,[27]=43,[147]=44,[417]=45,[429]=46,[129]=47,[253]=48,[349]=49,[12]=50,[267]=51,[93]=52,
	[26]=53,[226]=54,[2]=55,[418]=56,[220]=57,[183]=58,[134]=59,[493]=60,[391]=61,[219]=62,[137]=63,[47]=64,[73]=65,
	[398]=66,[133]=67,[135]=68,[35]=69,[223]=70,[264]=71,[143]=72,[228]=73,[32]=74,[399]=75,[136]=76,[242]=77,[259]=78,
	[140]=79,[241]=80,[505]=81,[397]=82,[3]=83,[39]=84,
};

int main() {
	// Precompute values for ELEMENTHASH_TO_ELEMENT
	for (ChemElement i = 0; i < EARTH_ELEMENT_CNT; i++)
		printf("[%d]=%d,", ptable_hash(EARTH_SYMBOLS_PADDED[i][0], EARTH_SYMBOLS_PADDED[i][1]), i);
}