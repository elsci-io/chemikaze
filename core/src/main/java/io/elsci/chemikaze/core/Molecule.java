package io.elsci.chemikaze.core;

public interface Molecule {
    byte getElement(int atom);
    int getAtomCnt();
    int getBondCnt(int atom);
    byte getBondType(int atom, int bond);
    void setBond(int atom1idx, int atom2idx, byte bondtype);
    int getConnectedAtom(int atom, int bond);

    static Molecule create(byte[] atoms) {
        return new MoleculeSimple(atoms);
    }
}
