use crate::atom_counts::AtomCounts;
use crate::errors::ChemikazeError;
use crate::errors::ErrorKind::Parsing;
use crate::periodic_table;
use crate::periodic_table::EARTH_ELEMENT_CNT;
use crate::util::{*};

const MF_PUNCTUATION: [u8;7] = [OP, CP, b'+', b'-', DOT, b'[', b']'];

//
// Performance considerations:
// Tried to figure out what matters and what doesn't in terms of performance:
// * (De)allocations in the original implementation were a big hit in performance
// * `opt-level = 3` also mattered
// * Replacing 'a'.is_digit() and related functions with macros had 0.3% difference
// * `if` vs `match` - doesn't matter
//
// Many optimizations were made by Artur Jakubiec. Here's his a little more idiomatic
// implementation: https://github.com/Artxiom/chemikaze
//
pub struct MfParser {
    i: usize,
    coeffs: Vec<u32>,
    elements: Vec<u8>,
}

impl MfParser {
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            i: 0,
            coeffs: Vec::with_capacity(capacity),
            elements: Vec::with_capacity(capacity),
        }
    }
    pub fn new() -> Self {
        Self::with_capacity(20)
    }

    #[allow(dead_code)]
    pub fn parse_mf(&mut self, mf: &str) -> Result<AtomCounts, ChemikazeError> {
        let sanitized = mf.as_bytes().trim_ascii();
        if sanitized.is_empty() {
            return Err(ChemikazeError{ kind: Parsing, msg: "Empty Molecular Formula".into() })
        }
        self.parse_mf_sanitized(sanitized)
    }

    pub fn parse_mf_sanitized(&mut self, mf: &[u8]) -> Result<AtomCounts, ChemikazeError> {
        self.coeffs.clear();
        self.elements.clear();
        self.coeffs.resize(mf.len(), 0);
        self.elements.resize(mf.len(), 0);

        // First pass: read symbols and their immediate coefficients
        self.i = 0;
        err_if_invalid_mf(mf, self.read_symbols_and_coeffs(mf))?;

        // Second pass: apply group coefficients (parentheses and leading numbers)
        self.i = 0;
        err_if_invalid_mf(mf, self.apply_group_coeffs(mf))?;
        Ok(AtomCounts{counts: self.combine_into_atom_counts()})
    }
    fn read_symbols_and_coeffs(&mut self, mf: &[u8]) -> Result<(), ChemikazeError> {
        while self.i < mf.len() {
            let letter = mf[self.i];
            if letter.is_ascii_uppercase() {
                let start = self.i;
                self.elements[start] = self.consume_element(mf)?;
                self.coeffs[start] = self.consume_coeff(mf);
            } else if letter.is_ascii_digit() || MF_PUNCTUATION.contains(&letter) { // digit - meaning (xx)N or Nxx
                self.i += 1;
            } else {
                return Err(ChemikazeError {
                    kind: Parsing,
                    msg: String::from(format!("Unexpected symbol: {:?}", char::from(letter)))
                });
            }
        }
        Ok(())
    }
    fn consume_element(&mut self, input: &[u8]) -> Result<u8, ChemikazeError> {
        let first = input[self.i];
        self.i += 1;
        let symbol = if self.i < input.len() && input[self.i].is_ascii_lowercase() {
            let second = input[self.i];
            self.i += 1;
            [first, second]
        } else {
            [first, 0]
        };
        periodic_table::get_element_by_symbol_bytes(symbol)
    }
    fn consume_coeff(&mut self, mf: &[u8]) -> u32 {
        if self.i >= mf.len() || !mf[self.i].is_ascii_digit() {
            return 1;
        }
        let mut multiplier = 0u32;
        while self.i < mf.len() && mf[self.i].is_ascii_digit() {
            multiplier = multiplier * 10 + (mf[self.i] - _0) as u32;
            self.i += 1;
        }
        multiplier
    }
    /// There are 2 types of group coefficients:
    ///
    /// * At the beginning: 5Cl or O.5Cl - for this we run scale_forward()
    /// * After parenthesis: (CO)2 - for this we run scale_backward()
    fn apply_group_coeffs(&mut self, mf: &[u8]) -> Result<(), ChemikazeError> {
        let mut stack_depth = 0i32;
        while self.i < mf.len() {
            if mf[self.i].is_ascii_digit() {  // things like 5Cl, which are relatively rare
                let coeff = self.consume_coeff(mf);
                self.scale_forward(mf, self.i, stack_depth, coeff);
            }
            while self.i < mf.len() && mf[self.i].is_ascii_alphanumeric() {
                self.i += 1; // skip alphanumerics
            }
            if self.i >= mf.len() {
                break
            }
            match mf[self.i] {
                OP => {
                    stack_depth += 1;
                    self.i += 1;
                },
                CP => {
                    let chunk_end = self.i;
                    self.i += 1;
                    let coeff = self.consume_coeff(mf);
                    self.scale_backward(mf, chunk_end, stack_depth, coeff);
                    stack_depth -= 1;
                },
                _ => self.i += 1
            }
        }
        if stack_depth != 0 {
            return Err(ChemikazeError{
                kind: Parsing,
                msg: String::from("The opening and closing parentheses don't match.")
            })
        }
        Ok(())
    }
    fn scale_forward(&mut self, mf: &[u8], mut lo: usize, curr_stack_depth: i32, group_coeff: u32) {
        if group_coeff == 1 {
            return;// usually the case, as people rarely put coefficients in front of MF
        }
        let mut depth = curr_stack_depth;
        while lo < mf.len() && depth >= curr_stack_depth {
            match mf[lo] {
                OP => depth += 1,
                CP => depth -= 1,
                DOT if depth == curr_stack_depth => break,
                _ => {}
            }
            self.coeffs[lo] *= group_coeff;
            lo += 1;
        }
    }
    fn scale_backward(&mut self, mf: &[u8], mut hi: usize/*exclusive*/,
                      curr_stack_depth: i32, group_coeff: u32) {
        if group_coeff == 1 {
            return;
        }
        let mut depth = curr_stack_depth;
        while hi > 0 && depth <= curr_stack_depth {
            hi -= 1;
            match mf[hi] {
                OP => depth += 1,
                CP => depth -= 1,
                _ => {}
            }
            self.coeffs[hi] *= group_coeff;
        }
    }
    fn combine_into_atom_counts(&self) -> [u32; EARTH_ELEMENT_CNT] {
        let mut result = [0u32; EARTH_ELEMENT_CNT];
        let mut i = 0;
        while i < self.coeffs.len() {
            if self.coeffs[i] > 0 {
                result[self.elements[i] as usize] += self.coeffs[i];
            }
            i+=1;
        }
        result
    }
}


