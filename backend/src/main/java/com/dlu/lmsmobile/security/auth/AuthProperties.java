package com.dlu.lmsmobile.security.auth;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

/**
 * Login settings (app.auth.*). Local accounts come from the git-ignored .local\backend.json (AUTH block,
 * BCrypt hashes only). The Moodle provider is OFF unless explicitly enabled with the School's permission.
 */
@ConfigurationProperties(prefix = "app.auth")
public class AuthProperties {
    private int maxFailures = 5;
    private Duration lockWindow = Duration.ofMinutes(15);
    private final Local local = new Local();
    private final Moodle moodle = new Moodle();

    public int getMaxFailures() { return maxFailures; }
    public void setMaxFailures(int maxFailures) { this.maxFailures = maxFailures; }
    public Duration getLockWindow() { return lockWindow; }
    public void setLockWindow(Duration lockWindow) { this.lockWindow = lockWindow; }
    public Local getLocal() { return local; }
    public Moodle getMoodle() { return moodle; }

    public static class Local {
        private boolean enabled;
        private List<Account> users = new ArrayList<>();

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }
        public List<Account> getUsers() { return users; }
        public void setUsers(List<Account> users) { this.users = users; }
    }

    /** One local account: student code (MSSV) or username, the LMS user id, the role and a BCrypt hash. */
    public static class Account {
        private String login;
        private long userId;
        private String role;
        private String bcrypt;

        public String getLogin() { return login; }
        public void setLogin(String login) { this.login = login; }
        public long getUserId() { return userId; }
        public void setUserId(long userId) { this.userId = userId; }
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
        public String getBcrypt() { return bcrypt; }
        public void setBcrypt(String bcrypt) { this.bcrypt = bcrypt; }
    }

    public static class Moodle {
        private boolean enabled;
        private String baseUrl;
        private String service = "moodle_mobile_app";
        private Duration timeout = Duration.ofSeconds(10);

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }
        public String getBaseUrl() { return baseUrl; }
        public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
        public String getService() { return service; }
        public void setService(String service) { this.service = service; }
        public Duration getTimeout() { return timeout; }
        public void setTimeout(Duration timeout) { this.timeout = timeout; }
    }
}
