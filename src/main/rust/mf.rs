use crate::atom_counts::AtomCounts;
use crate::errors::ChemikazeError;
use crate::errors::ErrorKind::Parsing;
use crate::periodic_table::EARTH_ELEMENT_CNT;
use crate::util::bytes_to_string;

mod atom_counts;
mod periodic_table;
mod errors;
mod util;

const MF_PUNCTUATION: [u8;7] = ['(' as u8, ')' as u8, '+' as u8, '-' as u8, '.' as u8, '[' as u8, ']' as u8];
const A: u8 = 'A' as u8;
const Z: u8 ='Z' as u8;
#[allow(non_upper_case_globals)]
const a: u8 = 'a' as u8;
#[allow(non_upper_case_globals)]
const z: u8 ='z' as u8;
const _0: u8 ='0' as u8;
const _9: u8 ='9' as u8;

pub fn parse_mf(mf: &str) -> Result<AtomCounts, ChemikazeError> {
    parse_mf_ascii(mf.as_bytes())
}
pub fn parse_mf_ascii(mf: &[u8]) -> Result<AtomCounts, ChemikazeError> {
    parse_mf_ascii_chunk(mf, 0, mf.len())
}
pub fn parse_mf_ascii_chunk(mf: &[u8], mf_start: usize, mf_end: usize) -> Result<AtomCounts, ChemikazeError> {
    let mut coeff: Vec<u32> = vec![0u32; mf_end - mf_start];
    let mut elements: Vec<u8> = vec![0u8; mf_end - mf_start];
    let mut i = mf_start;

    let res = read_symbols_and_coeffs(mf, &mut i, mf_start, mf_end, &mut elements, &mut coeff);
    if res.is_err() {
        return Err(res.unwrap_err());
    }
    Ok(AtomCounts{counts: [0; EARTH_ELEMENT_CNT]})
}

fn read_symbols_and_coeffs(mf: &[u8], i: &mut usize, mf_start: usize, mf_end: usize,
                           result_elements: &mut Vec<u8>, coeff: &mut Vec<u32>) -> Result<(), ChemikazeError> {
    *i = mf_start;
    while *i < mf_end {
        if between(A, Z, mf[*i]) {
            let result = consume_symbol_and_coeff(mf, i, mf_start, mf_end, result_elements, coeff);
            if result.is_err() {
                let mf_str = bytes_to_string(&mf[mf_start..mf_end]);
                let msg = String::from(format!("Invalid Molecular Formula: {mf_str}. Details: {}",
                                               result.unwrap_err().msg));
                return Err(ChemikazeError {
                    kind: Parsing,
                    msg
                });
            }
        } else if MF_PUNCTUATION.contains(&mf[*i]) {
            *i += 1;
        } else {
            let mf_str = bytes_to_string(&mf[mf_start..mf_end]);
            return Err(ChemikazeError {
                kind: Parsing,
                msg: String::from(format!("Invalid Molecular Formula: {}", mf_str))
            });
        }
    }
    Ok(())
}
fn consume_symbol_and_coeff(mf: &[u8], i: &mut usize, mf_start: usize, mf_end: usize,
                            result_elements: &mut Vec<u8>, result_coeffs: &mut Vec<u32>) -> Result<(), ChemikazeError> {
    let result_position = *i - mf_start;
    let mut b: [u8; 2] = [mf[*i], 0];
    *i += 1;
    if *i < mf_end && is_small_letter(mf[*i]) { // we didn't reach the end and the next byte is small letter
        b[1] = mf[*i];
        *i += 1;// increment so that consumeMultiplier() starts parsing the coefficient next
    }
    let result = periodic_table::get_element_by_symbol_bytes(b);
    if result.is_err() {
        return Err(result.err().unwrap());
    }
    result_elements[result_position] = result?;
    result_coeffs[result_position] = consume_number(mf, i, mf_end);//can handle if *i is out of bounds
    Ok(())
}

fn consume_number(mf: &[u8], i: &mut usize, mf_end: usize) -> u32 {
    if *i >= mf_end || !is_digit(mf[*i]) {
        return 1;
    }
    let mut multiplier: u32 = 0;
    while *i < mf_end {
        multiplier = multiplier * 10 + (mf[*i] - _0) as u32;
        *i += 1;
    }
    multiplier
}


fn main() {
    match periodic_table::get_element_by_symbol_str("Na") {
        Ok(element) => println!("{}", element),
        Err(e) => eprintln!("{}", e.msg)
    }
}

fn is_digit(ascii: u8) -> bool {
    between(_0, _9, ascii)
}
fn is_small_letter(ascii: u8) -> bool {
    between(a, z, ascii)
}
fn between(lo: u8, hi: u8, val: u8) -> bool {
    lo <= val && val <= hi
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn simple_mf_is_parsed_into_counts() {
        assert_eq!("H2O", parse_mf("H2O").unwrap().to_string());
    }
    #[test]
    fn empty_mf_creates_empty_counts() {
        let mf = parse_mf("");
        assert_eq!(mf.unwrap().counts, [0u8; EARTH_ELEMENT_CNT]);
        assert_eq!("", parse_mf("H2O").unwrap().to_string());
    }
    #[test]
    fn errs_if_symbol_is_not_known() {
        let err = parse_mf("A").err().unwrap();
        assert_eq!(Parsing, err.kind);
        assert_eq!("Invalid Molecular Formula: A. Details: Unknown chemical symbol: A", err.msg);

        let err = parse_mf("o").err().unwrap();
        assert_eq!(Parsing, err.kind);
        assert_eq!("Invalid Molecular Formula: o", err.msg);
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