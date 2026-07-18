package io.elsci.chemikaze;

/**
 * Can be an actual molecule or a multiple unconnected compoonents (like a salt). Has a list of atoms, as well as
 * bonnds between them.
 * <p>
 * <a href="./README.md">Design decisions</a>
 */
public class MoleculeBase1Bonds4Array {
    /** Use {@code PeriodicTable.SYMBOLS[atom]} to conver it to human-readable name. */
    byte[] atoms;
    int[] bonds;
    byte[] bondtypes;

    public MoleculeBase1Bonds4Array(byte[] atoms) {
        this.atoms = new byte[atoms.length+1];
        System.arraycopy(atoms, 0, this.atoms, 1, this.atoms.length);
        bonds = new int[this.atoms.length*4 + 1];
        bondtypes = new byte[bonds.length];
    }

    public byte getAtom(int idx) {
        return atoms[idx+1];
    }

    public int getAtomCount() {
        return atoms.length-1;
    }
    public int isConnected(int atomIdx0, int atomIdx1) {
        throw new UnsupportedOperationException();
    }

    public int getBond(int atomIdx, int bondIdx) {
        if(bondIdx > 4)
            throw new IndexOutOfBoundsException("We don't yet support more than 4 bonds");
        int atom = bonds[atomIdx * 4 + bondIdx];
        if (atom == 0)
            throw new IndexOutOfBoundsException("Bond #" + bondIdx+" does not exist, there are only " + getBondCount(atomIdx) + " bonds");
        return atom;
    }

    public int getBondCount(int atomIdx) {
        int cnt = 0;
        int startIdx = atomIdx * 4;
        int endIdx = startIdx + 4;
        for (int i = startIdx; i < endIdx && bonds[atomIdx] != 0; i++)
            cnt++;
        return cnt;
    }
}
