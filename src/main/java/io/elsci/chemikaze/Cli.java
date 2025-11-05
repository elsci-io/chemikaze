package io.elsci.chemikaze;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import static java.lang.System.*;

public class Cli {
    public static void main(String[] args) {
        String filename = readFilenameOrExit(args);
        byte[][] lines = readAndGenerateMfs(filename);
        MfParser parser = new MfParser();

        // *** BENCHMARK SETUP ***
        int repeats = 50;
        int mfCnt = lines.length * repeats;

        // *** WARMUP ***
        long start = System.nanoTime();
        parseMfs(parser, lines, 15);
        out.printf("Finished warmup in %.2fs %n", (System.nanoTime() - start)/1e9F);

        // *** BENCHMARK ***
        start = System.nanoTime();
        long hcount = parseMfs(parser, lines, repeats);
        long end = System.nanoTime();
        int speed = (int)(mfCnt / ((end - start)/1e9));

        out.printf("[JAVA BENCHMARK] %d MFs in %.2fs (%d MF/s). Hydrogens: %d %n",
                mfCnt, (end-start)/1e9F, speed, hcount);
    }

    @SuppressWarnings({"UnusedReturnValue", "SameParameterValue"})
    private static long parseMfs(MfParser parser, byte[][] lines, int n) {
        long hydrogenCnt = 0;
        for (int i = 0; i < n; i++)
            for (byte[] line : lines)
                hydrogenCnt += parser.parseSanitized(line, 0, line.length).counts[0];
        return hydrogenCnt;
    }

    private static byte[][] readAndGenerateMfs(String filename) {
        String[] strings;
        try (FileInputStream in = new FileInputStream(filename)) {
            strings = new String(in.readAllBytes()).split("\n");
        } catch (IOException e) {
            err.println("Couldn't open the file, see error below:");
            throw new RuntimeException(e);
        }
        byte[][] lines = new byte[strings.length*2][];
        for (int i = 0; i < strings.length; i++) {
            lines[i*2] = strings[i].getBytes(StandardCharsets.US_ASCII);
            StringBuilder b = new StringBuilder()
                    .append('(')
                    .append(strings[i])
                    .append(')');
            int coeff = i % 20;
            if(coeff > 1)
                b.append(coeff);
            lines[i*2+1] = b.toString().getBytes(StandardCharsets.US_ASCII);
        }
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
