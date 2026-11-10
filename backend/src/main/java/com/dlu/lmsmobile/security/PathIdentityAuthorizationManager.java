package com.dlu.lmsmobile.security;

import org.springframework.security.authorization.AuthorizationDecision;
import org.springframework.security.authorization.AuthorizationManager;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.access.intercept.RequestAuthorizationContext;

import java.util.function.Supplier;
import java.util.regex.Pattern;

/** Path IDs are resource selectors, never caller-supplied authentication. */
final class PathIdentityAuthorizationManager implements AuthorizationManager<RequestAuthorizationContext> {
    private final String role;
    private final Pattern actorPath;

    PathIdentityAuthorizationManager(String role, String actorPath) {
        this.role = "ROLE_" + role;
        this.actorPath = Pattern.compile(actorPath);
    }

    @Override
    public AuthorizationDecision check(Supplier<Authentication> authentication,
                                        RequestAuthorizationContext context) {
        Authentication caller = authentication.get();
        if (caller == null || !caller.isAuthenticated() || !(caller.getPrincipal() instanceof Long userId)
                || caller.getAuthorities().stream().noneMatch(a -> role.equals(a.getAuthority()))) {
            return new AuthorizationDecision(false);
        }
        String path = context.getRequest().getRequestURI()
                .substring(context.getRequest().getContextPath().length());
        var matcher = actorPath.matcher(path);
        return new AuthorizationDecision(matcher.matches() && userId.toString().equals(matcher.group(1)));
    }
}
