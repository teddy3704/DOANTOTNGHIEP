-- V2 feature migration (docs/V2_FEATURES_PROMPT.md §3 + PART_B N10). Schema app only.
-- Idempotent (IF NOT EXISTS) and meant to run inside ONE transaction:
--   psql --single-transaction -v ON_ERROR_STOP=1 -f 2026-11-08_v2_features.sql
-- Run as the database owner (postgres) by tools/Apply-V2Migration.ps1, never by the runtime role.
-- Grants for lms_group_app live in database/grants_lms_group_app.sql (applied right after).
\set ON_ERROR_STOP on

-- V2-N5: SM-2 spaced-repetition state per card and per user.
CREATE TABLE IF NOT EXISTS app.flashcard_reviews (
    id               bigserial PRIMARY KEY,
    flashcard_id     bigint      NOT NULL REFERENCES app.flashcards(id) ON DELETE CASCADE,
    user_id          bigint      NOT NULL,
    repetitions      int         NOT NULL DEFAULT 0,
    ease_factor      numeric(4,2) NOT NULL DEFAULT 2.50,
    interval_days    int         NOT NULL DEFAULT 0,
    due_at           timestamptz NOT NULL DEFAULT now(),
    last_rating      smallint    CHECK (last_rating BETWEEN 0 AND 5),
    last_reviewed_at timestamptz,
    CONSTRAINT flashcard_reviews_card_user_uq UNIQUE (flashcard_id, user_id),
    CONSTRAINT flashcard_reviews_values_ck CHECK (repetitions >= 0 AND interval_days >= 0 AND ease_factor >= 1.30)
);
CREATE INDEX IF NOT EXISTS flashcard_reviews_user_due_idx ON app.flashcard_reviews (user_id, due_at);

-- V2-N6: weekly study plan.
CREATE TABLE IF NOT EXISTS app.study_plan_items (
    id              bigserial PRIMARY KEY,
    user_id         bigint       NOT NULL,
    course_id       bigint,
    plan_date       date         NOT NULL,
    source_type     varchar(20)  NOT NULL
        CHECK (source_type IN ('assign', 'quiz', 'resource', 'flashcards', 'custom')),
    source_id       bigint,
    title           varchar(255) NOT NULL,
    planned_minutes int          NOT NULL CHECK (planned_minutes > 0),
    status          varchar(10)  NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'done', 'skipped')),
    created_at      timestamptz  NOT NULL DEFAULT now(),
    updated_at      timestamptz  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS study_plan_items_user_date_idx ON app.study_plan_items (user_id, plan_date);

-- V2-N10: focused study sessions (Pomodoro) feeding study_minutes goals.
CREATE TABLE IF NOT EXISTS app.study_sessions (
    id            bigserial PRIMARY KEY,
    user_id       bigint      NOT NULL,
    course_id     bigint,
    plan_item_id  bigint      REFERENCES app.study_plan_items(id) ON DELETE SET NULL,
    started_at    timestamptz NOT NULL,
    ended_at      timestamptz NOT NULL,
    focus_minutes int         NOT NULL CHECK (focus_minutes BETWEEN 1 AND 180),
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT study_sessions_time_ck CHECK (ended_at > started_at)
);
CREATE INDEX IF NOT EXISTS study_sessions_user_started_idx ON app.study_sessions (user_id, started_at);

-- New tables follow the existing app tables' owner (the cluster owner); no grants to PUBLIC.
REVOKE ALL ON app.flashcard_reviews, app.study_plan_items, app.study_sessions FROM PUBLIC;
