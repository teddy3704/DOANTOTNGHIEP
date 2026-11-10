package com.dlu.lmsmobile.portal;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.*;

/**
 * V3-P0: DLU training portal (Portal Online DLU Proxy). Everything here is server-owned; the
 * student/teacher mapping is NEVER taken from a request (docs/V3_PORTAL_PROMPT.md §2.2).
 * Supplied at runtime by tools/Start-LocalBackend.ps1 from the git-ignored .local/backend.json.
 */
@ConfigurationProperties(prefix = "app.portal")
public class PortalProperties {
    private boolean enabled = false;
    private String baseUrl = "https://quan-ly-dao-tao-api.nguyentronghieu.io.vn";
    private String apiKey = "";
    private Duration cacheTtl = Duration.ofMinutes(10);
    private int cacheMaxEntries = 500;
    private Duration healthTtl = Duration.ofSeconds(60);
    private Duration connectTimeout = Duration.ofSeconds(5);
    private Duration readTimeout = Duration.ofSeconds(15);
    private Map<Long, StudentLink> students = new LinkedHashMap<>();
    private Map<Long, List<String>> advisors = new LinkedHashMap<>();
    private Map<Long, String> courseMap = new LinkedHashMap<>();
    /** Moodle userId → Portal StudentID for the advisor bridge (P6), in addition to lms.user.idnumber. */
    private Map<Long, String> lmsStudentLinks = new LinkedHashMap<>();
    /** courseMap/lmsStudentLinks are demo mappings (shown as such on P7). */
    private boolean demoMapping = false;
    private boolean presentationMask = true;
    private BigDecimal conductThreshold = BigDecimal.valueOf(50);
    /** Graduation bands on the 4-point scale, highest first (Thông tư 08/2021/TT-BGDĐT). */
    private List<GradeBand> gradeBands = new ArrayList<>(List.of(
        new GradeBand("Xuất sắc", new BigDecimal("3.6")),
        new GradeBand("Giỏi", new BigDecimal("3.2")),
        new GradeBand("Khá", new BigDecimal("2.5")),
        new GradeBand("Trung bình", new BigDecimal("2.0"))));

    public static class StudentLink {
        private String studentId;
        private String studyProgramId;
        private String classId;

        public StudentLink() {
        }

        public StudentLink(String studentId, String studyProgramId, String classId) {
            this.studentId = studentId;
            this.studyProgramId = studyProgramId;
            this.classId = classId;
        }

        public String getStudentId() { return studentId; }
        public void setStudentId(String v) { studentId = v; }
        public String getStudyProgramId() { return studyProgramId; }
        public void setStudyProgramId(String v) { studyProgramId = v; }
        public String getClassId() { return classId; }
        public void setClassId(String v) { classId = v; }

        public boolean complete() {
            return notBlank(studentId) && notBlank(studyProgramId) && notBlank(classId);
        }
    }

    public static class GradeBand {
        private String name;
        private BigDecimal min;

        public GradeBand() {
        }

        public GradeBand(String name, BigDecimal min) {
            this.name = name;
            this.min = min;
        }

        public String getName() { return name; }
        public void setName(String v) { name = v; }
        public BigDecimal getMin() { return min; }
        public void setMin(BigDecimal v) { min = v; }
    }

    /** Enabled and has a key and a base URL. */
    public boolean configured() {
        return enabled && notBlank(apiKey) && notBlank(baseUrl);
    }

    static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean v) { enabled = v; }
    public String getBaseUrl() { return baseUrl; }
    public void setBaseUrl(String v) { baseUrl = v; }
    public String getApiKey() { return apiKey; }
    public void setApiKey(String v) { apiKey = v; }
    public Duration getCacheTtl() { return cacheTtl; }
    public void setCacheTtl(Duration v) { cacheTtl = v; }
    public int getCacheMaxEntries() { return cacheMaxEntries; }
    public void setCacheMaxEntries(int v) { cacheMaxEntries = v; }
    public Duration getHealthTtl() { return healthTtl; }
    public void setHealthTtl(Duration v) { healthTtl = v; }
    public Duration getConnectTimeout() { return connectTimeout; }
    public void setConnectTimeout(Duration v) { connectTimeout = v; }
    public Duration getReadTimeout() { return readTimeout; }
    public void setReadTimeout(Duration v) { readTimeout = v; }
    public Map<Long, StudentLink> getStudents() { return students; }
    public void setStudents(Map<Long, StudentLink> v) { students = v; }
    public Map<Long, List<String>> getAdvisors() { return advisors; }
    public void setAdvisors(Map<Long, List<String>> v) { advisors = v; }
    public Map<Long, String> getCourseMap() { return courseMap; }
    public void setCourseMap(Map<Long, String> v) { courseMap = v; }
    public Map<Long, String> getLmsStudentLinks() { return lmsStudentLinks; }
    public void setLmsStudentLinks(Map<Long, String> v) { lmsStudentLinks = v; }
    public boolean isDemoMapping() { return demoMapping; }
    public void setDemoMapping(boolean v) { demoMapping = v; }
    public boolean isPresentationMask() { return presentationMask; }
    public void setPresentationMask(boolean v) { presentationMask = v; }
    public BigDecimal getConductThreshold() { return conductThreshold; }
    public void setConductThreshold(BigDecimal v) { conductThreshold = v; }
    public List<GradeBand> getGradeBands() { return gradeBands; }
    public void setGradeBands(List<GradeBand> v) { gradeBands = v; }

    /** Never print the key or the mapping. */
    @Override
    public String toString() {
        return "PortalProperties[enabled=" + enabled + ", configured=" + configured()
            + ", students=" + students.size() + ", advisors=" + advisors.size() + "]";
    }
}
