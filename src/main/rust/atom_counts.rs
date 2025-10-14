use std::fmt::{Display, Formatter, Pointer, Write};
use crate::periodic_table;
use crate::periodic_table::EARTH_ELEMENT_CNT;

#[derive(Debug)]
pub struct AtomCounts {
    pub counts: [u8; EARTH_ELEMENT_CNT]
}

impl Display for AtomCounts {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        for (i, val) in self.counts.iter().enumerate() {
            if *val != 0 {
                f.write_str(periodic_table::EARTH_SYMBOLS[i])?;
            }
            if *val > 1 {
                f.write_str(format!("{}", *val).as_str())?;
            }
        }
        Ok(())
    }
}