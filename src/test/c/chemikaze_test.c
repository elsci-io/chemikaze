#include "signals.h"
#include "log.h"
#include "asserts.h"
#include "test_util.h"
#include "../../main/c/periodic_table.h"
#include "../../main/c/mf_parser.h"

void getElementBySybmol_returnsChemElement() {
	ChemElement e = ptable_getElementBySymbol("H");
	assertEqualsUnsigned(0, e);

	e = ptable_getElementBySymbol("C");
	assertEqualsUnsigned(1, e);

	e = ptable_getElementBySymbol("Cl");
	assertEqualsUnsigned(8, e);
}

void parseMf__parsesSimpleMfIntoCounts() {
	assertEqualsString("H2O", AtomCounts_toString(parseMf("H2O")));
	assertEqualsString("H2O", AtomCounts_toString(parseMf("HOH")));
	assertEqualsString("H132C67O3N8", AtomCounts_toString(parseMf("C67H132N8O3")));
}
void parseMf__trimsInput() {
	assertEqualsString("H8C2", AtomCounts_toString(parseMf("  CH4CH4 ")));
	assertEqualsString("H5C2", AtomCounts_toString(parseMf("  (CH4).[CH]-  ")));
}
void parseMf__signIsIgnoredInCounts() {
	assertEqualsString("H8C2", AtomCounts_toString(parseMf("[CH4CH4]+")));
	assertEqualsString("H8C2", AtomCounts_toString(parseMf("[CH4CH4]2+")));
}
void parseMf__complicatedMfIsParsedIntoCounts() {
	assertEqualsString("H12O6NSCl3Na3", AtomCounts_toString(parseMf("[(2H2O.NaCl)3S.N]2-")));
	assertEqualsString("H12O6NSCl3Na3", AtomCounts_toString(parseMf(" [(2H2O.NaCl)3S.N]2- ")));
}
void parseMf__parenthesisMultiplyCounts() {
	assertEqualsString("H8C2", AtomCounts_toString(parseMf("(CH4CH4)")));
	assertEqualsString("H16C4", AtomCounts_toString(parseMf("(CH4CH4)2")));
	assertEqualsString("H16C5", AtomCounts_toString(parseMf("C(CH4CH4)2")));
	assertEqualsString("H4C2O4P", AtomCounts_toString(parseMf("(C(OH)2)2P")));
	assertEqualsString("C2O2PS8", AtomCounts_toString(parseMf("(C(2S)2O)2P")));
	assertEqualsString("H2C2O2PS4", AtomCounts_toString(parseMf("(C(OH))2(S(S))2P")));
}
void parseMf__dotsSeparateComponents_butComponentsAreSummedUp() {
	assertEqualsString("H9C2N", AtomCounts_toString(parseMf("NH3.2CH3")));
	assertEqualsString("H6CN", AtomCounts_toString(parseMf("NH3.CH3")));
	assertEqualsString("H9C2N", AtomCounts_toString(parseMf("2CH3.NH3")));
}
void parseMf__numberAtTheBeginningMultiplesCounts() {
	assertEqualsString("H4O2", AtomCounts_toString(parseMf("2H2O")));
	assertEqualsString("", AtomCounts_toString(parseMf("0H2O")));
}

int main(void) {
	register_signals();
	logInfo("[INFO] Testing periodic_table");
	RUN_TEST(getElementBySybmol_returnsChemElement);

	logInfo("[INFO] Testing parseMf");
	RUN_TEST(parseMf__parsesSimpleMfIntoCounts);
	RUN_TEST(parseMf__signIsIgnoredInCounts);
	RUN_TEST(parseMf__trimsInput);
	RUN_TEST(parseMf__parenthesisMultiplyCounts);
	RUN_TEST(parseMf__numberAtTheBeginningMultiplesCounts);
	RUN_TEST(parseMf__dotsSeparateComponents_butComponentsAreSummedUp);
	RUN_TEST(parseMf__complicatedMfIsParsedIntoCounts);
}
