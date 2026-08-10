package io.elsci.chemikaze.core;

public interface Molecule {
    byte getAtom(int atomidx);
    int getAtomCnt();
    int getBondCnt(int atomidx);
    byte getBondType(int atomidx, int bondidx);
    void setBond(int atom1idx, int atom2idx, byte bondtype);
    int getConnectedAtom(int atomidx, int bondidx);

    static Molecule create(byte[] atoms) {
        return new MoleculeBase0Bonds4Array(atoms);
    }
}
