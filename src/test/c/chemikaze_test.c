#include "signals.h"
#include "log.h"
#include "asserts.h"
#include "test_util.h"
#include "../../main/c/periodic_table.h"
#include "../../main/c/mf_parser.h"

void getElementBySybmol_returnsChemElement() {
	ChemElement e = get_element_by_symbol("H");
	assertEqualsUnsigned(0, e);

	e = get_element_by_symbol("C");
	assertEqualsUnsigned(1, e);

	e = get_element_by_symbol("Cl");
	assertEqualsUnsigned(8, e);
}

void parseMf__parsesSimpleMfIntoCounts() {
	assertEqualsString("H2O", AtomCounts_toString(parseMf("H2O")));
	assertEqualsString("H2O", AtomCounts_toString(parseMf("HOH")));
	assertEqualsString("H132C67O3N8", AtomCounts_toString(parseMf("C67H132N8O3")));
}
void parseMf__sign_is_ignored_in_counts() {
	assertEqualsString("H8C2", AtomCounts_toString(parseMf("[CH4CH4]+")));
	assertEqualsString("H8C2", AtomCounts_toString(parseMf("[CH4CH4]2+")));
}

int main(void) {
	register_signals();
	logInfo("[INFO] Testing periodic_table");
	RUN_TEST(getElementBySybmol_returnsChemElement);
	logInfo("[INFO] Testing parseMf");
	RUN_TEST(parseMf__parsesSimpleMfIntoCounts);
	RUN_TEST(parseMf__sign_is_ignored_in_counts);
}
