pub const EARTH_SYMBOLS: [&str; 85] = [
    "H", "C", "O", "N", "P", "F", "S", "Br", "Cl", "Na", "Li", "Fe", "K", "Ca", "Mg", "Ni", "Al",
    "Pd", "Sc", "V", "Cu", "Cr", "Mn", "Co", "Zn", "Ga", "Ge", "As", "Se", "Ti", "Si", "Be", "B",
    "Kr", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Ru", "Rh", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I",
    "Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb",
    "Lu", "Hf", "Ta", "Tc", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Th", "Pa",
    "U", "He", "Ne", "Ar",
];
const INDEX_BUCKET_CNT: usize = 512;
const ELEMENTHASH_TO_ELEMENT: [u8; INDEX_BUCKET_CNT] = {
    // a precaution to see if we made an error in the hash()
    let mut taken_buckets = [false; INDEX_BUCKET_CNT];
    let mut result = [0; INDEX_BUCKET_CNT];
    let mut i = 0;
    while i < EARTH_SYMBOLS.len() {
        let bucket = hash(EARTH_SYMBOLS[i].as_bytes());
        if taken_buckets[i] {
            panic!("Wrong hash function for the Symbol HashTable: 2 symbols were mapped to the same bucket")
        }
        taken_buckets[i] = true;
        result[bucket] = i as u8;
        i += 1;
    }
    result
};

pub fn get_element_by_symbol_str(symbol: &str) -> Result<u8, String> {
    get_element_by_symbol(symbol.as_bytes())
}
pub fn get_element_by_symbol(symbol: &[u8]) -> Result<u8, String> {
    let bucket = hash(symbol);
    let element = ELEMENTHASH_TO_ELEMENT[bucket];
    if EARTH_SYMBOLS[element as usize].as_bytes().eq(symbol) {
        return Ok(element);
    }
    let s = match str::from_utf8(symbol) {
        Ok(s) => format!("No such Chemical Element: {}", s),
        Err(e) => String::from("Invalid ASCII sequence in the Chemical Element symbol")
    };
    Err(format!("No such symbol: {}", s))
}

const A: i16 = 65;

const fn hash(element: &[u8]) -> usize {
    if element.len() == 1 { ((element[0] as i16 - A) & 0x01FF) as usize }
    else                  { ((element[0] as u16 * 21 + element[1] as u16) & 0x01FF) as usize }
}