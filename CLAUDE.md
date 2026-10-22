# __PROJECT_NAME__ (Godot 4.7.2, GDScript)

<!-- KIT-ONLY: this is the CLAUDE.md template for projects made with tools/new_project.sh, which fills in the name and drops this line. Working on the kit itself: see README.md. -->
<!-- One paragraph: what the game is, who it is for, what v1 is. Replace this line. -->

## Commands
- `tools/run_tests.sh [test_name]`: headless unit tests (`tests/unit/test_*.gd`). Prints failures only.
- `tools/lint.sh`: parse and static checks for every script. Ends with `LINT problems=<n>`.
- `tools/run_sims.sh`: regression sims (`tests/sim/sim_*.gd`, listed in `tests/sim/sim_suite.gd`).
- `tools/check_all.sh`: everything at once (unit, sims, lint, plus the bot and lab if their scenes exist).
- `tools/export_windows.sh`: Windows build zip in `build/`. `tools/export_android.sh`: debug APK in `build/`.
- Run the game: `godot --path .` (add `-- --dev` for dev entries, `-- --stamp` to show the frame stamp).

## Layout
- `game/autoload/`: `Flags` (run flags, frame counter, state hash), `Controls` (input actions).
- `game/debug/`: frame stamp (F10), render toggles (F4, F6-F9), `Tuning` (live-tunable numbers).
- `game/<system>/`: one folder per system.
- `tests/unit/`: one `test_<module>.gd` per module, `extends TestCase`. `tests/sim/`: regression sims.
- `tools/`: shell and Python tools. Python uses the standard library only.
- `docs/`: `playbook.md` (kickoff, fan-out, measure-fix loop), `agent_brief.md` (contracts and subagent rules),
  `lessons_learned.md`, `new_project_checklist.md`, `production_pipeline.md`, `performance.md`, `online.md`,
  `android.md`, `agent_dashboard.md`, `character_creation_lessons.md`.

## Rules
- Static typing everywhere: typed vars, params and returns. Tabs for indentation.
- Gameplay logic is pure `RefCounted` classes with `class_name`, no Node, no wall clock, no `randf()`: take `delta`
  and a seeded `RandomNumberGenerator`. Nodes are thin wrappers that feed them input. Put pure logic in
  `game/logic/` (or edit `PURE_PREFIXES` in `tools/lint.py`).
- Gameplay numbers live in `Tuning` (or data files), never as literals in logic.
- Every logic module has a unit test file. A change is done when `tools/run_tests.sh` and `tools/lint.sh` pass.
- File-local helper names must be unique across the project (one `class_name` space).
- Tools are quiet: print errors and failures, then one summary line.
- Scripted shots key on game state (an observed condition) with a time fallback, never fixed seconds alone.
- Compare state hashes only on frames where `Flags.commands == 0`.
- Captures, tests and gates never write player data (`Flags.is_scripted_run()`).
- No secrets in git: credentials live in git-ignored `config/*credentials*` and are injected at export.
- Reproduce a bug (test, sim, bot, replay) before fixing it; fix the traced mechanism, not a guess.
- Read `docs/lessons_learned.md` before starting; add a row whenever something goes wrong.
