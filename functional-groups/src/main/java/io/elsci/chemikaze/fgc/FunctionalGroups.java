package io.elsci.chemikaze.fgc;

import io.elsci.chemikaze.core.Molecule;

public interface FunctionalGroups {
    int[][] match(Molecule target, Molecule query);

    static FunctionalGroups create() {
        return new FunctionalGroupsUllmann();
    }
}
