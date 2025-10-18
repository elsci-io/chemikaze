//
// Created by Stanislav Bashkyrtsev on 10/18/25.
//

#ifndef ELSCI_CHEMIKAZE_ATOMCOUNTS_H
#define ELSCI_CHEMIKAZE_ATOMCOUNTS_H

typedef struct AtomCounts {
	unsigned *counts;
} AtomCounts;

AtomCounts* AtomCounts_new();
char* AtomCounts_toString(AtomCounts*);
#endif //ELSCI_CHEMIKAZE_ATOMCOUNTS_H
