package io.elsci.chemikaze;

import java.util.*;

import static java.nio.charset.StandardCharsets.US_ASCII;

/**
 * Each element is represented by a number. This number is NOT its order in the periodic table, so treat it as just an
 * opaque ID. It was chosen so that popular elements end up having a small value - so that if we have arrays of
 * elements - the filled values were all grouped at the beginning of the array.
 * <p>
 * The element is a {@code byte}, not an {@code int} - because the number of known elements is less than 128.
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
     * These are actually used for MF everything. They are roughly sorted by popularity in organic chemistry. Well,
     * at least the first elements are. Doesn't contain elements that would never be used in organic chemistry.
     */
    final static String[] EARTH_SYMBOLS = new String[] {
            "H", "C", "O", "N", "P", "F", "S", "Br", "Cl", "Na", "Li", "Fe", "K", "Ca", "Mg", "Ni", "Al",
            "Pd", "Sc", "V", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B", "Kr",
            "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs",
            "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta",
            "Tc", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa", "U", "He", "Ne", "Ar"
    };
    /** Optimization so that we don't have to turn byte[] into String */
    static final byte[][] EARTH_SYMBOLS_AS_BYTES = buildSymbolsAsBytes();
    /** The size of {@link #ELEMENTHASH_TO_ELEMENT} */
    static final int INDEX_BUCKET_CNT = 512;
    static final byte[/*element ID*/] ELEMENTHASH_TO_ELEMENT = buildIndex();

    static int getEarthElementCount() {
        return EARTH_SYMBOLS.length;
    }
    public static String getElementSymbol(byte element) {
        return EARTH_SYMBOLS[element];
    }
    public static byte getElementBySymbol(byte[] symbol) {
        int bucket = hash(symbol);
        byte elementIdx = ELEMENTHASH_TO_ELEMENT[bucket];
        if(!ArrayUtils.isElementEqual(EARTH_SYMBOLS_AS_BYTES[elementIdx], symbol))
            throw new IllegalArgumentException("Unrecognized element: " + new String(symbol));
        return elementIdx;
    }
    public static byte getElementBySymbol(String symbol) {
        return getElementBySymbol(symbol.getBytes(US_ASCII));
    }

    static int hash(String element) {
        return hash(element.getBytes(US_ASCII), 23, 2);
    }
    static int hash(byte[] element) {
        return hash(element, 23, 2);
    }
    static int hash(String element, int hashMultiplier, int subtract) {
        return hash(element.getBytes(US_ASCII), hashMultiplier, subtract);
    }
    static int hash(byte[] element, int hashMultiplier, int subtract) {
        return element.length == 1
            ? element[0]-'A'
            : (element[0]*hashMultiplier + element[1])&0x01FF;
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
        for (int i = 0; i < EARTH_SYMBOLS.length; i++)
            result[i] = EARTH_SYMBOLS[i].getBytes(US_ASCII);
        return result;
    }
}
