package io.elsci.chemikaze.core;

public class MoleculeSimple implements Molecule {
    byte[] elements;
    byte[] bondcnts;
    int[][] neighbors;
    byte[][] bondtypes;

    public MoleculeSimple(byte[] elements) {
        this.elements = elements;
        this.bondcnts = new byte[elements.length];
        this.neighbors = new int[elements.length][4];
        this.bondtypes = new byte[elements.length][4];
    }

    public byte getElement(int atom) {
        return elements[atom];
    }
    public int getAtomCnt() {
        return elements.length;
    }
    public int getBondCnt(int atom) {
        return bondcnts[atom];
    }
    public byte getBondType(int atom, int bond) {
        assertBondExists(atom, bond);
        return bondtypes[atom][bond];
    }
    public void setBond(int a1, int a2, byte bondtype) {
        int bond = ArrayUtils.indexOf(neighbors[a1], 0, bondcnts[a1], a2);
        if(bond >= 0) {
            setBondTypeLeftSide(a1, a2, bondtype);
            setBondTypeLeftSide(a2, a1, bondtype);
        } else {
            addNewBondLeftSide(a1, a2, bondtype);
            addNewBondLeftSide(a2, a1, bondtype);
        }
        assert isConnected(a1, a2);
    }
    public int getConnectedAtom(int atom, int bond) {
        assertBondExists(atom, bond);
        return neighbors[atom][bond];
    }

    /**
     * Atoms bond with each other bidirectionally, but this helper func adds the bond only to one side. Call it by
     * passing x and y, then y and x - and you got yourself a bidi connection.
     */
    private void setBondTypeLeftSide(int a1, int a2, byte bondtype) {
        int bond = ArrayUtils.indexOf(neighbors[a1], 0, bondcnts[a1], a2);
        assert bond >= 0;
        bondtypes[a1][bond] = bondtype;
    }
    private void addNewBondLeftSide(int a1, int a2, byte bondtype) {
        int a1bondcnt = bondcnts[a1];
        ArrayUtils.extendArrayIfFull(neighbors, a1, a1bondcnt+1);
        ArrayUtils.extendArrayIfFull(bondtypes, a1, a1bondcnt+1);
        neighbors[a1][a1bondcnt] = a2;
        bondtypes[a1][a1bondcnt] = bondtype;
        bondcnts[a1]++;
    }
    private boolean isConnected(int a1, int a2) {
        int bondCnt = getBondCnt(a1);
        int[] a1neighbors = neighbors[a1];
        for(int i = 0; i < bondCnt; i++)
            if(a1neighbors[i] == a2)
                return true;
        return false;
    }
    private void assertBondExists(int atom, int bond) {
        if(getBondCnt(atom) < bond)
            throw new IndexOutOfBoundsException("Bond #" + bond+" does not exist, there are only " + getBondCnt(atom) + " bonds");
    }

}
