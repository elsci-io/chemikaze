package io.elsci.chemikaze;

import java.util.HashSet;
import java.util.Set;

import static java.nio.charset.StandardCharsets.US_ASCII;

/**
 * Each element is represented by a number. This number is NOT its order in the periodic table, so treat it as just an
 * opaque ID. It was chosen so that popular elements had small values - so that if we have arrays of
 * elements - the filled values were all grouped at the beginning of the array.
 * <p>
 * The element is a {@code byte}, not an {@code int} - because the number of known elements is less than 128.
 * <p>
 */
public final class PeriodicTable {
    final static String[] SYMBOLS = new String[] { // all elements sorted by atomic number, not used at the moment
            "H", "He",
            "Li", "Be", "B", "C", "N", "O", "F", "Ne",
            "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar",
            "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr",
            "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe",
            "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Po", "At", "Rn",
            "Fr", "Ra", "Ac", "Th", "Pa", "U", "Np", "Pu", "Am", "Cm", "Bk", "Cf", "Es", "Fm", "Md", "No", "Lr", "Rf", "Db", "Sg", "Bh", "Hs", "Mt", "Ds", "Rg", "Cn", "Nh", "Fl", "Mc"
    };
    /**
     * These are actually used for MF. They are roughly sorted by popularity in organic chemistry. Well,
     * at least the first elements are. Doesn't contain elements that would never be used in organic chemistry.
     */
    final static String[] EARTH_SYMBOLS = new String[] {
            "H", "C", "O", "N", "P", "F", "S", "Br", "Cl", "Na", "Li", "Fe", "K", "Ca", "Mg", "Ni", "Al",
            "Pd", "Sc", "V", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B", "Kr",
            "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs",
            "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta",
            "Tc", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa", "U", "He", "Ne", "Ar"
    };
    // Keep symbols as bytes so that we don't have to turn them into String on each lookup.
    // Each symbol is 2 bytes: for 1-symbol elements like H, the 2nd byte is 0.
    private static final byte[][] EARTH_SYMBOLS_AS_BYTES = buildSymbolsAsBytes();

    /** The size of {@link #ELEMENTHASH_TO_ELEMENT} hash table*/
    private static final int INDEX_BUCKET_CNT = 512,
                             INDEX_HASH_MASK = INDEX_BUCKET_CNT - 1;
    private static final byte[/*element ID*/] ELEMENTHASH_TO_ELEMENT = buildIndex();

    static int getEarthElementCount() {
        return EARTH_SYMBOLS.length;
    }

    public static String getElementSymbol(byte element) {
        return EARTH_SYMBOLS[element];
    }

    /**
     * @param b0 1st byte of the symbol, e.g. "H" in He
     * @param b1 2nd byte of the symbol, e.g. "e" in He. If it's a 1-byte symbol, then 0.
     */
    public static byte getElementBySymbol(byte b0, byte b1) {
        byte elementIdx = ELEMENTHASH_TO_ELEMENT[hash(b0, b1)];
        byte[] symbol = EARTH_SYMBOLS_AS_BYTES[elementIdx];
        if(symbol[0] != b0 || symbol[1] != b1) {
            byte[] ascii = b1 == 0 ? new byte[] {b0} : new byte[]{b0, b1};
            throw new IllegalArgumentException("Unrecognized element: " + new String(ascii));
        }
        return elementIdx;
    }
    public static byte getElementBySymbol(String symbol) {
        byte[] bytes = symbol.getBytes(US_ASCII);
        int len = bytes.length;
        if(len == 0 || len > 2)
            throw new IllegalArgumentException("Unrecognized element: " + symbol);
        return len == 1 ? getElementBySymbol(bytes[0], (byte)0) : getElementBySymbol(bytes[0], bytes[1]);
    }

    public static int hash(String element) {
        return hash(element.getBytes(US_ASCII));
    }
    public static int hash(byte[] element) {
        return hash(element[0], element.length == 2 ? element[1] : 0);
    }
    public static int hash(byte b0, byte b1) {
        // Ran an experiment, and 277 is one of few multipliers that gave no collisions in 512-sized hash table.
        // Couldn't achieve the same with subtractions or shifts, no matter the order of b0 and b1.
        return ((b0 * 277) ^ b1) & INDEX_HASH_MASK;
    }

    private static byte[] buildIndex() {
        Set<Integer> takenBuckets = new HashSet<>(512);
        byte[] index = new byte[INDEX_BUCKET_CNT];
        for (int i = 0; i < EARTH_SYMBOLS.length; i++) {
            String element = EARTH_SYMBOLS[i];
            int bucket = hash(element);
            if(!takenBuckets.add(bucket))
                throw new IllegalStateException("The index of element symbols has collisions: "+bucket + " at the element #" + i);
            index[bucket] = (byte) i;
        }
        return index;
    }
    private static byte[][] buildSymbolsAsBytes() {
        byte[][] result = new byte[EARTH_SYMBOLS.length][];
        for (int i = 0; i < EARTH_SYMBOLS.length; i++) {
            byte[] bytes = EARTH_SYMBOLS[i].getBytes(US_ASCII);
            if(bytes.length == 2)
                result[i] = bytes;
            else
                result[i] = new byte[]{bytes[0], 0};
        }
        return result;
    }
}
