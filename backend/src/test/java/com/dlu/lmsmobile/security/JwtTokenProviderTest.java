package com.dlu.lmsmobile.security;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTCreator;
import com.auth0.jwt.algorithms.Algorithm;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.Date;
import static org.junit.jupiter.api.Assertions.*;

class JwtTokenProviderTest {
    private static final String KEY = "isolated-test-only-secret-not-for-runtime-1234";
    private final JwtTokenProvider provider = new JwtTokenProvider(KEY, 3600000);

    private JWTCreator.Builder claims() {
        return JWT.create().withIssuer("dlu-lms-group").withAudience("dlu-lms-mobile")
                .withSubject("205").withClaim("role", "STUDENT")
                .withIssuedAt(Date.from(Instant.now().minusSeconds(60)))
                .withExpiresAt(Date.from(Instant.now().plusSeconds(60)));
    }

    @Test void validTokenHasExpectedIdentityAndExpiry() {
        var decoded = provider.validateToken(provider.generateToken(205L, "STUDENT"));
        assertNotNull(decoded);
        assertEquals("205", decoded.getSubject());
        assertEquals("STUDENT", decoded.getClaim("role").asString());
        assertNotNull(decoded.getExpiresAt());
    }

    @Test void invalidRoleSubjectIssuerAudienceExpiryAndSignatureAreRejected() {
        assertNull(provider.validateToken("not.a.jwt"));
        assertNull(provider.validateToken(claims().withClaim("role", "ADMIN").sign(Algorithm.HMAC256(KEY))));
        assertNull(provider.validateToken(claims().withSubject("-1").sign(Algorithm.HMAC256(KEY))));
        assertNull(provider.validateToken(claims().withSubject("not-numeric").sign(Algorithm.HMAC256(KEY))));
        assertNull(provider.validateToken(claims().withIssuer("other").sign(Algorithm.HMAC256(KEY))));
        assertNull(provider.validateToken(claims().withAudience("other").sign(Algorithm.HMAC256(KEY))));
        assertNull(provider.validateToken(claims().withExpiresAt(Date.from(Instant.now().minusSeconds(1)))
                .sign(Algorithm.HMAC256(KEY))));
        assertNull(provider.validateToken(claims().sign(Algorithm.HMAC256(KEY + "wrong"))));
        assertNull(provider.validateToken(JWT.create().withIssuer("dlu-lms-group").withAudience("dlu-lms-mobile")
                .withSubject("205").withClaim("role", "STUDENT").sign(Algorithm.HMAC256(KEY))));
    }

    @Test void missingWeakOrPlaceholderSecretsAndInvalidTtlFailFast() {
        for (String secret : new String[] {"", "short", "${JWT_SECRET}"}) {
            assertThrows(IllegalArgumentException.class, () -> new JwtTokenProvider(secret, 3600000));
        }
        assertThrows(IllegalArgumentException.class, () -> new JwtTokenProvider(KEY, 0));
        assertThrows(IllegalArgumentException.class, () -> provider.generateToken(205L, "ADMIN"));
    }
}
