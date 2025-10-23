import sys
import csv
import chemparse


def parse_all_components(formula):
    """Parse dot-separated parts with chemparse and sum all atoms."""
    total = {}
    for part in formula.split('.'):
        part = part.strip()
        if not part:
            continue
        comp = chemparse.parse_formula(part)
        for k, v in comp.items():
            total[k] = total.get(k, 0) + v
    return total


def count_hydrogens_to_csv(input_path, output_path, column_index=0):
    total_h = 0

    with open(input_path, newline='') as infile, open(output_path, 'w', newline='') as outfile:
        reader = csv.reader(infile)
        writer = csv.writer(outfile, lineterminator='\n')

        writer.writerow(["Formula", "Hydrogen_Count"])

        for row in reader:
            if not row or len(row) <= column_index:
                continue
            formula = row[column_index].strip()
            if not formula:
                continue

            try:
                comp = parse_all_components(formula)
                h_count = int(comp.get("H", 0))
                total_h += h_count
                writer.writerow([formula, h_count])
            except Exception as e:
                writer.writerow([formula, f"Error: {e}"])

    print(f"Total hydrogen atoms found: {total_h}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python count_hydrogen_csv.py <input.csv> <output.csv> [column_index]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    column_index = int(sys.argv[3]) if len(sys.argv) > 3 else 0

    count_hydrogens_to_csv(input_file, output_file, column_index)
    print(f"Done. Results saved to {output_file}")

