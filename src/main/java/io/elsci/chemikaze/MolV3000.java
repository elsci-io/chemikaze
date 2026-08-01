package io.elsci.chemikaze;

import java.nio.charset.StandardCharsets;

import static java.lang.Character.isDigit;
import static java.lang.Math.max;
import static java.lang.Math.min;

/** <a href="https://www.daylight.com/meetings/mug05/Kappler/ctfile.pdf">CTFILE spec</a> */
public class MolV3000 {
    private static final byte[] BEGIN_CTAB = "M  V30 BEGIN CTAB\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] END_CTAB = "M  V30 END CTAB\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] END_MOLECULE = "M  END".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] COUNTS_LINE = "M  V30 COUNTS ".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] BEGIN_ATOM = "M  V30 BEGIN ATOM\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] BEGIN_BOND = "M  V30 BEGIN BOND\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] END_BOND_LINE = "M  V30 END BOND\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] END_BOND = "END BOND\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] END_ATOM = "M  V30 END ATOM\n".getBytes(StandardCharsets.US_ASCII);
    public static final byte[] LINE_START = "M  V30 ".getBytes(StandardCharsets.UTF_8);
    private static final byte NL = (byte) '\n';
    private int i;

    public Molecule readOne(String mol) {
        if(mol == null || mol.isEmpty())
            throw new InvalidChemStructureException(mol, "Can't parse empty chemical structure");
        return readOne(mol.getBytes(StandardCharsets.US_ASCII));
    }
    public Molecule readOne(byte[] mol) {
        if(mol == null || mol.length == 0)
            throw new InvalidChemStructureException("Can't parse empty chemical structure");
        if(mol.length < 178) // all the essential blocks like BEGIN CTAB, BEGIN ATOMS combined
            throw new InvalidChemStructureException(new String(mol, StandardCharsets.UTF_8), "Is not a proper MOL V3000 format");
        skipAfter(mol, NL);
        skipAfter(mol, NL);
        skipAfter(mol, NL);
        // for now skip the header too:
        skipAfter(mol, NL);
        skipOrThrow(mol, BEGIN_CTAB);
        skipOrThrow(mol, COUNTS_LINE);
        int atomCnt = readInt(mol);
        i++;//skip space
        int bondCnt = readInt(mol);
        skipAfter(mol, NL); // for now skip, we don't need the rest of the data
        // skipping the rest of the counts for now, will return to them later
        byte[] atoms = new byte[atomCnt];

        skipOrThrow(mol, BEGIN_ATOM);
        readAtoms(mol, atoms);
        skipOrThrow(mol, END_ATOM);

        Molecule m = Molecule.create(atoms);

        skipOrThrow(mol, BEGIN_BOND);
        readBonds(mol, bondCnt, m);
        skipOrThrow(mol, END_BOND_LINE);
        skipOrThrow(mol, END_CTAB);
        skipOrThrow(mol, END_MOLECULE);
        return m;
    }
    private void readBonds(byte[] mol, int bondCnt, Molecule m) {
        for (int j = 0; j < bondCnt; j++) {
            skipOrThrow(mol, LINE_START);
            try {
                readInt(mol); // not interested in the bond number
            } catch (NumberFormatException e) {
                if(isEqual(mol, END_BOND))
                    throw new InvalidChemStructureException("Bond Count is "+bondCnt+", while the actual number of bonds is "+j);
                throw e;
            }
            i++;//skip space
            byte bondtype = (byte) readInt(mol);
            i++;//skip space
            int atom1idx = assertAtomIdxValid(m, readInt(mol) - 1);
            i++;//skip space
            int atom2idx = assertAtomIdxValid(m, readInt(mol) - 1);
            m.setBond(atom1idx, atom2idx, bondtype);
            skipAfter(mol, NL);
        }
    }

    private static int assertAtomIdxValid(Molecule m, int atom1idx) {
        if (atom1idx < 0 || atom1idx >= m.getAtomCnt())
            throw new InvalidChemStructureException("One of the bonds referenced a non-existing atom number: " + (atom1idx+1));
        return atom1idx;
    }

    private void readAtoms(byte[] mol, byte[] atoms) {
        for(int j = 0; j < atoms.length; j++) {
            skipOrThrow(mol, LINE_START);
            int atomIdx;
            try {
                atomIdx = readInt(mol) - 1;
            } catch(NumberFormatException e) {
                throw new InvalidChemStructureException("Expected a line with atom, but got: '" +
                        getCurrentLineForError(mol) + "'. Is Atom Count from " + atoms.length + " correct? Or maybe atom position is less than 1?");
            }
            if(atomIdx < 0 || atomIdx >= atoms.length)
                throw new InvalidChemStructureException("Atoms #"+(j+1)+" had an invalid index (either less than 1 or greater than the atom count): " + (atomIdx+1));
            i++;//skip space
            try {
                atoms[atomIdx] = readChemSymbol(mol);
            } catch (InvalidElementException e) {
                throw new InvalidChemStructureException("Unrecognized element: " + e.element + " in the line '" + getCurrentLineForError(mol)+"'");
            }
            skipAfter(mol, NL);
        }
    }

    private byte readChemSymbol(byte[] mol) {
        return mol[i+1] == ' '
                ? PeriodicTable.getElementBySymbol(mol[i++], (byte) 0)
                : PeriodicTable.getElementBySymbol(mol[i++], mol[i++]);
    }
    private int readInt(byte[] mol) {
        int result = 0;
        int j = i;
        while(isDigit(mol[j]))
            result += (mol[j++] - '0') + result*10;
        if (i == j)
            throw new NumberFormatException("Not a number: " + new String(mol, i, 5));
        i = j;
        return result;
    }

    private boolean isEqual(byte[] mol, byte[] section) {
        if(i + section.length >= mol.length)
            return false;
        int j = 0;// character number within the line
        for(; j < section.length; j++)
            if(section[j] != mol[i+j])
                return false;
        return true;
    }
    private boolean skip(byte[] mol, byte[] section) {
        if(i + section.length >= mol.length)
            throw new InvalidChemStructureException(new String(mol, StandardCharsets.UTF_8),
                    "Not a valid MOLV3000 format - didn't find section: " + new String(section).trim()
                            + ". Instead the structure ended prematurely: " + new String(mol, i, mol.length - i).trim());
        int j = 0;// character number within the line
        for(; j < section.length; j++)
            if(section[j] != mol[i+j])
                return false;
        i += j;
        return true;
    }
    private void skipOrThrow(byte[] mol, byte[] section) {
        if(i + section.length >= mol.length)
            throw new InvalidChemStructureException(new String(mol, StandardCharsets.UTF_8),
                    "Not a valid MOLV3000 format - didn't find section: " + new String(section).trim()
                            + ". Instead the structure ended prematurely: " + new String(mol, i, mol.length - i).trim());
        int j = 0;// character number within the line
        for(; j < section.length; j++)
            if(section[j] != mol[i+j])
                throw new InvalidChemStructureException(new String(mol, StandardCharsets.UTF_8)
                        , "Not a valid MOLV3000 format - didn't find section: " + new String(section).trim()
                        + ". Instead got: " + new String(mol, i, section.length).trim());
        i += j;
    }

    private void skipAfter(byte[] data, byte b) {
        for(; i < data.length; i++)
            if(data[i] == b)
                break;
        i++;
    }

    private String getCurrentLineForError(byte[] data) {
        int leftLimit = max(0, i - 50);
        int left = i;
        for (; left >= leftLimit; left--) {
            if (data[left] == NL) {
                left++;
                break;
            }
        }

        int rightLimit = min(i+50, data.length); // byte[10], i = 8
        int right = i;
        while (right < rightLimit && data[right] != NL)
            right++;
        return new String(data, left, right-left);
    }
}
