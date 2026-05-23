package io.elsci.chemikaze;

import java.nio.charset.StandardCharsets;

import static java.lang.Character.isDigit;

/** <a href="https://www.daylight.com/meetings/mug05/Kappler/ctfile.pdf">CTFILE spec</a> */
public class MolV3000 {
    private static final byte[] BEGIN_CTAB = "M  V30 BEGIN CTAB\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] COUNTS_LINE = "M  V30 COUNTS ".getBytes(StandardCharsets.US_ASCII);
    private static final byte NL = (byte) '\n';

    public static Molecule readOne(String mol) {
        if(mol == null || mol.isEmpty())
            throw new InvalidChemStructureException(mol, "Can't parse empty chemical structure");
        return readOne(mol.getBytes(StandardCharsets.US_ASCII));
    }
    public static Molecule readOne(byte[] mol) {
        if(mol == null || mol.length == 0)
            throw new InvalidChemStructureException("Can't parse empty chemical structure");
        if(mol.length < 178) // all the essential blocks like BEGIN CTAB, BEGIN ATOMS combined
            throw new InvalidChemStructureException(new String(mol, StandardCharsets.UTF_8), "Is not a proper MOL V3000 format");
        int i = indexOf(mol, NL, 0);
        i = indexOf(mol, NL, i)+1;
        i = indexOf(mol, NL, i)+1;
        // for now skip the header too:
        i = indexOf(mol, NL, i+1)+1;
        i = assertEqual(mol, i, BEGIN_CTAB);
        i = assertEqual(mol, i, COUNTS_LINE);
        int lineEnd = indexOf(mol, NL, i);
        if (lineEnd - i < 9)
            throw new InvalidChemStructureException("Not a valid MOLV3000 format - COUNTS line ended prematurely: " + new String(mol, i, lineEnd-i));

        int atomCnt = readInt(mol, i);
        Molecule m = new Molecule();
        m.atoms = new byte[atomCnt];
        return m;
    }

    private static int readInt(byte[] mol, int offset) {
        int result = 0;
        while(isDigit(mol[offset]))
            result += (mol[offset++] - '0') + result*10;
        return result;
    }

    private static int assertEqual(byte[] mol, int i, byte[] section) {
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
        return i + j;
    }

    private static int indexOf(byte[] data, byte b, int startOffset) {
        for(int i = startOffset; i < data.length; i++)
            if(data[i] == b)
                return i;
        return -1;
    }
}