fn err_if_invalid_mf<T>(mf: &[u8], result: Result<T, ChemikazeError>) -> Result<(), ChemikazeError> {
    if result.is_err() {
        let mf_str = bytes_to_string(&mf);
        let msg = String::from(format!("Invalid Molecular Formula: {mf_str}. Details: {}",
                                       result.err().unwrap().msg));
        return Err(ChemikazeError { kind: Parsing, msg });
    }
    Ok(())
}

#[cfg(test)]
mod parse_mf_test {
    use super::*;

    fn parse_mf(mf: &str) -> Result<AtomCounts, ChemikazeError> {
        MfParser::new().parse_mf(mf)
    }

    #[test]
    fn simple_mf_is_parsed_into_counts() {
        assert_eq!("H2O", parse_mf("H2O").unwrap().to_string());
        assert_eq!("H2O", parse_mf("HOH").unwrap().to_string());
        assert_eq!("H132C67O3N8", parse_mf("C67H132N8O3").unwrap().to_string());
    }
    #[test]
    fn complicated_mf_is_parsed_into_counts() {
        assert_eq!("H12O6NSCl3Na3", parse_mf("[(2H2O.NaCl)3S.N]2-").unwrap().to_string());
        assert_eq!("H12O6NSCl3Na3", parse_mf(" [(2H2O.NaCl)3S.N]2- ").unwrap().to_string());
    }
    #[test]
    fn errs_on_empty_mf() {
        assert_eq!("Empty Molecular Formula", parse_mf("").unwrap_err().msg);
        assert_eq!("Empty Molecular Formula", parse_mf(" ").unwrap_err().msg);
        assert_eq!("Empty Molecular Formula", parse_mf("  ").unwrap_err().msg);
    }
    #[test]
    fn trims_input() {
        assert_eq!("H8C2", parse_mf("  CH4CH4 ").unwrap().to_string());
        assert_eq!("H5C2", parse_mf("  (CH4).[CH]-  ").unwrap().to_string());
    }
    #[test]
    fn parenthesis_multiply_counts() {
        assert_eq!("H8C2", parse_mf("(CH4CH4)").unwrap().to_string());
        assert_eq!("H16C4", parse_mf("(CH4CH4)2").unwrap().to_string());
        assert_eq!("H16C5", parse_mf("C(CH4CH4)2").unwrap().to_string());
        assert_eq!("H4C2O4P", parse_mf("(C(OH)2)2P").unwrap().to_string());
        assert_eq!("C2O2PS8", parse_mf("(C(2S)2O)2P").unwrap().to_string());
        assert_eq!("H2C2O2PS4", parse_mf("(C(OH))2(S(S))2P").unwrap().to_string());
    }
    #[test]
    fn number_at_the_beginning_multiples_counts() {
        assert_eq!("H4O2", parse_mf("2H2O").unwrap().to_string());
        assert_eq!("", parse_mf("0H2O").unwrap().to_string());
    }
    #[test]
    fn sign_is_ignored_in_counts() {
        assert_eq!("H8C2", parse_mf("[CH4CH4]+").unwrap().to_string());
        assert_eq!("H8C2", parse_mf("[CH4CH4]2+").unwrap().to_string());
    }
    #[test]
    fn dots_separate_components_but_components_are_summed_up() {
        assert_eq!("H6CN", parse_mf("NH3.CH3").unwrap().to_string());
        assert_eq!("H9C2N", parse_mf("NH3.2CH3").unwrap().to_string());
        assert_eq!("H9C2N", parse_mf("2CH3.NH3").unwrap().to_string());
    }
    #[test]
    fn errs_if_parenthesis_do_not_match() {
        assert_eq!("Invalid Molecular Formula: (C. Details: The opening and closing parentheses don't match.",
                   parse_mf("(C").unwrap_err().msg);
        assert_eq!("Invalid Molecular Formula: )C. Details: The opening and closing parentheses don't match.",
                   parse_mf(")C").unwrap_err().msg);
        assert_eq!("Invalid Molecular Formula: C). Details: The opening and closing parentheses don't match.",
                   parse_mf("C)").unwrap_err().msg);
        assert_eq!("Invalid Molecular Formula: C(. Details: The opening and closing parentheses don't match.",
                   parse_mf("C(").unwrap_err().msg);
        assert_eq!("Invalid Molecular Formula: (C)). Details: The opening and closing parentheses don't match.",
                   parse_mf("(C))").unwrap_err().msg);
        assert_eq!("Invalid Molecular Formula: (C(OH)2(S(S))2P. Details: The opening and closing parentheses don't match.",
                   parse_mf("(C(OH)2(S(S))2P").unwrap_err().msg);
    }
    #[test]
    fn errs_if_symbol_is_not_known() {
        let err = parse_mf("A").err().unwrap();
        assert_eq!(Parsing, err.kind);
        assert_eq!("Invalid Molecular Formula: A. Details: Unknown chemical symbol: A", err.msg);

        let err = parse_mf("o").err().unwrap();
        assert_eq!(Parsing, err.kind);
        assert_eq!("Invalid Molecular Formula: o. Details: Unexpected symbol: 'o'", err.msg);
    }
    #[test]
    fn errs_if_contains_special_symbols_outside_of_allowed_punctuation() {
        let err = parse_mf("=").err().unwrap();
        assert_eq!(Parsing, err.kind);

        let err = parse_mf("O=").unwrap_err();
        assert_eq!(Parsing, err.kind);

        let err = parse_mf("=C").unwrap_err();
        assert_eq!(Parsing, err.kind);
    }
}