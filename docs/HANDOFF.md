# HANDOFF — hiện trạng (cập nhật 2026-11-10, FINAL)

STATUS hiện hành: N1–N18, O1, E2, P0–P8 DONE (gate + emulator DB demo). Đang làm FINAL-F0…F7 (docs/FINAL_DEFENSE_PROMPT.md).
Checkpoint ngắn để tiếp tục: **docs/RESUME_STATE.md**. Chi tiết theo ngày: các mục cuối file này.
Workspace D:\DLU-LMS-Group · branch codex/group-stack-takeover · git cục bộ, không remote, không push.

---

Lịch sử — phần đầu cũ (giữ nguyên, không còn là trạng thái hiện hành):

# Exact handoff — 2026-10-31 (Claude takeover)

STATUS: IN_PROGRESS — T03–T06 PASS; APK on D. T07a PASS. T07b PASS (lms_mobile_group_dev restored, 1,686 rows, 0 errors). T08 structure all MATCHES_SNAPSHOT; 1 integrity finding (2 orphan learning_reflections). Runtime role lms_group_app verified (= ceiling). T09 DONE 2026-11-07: all flows PASS on emulator; 401→403 fix in SecurityConfig (backend gate PASS). Not committed. T07b restore NOT approved. T08/T09 NOT_RUN.
ACTIVE_WORKSPACE: D:\DLU-LMS-Group
WRITER (current, 2026-11-03): native Claude Code on Windows, running in D:\DLU-LMS-Group
(accepted 2026-10-31 01:52 +07, see WRITER_TRANSFER below). Only one writer; hand back explicitly.
History — earlier writer: Claude (claude.ai session linked through the Claude desktop app),
granted 2026-10-31 00:12 +07; it stopped editing when the native session accepted.

## Storage rule (owner, 2026-11-03)

All new project data we control goes on D: downloads, extraction, builds, caches, DB data/WAL,
logs, backups, APKs. Installed tools on C may run. No machine/user TEMP/PATH/AppData changes.
Stop heavy work if C < 15 GiB. Verified 2026-11-03 (real targets, junctions resolved):
TEMP/TMP D:\DLU-LMS\Temp, Maven D:\DLU-LMS\Caches\Maven (`-Dmaven.repo.local`), Gradle
D:\DLU-LMS\Caches\Gradle (C:\Users\admin\.gradle is a junction to it), Pub D:\DLU-LMS\Caches\Pub,
SDK D:\DLU-LMS\Android\Sdk, Artifacts D:\DLU-LMS\Artifacts, ANDROID_AVD_HOME (user env, pre-existing)
D:\DLU-LMS\Android\AVD (AVD `DLU_LMS_Pixel`). Small C writes remain: C:\Users\admin\.android
(6.4 MB: adb keys/debug keystore), AppData\Roaming\.dart-tool (1.4 MB).
Disk: C 22.4 GiB free after APK build (11-03 22:55) → 16.24 GiB at 11-03 session start (drop not
caused by a project command of this session; cause not investigated) → 16.26 GiB at end of checks.
D 77.7 GiB. Idle Gradle daemon + 2 Kotlin daemons (JDK17 on D) left from the APK build; not killed.

### C: audit 2026-11-04 (owner request; read-only, nothing changed — each item awaits owner approval)

| Path | Size | In use | Proposal |
| --- | ---: | --- | --- |
| %LOCALAPPDATA%\Pub\Cache | absent | – | nothing to do (Pub uses D:\DLU-LMS\Caches\Pub) |
| %LOCALAPPDATA%\.dartServer | 155.56 MB, 13,657 files (Aug 12 → Nov 3 22:48) | no | leave (shared Dart analysis-server cache, also older/other projects); future: test a process-level redirect to D before adopting |
| %USERPROFILE%\.gradle | junction → D:\DLU-LMS\Caches\Gradle | – | leave (data already on D) |
| %USERPROFILE%\.m2 | absent | – | nothing (Maven uses -Dmaven.repo.local=D:\DLU-LMS\Caches\Maven) |
| %USERPROFILE%\.android | 6.42 MB (cache 6.41 MB from Aug; adbkey, debug.keystore) | no | leave (adb key + debug signing key; moving changes APK debug signature/adb trust) |
| %LOCALAPPDATA%\kotlin | ~0 MB, 4 files | yes: idle Kotlin daemons java#13644, #16756 (from 11-03 APK build) | leave; optionally stop the idle Gradle/Kotlin daemons |
| Temp\BRL000071d8 | 1.67 MB | no | delete (EDB installer helper, ours) |
| Temp\postgresql_installer_5f28617d12, _10e489b257 | empty dirs | no | delete (ours) |
| Temp\install-postgresql.log, installbuilder_installer.log | 0.41 MB each | no | move to D:\DLU-LMS\PostgreSQL\logs\installer\ as evidence |
| Temp\DLU-LMS-Build-stale-onedrive-20260821 | empty dir (Sep 30) | no | leave — not created by this workspace/session |

Rule from 2026-11-04: every ad-hoc command outside the scripts sets process TEMP/TMP, PUB_CACHE,
GRADLE_USER_HOME on D and Maven `-Dmaven.repo.local=D:\DLU-LMS\Caches\Maven` (as Use-LocalToolchain.ps1).

## APK handoff (2026-11-03)

`D:\DLU-LMS\Artifacts\dlu-lms-group-2026-11-03-debug.apk`, 148,091,503 bytes, SHA256
A07660D5F9387299F76710899B7A375D2B10D493960F778CC3BEF7F63C9C01AE — copied (target did not exist)
from frontend\build\app\outputs\flutter-apk\app-debug.apk; source and copy hashes both match.
Not rebuilt. Uses http://127.0.0.1:8081/api/v1 → needs `adb reverse tcp:8081 tcp:8081`.

## T07 read-only findings (2026-11-03) — restore NOT performed

- Windows has NO PostgreSQL server: no service, no postgres.exe, no registry install, nothing in
  PATH, no listener on 5432–5440, WSL has no distro, no Docker. Only client found: pgAdmin 4 9.17 at
  D:\Doantotnghiep\pgAdmin 4 (old project folder; bundled psql/pg_dump/pg_restore 18.4). Not used
  and not modified; its saved-server DB was not opened.
- Dump D:\doan\lms_mobile_learning_backup.sql SHA256 936B8475…41F4AD4 (= baseline). Plain psql
  SQL from server/pg_dump 18.6. Statement inventory (COPY bodies skipped, no rows read):
  schemas app/derived/lms; 71× `OWNER TO postgres` (only owner); 0 GRANT/REVOKE, 0 CREATE ROLE,
  0 CREATE EXTENSION, 0 CREATE DATABASE/\connect, default tablespace only; psql meta `\restrict`
  and `\unrestrict` once each; `SET transaction_timeout` present (server ≥17 needed).
- Backend writes only app.{flashcards, learning_goals, learning_reflections, notifications,
  teacher_notes} (INSERT/UPDATE; DELETE only flashcards). Reads lms/derived. Basis for runtime grants.
- Port 55432 free and outside Windows excluded range (50000–50059).
- Approval request (proposal: new portable PostgreSQL 18 cluster fully on D, port 55432, PGDATA
  D:\DLU-LMS\PostgreSQL\data, logs D:\DLU-LMS\PostgreSQL\logs, restore as cluster role `postgres`,
  runtime role `lms_group_app` with least privilege) was sent to the owner in chat 2026-11-03.
  Nothing downloaded, installed, initialised or created at that point.

## T07a — empty local cluster on D (owner decision 2026-11-04: CAI_CLUSTER_D=CO, RESTORE_DUMP=KHONG)

Task file: D:\DLU-LMS\Artifacts\ClaudeCodeSetup\T07_LOCAL_D_HANDOFF_2026-11-03.md. Restore (T07b) NOT approved.
- Re-check before install: no postgres process/service, port 55432 free, all target dirs absent.
- Version probe on official EDB host: 18.7–18.9 not published (403); latest = 18.6-2 (same minor as dump).
- Download: `curl.exe -f -L --proto =https --tlsv1.2` (TLS verified, no -k) → exit 0,
  D:\DLU-LMS\Downloads\postgresql-18.6-2-windows-x64-binaries.zip, 343,811,176 bytes (= Content-Length),
  SHA256 41BB1496F60666D3745AE8A855753B877D14FA9E34667F266867635B790FC323 (recorded; EDB publishes none).
- Zip check: 21,968 entries, single root `pgsql/`, 0 traversal/absolute paths. Extracted only
  bin/lib/share + license txt (1,588 files, 141 MB; pgAdmin/StackBuilder/doc/include skipped) to
  D:\DLU-LMS\Toolchains\pgsql-18.
- Provenance caveat: Authenticode — 161 of 162 exe/dll NotSigned (postgres/initdb/pg_ctl/psql
  included; only stackbuilder.exe signed by EnterpriseDB Corporation). This is how EDB ships the
  zip. Defender custom scan of the folder: no threats (MpCmdRun exit 0). No binary executed yet.
- Dump has 0 COLLATE / CREATE COLLATION → cluster uses builtin C.UTF-8 locale provider.
- New script `tools/Use-LocalPostgres.ps1 -Action Init|Start|Stop|Status|Verify` (parse-checked,
  not yet run): Init refuses if C < 15 GiB, PGDATA non-empty or port busy; initdb with --pwprompt
  (password typed by owner in their own console), SCRAM host+local, listen 127.0.0.1:55432,
  logging_collector to D:\DLU-LMS\PostgreSQL\logs; pg_ctl start (no service); Verify runs read-only
  catalog queries (version, data_directory, port, listen, WAL dir, tablespaces, DBs, login roles,
  hba rules) via psql prompt and saves to logs\t07a-verify-<stamp>.txt.
- Disk: C 18.81 → 18.80 GiB, D 77.22 → 76.75 GiB across download+extract.

### Update 2026-11-04 (later run) — PACKAGE_INTEGRITY_UNVERIFIED

The next task message carried `CAI_CLUSTER_D=KHONG` (no install/initdb) and requires a
publisher checksum or whole-package signature before ANY binary runs. Checked official pages:
postgresql.org/download/windows (zip hosted by EDB, no checksum/signature mentioned) and
enterprisedb.com/download-postgresql-binaries (lists 18.6 only, no SHA/MD5/GPG). Per-EXE
Authenticode does not cover the zip and most files are unsigned anyway → **PACKAGE_INTEGRITY_UNVERIFIED**.
- No PostgreSQL binary has ever been executed. Owner did not run the old `-Action Init`
  (verified: no D:\DLU-LMS\PostgreSQL, no postgres process, 55432 not listening).
- Downloaded zip + extracted D:\DLU-LMS\Toolchains\pgsql-18 are kept untouched (not deleted,
  not used). Treat as unverified.
- `tools/Use-LocalPostgres.ps1` rewritten: `Init` removed (initdb is a direct owner command);
  `Start` now runs a static pre-start `Check` first (C ≥ 15 GiB, PG_VERSION present, PGDATA/pg_wal
  not links, pg_tblspc empty, listen 127.0.0.1, port 55432, logging_collector on, log_directory on D,
  every pg_hba rule scram-sha-256, port free). Actions: Check|Start|Stop|Status|Verify. Parse-checked only.
- initdb command for when the package is approved (owner, own PowerShell window, hidden prompt):
  `$env:TEMP='D:\DLU-LMS\Temp'; $env:TMP=$env:TEMP; & 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin\initdb.exe' -D 'D:\DLU-LMS\PostgreSQL\data' -U postgres --pwprompt -A scram-sha-256 -E UTF8 --locale-provider=builtin --builtin-locale=C.UTF-8 -c listen_addresses=127.0.0.1 -c port=55432 -c logging_collector=on -c log_directory=D:/DLU-LMS/PostgreSQL/logs`
  then writer: `Use-LocalPostgres.ps1 -Action Check` → `-Action Start` → owner `-Action Verify`.
- STATUS T07a: BLOCKED — PACKAGE_INTEGRITY_UNVERIFIED and CAI_CLUSTER_D=KHONG for this run.

### Update 2026-11-04 (owner: CAI_CLUSTER_D=CO, PHUONG_AN=EDB_SIGNED_INSTALLER_EXTRACT_ONLY, CHO_PHEP_ADMIN=KHONG, RESTORE_DUMP=KHONG)

- Disk before: C 18.80 / D 76.75 GiB. Official installer probe: 18.6-2 and 18.6-1 exist; chose 18.6-2.
- Download (process TEMP/TMP on D, curl TLS-verified, exit 0):
  D:\DLU-LMS\Downloads\postgresql-18.6-2-windows-x64.exe, 377,853,032 bytes (= Content-Length),
  SHA256 5DE1182B7F8C823C6BE13D9DE9A5BCA56D1D856AE18E1029AFBD8EF3BA5573D6. Disk after: C 18.80 / D 76.40.
- Authenticode (read-only, file NOT executed): Status **Valid**; signer CN=EnterpriseDB Corporation,
  O=EnterpriseDB Corporation, Wilmington, Delaware, US; issuer DigiCert Trusted G4 Code Signing RSA4096
  SHA384 2021 CA1; thumbprint 7BEDD1269FCCF7A5D95F18274750B79893C06C70, valid 2026-01-30..2029-02-01;
  DigiCert timestamp. VersionInfo only says ProductVersion=18 (minor 18.6-2 comes from URL/filename).
- **STOP: embedded manifest `requestedExecutionLevel level="requireAdministrator"`** → any run of the
  installer, including `--extract-only`, triggers UAC. CHO_PHEP_ADMIN=KHONG → not executed; no manifest
  bypass (e.g. RunAsInvoker) used; no fallback to the zip. D:\DLU-LMS\Toolchains\pgsql-18-verified NOT created.
- Unverified zip + D:\DLU-LMS\Toolchains\pgsql-18 kept untouched, not executed.
- `tools/Use-LocalPostgres.ps1` now points ONLY to ...\pgsql-18-verified\bin and throws if postgres.exe
  is missing there; initdb command above updated to the verified path. No doc/script references the zip bin.
- STATUS T07a: BLOCKED — INSTALLER_REQUIRES_ADMIN. No PGDATA, no postgres process, 55432 free.

### Update 2026-11-04 00:29 (owner: CHO_PHEP_UAC_MOT_LAN=CHI_BO_CAI_EDB_DA_XAC_MINH_DE_GIAI_NEN)

- Pre-run re-check: SHA256 5DE1182B… match, Authenticode Valid, thumbprint 7BEDD126… match,
  target absent. State snapshot (D:\DLU-LMS\Temp\t07a-uac-before.json): 300 services, 235 uninstall
  entries, no HKLM\SOFTWARE\PostgreSQL, no C:\Program Files\PostgreSQL. C 20.066 / D 76.402 GiB.
- Elevated ONLY the installer (Start-Process -Verb RunAs; terminal/Claude stayed non-elevated; owner
  confirmed UAC): `postgresql-18.6-2-windows-x64.exe --mode unattended --unattendedmodeui none
  --extract-only 1 --install_runtimes 0 --disable-components pgAdmin,stackbuilder
  --prefix "D:\DLU-LMS\Toolchains\pgsql-18-verified"` → exit 0 (00:29:22–00:30:28).
- After: new services 0, new/removed uninstall entries 0 (VC++ unchanged), no PostgreSQL registry key,
  no Program Files dir, no Start Menu entry, no postgres process. Installer log: only `whoami` and a
  COMSPEC check .bat executed; vcredist_x86/x64.exe were only unpacked as files into
  pgsql-18-verified\installer (not run); no service/initdb. C writes: ~2.5 MB installer temp + logs in
  C:\Users\admin\AppData\Local\Temp (BRL000071d8, postgresql_installer_*, install-postgresql.log,
  installbuilder_installer.log) — elevated process used the user TEMP; left in place.
- Extracted set D:\DLU-LMS\Toolchains\pgsql-18-verified: 4,598 files, 228.7 MB (bin, lib, share,
  include, doc, scripts, installer); no pgAdmin; stackbuilder.exe present as a file only (not installed/run).
  `postgres/initdb/pg_ctl/psql --version` (non-elevated) → 18.6. Individual exe/dll are not signed
  (161/162, same as EDB ships); trust comes from the signed installer package.
- Informational: all 215 bin/lib files of the old zip extract are hash-identical to the verified set.
  Zip and ...\pgsql-18 still unused, kept.
- Disk: C 20.066 → 20.861 GiB (C free rose; other system activity), D 76.402 → 76.166 GiB.
- `tools/Use-LocalPostgres.ps1` uses only pgsql-18-verified; Start also creates the logs dir.
- Preconditions for initdb: process non-elevated, D:\DLU-LMS\PostgreSQL absent, 55432 free.
- STATUS T07a: IN_PROGRESS — WAITING_OWNER_INITDB (command in "Exact next step").

### Update 2026-11-04 00:39 — initdb done by owner, static check PASS, cluster started

- Owner ran initdb (PGDATA written 00:37:03); password never entered in this session.
  PG_VERSION 18, global/pg_control present, base has 3 DBs; pg_controldata: cluster state
  "shut down", catalog 202506291, data page checksums on.
- `Use-LocalPostgres.ps1 -Action Check` → exit 0: postgresql.conf listen_addresses='127.0.0.1',
  port=55432, logging_collector=on, log_directory='D:/DLU-LMS/PostgreSQL/logs'; postgresql.auto.conf
  empty; pg_hba 6 rules (local/host 127.0.0.1/32/::1/128, all + replication) all scram-sha-256, no trust;
  PGDATA, pg_wal, pg_tblspc are real dirs on D (no links); pg_tblspc empty.
- `-Action Start` → pg_ctl exit 0 ("server started"). postmaster.pid: datadir D:/DLU-LMS/PostgreSQL/data,
  port 55432, listen 127.0.0.1, status ready. Only listener 127.0.0.1:55432 (postmaster pid 20796);
  all 10 postgres processes run D:\DLU-LMS\Toolchains\pgsql-18-verified\bin\postgres.exe; no Windows
  service. pg_isready 127.0.0.1:55432 → accepting connections (exit 0). Server log in
  D:\DLU-LMS\PostgreSQL\logs\postgresql-2026-11-04_003926.log: "starting PostgreSQL 18.6 on
  x86_64-windows", "listening on IPv4 address 127.0.0.1, port 55432", ready.
- Disk: C 21.612 / D 76.129 → 76.130 GiB (start changed nothing material).
- Cluster left RUNNING for the owner's SQL-level verify.
- STATUS T07a: IN_PROGRESS — file/process/listener checks PASS; SQL-level `-Action Verify`
  (needs owner password at psql prompt) NOT_RUN yet. Mark PASS only after reviewing that output.

### T07a PASS — 2026-11-04 00:41 (owner ran `-Action Verify`, password typed by owner)

Reviewed D:\DLU-LMS\PostgreSQL\logs\t07a-verify-20261104-004145.txt (copy, no secrets:
D:\DLU-LMS\Artifacts\t07a-verify-20261104-004145.txt):
- Server: PostgreSQL 18.6 on x86_64-windows (client psql 18.6 from the same verified set).
- data_directory D:/DLU-LMS/PostgreSQL/data; config_file and hba_file inside it; WAL
  D:/DLU-LMS/PostgreSQL/data\pg_wal; log_directory D:/DLU-LMS/PostgreSQL/logs, logging_collector on.
- listen_addresses 127.0.0.1, port 55432; password_encryption scram-sha-256; data_checksums on; UTF8.
- Tablespaces only pg_default/pg_global (no external location). Databases: postgres, template0,
  template1 only (no lms_mobile_group_dev). Login roles: postgres (superuser) only.
- pg_hba_file_rules: 6 rules, all scram-sha-256, no trust.
Cluster left RUNNING (pg_ctl, no service). Start/stop: `tools\Use-LocalPostgres.ps1 -Action Start|Stop|Status`.
T07b NOT started (RESTORE_DUMP=KHONG): no app DB, no restore, no runtime role/grants.

## 2026-11-04 ~00:45–01:00 — dọn C, A0, T07b preparation

Owner decisions: LUU_TRU=CHI_O_D; DON_C 6=DUNG_DAEMON 7=XOA 8=CHUYEN; RESTORE_DUMP=CO;
NGUON_DUMP=TU_XAC_MINH; PHAN_LOAI_DU_LIEU=TU_XAC_MINH; QUYEN_DUNG_LOCAL=CO (owner decision);
ROLE_RUNTIME=lms_group_app; GHI_THU_T09=CO_GIOI_HAN. Other-writer check: only Claude Desktop app
(PID 22892, no shell children) + this session.

