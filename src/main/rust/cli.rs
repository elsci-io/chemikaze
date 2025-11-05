use std::{env, fs};
use std::time::*;
use crate::mf_parser::MfParser;

mod atom_counts;
mod periodic_table;
mod errors;
mod util;
mod mf_parser;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        panic!("[ERROR] Pass filename as a parameter!");
    }
    let filepath = &args[1];
    let repeats = 50;
    let content = fs::read_to_string(filepath).expect(&format!("Couldn't read {filepath}"));
    let mut lines: Vec<Vec<u8>> = Vec::new();
    for (i, line) in content.lines().enumerate() {
        lines.push(Vec::from(line.as_bytes()));
        let coeff = i % 20;
        if coeff < 2 {
            lines.push(format!("({line})").into_bytes());
        } else {
            lines.push(format!("({line}){coeff}").into_bytes());
        }
    }
    let mf_cnt = repeats * lines.len();

    let mut start = Instant::now();
    parse_mfs(&lines, 10);
    println!("Finished warmup in {:.3?}", start.elapsed());

    start = Instant::now();
    let hcount = parse_mfs(&lines, repeats);
    let elapsed = start.elapsed();
    println!("[RUST] {mf_cnt} MFs in {:.2?} ({} MF/s). Hydrogens: {hcount}", elapsed,
             (mf_cnt as f64 / elapsed.as_secs_f64()) as u32);
}

fn parse_mfs(mfs: &Vec<Vec<u8>>, n: usize) -> u64 {
    let mut parser = MfParser::new();
    let mut hcount = 0u64;
    for _ in 0..n {
        for mf in mfs {
            hcount += parser.parse_mf_sanitized(mf).unwrap().counts[0] as u64;
        }
    }
    hcount // return something so that this isn't optimized out
}
