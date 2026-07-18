package io.elsci.chemikaze;

import org.openscience.cdk.interfaces.IAtomContainer;
import org.openscience.cdk.io.MDLV3000Reader;
import org.openscience.cdk.silent.SilentChemObjectBuilder;

import java.io.StringReader;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

public class CdkUtil {
    public static IAtomContainer fromMolV3000(String struct) {
        try {
            return new MDLV3000Reader(new StringReader(struct))
                    .read(SilentChemObjectBuilder.getInstance().newAtomContainer());
        } catch (Exception/*throws NPE in some cases %)*/ e) {
            throw new InvalidChemStructureException(struct, "Can't read MDL MOLV3000 " + struct, e);
        }
    }
    public static void assertMoleculesEqual(IAtomContainer cdk, Molecule m) {
        if(cdk == null && m == null)
            return;
        if(cdk == null || m == null)
            fail("\nExpected: " + cdk + ",\n     got: " + m);
        assertEquals("Different number of atoms. Expected " + cdk + ",\n   got: " + m, cdk.getAtomCount(), m.getAtomCnt());
        for (int i = 0; i < m.getAtomCnt(); i++) {
            byte e = m.getAtom(i);
            if(cdk.getAtom(i).getAtomicNumber() != PeriodicTable.getAtomicNumber(e))
                fail("Molecules weren't equal at atom #" + i + ", expected " + cdk.getAtom(i) + ",\n     got " + PeriodicTable.getElementSymbol(e));
        }
    }
}
