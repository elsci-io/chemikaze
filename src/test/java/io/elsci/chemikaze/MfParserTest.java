package io.elsci.chemikaze;

import org.junit.Ignore;
import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;
import java.time.Duration;
import java.util.Objects;

import static io.qala.datagen.RandomShortApi.nullOrBlank;
import static org.junit.Assert.*;

public class MfParserTest {

    private static final MfParser PARSER = new MfParser();

    @Test @Ignore
    public void parseMf_throws_ifNullOrBlankString() {
        Exception e = assertThrows(IllegalArgumentException.class, () -> parseMf(nullOrBlank()));
        assertTrue(e.getMessage().startsWith("Expected a Molecular Formula, got: "));
    }
    @Test public void parseMf_throws_ifElementNotRecognized() {
        Exception e = assertThrows(IllegalArgumentException.class, () -> parseMf("n"));
        assertEquals("Invalid Molecular Formula: n", e.getMessage());

        e = assertThrows(IllegalArgumentException.class, () -> parseMf("o2"));
        assertEquals("Invalid Molecular Formula: o2", e.getMessage());
    }

    @Test @Ignore public void parseMf_parsesElementAndCounts() {
        for(int i = 0; i < 10_000_000; i++) {
//            PARSER.parseMf("H");
//            PARSER.parseMf("H2");
//            PARSER.parseMf("CH4");
//            PARSER.parseMf("CH4CH4");
//            PARSER.parseMf("(CH4CH4)");
//            PARSER.parseMf("(CH4CH4)2");
//            PARSER.parseMf("C(CH4CH4)2");
//            PARSER.parseMf("(C(OH)2)2P");
//            PARSER.parseMf("(C(OH))2(S(S))2P");
            PARSER.parseMf("[CH2O]+");
        }
    }
    @Test public void trimsInput() {
        assertEquals("H8C2", parseMf("  CH4CH4 ").toMf());
        assertEquals("H5C2", parseMf("  (CH4).[CH]-  ").toMf());
    }

    @Test public void parenthesisCanMultiplyCounts() {
        assertEquals("H8C2", parseMf("(CH4CH4)").toMf());
        assertEquals("H16C4", parseMf("(CH4CH4)2").toMf());
        assertEquals("H16C5", parseMf("C(CH4CH4)2").toMf());
        assertEquals("H4C2O4P", parseMf("(C(OH)2)2P").toMf());
        assertEquals("C2O2PS8", parseMf("(C(2S)2O)2P").toMf());//2 is followed by O, but this 2 should be applied to ()
        assertEquals("H132C67O3N8", parseMf("C67H132N8O3").toMf());
        assertEquals("H2C2O2PS4", parseMf("(C(OH))2(S(S))2P").toMf());
    }
    @Test public void throwsIfParenthesesDoNotMatch() {
        Exception e = assertThrows(IllegalArgumentException.class, () -> parseMf("(C").toMf());
        assertEquals("The opening and closing parentheses don't match: (C", e.getMessage());

        e = assertThrows(IllegalArgumentException.class, () -> parseMf(")C").toMf());
        assertEquals("The opening and closing parentheses don't match: )C", e.getMessage());

        e = assertThrows(IllegalArgumentException.class, () -> parseMf("C)").toMf());
        assertEquals("The opening and closing parentheses don't match: C)", e.getMessage());

        e = assertThrows(IllegalArgumentException.class, () -> parseMf("(C))").toMf());
        assertEquals("The opening and closing parentheses don't match: (C))", e.getMessage());

        e = assertThrows(IllegalArgumentException.class, () -> parseMf("(C(OH)2(S(S))2P").toMf());
        assertEquals("The opening and closing parentheses don't match: (C(OH)2(S(S))2P", e.getMessage());
    }
    @Test public void numberAtTheBeginningMultiplesCounts() {
        assertEquals("H4O2", parseMf("2H2O").toMf());
        assertEquals("", parseMf("0H2O").toMf());
    }

    @Test public void signIsIgnoredInCounts() {
        assertEquals("H8C2", parseMf("[CH4CH4]+").toMf());
        assertEquals("H8C2", parseMf("[CH4CH4]2+").toMf());
    }

    @Test
    public void dotsSeparateComponents_butComponentsAreSummedUp() {
        assertEquals("H9C2N", parseMf("NH3.2CH3").toMf());
        assertEquals("H6CN", parseMf("NH3.CH3").toMf());
        assertEquals("H9C2N", parseMf("2CH3.NH3").toMf());
    }
    @Test public void complicatedExample() {
        assertEquals("H12O6NSCl3Na3", parseMf("[(2H2O.NaCl)3S.N]2-").toMf());
        assertEquals("H12O6NSCl3Na3", parseMf(" [(2H2O.NaCl)3S.N]2- ").toMf());
    }

    @Test @Ignore
    public void meveSource() {
        String[] lines;

        try (InputStream in = getClass().getResourceAsStream("/MF.meve.csv")){
            lines = new String(Objects.requireNonNull(in).readAllBytes()).split("\n");
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        System.out.println(lines.length + " lines");

        for (String line : lines)
            parseMf(line);
        for (String line : lines)
            parseMf(line);
        long start = System.nanoTime();
        for (String line : lines)
            parseMf(line);
        System.out.println("Took: " + Duration.ofNanos(System.nanoTime() - start));
//        IChemObjectBuilder builder = DefaultChemObjectBuilder.getInstance();
//        System.out.println();
//        for (String line : lines) {
//            AtomCounts counts = parseMf(line);
//            if(AsciiUtil.isDigit((byte) line.charAt(0)))
//                continue;
//            String cdkStr = getString(getMolecularFormula(line, builder));
//            String chemikazeStr = getString(getMolecularFormula(counts.toMf(), builder));
//            assertEquals("Original: " + line +", got: " + counts.toMf(), cdkStr, chemikazeStr);
//        }
    }

    private static AtomCounts parseMf(String mf) {
        return PARSER.parseMf(mf);
    }
}