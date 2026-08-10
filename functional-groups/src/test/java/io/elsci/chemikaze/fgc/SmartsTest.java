package io.elsci.chemikaze.fgc;

import org.junit.Test;
import org.openscience.cdk.exception.InvalidSmilesException;
import org.openscience.cdk.interfaces.IAtomContainer;
import org.openscience.cdk.isomorphism.Mappings;
import org.openscience.cdk.silent.SilentChemObjectBuilder;
import org.openscience.cdk.smarts.SmartsPattern;
import org.openscience.cdk.smiles.SmilesParser;

import static org.junit.Assert.assertEquals;

public class SmartsTest {
    @Test
    public void smarts() {
        SmartsPattern aldehydeSmarts = SmartsPattern.create("[O]=[$([H1]([#6])),$([H2]);C;X3]");
        assertEquals(0, matches(aldehydeSmarts, "CCC").countUnique());
        assertEquals(1, matches(aldehydeSmarts, "C1(F)C=CC=C2C(C=O)=CC(O)=CC=12").countUnique());
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
}
