pub const _0: u8 ='0' as u8;
const _9: u8 ='9' as u8;
pub const OP: u8 ='(' as u8;
pub const CP: u8 =')' as u8;
pub const DOT: u8 ='.' as u8;

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
