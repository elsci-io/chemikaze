#include "periodic_table.h"

#include <stdio.h>
#include <stdlib.h>

#include "error.h"

#define INDEX_BUCKET_CNT 512
#define INDEX_HASH_MASK (INDEX_BUCKET_CNT-1)

unsigned hash(const char symbol[static 2]) {
	// Ran an experiment, and 277 is one of few multipliers that gave no collisions in 512-sized hash table.
	// Couldn't achieve the same with subtractions or shifts, no matter the order of b0 and b1.
	//
	// Need to try gperf in the future: https://www.gnu.org/software/gperf/manual/gperf.html#Description
	// ReSharper disable once CppRedundantParentheses
	return ((symbol[0] * 277) ^ symbol[1]) & INDEX_HASH_MASK;
}

// precomputed hash table of `hash(EARTH_SYMBOL_PADDED) -> ChemElement`. See main() for the precomputing.
constexpr ChemElement ELEMENTHASH_TO_ELEMENT[INDEX_BUCKET_CNT] = {
	[488]=0,[127]=1,[379]=2,[102]=3,[144]=4,[446]=5,[463]=6,[280]=7,[19]=8,[7]=9,[85]=10,[475]=11,[295]=12,[30]=13,
	[310]=14,[15]=15,[57]=16,[244]=17,[428]=18,[270]=19,[10]=20,[13]=21,[319]=22,[16]=23,[268]=24,[178]=25,[182]=26,
	[38]=27,[426]=28,[141]=29,[422]=30,[271]=31,[362]=32,[341]=33,[216]=34,[445]=35,[77]=36,[272]=37,[4]=38,[318]=39,
	[207]=40,[210]=41,[50]=42,[27]=43,[147]=44,[417]=45,[429]=46,[129]=47,[253]=48,[349]=49,[12]=50,[267]=51,[93]=52,
	[26]=53,[226]=54,[2]=55,[418]=56,[220]=57,[183]=58,[134]=59,[493]=60,[391]=61,[219]=62,[137]=63,[47]=64,[73]=65,
	[398]=66,[133]=67,[135]=68,[35]=69,[223]=70,[264]=71,[143]=72,[228]=73,[32]=74,[399]=75,[136]=76,[242]=77,[259]=78,
	[140]=79,[241]=80,[505]=81,[397]=82,[3]=83,[39]=84,
};

ChemElement ptable_getElementBySymbol(char symbol[static 2]) {
	ChemElement e = ELEMENTHASH_TO_ELEMENT[hash(symbol)];
	if (EARTH_SYMBOLS[e][0] != symbol[0] || EARTH_SYMBOLS[e][1] != symbol[1])
		return INVALID_CHEM_ELEMENT;
	return e;
}

[[maybe_unused]]
static void precomputeElementHashTable() {
	// Precompute values for ELEMENTHASH_TO_ELEMENT
	for (ChemElement i = 0; i < EARTH_ELEMENT_CNT; i++)
		printf("[%d]=%d,", hash((char[]) {EARTH_SYMBOLS[i][0], EARTH_SYMBOLS[i][1]}), i);
}