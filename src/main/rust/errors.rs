#[derive(Debug)]
pub struct ChemikazeError {
    pub msg: String,
    pub kind: ErrorKind
}
#[derive(Debug, PartialEq, Eq)]
pub enum ErrorKind { 
    Parsing, UnknownElement
}
