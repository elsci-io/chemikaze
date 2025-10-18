//
// Created by Stanislav Bashkyrtsev on 10/18/25.
//

#ifndef ELSCI_CHEMIKAZE_ATOMCOUNTS_H
#define ELSCI_CHEMIKAZE_ATOMCOUNTS_H

/**
 * Contains number of atoms of each element in the molecule. Usually is a result of parsing Molecular Formula
 * (see `mf_parser.h#parseMf()`).
 */
typedef struct AtomCounts {
	// The number of atoms of each element: `AtomCounts->counts[e]`, where `e` is ChemElement (see `periodic_table.h`).
	// The array size is always the same size defined by `EARTH_ELEMENT_CNT` in `periodic_table.h`. Usually, there are
	// only a few non-zero values.
	unsigned *counts;
} AtomCounts;

AtomCounts* AtomCounts_new();
char* AtomCounts_toString(AtomCounts*);
#endif //ELSCI_CHEMIKAZE_ATOMCOUNTS_H
