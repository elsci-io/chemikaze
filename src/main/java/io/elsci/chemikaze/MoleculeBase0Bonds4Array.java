package io.elsci.chemikaze;

import java.util.Arrays;

/**
 * Can be an actual molecule or a multiple unconnected compoonents (like a salt). Has a list of atoms, as well as
 * bonnds between them.
 * <p>
 * <a href="./README.md">Design decisions</a>
 */
public class MoleculeBase0Bonds4Array implements Molecule {
    /** Use {@code PeriodicTable.SYMBOLS[atom]} to conver it to human-readable name. */
    byte[] atoms;
    int[] bonds;
    byte[] bondtypes;

    public MoleculeBase0Bonds4Array(byte[] atoms) {
        this.atoms = atoms;
        bonds = new int[atoms.length*4];
        bondtypes = new byte[bonds.length];
        Arrays.fill(bonds, -1);
        Arrays.fill(bondtypes, (byte) -1);
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
    public int getBondCnt(int atomIdx) {
        int cnt = 0;
        int startIdx = atomIdx * 4;
        int endIdx = startIdx + 4;
        for (int i = startIdx; i < endIdx && bonds[atomIdx] != -1; i++)
            cnt++;
        return cnt;
    }
    public int getConnectedAtom(int atomIdx, int bondIdx) {
        if(bondIdx > 4)
            throw new IndexOutOfBoundsException("We don't yet support more than 4 bonds");
        int bond = bonds[atomIdx * 4 + bondIdx];
        if (bond == -1)
            throw new IndexOutOfBoundsException("Bond #" + bondIdx+" does not exist, there are only " + getBondCnt(atomIdx) + " bonds");
        return bond;
    }

    public byte getBondType(int atomIdx, int bondIdx) {
        if(bondIdx > 4)
            throw new IndexOutOfBoundsException("We don't yet support more than 4 bonds");
        byte bondtype = bondtypes[atomIdx * 4 + bondIdx];
        if (bondtype == -1)
            throw new IndexOutOfBoundsException("Bond #" + bondIdx+" does not exist, there are only " + getBondCnt(atomIdx) + " bonds");
        return bondtype;
    }
}
