#include <stdio.h>
#include <stdlib.h>

#include "../../main/c/signals.h"
#include "log.h"
#include "asserts.h"
#include "test_util.h"
#include "../../main/c/periodic_table.h"
#include "../../main/c/mf_parser.h"

char* parseMfOrFail(const char *mf) {
	MfParser *parser = MfParser_new();
	AtomCounts *atoms = MfParser_parseOrPanic(parser, mf);
	char *toMf = AtomCounts_toString(atoms);
	AtomCounts_free(atoms);
	MfParser_destroy(parser);
	return toMf;
}
char* parseMfAndFail(const char *mf) { // leaks ChemikazeError, but there aren't many tests so let's ignore that
	ChemikazeError *error = nullptr;
	MfParser *parser = MfParser_new();
	AtomCounts *atoms = MfParser_parse(parser, mf, &error);
	if (!error) {
		char buffer[1024];
		sprintf(buffer, "Expected an error for: %s", mf);
		logError(buffer);
		exit(1);
	}
	if (atoms) {
		logError("In case of error, AtomCounts must be NULL");
		exit(1);
	}
	AtomCounts_free(atoms);
	MfParser_destroy(parser);
	return error->msg;
}

void getElementBySybmol_returnsChemElement() {
	ChemElement e = ptable_getElementBySymbol("H");
	assertEqualsUnsigned(0, e);

	e = ptable_getElementBySymbol("C");
	assertEqualsUnsigned(1, e);

	e = ptable_getElementBySymbol("Cl");
	assertEqualsUnsigned(8, e);
}
void parseMf__errsIfMfIsNull() {
	assertEqualsString("MF is null", parseMfAndFail(NULL));
}
void parseMf__parsesSimpleMfIntoCounts() {
	assertEqualsString("H2O", parseMfOrFail("H2O"));
	assertEqualsString("H2O", parseMfOrFail("HOH"));
	assertEqualsString("Cl2", parseMfOrFail("Cl2"));
	assertEqualsString("Cl2", parseMfOrFail("ClCl"));
	assertEqualsString("H132", parseMfOrFail("H132"));
	assertEqualsString("H132C67O3N8", parseMfOrFail("C67H132N8O3"));
}
void parseMf__trimsInput() {
	assertEqualsString("H8C2", parseMfOrFail("  CH4CH4 "));
	assertEqualsString("H5C2", parseMfOrFail("  (CH4).[CH]-  "));
}
void parseMf__signIsIgnoredInCounts() {
	assertEqualsString("H8C2", parseMfOrFail("[CH4CH4]+"));
	assertEqualsString("H8C2", parseMfOrFail("[CH4CH4]2+"));
}
void parseMf__complicatedMfIsParsedIntoCounts() {
	assertEqualsString("H12O6NSCl3Na3", parseMfOrFail("[(2H2O.NaCl)3S.N]2-"));
	assertEqualsString("H12O6NSCl3Na3", parseMfOrFail(" [(2H2O.NaCl)3S.N]2- "));
}
void parseMf__parenthesisMultiplyCounts() {
	assertEqualsString("H8C2", parseMfOrFail("(CH4CH4)"));
	assertEqualsString("H16C4", parseMfOrFail("(CH4CH4)2"));
	assertEqualsString("H16C5", parseMfOrFail("C(CH4CH4)2"));
	assertEqualsString("H4C2O4P", parseMfOrFail("(C(OH)2)2P"));
	assertEqualsString("C2O2PS8", parseMfOrFail("(C(2S)2O)2P"));
	assertEqualsString("H2C2O2PS4", parseMfOrFail("(C(OH))2(S(S))2P"));
}
void parseMf__dotsSeparateComponents_butComponentsAreSummedUp() {
	assertEqualsString("H9C2N", parseMfOrFail("NH3.2CH3"));
	assertEqualsString("H6CN", parseMfOrFail("NH3.CH3"));
	assertEqualsString("H9C2N", parseMfOrFail("2CH3.NH3"));
}
void parseMf__numberAtTheBeginningMultiplesCounts() {
	assertEqualsString("H4O2", parseMfOrFail("2H2O"));
	assertEqualsString("", parseMfOrFail("0H2O"));
}
void parseMf__errsOnEmptyInput() {
	assertEqualsString("Empty Molecular Formula", parseMfAndFail(""));
	assertEqualsString("Empty Molecular Formula", parseMfAndFail(" "));
	assertEqualsString("MF is null", parseMfAndFail(nullptr));
}
void atomCounts_toString() {
	AtomCounts* ac = AtomCounts_new();
	ac->counts[0] = 137;
	assertEqualsString("H137", AtomCounts_toString(ac));
}
void parseMf__errsIfParenthesesDoNotMatch() {
#define TSTBEGIN "Couldn't parse "
#define TSTEND ". The opening and closing parentheses don't match."
	assertEqualsString(TSTBEGIN"(C"TSTEND, parseMfAndFail("(C"));
	assertEqualsString(TSTBEGIN")C"TSTEND, parseMfAndFail(")C"));
	assertEqualsString(TSTBEGIN"C)"TSTEND, parseMfAndFail("C)"));
	assertEqualsString(TSTBEGIN"(C))"TSTEND, parseMfAndFail("(C))"));
	assertEqualsString(TSTBEGIN"(C(OH)2(S(S))2P"TSTEND, parseMfAndFail("(C(OH)2(S(S))2P"));
#undef TSTBEGIN
#undef TSTEND
}
void parseMf_errsIfElementNotRecognized() {
	assertEqualsString("Couldn't parse A. Unknown chemical symbol: A", parseMfAndFail("A"));
	assertEqualsString("Couldn't parse A2. Unknown chemical symbol: A", parseMfAndFail("A2"));
	assertEqualsString("Couldn't parse i2. Unexpected symbol: i", parseMfAndFail("i2"));
}

int main(void) {
	register_signals();
	logNorm("Testing AtomCounts");
	RUN_TEST(atomCounts_toString);
	logNorm("Testing periodic_table");
	RUN_TEST(getElementBySybmol_returnsChemElement);

	logNorm("Testing MfParser");
	RUN_TEST(parseMf__errsIfMfIsNull);
	RUN_TEST(parseMf__parsesSimpleMfIntoCounts);
	RUN_TEST(parseMf__signIsIgnoredInCounts);
	RUN_TEST(parseMf__trimsInput);
	RUN_TEST(parseMf__parenthesisMultiplyCounts);
	RUN_TEST(parseMf__numberAtTheBeginningMultiplesCounts);
	RUN_TEST(parseMf__dotsSeparateComponents_butComponentsAreSummedUp);
	RUN_TEST(parseMf__complicatedMfIsParsedIntoCounts);
	RUN_TEST(parseMf__errsIfParenthesesDoNotMatch);
	RUN_TEST(parseMf__errsOnEmptyInput);
	RUN_TEST(parseMf_errsIfElementNotRecognized);
}
