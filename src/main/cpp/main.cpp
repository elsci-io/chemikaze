#include "profiler.hpp"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <stdio.h>
#include <stdint.h>
#include <cstring>
#include <time.h>
#include "tests.hpp"
#include "parser.hpp"

std::vector<char*> get_data(std::ifstream& file) {
    std::vector<char*> values;
    std::string line;
    while (std::getline(file, line)) {
        if (!line.empty()) {
            char* copy = new char[line.size() + 1];
            std::memcpy(copy, line.c_str(), line.size() + 1);
            values.push_back(copy);
        }
    }
    return values;
}

long getFileSize(const std::string& fileName) {
    std::ifstream file(fileName, std::ios::in | std::ios::binary);
    if (!file.is_open()) {
        return -1; // Indicate error
    }
    file.seekg(0, std::ios::end);
    long fileSize = file.tellg();
    file.close();
    return fileSize;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <csv_file>\n";
        return 1;
    }

    std::ifstream file(argv[1]);
    if (!file) {
        std::cerr << "Error: cannot open file " << argv[1] << "\n";
        return 1;
    }

    auto formulas = get_data(file);
    init_element_index();
    startProfiling();
    clock_t t0 = clock();

    int hydrogens = 0;
    {
        TimeThroughput("Parse formulas", getFileSize(argv[1]))
        for (int i = 0; i < formulas.size(); ++i) {
            const char* s = formulas[i];
            AtomCount atom_count = parse_mf(&s);
            hydrogens += atom_count.atoms[0];
        }
    }

    clock_t t1 = clock();
    f64 elapsed_rdtsc = endProfilingAndPrint();

    double elapsed_std = (double)(t1 - t0) / CLOCKS_PER_SEC;
    printf("Std-lib elapsed: %.6f s\n", elapsed_std);
    printf("RDTSC elapsed : %.6f s\n", elapsed_rdtsc);
    printf("Ratio (RDTSC/std): %.3f\n", elapsed_rdtsc / elapsed_std);

    printf("MF/s (std-lib): %.3f\n", formulas.size() / elapsed_std);
    printf("MF/s (rdtsc)  : %.3f\n", formulas.size() / elapsed_rdtsc);
    printf("Number of hydrogens: %d\n", hydrogens);

    run_all_tests();
    return 0;
}
