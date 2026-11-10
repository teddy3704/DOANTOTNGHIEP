package com.dlu.lmsmobile.security;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Set;

@Component
public class JwtTokenProvider {
    private static final Set<String> ROLES = Set.of("STUDENT", "TEACHER");
    private static final String ISSUER = "dlu-lms-group";
    private static final String AUDIENCE = "dlu-lms-mobile";
    private final Algorithm algorithm;
    private final long expirationMs;

    public JwtTokenProvider(@Value("${app.jwt.secret}") String secret,
                            @Value("${app.jwt.expirationMs:3600000}") long expirationMs) {
        if (secret == null || secret.isBlank() || secret.startsWith("${")
                || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalArgumentException("JWT_SECRET must be an explicit random secret of at least 32 bytes");
        }
        if (expirationMs <= 0 || expirationMs > 86400000L) {
            throw new IllegalArgumentException("JWT expiration must be between 1 millisecond and 24 hours");
        }
        this.algorithm = Algorithm.HMAC256(secret);
        this.expirationMs = expirationMs;
    }

    public String generateToken(Long userId, String role) {
        if (userId == null || userId <= 0 || role == null || !ROLES.contains(role)) {
            throw new IllegalArgumentException("Invalid token identity");
        }
        Instant now = Instant.now();
        return JWT.create().withIssuer(ISSUER).withAudience(AUDIENCE)
                .withSubject(userId.toString()).withClaim("role", role)
                .withIssuedAt(Date.from(now)).withExpiresAt(Date.from(now.plusMillis(expirationMs)))
                .sign(algorithm);
    }

    public DecodedJWT validateToken(String token) {
        try {
            DecodedJWT decoded = JWT.require(algorithm).withIssuer(ISSUER).withAudience(AUDIENCE)
                    .withClaimPresence("exp").withClaimPresence("iat").build().verify(token);
            if (decoded.getSubject() == null || Long.parseLong(decoded.getSubject()) <= 0
                    || !ROLES.contains(decoded.getClaim("role").asString())) {
                return null;
            }
            return decoded;
        } catch (JWTVerificationException | IllegalArgumentException | NullPointerException ex) {
            return null;
        }
    }
}
