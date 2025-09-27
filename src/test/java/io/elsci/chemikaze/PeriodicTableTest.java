package io.elsci.chemikaze;

import org.junit.Ignore;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import static io.elsci.chemikaze.PeriodicTable.*;

public class PeriodicTableTest {
    @Test @Ignore
    public void findPerfectHashFunction() {
        Set<String> popularElements = Set.of(
                "H", "B", "C", "N", "O", "F", "Na", "Mg", "Al", "Si", "P", "S", "Cl",
                "K", "Ca", "Fe", "Co", "Ni","Cu", "Zn", "Br", "Pd", "Ag", "I"
        );
        int minCollisions = 1000;
        int minMultiplier = -1, minSubtract = -1;
//        Map<String, Integer> collisionFrequencies = new HashMap<>();
        for(int i = minMultiplier; i < 97; i++) {
            for(int s = 0; s < 100; s++) {
                Map<Integer, String> hashes = new HashMap<>(INDEX_BUCKET_CNT);
                int collisions = 0;
                for (String e : EARTH_SYMBOLS)
                    if (hashes.put(hash(e, i, s), e) != null) {
                        if(popularElements.contains(e))
                            continue;
                        collisions++;
                    }
                if (collisions == 0) {
                    System.out.println("Zero collisions: x*" + i + "-"+s);
                }
//                collisionFrequencies.put("m"+i+"s"+s, collisions);
            }
        }
//        System.out.println(collisionFrequencies);
        System.out.println("Best multiplier: "+minMultiplier + ", subtact=" +minSubtract +" minCollisions="+minCollisions);
    }
}