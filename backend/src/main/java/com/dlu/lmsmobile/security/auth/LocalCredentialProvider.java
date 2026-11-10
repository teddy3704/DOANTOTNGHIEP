package com.dlu.lmsmobile.security.auth;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.security.SecureRandom;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Demo accounts from server configuration, BCrypt only (cost 12 when hashed by tools\Set-DemoPasswords.ps1).
 * An unknown login still runs one BCrypt comparison against a dummy hash, so both failures take the same time.
 */
public class LocalCredentialProvider implements AuthProvider {
    public static final int COST = 12;
    private static final Set<String> ROLES = Set.of("STUDENT", "TEACHER");
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(COST);
    private final Map<String, AuthProperties.Account> accounts = new HashMap<>();
    private final String dummyHash;

    public LocalCredentialProvider(List<AuthProperties.Account> users) {
        for (AuthProperties.Account a : users) {
            if (a.getLogin() == null || a.getLogin().isBlank() || a.getUserId() <= 0 || !ROLES.contains(a.getRole())
                    || a.getBcrypt() == null || !a.getBcrypt().startsWith("$2")) {
                throw new IllegalStateException("Invalid local account entry (values withheld)");
            }
            if (accounts.put(normalize(a.getLogin()), a) != null) {
                throw new IllegalStateException("Duplicate local login (values withheld)");
            }
        }
        byte[] random = new byte[24];
        new SecureRandom().nextBytes(random);
        dummyHash = encoder.encode(HexFormat.of().formatHex(random));
    }

    /** Logins compare without surrounding spaces and case ("TEACHER02" = "teacher02"). */
    public static String normalize(String login) {
        return login.trim().toLowerCase(Locale.ROOT);
    }

    @Override
    public Optional<AuthenticatedUser> authenticate(String login, String password) {
        AuthProperties.Account a = accounts.get(normalize(login));
        if (a == null) {
            encoder.matches(password, dummyHash);
            return Optional.empty();
        }
        return encoder.matches(password, a.getBcrypt())
            ? Optional.of(new AuthenticatedUser(a.getUserId(), a.getRole()))
            : Optional.empty();
    }

    public int size() { return accounts.size(); }
}
