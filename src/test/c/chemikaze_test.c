#include <string.h>

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
	char *mf = "H2O";
	assertEqualsString(mf, parseMfChunk(mf, mf + strlen("H2O")));
}

int main(void) {
	register_signals();
	logInfo("[INFO] Testing periodic_table");
	RUN_TEST(getElementBySybmol_returnsChemElement);
	logInfo("[INFO] Testing parseMf");
	RUN_TEST(parseMf__parsesSimpleMfIntoCounts);
}
