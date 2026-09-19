# DLU authentication / linking checkpoint — 2026-09-18

Official system: `https://lms.dlu.edu.vn/`.

Ordinary authorized browser navigation confirmed an existing authenticated
dashboard, course page, assignment page and visible grade navigation. No academic
write was performed. No session secrets, cookies, credentials or private records
were extracted. Observed production activity IDs are not copied into synthetic
course mappings.

- DLU_LOGIN_METHOD: **TO_VERIFY_DLU**. An existing browser session does not prove
  the login protocol supported for a mobile application.
- DLU_WEB_SERVICES: **TO_VERIFY_DLU**. No token/private endpoint probing.
- Teacher production context/capabilities: **TO_VERIFY_DLU**; not inferred from
  a Student browser page.
- Safe current link: official HTTPS home. Exact Student/Teacher activity mapping
  requires a DLU-approved integration contract; no invented Moodle IDs/URLs.
- App default production repositories fail closed. Development identities and
  Teacher fixture are explicitly composed only in staging/development.

University/LMS administrator must confirm approved mobile authentication,
read-service access and capability/URL mapping. Do not request an admin password.
