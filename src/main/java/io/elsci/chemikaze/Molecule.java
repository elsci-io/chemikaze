package io.elsci.chemikaze;

/**
 * Can be an actual molecule or a multiple unconnected compoonents (like a salt). Has a list of atoms, as well as
 * bonnds between them.
 */
public class Molecule {
    /** Use {@code PeriodicTable.SYMBOLS[atom]} to conver it to human-readable name. */
    byte[] atoms;
    int[][] bonds;
    byte[][] bondtypes;

    int getAtomCount() {
        return atoms.length;
    }
}
