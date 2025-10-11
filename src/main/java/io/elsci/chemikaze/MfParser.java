package io.elsci.chemikaze;


import static io.elsci.chemikaze.AsciiUtil.*;
import static java.nio.charset.StandardCharsets.US_ASCII;

/**
 * Parses Molecular formulas of formats: {@code H2O, 2H2O, (H2O)2, H2O.4NaCl, (H2O.(NaCl)3)2}.
 * Not Thread Safe! Don't reuse the same instance in multiple threads!
 */

// Design/conventions:
// * `startMf` (inclusive) & `endMf` (exclusive) determine the part of mf that we actually parse. In case MF
//    comprises not the whole string/bytes that were passed to us, but is only part of it. E.g. start/end won't
//    correspond to the beginning or the end of the string if there are whitespaces to trim; or if we're parsing a
//    a big file in which case start/end could be somewhere in the middle of the file.
// * Many methods accept mf, startMf, endMf - it's a single unit that we parse, and it can be considered as a single
//   parameter
public class MfParser {
    private final static byte[] MF_PUNCTUATION = new byte[]{'(', ')', '+', '-', '.', '[', ']'};
    /**
     * Points to the current character in MF that we're looking at. It's shared across methods,
     * so that each of them could increment it - we say it "consumed" that byte.
     */
    private int i = 0;

    public AtomCounts parseMf(String mf) {
        return parseMf(mf.getBytes(US_ASCII));
    }
    public AtomCounts parseMf(byte[] mf/*MF encoded in ASCII*/) {
        return parseMf(mf, indexOfStart(mf), indexOfEnd(mf));
    }

    /**
     * @param mf ASCII bytes with the molecular formula inside. The MF could take the whole array, or it could be in
     *           the middle - so use other params to tell the offset and where it ends.
     * @param mfStart index where the MF actually starts in the array
     * @param mfEnd index (exclusive) where the MF actually ends in the array
     */
    public AtomCounts parseMf(byte[] mf, int mfStart, int mfEnd) {
        // We create 2 arrays that contain some of the info about what each of the symbol in MF corresponds to:
        // 1.a `elements[]` is filled where we could parse out the symbol. The values correspond to the order of
        //    elements in PeriodicTable.EARTH_SYMBOLS.
        // 1.b `coefficients[]` that go after the element. This doesn't include the group coefficients (at the beginning
        //    of a MF chunk or after parenthesis).
        // 1.c We end up with 2 arrays that partially contain the info about elements. Example for 2H2O.(NaCl)5:
        //     MF:       2|H|2|O|.|(|N|a|C|l|)|5
        //     Elements: 0|0|0|2|0|0|9|0|8|0|0|0
        //     Coeffs:   0|2|0|1|0|0|1|0|1|0|0|0
        // 2. Then process the group coefficients and multiply the "coefficients" by them - that's the resulting coeffs:
        //    MF (hiding chars that we don't care about anymore): 2|*|*|*|.|(|*|*|*|*|)|5
        //    Coeffs (before):                                    0|2|0|1|0|0|1|0|1|0|0|0
        //    Coeffs (after multiplication by group coeffs):      0|4|0|2|0|0|5|0|5|0|0|0
        // 3. Finally, step through each coefficient, and combine it with the element info into the resulting AtomCounts
        int[] coefficients = new int[mfEnd - mfStart];
        byte[] elements = new byte[mfEnd - mfStart]; // elements that correspond to the symbols
        readSymbolsAndCoeff(mf, mfStart, mfEnd, elements, coefficients);
        findAndApplyGroupCoeff(mf, mfStart, mfEnd, coefficients);
        return new AtomCounts(combineIntoAtomCounts(elements, coefficients));
    }

    private void readSymbolsAndCoeff(byte[] mf, int mfStart, int mfEnd,
                                     byte[] resultElem, int[] resultCoeff) {
        for (i = mfStart; i < mfEnd;)
            if (between(mf[i], A, Z))
                consumeSymbolAndCoefficient(mf, mfStart, mfEnd, resultElem, resultCoeff);
            // there are only 7 punctuation signs, so hopefully JVM vectorizes and turns it into 1 comparison
            else if(ArrayUtils.contains(MF_PUNCTUATION, mf[i]) || isDigit(mf[i]))// digit - meaning (xx)N or Nxx
                i++;
            else
                throw new IllegalArgumentException("Invalid Molecular Formula: " + new String(mf, mfStart, mfEnd-mfStart));
    }

