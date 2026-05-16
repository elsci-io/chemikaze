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
    @Test
    public void errsIfNoBeginCtabBlock() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        String section = "M  V30 BEGIN CTAB\n";
        Exception e = assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne(mol.replace(section, "m  V30 BEGIN CTAB")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB\n. Instead got: m  V30 BEGIN CTABM", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne(mol.replace(section, "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB\n. Instead got: \n" +
                "M  V30 COUNTS 1 0", e.getMessage());
    }
    @Test
    public void errsIfNoCountsLine() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne(mol.replace("M  V30 COUNTS ", "m  V30 COUNTS ")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 COUNTS . Instead got: m  V30 COUNTS ", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> MolV3000.readOne(mol.replace("M  V30 COUNTS ", "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 COUNTS . Instead got: \n" +
                "1 0 0 0 0\nM  ", e.getMessage());
    }
}