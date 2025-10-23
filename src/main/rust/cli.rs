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
    let repeats = 5;
    let content = fs::read_to_string(filepath).expect(&format!("Couldn't read {filepath}"));
    let lines: Vec<&str> = content.split("\n").collect();
    let mf_cnt = repeats * lines.len();


    let start = Instant::now();
    let hydrogen_atoms = parse_mfs(&lines, repeats);
    let elapsed = start.elapsed();

    let gb: f64 = 1024.0 * 1024.0 * 1024.0;
    let secs = elapsed.as_secs_f64();
    let mfs_per_sec = mf_cnt as f64 / secs;
    let bytes_total = (lines.iter().map(|s| s.len()).sum::<usize>() * repeats) as f64;
    let gb_per_sec = bytes_total / secs / gb;

    println!(
        "[RUST BENCHMARK] {mf_cnt} - {hydrogen_atoms} MFs in {:.2?} ({:.0} MF/s, {:.3} GB/s)",
        elapsed,
        mfs_per_sec,
        gb_per_sec
    );
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