    /**
     * There are 2 types of group coefficients:
     * <ul>
     *     <li>At the beginning: 5Cl or O.5Cl - for this we run {@link #scaleForward(byte[], int, int, int, int, int[], int)}</li>
     *     <li>After parenthesis: (CO)2 - for this we run {@link #scaleBackward(byte[], int, int, int, int[], int)}</li>
     * </ul>
     */
    private void findAndApplyGroupCoeff(byte[] mf, int mfStart, int mfEnd,
                                        int[] resultCoeff) {
        int currStackDepth = 0;
        out: for (i = mfStart; i < mfEnd;) {
            scaleForward(mf, mfStart, mfEnd, i, currStackDepth, resultCoeff, consumeMultiplier(mf, mfEnd));
            if(i == mfEnd)
                break;
            while(isAlphanumeric(mf[i])) // skip all letters, numbers, dots
                if(++i >= mfEnd)
                    break out;
            if(mf[i] == '(')
                currStackDepth++;
            else if (mf[i] == ')') {
                int chunkEnd = i - 1;
                i++;
                int groupCoeff = consumeMultiplier(mf, mfEnd);
                scaleBackward(mf, mfStart, chunkEnd, currStackDepth--, resultCoeff, groupCoeff);
                continue; // we incremented i++ inside scaleBackward()
            }
            i++;// happens on these: (.[]+
        }
        if(currStackDepth != 0)
            throw new IllegalArgumentException(
                    "The opening and closing parentheses don't match: " + new String(mf));
    }

    private void consumeSymbolAndCoefficient(byte[] mf, int mfStart, int mfEnd,
                                             byte[] resultElem, int[] resultCoeff) {
        int elementStart = i - mfStart;
        byte b0 = mf[i],
             b1 = 0;
        if(++i < mfEnd && isSmallLetter(mf[i]))// we didn't reach the end and the next byte is small letter
            b1 = mf[i++];// increment so that consumeMultiplier() starts parsing the coefficient next
        resultElem[elementStart] = PeriodicTable.getElementBySymbol(b0, b1);
        resultCoeff[elementStart] = consumeMultiplier(mf, mfEnd)/*can handle if i is out of bounds*/;
    }

    /**
     * @param lo the index inside mf where we start applying {@code groupCoeff} and go right from there
     */
    private void scaleForward(byte[] mf, int mfStart, int mfEnd, int lo,
                              int currStackDepth, int[] resultCoeff, int groupCoeff) {
        if (groupCoeff == 1)
            return;// usually the case, as people rarely put coefficients in front of MF
        int depth = currStackDepth;
        for (; lo < mfEnd && depth >= currStackDepth; lo++) {
            if     (mf[lo] == '(') depth++;
            else if(mf[lo] == ')') depth--;
            else if(mf[lo] == '.' && depth == currStackDepth)
                break;
            resultCoeff[lo - mfStart] *= groupCoeff;
        }
    }

    /**
     * @param hi index in mf where we start applying {@code groupCoeff} and go left from there
     */
    private void scaleBackward(byte[] mf, int mfStart, int hi/*inclusive*/,
                               int currStackDepth, int[] resultCoeff, int groupCoeff) {
        int depth = currStackDepth;
        for (; hi >= mfStart && depth <= currStackDepth; hi--) {
            if     (mf[hi] == '(') depth++;
            else if(mf[hi] == ')') depth--;
            resultCoeff[hi - mfStart] *= groupCoeff;
        }
    }

    private int consumeMultiplier(byte[] mf, int mfEnd) {// reads a number starting from current position, if no number then 1 is returned
        if(i >= mfEnd || !isDigit(mf[i]))
            return 1;
        int multiplier = 0;
        for (; i < mfEnd && isDigit(mf[i]); i++) // parse the number
            multiplier = multiplier * 10 + (mf[i] - _0);
        return multiplier;
    }
    private int[] combineIntoAtomCounts(byte[] elements, int[] coefficients) {
        int[] counts = new int[PeriodicTable.getEarthElementCount()];
        int len = coefficients.length;
        for (i = 0; i < len; i++)
            if(coefficients[i] != 0)
                counts[elements[i]] += coefficients[i];
        return counts;
    }

    private static int indexOfEnd(byte[] mf) {
        int i = mf.length - 1;
        while(i >= 0 && mf[i] == ' ')
            i--;
        return ++i;// the end is exclusive
    }
    private static int indexOfStart(byte[] mf) {
        int i = 0;
        while(mf[i] == ' ')
            i++;
        return i;
    }
}
