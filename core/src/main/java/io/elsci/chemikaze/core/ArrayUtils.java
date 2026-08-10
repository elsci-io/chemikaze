package io.elsci.chemikaze.core;

interface ArrayUtils {
    static boolean contains(byte[] bytes, byte b) {
        for (byte next : bytes)
            if(next == b)
                return true;
        return false;
    }
}
