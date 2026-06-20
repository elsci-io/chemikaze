package io.elsci.chemikaze;


import org.junit.Ignore;
import org.junit.Test;

import static io.elsci.chemikaze.CdkUtil.assertMoleculesEqual;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

public class MolV3000Test {
    @Test
    public void readsOne() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertMoleculesEqual(CdkUtil.fromMolV3000(mol), m);
    }
    @Test
    public void readsAtomCntLine() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(1, m.getAtomCount());
    }
    @Test
    public void readsAtoms() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(1, m.getAtomCount());
        assertEquals(PeriodicTable.getElementBySymbol("C"), m.atoms[0]);
    }
    @Test
    public void readsMultipleAtoms() {
        String mol = IoUtils.getStringFromClasspath("molecules/co.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(2, m.getAtomCount());
        assertEquals(PeriodicTable.getElementBySymbol("O"), m.atoms[0]);
        assertEquals(PeriodicTable.getElementBySymbol("C"), m.atoms[1]);
    }
    @Test
    @SuppressWarnings("DataFlowIssue")
    public void errsIfStructureIsEmtpy() {
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol((String) null));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
        assertThrows(InvalidChemStructureException.class, () -> readMol(""));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
        assertThrows(InvalidChemStructureException.class, () -> readMol((byte[]) null));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
        assertThrows(InvalidChemStructureException.class, () -> readMol(new byte[0]));
        assertEquals("Can't parse empty chemical structure", e.getMessage());
    }
    @Test
    public void errsIfNoBeginCtabBlock() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        String section = "M  V30 BEGIN CTAB\n";
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "m  V30 BEGIN CTAB\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB\n. Instead got: m  V30 BEGIN CTAB\n", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB\n. Instead got: \nM  V30 COUNTS 1 0", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, section.substring(0, section.length() - 1))));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB\n. Instead got: M  V30 BEGIN CTABM", e.getMessage());
    }
    @Test
    public void errsIfNoBeginAtomBlock() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        String section = "M  V30 BEGIN ATOM\n";

        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "m  V30 BEGIN ATOM\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN ATOM\n. Instead got: m  V30 BEGIN ATOM\n", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN ATOM\n. Instead got: \nM  V30 1 C 12.225", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, section.substring(0, section.length() - 1))));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN ATOM\n. Instead got: M  V30 BEGIN ATOMM", e.getMessage());
    }
    @Test
    public void errsIfNoCountsLine() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace("M  V30 COUNTS ", "m  V30 COUNTS ")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 COUNTS . Instead got: m  V30 COUNTS ", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace("M  V30 COUNTS ", "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 COUNTS . Instead got: \n" +
                "1 0 0 0 0\nM  ", e.getMessage());
    }
    @Test @Ignore
    public void errsIfCountsLineIsIncomplete() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace("M  V30 COUNTS 1 0 0 0 0", "M  V30 COUNTS 1 0 0 0 ")));
        assertEquals("Invalid structure: Not a valid MOLV3000 format - COUNTS line ended prematurely: 1 0 0 0 ", e.getMessage());
    }

    private static Molecule readMol(String mol) {
        return new MolV3000().readOne(mol);
    }
    private static Molecule readMol(byte[] mol) {
        return new MolV3000().readOne(mol);
    }
}