package io.elsci.chemikaze.fgc;

import io.elsci.chemikaze.core.Molecule;

import java.util.Arrays;

// TODO:
//  - Do the actual matching of elements and filling the connection map
//  - Query isn't necessarily just a structure, it may be something more sophisticated like match any element on
//    the list or match N that has some specific bond number / type
//
public class FunctionalGroupsUllmann implements FunctionalGroups {
    private static final int UNMAPPED = -1;

    public int[][] match(Molecule target, Molecule query) {
        int queryElement = query.getElement(0);
        for (int targetAtom = 0; targetAtom < target.getAtomCnt(); targetAtom++) {
            if (queryElement != target.getElement(targetAtom))
                continue;
            int[] atommap = new int[query.getAtomCnt()];
            Arrays.fill(atommap, UNMAPPED);
            dfs(target, targetAtom, query, 0, atommap);
        }
        return new int[0][];
    }

    /**
     *
     * @param target molecule we search in
     * @param targetatom the atom of the target molecule we're currently navigating from
     * @param query the substructure that we're looking for
     * @param queryatom the atom of the substructure we're currently navigating from
     * @param atommap the result of the mapping between the target molecule and the substructure. The position (index)
     *                of the element represent the atom index of the query, while the value is the index of the target
     *                atom. It's filled with -1 initially, and as we find more atoms that match the query we fill more
     *                indices.
     */
    private void dfs(Molecule target, int targetatom, Molecule query, int queryatom, int[] atommap) {
        atommap[queryatom] = targetatom;
        System.out.println(queryatom);
        int bondCnt = query.getBondCnt(queryatom);
        for (int b = 0; b < bondCnt; b++) {
            int connectedAtom = query.getConnectedAtom(queryatom, b);
            if (atommap[connectedAtom] != UNMAPPED) // has been visited and mapped already
                continue;
            for (int targetbond = 0; targetbond < target.getBondCnt(targetatom); targetbond++)
                 // todo:
                 //  - check if the target atom has been visited and mapped already
                 //  - do the actual match between the queryelement and targetelement
                 dfs(target, target.getConnectedAtom(targetatom, targetbond), query, connectedAtom, atommap);
        }
    }
}
