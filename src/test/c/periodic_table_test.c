#include "signals.c"
#include "log.h"
#include "asserts.h"
#include "test_util.h"
#include "../../main/c/periodic_table.h"

void test_get_element_by_symbol() {
	ChemElement e = get_element_by_symbol("H");
	assertEqualsUnsigned(0, e);

	e = get_element_by_symbol("C");
	assertEqualsUnsigned(1, e);

	e = get_element_by_symbol("Cl");
	assertEqualsUnsigned(8, e);
}

int main(void) {
	register_signals();
	logInfo("[INFO] Testing periodic_table");
	RUN_TEST(test_get_element_by_symbol);
}
