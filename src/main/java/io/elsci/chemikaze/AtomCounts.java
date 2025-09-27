package io.elsci.chemikaze;

public class AtomCounts {
    final int[] counts;

    public AtomCounts(int[] counts) {
        this.counts = counts;
    }

    public String toMf() {
        StringBuilder sb = new StringBuilder();
        for (byte i = 0; i < counts.length; i++) {
            if (counts[i] == 0)
                continue;
            sb.append(PeriodicTable.getElementSymbol(i));
            if (counts[i] > 1)
                sb.append(counts[i]);
        }
        return sb.toString();
    }
}
