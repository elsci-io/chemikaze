package io.elsci.chemikaze;


import org.openjdk.jmh.annotations.*;
import org.openscience.cdk.DefaultChemObjectBuilder;
import org.openscience.cdk.interfaces.IChemObjectBuilder;
import org.openscience.cdk.tools.manipulator.MolecularFormulaManipulator;

import java.io.IOException;
import java.io.InputStream;

import static io.qala.datagen.RandomShortApi.integer;
import static java.util.Objects.requireNonNull;

@Warmup(iterations = 2, time = 3)
@Measurement(iterations = 2, time = 5)
@Fork(value = 1)
public class MfParserBenchmark {

    public static void main(String[] args) throws Exception {
        org.openjdk.jmh.Main.main(new String[]{MfParserBenchmark.class.getSimpleName()});
    }

    static MfParser parser = new MfParser();
    static IChemObjectBuilder cdkBuilder = DefaultChemObjectBuilder.getInstance();

    @Benchmark
    public void atomCounts(Data data) {
        for (String mf : data.mfs)
            parser.parseMf(mf);
    }
    @Benchmark
    public void atomCountsWithParentheses(Data data) {
        for (String mf : data.mfsWithParenthesis)
            parser.parseMf(mf);
    }
//    @Benchmark
    public void atomCountsCdk(Data data) {
        for (String mf : data.mfs)
            MolecularFormulaManipulator.getMolecularFormula(mf, cdkBuilder);
    }
//    @Benchmark
    public void atomCountsCdkWithParenthesis(Data data) {
        for (String mf : data.mfsWithParenthesis)
            MolecularFormulaManipulator.getMolecularFormula(mf, cdkBuilder);
    }

    @State(Scope.Benchmark)
    public static class Data {
        String[] mfs; {
            // CDK can't parse some of the structures, so if we want to compare CDK w/ our implementation, then
            // uncomment the other file
            String filename = "/MFs.csv";
//            String filename = "/MFs-wo-starting-numbers.csv";
            try (InputStream in = getClass().getResourceAsStream(filename)){
                mfs = new String(requireNonNull(in).readAllBytes()).split("\n");
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
        String[] mfsWithParenthesis = new String[mfs.length]; {
            for (int i = 0; i < mfs.length; i++)
                mfsWithParenthesis[i] = "("+mfs[i]+")"+integer(1, 10) + ".2H2O";
        }
    }
}