Dọn C (C 21.70 → 23.97 GiB, mostly unrelated system activity):
- 6 DONE: `frontend\android\gradlew.bat --stop` (GRADLE_USER_HOME/TEMP on D, JAVA_HOME jdk-17 on D) →
  exit 0 "1 Daemon stopped"; PIDs before: Gradle 10356, Kotlin 13644, 16756. Both Kotlin daemons exited
  with the Gradle daemon within 13 s — no manual kill needed. No java process left.
- 8 DONE: install-postgresql.log and installbuilder_installer.log → D:\DLU-LMS\PostgreSQL\logs\installer\,
  hash-checked copy then source removed; both SHA256 4E17EA96D57BEE3CED90EC8451B6F014AE6142179119AB2A922EF68B263A74B5
  (the installer writes identical content to both files).
- 7 PARTIAL: both empty Temp\postgresql_installer_* dirs deleted. Temp\BRL000071d8 (10 files, 1.67 MB)
  → Access denied: created by the elevated installer, needs admin. Left in place (no elevation).

!! Source change observed (not by this session): D:\doan is now EMPTY (dir re-created 2026-11-04 00:35:01;
the earlier DO-AN-TOT-NGHIEP-* extractions and the dump are gone from there; nothing in Recycle Bin).
The dump now exists at D:\DLU-LMS-Group\database\lms_mobile_learning_backup.sql (created 00:31:33,
modified 2026-10-26 22:37:18), SHA256 936B8475…41F4AD4 = approved, Git-ignored by `.gitignore:17
**/*backup*.sql` (status `!!`). Restore uses this hash-identical path.

A0 (aggregate-only stream script; no rows printed) → D:\DLU-LMS\Artifacts\a0-dump-provenance-20261104-005306.txt
(an earlier 20261104-0052xx file has empty auth/domain/password lines from a script argument bug; superseded):
- NGUON_DUMP: SHA256 936B8475…41F4AD4, 274,562 bytes, modified 2026-10-26 22:37:18; no Zone.Identifier
  (no download origin recorded); header pg_dump/server 18.6. Docs: database/README.md:12 says the reviewed
  original was C:\Users\admin\Downloads\lms_mobile_learning_backup.sql (same hash); backend/db/mock/README.md:9
  and backend/docs/DEMO_DATA_CATALOG.md:3 describe the group's mock/seed data (3 teachers, 15 students,
  5 courses, 18 assignments, 10 quizzes — matches the dump). Who supplied the file and when: không xác định.
- PHAN_LOAI_DU_LIEU = **tổng hợp** (high confidence): 44 COPY blocks / 1,686 rows; lms."user" 18 rows,
  auth manual=10 nologin=8; all 18 emails on reserved test domains (example.edu.vn=10, example.invalid=8);
  18/18 match test/demo patterns; password format empty=8 other=10 (no bcrypt/32-hex); no timecreated
  column (lastaccess year 2026, 1 non-zero). Overlap with the 4 group mock SQL files: usernames 18/18,
  emails 18/18, course shortnames 5/5 (100%).
→ Per A0.3: tổng hợp + QUYEN_DUNG_LOCAL=CO → continue to D.

T07b/E preparation (files written, NOT executed — need the owner's postgres password):
- Re-check: dump SHA ok, postmaster datadir D:/DLU-LMS/PostgreSQL/data, 127.0.0.1:55432 ready, C 24.03 GiB.
- `tools/Invoke-GroupRestore.ps1` (parse OK, no secrets): one hidden prompt for postgres (process env only,
  removed in finally); stops if C<15, hash mismatch, cluster not the verified one, or DB already exists;
  CREATE DATABASE lms_mobile_group_dev OWNER postgres TEMPLATE template0 ENCODING 'UTF8'; approved psql
  restore (`-X ... --single-transaction -f <dump>`, plus VERBOSITY=sqlstate/SHOW_CONTEXT=never so errors carry
  no row values) → logs\restore-<stamp>.log; on error prints only SQL line + SQLSTATE, no retry/DROP. Then on
  fresh connections: T08 verify_group_catalog.sql with expected_database → logs\t08-verify-<stamp>.txt;
  E4 read-only demo-ID aggregates (ids + course counts, prefer 205/102) → logs\e4-demo-ids-<stamp>.txt.
- `database/grants_lms_group_app.sql`: from real code (repositories): SELECT on 13 lms tables, 18 derived
  views (no security_invoker), app.learning_reminders; SELECT/INSERT/UPDATE on app.{flashcards,
  learning_goals, learning_reflections, notifications, teacher_notes}; DELETE only app.flashcards;
  USAGE/SELECT on their id sequences (pg_get_serial_sequence); CONNECT + schema USAGE; REVOKE ALL ON
  DATABASE FROM PUBLIC. Code uses no DDL/TRUNCATE/sequence calls; one `RETURNING id` (covered by SELECT).
  Within the approved ceiling.
- `tools/Initialize-GroupRuntimeRole.ps1`: one postgres prompt; CREATE ROLE lms_group_app LOGIN NOSUPERUSER
  NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS (stops if it exists); owner sets password via psql
  `\password`; applies grants; aggregate privilege report + BEGIN/SET ROLE/ROLLBACK smoke (read derived ok,
  INSERT into lms denied) → logs\runtime-role-<stamp>.txt.
STATUS: T07b WAITING_OWNER_RUN (Invoke-GroupRestore.ps1). T08/E4 run inside it. Role script after restore.

### T07b PASS / T08 / E4 — owner ran Invoke-GroupRestore.ps1 at 2026-11-04 00:59:57–01:00:01

- Restore log D:\DLU-LMS\PostgreSQL\logs\restore-20261104-005957.log (summarised, no rows read):
  0 ERROR, 0 WARNING; COPY tags 44, rows 1,686 (= A0 count); CREATE SCHEMA 3, CREATE TABLE 44,
  CREATE VIEW 21, CREATE INDEX 104, CREATE SEQUENCE 3, ALTER TABLE 186, ALTER VIEW 21, ALTER SEQUENCE 6,
  ALTER SCHEMA 3, SET 12. Single transaction committed. **T07b PASS.**
- T08 logs\t08-verify-20261104-005957.txt (PG 18.6, read-only repeatable read, ended ROLLBACK):
  app_tables 7/7, lms_tables 37/37, physical_tables 44/44, derived_views 21/21, physical_columns 583/583,
  primary_keys 44/44, foreign_keys 41/41, unique_constraints 15/15, app_foreign_keys_known_gap 0/0 — all
  MATCHES_SNAPSHOT. missing_or_wrong_kind_relations 0; auth_account absent (expected). Owners: 1 per schema
  (postgres, superuser), RLS-enabled relations 0. Not-validated constraints 0. flashcards.userid nullable
  with default (known risk). Module/assign/quiz/course consistency counts all 0.
  **Integrity finding (count ≠ 0): app.learning_reflections — 4 rows, missing_owner_count 2,
  missing_course_count 2** (2 reflections reference a user/course not present). Not fixed, expectations not
  changed, no auth_account created. T08 = structure PASS, integrity NOT clean (this one finding).
- E4 logs\e4-demo-ids-20261104-005957.txt: student 205 → 3 courses (201, 202 also 3); teacher 102 → 3 courses
  (101 → 2, 3000103 → 1). Use DEMO_STUDENT_ID=205, DEMO_TEACHER_ID=102.
- New `tools/New-LocalBackendConfig.ps1` (parse OK): owner-run; refuses if .local\backend.json exists or is
  not git-ignored (.gitignore:13 `/.local/`); ACL current user only before writing; hidden prompt for the
  lms_group_app password; 48-byte RNG JWT secret; DB_URL 127.0.0.1:55432/lms_mobile_group_dev,
  DB_USERNAME lms_group_app, DEMO 205/102; prints no values.
NEXT: owner runs Initialize-GroupRuntimeRole.ps1, then New-LocalBackendConfig.ps1; writer reviews the
role report, then T09.

### Runtime role + T09 — 2026-11-04 01:05 → 2026-11-07 22:10

Role (owner ran Initialize-GroupRuntimeRole.ps1 01:05): lms_group_app created, password set by owner,
grants applied. Its report stopped at the sequence query (`"pg_toast_16392" is not a sequence`: pg_class
relkind filter bug) so the smoke part did not run there. Script fixed (uses pg_sequences; new
`-ReportOnly` switch). Report + smoke re-run AS lms_group_app (password read from .local\backend.json into
process env, never printed) → D:\DLU-LMS\PostgreSQL\logs\runtime-smoke-20261107.txt, psql exit 0:
rolsuper/createdb/createrole/replication/bypassrls all f; grants app DELETE 1, INSERT 5, SELECT 6,
UPDATE 5, derived SELECT 18, lms SELECT 13 (= ceiling); sequence USAGE only on the 5 write tables' id
seqs, UPDATE none; CREATE on db/lms/app/derived/public all f, TEMP f; BEGIN…ROLLBACK smoke: read
derived.student_dashboard ok; INSERT lms.course, DELETE app.notifications, TRUNCATE app.flashcards,
CREATE TABLE app.* all "permission denied".
.local\backend.json (owner ran New-LocalBackendConfig.ps1): 6 keys present, DEMO 205/102, ACL only
DESKTOP-BMK6MGL\admin FullControl, inheritance off, git-ignored.

T09 (backend log D:\DLU-LMS\Artifacts\t09\backend-*.log, 127.0.0.1:8081 only, DB user lms_group_app):
- 2026-11-04: health 200 status=UP database=CONNECTED; 24 read endpoints 200. **Bug found:** every
  cross-user/role request returned 401 instead of 403 — accessDeniedHandler's sendError(403) re-dispatches
  to /error, which was re-authorised anonymously → 401. Fix: SecurityConfig permits
  `DispatcherType.ERROR` (only the error dispatch; the original request is still authorised).
  Gate: tools\Test-Backend.ps1 -Package exit 0, 71 tests 0 fail 0 error 1 skipped, BUILD SUCCESS, jar
  SHA256 E8C06A11…13B8E. Re-run isolation 12/12 OK. No frontend change → APK unchanged, no Flutter gate.
- 2026-11-07: session teardown on 11-04 had killed pg_ctl-started postgres (child of the session's job);
  restarted with tools\Use-LocalPostgres.ps1 -Action Start → automatic WAL recovery clean, 127.0.0.1:55432.
  NOTE: postgres/backend/emulator started from a Claude session die when that session ends.
- Emulator: existing AVD DLU_LMS_Pixel, serial emulator-5554, `adb reverse tcp:8081 tcp:8081`; APK
  D:\DLU-LMS\Artifacts\dlu-lms-group-2026-11-03-debug.apk SHA256 A07660D5…C01AE verified, install Success
  (package com.example.lms_mobile_app). C dropped 23.9 → 18.0 GiB while emulator runs (pagefile.sys grows).
- Flows (UI on emulator, screenshots D:\DLU-LMS\Artifacts\t09\screens, 40 PNG; data is synthetic per A0):
  Student 205: dashboard PASS; courses PASS (3); tasks PASS (filters, 5 overdue); course detail PASS;
  grades PASS; attendance PASS (MOBILE101 5/5; TEST101 correctly "no data"); reflection add PASS;
  flashcard add/edit/delete PASS (pre-existing card untouched); goal create + cancel PASS (goal has no
  free-text field, so no "[T09-TEST]" prefix possible); notifications PASS; mark-read PASS.
  Teacher 102: home PASS; courses PASS (3); student list PASS; assignment + quiz monitoring PASS;
  student detail PASS; note add + status change (active→resolved) PASS; reminder composer opens/cancel PASS.
  Reminder SEND: UI only offers "Nhắc N" for whole lists (3/4/15 here, no filter to 1) → not sent from UI;
  sent once via the app's own API to student 205 only (POST …/teachers/102/courses/13/reminders → 200
  sent=1); student 205 sees it in-app ("Nhắc nhở từ giảng viên"), marked read via UI.
  Role switch: Back → signOut → role screen; teacher screens show no student data and vice versa PASS.
  Isolation (API, D:\DLU-LMS\Artifacts\t09\isolation-20261107.txt): 14/14 as expected (10×403, 2×401, 2×200).
  Backend log: 0 WARN/ERROR lines.
- Records created by T09 (all app.*, all to remove/ignore later if wanted): learning_reflections id 5
  (user 205, course 14, "[T09-TEST] …"); flashcards — 1 created then deleted (0 left); learning_goals id 10
  (user 205, completion_percentage, status cancelled); teacher_notes id 3 (102→a student, "[T09-TEST]",
  resolved) and id 4 (auto support-note written by the reminder, active); notifications id 12 (to 205,
  teacher_reminder, read). No Moodle/lms.* writes.
- Observation (not fixed): student 205 notifications list returns id 3000005 twice with different
  source_kind (reminder vs notification) — ids from two tables share a namespace in the merged feed.

WRITER_TRANSFER: ACCEPTED by native Claude Code 2.1.308 at 2026-10-31 01:52 +07
(Windows NT 10.0.26300, PowerShell 7.6.5, cwd D:\DLU-LMS-Group. Pre-accept process check: no
java/mvn/dart/flutter/gradle running; Codex desktop app-server + its MCP helpers are open but idle,
no shell child in this workspace. This native session is now the ONLY writer.)
WRITER_TRANSFER (2026-10-31 01:00 +07): owner chose a Windows-native Claude Code session at
D:\DLU-LMS-Group as the next writer. PENDING until that session confirms it accepted the task.
From that confirmation on, the native session is the ONLY writer; this desktop/cloud session
stops editing source. Never run two builds or migrations at once. Native session: verify it runs
on Windows, read the rules + TASK_BOARD/ACCESS_MATRIX/API_CONTRACT, then `.\tools\Test-Backend.ps1`.
Task text for the native session: docs/NATIVE_TAKEOVER_PROMPT.md. Computer use could not launch it:
Terminal and Windows PowerShell are grantable only at tier 'click' (no typing/keys/paste), so the owner
starts PowerShell + `claude` manually. Claude Code native install not detected (no %USERPROFILE%\.local;
WinGet/npm installs not checked). Pre-flight OK: one JDK candidate, Maven 3.9.16, flutter.bat/dart.bat,
D:\DLU-LMS\{Temp,Caches,Android} exist.
01:29 and 01:37 +07: the NATIVE_TAKEOVER_PROMPT task message reached the cloud/desktop session, not a native one.
Section 0.1 check FAILED there (Ubuntu 22.04 Linux VM, no PowerShell), so NOT accepted and no gate run.
No ACCEPTED line and no workspace .claude/ yet: no native session has written here.

GIT: branch `codex/group-stack-takeover`, unborn (no HEAD/commit), no remote; 306 untracked
files at takeover. No commit, push, reset, clean or stash performed. Read with
`GIT_OPTIONAL_LOCKS=0` so no index writes.

## Verified this session (evidence, no secrets)

- SQL backup is present: `D:\doan\lms_mobile_learning_backup.sql`, 274,562 bytes, SHA256
  `936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4` = SOURCE_BASELINE.
  The old blocker EXACT_DATABASE_BACKUP_MISSING is RESOLVED for file availability only.
  Restore is still gated (database/README.md). Owner: no import-over authorization yet.
- Static dump inventory (statement-prefix counts, no rows read): 44 CREATE TABLE
  (37 lms + 7 app), 21 CREATE VIEW, 44 COPY, 71 `OWNER TO`, 44 PRIMARY KEY, 41 FOREIGN KEY;
  header pg_dump/server 18.6, has `\restrict` and `SET transaction_timeout`. Matches baseline.
  `derived.teacher_student_monitoring` exposes `teacherid`, `courseid`, `studentid`
  (used by the new TeacherNoteRepository roster guard).
- Unfinished-change baseline = original extractions under
  `D:\doan\DO-AN-TOT-NGHIEP-{BACKEND,FRONEND}-main\...` (`diff -rq` against them):
  - Backend main: 15 files changed, 3 added (LocalDevelopmentSettings,
    PathIdentityAuthorizationManager, application-local-development.properties).
  - Backend tests: 7 changed, 4 added (JwtTokenProviderTest, LocalDevelopmentSettingsTest,
    LearningWriteSecurityTest, TeacherNoteSecurityTest).
  - Frontend lib: 5 changed, 3 added (api_exception, api_session, learning_note_dialog);
    tests: 15 changed, 2 added + test/support; Android manifests + generated files.
- Intent of the interrupted edits (reviewed): startup DDL runner removed; no default DB URL,
  password or JWT secret; demo-login only with profile `local-development` + explicit flag,
  server-owned IDs, loopback bind; JWT issuer/audience/exp/role allowlist; path-identity
  authorization with deny-all fallback; flashcard/reflection course-enrolment checks;
  teacher-note roster scope and parameterized SQL; Flutter `API_BASE_URL` dart-define with
  HTTPS/local validation, memory-only Bearer session, error states, dialog draft keeping.
- Default backend tests are isolated: only `SchemaVerificationTest` is `@SpringBootTest`
  and it is `@Disabled` + tagged `database-integration`; others are standalone or
  `@WebMvcTest` slices with mocks (no DataSource).

## Changed by Claude

- `backend/src/main/java/com/dlu/lmsmobile/service/ReflectionService.java`: import of
  nonexistent `InightsRepository` corrected to `InsightsRepository` (compile error left by
  the interrupted edit). Confirms the 27 Oct JAR in backend/target predates current source.
- Frontend (2026-11-03, native session): `dart format .` on 55 files (via Test-Flutter.ps1);
  `dart fix --apply` 20 lint fixes in 11 files; `print`→`debugPrint` in
  test/product_polish_test.dart. No behaviour change intended; see Gates T05.
- Docs: this file, `ACCESS_MATRIX.md`, `TASK_BOARD.md`, `API_CONTRACT.md` (new); dated
  backup-status notes in `SOURCE_BASELINE.md`, `LOCAL_RUNBOOK.md`, `database/README.md`.
- Static checks only: every `com.dlu.lmsmobile.*` import resolves to a source file; every
  Dart relative/package import resolves. This is NOT a compile or analyze result.

## Session tool limits (see ACCESS_MATRIX.md)

The bridge shell is a Linux VM: Windows `.cmd/.bat/.exe` toolchain cannot run there; VM has
Java 11 (no javac), no mvn/flutter/psql, Maven Central unreachable; no Windows process view;
no Windows localhost. Per owner instruction, nothing was installed to work around this.

## Gates

- Backend isolated tests (T03): PASS 2026-10-31 02:01 +07, native Claude Code.
  `pwsh -NoProfile -ExecutionPolicy RemoteSigned -File .\tools\Test-Backend.ps1` (RemoteSigned =
  machine policy; the launcher process had inherited Process=Bypass, not set by Claude) → exit 0,
  BUILD SUCCESS, Maven `clean test` 41 s, Java 21.0.12.1. Surefire: tests 71, failures 0, errors 0,
  skipped 1 (SchemaVerificationTest, still @Disabled). 14 test classes. Log grep: 0 matches for
  hikari/jdbc:postgresql/datasource/connection refused → no DB contact. Local log (not in Git):
  D:\DLU-LMS\Temp\backend-test-20261031.log. No source change was needed.
- Backend package (T04): PASS 2026-11-03 18:55 +07. `Test-Backend.ps1 -Package` (RemoteSigned)
  → exit 0, BUILD SUCCESS 38.6 s; tests again 71/0F/0E/1 skipped; log grep 0 DB matches.
  JAR `backend\target\lms_mobile_backend-0.0.1-SNAPSHOT.jar` 27,370,580 bytes, SHA256
  003CD96F2955DBC07D13AE5D283EA04C0CEA940E9564EB13B2D28C10E032E7B3 (built from current source;
  replaces the stale 27 Oct JAR). Log: D:\DLU-LMS\Temp\backend-package-20261103.log.
- Flutter format/analyze/test (T05): PASS 2026-11-03 ~22:50 +07 on the 3rd run.
  - Run 1 (18:55): `dart format .` reformatted 55 of 70 .dart files (35 lib, 20 test;
    whitespace/layout only; list in D:\DLU-LMS\Temp\dart-format-changed-20261103.txt); the
    session was interrupted during analyze's `pub get` — no result recorded.
  - Run 2: format 0 changed; `flutter analyze` exit 1 on 21 info-level lints (no errors/warnings):
    16 curly_braces_in_flow_control_structures, 4 unnecessary_brace_in_string_interps,
    1 use_null_aware_elements, 1 avoid_print.
  - Fix: `dart fix --apply` (20 fixes, 11 files: student_analytics/flashcard/task_center screens,
    teacher_analytics/home/notes screens, services/api_service.dart, tests learning_support,
    local_api_session, risk_action_flow, teacher_reminder_notifications) + manual
    `print`→`debugPrint` in test/product_polish_test.dart. api_service.dart:480 now uses
    `'courseId': ?courseId` (same semantics as the old `if (courseId != null)`; SDK >=3.12).
  - Run 3: format 0 changed, analyze "No issues found!", `flutter test` 203 passed, exit 0.
    Log: D:\DLU-LMS\Temp\flutter-test-20261103c.log. Tests use mocks only (no backend/DB).
- Debug APK (T06): PASS 2026-11-03 22:55 +07. Pre-check C free 22.4 GB (≥ 15; Gradle/Pub/TEMP
  on D:). `Test-Flutter.ps1 -BuildApk` → exit 0 (format 0 changed, analyze clean, 203 tests,
  then `assembleDebug` 413 s). `frontend\build\app\outputs\flutter-apk\app-debug.apk`
  148,091,503 bytes, SHA256 A07660D5F9387299F76710899B7A375D2B10D493960F778CC3BEF7F63C9C01AE.
  Built with LOCAL_DEVELOPMENT=true, API_BASE_URL=http://127.0.0.1:8081/api/v1 (needs
  `adb reverse tcp:8081 tcp:8081`). Gradle warning only: SDK XML v4 vs older tools (harmless).
  C free after 22.4 GB. Not installed/run on a device — that is part of T09.
  Log: D:\DLU-LMS\Temp\flutter-apk-20261103.log.
