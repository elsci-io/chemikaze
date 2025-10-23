use crate::atom_counts::AtomCounts;
use crate::errors::ChemikazeError;
use crate::errors::ErrorKind::Parsing;
use crate::periodic_table;
use crate::periodic_table::EARTH_ELEMENT_CNT;
use crate::util::{*};

const MF_PUNCTUATION: [u8;7] = ['(' as u8, ')' as u8, '+' as u8, '-' as u8, '.' as u8, '[' as u8, ']' as u8];

pub fn parse_mf(mf: &str) -> Result<AtomCounts, ChemikazeError> {
    parse_mf_ascii(mf.as_bytes())
}
pub fn parse_mf_ascii(mf: &[u8]) -> Result<AtomCounts, ChemikazeError> {
    parse_mf_ascii_chunk(mf, index_of_start(mf), index_of_end(mf))
}
pub fn parse_mf_ascii_chunk(mf: &[u8], mf_start: usize, mf_end: usize) -> Result<AtomCounts, ChemikazeError> {
    if mf_start >= mf_end {
        return Err(ChemikazeError{ kind: Parsing, msg: String::from("Empty Molecular Formula") })
    }
    let mut coeff: Vec<u32> = vec![0u32; mf_end - mf_start];
    let mut elements: Vec<u8> = vec![0u8; mf_end - mf_start];
    let mut i = mf_start;

    err_if_invalid_mf(mf, mf_start, mf_end,
                      read_symbols_and_coeffs(mf, &mut i, mf_start, mf_end, &mut elements, &mut coeff)
    )?;
    err_if_invalid_mf(mf, mf_start, mf_end,
        find_and_apply_group_coeff(mf, &mut i, mf_start, mf_end, &mut coeff)
    )?;
    Ok(AtomCounts{counts: combine_into_atom_counts(&elements, &coeff)})
}

fn err_if_invalid_mf<T>(mf: &[u8], mf_start: usize, mf_end: usize,
                     result: Result<T, ChemikazeError>) -> Result<(), ChemikazeError> {
    if result.is_err() {
        let mf_str = bytes_to_string(&mf[mf_start..mf_end]);
        let msg = String::from(format!("Invalid Molecular Formula: {mf_str}. Details: {}",
                                       result.err().unwrap().msg));
        return Err(ChemikazeError { kind: Parsing, msg });
    }
    Ok(())
}

