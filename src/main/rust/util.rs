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
