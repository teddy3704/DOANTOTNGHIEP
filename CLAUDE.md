# Claude / Codex shared entrypoint

Read AGENTS.md, the relevant backend/frontend AGENTS.md, docs/SOURCE_BASELINE.md
and docs/HANDOFF.md before work. This workspace supersedes the old implementation
for new work but does NOT authorize deleting or modifying the old project.

This is a source-archive takeover, not a clone of an existing GitHub branch.
Do not infer old Node/Render/Supabase checkpoints or import their configuration.
Do not run tests/startup until database side effects and target isolation are verified.

On takeover, inspect git status and any active build/service processes first.
Resume the exact next step. Preserve unfinished changes. State real evidence and
NOT_RUN gates honestly. Update the handoff after each small milestone, not only
when usage is almost exhausted. Do not include secrets or sensitive row data.

There is no automatic Codex-to-Claude switching configured. The human starts the
next tool; only one tool owns a given working copy at a time.

On start or resume, read docs/RESUME_STATE.md first (current checkpoint: NEXT_ACTION, DO_NOT_REPEAT).
