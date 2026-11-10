package com.dlu.lmsmobile.security.auth;

import com.dlu.lmsmobile.security.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * POST /api/v1/auth/login: tries the enabled providers in order, issues the same JWT as before (sub = userId,
 * role decided by the server). One generic failure for a wrong password and for an unknown account.
 * Logs only the outcome, the user id on success and the login length - never the login or the password.
 */
public class LoginService {
    private static final Logger log = LoggerFactory.getLogger(LoginService.class);
    private final List<AuthProvider> providers;
    private final LoginAttemptLimiter limiter;
    private final JwtTokenProvider tokens;

    public LoginService(List<AuthProvider> providers, LoginAttemptLimiter limiter, JwtTokenProvider tokens) {
        this.providers = List.copyOf(providers);
        this.limiter = limiter;
        this.tokens = tokens;
    }

    public boolean configured() { return !providers.isEmpty(); }

    public Map<String, String> login(String login, String password, String client) {
        if (providers.isEmpty()) throw new AuthProvider.UnavailableException("No login provider configured");
        String key = LoginAttemptLimiter.key(login, client);
        long wait = limiter.retryAfterSeconds(key);
        if (wait > 0) {
            log.info("login result=LOCKED loginLength={}", login.length());
            throw new LockedException(wait);
        }
        Optional<AuthProvider.AuthenticatedUser> user = Optional.empty();
        for (AuthProvider p : providers) {
            user = p.authenticate(login, password);
            if (user.isPresent()) break;
        }
        if (user.isEmpty()) {
            limiter.recordFailure(key);
            log.info("login result=FAIL loginLength={}", login.length());
            throw new FailedException();
        }
        limiter.recordSuccess(key);
        AuthProvider.AuthenticatedUser u = user.get();
        log.info("login result=OK userId={} role={}", u.userId(), u.role());
        return Map.of("token", tokens.generateToken(u.userId(), u.role()),
            "role", u.role(), "userId", Long.toString(u.userId()));
    }

    /** Wrong password or unknown account: the same answer for both. */
    public static class FailedException extends RuntimeException {
        public FailedException() { super("invalid credentials"); }
    }

    public static class LockedException extends RuntimeException {
        private final long retryAfterSeconds;
        public LockedException(long retryAfterSeconds) {
            super("locked");
            this.retryAfterSeconds = retryAfterSeconds;
        }
        public long retryAfterSeconds() { return retryAfterSeconds; }
    }
}
