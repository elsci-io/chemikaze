mod atom_counts;
mod periodic_table;
mod errors;

fn main() {
    match periodic_table::get_element_by_symbol_str("Na") {
        Ok(element) => println!("{}", element),
        Err(e) => eprintln!("{}", e.msg)
    }
}