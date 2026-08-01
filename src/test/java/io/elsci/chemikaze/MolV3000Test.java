package io.elsci.chemikaze;


import org.junit.Ignore;
import org.junit.Test;

import static io.elsci.chemikaze.CdkUtil.assertMoleculesEqual;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

public class MolV3000Test {
    @Test
    public void readsMethaneWithoutExplicitBonds() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(1, m.getAtomCnt());
        assertEquals(0, m.getBondCnt(0));
        assertMoleculesEqual(CdkUtil.fromMolV3000(mol), m);
    }
    @Test
    public void readsBiggerMolecules() {
        String mol = IoUtils.getStringFromClasspath("molecules/big-ugly.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(12, m.getAtomCnt());
        assertEquals(3, m.getBondCnt(0));
        assertMoleculesEqual(CdkUtil.fromMolV3000(mol), m);
    }
    @Test
    public void readsAtomCntLine() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(1, m.getAtomCnt());
    }
    @Test
    public void readsAtoms() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(1, m.getAtomCnt());
        assertEquals(PeriodicTable.getElementBySymbol("C"), m.getAtom(0));
    }
    @Test
    public void readsMultipleAtoms() {
        String mol = IoUtils.getStringFromClasspath("molecules/co.ketcher.molv3000");
        Molecule m = readMol(mol);
        assertEquals(2, m.getAtomCnt());
        assertEquals(PeriodicTable.getElementBySymbol("O"), m.getAtom(0));
        assertEquals(PeriodicTable.getElementBySymbol("C"), m.getAtom(1));
        assertEquals(1, m.getBondCnt(0));
        assertEquals(1, m.getBondCnt(1));
        assertEquals(2, m.getBondType(0, 0));
        assertEquals(2, m.getBondType(1, 0));
    }
    // todo: write tests when there are more bonds or the counts are lying or the bondtype is invalid
    @Test
    public void errsWhenBondCountDoesNotMatchActualBondList() {
        String mol = IoUtils.getStringFromClasspath("molecules/co.ketcher.molv3000").replace("M  V30 COUNTS 2 1 0 0 0", "M  V30 COUNTS 2 2 0 0 0");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol));
        assertEquals("Invalid structure: Bond Count is 2, while the actual number of bonds is 1", e.getMessage());
    }
    @Test
    public void errsWhenAtomCountLies_andIsGreaterThanActualAtomLines() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000").replace("M  V30 COUNTS 1", "M  V30 COUNTS 2");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol));
        assertEquals("Invalid structure: Expected a line with atom, but got: 'M  V30 END ATOM'. Is Atom Count 2 correct?", e.getMessage());
    }
    @Test
    public void errsWhenAtomPositionInAtomBlockIsLessThan1() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000").replace("M  V30 1 C", "M  V30 0 C");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol));
        assertEquals("Invalid structure: Atoms #1 had an invalid index (either less than 1 or greater than the atom count): 0", e.getMessage());
    }
    @Test
    public void errsIfAtomBlockDidNotEnd() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000").replace("M  V30 END ATOM", "m  V30 END ATOM");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 END ATOM. Instead got: m  V30 END ATOM", e.getMessage());
    }
    @Test
    public void errsIfRunsIntoUnrecognizedAtom() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000").replace("M  V30 1 C", "M  V30 1 X");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol));
        assertEquals("Invalid structure: Unrecognized element: X in the line 'M  V30 1 X 12.225 -6.925 0.0 0'", e.getMessage());
    }
    @Test
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
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB. Instead got: m  V30 BEGIN CTAB", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB. Instead got: M  V30 COUNTS 1 0", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, section.substring(0, section.length() - 1))));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN CTAB. Instead got: M  V30 BEGIN CTABM", e.getMessage());
    }
    @Test
    public void errsIfNoBeginAtomBlock() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        String section = "M  V30 BEGIN ATOM\n";

        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "m  V30 BEGIN ATOM\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN ATOM. Instead got: m  V30 BEGIN ATOM", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN ATOM. Instead got: M  V30 1 C 12.225", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, section.substring(0, section.length() - 1))));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN ATOM. Instead got: M  V30 BEGIN ATOMM", e.getMessage());
    }
    @Test
    public void errsIfNoBeginBondBlock() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        String section = "M  V30 BEGIN BOND\n";

        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "m  V30 BEGIN BOND\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN BOND. Instead got: m  V30 BEGIN BOND", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN BOND. Instead got: M  V30 END BOND\nM", e.getMessage());
        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace(section, section.substring(0, section.length() - 1))));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 BEGIN BOND. Instead got: M  V30 BEGIN BONDM", e.getMessage());
    }
    @Test
    public void errsIfNoCountsLine() {
        String mol = IoUtils.getStringFromClasspath("molecules/methane.ketcher.molv3000");
        Exception e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace("M  V30 COUNTS ", "m  V30 COUNTS ")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 COUNTS. Instead got: m  V30 COUNTS", e.getMessage());

        e = assertThrows(InvalidChemStructureException.class, () -> readMol(mol.replace("M  V30 COUNTS ", "\n")));
        assertEquals("Not a valid MOLV3000 format - didn't find section: M  V30 COUNTS. Instead got: 1 0 0 0 0\nM", e.getMessage());
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