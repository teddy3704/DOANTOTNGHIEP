package com.dlu.lmsmobile.security.auth;

import java.util.Optional;

/** Checks a login (student code or username) and password; the role always comes from the server side. */
public interface AuthProvider {
    /** @return the user when the credentials are right, empty when they are wrong. */
    Optional<AuthenticatedUser> authenticate(String login, String password);

    record AuthenticatedUser(long userId, String role) {}

    /** The identity source cannot answer (e.g. LMS mobile web service disabled); not a wrong password. */
    class UnavailableException extends RuntimeException {
        public UnavailableException(String message) { super(message); }
    }
}
