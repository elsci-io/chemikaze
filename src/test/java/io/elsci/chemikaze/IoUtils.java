package io.elsci.chemikaze;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.Map;

public final class IoUtils {
    private static final Map<String, String> CACHE = new HashMap<>();

    public static String getStringFromClasspath(String path) {
        if (!CACHE.containsKey(path))
            CACHE.put(path, loadStringFromClasspath(path));
        return CACHE.get(path);
    }
    public static byte[] loadFromClasspath(final String name) {
        try (InputStream stream = IoUtils.class.getClassLoader().getResourceAsStream(name);
                ByteArrayOutputStream bao = new ByteArrayOutputStream()
        ) {
            if(stream == null)
                throw new RuntimeException("Couldn't load resource " + name);
            stream.transferTo(bao);
            return bao.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public static String loadStringFromClasspath(final String name) {
        return new String(loadFromClasspath(name), Charset.defaultCharset());
    }
}
