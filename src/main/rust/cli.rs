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
    let lines: Vec<&[u8]> = content.split("\n").map(|l|l.as_bytes()).collect();
    let mf_cnt = repeats * lines.len();

    let mut start = Instant::now();
    parse_mfs(&lines, repeats);
    println!("Finished warmup in {:.3?}", start.elapsed());

    start = Instant::now();
    parse_mfs(&lines, repeats);
    let elapsed = start.elapsed();
    println!("[RUST BENCHMARK] {mf_cnt} MFs in {:.2?} ({} MF/s)", elapsed,
             (mf_cnt as f64 / elapsed.as_secs_f64()) as u32);
}

fn parse_mfs(mfs: &Vec<&[u8]>, n: usize) -> u32 {
    let mut parser = MfParser::new();
    let mut hcount: u32 = 0;
    for _ in 0..n {
        for mf in mfs {
            hcount += parser.parse_mf_sanitized(mf).unwrap().counts[0];
        }
    }
    hcount // return something so that this isn't optimized out
}
