package io.elsci.chemikaze;

/**
 * Can be an actual molecule or a multiple unconnected compoonents (like a salt). Has a list of atoms, as well as
 * bonnds between them.
 * <p>
 * <a href="./README.md">Design decisions</a>
 */
public class MoleculeBondCountArray {
    /** Use {@code PeriodicTable.SYMBOLS[atom]} to conver it to human-readable name. */
    byte[] atoms;
    byte[] bondCnt;
    int[] bonds;
    byte[] bondtypes;

    public MoleculeBondCountArray(int atomCnt) {
        atoms = new byte[atomCnt];
        bondCnt = new byte[atoms.length];
        bonds = new int[atomCnt*4];
        bondtypes = new byte[bonds.length];
    }

    public byte getAtom(int idx) {
        return atoms[idx];
    }

    public int getAtomCnt() {
        return atoms.length;
    }
    public int isConnected(int atomIdx0, int atomIdx1) {
        throw new UnsupportedOperationException();
    }

    public int getBond(int atomIdx, int bondIdx) {
        if(bondIdx > 4)
            throw new IndexOutOfBoundsException("We don't yet support more than 4 bonds");
        if (bondIdx >= getBondCount(atomIdx))
            throw new IndexOutOfBoundsException("Bond #" + bondIdx+" does not exist, there are only " + getBondCount(atomIdx) + " bonds");
        return bonds[atomIdx * 4 + bondIdx];
    }

    public int getBondCount(int atomIdx) {
        return bondCnt[atomIdx];
    }
}
