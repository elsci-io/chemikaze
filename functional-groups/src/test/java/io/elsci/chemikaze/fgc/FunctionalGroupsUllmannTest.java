package io.elsci.chemikaze.fgc;

import io.elsci.chemikaze.core.Smiles;
import org.junit.Test;

import static org.junit.Assert.assertArrayEquals;

public class FunctionalGroupsUllmannTest {
    @Test
    public void findsOneAlocohol() {
        assertArrayEquals(new int[][]{{1, 2}}, match("CCO", "CO"));
//        assertArrayEquals(new int[][]{{2, 1}}, match("CCCO", "CO"));
    }

    private static int[][] match(String target, String query) {
        Smiles parser = new Smiles();
        return FunctionalGroups.create().match(parser.readOne(target), parser.readOne(query));
    }
}