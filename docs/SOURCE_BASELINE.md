# Group source baseline — 2026-10-27

Workspace: D:\DLU-LMS-Group. Independent Git workspace; no remote selected.

Backend and frontend copied from the previously inspected, preserved extraction:
D:\DLU-LMS\Artifacts\GroupReview-2026-10-26.
No files from the old application have been copied into the new implementation.

Previously observed original archive SHA256:

- Backend ZIP: 5D12CBDF20F0005697980F21B63366B4894308CE67DF81873B0D2C653CF32978
- Frontend ZIP: A70581F9316153FD735516EADE09F63E91FDF9FE0A16EB1E971B2098E402ED10
- SQL backup: 936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4

At execution start, these three original Downloads paths were missing. The two
source extractions remain available and were copied to backend/ and frontend/.
The exact SQL backup has NOT been recovered or imported. The old mock-data SQL is
not a replacement. The user was asked to restore/provide the exact backup path.

> **Update 2026-10-31 (Claude):** the exact backup is available again at `D:\doan\lms_mobile_learning_backup.sql`; SHA256 re-verified as `936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4`. File availability is resolved; restore remains gated (no approved target or import authorization). See docs/HANDOFF.md.

Database expected from prior static inspection: 3 schemas, 44 physical tables
(37 lms +7 app), 21 derived views, 583 columns, 44 PK, 41 FK. These are NOT current
catalog results. No DB target has been selected or modified by this takeover.

Stack: Java21, Spring Boot3.3.4, Maven/JdbcTemplate/Security/JWT; Flutter/http/fl_chart.
Authentication and functionality claims in archive docs require current verification.
