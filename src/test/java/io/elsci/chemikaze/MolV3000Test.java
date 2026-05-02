package io.elsci.chemikaze;


import org.junit.Test;

import static io.elsci.chemikaze.CdkUtil.assertMoleculesEqual;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

public class MolV3000Test {
    @Test
    public void readsOne() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = MolV3000.readOne(mol);
        assertMoleculesEqual(CdkUtil.fromMolV3000(mol), m);
    }
    @Test
    @SuppressWarnings("DataFlowIssue")
    public void errsIfStructureIsEmtpy() {
        Exception e = assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne((String) null));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
        assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne(""));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
        assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne((byte[]) null));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
        assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne(new byte[0]));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
    }
}