- DB restore / catalog verification: NOT_RUN (BLOCKED: approved empty target, version
  compatibility, owner mapping, explicit approval).
- API + emulator runtime (notes/reflections persistence, role isolation): NOT_RUN.
- Old project PASS results do not count here.

## Exact next step

On Windows PowerShell at `D:\DLU-LMS-Group`, run by a Windows-capable runner the owner
chooses (owner, Claude via computer use, or one native Claude Code session; still one writer):

(Updated 2026-11-04 01:00.) Restore approved (A0 = tổng hợp, QUYEN_DUNG_LOCAL=CO). Owner runs, in a
normal (non-elevated) PowerShell window, typing the postgres password once at the hidden prompt:
`pwsh -NoProfile -ExecutionPolicy RemoteSigned -File D:\DLU-LMS-Group\tools\Invoke-GroupRestore.ps1`
Then writer reviews logs\restore-*.log (aggregates only), t08-verify-*.txt (every count vs README),
e4-demo-ids-*.txt. If clean, owner runs `tools\Initialize-GroupRuntimeRole.ps1` (postgres password once,
then sets the lms_group_app password via \password). Then F (backend.json script, backend, emulator).
(Earlier, superseded:) T07a PASS — empty cluster on D, 127.0.0.1:55432, running.
(Done:) initdb, Check, Start, owner Verify.
(Previous step, done:) Verified binaries are in D:\DLU-LMS\Toolchains\pgsql-18-verified.
Owner runs in their OWN non-elevated PowerShell window (not via `!`), typing the password at the
hidden prompt:
`$env:TEMP='D:\DLU-LMS\Temp'; $env:TMP=$env:TEMP; & 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin\initdb.exe' -D 'D:\DLU-LMS\PostgreSQL\data' -U postgres --pwprompt -A scram-sha-256 -E UTF8 --locale-provider=builtin --builtin-locale=C.UTF-8 -c listen_addresses=127.0.0.1 -c port=55432 -c logging_collector=on -c log_directory=D:/DLU-LMS/PostgreSQL/logs`
Then writer: `.\tools\Use-LocalPostgres.ps1 -Action Check` (static; must pass) → `-Action Start`
→ check listener/postmaster.pid → owner `-Action Verify` (psql prompt) → mark T07a PASS only if all OK.
Stop: `-Action Stop`. Never run binaries from the old ...\pgsql-18 zip extract.
(Earlier blocked text:) T07a BLOCKED: PACKAGE_INTEGRITY_UNVERIFIED (see T07a update). T07b restore stays NOT approved (RESTORE_DUMP=KHONG): do not create
lms_mobile_group_dev. (The earlier `-Action Init` instruction is withdrawn; that action no longer exists.)

(Superseded 2026-11-03 text, kept for history:) T03–T06 done; APK handed off (see "APK handoff"). Do not rebuild.
Next = T07, waiting for ONE owner approval covering: dump provenance/usage permission; installing
a portable PostgreSQL 18.x (≥18.6) server on D (download + extract on D only, checksum verified);
initdb to D:\DLU-LMS\PostgreSQL\data on 127.0.0.1:55432 started with pg_ctl (no Windows service);
superuser password entered by the owner interactively; restore as `postgres` into NEW
`lms_mobile_group_dev` with `-X -v ON_ERROR_STOP=1 --single-transaction`; runtime role
`lms_group_app` (password set by owner via `\password`). After approval: measure C/D, recheck
C ≥ 15 GiB, then proceed. Then T08 (verify_group_catalog.sql, review every count vs
database/README.md) and T09 (backend + AVD DLU_LMS_Pixel on D + adb reverse 8081).
No commit/push has been made.

## Previous checkpoint (Codex, 2026-10-27) — kept for history; superseded above

### Exact handoff — 2026-10-27

STATUS: IN_PROGRESS — source takeover and safe local foundation.
ACTIVE_WORKSPACE: D:\DLU-LMS-Group
OWNER: Codex (do not start another writer on this working copy while active).

#### Completed

- Preserved all old repositories and databases; no destructive operation.
- Copied both previously reviewed group source extractions into backend/frontend.
- Added root ignore and shared agent rules. No remote, commit or push.
- Read both scoped AGENTS.md.
- Confirmed installed Flutter3.44.9/Dart3.12.2; current PATH Java17 is insufficient
  for Java21 backend. Portable Java21/Maven setup on D is in progress.

#### Active work

- Backend: eliminate implicit startup DDL/default secrets; explicit local-only
  development auth, ownership checks and isolated tests.
- Frontend: configurable API URL, Bearer transport/local dev gate, notes/reflection
  error and draft preservation, focused tests.
- Database: read-only catalog/integrity verification and restore requirements.

#### External blocker

EXACT_DATABASE_BACKUP_MISSING: original SQL Downloads file is absent. User notified.
Do not use old mock SQL, old runtime/candidate database, or fabricate a substitute.
Do not declare DB/API runtime PASS until exact backup/authorized target is available.

#### Gates

Database restore/runtime: NOT_RUN.
Backend tests/build: NOT_RUN (toolchain/preconditions in progress).
Flutter analyze/tests/APK/runtime: NOT_RUN for this new working copy.
Old project PASS results do not count here.

#### Next checkpoint

Finish safe config/auth edits; install portable tools with checksums; run isolated
backend tests and Flutter gates; document real results. If SQL returns, recheck its
hash and explicit target authority before any restore. Update this file at milestone.

## GÓI V2 (docs/V2_FEATURES_PROMPT.md + PART_B.md) — bắt đầu 2026-11-07 22:40
Owner: DOI_NGAY_DEMO=CO; 2 reflection mồ côi giữ nguyên = giới hạn dữ liệu mẫu (không xóa); dừng khi cần chạy script migration.
Thứ tự (Part B §0): N1 → N9 → N2 → N4 → N3 → [APK+emulator] → migration (gồm study_sessions) → N5 → N6 → N7 → N10 → …
Ràng buộc phát hiện: lms_group_app KHÔNG có SELECT trên lms.grade_items/grade_categories/grade_grades và file V2 cấm cấp thêm
quyền lms → engine điểm chỉ đọc derived.student_grade_overview (có category_id/parent_category_id, grademax, gradepass), không
đọc được aggregation/aggregationcoef/hidden/aggregateonlygraded → giả định Mean of grades, ẩn = không có module hiển thị.
Backend được tắt trong lúc chạy gate (mvn clean xóa target của backend đang chạy); postgres vẫn chạy.

### V2-N1 Mô phỏng điểm và "điểm cần đạt" — 2026-11-07 23:30
Files: backend service/GradeForecastService.java, repository/ForecastRepository.java, controller/StudentForecastController.java;
  test service/GradeForecastServiceTest.java (13), V2SecurityTest.java (4); frontend models/grade_forecast.dart,
  screens/student/grade_forecast_screen.dart, services/api_service.dart (getGradeForecast), student_course_detail_screen.dart
  (nút "Mô phỏng điểm" trong thẻ Tổng quan điểm); test grade_forecast_test.dart (4).
API: GET /api/v1/dev/students/{userId}/courses/{courseId}/grade-forecast (404 nếu chưa ghi danh)
Tests: backend 88/0/0/1; flutter 207 pass; test mới: GradeForecastServiceTest (cây 2 tầng, đã chấm hết, chưa chấm, chỉ tính
  nhóm đã chấm, không khả thi, đã chắc đạt, item ẩn, có trọng số + trọng số thiếu → approximation, item ở gốc, ngưỡng qua,
  nhiều gốc, ngưỡng nhóm GV, JSON); V2SecurityTest 401/403/404/200; widget: kéo slider 50,0% → 65,0%, chọn 80%, lưu mục tiêu
  target_grade.
Gate: Test-Backend -Package exit 0, JAR SHA256 71BE06CB…B88ABBF2; Test-Flutter exit 0
Runtime: SQL item đã chạy thật bằng lms_group_app: 5 khóa, mọi item khớp module hiển thị, 53 ms. UI emulator: chờ cuối hạng A.
Còn thiếu / giới hạn: aggregation/coef/hidden của Moodle không đọc được (xem trên); ngưỡng qua lấy gradepass/grademax chung
  của các bài (dữ liệu: 50/100), khác nhau thì dùng 50% mặc định và UI ghi rõ.

### V2-N9 Tình trạng học tập của tôi — 2026-11-08 00:20
Files: backend service/RiskScore.java (công thức dùng chung; ClassInsightsService.scoreBreakdown/groupForScore gọi lại),
  service/LearningHealthService.java, repository/LearningHealthRepository.java, controller/StudentHealthController.java;
  test service/LearningHealthServiceTest.java (6), V2SecurityTest (+N9); frontend models/learning_health.dart,
  widgets/learning_health_widgets.dart, screens/student/learning_health_screen.dart (màn chi tiết, ô Home, ô khóa học),
  student_dashboard_screen.dart (ô dưới lời chào), student_course_detail_screen.dart (ô đầu tab Tổng quan); test learning_health_test.dart (3).
API: GET /api/v1/dev/students/{userId}/learning-health; GET …/courses/{courseId}/learning-health (404 nếu chưa ghi danh)
Tests: backend 95/0/0/1; flutter 210 pass; test mới: điểm SV = điểm GV (5 bộ số, so với ClassInsightsService.studentDetails
  và risk_score lưu), ngưỡng mức, ≤3 hành động gộp "vào học" (40+10), khóa Xanh không có hành động, chỉ truy vấn userId của
  chính mình + payload không có userid/fullname, 404; widget ô Home → màn chi tiết; ô ẩn khi API lỗi.
Gate: Test-Backend -Package exit 0, JAR SHA256 62E23713…19FEBDBF; Test-Flutter exit 0
Runtime: DB thật bằng lms_group_app: 46/46 hàng student_risk_indicator có luật Java = risk_score lưu = điểm GV thấy;
  truy vấn endpoint của SV 205: 3 khóa, 4–32 ms. UI emulator: chờ cuối hạng A.
Còn thiếu / giới hạn: hành động "RECOMMENDATIONS" hiện mở tab Tổng quan của khóa (nơi đặt mục gợi ý N2).

### V2-N2 Gợi ý ôn lại theo chương — 2026-11-08 01:05
Files: backend service/StudyRecommendationService.java, controller/StudentRecommendationController.java,
  repository/ForecastRepository.java (+findClassItemStats: chỉ trung bình + số SV có điểm theo hoạt động);
  test service/StudyRecommendationServiceTest.java (6), V2SecurityTest (+N2); frontend models/study_recommendation.dart,
  widgets/study_recommendation_widgets.dart (mục "Nên ôn lại", thẻ chương), api_service.dart, student_dashboard_screen.dart
  (dưới "Ưu tiên hôm nay"), student_course_detail_screen.dart (tab Tổng quan), student_flashcard_screen.dart (tham số
  openAddWithFront mở dialog thêm thẻ của đúng khóa); test study_recommendation_test.dart (3).
API: GET …/students/{userId}/courses/{courseId}/study-recommendations (404 nếu chưa ghi danh);
  GET …/students/{userId}/study-recommendations?limit=3 (1–10)
Tests: backend 102/0/0/1; flutter 213 pass; test mới: chương dưới ngưỡng qua + thứ tự gợi ý, chương không có điểm (chỉ yếu khi
  có bài tính điểm quá hạn), bài đã nộp không tính quá hạn, chương yếu vì lớp cao hơn ≥10 điểm (chỉ khi ≥5 SV có điểm; 4 SV
  → ẩn số lớp), tối đa 3 gợi ý + sắp theo mức yếu, ngưỡng qua; security 401/403/404.
Gate: Test-Backend -Package exit 0, JAR SHA256 DAADF7E1…6DA8D678; Test-Flutter exit 0
Runtime: chờ cuối hạng A (emulator).
Còn thiếu / giới hạn: trung bình lớp chỉ dùng khi ≥5 SV có điểm ở hoạt động đó (riêng tư; khóa 13/14 có 4 SV nên tiêu chí
  "thấp hơn lớp" không áp dụng ở đó). Lỗi tìm thấy khi test: Set.of(..).contains(null) ném NPE với task_status null của tài
  liệu — đã sửa (in()).

