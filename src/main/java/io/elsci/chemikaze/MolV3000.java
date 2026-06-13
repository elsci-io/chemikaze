package io.elsci.chemikaze;

import java.nio.charset.StandardCharsets;

import static java.lang.Character.isDigit;

/** <a href="https://www.daylight.com/meetings/mug05/Kappler/ctfile.pdf">CTFILE spec</a> */
public class MolV3000 {
    private static final byte[] BEGIN_CTAB = "M  V30 BEGIN CTAB\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] COUNTS_LINE = "M  V30 COUNTS ".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] BEGIN_ATOM = "M  V30 BEGIN ATOM\n".getBytes(StandardCharsets.US_ASCII);
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
        assertEqual(mol, BEGIN_CTAB);
        assertEqual(mol, COUNTS_LINE);
        int atomCnt = readInt(mol);
        skipAfter(mol, NL); // for now skip, we don't need the rest of the data
        // skipping the rest of the counts for now, will return to them later
        Molecule m = new Molecule();
        m.atoms = new byte[atomCnt];

        assertEqual(mol, BEGIN_ATOM);
        readAtoms(mol, m);
        return m;
    }

    private void readAtoms(byte[] mol, Molecule m) {
        assertEqual(mol, LINE_START);
        int atomIdx = readInt(mol) - 1;
        i++;
        m.atoms[atomIdx] = readChemSymbol(mol);
        // todo: next read other atoms
    }

    private byte readChemSymbol(byte[] mol) {
        return mol[i+1] == ' '
                ? PeriodicTable.getElementBySymbol(mol[i++], (byte) 0)
                : PeriodicTable.getElementBySymbol(mol[i++], mol[i++]);
    }
    private int readInt(byte[] mol) {
        int result = 0;
        while(isDigit(mol[i]))
            result += (mol[i++] - '0') + result*10;
        return result;
    }

    private void assertEqual(byte[] mol, byte[] section) {
        if(i + section.length >= mol.length)
            throw new InvalidChemStructureException(new String(mol, StandardCharsets.UTF_8),
                    "Not a valid MOLV3000 format - didn't find section: " + new String(section)
                            + ". Instead the structure ended prematurely: " + new String(mol, i, mol.length - i));
        int j = 0;// character number within the line
        for(; j < section.length; j++)
            if(section[j] != mol[i+j])
                throw new InvalidChemStructureException(new String(mol, StandardCharsets.UTF_8)
                        , "Not a valid MOLV3000 format - didn't find section: " + new String(section)
                        + ". Instead got: " + new String(mol, i, section.length));
        i += j;
    }

    private void skipAfter(byte[] data, byte b) {
        for(; i < data.length; i++)
            if(data[i] == b)
                break;
        i++;
    }
}
