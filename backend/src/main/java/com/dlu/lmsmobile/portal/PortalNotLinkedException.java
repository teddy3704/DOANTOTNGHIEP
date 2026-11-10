package com.dlu.lmsmobile.portal;

/** The signed-in user has no server-configured Portal mapping (or the advisor class is not theirs). 404. */
public class PortalNotLinkedException extends RuntimeException {
    public PortalNotLinkedException() {
        super("PORTAL_NOT_LINKED");
    }
}
