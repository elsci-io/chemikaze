#include "tests.hpp"
#include "parser.hpp"
#include <iostream>

std::string atomcount_to_string(AtomCount atomCount) {
    std::string ans = "";
    for (int i = 0; i < 85; ++i) {
        if (atomCount.atoms[i]) {
            const char* el = get_element_by_index(i);
            ans.append(el);
            atomCount.atoms[i] > 1 ? ans.append(std::to_string(atomCount.atoms[i])) : "";
        }
    }

    return ans;
}

static void check(const char* input, const std::string& expected) {
    const char* p = input;
    std::string result = atomcount_to_string(parse_mf(&p));
    if (result != expected) {
        std::cerr << "\n========== [TEST FAILED] ==========\n" << input
                  << "\n  expected: \"" << expected
                  << "\"\n  got:      \"" << result << "\"\n"
        << "===================================\n" ;
    } else {
        std::cout << "========== [TEST PASSED] ==========" << '\n';
    }
}

// -------------------------------------------------------

static void test_simple_mf_is_parsed_into_counts() {
    check("H2O", "H2O");
    check("HOH", "H2O");
    check("C67H132N8O3", "H132C67O3N8");
}

static void test_complicated_mf_is_parsed_into_counts() {
    check("[(2H2O.NaCl)3S.N]2-", "H12O6NSCl3Na3");
    check(" [(2H2O.NaCl)3S.N]2- ", "H12O6NSCl3Na3");
}

static void test_errs_on_empty_mf() {
    check("", "");
    check(" ", "");
    check("  ", "");
}

static void test_trims_input() {
    check("  CH4CH4 ", "H8C2");
    check("  (CH4).[CH]-  ", "H5C2");
}

static void test_parenthesis_multiply_counts() {
    check("(CH4CH4)", "H8C2");
    check("(CH4CH4)2", "H16C4");
    check("C(CH4CH4)2", "H16C5");
    check("(C(OH)2)2P", "H4C2O4P");
    check("(C(2S)2O)2P", "C2O2PS8");
    check("(C(OH))2(S(S))2P", "H2C2O2PS4");
}

static void test_number_at_the_beginning_multiples_counts() {
    check("2H2O", "H4O2");
    check("0H2O", "");
}

static void test_sign_is_ignored_in_counts() {
    check("[CH4CH4]+", "H8C2");
    check("[CH4CH4]2+", "H8C2");
}

static void test_dots_separate_components_but_components_are_summed_up() {
    check("NH3.CH3", "H6CN");
    check("NH3.2CH3", "H9C2N");
    check("2CH3.NH3", "H9C2N");
}

static void test_errs_if_parenthesis_do_not_match() {
    check("(C", "");
    check(")C", "");
    check("C)", "");
    check("C(", "");
    check("(C))", "");
    check("(C(OH)2(S(S))2P", "");
}

static void test_errs_if_symbol_is_not_known() {
    check("A", "");
    check("o", "");
}

static void test_errs_if_contains_special_symbols_outside_of_allowed_punctuation() {
    check("=", "");
    check("O=", "");
    check("=C", "");
}

void run_all_tests() {
    printf("====================== TESTS ====================== \n");
    test_simple_mf_is_parsed_into_counts();
    test_complicated_mf_is_parsed_into_counts();
    test_errs_on_empty_mf();
    test_trims_input();
    test_parenthesis_multiply_counts();
    test_number_at_the_beginning_multiples_counts();
    test_sign_is_ignored_in_counts();
    test_dots_separate_components_but_components_are_summed_up();
    test_errs_if_parenthesis_do_not_match();
    test_errs_if_symbol_is_not_known();
    test_errs_if_contains_special_symbols_outside_of_allowed_punctuation();

    std::cout << "All tests executed.\n";
}
