use crate::errors::{ChemikazeError, ErrorKind};

/// They are roughly sorted by popularity in organic chemistry. Well, at least the first elements
/// are. Doesn't contain elements that would never be used in organic chemistry.
pub const EARTH_SYMBOLS: [&str; 85] = [
    "H", "C", "O", "N", "P", "F", "S", "Br", "Cl", "Na", "Li", "Fe", "K", "Ca", "Mg", "Ni", "Al",
    "Pd", "Sc", "V", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B",
    "Kr", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I",
    "Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb",
    "Lu", "Hf", "Ta", "Tc", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa",
    "U", "He", "Ne", "Ar",
];
/// Same as EARTH_SYMBOLS, but keep symbols as bytes so that we don't have to turn them into
/// String on each lookup. Each symbol is 2 bytes: for 1-symbol elements like H, the 2nd byte is 0.
const EARTH_SYMBOLS_AS_BYTES: [u8; EARTH_SYMBOLS.len()*2] = build_symbols_as_bytes();
/// The size of {@link #ELEMENTHASH_TO_ELEMENT} hash table
const INDEX_BUCKET_CNT: usize = 512;
const INDEX_HASH_MASK: usize = INDEX_BUCKET_CNT - 1;
const ELEMENTHASH_TO_ELEMENT: [u8; INDEX_BUCKET_CNT] = build_index();

pub fn get_element_by_symbol_str(symbol: &str) -> Result<u8, ChemikazeError> {
    let ascii = symbol.as_bytes();
    let mut bytes: [u8; 2] = [0; 2];
    bytes[0] = ascii[0];
    if ascii.len() > 1 {
        bytes[1] = ascii[1];
    }
    get_element_by_symbol_bytes(bytes)
}
///
/// The 2 bytes that represent symbol ASCII (like ['H', 'e']). For 1-byte symbols: ['H', 0].
///
pub fn get_element_by_symbol_bytes(bytes: [u8; 2]) -> Result<u8, ChemikazeError> {
    let bucket = hash(bytes);
    let element = ELEMENTHASH_TO_ELEMENT[bucket];
    let i = (element * 2) as usize;
    if EARTH_SYMBOLS_AS_BYTES[i] != bytes[0] || EARTH_SYMBOLS_AS_BYTES[i+1] != bytes[1] {
        let element_str = String::from_utf8(Vec::from(bytes)).unwrap_or_else(|_| {
            format!("Invalid ASCII sequence: [{}]", join(&bytes))
        });
        return Err(ChemikazeError {
            msg: String::from(format!("Unknown chemical symbol: {element_str}")),
            kind: ErrorKind::UnknownElement
        });
    }
    Ok(element)
}
pub const fn hash(symbol: [u8; 2]) -> usize {
    // Ran an experiment, and 277 is one of few multipliers that gave no collisions in 512-sized
    // hash table. Couldn't achieve the same with subtractions or shifts, no matter the order of b0
    // and b1.
    ((symbol[0] as usize * 277) ^ symbol[1] as usize) & INDEX_HASH_MASK
}

fn join(symbol: &[u8]) -> String {
    let mut s = symbol[0].to_string();
    for b in &symbol[1..symbol.len() - 1] {
        s = s + "," + b.to_string().as_str();
    }
    s + "," + symbol[symbol.len() - 1].to_string().as_str()
}

const fn build_index() ->  [u8; INDEX_BUCKET_CNT] {
    // a precaution to see if we made an error in the hash()
    let mut taken_buckets = [false; INDEX_BUCKET_CNT];
    let mut result = [0; INDEX_BUCKET_CNT];
    let mut i = 0;
    while i < EARTH_SYMBOLS.len() {
        let bucket = hash([EARTH_SYMBOLS_AS_BYTES[i*2], EARTH_SYMBOLS_AS_BYTES[i*2+1]]);
        if taken_buckets[i] {
            panic!("Wrong hash function for the Symbol HashTable: 2 symbols were mapped to the same bucket")
        }
        taken_buckets[i] = true;
        result[bucket] = i as u8;
        i += 1;
    }
    result
}
const fn build_symbols_as_bytes() -> [u8; EARTH_SYMBOLS.len()*2] {
    let mut symbol_bytes: [u8; EARTH_SYMBOLS.len()*2] = [0u8; EARTH_SYMBOLS.len()*2];
    let mut i = 0;
    while i < EARTH_SYMBOLS.len() {
        let b = EARTH_SYMBOLS[i].as_bytes();
        let j = i * 2;
        symbol_bytes[j] = b[0];
        if b.len() > 1 {
            symbol_bytes[j + 1] = b[1];
        }
        i += 1;
    }
    symbol_bytes
}