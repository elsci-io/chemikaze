package io.elsci.chemikaze.core;

import org.openscience.cdk.exception.InvalidSmilesException;
import org.openscience.cdk.interfaces.IAtom;
import org.openscience.cdk.interfaces.IAtomContainer;
import org.openscience.cdk.interfaces.IBond;
import org.openscience.cdk.silent.SilentChemObjectBuilder;
import org.openscience.cdk.smiles.SmilesParser;

public class Smiles {
    public Molecule readOne(String smiles) {
        try {
            return fromCdk(new SmilesParser(SilentChemObjectBuilder.getInstance()).parseSmiles(smiles));
        } catch (InvalidSmilesException e) {
            throw new InvalidChemStructureException(e);
        }
    }

    private static Molecule fromCdk(IAtomContainer m) {
        byte[] resultAtoms = new byte[m.getAtomCount()];
        int i = 0;
        for (IAtom next : m.atoms())
            resultAtoms[i++] = PeriodicTable.getElementBySymbol(next.getSymbol());
        Molecule result = Molecule.create(resultAtoms);
        for (IBond bond : m.bonds())
            result.setBond(bond.getAtom(0).getIndex(), bond.getAtom(1).getIndex(), (byte)(int) bond.getOrder().numeric());
        return result;
    }
}
