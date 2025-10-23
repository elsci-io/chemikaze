package io.elsci.chemikaze;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import static java.lang.System.*;

public class Cli {
    public static void main(String[] args) {
        String filename = readFilenameOrExit(args);
        byte[][] lines = readIntoLines(filename);
        MfParser parser = new MfParser();

        // *** BENCHMARK SETUP ***
        int repeats = 50;
        int mfCnt = lines.length * repeats;

        // *** WARMUP ***
        long start = System.nanoTime();
        parseMfs(parser, lines, repeats);
        out.printf("Finished warmup in %.2fs %n", (System.nanoTime() - start)/1e9F);

        // *** BENCHMARK ***
        start = System.nanoTime();
        parseMfs(parser, lines, repeats);
        long end = System.nanoTime();
        int speed = (int)(mfCnt / ((end - start)/1e9));

        out.printf("[JAVA BENCHMARK] %d MFs in %.2fs (%d MF/s) %n", mfCnt, (end-start)/1e9F, speed);
    }

    @SuppressWarnings({"UnusedReturnValue", "SameParameterValue"})
    private static int parseMfs(MfParser parser, byte[][] lines, int n) {
        int hydrogenCnt = 0;
        for (int i = 0; i < n; i++)
            for (byte[] line : lines)
                hydrogenCnt += parser.parseMf(line, 0, line.length).counts[0];
        return hydrogenCnt;
    }

    private static byte[][] readIntoLines(String filename) {
        String[] strings;
        try (FileInputStream in = new FileInputStream(filename)) {
            strings = new String(in.readAllBytes()).split("\n");
        } catch (IOException e) {
            err.println("Couldn't open the file, see error below:");
            throw new RuntimeException(e);
        }
        byte[][] lines = new byte[strings.length][];
        for (int i = 0; i < strings.length; i++)
            lines[i] = strings[i].getBytes(StandardCharsets.US_ASCII);
        return lines;
    }

    private static String readFilenameOrExit(String[] args) {
        if(args.length == 0) {
            err.println("Pass filename as a parameter!");
            exit(1);
        }
        return args[0];
    }
}
