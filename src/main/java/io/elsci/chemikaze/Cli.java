package io.elsci.chemikaze;

import java.io.FileInputStream;
import java.io.IOException;

import static java.lang.System.*;

public class Cli {
    public static void main(String[] args) {
        String filename = readFilenameOrExit(args);
        String[] lines = readIntoLines(filename);
        MfParser parser = new MfParser();

        // *** BENCHMARK SETUP ***
        int repeats = 50;
        int mfCnt = lines.length * repeats;

        // *** WARMUP ***
        long start = System.nanoTime();
        parseMfs(parser, lines, repeats);
        out.println("Finished warmup in " + durationSince(start));

        // *** BENCHMARK ***
        start = System.nanoTime();
        parseMfs(parser, lines, repeats);
        out.println("Finished processing "+ mfCnt +" MFs in " + durationSince(start));
    }

    private static String durationSince(long startNanosec) {
        double diff = System.nanoTime() - startNanosec;
        return diff / 1e9 + " s";
    }

    @SuppressWarnings({"UnusedReturnValue", "SameParameterValue"})
    private static int parseMfs(MfParser parser, String[] lines, int n) {
        int hydrogenCnt = 0;
        for (int i = 0; i < n; i++)
            for (String line : lines)
                hydrogenCnt += parser.parseMf(line).counts[0];
        return hydrogenCnt;
    }

    private static String[] readIntoLines(String filename) {
        try (FileInputStream in = new FileInputStream(filename)) {
            return new String(in.readAllBytes()).split("\n");
        } catch (IOException e) {
            err.println("Couldn't open the file, see error below:");
            throw new RuntimeException(e);
        }
    }

    private static String readFilenameOrExit(String[] args) {
        if(args.length == 0) {
            err.println("Pass filename as a parameter!");
            exit(1);
        }
        return args[0];
    }
}
