const A: u8 = 'A' as u8;
const Z: u8 ='Z' as u8;
#[allow(non_upper_case_globals)]
const a: u8 = 'a' as u8;
#[allow(non_upper_case_globals)]
const z: u8 ='z' as u8;
pub const _0: u8 ='0' as u8;
const _9: u8 ='9' as u8;
pub const OP: u8 ='(' as u8;
pub const CP: u8 =')' as u8;
pub const DOT: u8 ='.' as u8;
pub const SPACE: u8 =' ' as u8;

pub const fn is_digit(ascii: u8) -> bool {
    between(_0, _9, ascii)
}
pub const fn is_small_letter(ascii: u8) -> bool {
    between(a, z, ascii)
}
pub const fn is_big_letter(ascii: u8) -> bool {
    between(A, Z, ascii)
}
pub const fn is_alphanumeric(ascii: u8) -> bool {
    is_digit(ascii) || is_small_letter(ascii) || is_big_letter(ascii)
}
pub const fn between(lo: u8, hi: u8, val: u8) -> bool {
    lo <= val && val <= hi
}
pub fn index_of_start(ascii: &[u8]) -> usize {
    if ascii.is_empty() {
        return 0;
    }
    let mut i = 0;
    while i < ascii.len() && ascii[i] == SPACE {
        i += 1;
    }
    i
}
pub fn index_of_end(ascii: &[u8]) -> usize {
    if ascii.is_empty() {
        return 0
    }
    let mut i = ascii.len() - 1;
    while i != 0 && ascii[i] == SPACE {
        i -= 1;
    }
    i + 1 // end is exclusive
}
pub fn bytes_to_string(ascii: &[u8]) -> String {
    String::from_utf8(Vec::from(ascii)).unwrap_or_else(|_| {
        format!("Invalid ASCII sequence: [{}]", join(&ascii))
    })
}

pub fn join(symbol: &[u8]) -> String {
    let mut s = symbol[0].to_string();
    for b in &symbol[1..symbol.len() - 1] {
        s = s + "," + b.to_string().as_str();
    }
    s + "," + symbol[symbol.len() - 1].to_string().as_str()
}
