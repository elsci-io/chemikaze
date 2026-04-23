package io.elsci.chemikaze;

import java.nio.charset.StandardCharsets;

public class MolV3000 {
    public static Molecule readOne(String mol) {
        return readOne(mol.getBytes(StandardCharsets.US_ASCII));
    }
    public static Molecule readOne(byte[] mol) {
        return null;
    }
}