### V2-N4 Dự báo qua môn của cả lớp (giảng viên) — 2026-11-08 01:40
Files: backend service/GradeForecastService.java (+teacherForecast, classJson, BAND_ORDER; dùng TeacherRepository.hasCourse/
  findStudents), controller/TeacherForecastController.java; test service/TeacherForecastTest.java (3), V2SecurityTest (+GV);
  frontend models/class_forecast.dart, screens/teacher/class_forecast_section.dart, teacher_analytics_screen.dart (mục "Dự báo
  qua môn" trước "Tiến độ và kết quả học tập"), api_service.dart; test class_forecast_test.dart (2); sửa 2 test cũ đếm/giới hạn
  request (course_navigation_test thêm 'grade-forecast' vào danh sách cho phép; drilldown chỉ đếm GET class-insights).
API: GET /api/v1/dev/teachers/{teacherId}/courses/{courseId}/grade-forecast (404 nếu không phải khóa của GV)
Tests: backend 107/0/0/1; flutter 215 pass; test mới: 4 SV → SURE_PASS/SAFE(need 60)/HIGH_RISK(90)/NOT_FEASIBLE, thứ tự gấp
  trước, 1 truy vấn điểm cho cả lớp; SV chưa có điểm → SAFE need=ngưỡng; khóa GV khác → 404, không tải gì; security 401/403
  (GV 103, token SV)/404; widget đếm theo nhóm, lọc, mở SV, nút "Nhắc riêng" (không có cho SURE_PASS).
Gate: Test-Backend -Package exit 0, JAR SHA256 F141F7EB…4D15A7EF; Test-Flutter exit 0
Runtime: chờ cuối hạng A.
Còn thiếu / giới hạn: "Nhắc riêng" mới là callback (nối N8 ở hạng B). Ngưỡng: SAFE need ≤60, EFFORT ≤85, HIGH_RISK ≤100.
Ghi chú: tab Phân tích GV đã có sẵn "ActivityHeatmapSection" → N15 phải đối chiếu để không làm lại.

### V2-N3 Vị trí của tôi trong lớp — ẩn danh — 2026-11-08 02:15
Files: backend service/PeerComparisonService.java, repository/ForecastRepository.java (+findClassProgress, +findClassAverageGrades:
  chỉ trả (mine boolean, giá trị), không có id), controller/StudentForecastController.java (+peer-comparison);
  test service/PeerComparisonServiceTest.java (6), V2SecurityTest (+N3); frontend models/peer_comparison.dart,
  widgets/peer_comparison_widgets.dart (thẻ + fl_chart BarChart, cột của mình tô đậm; danh sách theo khóa), api_service.dart,
  student_course_detail_screen.dart (tab Tổng quan), student_analytics_screen.dart (mục "Vị trí của tôi trong lớp");
  test peer_comparison_test.dart (2).
API: GET /api/v1/dev/students/{userId}/courses/{courseId}/peer-comparison (404 nếu chưa ghi danh)
Tests: backend 114/0/0/1; flutter 217 pass; test mới: lớp 4 người → suppressed (không có mine/median/histogram), lớp 15 người
  percentBelow 64,3 = 9/14 + median + histogram, biên khoảng (100 → khoảng cuối), SV chưa có dữ liệu, JSON không có
  userid/name/fullname/email/student_code, 404; widget biểu đồ + chuyển sang Điểm TB bị ẩn.
Gate: Test-Backend -Package exit 0, JAR SHA256 AE603433…C6760FC1; Test-Flutter exit 0
Runtime: chờ emulator (ngay sau đây).
Còn thiếu / giới hạn: ngưỡng ẩn danh 5 SV có dữ liệu; khóa 13/14 (4 SV) sẽ hiện "Lớp quá nhỏ…", chỉ MVP3-LEARN (15 SV) có biểu đồ.

### V2 hạng A — chạy thật trên emulator — 2026-11-08 11:25
APK: D:\DLU-LMS\Artifacts\dlu-lms-group-v2-rankA-debug.apk SHA256 7F403132438DFE31273D8B0EB362F71CD7318E8C85402461674BF5A94ABF56EF
  (Test-Flutter -BuildApk exit 0: analyze sạch, 217 test pass). Backend JAR AE603433…C6760FC1, 114/0/0/1.
C: 14,99 GiB khi emulator chạy → tắt emulator trước build (quy tắc 8) → 20,03 GiB; build xong 20,86 GiB.
API thật (lms_group_app, SV 205 / GV 102): N1 khóa 13 hiện tại 54,7 (tay: (95+92+0)/3=62,33; (94+0)/2=47 → 54,67), cần 25%
  ở 1 bài, tối đa 59,4; N9 2 Đỏ 1 Vàng, score = storedScore cả 3 khóa; N2 6 chương yếu (điểm 0 thật của bài MVP3 seed);
  N3 khóa 13 suppressed (4 SV), MVP3 15 SV histogram 3,3,0,3,6 (tổng 15); N4 MVP3: 2 chắc qua/11 an toàn/1 cố gắng/1 nguy cơ
  cao; khóa GV khác 404; SV chưa ghi danh 404; 19–186 ms (lần gọi đầu 442 ms).
Emulator (DLU_LMS_Pixel, emulator-5554, adb reverse 8081): ảnh D:\DLU-LMS\Artifacts\v2\screens\ n1-01..03, n2-01..02, n3-01..02,
  n4-01..03, n9-01..03 (dữ liệu tổng hợp theo A0). Kiểm: mục tiêu 70% → "Không thể đạt… tối đa 59,4%"; kéo slider → 59,4% =
  bestCase; lọc "Nguy cơ cao" → mở đúng SV (điểm TB 0%, tiến độ 100%). Không ghi dữ liệu thật trong lượt này (nút "Lưu làm
  mục tiêu" chỉ kiểm bằng widget test).
Sự cố khi điều khiển UI: uiautomator trả tọa độ semantics cũ của Flutter sau khi cuộn → vài lần bấm trúng "Quay lại"/chip
  khác (app về màn chọn vai trò, lọc sai nhóm). Không phải lỗi app; từ đó dùng tọa độ lấy từ ảnh chụp.
Video hạng A: NOT_RUN (để cuối gói).
Migration: database/migrations/2026-11-08_v2_features.sql (flashcard_reviews, study_plan_items, study_sessions; idempotent,
  chỉ app); grants_lms_group_app.sql cập nhật (tên DB lấy theo current_database(); quyền V2 chỉ cấp khi bảng tồn tại;
  notification_preferences SELECT/INSERT/UPDATE; DELETE thêm cho study_plan_items theo V2 §3); database/demo/shift_demo_dates.sql
  (71 cột epoch liệt kê rõ, guard chỉ chạy trên lms_mobile_group_demo; xem trước với 08/11: dời 52 ngày, 7 hạn trong 7 ngày tới);
  tools/Apply-V2Migration.ps1 (parse OK; C≥15, đúng cluster, pg_dump -n app → D:\DLU-LMS\Backups, migration --single-transaction,
  grants, báo cáo quyền; -CreateDemo [-DemoTargetDate]); Start-LocalBackend cho phép lms_mobile_group_(dev|demo);
  tools/Set-LocalBackendDatabase.ps1. docs/FEATURES_V2.md (N1, N9, N2, N4, N3, demo).
STATUS: DỪNG — chờ owner chạy Apply-V2Migration.ps1 (theo yêu cầu "khi cần chạy script migration thì dừng và báo").

Owner decision 2026-11-07: 2 app.learning_reflections mồ côi (thiếu user/course) GIỮ NGUYÊN — giới hạn đã biết của dữ liệu mẫu, không xóa, không viết migration xóa.

!! Ổ C: emulator chạy làm pagefile (C:\pagefile.sys, tự quản lý) phình: 20,9 → 12,5 GiB sau ~25 phút chạy hạng A; tắt emulator →
18,1 GiB. Đã tắt emulator ngay khi <15 GiB. Ảnh hưởng ngày bảo vệ/O1: cần thêm chỗ trống trên C (dọn file của chính owner,
hoặc chuyển pagefile sang D — cần quyền admin, owner tự quyết). Temp\qegh4jq1 (1,95 GB, 07/11 18:59, không phải của phiên này)
và Temp\BRL000071d8 (cần admin) vẫn để nguyên.

### V2 migration — owner chạy Apply-V2Migration.ps1 -CreateDemo -DemoTargetDate 2026-11-20 — 2026-11-09 19:46
Trước đó owner chạy Reset-PostgresPassword.ps1 (mật khẩu postgres mới; không ghi ở đây). Cluster start bằng Use-LocalPostgres
(PID 17184; cảnh báo "another server might be running" = postmaster.pid cũ, cổng 55432 trống trước khi start).
- Backup app dev: D:\DLU-LMS\Backups\app-before-v2-20261109-194644.sql sha256 B234E27CAF7AE7FA8E5C45238378532F2D61C835F7037C65899058AB688A3684.
- dev: migration/grants exit 0. demo: create/restore/shift/migration/grants exit 0. Dời 64 ngày; hạn muộn nhất 2026-11-25;
  19 hạn trước 20/11, 7 hạn trong 7 ngày tới, 0 sau đó; 71 cột, 2145 column-rows.
- Báo cáo quyền (cả dev & demo giống nhau): lms_group_app không super/createdb/createrole/replication/bypassrls; app SELECT 10,
  INSERT 9, UPDATE 8, DELETE 2 (flashcards, study_plan_items); study_sessions INSERT,SELECT; learning_reminders SELECT;
  derived SELECT 18, lms SELECT 13; không CREATE trên lms/app/DB. Khớp grants_lms_group_app.sql.
- Kiểm log (Claude): v2-migration-20261109-194644.log 36 dòng, restore-demo-20261109-194644.log 662 dòng: 0 error/fatal/warning.
STATUS: migration PASS (kiểm chứng xong). Tiếp theo theo Part B §0: N5.

### V2-N5 Ôn tập ngắt quãng SM-2 — 2026-11-09
Backend: service/Sm2.java (hàm thuần: q<3 → reps 0, I=1; 1/6/round(I×EF cũ); EF' làm tròn 2 số, ≥1,3; trần 36.500 ngày;
  preview 4 nút), repository/FlashcardReviewRepository.java (đọc app.flashcards + app.flashcard_reviews, chỉ khóa đã ghi danh
  qua derived.student_course_progress; ghi DUY NHẤT app.flashcard_reviews bằng INSERT … ON CONFLICT DO UPDATE),
  service/FlashcardReviewService.java (rating ∈ {1,3,4,5}, khác → 400; khóa chưa ghi danh/thẻ không thuộc SV+khóa → 404, không ghi),
  controller/StudentFlashcardReviewController.java: GET /dev/students/{id}/flashcards/due[?courseId=],
  POST /dev/students/{id}/courses/{c}/flashcards/{id}/review {rating}.
  Test: Sm2Test (16, bảng + lặp nhiều lần + quên rồi học lại + chặn EF 1,3 + trần), FlashcardReviewServiceTest (8),
  V2SecurityTest (+2 GET vào 401/403, +3 test POST 401/403/404/200).
Frontend: models/flashcard_review.dart, ApiService.getDueFlashcards/reviewFlashcard, screens/student/flashcard_review_screen.dart
  (phiên ôn: mặt trước → chạm lật → 4 nút Quên/Khó/Được/Dễ kèm "1 ngày"/"15 ngày"… → tổng kết; lỗi lưu giữ nguyên thẻ;
  trạng thái rỗng có giải thích) + DueFlashcardsChip "Hôm nay cần ôn N thẻ" trên dashboard (ẩn khi 0 hoặc lỗi);
  student_flashcard_screen.dart: bỏ chế độ lật "Đã nhớ/Cần ôn lại" cũ, nút "Bắt đầu ôn tập · N thẻ đến hạn" mở phiên SM-2.
  Test: flashcard_review_test.dart (12).
Gates: Test-Backend.ps1 -Package exit 0 (141 test, 0 fail, 1 skip = SchemaVerificationTest @Disabled; JAR build);
  Test-Flutter.ps1 exit 0 (format 0 đổi, analyze sạch, 229 test pass). Lần đầu Flutter fail 1 test (setState trả Future khi
  "Thử lại") → sửa → PASS; lần 2 analyze 1 info (curly braces) → sửa → PASS.
Chạy thật API/emulator: NOT_RUN (để cuối hạng A theo Part B §0; POST review sẽ ghi app.flashcard_reviews trên DB đang chọn).
STATUS: N5 DONE (gate). Tiếp theo: N6 Kế hoạch học tuần.

## V3 — Portal đào tạo DLU (docs/V3_PORTAL_PROMPT.md) — bắt đầu 2026-11-09 20:00
Owner: V3 ưu tiên cao nhất. Thứ tự: (V2 dở: không có — N5 đã DONE) → P0 → P1…P8 → Sơ đồ → V2 còn lại (N6…).
Quy tắc §2: không key trong file/console/log; không in tên/MSSV/điểm thật; fixture bịa (2399Z001, ITK99Z, CQ99CT).

### V3-P0 Nền tảng tích hợp Portal — 2026-11-09 20:10
Backend package com.dlu.lmsmobile.portal: PortalProperties (app.portal.*: enabled=false mặc định, baseUrl, apiKey, cacheTtl 10m,
  cacheMaxEntries 500, healthTtl 60s, connect 5s/read 15s, students userId→{studentId,studyProgramId,classId}, advisors
  teacherId→[lớp], courseMap, presentationMask=true, conductThreshold 50, gradeBands TT08/2021 3,6/3,2/2,5/2,0; toString không lộ
  key/MSSV), PortalCache (ConcurrentHashMap + hết hạn, giới hạn số mục, không lưu lỗi), PortalValues (số dạng chuỗi→BigDecimal,
  ""→null, dd/MM/yyyy, bool, maskId 2399Z001→23**Z0**), PortalClient (RestClient, X-API-KEY, retry 1 lần IO/5xx backoff 500 ms,
  4xx không retry, ok=false/JSON sai→PortalUnavailableException; log chỉ endpoint/status/ms/records; health() cache 60 s),
  PortalConfig (SimpleClientHttpRequestFactory timeout), PortalIdentity (ánh xạ do server; chưa ánh xạ→404 PORTAL_NOT_LINKED;
  Portal tắt→503 PORTAL_DISABLED; lớp cố vấn không thuộc GV→404). GlobalExceptionHandler: 503 {"code":"PORTAL_UNAVAILABLE"|
  "PORTAL_DISABLED"}, 404 {"code":"PORTAL_NOT_LINKED"}. /api/v1/health thêm portal UP|DOWN|DISABLED. application.properties:
  app.portal.enabled=false, logging org.springframework.web.client/http = INFO (DEBUG sẽ in request body).
Tools: tools\Set-PortalConfig.ps1 (mới; key Read-Host -AsSecureString, Enter = giữ key cũ, cảnh báo nếu key mk_dev_*; hỏi MSSV/CTĐT/lớp
  của SV demo DEMO_STUDENT_ID và lớp cố vấn của DEMO_TEACHER_ID, kiểm định dạng; ghi gộp PORTAL vào .local\backend.json -Depth 10,
  giữ ACL; kiểm git check-ignore; in tóm tắt đã che; /health không cần key). Start-LocalBackend.ps1: PORTAL →
  SPRING_APPLICATION_JSON (app.portal.*), thêm key + MSSV vào danh sách che log, xóa env khi thoát.
  Set-LocalBackendDatabase.ps1: sửa ConvertTo-Json → -Depth 10 (độ sâu mặc định 2 sẽ làm hỏng khối PORTAL khi đổi dev/demo).
  Parse 3 script: 0 lỗi. Kiểm hình dạng JSON bằng giá trị giả: đúng (mảng 1 phần tử vẫn là mảng).
Test: portal/PortalClientTest (13: header key, không key→DISABLED, timeout retry→503, 500 rồi 200, 502×2, 401 không retry,
  ok=false/JSON sai/mảng/thiếu ok, body null, cache hit + hết hạn, lỗi không cache, health cache 60 s, đếm bản ghi, toString;
  @AfterEach bắt log ở mức DEBUG: key, MSSV giả và body không xuất hiện), PortalSupportTest (7), PortalPropertiesBindingTest (2).
Gate: Test-Backend.ps1 -Package exit 0 — 163 test, 0 fail, 1 skip. Flutter không đổi ở P0 (màn "Chưa kết nối" làm cùng P1).
Runtime: backend thật (dev DB, lms_group_app) khởi động OK; /health = {"status":"UP","database":"CONNECTED","portal":"DISABLED"};
  GET N5 /flashcards/due = 200, total 1 (chỉ đọc). Log D:\DLU-LMS\Artifacts\v3\backend-p0-20261109-200740.log. Đã tắt backend.
  Portal: chưa cấu hình (0 bản ghi thật).
STATUS: P0 DONE (gate). (Đã thay bởi docs/V3_PORTAL_ADDENDUM.md — không dừng chờ owner; xem mục kế tiếp.)

### V3 — Phụ lục 20:10 (docs/V3_PORTAL_ADDENDUM.md): API trả dữ liệu MÔ PHỎNG, key dùng chung = key dev trên trang docs
Owner 09/11: không dừng chờ Set-PortalConfig; tự lấy key dev ghi vào .local\backend.json; chạy thật ngay sau P0; rồi P1→P8 + Sơ đồ.
Owner 09/11 (trước phụ lục): trong app bỏ mọi ghi chú không cần thiết, làm như app thật.
Lấy key: tải llms.txt + 8 trang .md của docs vào scratchpad; có 2 key mk_dev_ khác nhau → thử từng key (chỉ in status):
  key#0 200 (66 bản ghi lớp ITK47A), key#1 401 "Invalid or expired API key". Lưu ý: client Python urllib mặc định bị API trả
  403 (chặn theo client); PowerShell và JDK HttpURLConnection mặc định (= SimpleClientHttpRequestFactory của backend) đều 200.
  Không đổi User-Agent. Key ghi thẳng vào .local\backend.json (git check-ignore OK, ACL giữ nguyên) bằng script scratchpad,
  không in. Không có trong repo/log/HANDOFF. Kiểm log backend: mk_dev_ 0, X-API-KEY 0, MSSV demo 0.
Khảo sát dữ liệu mô phỏng (chỉ đếm/tên trường):
  - Lớp ITK47A 66 SV (CQ23CT 3, CQ23CT-MMT 24, CQ23CT-PM 39); ITK47C 49 SV. Endpoint theo lớp trả đủ dòng cho mọi học kỳ kể cả
    tương lai, nhưng chỉ có giá trị ở 2023-2024…2025-2026 HK01/HK02 (HK03 và 2026-2027 rỗng, Ranks 'KXL').
  - SV 2347A008 (CQ23CT-PM, ITK47A): 8 học kỳ, 64 học phần; 2026-2027 HK01 có 8 HP đã đăng ký chưa có điểm (đang học).
    Cờ dạng chuỗi: IsGather 'x', IsPass 'x', NotComputeAverageScore 'True'/'False'; TB_* lặp lại trên mọi dòng của học kỳ.
  - CTĐT: CQ23CT-PM chỉ có HK5–8 (27 HP, 84 TC); CTĐT gốc CQ23CT HK1–5 (41 HP, 109 TC) → P2 gộp gốc + chuyên ngành.
    BatBuoc là chữ 'Bắt Buộc'/'Tự Chọn'. Không CTĐT nào có HPTienQuyet/HPHocTruoc; groupSelection rỗng.
  - Quyết định: 1 (loại 16 "Quyết định khác").
Ánh xạ demo (cấu hình server, nhãn "ánh xạ demo"): SV 205 → MSSV 2347A008 / CQ23CT-PM / ITK47A (gợi ý của phụ lục, dữ liệu dày).
  courseMap: LMS 13 Software Testing → 20CT3206 Kiểm thử phần mềm (đang học trên Portal, chưa điểm); LMS 14 Mobile Application
  Development → 20CT4106D Phát triển ứng dụng di động nâng cao (HK8, chưa điểm). LMS 3000015 Hỗ trợ học tập số: không có HP tương
  ứng trong CTĐT → không ánh xạ. GV 102 → lớp cố vấn ITK47A; lmsStudentLinks: Moodle 206/207/208 → 3 SV khác của ITK47A có điểm
  2025-2026 HK02 (chọn tự động, không in MSSV). presentationMask=false (phụ lục §7), demoMapping=true.
Phát hiện an toàn: DB_PASSWORD trong .local\backend.json (mật khẩu lms_group_app) rất ngắn → Start-LocalBackend thay mọi lần xuất
  hiện ký tự đó bằng [REDACTED] (log hỏng, lộ ký tự). Đã sửa launcher: giá trị < 6 ký tự không dùng để thay chuỗi + in cảnh báo.
  Đổi mật khẩu là việc của owner (DB chỉ nghe 127.0.0.1). Không ghi giá trị ở đâu.
Sự cố vận hành: backend P0 (PID cũ) sống sót sau khi tắt mvn cha; Get-NetTCPConnection/netstat trong sandbox không thấy cổng → các
  lần chạy sau trả lời bởi bản cũ. Đã tắt; script chạy thật giờ tắt cả java LmsMobileBackendApplication trước khi khởi động.

### V3 — Chạy thật API (dữ liệu mô phỏng) qua backend — 2026-11-09 20:31
Log D:\DLU-LMS\Artifacts\v3\backend-real-20261109-203120.log. /health portal=UP. (cold = chưa cache, cached = lần 2)
| Endpoint app | HTTP | cold ms | cached ms | Số liệu tổng hợp |
| --- | --- | ---: | ---: | --- |
| SV portal/summary | 200 | 1110 | 4 | có GPA; còn 15 TC bắt buộc; dữ liệu đến 2025-2026/HK02; GPA tự tính − GPA Portal = 0 |
| SV portal/transcript | 200 | 6 | 4 | 8 học kỳ, 64 HP |
| SV portal/program | 200 | 48 | 10 | 62 HP (gốc+CN), 97 TC bắt buộc; PASSED 40, IN_LMS 2, IN_PROGRESS 5, NOT_TAKEN 15; đủ ĐK 15, bị chặn 0 |
| SV portal/gpa-simulation | 200 | 53 | 24 | còn 27 TC, 9 HP; 2 HP có dự báo N1; có projection; bảng quy đổi 5 dòng (3 suy từ bảng điểm) |
| SV portal/conduct | 200 | 1268 | 3 | 6 học kỳ |
| SV portal/decisions | 200 | 147 | 3 | 1 quyết định, 0 cảnh báo |
| GV portal/advisor/classes/ITK47A | 200 | 1958 | 6 | 6 học kỳ có dữ liệu; 66 SV; 21 cần quan tâm |
| GV …/students/1 | 200 | 182 | 164 | lịch sử 6 học kỳ |
| sources (SV, GV) | 200 | 9/26 | 8/27 | |
Cầu nối GV: 4/66 SV có liên kết LMS (205 + 3 ánh xạ demo). Âm tính: SV xem 206 → 403; token GV trên đường SV → 403; lớp
  ITK47C (không phải lớp cố vấn) → 404; export không xác nhận → 400; export xác nhận + mask=false → 200.
Thời gian gọi Portal (log backend, mỗi lời gọi): 140–255 ms. Sửa nhỏ sau lần chạy: đếm bản ghi của object lấy mảng lớn nhất
  (CTĐT trước đó log records=0 vì groupSelection rỗng đứng trước).

### V3-P1…P8 (code + gate) — 2026-11-09 21:40
Backend (package portal): PortalModels/PortalParser (allow-list đúng bảng §1; cờ 'x'/'True'; TB_* lấy từ dòng đầu học kỳ),
  AcademicEngine (P1 GPA tự tính = lần học cuối có điểm, IsGather & !NotCompute; P2 trạng thái PASSED>FAILED>IN_LMS>IN_PROGRESS>
  NOT_TAKEN, tiên quyết "A, B;C", CTĐT gộp gốc (CQ23CT) + chuyên ngành (-PM/-MMT); P3 bảng quy đổi suy từ bảng điểm (min/max
  DiemTK_10 theo điểm chữ, chữ chưa gặp dùng mặc định A8,5/B7/C5,5/D4/F), need=(band×(C+R)−GPA×C)/R, ACHIEVED/FEASIBLE/
  NOT_FEASIBLE), StudentPortalService (summary, transcript, program, gpa-simulation [cầu nối N1: % hiện tại → hệ 10 → chữ → hệ 4],
  conduct [tuần tự ≤10 học kỳ, chỉ dòng của mình], decisions [cảnh báo học vụ]), AdvisorPortalService (P6: dò học kỳ mới nhất có
  dữ liệu, không tin đồng hồ; cờ LOW_GPA/WEAK_RANK/LOW_CONDUCT/NO_SCORE; histogram; xu hướng; ẩn danh "SV 01"+23**Z0**; chi tiết
  theo số thứ tự (không lộ MSSV khi ẩn danh); cầu nối LMS chỉ khi SV nằm trong roster khóa của GV; CSV chỉ khi confirm=true và
  mask=false, chống công thức), PortalSourcesService (P7). Controller: StudentPortalController /dev/students/{id}/portal/*,
  TeacherPortalController /dev/teachers/{id}/portal/*.
Frontend: models/portal.dart, core/gpa_simulator.dart (cùng công thức backend, mô phỏng tức thì), widgets/portal_widgets.dart
  (PortalView: loading / chưa liên kết / chưa kết nối / lỗi + Thử lại), screens/student/academic_record_screen.dart "Học vụ"
  (tab Bảng điểm [biểu đồ GPA, lọc Chưa đạt], Chương trình, Mô phỏng GPA [chọn điểm chữ "nếu tôi được…"], Rèn luyện [biểu đồ],
  Quyết định [thẻ cảnh báo → tab Mô phỏng]), screens/portal_sources_screen.dart (P7 + PortalSummaryCard đầu dashboard: GPA ·
  tín chỉ · còn thiếu X TC bắt buộc · "Dữ liệu Portal đến HKx năm …"; ẩn khi chưa liên kết/lỗi khác, chỉ hiện Thử lại khi Portal
  503), screens/teacher/advisor_class_screen.dart (P6 + AdvisorClassEntry trên trang chủ GV). ApiException có code; ApiService
  cache Portal 5 phút phía client, xóa khi signOut/demoLogin (P8). Không có ghi chú giải thích trong UI (yêu cầu owner).
Test: AcademicEngineTest 24, StudentPortalServiceTest 9 (gồm "không lộ MobilePhone/BirthDay/_Eng/SoHieuBang…"),
  AdvisorPortalServiceTest 8, PortalSecurityTest 5 (401/403 mọi đường, 404 PORTAL_NOT_LINKED, 503 mã), PortalClientTest 13,
  PortalSupportTest 7, binding 2; Flutter portal_test.dart 17. Fixture bịa (2399Z00x, ITK99Z, CQ99CT, năm 2098–2100).
Gate: Test-Backend.ps1 -Package exit 0 — 209 test, 0 fail, 1 skip. Test-Flutter.ps1 exit 0 — 246 test, analyze sạch.
  Lỗi tìm thấy nhờ test: hàng GPA tràn 25 px ở bề rộng 360 dp (đổi sang Wrap); thẻ học kỳ giữ trạng thái đóng khi lọc (thêm key);
  thẻ Portal trên dashboard chen nút "Thử lại" làm hỏng 4 test day2 + 1 ux_polish (giờ ẩn trừ khi Portal 503).
P8/E2 số đo (backend thật, dữ liệu mô phỏng, xem bảng 20:31): Portal chưa cache 140–255 ms/lời gọi; endpoint ghép nhiều lời gọi
  cold 1,1–2,0 s (summary, conduct 6 học kỳ, lớp cố vấn dò 6 học kỳ); có cache 2–27 ms.
STATUS: P0–P8 CODE DONE + gate (xem mục emulator 21:00 bên dưới).

### V3 — APK + emulator (API thật, dữ liệu mô phỏng) — 2026-11-09 20:55–21:02
APK D:\DLU-LMS\Artifacts\dlu-lms-group-v3-portal-debug.apk (164,232,487 B, SHA256 0E60650A85A1A73F5E7F203E3669CAE9DDD5CDBC096FA63B31B4A6C24ED6A3F7)
  → sửa nhãn trục biểu đồ rèn luyện ("100" bị gãy dòng: reservedSize 30 → 40) → bản dùng cuối
  D:\DLU-LMS\Artifacts\dlu-lms-group-v3-portal-r2-debug.apk (164,229,779 B, SHA256 02218653E9E8C81FBD6C9EF1935E4D8F0E14F68401C6A5DED8C39B6A6BFB24A0).
  Test-Flutter -BuildApk exit 0 cả hai lần (246 test). C trước/sau: 24,77 / 24,64 GiB.
Emulator DLU_LMS_Pixel + adb reverse 8081; backend thật (dev DB, lms_group_app, Portal UP). 19 ảnh
  D:\DLU-LMS\Artifacts\v3\screens\p1-01 … p7-02 (tên file có "du-lieu-mo-phong"; chú thích CHU-THICH.md). Kiểm trên máy:
  thẻ GPA đầu dashboard; Học vụ 5 tab; P3 dự báo từ 2 khóa LMS; P6 lớp 66 SV, 21 cần quan tâm, ẩn danh SV 01/23**A0** khóa nút
  xuất; chi tiết SV 2347A008 có tín hiệu N9 của 3 khóa GV 102; P7 trạng thái + ánh xạ demo. Ảnh GV để ẩn danh TẮT (phụ lục §7),
  có thêm 1 ảnh ẩn danh BẬT (p6-05). Log backend: mk_dev_ 0, X-API-KEY 0. Đã tắt emulator và backend.

### V3-DIAG + tài liệu — 2026-11-09 21:10
docs/diagrams/01-context, 02-components, 03-deployment, 04-seq-auth, 05-seq-gpa-simulation, 06-dataflow-bridge, 07-erd-app,
  08-usecase-student, 09-usecase-teacher, 10-activity-study-plan (theo đặc tả N6 — N6 CHƯA cài đặt, ghi rõ trong file),
  11-activity-forecast. Tên lớp/bảng/cổng lấy từ code. ERD: FK thật chỉ flashcard_reviews→flashcards, study_sessions→
  study_plan_items; còn lại tham chiếu logic. mmdc không có trên máy → chưa render docs/diagrams/out (phiên cloud render).
  Chưa kiểm cú pháp bằng trình render (NOT_RUN).
docs/FEATURES_V3.md (P0–P8, privacy by design gồm lý do không tích hợp miễn giảm học phí, công thức, ánh xạ demo, giới hạn).
docs/COMPARISON_FACTS.md (mỗi chức năng cũ/V2/V3: nguồn, màn hình, endpoint, test, lợi ích; không tự khẳng định Moodle/Portal thiếu gì).

### Tổng kết phiên 09/11 — trạng thái và bước tiếp theo
- Gate cuối: Backend 209/0/0/1 (Test-Backend.ps1 -Package exit 0); Flutter 246 pass, analyze sạch (Test-Flutter.ps1 -BuildApk exit 0).
- Chưa commit (toàn bộ thư mục vẫn untracked, nhánh codex/group-stack-takeover).
- Việc cho owner: (1) mật khẩu lms_group_app rất ngắn — nên đổi (Initialize-GroupRuntimeRole/ALTER ROLE + cập nhật backend.json);
  (2) dữ liệu demo dời ngày (lms_mobile_group_demo) chưa được dùng trong lần chạy V3 (backend đang trỏ dev).
- Tiếp theo theo thứ tự cũ (Part B §0): V2-N6 Kế hoạch học tuần → N7 → N10 → [APK + emulator hạng A gồm N5] → hạng B (N8 …).

## Phiên 10/11/2026 (Claude Code native) — tiếp tục từ checkpoint
Thứ tự owner giao: N6 → N7 → N10 → [DB demo + APK + emulator N5/N6/N7/N10 + kiểm nhanh N1–N4, N9, P1–P7] → O1 → N8 → N16 → N15 → E2 → hạng C.
Git: điểm lưu cục bộ 098ad25 (WIP N6, chưa có remote, không push). .gitignore đã loại .local/, *backup*.sql, target/, build/,
  .dart_tool/, *.apk, *.log (kiểm bằng git check-ignore); quét WIP không có key/mật khẩu. Mỗi chức năng qua gate commit một lần.
Lưu ý: Use-LocalToolchain đổi TEMP sang D:\DLU-LMS\Temp trong process — log gate chuyển hướng bằng $env:TEMP vẫn nằm ở TEMP cũ.

### V2-N6 Kế hoạch học tuần — 2026-11-10 11:45
Files: backend service/StudyPlanner.java (hàm thuần), service/StudyPlanService.java, repository/StudyPlanRepository.java
  (chỉ app.study_plan_items; replacePlanned @Transactional), controller/StudentStudyPlanController.java; test StudyPlannerTest (9),
  StudyPlanServiceTest (8), V2SecurityTest (+GET 401/403, +ghi 401/403, +404 mục người khác/200). Frontend models/study_plan.dart,
  screens/student/study_plan_screen.dart (màn Kế hoạch tuần + TodayPlanCard), services/api_service.dart (getStudyPlan,
  generateStudyPlan, setPlanItemStatus), student_dashboard_screen.dart (thẻ dưới LearningHealthHomeTile); test study_plan_test.dart (5).
API: POST /api/v1/dev/students/{id}/study-plan/generate {dailyMinutes}; GET …/study-plan?from=&to=; PUT …/study-plan/items/{id}/status
Tests: backend 228/0/0/1; flutter 251 pass; test mới: StudyPlannerTest (quá hạn trước, tách 2×45, quá tải, tuần bận, hạn hôm nay,
  hạn ngoài chân trời = hoãn, thẻ chỉ hôm nay, tạo lại giữ done, xác định + kiểm tham số), StudyPlanServiceTest, widget (chọn quỹ,
  cảnh báo quá tải, dải ngày, tick lưu/lỗi hoàn tác, thẻ dashboard).
Gate: Test-Backend -Package exit 0, JAR SHA256 22D973B6…184A5D63 (gồm lớp N7 đang viết dở, chưa test); Test-Flutter exit 0 (format 0 đổi, analyze sạch).
Runtime: NOT_RUN (chạy ở bước b trên DB demo; generate sẽ ghi app.study_plan_items của SV 205).
Còn thiếu / giới hạn: danh sách "Quá tải" chỉ trả trong phản hồi generate (GET không tính lại); ước lượng thời lượng là hằng số.

### V2-N7 Nhắc học trên điện thoại + cài đặt — 2026-11-10 12:20
Files: backend repository/NotificationPreferenceRepository.java (chỉ app.notification_preferences, upsert ON CONFLICT (user_id)),
  service/NotificationPreferenceService.java (mặc định = mặc định của bảng; PUT từng phần; kiểm kiểu + giờ 0–168),
  controller/StudentNotificationPreferenceController.java; test NotificationPreferenceServiceTest (6), V2SecurityTest (+GET 401/403,
  +PUT 401/403 SV khác/403 GV/200/400). Frontend pubspec (+flutter_local_notifications ^23.0.0, timezone ^0.11.2,
  shared_preferences ^2.5.6), android/app/build.gradle.kts (core library desugaring, desugar_jdk_libs 2.1.4), AndroidManifest
  (POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, 2 receiver của plugin; không exact alarm), core/reminder_schedule.dart (hàm thuần),
  services/reminder_service.dart (NotificationGateway/ReminderDeviceStore để test, LocalNotificationGateway dùng plugin),
  screens/student/reminder_settings_screen.dart, api_service.dart (get/putNotificationPreferences), dashboard (nút chuông AppBar),
  student_main_screen.dart (lên lịch lại khi mở app, lỗi bỏ qua); test reminder_test.dart (13).
API: GET/PUT /api/v1/dev/students/{id}/notification-preferences
Tests: backend 235/0/0/1; flutter 264 pass; test mới: hạn quá khứ bỏ qua, đổi số giờ trước hạn, thời điểm nhắc đã qua, công tắc
  quiz/assign/chung, nhắc hằng ngày theo ngày kế hoạch + thẻ, giờ đã qua → mai, giới hạn 40, service (hủy rồi lên lịch, không quyền,
  1 nguồn lỗi, PUT không chứa giờ hằng ngày), widget (công tắc lưu, tắt chung khóa các mục, "Không có hạn nộp sắp tới", gửi thử,
  lưu lỗi hoàn tác).
Gate: Test-Backend -Package exit 0, JAR SHA256 D64C1B96…8564454E; Test-Flutter exit 0 (format 1 file test, analyze sạch).
Runtime: NOT_RUN — build APK với plugin native + thông báo thật trên emulator ở bước b.
Còn thiếu / giới hạn: giờ nhắc hằng ngày chỉ lưu trên máy (không có cột trong bảng, không thêm migration); nội dung nhắc hằng ngày
  chốt lúc lên lịch (cập nhật lại mỗi lần mở app); thời điểm nhắc hạn đã qua mà hạn còn tới thì không nhắc.

### V2-N10 Phiên học tập trung (Pomodoro) + mục tiêu phút học — 2026-11-10 12:55
Files: backend repository/StudySessionRepository.java (INSERT … RETURNING id; tổng theo ngày giờ VN + khóa; tổng phút cho mục tiêu),
  service/StudySessionService.java (validate thuần, ghi, summary/summarize thuần), controller/StudentStudySessionController.java,
  service/GoalService.java (study_minutes được hỗ trợ: số nguyên 1–10.000, tiến độ từ app.study_sessions; constructor 4 tham số
  @Autowired, giữ constructor 3 tham số cho test cũ); test StudySessionServiceTest (8: bảng hợp lệ 13 trường hợp, ghi + đánh dấu
  xong, không khóa/mục, 404 không ghi, body sai, summary đủ ngày + theo khóa, mặc định 7 ngày VN, mục tiêu phút), InsightsApiTest
  (study_minutes 2,5 và 20000 bị từ chối thay cho "luôn từ chối"), V2SecurityTest (+GET summary 401/403, +POST 401/403/403/404).
  Frontend models/study_session.dart (FocusPreset, StudySummary, focusMinutes từ mốc thời gian), screens/student/focus_timer_screen.dart
  (FocusTimerScreen, FocusEntryCard, StudyMinutesChart), api_service.dart (recordStudySession, getStudySummary), learning_goal.dart
  (GoalType.studyMinutes), dashboard (thẻ dưới Kế hoạch), study_plan_screen.dart (nút đồng hồ + mục "Học tập trung"; menu đổi sang
  giá trị chuỗi vì PopupMenuButton coi null là hủy), student_analytics_screen.dart (biểu đồ 7 ngày); test focus_timer_test.dart (6).
API: POST /api/v1/dev/students/{id}/study-sessions; GET …/study-sessions/summary?from=&to=
Tests: backend 244/0/0/1; flutter 270 pass; widget dùng đồng hồ giả: nền 10 phút → hiển thị nhảy 25:00 → 15:00, hết giờ tự lưu 25 phút
  kèm planItemId + courseId của việc + markPlanItemDone, nghỉ 5 phút; dừng sớm lưu 18 phút, lỗi lưu → thử lại; <1 phút không lưu.
Gate: Test-Backend -Package exit 0, JAR SHA256 6813AD4C…AFED179C; Test-Flutter exit 0 (format 2 file, analyze sạch).
Runtime: NOT_RUN — chạy ở bước b (POST ghi app.study_sessions của SV 205 trên DB demo).
Còn thiếu / giới hạn: không có thông báo khi hết giờ lúc app ở nền (đồng hồ vẫn đúng khi mở lại; phiên được lưu khi mở lại màn);
  màn Mục tiêu dùng ô nhập số chung cho mọi loại.

### Bước b — DB demo + APK + emulator (N5, N6, N7, N10; kiểm lại N1–N4, N9, P1–P7) — 2026-11-10 12:00–12:40
Cấu hình: Set-LocalBackendDatabase.ps1 -Target demo (backend.json → lms_mobile_group_demo; giữ nguyên trạng thái này cho demo/O1);
  Use-LocalPostgres Start (pg_ctl giữ pipe → lệnh treo nhưng server chạy, pg_isready OK); Start-LocalBackend (lms_group_app).
  /health (cần token) = UP / CONNECTED / portal UP. Log D:\DLU-LMS\Artifacts\v2ackend-demo-20261110.log và …b.log: mk_dev_ 0, X-API-KEY 0.
APK: lần 1 FAIL — flutter_local_notifications 23.0.0 kéo androidx.core 1.19.0 cần compileSdk 37, AGP 9.1.0 chỉ tới 36 → ghim
  22.3.1 (cùng API Dart, compileSdk 36) — commit 076b37b. Test-Flutter -BuildApk exit 0 (270 test).
  D:\DLU-LMS\Artifacts\dlu-lms-group-v2-n6n7n10-debug.apk (186,964,723 B, SHA256 7827F4963F5C3ABB37041D616965C1E17095AD74E058AD7EBEC241899D6A2C99) → bản cuối
  D:\DLU-LMS\Artifacts\dlu-lms-group-v2-n6n7n10-r2-debug.apk (205,667,164 B, SHA256 AB9ECD8B85344698D455F1AE161E9EB39864B6BBFDDD8C793F433A30F965505C),
  Test-Flutter -BuildApk exit 0 (271 test). C trước/sau build 24,9/24,9 GiB.
Emulator DLU_LMS_Pixel (API 35), adb reverse 8081. Cài bằng `adb install -r -g` → quyền POST_NOTIFICATIONS cấp sẵn, hộp thoại xin
  quyền KHÔNG được kiểm trên máy (chỉ có trong code + test giả).
Ảnh D:\DLU-LMS\Artifacts\v2\screens\: n5-01..03, n6-01..05, n7-01..04, n10-01..06, recheck-01..02.
Kết quả thật (DB demo, SV 205):
  - N6: lập kế hoạch 60′ → 7 ngày, assign tách "phần 1/2" hôm nay + "phần 2/2" hôm sau, thẻ ôn hôm nay; tick lưu được; 30′ → thẻ
    "Quá tải: MVP3 - Bài tập 5.1 (hạn 17/11)", mục đã xong giữ nguyên.
    LỖI TÌM THẤY: tạo lại kế hoạch thêm "Ôn 1 thẻ" thứ hai cạnh mục đã tick → sửa StudyPlanService (thẻ ôn đã xong hôm nay trừ vào việc
    ôn hôm nay) + test doneFlashcardReviewTodayIsNotPlannedAgainButYesterdaysIs; gate BE 245/0/0/1 exit 0; commit 238dd7e; chạy lại trên
    máy: hết trùng (n6-05). Kế hoạch để lại ở mức 60′ cho demo.
  - N10: chọn việc kế hoạch → tự chọn khóa của việc; chạy 25′, cho app xuống nền ~77 s → mở lại 23:43 (đúng, tính từ mốc); kết thúc
    → lưu 1 phút (app.study_sessions), nghỉ 04:56. Biểu đồ "Phút học 7 ngày · 1 phút".
    LỖI TÌM THẤY: thẻ "Học tập trung" trên dashboard không cập nhật khi phiên lưu từ màn Kế hoạch → ApiService.studyDataVersion
    (ValueNotifier) báo sau mọi ghi kế hoạch/phiên; 2 thẻ dashboard nghe và tải lại; test mới; lần chạy gate đầu FAIL vì
    setState(() => _future = …) trả Future (test bắt được) → sửa → Test-Flutter exit 0 (271); commit a6535d8; trên máy r2: "Hôm nay 1 phút".
  - N7: "Sắp nhắc" liệt kê 5 hạn thật (16/11–20/11, trước 24 giờ); dumpsys alarm có alarm của app; "Gửi thử" → thông báo thật trên
    thanh thông báo (n7-02); đặt giờ nhắc hằng ngày 12:32, đóng app → 12:34:02 thông báo "Hôm nay học gì? Cần ôn 1 thẻ · 1 việc trong
    kế hoạch (45 phút)" tự hiện (inexact, trễ ~2 phút) (n7-04). Giờ nhắc hằng ngày trên emulator hiện là 12:32 (đổi lại 19:00 trước demo nếu muốn).
    Ghi nhận: hộp chọn giờ hiện tiêu đề tiếng Anh "Select time"/"Enter time" (localization hệ thống), chưa sửa.
  - N5: chip "Hôm nay cần ôn 1 thẻ" → phiên ôn → lật → 4 nút "1 ngày" (thẻ mới, đúng SM-2) → "Được" → tổng kết; API due total 0 sau đó.
    Nội dung thẻ là dữ liệu có sẵn trong dump.
  - Kiểm lại (API, token thật, DB demo): N1 grade-forecast 13/14, N9 learning-health, N2 study-recommendations, N3 peer-comparison,
    N4 GV grade-forecast, P1–P7 (summary, transcript, program, gpa-simulation, conduct, decisions, sources, advisor ITK47A) đều 200
    (19–193 ms; Portal chưa cache 0,97–2,5 s); SV gọi SV 206 → 403; token GV gọi đường SV → 403. UI: dashboard SV (thẻ GPA P1, N9 Đỏ),
    N3 ẩn danh với lớp 4 SV, trang chủ GV ("5 hoạt động sắp đến hạn trong 7 ngày tới" nhờ dời ngày), P6 lớp ITK47A 66 SV / 21 cần quan tâm.
  Ghi vào DB demo trong lượt này (schema app, SV 205): app.study_plan_items (kế hoạch), app.study_sessions (1 phiên 1 phút),
  app.flashcard_reviews (1 thẻ), app.notification_preferences (1 dòng: bật hết, 24 giờ). Không ghi lms.
Ổ C: 25 → 20 GiB sau ~40 phút emulator (pagefile) → đã tắt emulator (adb emu kill). Backend + postgres vẫn chạy.
Video: NOT_RUN.
STATUS: bước b DONE. Tiếp theo: O1 Start-Demo.ps1 / Stop-Demo.ps1.

### V2-O1 Start-Demo.ps1 / Stop-Demo.ps1 — 2026-11-10 12:45–13:00
Files: tools/Start-Demo.ps1 (mới), tools/Stop-Demo.ps1 (mới), docs/LOCAL_RUNBOOK.md (mục "Ngày bảo vệ": cách chạy, checklist 10 dòng,
  bảng 5 sự cố: cổng bận, emulator treo, mất adb reverse, backend 401, ổ C đầy).
Start-Demo: -Database demo (mặc định)|dev, -Avd, -Apk, -NoEmulator. 0 kiểm tra (Set-LocalBackendDatabase; Portal bật? chỉ đọc cờ
  enabled, không in giá trị) → 1 PostgreSQL trong cửa sổ riêng (Start-Process pwsh -NoExit) → 2 pg_isready ≤60 s → 3 Start-LocalBackend
  trong cửa sổ riêng → 4 demo-login + /health = UP ≤180 s (in database/portal) → 5 emulator trong cửa sổ riêng (C ≥15 GiB, cảnh báo <22)
  → 6 sys.boot_completed ≤240 s → 7 adb reverse 8081 → 8 cài APK mới nhất nếu chưa có app, mở app. Bước nào đã chạy thì dùng lại; lỗi thì
  dừng và in "Cách xử lý". PID cửa sổ lưu ở .local\demo-pids.json (git-ignored).
Stop-Demo: emulator (adb reverse --remove-all, emu kill) → Java của backend (Maven + app) → pg_ctl stop -m fast (trừ -KeepPostgres)
  → đóng các cửa sổ đã ghi PID (chỉ khi tiến trình vẫn là pwsh/powershell).
Kiểm (Claude, 13:00): parse 0 lỗi cả hai. Stop-Demo khi đang chạy backend+pg của phiên: tắt 2 Java + pg. Start-Demo đầy đủ: 8/8 OK —
  "status UP, database CONNECTED, portal UP", boot_completed, reverse, mở app (ảnh o1-01 = splash Flutter). Stop-Demo: tắt emulator,
  2 Java, pg (pg_isready: no response), đóng 3 cửa sổ.
!! Ổ C: trước emulator 21,3 GiB → sau khi boot 15,5 GiB (−6 GiB pagefile) → sau Stop-Demo 20,8 GiB. Ngày bảo vệ cần C ≥ 22 GiB trước
  khi chạy (ghi trong checklist), hoặc owner chuyển pagefile sang D (cần quyền admin).
Owner test sau khi đóng phiên Claude: NOT_RUN (việc của owner theo Part B §O1 — chạy .\tools\Start-Demo.ps1 từ PowerShell của mình).
STATUS: O1 DONE (Claude kiểm thật một vòng). Tiếp theo: hạng B N8 (Nhắc riêng 1 SV + CSV).

### V2-N8 Nhắc riêng 1 SV + xuất CSV — 2026-11-10 13:40
Files: backend service/TeacherReminderService.java (SV ngoài lớp → ResourceNotFoundException 404 thay cho 400; vẫn không ghi gì);
  test InsightsApiTest (+remindOneStudentOfTheClass; ngoài lớp → 404 kể cả danh sách chỉ 1 SV). Frontend core/reminder_templates.dart
  (hàm thuần, mẫu chỉ khi có dữ kiện), core/support_csv.dart (RFC 4180 + BOM + chặn công thức), screens/teacher/remind_one.dart
  (factsFromInsight/factsFromMonitored, remindOne, supportRows, exportSupportList với share có thể thay khi test),
  teacher_analytics_widgets.dart (composer: recipients theo tên, chip mẫu, tiêu đề "Nhắc riêng <tên>"), teacher_analytics_screen.dart
  (nút "Xuất danh sách cần hỗ trợ", N4 onRemindOne nối vào remindOne), teacher_monitoring_screens.dart (nút "Nhắc riêng" ở chi tiết SV),
  api_service.dart (getCourseNotes), pubspec (+share_plus 13.3.1: androidx.core-ktx 1.16.0, compileSdk theo Flutter → hợp với AGP 9.1.0);
  test remind_one_test.dart (6).
API: không thêm endpoint; dùng POST …/teachers/{id}/courses/{c}/reminders với 1 student_id; GET /teachers/{id}/notes?courseId=.
Tests: backend 246/0/0/1; flutter 277 pass; test mới: mẫu có số thật (4 bài quá hạn → 3 tên + "và 1 bài khác", 30 ngày, 42,3%), SV ổn chỉ
  mẫu chung, CSV (dấu phẩy, ngoặc kép, xuống dòng, =SUM, BOM, tiếng Việt), hàng CSV (chỉ nhóm cần hỗ trợ/theo dõi, sắp theo điểm, ghi chú
  mới nhất, dự báo), xuất khi dự báo/ghi chú lỗi, widget nhắc riêng (1 người nhận, đổi mẫu, gửi [3]).
Gate: Test-Backend -Package exit 0, JAR SHA256 220624D1…11AA5DC5; Test-Flutter exit 0 ở lần 3 (lần 1, 2: analyze — const constructor đọc
  List.length; lint prefer_initializing_formals → đổi sang trường overdueTotal + getter).
Runtime: NOT_RUN (emulator gộp cuối hạng B; gửi nhắc sẽ ghi app.notifications + app.teacher_notes trên DB demo).
Còn thiếu / giới hạn: ngưỡng điểm thấp dùng 50% chung (không lấy gradepass riêng từng khóa); tên file CSV theo mã khóa.

### V2-N16 Phân tích bài kiểm tra (GV) — 2026-11-10 14:10
Files: backend repository/QuizInsightsRepository.java (quiz của khóa GV + link Moodle theo course_modules; lượt cuối mỗi SV ghi danh,
  % = sumgrades/quiz.sumgrades), service/QuizInsightsService.java (analyze thuần; insights chỉ tính SV trong roster),
  controller/TeacherQuizInsightsController.java; test QuizInsightsServiceTest (8: không có lượt, biên histogram, Quá khó cần ≥3,
  bỏ 40%, quá nhanh chỉ khi có timelimit + trung vị chẵn/lẻ, lượt chưa chấm, roster + id ngoài roster bị bỏ, 404), V2SecurityTest
  (+quiz-insights vào TEACHER_PATHS 401/403/403, +404/200). Frontend models/quiz_insights.dart, screens/teacher/quiz_insights_section.dart,
  api_service.dart (getQuizInsights), teacher_analytics_screen.dart (mục mới trước "Bài tập và hoạt động"); test quiz_insights_test.dart (3);
  course_navigation_test.dart (thêm 'quiz-insights' vào danh sách request được phép của tab Phân tích).
  Sửa kèm: setState(() => _future = _load()) trả Future (assert ở debug khi bấm "Thử lại") trong grade_forecast_screen.dart và
  class_forecast_section.dart (code V2 cũ) → thân khối.
API: GET /api/v1/dev/teachers/{id}/courses/{c}/quiz-insights
Tests: backend 255/0/0/1; flutter 280 pass.
Gate: Test-Backend -Package exit 0, JAR SHA256 746EB580…6413FC31; Test-Flutter exit 0 ở lần 2 (lần 1: course_navigation_test chặn request mới quiz-insights).
Runtime: NOT_RUN (gộp cuối hạng B).
Còn thiếu / giới hạn: điểm % theo lượt cuối (không theo cách tính điểm của quiz như cao nhất/trung bình); quiz không có sumgrades → không có điểm.

### V2-N15 Bản đồ nhiệt tương tác (đối chiếu ActivityHeatmapSection) — 2026-11-10 14:35
Đối chiếu: ActivityHeatmapSection + ClassInsightsService.activityHeatmap đã có ma trận SV × tuần (logstore, chỉ roster), xếp ngừng học /
  chưa vào học / im lặng lâu nhất lên đầu, bấm hàng mở chi tiết → KHÔNG làm lại. Thiếu so với N15: 4 mức màu, endpoint riêng.
Files: backend ClassInsightsService (engagementHeatmap dùng chung activityHeatmap + levels; heatLevel thuần), TeacherInsightsController
  (GET …/engagement-heatmap?weeks=8); test InsightsApiTest (+endpoint: khớp dữ liệu, levels 6/9→3, 4/9→2, 9/9→4, tuần ngoài cửa sổ bị bỏ,
  khóa khác 404, weeks=0 → 400), HeatLevelTest (biên phần tư). Frontend teacher_analytics_sections.dart (heatLevel thuần + màu 4 mức +
  chú thích + dòng "Cách tính"); test heatmap_levels_test.dart.
API: GET /api/v1/dev/teachers/{id}/courses/{c}/engagement-heatmap?weeks=
Tests: backend 257/0/0/1; flutter 281 pass.
Gate: Test-Backend -Package exit 0, JAR SHA256 FD254B3D…022E5AA5; Test-Flutter exit 0 ở lần 2 (lần 1 analyze: const [0, .25…] là List<num>).
Runtime: NOT_RUN (gộp cuối hạng B).
Còn thiếu / giới hạn: không cộng course_modules_completion (tránh đếm trùng với log); app vẫn đọc heatmap từ class-insights (endpoint riêng cho E2/tích hợp).

### V2-E2 Đo hiệu năng API + kiểm thật hạng B qua API — 2026-11-10 15:05
Files: tools/Measure-Api.ps1 (mới; parse 0 lỗi). Chạy: Start-Demo.ps1 -NoEmulator (DB demo, Portal UP) → Measure-Api.ps1 → Stop-Demo.ps1.
Kết quả: D:\DLU-LMS\Artifacts\v2\perf-20261110-130614.csv + perf-20261110-130614-machine.txt. 12 endpoint × (10 khởi động + 200 đo):
  p50 1,8–13,9 ms, p95 3,1–28,7 ms, max ≤ 43,5 ms, 0 lỗi; không endpoint nào p95 > 500 ms. Bảng đầy đủ + số Portal V3 trong FEATURES_V2 §E2.
Kiểm thật hạng B (API, DB demo, token thật): N16 quiz-insights khóa 13/14 (roster 4: không cờ — TB 36,5% nhưng chỉ 2 lượt < 3) và khóa
  3000015 (roster 15: Quiz 1 TB 30,5%, 6 chưa làm → Quá khó + Nhiều SV bỏ; Quiz 2 9 chưa làm → Nhiều SV bỏ); courseModuleId có đủ.
  N15 engagement-heatmap khóa 14: 8 tuần, 4 hàng, max 11, mức dùng 0/1/2/4. N8: nhắc id ngoài lớp → 404 (không ghi). SV gọi quiz-insights
  của GV → 403; khóa không thuộc GV → 404. Không có thao tác ghi nào trong lượt này.
STATUS: hạng B (N8, N16, N15, E2) DONE ở mức gate + API thật. UI emulator hạng B (n8/n15/n16 ảnh): NOT_RUN — xem bước tiếp theo.

### Hạng B — APK + emulator (DB demo, Start-Demo) — 2026-11-10 15:10–15:20
APK D:\DLU-LMS\Artifacts\dlu-lms-group-v2-hangB-debug.apk (211,395,702 B, SHA256 1E6450208AF9E955566A2AE9B220768B9DD271CB43E3C08719BD35B77EEB9978),
  Test-Flutter -BuildApk exit 0 (281). Chạy bằng tools\Start-Demo.ps1 (8/8 OK lần 2) + adb install -r; tắt bằng Stop-Demo.ps1.
Ảnh D:\DLU-LMS\Artifacts\v2\screens\: n8-01..05, n15-01, n16-01..03. Kết quả thật (GV 102, khóa 3000015 "Hỗ trợ học tập số", 15 SV):
  - N8: nút "Xuất danh sách cần hỗ trợ" → share sheet Android với can-ho-tro-khoa-3000015-20261110.csv (không gửi đi đâu);
    chi tiết SV → "Nhắc riêng" → composer "Nhắc riêng <tên>" chỉ có mẫu "Lâu không truy cập" (11 ngày, số thật) + "Chung"
    (không quá hạn, chưa có điểm → không có mẫu tương ứng); GỬI THẬT 1 nhắc → API thông báo của SV 205 có đúng 1 nhắc mới
    (ghi app.notifications + app.teacher_notes trên DB demo). N4 hiện "Nhắc riêng" cho SV chưa chắc qua (n8-05).
  - N16: Quiz 5.1 "Quá khó" + "Nhiều sinh viên bỏ" (TB 30,5%, đã làm 6/15, chưa làm 6 = 40%, trung vị 60 phút); Quiz 5.2 "Nhiều sinh viên
    bỏ" (9/15); "Nhắc 6 SV chưa làm" mở composer với lời nhắc theo quiz (đã Hủy, không gửi).
  - N15: "Lịch sử vào học theo tuần" 4 mức, SV chưa vào học lên đầu.
  Sửa sau lượt này: chip mẫu đang dùng chưa được đánh dấu khi mở composer → chọn sẵn + assert trong test; Test-Flutter exit 0 (281).
Ghi nhận (chưa sửa): (1) DB demo dời ngày theo mốc 20/11 nên hôm nay (10/11) một số log nằm ở tương lai → danh sách SV hiện
  "Hoạt động gần nhất: -6 ngày trước"; đúng lại từ ~16–20/11. (2) Nhãn trục Y biểu đồ "Xu hướng học tập theo tuần" (104.4) bị xuống dòng
  (biểu đồ có từ trước V2). (3) Hộp chọn giờ N7 có tiêu đề tiếng Anh.
Ổ C: 21,1 → 15,6 GiB khi emulator chạy (sát ngưỡng 15) → 21,1 GiB sau Stop-Demo.
STATUS: hạng B DONE (gate + API + emulator). Video: NOT_RUN. Tiếp theo: hạng C theo thứ tự Part B (N11 → N12 → N13 → N14 → N17 → N18).

### V2-N11 Xem khi mất mạng — 2026-11-10 15:45
Files: frontend services/offline_cache.dart (OfflineStore, SharedPrefsOfflineStore, MemoryOfflineStore, isOfflineCacheable),
  services/api_service.dart (offlineStore + offlineSince; GET được phép → lưu; ClientException/Timeout → bản lưu (đọc tối đa 2 s);
  ghi khi offline → ApiException offlineWriteMessage; xóa khi demoLogin/signOut), widgets/offline_banner.dart, student_main_screen.dart
  (banner đầu màn); test offline_cache_test.dart (5: danh sách đường dẫn, lỗi mạng → bản lưu + khóa ghi + trở lại online, không bản lưu,
  đổi vai trò/đăng xuất xóa sạch, banner).
Tests: flutter 286 pass; backend không đổi (257/0/0/1).
Gate: Test-Flutter exit 0 ở lần 2 (lần 1: 3 test day2 "Home isolates … failure" treo vì SharedPreferences chưa mock trong test không bao giờ
  trả về → thêm timeout 2 s khi đọc bản lưu; đây cũng là bảo vệ cho máy thật).
Runtime: NOT_RUN (cần thử trên emulator bằng cách tắt mạng/backend).
Còn thiếu / giới hạn: chỉ phía SV; dữ liệu lưu không hết hạn (bị thay khi tải lại thành công, xóa khi đổi vai trò/đăng xuất).

### V2-N12 Lịch tổng hợp + xuất .ics — 2026-11-10 16:15
Files: backend service/StudentCalendarService.java (assemble thuần + calendar), controller/StudentCalendarController.java; test
  StudentCalendarServiceTest (2: gộp 3 nguồn trong khoảng, biên tháng, bỏ skipped/không hạn, uid ổn định, giờ kết thúc buổi học; mặc định
  tháng hiện tại + kiểm khoảng), V2SecurityTest (+calendar vào STUDENT_PATHS 401/403). Frontend core/ics.dart, models/calendar_event.dart,
  screens/student/calendar_screen.dart, api_service.dart (getCalendar), dashboard (nút lịch trên AppBar); test calendar_ics_test.dart (3).
API: GET /api/v1/dev/students/{id}/calendar?from=&to=
Tests: backend 259/0/0/1; flutter 289 pass.
Gate: Test-Backend -Package exit 0, JAR SHA256 58B2891E…CABF6F4A; Test-Flutter exit 0 ở lần 2 (lần 1: danh sách ngày nằm ngoài khung test 800×600 → test đặt màn 1080×2400).
Runtime: NOT_RUN.
Còn thiếu / giới hạn: chỉ lịch tháng (không có chế độ tuần riêng — danh sách theo ngày thay thế); không có lịch lặp (mỗi buổi điểm danh là 1 sự kiện).

### V2-N13 Tìm kiếm nhanh — 2026-11-10 16:45
Files: backend service/SearchService.java (fold + rank thuần; student/teacher dùng repository sẵn có theo id người gọi),
  controller/SearchController.java; test SearchServiceTest (6: bỏ dấu, độ dài q, mọi từ + xếp hạng + nhóm + trần 20 + trùng,
  SQL injection không khớp gì và repository chỉ nhận id, SV tìm đủ 4 loại, GV tìm SV theo tên không dấu/MSSV), V2SecurityTest
  (+search SV/GV vào STUDENT_PATHS/TEACHER_PATHS 401/403). Frontend models/search_hit.dart, screens/search_screen.dart,
  api_service.dart (search), nút kính lúp ở dashboard SV và trang chủ GV; test search_test.dart.
API: GET /api/v1/dev/students/{id}/search?q=, GET /api/v1/dev/teachers/{id}/search?q=
Tests: backend 265/0/0/1; flutter 290 pass.
Gate: Test-Backend -Package exit 0, JAR SHA256 BBE69BB0…F1EB689A; Test-Flutter exit 0 (lần 1).
Runtime: NOT_RUN.
Còn thiếu / giới hạn: tìm trong bộ nhớ trên dữ liệu đã giới hạn theo người gọi (dữ liệu demo nhỏ; với dữ liệu lớn nên chuyển sang unaccent + chỉ mục).

### V2-N14 "Tuần của bạn" — 2026-11-10 17:15
Files: backend service/WeeklyReportService.java (summarize thuần; tuần T2–CN giờ VN; dùng streak của InsightsService),
  repository/FlashcardReviewRepository.java (+countReviewedBetween), controller/StudentWeeklyReportController.java; test
  WeeklyReportServiceTest (3: ẩn dòng không dữ liệu, dòng kế hoạch x/y kể cả khi chỉ tuần trước có kế hoạch, ranh giới tuần + streak +
  bỏ skipped + không tính tuần sau), V2SecurityTest (+weekly-report 401/403). Frontend models/weekly_report.dart,
  screens/student/weekly_report_card.dart (thẻ + chia sẻ PNG), api_service.dart (getWeeklyReport), student_analytics_screen.dart (thẻ đầu
  màn); test weekly_report_test.dart (2: dòng thật + mũi tên + streak + PNG thật qua toImage; rỗng/lỗi → ẩn).
API: GET /api/v1/dev/students/{id}/weekly-report[?week=]
Tests: backend 268/0/0/1; flutter 292 pass.
Gate: Test-Backend -Package exit 0, JAR SHA256 FDB94970…C325C164; Test-Flutter exit 0 ở lần 2 (lần 1: test dùng bySemanticsLabel khi semantics tắt → đổi sang byIcon).
Runtime: NOT_RUN.
Còn thiếu / giới hạn: không có "điểm mới nhận" (không có mốc thời gian điểm); thẻ ôn chỉ tính lần ôn gần nhất.

### V2-N17 Thành tích — 2026-11-10 17:45
Files: backend repository/AchievementRepository.java (bài nộp + hạn; ngày ôn gần nhất), service/AchievementService.java (onTime,
  reviewStreak, planWeek, minutes thuần; goal/no_red theo trạng thái), controller/StudentAchievementController.java; test
  AchievementServiceTest (5), V2SecurityTest (+achievements 401/403). Frontend models/achievement.dart, screens/student/achievements_screen.dart
  (màn + AchievementsEntry), api_service.dart (getAchievements), student_analytics_screen.dart (thẻ dưới "Tuần của bạn"); test achievements_test.dart (2).
API: GET /api/v1/dev/students/{id}/achievements
Tests: backend 273/0/0/1; flutter 294 pass.
Gate: Test-Backend -Package exit 0, JAR SHA256 500A2C59…F658E6C6; Test-Flutter exit 0 (lần 1).
Runtime: NOT_RUN.
Khác đặc tả (trung thực): "hết Đỏ ở một khóa" → "Không còn khóa Đỏ" (trạng thái hiện tại; không có lịch sử N9); "ôn thẻ 7 ngày" là cận dưới
  (chỉ lưu lần ôn gần nhất); "đạt một mục tiêu" không có ngày đạt. Ghi rõ trong FEATURES_V2 §N17.

### V2-N18 Đánh bóng giao diện — 2026-11-10 18:15
Files: frontend core/app_settings.dart (theme mode + cờ giới thiệu; load có timeout 2 s), core/theme/app_theme.dart (+darkTheme), main.dart
  (load trước runApp; MaterialApp theo themeMode), screens/onboarding_screen.dart, role_selection_screen.dart (giới thiệu 1 lần sau khi chọn
  vai trò; ThemeModeMenu ở cả 2 nhánh), core/vietnamese_localizations.dart (chữ bộ chọn giờ), student_goals_screen.dart (tooltip nút xóa ngày),
  study_plan_screen.dart (dải ngày cao theo cỡ chữ); test/flutter_test_config.dart (tắt giới thiệu cho mọi test), test polish_n18_test.dart (5:
  1.3 × 5 màn × sáng/tối, darkTheme, menu đổi giao diện toàn app, giới thiệu 3 bước, bộ chọn giờ tiếng Việt).
Tests: flutter 299 pass; backend không đổi (273/0/0/1).
Gate: Test-Flutter exit 0 ở lần 2 (lần 1: tràn 15 px dải ngày Kế hoạch tuần ở 1.3 — lỗi thật, đã sửa; menu giao diện chưa có ở nhánh
  "chưa cấu hình" mà test LMSApp dùng — đã thêm).
Runtime: NOT_RUN.
Còn thiếu / giới hạn: màn cũ còn một số màu xám cứng (Colors.grey.*) — đọc được ở chế độ tối nhưng chưa tối ưu; chưa có công tắc giao diện trong app sau khi vào vai trò (chỉ ở màn chọn vai trò).

### Hạng C — APK + emulator (DB demo, Start-Demo) — 2026-11-10 16:54–17:05
APK cuối: D:\DLU-LMS\Artifacts\dlu-lms-group-v2-hangC-r3-debug.apk (211,450,873 B, SHA256
  10FA1DD276D12F9A9256065F6437D8F6187A7BF3A2DE85BAFDEBE087FBC20528); Test-Flutter -BuildApk exit 0 (300). Các bản trước trong lượt:
  hangC (0E5F4A01…), hangC-r2 (E591DBBE…) — đã thay.
Ảnh D:\DLU-LMS\Artifacts\v2\screens\: n18-01 (giới thiệu bước 1, hiện đúng 1 lần sau khi chọn vai trò), n8-06 (SV 205 thấy banner nhắc riêng
  của GV gửi lúc 15:16 — xác nhận N8 đầu-cuối), n13-01 ("ho tro hoc" không dấu → khóa "Hỗ trợ học tập số" + 4 việc kèm Mở trên LMS),
  n12-01..02 (lịch tháng 11: hạn nộp đến 25/11, kế hoạch, điểm danh hằng ngày; lich-hoc-2026-11.ics ra share sheet), n14-01 ("Tuần của bạn":
  1/7 kế hoạch, 1 phút, 1 thẻ, 5 hoạt động, 3 ngày, chuỗi 5 ngày, so với tuần trước), n17-01 (1/6 huy hiệu, tiến độ thật), n11-01 (tắt
  backend → dashboard từ bản lưu + "Đang ngoại tuyến · dữ liệu lúc 17:00 10/11"), n18-02 (chế độ tối).
Lỗi tìm thấy trên máy và đã sửa (gate FE 300, exit 0): (1) N11 — nội dung dưới banner vẫn cộng khoảng status bar → bỏ padding trên khi
  ngoại tuyến + test; (2) N18 — màn chọn vai trò dùng màu chữ cứng #1E293B/grey → gần như không đọc được ở chế độ tối → dùng màu theme.
Ghi nhận khi thử: tắt backend chỉ ~7 s sau đăng nhập thì dashboard chưa kịp lưu → hiện lỗi thường (đúng thiết kế: đổi vai trò xóa bản lưu;
  ngoại tuyến chỉ áp dụng trong phiên đã tải). Thiết bị đã đặt lại giao diện "Theo hệ thống". C: 21,5 GiB suốt lượt (pagefile không tăng thêm).
Đã tắt bằng Stop-Demo.ps1 (emulator, PostgreSQL, 3 cửa sổ).

## TỔNG KẾT PHIÊN 10/11/2026 — trạng thái và bước tiếp theo
- Xong (gate + chạy thật): N6, N7, N10 (bước a); DB demo + APK + emulator N5/N6/N7/N10 + kiểm lại N1–N4, N9, P1–P7 (bước b); O1
  Start/Stop-Demo (bước c); hạng B N8, N16, N15, E2 (bước d); hạng C N11, N12, N13, N14, N17, N18 (bước e). TASK_BOARD đủ N1–N18, O1, E2.
- Gate cuối: Backend 273 test / 0 fail / 0 error / 1 skip (Test-Backend -Package exit 0); Flutter 300 test, analyze sạch (Test-Flutter
  -BuildApk exit 0). Git cục bộ nhánh codex/group-stack-takeover, mỗi chức năng 1 commit, không remote, không push.
- Lỗi thật tìm thấy nhờ chạy trên máy/test và đã sửa: trùng thẻ ôn khi lập lại kế hoạch (N6); thẻ dashboard không cập nhật (N10);
  setState trả Future (3 chỗ, gồm code V2 cũ); flutter_local_notifications 23 cần compileSdk 37 (ghim 22.3.1); dải ngày tràn ở cỡ chữ 1.3;
  khoảng trống dưới banner ngoại tuyến; màu chữ cứng ở chế độ tối.
- Khác đặc tả (ghi trong FEATURES_V2): N17 "hết Đỏ" → "không còn khóa Đỏ"; N14 không có "điểm mới nhận"; N7 giờ nhắc hằng ngày lưu trên máy;
  N15 giữ ActivityHeatmapSection, chỉ thêm 4 mức + endpoint.
- Việc cho owner (cần người):
  1. Chạy .\tools\Start-Demo.ps1 từ PowerShell của mình SAU KHI đóng Claude (Part B §O1), rồi Stop-Demo.ps1; ghi kết quả.
  2. Ổ C ≥ 22 GiB trước buổi bảo vệ (emulator có lúc làm pagefile tăng ~6 GiB); chuyển pagefile sang D cần quyền admin — tùy owner.
  3. Mật khẩu lms_group_app rất ngắn (ghi từ 09/11) — nên đổi.
- NOT_RUN: video screenrecord các hạng; hộp thoại xin quyền thông báo Android 13+ (cài bằng -g); docs/diagrams chưa render SVG;
  10-activity-study-plan.mmd viết khi N6 chưa có — nên đối chiếu lại với StudyPlanner hiện tại.
- Gợi ý nếu còn thời gian: quay video demo; chạy Measure-Api lại trên máy bảo vệ; rà màu cứng ở các màn cũ cho chế độ tối.

### FINAL-F2 Giảm rủi ro ngày demo — 2026-11-10 19:00–19:40
Files: frontend core/relative_days.dart (mới), core/theme/app_colors.dart (mới), widgets/chart_axis.dart (mới), models/teacher_monitoring.dart,
  screens/teacher/{teacher_analytics_widgets,student_overview_details}.dart ("-6 ngày trước" → "sau hôm nay 6 ngày", không abs());
  services/reminder_service.dart (isPermitted/openSettings; chỉ xin quyền khi bật nhắc hoặc Gửi thử; khởi động app không xin),
  screens/student/reminder_settings_screen.dart (nút "Mở cài đặt thông báo", tự cập nhật khi quay lại app, ẩn snackbar cũ),
  android MainActivity.kt (kênh dlu.lms/settings → ACTION_APP_NOTIFICATION_SETTINGS); 16 màn cũ đổi Colors.grey/black87/#1E293B/shade50
  sang màu theme (context.muted/strong/subtle/hairline/tint); trục Y "Xu hướng học tập theo tuần" và biểu đồ tuần SV dùng
  countAxisTitles (số nguyên, 1 dòng, rộng theo cỡ chữ); calendar_screen.dart thêm chế độ Tuần (T2–CN, qua tháng/năm, xuất
  lich-hoc-tuan-YYYY-MM-DD.ics) và ô ngày không tràn ở 320 dp × 1.3; api_service.dart: khóa cache N11 = địa chỉ API + path,
  phản hồi về sau khi đăng xuất/đổi vai trò không ghi cache và không bật chế độ ngoại tuyến.
  tools/Start-Demo.ps1: -PhysicalDevice (chờ máy USB, adb -s serial, adb reverse, cài APK cuối nếu SHA-256 khác lần cài trước),
  bước 0 dừng nếu C < 15 / cảnh báo < 22, Tóm tắt (DB, Portal UP/DOWN/TẮT, thiết bị, C); BOM UTF-8 cho Start/Stop-Demo (PowerShell 5).
  docs/LOCAL_RUNBOOK.md (mục USB), COMPARISON_FACTS.md (trạng thái + hàng N6–N18), đầu HANDOFF (hiện trạng; phần cũ giữ làm lịch sử).
Tests mới: relative_days_test (quá khứ/hôm nay/tương lai), reminder_test nhóm "Android 13 permission" (3), calendar_ics_test (tuần,
  biên tháng/năm, tuần rỗng), search_test (phản hồi cũ bị bỏ, bấm kết quả mở đúng khóa), offline_cache_test nhóm isolation (401/403
  không bị cache che, môi trường khác không đọc, phản hồi muộn sau đăng xuất, khởi động lại), final_f2_test (trục, màu tint),
  polish_n18_test chạy 320/360/390 dp; SearchServiceTest đ/Đ + dấu tổ hợp ("dao" = "Đào").
  Test 320 dp tìm ra lỗi thật: ô ngày lịch tháng tràn 12–20 px ở cỡ chữ 1.3 → đã sửa.
N14/N17: đã có test phân biệt "không dữ liệu" với 0 (rowsWithoutDataInEitherWeekAreHiddenNotZero), tuần T2–CN theo giờ VN,
  chuỗi ngày đếm ngày phân biệt — không đổi code. Hộp chọn giờ tiếng Việt: đã có từ N18 (test "time picker speaks Vietnamese").
Gate (source = WIP F2 trên 62fca3e): Test-Backend -Package exit 0 — 274/0/0/1 skip; Test-Flutter -BuildApk exit 0 — 316 pass, analyze sạch.
  Sau gate có 1 sửa nhỏ (ẩn snackbar khi đã cấp quyền) + reminder_test 16/16 pass; gate tổng chạy lại ở F3.
APK F2: D:\DLU-LMS\Artifacts\dlu-lms-group-final-f2-debug.apk SHA256 A3D824F7CB77668343B3AB37139073D16B5BF24D548860BEF20BD808DA7D05C0.
Runtime (emulator, DB demo, Portal UP, Start-Demo bản mới in Tóm tắt đúng): ảnh D:\DLU-LMS\Artifacts\final\screens\
  f2-00 trang chủ (mở app KHÔNG hiện hộp thoại quyền), f2-01 Cài đặt nhắc khi chưa có quyền (nút Mở cài đặt), f2-02 hộp thoại hệ thống
  "Allow … to send you notifications?" khi bấm Gửi thử, f2-03 từ chối → snackbar "Mở cài đặt", f2-04 trang cài đặt thông báo của app,
  f2-05 bật quyền rồi quay lại → danh sách Sắp nhắc tự hiện, f2-06 "Thông báo thử" trên thanh thông báo, f2-07 lịch tháng 11.
Sự cố khi chạy: PostgreSQL và emulator mở từ shell của Claude bị dừng lúc 19:24 (postgres: "terminated by exception 0xC000013A" =
  Ctrl+C/đóng console) khi phiên Claude chạy lệnh khác → app quay vòng, API 500 sau 30 s. Chạy lại Start-Demo như tiến trình tách rời
  (Start-Process) thì các bước tự nối lại. Owner chạy từ PowerShell của mình không bị ảnh hưởng; Claude từ nay luôn chạy Start-Demo tách rời.
PARTIAL: ảnh lịch tuần, chế độ tối 5 màn, nhãn "sau hôm nay" ở danh sách SV của GV → chụp trong phiên emulator của F3.
  -PhysicalDevice: parse PS5/PS7 OK, chạy nhánh emulator OK; nhánh máy thật NOT_RUN (không có điện thoại cắm USB).

### FINAL-F4 Tài liệu cho nhóm — 2026-11-10 (commit 37c4117)
docs/DEMO_SCRIPT.md: 17 bước (SV 205 trước: GPA Portal → CTĐT → Mô phỏng GPA dùng N1 → N9 → N6 → N5 → N1 → N12 tuần → N7 → N13;
  GV 102: P6 ẩn danh → P6+N9 → N4 → N16 → N8 không bấm Gửi), mỗi bước có Bấm/Mã/Nói; nhánh dự phòng Portal DOWN, emulator treo,
  mất kết nối, 401, ngày khác 20/11; 8 câu hội đồng trả lời theo code thật (JWT HMAC-256 ≤ 24 h, PathIdentity 403, SM-2, công thức
  GPA dự kiến/need, Nghị định 13/2023 cho miễn giảm học phí, số test, triển khai thật). docs/USER_GUIDE.md: SV 13 mục, GV 6 mục, mỗi
  mục mục đích + 2–4 bước + tên ảnh thật trong v2/v3/final. Đi thử kịch bản trên emulator: làm ở F3.

### FINAL-F1 Sơ đồ khớp code — 2026-11-10
Đổi: docs/diagrams/02-components.mmd (thêm controller/service/repository N6–N18, ReminderService, OfflineStore N11),
  08-usecase-student.mmd (N6, N7, N10–N14, N17 vào nhóm "Dữ liệu riêng"/"Từ LMS"; N11, N18 nhóm "Trên máy"; giữ cách nhóm theo
  nguồn), 09-usecase-teacher.mmd (N8 ×2, N13, N15, N16), 10-activity-study-plan.mmd (viết lại theo StudyPlanner/StudyPlanService:
  thời lượng ước lượng, trừ phút done, thẻ ôn chỉ trừ mục done hôm nay = sửa lỗi trùng, tách assign 2×45′, quá tải/hoãn/bỏ, giữ
  done + skipped trong 1 transaction). 06-dataflow-bridge.mmd: không đổi (luồng LMS+Portal → N1/N9 → P2/P3/P6 vẫn đúng).
Render SVG: NOT_RUN (phiên cloud làm).

### FINAL-F6 Đổi mật khẩu role ứng dụng — 2026-11-10
tools/Rotate-AppRolePassword.ps1 (mới, BOM UTF-8): tự chạy lại bằng pwsh nếu mở từ PowerShell 5; cần PostgreSQL đang chạy; gọi
  Set-RuntimeRolePassword.ps1 (ô nhập ẩn mật khẩu postgres, mật khẩu 32 ký tự CSPRNG, ALTER ROLE qua stdin với log_statement=none,
  thử đăng nhập psql, ghi .local\backend.json, hoàn tác nếu lỗi); sau đó Stop-Demo -KeepPostgres + Start-Demo -NoEmulator và yêu cầu
  /health database = CONNECTED. Không in mật khẩu. Parse PS5 + PS7: 0 lỗi. Chạy thật: NOT_RUN — cần owner (mật khẩu postgres).
Việc cho owner: `.\tools\Rotate-AppRolePassword.ps1` một lần (role thuộc cluster nên đổi một lần cho cả dev và demo).

### FINAL-F3 (phần chạy thật) — 2026-11-10 21:30–22:10
Gate trên 6094590: Test-Backend -Package exit 0 (274/0/0/1 skip), Test-Flutter -BuildApk exit 0 (316). Measure-Api (Start-Demo -NoEmulator,
  DB demo, Portal UP): 12 endpoint × 200, p95 1,3–21,0 ms, 0 lỗi — D:\DLU-LMS\Artifacts\final\perf-20261110-214039.csv.
Đi hết DEMO_SCRIPT (17 bước) trên emulator với APK final, DB demo, Portal UP: ảnh D:\DLU-LMS\Artifacts\final\screens\demo-01..17.
  Lỗi tìm thấy và đã sửa: (1) lần đầu mở chi tiết SV lớp cố vấn > 20 s (server tải lịch sử nhiều học kỳ từ Portal) → app báo "phản hồi quá
  lâu" → ApiService.portalTimeout 60 s cho đường dẫn /portal/ (test final_f2_test), commit d36c389; (2) thẻ "Trợ lý giảng dạy" của GV
  nền xanh nhạt cứng → chữ không đọc được ở chế độ tối → context.tint + test quét mã nguồn cấm màu xám/đen/nền rất sáng cứng, commit
  6aaa36a (FE 318). Kịch bản chỉnh theo thực tế: tìm `ho tro hoc` (tên khóa trong DB demo là tiếng Anh), ôn thẻ ở khóa Mobile (thêm thẻ nếu
  không có thẻ đến hạn), tab Điểm › Mô phỏng điểm, mẹo làm ấm cache Portal.
Ảnh F2 bổ sung: f2-09 trục Y "Xu hướng học tập theo tuần" 1 dòng, f2-10 "Hoạt động gần nhất: sau hôm nay 5 ngày", f2-11..15 chế độ tối
  (trang chủ SV, chi tiết khóa, Học vụ, trang chủ GV sau sửa, lớp cố vấn); lịch tuần demo-09.
Ghi dữ liệu app (SV 205, đã duyệt): tạo 1 thẻ "Android Activity lifecycle" (khóa 14) và chấm "Được" 1 lần trong video sv-3. Không gửi nhắc
  riêng (chỉ mở rồi đóng hộp thoại). Không lập lại kế hoạch.
APK/JAR hiện tại (sẽ đóng gói lại sau đăng nhập MSSV): APK B3DBC02B…EF6215 (6aaa36a), JAR 0EB97BD5…2A0B3 (backend 6094590).

### FINAL-F5 Video quay màn hình thật — 2026-11-10 22:09–22:31
D:\DLU-LMS\Artifacts\final\video\ (adb screenrecord 6 Mbps, thao tác bằng adb input, chưa ghép/biên tập; khung kiểm tra trong checkpoints\):
- sv-1-tong-quan-gpa.mp4 (1:06, 1,1 MB): chọn Sinh viên → trang chủ thẻ GPA Portal, cuộn → Tình trạng học tập (Đỏ, lý do +25/+25/+10, việc để lên Xanh).
- sv-2-ctdt-mo-phong.mp4 (2:02, 3,0 MB): Học vụ › Chương trình (84,5 %, đủ điều kiện đăng ký) › Mô phỏng GPA (3,44 → dự kiến 3,30, Giỏi cần
  2,67) → khóa Mobile › Điểm › Mô phỏng điểm, kéo bài Android API lên 90 % → dự kiến 53,0 %.
- sv-3-ke-hoach-on-the.mp4 (2:28, 2,3 MB): Kế hoạch tuần (dải 7 ngày) → ôn thẻ SM-2 (lật, "Được", tổng kết) → Lịch tuần → tìm `ho tro hoc`.
- gv-1-du-bao-quiz.mp4 (2:24, 10,2 MB): chọn Giảng viên → khóa Hỗ trợ học tập số › Phân tích → Dự báo qua môn (Nguy cơ cao 1, Cần cố gắng 1…)
  → Phân tích bài kiểm tra (Quiz 5.1 Quá khó + Nhiều SV bỏ; Quiz 5.2).
- gv-2-co-van-nhac-rieng.mp4 (1:45, 2,2 MB): Lớp cố vấn ITK47A, bật Ẩn danh, Cần quan tâm → SV 09 (lịch sử học kỳ) → khóa › Xem SV cần theo
  dõi → Trần Minh Bảo → Nhắc riêng mẫu "Lâu không truy cập" (đóng, không gửi).
Mỗi file mở được (header ftyp; Windows đọc thời lượng). Lần quay đầu của sv-1, gv-1, gv-2 bị lệch thao tác (cuộn quá / chạm khi đang tải) → đã quay lại.

### LOGIN Đăng nhập bằng MSSV — 2026-11-10 22:30–23:10 (commit 08e41e6; owner yêu cầu sau F5, trước F7)
Backend: security/auth/{AuthProperties, AuthProvider, LocalCredentialProvider (BCrypt 12, hash giả cho tài khoản không tồn tại),
  MoodleTokenProvider (token.php + core_webservice_get_site_info; TẮT, chỉ test bằng MockRestServiceServer, không gọi lms.dlu.edu.vn),
  LoginAttemptLimiter (5 lần / 15 phút theo login + IP, bộ nhớ), LoginService (log chỉ kết quả/userId/độ dài login), AuthConfig},
  controller/LoginController (POST /api/v1/auth/login; 401 chung, 429 + Retry-After, 400 body sai/quá dài, 503 khi không có provider),
  tools/BcryptCli (băm qua JAR), SecurityConfig permit /auth/login, application.properties app.auth.local/moodle.enabled=false.
  demo-login cũ giữ nguyên điều kiện (profile local-development + DEMO_AUTH_ENABLED).
Frontend: screens/login_screen.dart (MSSV/tên đăng nhập, mật khẩu hiện/ẩn, Ghi nhớ mã số — chỉ mã số, lỗi chung/khóa tạm/mất mạng,
  "Chế độ demo" chỉ ở bản local), widgets/logout_button.dart (trang chủ SV + GV), ApiService.login, ReminderService.clearAll,
  main.dart mở màn Đăng nhập, màn chọn vai trò có nút quay lại.
Tools: Set-DemoPasswords.ps1 (ô nhập ẩn ×2, ≥ 8 ký tự, băm bằng JAR, ghi khối AUTH vào .local\backend.json, in login + role; -PasswordFile
  chỉ cho phiên tự động), Start-LocalBackend.ps1 (khối AUTH → app.auth.local qua SPRING_APPLICATION_JSON, hash vào danh sách che).
Tests: BE LoginApiTest 7 + MoodleTokenProviderTest 3 (tổng 284/0/0/1 skip); FE login_test 11 (tổng 329). Gate: Test-Backend -Package exit 0,
  Test-Flutter -BuildApk exit 0.
Runtime (emulator, DB demo, Portal UP): login-01 màn Đăng nhập; login-02 nhập 2312005 + mật khẩu (che); login-03 vào thẳng giao diện SV;
  login-04 teacher02 vào giao diện GV (sau Đăng xuất, mã số được điền sẵn); login-05a sai mật khẩu → "Mã số hoặc mật khẩu không đúng";
  login-05 lần thứ 6 → "Đăng nhập sai nhiều lần. Vui lòng thử lại sau 14 phút."; login-06 2212001 xem kết quả ở mục dưới.
  Video sv-1-tong-quan-gpa.mp4 quay lại có màn đăng nhập (mật khẩu che hoàn toàn: đã tắt hiện ký tự vừa gõ trên emulator).
Sự cố trong lượt: lần gõ đầu, bàn phím đẩy form lên nên cú chạm trượt và mật khẩu tạm bị gõ vào ô mã số, hiện trong 2 ảnh chụp → đã xóa
  ảnh, đổi bộ mật khẩu tạm khác (Set-DemoPasswords), khởi động lại backend; từ đó chuyển ô bằng phím Enter.
Mật khẩu demo hiện tại là mật khẩu tạm do phiên Claude sinh ngẫu nhiên (không ghi ở đâu ngoài file tạm sẽ xóa). **Owner phải đặt lại**:
  `.\tools\Set-DemoPasswords.ps1` rồi khởi động lại backend.
Bản cuối đóng gói lại từ 08e41e6: APK E285526E2BDC1E5AB2CC0E6382C1DEBE5090B547666E8B7D0793A7CD4F048917,
  JAR 3169A50465347CABE25686B650B2A569B856BC99B0F3C352FDAB10AAF8C9F046 (D:\DLU-LMS\Artifacts\final, SHA256SUMS.txt); docs/RELEASE_NOTES.md.

### PUSH GitHub (docs/PUSH_GITHUB.md) — 2026-11-10 23:05 — BLOCKED, chờ owner quyết định
Owner cho phép push nhánh mới `dlu-lms-group-bao-ve` lên https://github.com/teddy3704/DOANTOTNGHIEP (không main, không --force).
Bước 2 quét bí mật trên toàn bộ lịch sử (`git log --all -p`, 33 commit): các dòng khớp `password`/`secret`/`mk_dev_`/`X-API-KEY` đều là
  tên biến, placeholder `${...}`, secret chỉ dành cho test (`isolated-test-only-secret-not-for-runtime-1234`) hoặc văn bản nhắc tên key
  (không có chuỗi `mk_dev_` kèm giá trị: 0 lần). **NHƯNG** commit gốc `6f8c0ab` (nhập bản mã nguồn ban đầu) chứa:
  - `backend/docs/authentication_mvp.md` dòng 76–79: bảng **mật khẩu demo dạng chữ thường** của `student205` và `teacher102`
    (hệ đăng nhập `app.auth_account` của bản cũ);
  - `backend/db/auth/002_seed_demo_auth.sql`: hash BCrypt cost 10 của đúng hai mật khẩu đó.
  Hai file vẫn còn trong cây hiện tại. Mẫu của PUSH_GITHUB không bắt được (bảng Markdown, không có `password:`), nhưng đây là thông tin
  đăng nhập dùng được → theo quy tắc 4: DỪNG, KHÔNG push, không tự xóa khỏi lịch sử.
Bước 3 file lớn: blob lớn nhất 0,7 MB (backend/db/mock/seed_demo_v3.sql) — đạt. Bước 4: README.md chưa có → đã viết (commit cục bộ).
Chưa thêm remote, chưa fetch, chưa push.
Owner chọn một trong các cách (Claude không tự làm):
  (a) Viết lại lịch sử để bỏ hai đoạn đó (vd. `git filter-repo --replace-text`), rồi Claude quét lại và push;
  (b) Push một nhánh mới chỉ có ảnh chụp cây hiện tại (một commit gốc mới, không mang lịch sử cũ) sau khi xóa/che hai đoạn đó;
  (c) Xác nhận hai mật khẩu demo này không dùng ở bất kỳ hệ thống nào còn chạy (Render/Supabase cũ, DB demo) và chấp nhận công khai.
  Dù chọn cách nào: nếu tài khoản `student205`/`teacher102` của bản cũ còn tồn tại ở đâu, nên vô hiệu hóa hoặc đổi mật khẩu.

LOGIN bổ sung (23:08–23:12): sau khi hết khóa, `2212001` đăng nhập được (login-06: "Xin chào, Le An", chỉ dữ liệu của SV 201, không có thẻ
  GPA vì 201 không ánh xạ Portal). API thật: token của 201 gọi /dev/students/205/weekly-report → 403, /dev/students/201/… → 200.
  File mật khẩu tạm đã ghi đè và xóa. Emulator: đã tắt "hiện ký tự vừa gõ" (settings system show_password 0) và khóa xoay dọc.

## TỔNG KẾT CUỐI — FINAL 10/11/2026 (bản bảo vệ 20/11/2026)
- STATUS: FINAL-F0…F7 DONE; LOGIN (đăng nhập MSSV) DONE; PUSH GitHub DONE theo cách (b) — xem mục PUSH cách (b) cuối file.
- Git cục bộ nhánh `codex/group-stack-takeover`, tag `bao-ve-2026-11-20` (không push, không remote). Mã nguồn bản cuối: `08e41e6`
  (sau đó chỉ tài liệu).
- Test cuối (trên 08e41e6): Backend `Test-Backend -Package` exit 0 — 284 test, 0 lỗi, 1 bỏ qua có chủ đích (SchemaVerificationTest);
  Flutter `Test-Flutter -BuildApk` exit 0 — 329 test, analyze sạch. Hiệu năng: 12 endpoint × 200, p95 1,3–21,0 ms, 0 lỗi.
- Bản cuối D:\DLU-LMS\Artifacts\final\ (SHA256SUMS.txt):
  - dlu-lms-group-final-debug.apk — E285526E2BDC1E5AB2CC0E6382C1DEBE5090B547666E8B7D0793A7CD4F048917
  - lms_mobile_backend-final.jar — 3169A50465347CABE25686B650B2A569B856BC99B0F3C352FDAB10AAF8C9F046
- Ảnh: D:\DLU-LMS\Artifacts\final\screens\ (demo-01..17 đi hết DEMO_SCRIPT, f2-00..15 F2 + chế độ tối, login-01..06);
  ảnh cũ v2/v3 ở D:\DLU-LMS\Artifacts\v2|v3\screens. Video: D:\DLU-LMS\Artifacts\final\video\ — sv-1-tong-quan-gpa (có đăng nhập),
  sv-2-ctdt-mo-phong, sv-3-ke-hoach-on-the, gv-1-du-bao-quiz, gv-2-co-van-nhac-rieng (1:06–2:28, chưa ghép/biên tập).
- Tài liệu: RELEASE_NOTES, DEMO_SCRIPT (17 bước + dự phòng + 8 câu hội đồng), USER_GUIDE, README, LOCAL_RUNBOOK, sơ đồ 02/04/08/09/10.
- NOT_RUN / PARTIAL: Start-Demo -PhysicalDevice trên điện thoại thật; Rotate-AppRolePassword và Set-DemoPasswords chạy bằng tay owner
  (Set-DemoPasswords đã chạy thử bằng -PasswordFile); render SVG sơ đồ (phiên cloud); O1 owner tự chạy sau khi đóng Claude.
- Việc cho owner:
  1. Chạy `.\tools\Start-Demo.ps1` từ PowerShell của mình SAU KHI đóng Claude (bài thử O1), rồi `.\tools\Stop-Demo.ps1`.
  2. `.\tools\Set-DemoPasswords.ps1` — đặt mật khẩu đăng nhập demo (2312005, 2212001, teacher02); mật khẩu hiện tại là mật khẩu tạm
     ngẫu nhiên của phiên Claude, không ai còn giữ.
  3. `.\tools\Rotate-AppRolePassword.ps1` — đổi mật khẩu role CSDL lms_group_app (cần mật khẩu postgres).
  4. Giữ ổ C ≥ 22 GiB trước buổi bảo vệ (hiện 22,9 GiB).
  5. Quyết định cách xử lý mật khẩu demo trong lịch sử git (mục PUSH ở trên: a/b/c) để Claude push nhánh `dlu-lms-group-bao-ve`
     và tag; vô hiệu hóa tài khoản student205/teacher102 của bản cũ nếu còn ở đâu đó.
- NEXT_ACTION (phiên sau): chờ quyết định PUSH của owner; nếu (a)/(b)/(c) → quét lại toàn bộ lịch sử, push nhánh + tag, xác nhận
  `git ls-remote`.

### PUSH cách (b) — owner chọn 10/11/2026 (docs/PUSH_SNAPSHOT_PROMPT.md)
Bước 1 (commit 6d88f2a): tham chiếu tới hai file chỉ có trong tài liệu (backend/docs/authentication_mvp.md hướng dẫn chạy tay bằng
  pgAdmin, database/README.md, HANDOFF/RESUME_STATE/TASK_BOARD) — không script/test/build nào dùng file SQL. Đã `git rm`
  backend/db/auth/002_seed_demo_auth.sql; bảng mật khẩu trong authentication_mvp.md thay bằng dòng "Bảng tài khoản demo của bản cũ đã
  được gỡ…"; README thêm dòng "ảnh chụp mã nguồn bản bảo vệ". Quét cây làm việc bằng `git grep -c -F` với 2 mật khẩu + 2 hash cũ
  (đọc từ 6f8c0ab vào bộ nhớ, không in): 0 / 0 / 0 / 0. Lịch sử cục bộ giữ nguyên.
Bước 2 (chỉ đọc, role lms_group_app): `SELECT to_regclass('app.auth_account')` → NULL trên lms_mobile_group_dev và
  lms_mobile_group_demo: bảng đăng nhập của bản cũ không tồn tại, hai tài khoản student205/teacher102 không có trong DB cục bộ.
  Không sửa DB. (Các hệ thống ngoài máy này — Render/Supabase cũ — không kiểm tra được.)
F7: tag cục bộ `bao-ve-2026-11-20` được đặt lại vào commit có cây trùng snapshot (trước đó trỏ 6c5031e); không đổi hash commit nào.
Bước 3: snapshot `4d00d9820fad6702307fdebc4b15baf36c50b8a4` (git commit-tree, 1 commit, không cha), **cùng cây với commit cục bộ
  41f888beff685b1cbe02a08b8f6bbcd61bbee8df** (tree caceb9b247a10c522414d3c90f5469e34860f698); 534 file; không có .local/, .env*, *.apk,
  *.jar, *.jks, *.keystore, *.log. Quét cây: 2 mật khẩu + 2 hash cũ = 0; bcrypt hash = 0; key mk_dev_ có giá trị = 0; private key = 0;
  các dòng còn lại khớp mẫu là tên biến/placeholder/secret chỉ cho test/tài liệu liệt kê mẫu. Không tạo nhánh cục bộ, HEAD không đổi.
Bước 4–5: remote `github` = https://github.com/teddy3704/DOANTOTNGHIEP.git; ls-remote trước khi push: chưa có nhánh/tag. Push
  `<snap>:refs/heads/dlu-lms-group-bao-ve` (new branch) và `<snap>:refs/tags/bao-ve-2026-11-20` (new tag), không --force, không đẩy
  HEAD/tag cục bộ. Thời gian push: 2026-11-10 23:22 (+07). ls-remote sau push: refs/heads/dlu-lms-group-bao-ve = refs/tags/bao-ve-2026-11-20
  = 4d00d9820fad6702307fdebc4b15baf36c50b8a4; refs/heads/main giữ nguyên c773b7e. Đăng nhập GitHub: Git Credential Manager đã có sẵn
  quyền, không cần owner thao tác; không đọc/ghi token.
  Xem: https://github.com/teddy3704/DOANTOTNGHIEP/tree/dlu-lms-group-bao-ve
  Cập nhật về sau (chỉ khi owner yêu cầu): `git commit-tree 'HEAD^{tree}' -p 4d00d9820fad6702307fdebc4b15baf36c50b8a4 -m '...'`, push
  fast-forward vào nhánh; tag trên GitHub giữ nguyên.

## POLISH (docs/POLISH_PROMPT.md, owner 23:30 10/11/2026)
### POLISH-1/2/4 — commit 229ed71 (gate: BE 290/0/0/1 skip, FE 333, APK build exit 0)
POLISH-1: PortalPrewarmer (app.portal.prewarm, mặc định tắt) — sau ApplicationReady, luồng nền daemon gọi tuần tự
  AdvisorPortalService.overview rồi student(no) cho từng SV lớp cố vấn của GV demo (app.demo-auth.teacher-id), nghỉ 1 s sau mỗi lời gọi,
  lỗi chỉ đếm; log "Portal prewarm finished: ok/failed/total/ms" (không dữ liệu); /health thêm `prewarm: "N/M"` (null khi tắt).
  app.portal.cache-ttl đã có (mặc định 10 phút); Start-LocalBackend -DemoCache (chỉ Start-Demo dùng) đặt cacheTtl 6h + prewarm true qua
  SPRING_APPLICATION_JSON. Test PortalPrewarmerTest 6 (TTL bind 6h/mặc định 10 phút, mặc định tắt, gọi đúng 1+3 lần với 4 lần nghỉ,
  Portal DOWN không lỗi, 1 SV lỗi không chặn SV khác, log không có lớp/MSSV/tên).
  Đo (API, cùng cách app gọi): trước — backend không làm nóng, cache lạnh, 23:33 Portal nhanh: tổng quan 3569 ms (17 lời gọi Portal nối
  tiếp, tổng 3952 ms, chậm nhất 1693 ms), chi tiết SV đầu 954 ms; lúc 21:52 Portal chậm: chi tiết SV đầu > 20 s (app báo "phản hồi quá
  lâu"). Sau — Start-Demo, prewarm 67/67 (≈ 70 s sau khi backend UP): tổng quan 77 ms, chi tiết SV 242–258 ms. Emulator (bản build
  229ed71, Chế độ demo → GV → Lớp cố vấn → SV đầu): màn chi tiết đầy đủ khi chụp 2 s sau khi bấm (polish1-lop-co-van-2s,
  polish1-chi-tiet-sv-2s).
POLISH-2: AccountMenu (widgets/logout_button.dart) thay nút Đăng xuất ở góc trái trang chủ SV và GV: Giao diện Theo máy/Sáng/Tối (dấu ✓)
  + Đăng xuất; tooltip "Tài khoản và giao diện". Test account_menu_test 4 (2 trang chủ × đổi tối/sáng; 320 dp × 1.3, mở menu không
  tràn); login_test cập nhật. Emulator: polish2-01 menu, polish2-02 tối, polish2-03 về sáng.
POLISH-4: Start-Demo bước 0 kiểm tra chỉ đọc: pin (Win32_Battery BatteryStatus 1), chờ khởi động lại (RebootRequired, RebootPending,
  PendingFileRenameOperations), internet/Portal (HEAD baseUrl, 5 s; mọi phản hồi HTTP = có mạng); SHA của APK đang cài trên máy
  (pm path + sha256sum) so với bản cuối; bảng "SẴN SÀNG?" (DB, Backend, Portal + prewarm, Thiết bị, APK, Ổ C, Kết luận). Parse PS5/PS7 0
  lỗi. Chạy thật 23:35: Kết luận "CẦN XỬ LÝ — Windows đang chờ khởi động lại (cập nhật)" → việc cho owner. LOCAL_RUNBOOK có cách đọc bảng.

### POLISH-3 Nội dung demo — 2026-11-10 23:44–23:47 (DB lms_mobile_group_demo, chỉ qua API của app, SV 205)
Rà (chỉ đọc) dữ liệu app của SV 205 / GV 102: thẻ ôn, kế hoạch tuần, mục tiêu, nhật ký, thông báo, phiên học, ghi chú GV.
Nội dung vô nghĩa tìm thấy (tạo 10/10/2026 khi thử nghiệm bản cũ):
  - thẻ ôn id 8 (khóa Mobile 14): "ss" / "sss" → ĐÃ SỬA (PUT, chức năng Sửa của app) thành "Intent trong Android dùng để làm gì?";
  - thẻ ôn id 9 (tạo hôm nay, tiếng Anh) → sửa thành "Vòng đời của Activity gồm những hàm nào?";
  - nhật ký (reflections) id 2 "s" (khóa 13) và id 1 "hôm nay tôi đa" → app/API KHÔNG có Sửa (chỉ thêm/xem) → owner quyết định
    (không xóa, không SQL); màn Nhật ký không có trong DEMO_SCRIPT;
  - ghi chú GV id 1 "s", id 2 "a" (khóa 13, đã đóng "resolved") → API chỉ đổi trạng thái, không Sửa → owner quyết định; có thể hiện
    trong mục "Hiệu quả hỗ trợ" của khóa Software Testing (DEMO_SCRIPT dùng khóa Hỗ trợ học tập số, nơi chỉ có ghi chú thật).
  Mục tiêu (4), thông báo SV (3), kế hoạch tuần (8 mục, 1 đã xong), phiên học tập trung: nội dung có nghĩa, không đổi.
Thêm qua app API (POST, như nút "Thêm thẻ"): 6 thẻ — Software Testing: kiểm thử hộp đen, hộp trắng, phân vùng tương đương; Mobile:
  RecyclerView vs ListView, ViewModel; Hỗ trợ học tập số: Pomodoro. Tổng 8 thẻ có nghĩa ở 3 khóa, 6 thẻ đến hạn ôn (chip "Hôm nay
  cần ôn"). Thành tích: có dữ liệu (1/6 huy hiệu + tiến độ). Kế hoạch: tuần 20/11 bấm "Lập lại kế hoạch" khi demo (giữ mục đã xong).
Ảnh: final\screens\polish3-01-the-on-mobile.png.

### POLISH-5 Tập trọn kịch bản và bấm giờ — 2026-11-11 02:35–02:50 (emulator, DB demo, Portal UP, prewarm 67/67, APK build 229ed71)
Lượt 1 hỏng ngay từ bước 1 (chạm rơi vào ô mật khẩu rồi lạc sang ứng dụng Google trên emulator) → số đo bỏ. Nguyên nhân dịch tọa độ:
  banner "Giảng viên … vừa nhắc bạn" biến mất vì thông báo đó đã thành "đã đọc" (lượt hỏng chạm vào banner) → các thẻ trang chủ dịch
  lên; đây cũng là trạng thái ngày demo. Lượt 2 chạy theo 3 đoạn (1–6, 7–11, 12–17), mỗi đoạn kiểm khung hình: cả 17 bước đến đúng
  màn (ảnh final\screens\rehearse-01..17). Đo thao tác + tải màn (1,5 s mỗi lần bấm): 12,5 / 5,2 / 14,8 / 8,7 / 11,3 / 11,3 / 37,8 /
  23,2 / 27,2 / 11,3 / 15,7 / 30,5 / 17,1 / 6,7 / 62,1* / 38,6* / 33,9 s (*gồm thời gian công cụ dò chữ tự động khi cuộn).
DEMO_SCRIPT thêm cột "Giây" (thao tác đo + nói câu thuyết minh 3 tiếng/giây + 15 s gõ mã số/mật khẩu ở bước 1 và 12; bước 15–16 tính
  cuộn tay): tổng ≈ 455 s (7 phút 35 giây) + 15 s kết luận ≤ 10 phút → không phải chuyển bước nào. Bước 17 đổi sang đường ổn định:
  khóa › "Xem sinh viên cần theo dõi" › Trần Minh Bảo › Nhắc riêng (mẫu "Lâu không truy cập") › Hủy. Không có bước lỗi chức năng.
Ghi dữ liệu trong lượt (SV 205, qua app): chấm 1 thẻ ("Được") ở bước 7; thông báo nhắc riêng của GV thành đã đọc. Không gửi nhắc riêng.

### POLISH-6 Tài liệu trả lời hội đồng — 2026-11-11
DEMO_SCRIPT thêm câu 9–13 (an toàn đăng nhập MSSV, vì sao chưa dùng tài khoản LMS thật, vì sao GitHub là ảnh chụp, Portal có lưu đĩa
  không, mất mạng — hai trường hợp máy demo mất internet / điện thoại mất kết nối backend), đối chiếu code: LocalCredentialProvider.COST=12,
  LoginAttemptLimiter 5/15 phút, LoginController thông báo chung, ApiSession giữ token trong bộ nhớ, LoginMemory chỉ lưu mã số,
  MoodleTokenProvider TẮT + 3 test mock, PortalCache bộ nhớ (6 h demo / 10 phút), portalCacheTtl app 5 phút, git rev-list 42 commit từ
  09/11. COMPARISON_FACTS thêm dòng "Đăng nhập"; RELEASE_NOTES thêm "Hướng phát triển" (APK release, offline GV, unaccent, N14/N9, Portal đĩa).

### POLISH-7 Video — 2026-11-11 02:53–02:58 (APK build 229ed71, Chế độ demo, cache đã làm nóng)
Quay lại 2 đoạn (bản cũ giữ hậu tố -r1, không xóa; cùng lệnh screenrecord 6 Mbps, chưa ghép/biên tập):
- sv-3-ke-hoach-on-the.mp4 (2:10, 2,5 MB) — thay vì thẻ test cũ: Kế hoạch tuần → chip "Hôm nay cần ôn 5 thẻ" → lật + "Được" 2 thẻ tiếng
  Việt (kiểm thử hộp đen…) → Lịch tuần → tìm `ho tro hoc`. Bản cũ: sv-3-ke-hoach-on-the-r1.mp4 (2:28).
- gv-2-co-van-nhac-rieng.mp4 (1:37, 2,4 MB) — chi tiết SV 09 hiện ngay (chờ 3 s thay vì ~8 s ở bản cũ), Xem SV cần theo dõi → Trần Minh
  Bảo → Nhắc riêng → đóng (không gửi). Bản cũ: gv-2-co-van-nhac-rieng-r1.mp4 (1:45).
Giữ nguyên: sv-1-tong-quan-gpa (có cảnh đăng nhập MSSV thật; quay lại cần mật khẩu thật mà POLISH cấm Set-DemoPasswords — khác biệt duy
  nhất là biểu tượng góc trái trang chủ nay là menu Tài khoản), sv-2-ctdt-mo-phong, gv-1-du-bao-quiz (không có màn bị POLISH-2/3 đổi
  ngoài biểu tượng đó; không có cảnh chờ tải lâu). Ghi dữ liệu: chấm 2 thẻ "Được" (SV 205); không gửi nhắc riêng.
