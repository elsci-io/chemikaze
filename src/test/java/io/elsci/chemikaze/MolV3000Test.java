package io.elsci.chemikaze;


import org.junit.Test;

import static io.elsci.chemikaze.CdkUtil.assertMoleculesEqual;

public class MolV3000Test {
    @Test
    public void readsOne() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = MolV3000.readOne(mol);
        assertMoleculesEqual(CdkUtil.fromMolV3000(mol), m);
    }
}