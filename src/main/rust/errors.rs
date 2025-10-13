#[derive(Debug)]
pub struct ChemikazeError {
    pub msg: String,
    pub kind: ErrorKind
}
#[derive(Debug)]
pub enum ErrorKind { 
    Parsing, UnknownElement
}
