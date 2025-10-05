pub struct ChemikazeError {
    pub msg: String,
    pub kind: ErrorKind
}
pub enum ErrorKind { 
    Parsing, UnknownElement
}