package io.elsci.chemikaze;

public interface Molecule {
    byte getAtom(int atomidx);
    int getAtomCnt();
    int getBondCnt(int atomidx);
    byte getBondType(int atomidx, int bondidx);
    int getConnectedAtom(int atomidx, int bondidx);

    static Molecule create(byte[] atoms) {
        return new MoleculeBase0Bonds4Array(atoms);
    }
}
