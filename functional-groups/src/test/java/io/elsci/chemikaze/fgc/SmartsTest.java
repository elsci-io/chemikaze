package io.elsci.chemikaze.fgc;

import org.junit.Test;
import org.openscience.cdk.exception.InvalidSmilesException;
import org.openscience.cdk.interfaces.IAtomContainer;
import org.openscience.cdk.isomorphism.Mappings;
import org.openscience.cdk.silent.SilentChemObjectBuilder;
import org.openscience.cdk.smarts.SmartsPattern;
import org.openscience.cdk.smiles.SmilesParser;

import java.util.Map;

import static org.junit.Assert.assertEquals;

public class SmartsTest {
    @Test
    public void smarts() {
        SmartsPattern aldehydeSmarts = SmartsPattern.create("[O]=[$([H1]([#6])),$([H2]);C;X3]");
        assertEquals(0, matches(aldehydeSmarts, "CCC").countUnique());
        assertEquals(1, matches(aldehydeSmarts, "C1(F)C=CC=C2C(C=O)=CC(O)=CC=12").countUnique());
    }

    @Test
    public void amines() {
        assertStructuresMatchSmarts(Map.of(
                "Primary Amine Aliphatic", new String[]{"[NH2]-[C;!$(C=O)]",
                        "NC", "Smallest Primary Amine Aliphatic",
                        "NCC", "Primary Amine Aliphatic",
                        "NCO", "Primary Amine Aliphatic, not Amide because of single bond to O",
                        "NCCO", "Primary Amide because extra C in between",
                        "C1C=CC=C(CN)C=1", "Benzilic Amine",
                        "NC(C)C", "Amine connected to a branching C"},
                "Secondary Amine Aliphatic", new String[]{null,
                        "N(C)C", "Smallest Seconary Amine Aliphatic"},
                "Primary Amine Aromatic", new String[]{"[NH2]-[c;!$(c=[#8])]",
                        "C1C=CC=C(N)C=1", "Smallest Primary Amine Aromatic"},
                "Secondary Amine Aromatic", new String[]{null, "C1C=CC=C(NC2C=CC=CC=2)C=1", "Smallest Primary Amine Secondary"}
        ));
    }

    @Test
    public void esters() {
        assertStructuresMatchSmarts(Map.of(
                "Methyl Ester", new String[]{"O([CH3])[CX3]=O",
                        "O(C(C)=O)C", "Simplest Methyl Ester",
                        "O(C(C1C=CC=CC=1)=O)C", "Methyl Ester w/ Bezene",
                        "O(C(CC1C=CC=CC=1)=O)C", "Benzyl Ester"},
                "Ethyl Ester", new String[]{"O([CH2][CH3])[CX3]=O",
                        "O(C(C)=O)CC", "Simplest Ethyl Ester",
                        "O(C(C1C=CC=CC=1)=O)CC", "Ethyl Ester w/ Bezene",
                        "O(C(CC1C=CC=CC=1)=O)CC", "Benzyl Ethyl Ester"},
                "nPropyl Ester", new String[]{"O([CH2][CH2][CH3])[CX3]=O",
                        "O(C(C)=O)CCC", "Simplest nPropyl Ester",
                        "O(C(C1C=CC=CC=1)=O)CCC", "nPropyl Ester w/ Bezene",
                        "O(C(CC1C=CC=CC=1)=O)CCC", "Benzyl nPropyl Ester"},
                "Isopropyl Ester", new String[]{"O([CH]([CH3])[CH3])[CX3]=O",
                        "O(C(C)=O)C(C)C", "Simplest Isopropyl Ester",
                        "O(C(C1C=CC=CC=1)=O)C(C)C", "Isopropyl Ester w/ Bezene",
                        "O(C(CC1C=CC=CC=1)=O)C(C)C", "Benzyl Isopropyl Ester"},
                "tButyl Ester", new String[]{"O(C([CH3])([CH3])[CH3])[CX3]=O",
                        "O(C(C)=O)C(C)(C)C", "Simplest tButyl Ester",
                        "O(C(C1C=CC=CC=1)=O)C(C)(C)C", "tButyl Ester w/ Bezene",
                        "O(C(CC1C=CC=CC=1)=O)C(C)(C)C", "Benzyl Ester"},
                "Lactone", new String[]{null,
                        "C1CCCOC1=O", "6-membered lactone"}
        ));
    }

