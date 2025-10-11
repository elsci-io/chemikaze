package io.elsci.chemikaze;

import org.junit.Ignore;
import org.junit.Test;

import static java.nio.charset.StandardCharsets.US_ASCII;


public class PeriodicTableHashingTest {
    final static String[] EARTH_SYMBOLS = new String[]{
            "H", "C", "O", "N", "P", "F", "S", "Br", "Cl", "Na", "Li", "Fe", "K", "Ca", "Mg", "Ni", "Al",
            "Pd", "Sc", "V", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B", "Kr",
            "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs",
            "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta",
            "Tc", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa", "U", "He", "Ne", "Ar"
    };
    static final byte[][] EARTH_SYMBOLS_AS_BYTES = buildSymbolsAsBytes();
    static final int INDEX_BUCKET_CNT = 512;
    static final int INDEX_HASH_MASK = INDEX_BUCKET_CNT - 1;

    @Test
    @Ignore
    public void findPerfectHashFunction_withAddition() {
        for (int m = 0; m < 1000; m++) {
            boolean collision = false;
            boolean[] filled = new boolean[INDEX_BUCKET_CNT];
            for (byte[] earthSymbol : EARTH_SYMBOLS_AS_BYTES) {
                int hash = hash_add(earthSymbol[0], earthSymbol[1], m);
                if (filled[hash]) {
                    collision = true;
                    break;
                }
                filled[hash] = true;
            }
            if (!collision)
                System.out.println("Success with multiplier: " + m);
        }
    }

    @Test
    @Ignore
    public void findPerfectHashFunction_withMultiplication() {
        for (int m = 0; m < 1000000; m++) {
            boolean[] filled = new boolean[INDEX_BUCKET_CNT];
            boolean collision = false;
            for (byte[] earthSymbol : EARTH_SYMBOLS_AS_BYTES) {
                int hash = hash_mult(earthSymbol[0], earthSymbol[1], m);
                if (filled[hash]) {
                    collision = true;
                    break;
                }
                filled[hash] = true;
            }
            if (!collision)
                System.out.println("Success with subtract: " + m);
        }
    }

    @Test
    @Ignore
    public void findPerfectHashFunction_withShift() {
        for (int s = 0; s < 16; s++) {
            boolean[] filled = new boolean[INDEX_BUCKET_CNT];
            boolean collision = false;
            for (byte[] earthSymbol : EARTH_SYMBOLS_AS_BYTES) {
                int hash = hash_shift(earthSymbol[0], earthSymbol[1], s);
                if (filled[hash]) {
                    collision = true;
                    break;
                }
                filled[hash] = true;
            }
            if (!collision)
                System.out.println("Success with subtract: " + s);
        }
    }

    static int hash_mult(byte b0, byte b1, int hashMultiplier) {
        return ((b0 * hashMultiplier) ^ b1) & INDEX_HASH_MASK;
    }

    static int hash_add(byte b0, byte b1, int s) {
        return ((b1 + s) ^ b0) & INDEX_HASH_MASK;
    }

    static int hash_shift(byte b0, byte b1, int s) {
        return ((b0 << s) ^ b1) & INDEX_HASH_MASK;
    }

    private static byte[][] buildSymbolsAsBytes() {
        byte[][] result = new byte[EARTH_SYMBOLS.length][];
        for (int i = 0; i < EARTH_SYMBOLS.length; i++) {
            byte[] bytes = EARTH_SYMBOLS[i].getBytes(US_ASCII);
            if (bytes.length == 2)
                result[i] = bytes;
            else
                result[i] = new byte[]{bytes[0], 0};
        }
        return result;
    }
}