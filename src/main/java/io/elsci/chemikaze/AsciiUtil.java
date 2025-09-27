package io.elsci.chemikaze;

interface AsciiUtil {
    byte A = 'A', Z = 'Z', a = 'a', z = 'z', _0 = '0', _9 = '9';

    static boolean isDigit(byte b) {
        return between(b, _0, _9);
    }
    static boolean isAlphanumeric(byte b) {
        return between(b, _0, _9) || between(b, A, Z) || between(b, a, z);
    }
    static boolean isSmallLetter(byte b) {
        return between(b, a, z);
    }

    static boolean between(byte b, byte minInclusive, byte maxInclusive) {
        return b >= minInclusive && b <= maxInclusive;
    }
}
