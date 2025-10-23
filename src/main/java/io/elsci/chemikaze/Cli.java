package io.elsci.chemikaze;

import java.io.*;
import static java.lang.System.*;

public class Cli {
    public static void main(String[] args) {
        String filename = readFilenameOrExit(args);
        byte[] fileBytes = readAllBytes(filename);
        String[] lines = new String(fileBytes).split("\n");
        MfParser parser = new MfParser();

        int repeats = 50;
        int mfCnt = lines.length * repeats;

        long start = nanoTime();
        parseMfs(parser, lines, repeats); // warmup
        out.println("Finished warmup in " + durationSince(start));

        start = nanoTime();
        int hydrogenCnt = parseMfs(parser, lines, repeats);
        long end = nanoTime();

        double seconds = (end - start) / 1e9;
        double throughputMf = mfCnt / seconds;
        double throughputBytes = (fileBytes.length * repeats) / seconds / 1e6; // MB/s

        out.printf(
            "[JAVA BENCHMARK] %,d %,d MFs in %.2fs (%,.0f MF/s, %.2f MB/s)%n",
            mfCnt, hydrogenCnt, seconds, throughputMf, throughputBytes
        );

        // write results to CSV file
        writeResultsCsv(lines, parser);
        out.println("Results saved to test_java.csv");
    }

    private static byte[] readAllBytes(String filename) {
        try (FileInputStream in = new FileInputStream(filename)) {
            return in.readAllBytes();
        } catch (IOException e) {
            err.println("Couldn't open the file:");
            throw new RuntimeException(e);
        }
    }

    private static String durationSince(long startNanosec) {
        return duration(startNanosec, nanoTime());
    }

    private static String duration(long start, long end) {
        return Math.round(((end - start) / 1e9) * 100) / 100 + "s";
    }

    private static int parseMfs(MfParser parser, String[] lines, int n) {
        int hydrogenCnt = 0;
        for (int i = 0; i < n; i++)
            for (String line : lines)
                hydrogenCnt += parser.parseMf(line).counts[0];
        return hydrogenCnt;
    }

    private static void writeResultsCsv(String[] lines, MfParser parser) {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter("test_java.csv"))) {
            writer.write("Formula,Hydrogen_Count\n");
            int totalHydrogen = 0;
            for (String line : lines) {
                line = line.trim();
                if (line.isEmpty()) continue;
                int hCount = parser.parseMf(line).counts[0];
                totalHydrogen += hCount;
                writer.write(line + "," + hCount + "\n");
            }
            writer.write("TOTAL," + totalHydrogen + "\n");
        } catch (IOException e) {
            err.println("Error writing test_java.csv: " + e.getMessage());
        }
    }

    private static String readFilenameOrExit(String[] args) {
        if (args.length == 0) {
            err.println("Pass filename as a parameter!");
            exit(1);
        }
        return args[0];
    }
}

