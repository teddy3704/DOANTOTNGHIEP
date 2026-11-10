# Access matrix — 2026-10-31

Status values: NOT_INSTALLED / NOT_CONFIGURED / AUTH_REQUIRED / READ_ONLY_VERIFIED /
WRITE_APPROVAL_REQUIRED / BLOCKED. A tool connection is not a business-flow PASS.
No credentials, tokens, connection strings or data rows are recorded here.

| Item | Status | Target verified | Evidence (no secrets) | Notes |
| --- | --- | --- | --- | --- |
| Workspace `D:\DLU-LMS-Group` (desktop-app bridge) | Writer: Claude | Yes | Folder grant 2026-10-31; git read with `GIT_OPTIONAL_LOCKS=0` | Bridge deletes are off by default; no git writes made |
| `D:\doan` sources + SQL backup | READ_ONLY_VERIFIED | Yes | SHA256 match; static prefix counts only | Grant is technically read/write; used read-only by instruction |
| `D:\DLU-LMS\Toolchains` | READ_ONLY_VERIFIED; execution BLOCKED here | Files present | JDK release file 21.0.12.1 Windows x64; Maven 3.9.16; Flutter SDK dir | Windows binaries cannot run in the bridge's Linux VM; not modified |
| Windows build/test execution (native Claude Code 2.1.308, 2026-10-31) | READ_ONLY_VERIFIED → used: backend `clean test` ran, exit 0 | Yes | Portable JDK 21.0.12.1 + Maven via tools/Use-LocalToolchain.ps1 (process env only) | Earlier bridge session below could not run it |
| Windows build/test execution (old bridge session) | BLOCKED (that session) | — | VM: Java 11 without javac; no mvn/flutter/dart/psql; Maven Central unreachable | No install or env change, per owner. Needs a Windows-native runner |
| Windows process visibility | BLOCKED | — | Bridge exposes no Windows process list | Codex stop is owner-confirmed only |
| Codex relay | Files/Git only | — | HANDOFF, TASK_BOARD, API_CONTRACT, ACCESS_MATRIX | No shared session, browser, tokens or agent bridge |
| Claude in Chrome | NOT_CONFIGURED | — | Connected browsers: none (checked 2026-10-30 23:15 +07) | Needs extension + owner approval |
| Built-in browser (Claude desktop app) | AUTH_REQUIRED (per site) | — | Tool reachable; pane not opened; no site visited | Its sign-ins are separate from Codex's browser |
| Computer use (Windows desktop) | NOT_CONFIGURED | — | Enable tool offered, not enabled | Per-app approval needed; could drive PowerShell/pgAdmin |
| pgAdmin 4 GUI | NOT_CONFIGURED (for Claude) | No | Owner reports pgAdmin is open | No DB created/changed; no query tabs prepared yet |
| PostgreSQL client/target | BLOCKED | No | No psql in VM; VM cannot reach Windows localhost; no approved target | POSTGRES_ACCESS is separate from PGADMIN_GUI_ACCESS |
| Supabase (claude.ai connector) | WRITE_APPROVAL_REQUIRED — unused | No project | Account-wide OAuth incl. write tools (`execute_sql`, `apply_migration`, deploy) | No Supabase reference in backend/src, pom, frontend/lib or pubspec: not in current stack. Do not call until owner names a project + purpose; prefer project-scoped `read_only=true` |
| Render (`srv-dalmjc6k1f9s738oqua0`, historical) | NOT_RUN | No | Not opened | No change/restart/deploy authorized |
| Neon (`weathered-bird-45764086`, historical) | NOT_RUN | No | Not opened | No restore into old project |
| Postman | NOT_RUN | No | Not opened | Base URL + test data only; no DB creds/secrets in collections |
| GitHub `teddy3704/DOANTOTNGHIEP` | NOT_RUN | No | Workspace has no remote | Not verified as this group's remote; do not attach/push |
| Moodle DLU | NOT_RUN | No | Not opened | No scraping, submissions or grading |
| Vercel, Microsoft 365 connectors | Out of scope | — | Connected in claude.ai | Not used for this project |
