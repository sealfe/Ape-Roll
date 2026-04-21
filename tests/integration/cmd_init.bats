#!/usr/bin/env bats
# Integration tests for: roll init (simplified — US-CLI-001)
# New behavior: no type prompt, no tool prompt, no scaffold — 3-step init only.
#   1. Fresh project  → creates AGENTS.md + BACKLOG.md + docs/features/
#   2. Existing AGENTS.md → re-merges global conventions (idempotent)

load helpers

setup() {
  integration_setup
  run_roll setup
  PROJECT_DIR="${TEST_TMP}/myproject"
  mkdir -p "$PROJECT_DIR"
}

teardown() {
  integration_teardown
}

# Helper: run roll init inside PROJECT_DIR — no stdin needed (no prompts)
roll_init() {
  bash -c "cd '${PROJECT_DIR}' && HOME='${TEST_TMP}' ROLL_HOME='${ROLL_HOME}' '${ROLL_BIN}' init"
}

# ─── Happy path: fresh project ─────────────────────────────────────────────────

@test "init: creates AGENTS.md in new project" {
  run roll_init
  [ "$status" -eq 0 ]
  [ -f "${PROJECT_DIR}/AGENTS.md" ]
}

@test "init: creates BACKLOG.md in new project" {
  run roll_init
  [ "$status" -eq 0 ]
  [ -f "${PROJECT_DIR}/BACKLOG.md" ]
}

@test "init: creates docs/features/ in new project" {
  run roll_init
  [ "$status" -eq 0 ]
  [ -d "${PROJECT_DIR}/docs/features" ]
}

# ─── Happy path: re-merge (existing AGENTS.md) ────────────────────────────────

@test "init: re-merge exits 0 when AGENTS.md already exists" {
  run roll_init
  [ "$status" -eq 0 ]
  [ -f "${PROJECT_DIR}/AGENTS.md" ]

  # Second init — no prompts, should succeed and preserve AGENTS.md
  run roll_init
  [ "$status" -eq 0 ]
  [ -f "${PROJECT_DIR}/AGENTS.md" ]
}

@test "init: backfills BACKLOG.md when AGENTS.md exists but backlog is missing" {
  run roll_init
  [ "$status" -eq 0 ]
  rm -f "${PROJECT_DIR}/BACKLOG.md"

  run roll_init
  [ "$status" -eq 0 ]
  [ -f "${PROJECT_DIR}/AGENTS.md" ]
  [ -f "${PROJECT_DIR}/BACKLOG.md" ]
}

@test "init: backfills docs/features when AGENTS.md exists but features dir is missing" {
  run roll_init
  [ "$status" -eq 0 ]
  rm -rf "${PROJECT_DIR}/docs"

  run roll_init
  [ "$status" -eq 0 ]
  [ -f "${PROJECT_DIR}/AGENTS.md" ]
  [ -d "${PROJECT_DIR}/docs/features" ]
}

# ─── UX: clean completion message ────────────────────────────────────────────

@test "init: output includes 'Initialized' on success" {
  run roll_init
  [ "$status" -eq 0 ]
  [[ "$output" == *"Initialized"* ]]
}

# ─── Error path ────────────────────────────────────────────────────────────────

@test "init: exits non-zero when templates not found (setup not run)" {
  local empty_roll="${TEST_TMP}/empty_roll"
  mkdir -p "$empty_roll"
  run bash -c "cd '${PROJECT_DIR}' && HOME='${TEST_TMP}' ROLL_HOME='${empty_roll}' '${ROLL_BIN}' init"
  [ "$status" -ne 0 ]
}
