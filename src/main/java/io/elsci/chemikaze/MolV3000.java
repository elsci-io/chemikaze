package io.elsci.chemikaze;

import java.nio.charset.StandardCharsets;

/** <a href="https://www.daylight.com/meetings/mug05/Kappler/ctfile.pdf">CTFILE spec</a> */
public class MolV3000 {
    private static final byte[] BEGIN_CTAB = "M  V30 BEGIN CTAB\n".getBytes(StandardCharsets.US_ASCII);
    private static final String COUNTS_LINE = "M  V30 COUNTS ";

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
        int i = indexOf(mol, (byte) '\n', 0);
        i = indexOf(mol, (byte) '\n', i)+1;
        i = indexOf(mol, (byte) '\n', i)+1;
        // for now skip the header too:
        i = indexOf(mol, (byte) '\n', i+1)+1;
        i = assertEqual(mol, i, BEGIN_CTAB);
        return null;
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
