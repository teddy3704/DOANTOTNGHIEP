package com.dlu.lmsmobile;

import org.junit.jupiter.api.Test;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.ApplicationRunner;
import java.util.Arrays;
import static org.junit.jupiter.api.Assertions.assertFalse;

class LmsMobileBackendApplicationTests {
    @Test void applicationDeclaresNoAutomaticDatabaseStartupRunner() {
        assertFalse(Arrays.stream(LmsMobileBackendApplication.class.getDeclaredMethods())
                .anyMatch(m -> CommandLineRunner.class.isAssignableFrom(m.getReturnType())
                        || ApplicationRunner.class.isAssignableFrom(m.getReturnType())));
    }
}
