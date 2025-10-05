mod atom_counts;
mod periodic_table;



fn main() {
    match periodic_table::get_element_by_symbol_str("1") {
        Ok(element) => println!("{}", element),
        Err(e) => eprintln!("{}", e)
    }
}