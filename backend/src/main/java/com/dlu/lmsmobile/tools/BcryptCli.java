package com.dlu.lmsmobile.tools;

import com.dlu.lmsmobile.security.auth.LocalCredentialProvider;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

/**
 * Hashes one password per stdin line with BCrypt (cost 12) and prints one hash per line. Used by
 * tools\Set-DemoPasswords.ps1 through the backend JAR, so the hashing is Spring Security's, not hand-written.
 * Never prints or logs the input.
 */
public final class BcryptCli {
    private BcryptCli() {}

    public static void main(String[] args) throws IOException {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(LocalCredentialProvider.COST);
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
        String line;
        while ((line = in.readLine()) != null) {
            if (line.isEmpty() || line.length() > 128) {
                System.err.println("Password must be 1-128 characters");
                System.exit(2);
            }
            System.out.println(encoder.encode(line));
        }
    }
}
