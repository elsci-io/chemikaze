package io.elsci.chemikaze.fgc;

import org.junit.Test;
import org.openscience.cdk.exception.InvalidSmilesException;
import org.openscience.cdk.interfaces.IAtomContainer;
import org.openscience.cdk.silent.SilentChemObjectBuilder;
import org.openscience.cdk.smarts.SmartsPattern;
import org.openscience.cdk.smiles.SmilesParser;

import static org.junit.Assert.assertEquals;

public class SmartsTest {
    @Test
    public void smarts() {
        SmartsPattern aldehydeSmarts = SmartsPattern.create("[O]=[$([H1]([#6])),$([H2]);C;X3]");
        assertEquals(0, aldehydeSmarts.match(smi("CCC")).length);
        assertEquals(2, aldehydeSmarts.match(smi("C1(F)C=CC=C2C(C=O)=CC(O)=CC=12")).length);
    }

    private static IAtomContainer smi(String smiles) {
        try {
            return new SmilesParser(SilentChemObjectBuilder.getInstance()).parseSmiles(smiles);
        } catch (InvalidSmilesException e) {
            throw new RuntimeException(e);
        }
    }
}
