package io.elsci.chemikaze;

interface ArrayUtils {

    static boolean isElementEqual(byte[] found, byte[] element) {
        if(found[0] != element[0])
            return false;
        if(found.length != element.length)
            return false;
        return found.length != 2 || found[1] == element[1];
    }
    static boolean contains(byte[] bytes, byte b) {
        for (byte next : bytes)
            if(next == b)
                return true;
        return false;
    }
}
