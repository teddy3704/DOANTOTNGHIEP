# DLU LMS Group — workspace rules

This is the NEW group workspace: Java21/Spring Boot + Flutter + supplied PostgreSQL backup.
Read backend/AGENTS.md and frontend/AGENTS.md before changing those scopes.
Do not modify the old DLU repositories or their databases, Render settings or Git remotes.

- Preserve source and existing uncommitted changes. No destructive reset or cleanup.
- No production Moodle writes, private scraping or fabricated live data.
- Official assignment submission, quizzes and grading remain in Moodle.
- Flutter never receives database credentials or connects directly to PostgreSQL.
- Do not print secrets, env values, raw database rows or sensitive SQL error context.
- No automatic schema changes at application startup; reviewed migrations only.
- Database restore is allowed only into a new, empty, explicitly identified target.
- Do not replace the exact supplied backup with the older mock dataset.
- Development role login is explicit LOCAL ONLY, never a public production login.
- Use D for new toolchains/caches/artifacts; stop large installations if C <15GB free.
- No Android Studio. No global toolchain changes just for this workspace.
- Backend and frontend test/build gates must be actually run; distinguish NOT_RUN.
- Keep docs/HANDOFF.md current after milestones. No credentials in handoff files.
- One writer per worktree; one migration owner per database. Never run two agents on the same file.
- No commit, push, merge or deployment to existing services without explicit approval.

Source snapshots: see docs/SOURCE_BASELINE.md. Current state: docs/HANDOFF.md.