fn read_symbols_and_coeffs(mf: &[u8], i: &mut usize, mf_start: usize, mf_end: usize,
                           result_elements: &mut Vec<u8>, coeff: &mut Vec<u32>) -> Result<(), ChemikazeError> {
    *i = mf_start;
    while *i < mf_end {
        if is_big_letter(mf[*i]) {
            consume_symbol_and_coeff(mf, i, mf_start, mf_end, result_elements, coeff)?;
        } else if MF_PUNCTUATION.contains(&mf[*i]) || is_digit(mf[*i]) { // digit - meaning (xx)N or Nxx
            *i += 1;
        } else {
            return Err(ChemikazeError {
                kind: Parsing,
                msg: String::from(format!("Unexpected symbol: {:?}", char::from(mf[*i])))
            });
        }
    }
    Ok(())
}
/// There are 2 types of group coefficients:
///
/// * At the beginning: 5Cl or O.5Cl - for this we run scale_forward()
/// * After parenthesis: (CO)2 - for this we run scale_backward()
fn find_and_apply_group_coeff(mf: &[u8], i: &mut usize, mf_start: usize, mf_end: usize,
                              mut result_coeffs: &mut [u32]) -> Result<(), ChemikazeError> {
    let mut curr_stack_depth = 0;
    *i = mf_start;
    'out: while *i < mf_end {
        scale_forward(mf, mf_start, mf_end, *i, curr_stack_depth, &mut result_coeffs,
                      consume_coeff(mf, i, mf_end));
        if *i >= mf_end {
            break
        }
        while is_alphanumeric(mf[*i]) {
            *i += 1;
            if *i >= mf_end {
                break 'out;
            }
        }
        if mf[*i] == OP {
            curr_stack_depth += 1;
        } else if mf[*i] == CP {
            let mut chunk_end = 0;
            if *i > 0 {
                chunk_end = *i - 1;
            }
            *i += 1;
            scale_backward(mf, mf_start, chunk_end, curr_stack_depth, &mut result_coeffs,
                           consume_coeff(mf, i, mf_end));
            curr_stack_depth -= 1;
            continue;
        }
        *i += 1;
    }
    if curr_stack_depth != 0 {
        return Err(ChemikazeError{
            kind: Parsing,
            msg: String::from("The opening and closing parentheses don't match.")
        })
    }
    Ok(())
}
fn scale_forward(mf: &[u8], mf_start: usize, mf_end: usize,
                 mut lo: usize, curr_stack_depth: i32, result_coeffs: &mut [u32], group_coeff: u32) {
    if group_coeff == 1 {
        return;// usually the case, as people rarely put coefficients in front of MF
    }
    let mut depth = curr_stack_depth;
    while lo < mf_end && depth >= curr_stack_depth {
        if      mf[lo] == OP { depth += 1}
        else if mf[lo] == CP { depth -= 1}
        else if mf[lo] == DOT && depth == curr_stack_depth {
            break;
        }
        result_coeffs[lo - mf_start] *= group_coeff;
        lo += 1;
    }
}
fn scale_backward(mf: &[u8], mf_start: usize, mut hi: usize/*inclusive*/,
                  curr_stack_depth: i32, result_coeffs: &mut [u32], group_coeff: u32) {
    let mut depth = curr_stack_depth;
    while hi > mf_start && depth <= curr_stack_depth {
        if      mf[hi] == OP { depth += 1 }
        else if mf[hi] == CP { depth -= 1 }
        result_coeffs[hi - mf_start] *= group_coeff;
        hi -= 1;
    }
}
fn combine_into_atom_counts(elements: &Vec<u8>, coeffs: &Vec<u32>) -> [u32; EARTH_ELEMENT_CNT] {
    let mut result = [0u32; EARTH_ELEMENT_CNT];
    let mut i = 0;
    while i < coeffs.len() {
        if coeffs[i] > 0 {
            result[elements[i] as usize] += coeffs[i];
        }
        i+=1;
    }
    result
}

fn consume_symbol_and_coeff(mf: &[u8], i: &mut usize, mf_start: usize, mf_end: usize,
                            result_elements: &mut Vec<u8>, result_coeffs: &mut Vec<u32>) -> Result<(), ChemikazeError> {
    let result_position = *i - mf_start;
    let mut b: [u8; 2] = [mf[*i], 0]; // TODO: switch to 2 variables b0, b1? seems unnecessary..
    *i += 1;
    if *i < mf_end && is_small_letter(mf[*i]) { // we didn't reach the end and the next byte is small letter
        b[1] = mf[*i];
        *i += 1;// increment so that consumeMultiplier() starts parsing the coefficient next
    }
    result_elements[result_position] = periodic_table::get_element_by_symbol_bytes(b)?;
    result_coeffs[result_position] = consume_coeff(mf, i, mf_end);//can handle if *i is out of bounds
    Ok(())
}

fn consume_coeff(mf: &[u8], i: &mut usize, mf_end: usize) -> u32 {
    if *i >= mf_end || !is_digit(mf[*i]) {
        return 1;
    }
    let mut multiplier: u32 = 0;
    while *i < mf_end && is_digit(mf[*i]) {
        multiplier = multiplier * 10 + (mf[*i] - _0) as u32;
        *i += 1;
    }
    multiplier
}

#[cfg(test)]
mod parse_mf_test {
    use super::*;

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