    @Test
    public void snarHalides() {
        SmartsPattern halo2x = SmartsPattern.create("[Cl,Br,F,I]-[$(cn)]"); // located 2 bonds away from N
        assertEquals(1, matches(halo2x, "C1C=C(Cl)N=CC=1").countUnique());
        assertEquals(1, matches(halo2x, "c1cc(Cl)ncc1").countUnique());
        assertEquals(1, matches(halo2x, "S1C=CN=C1Cl").countUnique()); // pento
        assertEquals(1, matches(halo2x, "s1ccnc1Cl").countUnique()); // pento aromatic
        assertEquals(1, matches(halo2x, "C1(N=CC=CN=1)Br").countUnique()); // N on both sides
        assertEquals(1, matches(halo2x, "C1(N=CN=CN=1)Br").countUnique()); // N on both sides
        assertEquals(0, matches(halo2x, "s1c[n]cc1Cl").countUnique()); // N is 3 atoms away from X
        assertEquals(0, matches(halo2x, "C1(NCCCC1)Br").countUnique()); // aliphatic ring with NH
        assertEquals(0, matches(halo2x, "C1(N(C)CCCC1)Br").countUnique()); // aliphatic ring with NC
        assertEquals(0, matches(halo2x, "C(N=C)F").countUnique()); // aliphatic
        assertEquals(0, matches(halo2x, "C1(N=CCCC=1)Br").countUnique()); // one double-bond is missing in a ring -> aliphatic
        assertEquals(0, matches(halo2x, "N1(N=CC=CC1)F").countUnique()); // 1-N instead of 1-C

        SmartsPattern halo4x = SmartsPattern.create("[Cl,Br,F,I]-[$(c1acnaa1),$(c1acna1)]"); // located 4 bonds away from N
        assertEquals(1, matches(halo4x, "C1C=C(Cl)C=CN=1").countUnique()); // simplest
        assertEquals(1, matches(halo4x, "C1N=C(Cl)C=CN=1").countUnique()); // hetero-atom at position 2
        assertEquals(1, matches(halo4x, "c1cc(Cl)ccn1").countUnique()); // aromatic
        assertEquals(1, matches(halo4x, "c1[n]c(Br)ccn1").countUnique());// atomatic br
        assertEquals(1, matches(halo4x, "C1(N=CN=CN=1)Br").countUnique());// 2 extra Ns
        assertEquals(1, matches(halo4x, "s1c[n]cc1Cl").countUnique());// pento with N connected through S
        assertEquals(0, matches(halo4x, "N1C=C(Cl)C=CC=1").countUnique());// N is 3 atoms away from X
        assertEquals(0, matches(halo4x, "BrC1C=CN=CC1").countUnique());// one double-bond is missing - aliphatic
    }

    @Test
    public void halo_2X() {
        SmartsPattern halo2x = SmartsPattern.create("[#7]=,:;@[#6]-[Cl,Br,F,I]"); // located 2 bonds away from N
        assertEquals(1, matches(halo2x, "C1(N=CC=CC=1)Br").countUnique());
        assertEquals(0, matches(halo2x, "C(=N/C)\\Br").countUnique());
        assertEquals(0, matches(halo2x, "C1(NCCCC1)Br").countUnique());
        assertEquals(0, matches(halo2x, "C(N=C)F").countUnique());
    }
    private static Mappings matches(SmartsPattern smarts, String smiles) {
        return smarts.matchAll(smi(smiles));
    }
    private static IAtomContainer smi(String smiles) {
        try {
            return new SmilesParser(SilentChemObjectBuilder.getInstance()).parseSmiles(smiles);
        } catch (InvalidSmilesException e) {
            throw new RuntimeException(e);
        }
    }

    private static void assertStructuresMatchSmarts(Map<String, String[]> fgs) {
        for (Map.Entry<String, String[]> entry : fgs.entrySet()) {
            String smarts = entry.getValue()[0];
            if(smarts == null)
                continue; // some classes of compounds don't have SMARTS - they are only part of the test set, so skip testing their pattern
            String fgnameUnderTest = entry.getKey();
            SmartsPattern pattern = SmartsPattern.create(smarts);
            for (Map.Entry<String, String[]> tests : fgs.entrySet()) {
                String testsetName = tests.getKey();
                if(testsetName.equals(fgnameUnderTest)) {
                    // Testing against compounds of the class for which the SMARTS were created, expect 1 count:
                    for (int i = 1; i < tests.getValue().length; i += 2) {
                        String smiles = tests.getValue()[i];
                        String descrip = tests.getValue()[i + 1];
                        int matches = matches(pattern, smiles).countUnique();
                        String errorMsg = String.format("Testing %s with SMARTS %s - got matches=%d against SMILES %s\nCompound description: %s",
                                fgnameUnderTest, smarts, matches, smiles, descrip);
                        assertEquals(errorMsg, 1, matches);
                    }
                } else {
                    // Testing against other class compounds, don't expect a match:
                    for (int i = 1; i < tests.getValue().length; i += 2) {
                        String smiles = tests.getValue()[i];
                        String descrip = tests.getValue()[i + 1];
                        int matches = matches(pattern, smiles).countUnique();
                        String errorMsg = String.format("Testing %s with SMARTS %s - got matches=%d against %s SMILES %s\nCompound description: %s",
                                fgnameUnderTest, smarts, matches, testsetName, smiles, descrip);
                        assertEquals(errorMsg, 0, matches);
                    }
                }

            }
        }
    }

    private static void assertNotMatchesSmarts(String fgname, SmartsPattern smarts, String setname, String[] smilesAndDescription) {
        for (int i = 0; i < smilesAndDescription.length; i+=2) {
            String smiles = smilesAndDescription[i];
            String descrip = smilesAndDescription[i+1];
            int matches = matches(smarts, smiles).countUnique();
            assertEquals(fgname +" pattern matched="+matches+" a "+ setname + " in SMILES: " +smiles + "\nTest case: " + descrip, 0, matches);
        }
    }
    private static void assertMatchesSmarts(String fgname, SmartsPattern smarts, String setname, String[] smilesAndDescription) {
        for (int i = 0; i < smilesAndDescription.length; i+=2) {
            String smiles = smilesAndDescription[i];
            String descrip = smilesAndDescription[i+1];
            int matches = matches(smarts, smiles).countUnique();
            assertEquals(fgname +" pattern matched="+matches+" a "+ setname + " in SMILES: " +smiles + "\nTest case: " + descrip, 1, matches);
        }
    }
}
