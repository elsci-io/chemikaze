package io.elsci.chemikaze.fgc;

import io.elsci.chemikaze.core.Smiles;
import org.junit.Test;

import static org.junit.Assert.assertArrayEquals;

public class FunctionalGroupsUllmannTest {
    @Test
    public void findsOneAlocohol() {
        assertArrayEquals(new int[][]{{1, 2}}, match("CCO", "CO"));
        assertArrayEquals(new int[][]{{4, 5}}, match("C1C=CC=C(N)C=1", "NC"));
    }

    private static int[][] match(String target, String query) {
        Smiles parser = new Smiles();
        return FunctionalGroups.create().match(parser.readOne(target), parser.readOne(query));
    }
}