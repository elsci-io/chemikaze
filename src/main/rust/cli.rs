use std::{env, fs};
use std::time::*;

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
    let lines: Vec<&str> = content.split("\n").collect();
    let mf_cnt = repeats * lines.len();

    let mut start = Instant::now();
    parse_mfs(&lines, repeats);
    println!("Finished warmup in {:.3?}", start.elapsed());

    start = Instant::now();
    parse_mfs(&lines, repeats);
    println!("Finished processing {mf_cnt} MFs in {:.3?}", start.elapsed());
}

fn parse_mfs(mfs: &Vec<&str>, n: usize) -> u32 {
    let mut hcount: u32 = 0;
    for _ in 0..n {
        for mf in mfs {
            hcount += mf_parser::parse_mf(mf).unwrap().counts[0];
        }
    }
    hcount // return something so that this isn't optimized out
}
