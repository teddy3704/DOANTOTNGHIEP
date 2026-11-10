package com.dlu.lmsmobile.portal;

/** Portal down, timed out, refused the key or returned something unusable. Maps to 503. Message never holds a body. */
public class PortalUnavailableException extends RuntimeException {
    private final String code;

    public PortalUnavailableException(String code) {
        super(code);
        this.code = code;
    }

    /** PORTAL_UNAVAILABLE or PORTAL_DISABLED. */
    public String code() {
        return code;
    }

    public static PortalUnavailableException unavailable() {
        return new PortalUnavailableException("PORTAL_UNAVAILABLE");
    }

    public static PortalUnavailableException disabled() {
        return new PortalUnavailableException("PORTAL_DISABLED");
    }
}
