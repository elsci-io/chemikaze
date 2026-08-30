package io.elsci.chemikaze.fgc;

import io.elsci.chemikaze.core.Molecule;

import java.util.Arrays;

// TODO:
//  - Find all the matching paths, not just the first one
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
            if(dfs(target, targetAtom, query, 0, atommap, 0)) {
                Arrays.sort(atommap);
                return new int[][]{atommap};
            }
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
    private boolean dfs(Molecule target, int targetatom, Molecule query, int queryatom, int[] atommap, int mappedCnt) {
        atommap[queryatom] = targetatom;
        if(++mappedCnt == atommap.length) // visited all the query atoms already?
            return true;
        int bondCnt = query.getBondCnt(queryatom);
        for (int b = 0; b < bondCnt; b++) {
            int queryNeighbor = query.getConnectedAtom(queryatom, b);
            if (atommap[queryNeighbor] != UNMAPPED) // has been visited and mapped already
                continue;
            for (int targetbond = 0; targetbond < target.getBondCnt(targetatom); targetbond++){
                int targetNeighbor = target.getConnectedAtom(targetatom, targetbond);
                if (target.getElement(targetNeighbor) == query.getElement(queryNeighbor))
                    if(dfs(target, targetNeighbor, query, queryNeighbor, atommap, mappedCnt))
                        return true;
            }
        }
        return false;
    }
}
