package io.elsci.chemikaze.core;

public class MoleculeSimple implements Molecule {
    byte[] atoms;
    byte[] bondcnts;
    int[][] bonds;
    byte[][] bondtypes;

    public MoleculeSimple(byte[] atoms) {
        this.atoms = atoms;
        this.bondcnts = new byte[atoms.length];
        this.bonds = new int[atoms.length][4];
        this.bondtypes = new byte[atoms.length][4];
    }

    public byte getAtom(int atomidx) {
        return atoms[atomidx];
    }
    public int getAtomCnt() {
        return atoms.length;
    }
    public int getBondCnt(int atomidx) {
        return bondcnts[atomidx];
    }
    public byte getBondType(int atomidx, int bondidx) {
        assertBondExists(atomidx, bondidx);
        return bondtypes[atomidx][bondidx];
    }
    public void setBond(int a1, int a2, byte bondtype) {
        int bondidx = ArrayUtils.indexOf(bonds[a1], 0, bondcnts[a1], a2);
        if(bondidx >= 0) {
            setBondTypeLeftSide(a1, a2, bondtype);
            setBondTypeLeftSide(a2, a1, bondtype);
        } else {
            addNewBondLeftSide(a1, a2, bondtype);
            addNewBondLeftSide(a2, a1, bondtype);
        }
        assert isConnected(a1, a2);
    }
    public int getConnectedAtom(int atomidx, int bondidx) {
        assertBondExists(atomidx, bondidx);
        return bonds[atomidx][bondidx];
    }
    private void setBondTypeLeftSide(int a1, int a2, byte bondtype) {
        int bondidx = ArrayUtils.indexOf(bonds[a1], 0, bondcnts[a1], a2);
        assert bondidx >= 0;
        bondtypes[a1][bondidx] = bondtype;
    }
    private void addNewBondLeftSide(int atom1idx, int atom2idx, byte bondtype) {
        int a1bondcnt = bondcnts[atom1idx];
        ArrayUtils.extendArrayIfFull(bonds, atom1idx, a1bondcnt+1);
        ArrayUtils.extendArrayIfFull(bondtypes, atom1idx, a1bondcnt+1);
        bonds[atom1idx][a1bondcnt] = atom2idx;
        bondtypes[atom1idx][a1bondcnt] = bondtype;
        bondcnts[atom1idx]++;
    }
    private boolean isConnected(int a1idx, int a2idx) {
        int bondCnt = getBondCnt(a1idx);
        int[] a1bonds = bonds[a1idx];
        for(int i = 0; i < bondCnt; i++)
            if(a1bonds[i] == a2idx)
                return true;
        return false;
    }
    private void assertBondExists(int aidx, int bidx) {
        if(getBondCnt(aidx) < bidx)
            throw new IndexOutOfBoundsException("Bond #" + bidx+" does not exist, there are only " + getBondCnt(aidx) + " bonds");
    }

}
