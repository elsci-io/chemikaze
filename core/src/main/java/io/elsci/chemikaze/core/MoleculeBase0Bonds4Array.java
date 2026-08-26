package io.elsci.chemikaze.core;

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
        this.bonds = new int[atoms.length*4];
        this.bondtypes = new byte[bonds.length];
        Arrays.fill(bonds, -1);
        Arrays.fill(bondtypes, (byte) -1);
    }

    public byte getElement(int atom) {
        return atoms[atom];
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
        for (int i = startIdx; i < endIdx && bonds[i] != -1; i++)
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

    public void setBond(int atom1idx, int atom2idx, byte bondtype) {
        int pos = atom1idx*4 + getBondCnt(atom1idx);
        bonds[pos] = atom2idx;
        bondtypes[pos] = bondtype;
        // now fill the bond from the other side:
        pos = atom2idx*4 + getBondCnt(atom2idx);
        bonds[pos] = atom1idx;
        bondtypes[pos] = bondtype;
    }
}
