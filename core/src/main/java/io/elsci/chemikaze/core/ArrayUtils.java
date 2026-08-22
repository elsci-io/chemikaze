package io.elsci.chemikaze.core;

interface ArrayUtils {
    static int indexOf(int[] array, int fromIdx, int toIdxExclusive, int val) {
        for (int i = 0; i < toIdxExclusive; i++)
            if(array[i] == val)
                return i;
        return -1;
    }
    static boolean contains(byte[] bytes, byte b) {
        for (byte next : bytes)
            if(next == b)
                return true;
        return false;
    }

    static boolean extendArrayIfFull(int[][] array, int arrayidx, int ensureLength) {
        if(array[arrayidx].length >= ensureLength)
            return false;
        int[] newarray = new int[ensureLength];
        System.arraycopy(array[arrayidx], 0, newarray, 0, array[arrayidx].length);
        array[arrayidx] = newarray;
        return true;
    }
    static boolean extendArrayIfFull(byte[][] array, int arrayidx, int ensureLength) {
        if(array[arrayidx].length >= ensureLength)
            return false;
        byte[] newarray = new byte[ensureLength];
        System.arraycopy(array[arrayidx], 0, newarray, 0, array[arrayidx].length);
        array[arrayidx] = newarray;
        return true;
    }
}
