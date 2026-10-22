# Game starter kit (Godot 4.7.2)

One kit for starting a Godot game that a lead Claude session builds with many parallel subagents. It is what two
projects proved: **Skate Park** (a kid-friendly skateboarding game) and **Sandblood** (an M-rated physics fighter
with online 1v1 and Android). It gives a new project, from minute one, the debug layer, quiet test and lint tools,
CI, a cloud session hook, export scripts, the agent rules, the playbook and every lesson those projects paid for.

The kit is itself a working Godot project (placeholders `__PROJECT_NAME__` / `__PROJECT_SLUG__` in a few files), so
its own `tools/run_tests.sh` and `tools/lint.sh` pass.

## Quick start

    tools/new_project.sh <dest> "<Name>"       # e.g. tools/new_project.sh ~/code/kart-racer "Kart Racer"
    cd <dest> && tools/check_all.sh             # all green on minute one (ends CHECK_ALL PASS)

The scaffolder copies the kit into `<dest>` (which must be empty or missing), fills in the display name, a file-safe
slug and an Android package segment, puts `kit/project_README.md` in place as the project README, leaves out the
kit-only files, runs `git init` (`--no-git` skips it) and prints the next steps: fill in `CLAUDE.md` and
`docs/agent_brief.md`, create the GitHub repo, push, confirm CI. Then follow `docs/playbook.md`.

## What is inside

| Path | What |
| --- | --- |
| `CLAUDE.md` | The project instructions template: commands, layout, rules (static typing, pure logic, tests, quiet tools). |
| `project.godot`, `export_presets.cfg` | Compatibility renderer, 60 Hz physics, typed-GDScript warnings, `Flags` and `Controls` autoloads; Windows Desktop and Android presets. |
| `game/` | `autoload/` (`Flags`: run args, frame counter, state hash, `is_scripted_run()`; `Controls`), `debug/` (frame stamp F10 + frame code, render toggles F4/F6-F9, `Tuning`), `main.tscn`. |
| `tests/` | `runner.gd` + `test_case.gd` (unit tests in `tests/unit/test_*.gd`), `sim/` (sim suite, base with `net_port()`, example sim). |
| `tools/` | `run_tests.sh`, `lint.sh` (+ `lint.py`, `lint_parse.gd`), `run_sims.sh`, `check_all.sh`, `export_windows.sh`, `export_android.sh`, `frame_code.py`, `agent_stats.py` + `agent_dashboard/`, `new_project.sh` (kit only). |
| `.github/` | `checks` workflow (unit, lint, sims as a matrix; commented bot shard rows) and the `setup-godot` action. |
| `.claude/` | Settings (75-agent caps, SessionStart hook) and `hooks/session-start.sh` (installs pinned Godot, xvfb, zip, imports the project). |
| `docs/playbook.md` | Kickoff steps, fan-out rules (contract brief, file ownership, model choice, worker preamble, hand-back), measure-fix-verify loop, feeding the kit. |
| `docs/agent_brief.md` | Hard rules for helper agents and the contract skeleton. |
| `docs/new_project_checklist.md` | Day one to shipping, as checkboxes. |
| `docs/production_pipeline.md` | The lean measure-fix round, keeping token draw low, scaling out, Houdini to Godot. |
| `docs/performance.md` | How to measure: a perf harness on a scripted worst case, what to trust, budgets, rules for new effects. |
| `docs/online.md` | The host-authoritative online pattern: messages, budget, latency handling, soak, service layer, credentials. |
| `docs/android.md` | Android debug APK from the cloud box, install, touch control pattern. |
| `docs/agent_dashboard.md` | Agent dashboard set-up and refresh (agents, models, token pull per minute, CI). |
| `tools/ops_board/` | Ops board kit: a reusable Dashboard-type artifact page (`index.html`), `refresh.py` (collects workers, commits, branches, CI runs, checks, assets, goals from any repo with this layout), `schema.md`, `README.md`; `pc/` holds the Windows GPU-box side (PowerShell data builder, Godot probe scripts, test page). |
| `docs/character_creation_lessons.md` | Read before building any humanoid character. |
| `docs/lessons_learned.md` | Generic lessons, grouped by topic. |
| `docs/lessons/` | Game-specific stories: `skate_park.md`, `sandblood.md` (kit only). |
| `kit/project_README.md` | The README a new project gets (kit only). |

Kit-only files (`kit/`, `docs/lessons/`, `tools/new_project.sh`) are not copied into new projects.

## Where lessons live

- `docs/lessons_learned.md`: every generic lesson as a "what happened | rule" row, under Workflow and agents, Testing
  and measurement, Physics and gameplay, Rendering and art, Houdini and assets, Online, Android/touch. New projects
  get this file and add their own rows to it.
- `docs/lessons/<game>.md`: the stories as they happened in one game, with its own names and numbers, and rows that
  only make sense for that game.
- Topic docs carry the longer lessons: `character_creation_lessons.md`, `performance.md`, `online.md`,
  `production_pipeline.md` (Houdini to Godot).

## After each project: add its lessons here

1. Diff the project's `docs/lessons_learned.md` against the kit's. For each new row: if it is generic, reword it
   without the game's names (keep numbers as an example) and add it under the matching heading; skip it if an
   existing row already says it (sharpen that row instead).
2. Put the row as it happened, with the game's names, into `docs/lessons/<game>.md` (create it with a one-paragraph
   description of the game), together with rows that only make sense for that game.
3. Fold tools and docs that proved themselves and are not game-specific into the kit (`__PROJECT_NAME__` /
   `__PROJECT_SLUG__` where the name appears), and update `docs/new_project_checklist.md` and `docs/playbook.md`
   when a lesson changes a step.
4. Run `tools/run_tests.sh` and `tools/lint.sh` in the kit, and `tools/new_project.sh --no-git /tmp/kit_check "Kit Check"`
   followed by the same two checks there, then commit.

No secrets in the kit or in projects: credentials go in git-ignored `config/*credentials*` files (see `docs/online.md`).
