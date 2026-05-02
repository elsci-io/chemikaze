package io.elsci.chemikaze;

import java.nio.charset.StandardCharsets;

public class MolV3000 {
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
        return null;
    }
}
