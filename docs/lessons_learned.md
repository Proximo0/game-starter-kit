# Lessons learned (read before starting work)

Generic lessons from Skate Park (kid-friendly skateboarding) and Sandblood (M-rated physics fighter), both Godot 4.7.2
built by a lead Claude with many subagents. Build guide: https://claude.ai/artifact/WtmrkVRtizP8oJBRwhxdWW.
The full game-specific stories behind some rows are in the starter kit repo, `docs/lessons/skate_park.md` and
`docs/lessons/sandblood.md`.

Add a row under the matching heading whenever something goes wrong: what happened (one line, with numbers when you
have them) and the rule that prevents it. At the end of the project, copy the generic rows back into the starter kit
(`docs/playbook.md`, section 4).

## Workflow and agents

| What happened | Rule |
| --- | --- |
| Subagents messaged the user directly | Never call `mcp__hearthbot__` tools. Report only to the lead. |
| A global `flock` around every Godot run deadlocked agents | Only `godot --import` takes `/tmp/<project>_import.lock`. Never wrap `tools/*.sh` in flock. |
| Sub-orchestrator agents had no Agent tool | Nested fan-out needs the Workflow tool, or the lead starts every worker. |
| 4 cloud cores capped how many checks and agents could run Godot at once | Use `tools/check_all.sh` locally and the GitHub Actions matrix (`checks`) for scale. Keep local workers to about 8 (every worker runs the engine); run more as remote cloud agents, each on its own machine and branch, merged by the lead after the gate. |
| `git commit -a` pushed another worker's half-finished file | The lead stages files by name while workers are editing. |
| Untracked new files from a finished worker vanished from the shared tree while other workers were still running | Commit a finished worker's files promptly, or back them up first. Workers never run git at all (no clean, stash, checkout or reset) and never delete files they did not create. |
| Unit tests passed in the working tree but failed in CI, and mid-flight workers left the tree red while CI linted the pushed tree | Other workers' uncommitted edits hide failures. The lead copies finished files into a clean clone (`/tmp/<project>_build`) or a `git worktree` of HEAD, runs lint, tests and sims there, commits by name and pushes from it. |
| A worker typed a parameter as a contract class that was not committed yet; CI lint failed on the pushed tree | Code against an uncommitted contract class with duck typing (`Node3D`), and lint a clean clone before pushing. |
| The lead pushed a red tree: `(lint; tests; sims) && git commit` only checks the last command of the subshell | Gate commits on the summary lines (`failed=0`, `problems=0`), not on a subshell exit code. |
| A worker reported "sims and bot skipped as instructed" when the brief asked for them | The lead reruns `check_all` and the bot before every commit of physics-adjacent files. |
| Container restarts killed running workers three times | Workers leave WIP in the tree; relaunch on that WIP with the prior findings in the prompt, never from scratch. |
| A worker cleared its own hung Godot with `pkill godot` and killed another worker's render | Kill only your own PIDs (`kill <pid>`); never `pkill godot` while other workers run. |
| A worker reported a shared test failing in a file it did not touch; the cause was a concurrent worker (a tuning row made a filter match two groups; a data file length change broke a data test) | Before fixing a failure outside your files, check whether another worker's recent change caused it, and tell that worker. |
| A finished background worker sent duplicate hand-back reports | Stop a finished worker (TaskStop) once its work is integrated. |
| Two commit hashes were misquoted in reports | Report a commit hash only after the push has returned it. |
| The owner had to read long replies to see project state | Keep a Dashboard artifact fed by uploaded JSON (agents, commits, checks, perf, balance), refreshed at each merge (`docs/agent_dashboard.md`). |
| Remote Control on the owner's PC refused a guarded action (e.g. git push) approved only through the lead | Actions its permission check guards need the owner's own words in that session; ask them to type the approval there. |

## Testing and measurement

| What happened | Rule |
| --- | --- |
| Feel bugs were found by the player, not by us | Build the debug layer and the bot before content: tunables, debug frame, snapshot/replay, recorder, overlay, lab, bot. |
| A fix looked plausible but the bug predated the changed code | Check git history for when a bug first appeared. |
| A lab WARN almost undid a design choice the player wanted | Check a WARN against the player's stated wishes before tuning it away. |
| Evaluators reported bugs that were capture artefacts (a bot teleport wiped open state; a UI element caught mid-fade) | Before fixing an evaluator finding, reproduce it in the live scene; bots wait for open state to settle before teleporting. |
| Balance work started from stale numbers after an AI change | Re-measure the baseline on the current tree before tuning; numbers go stale after any AI or physics change. |
| A bot run hung 15 min and wrote 334 MB: another worker's half-saved shared script failed to parse, so every tick errored | Watch a long bot run's log size or error lines, not just its exit; re-run balance after a shared script stops changing. |
| A rate-per-second sim check failed on a 4 s bot fight: the opening clash and a finisher burst inflated the mean | Divide rates by a floor duration (e.g. 8 s) so short runs do not inflate them; bursts belong to a max/s check. |
| Mid-run restore of a physics match diverged (0.2 m after 1 s) though idle restore and fresh starts were exact | Record runs as seed + inputs from tick 0 and replay from the start; treat mid-run restore as approximate. |
| A bot tool reported a false "crash" on big outputs | Under `set -o pipefail`, `echo "$out" \| grep -q` fails when grep exits early (SIGPIPE). Use a here-string: `grep -q pat <<<"$out"`. |
| A perf tool averaged `Performance.TIME_PROCESS` per frame and reported 36 ms vs a real 5.2 ms: that monitor updates about once a second with the slowest frame, and the first run included shader compiles | Time real frames (ticks between frames, p50/p95/max) after a warm-up; never average a once-per-second monitor. Profile on a real GPU: the cloud box renders in software GL (`docs/performance.md`). |
| Per-frame timing was noisy and misleading: a first run after `--import` was 4x slower, a gap shrank on rerun, and with `--fixed-fps` and vsync off game time ran faster than wall time | Warm up before measuring and rerun a gap twice before hunting it. Report game time and wall time. Time frames with `Time.get_ticks_usec()` in a lowest-priority node (mean, p95, max) and track the worst frame per match. |
| Per-script cost was unknown without the editor profiler | In the measured window call `set_process(false)` on scripted nodes and call each `_process` from one timing node, summing by script path. |
| A texture pool re-stamped 30x a second at an unchanged radius (25 ms in the worst case), and a per-texel loop called three sines | Time sections in a scripted worst case (`perf.sh --heavy`) before guessing; gate repeated work on a changed input, hoist per-texel trig into a table. |
| A soak of 50+ back-to-back bot matches on real hardware found per-match hitches (63 ms at each match start, one 596 ms first-use shader compile) | Run a long soak on real hardware before release; pre-warm materials, shaders and pools during the intro. |
| Heavy GPU/CPU jobs run in parallel on one laptop distorted each other's results | Run heavy jobs one at a time on one machine. |
| Net sims and tests opened fixed ports, so two suites on one machine failed with "Could not listen on port", and two matchmaking runs found each other's peers | Sims take ports from `net_port(slot)` in `tests/sim/sim_base.gd` (a 64-port block per OS process id plus a slot). Never write a literal port in a test. |
| `check_all.sh` logged to a shared `/tmp/check`, so two runs overwrote each other's logs, and it ended on a table with no single verdict | Each run logs to its own `mktemp` dir; the last line is `CHECK_ALL PASS` or `CHECK_ALL FAIL`, and the exit code matches. |

## Physics and gameplay

| What happened | Rule |
| --- | --- |
| Wall ends were accepted as floor (`floor_max_angle` 80°), so a fake launch cut speed to 15% | Measure snags with a sweep tool (`tools/snag_sweep.sh`), then fix the traced mechanism. |
| Ramps had knife-edge side walls under 0.3 m | Piece rule: no collision edge under the character's radius, side walls run below ground, no coplanar floors. |
| A z-fighting floor pad | Lift the visual mesh, never the collider. |
| Same-seed physics runs split late in about 40% of fresh runs; a second match in one process always diverged | Jolt's contact order is thread-dependent: sort contacts before first-per-key debounce, and run each same-seed repeat in a fresh process. |
| A dynamic prop with a one-sided layer/mask became an immovable block that pinned a character for 40 s | Give dynamic props symmetric masks, or no layer at all; never one-sided. |
| An AI attack never hurt: it aimed open-loop and moved slower than the damage threshold | Steer AI actions on the measured result (closed loop) and check speeds against the damage thresholds. |
| A win rule had no fallback for its zero case, so every time-out of one match type was a draw | Every judge or scoring rule needs a fallback when its main measure is level. |
| A brief's threshold could never fire because it was normalised against the wrong range | Normalise between the real limits (the death line and full) and check a new threshold against the existing ones. |
| Active-ragdoll characters looked tiptoe and floating: the body was pushed while legs were posed from a sine phase, so PD-lagged legs trailed a stride behind (planted foot pitch 48°, slip 1.9 m/s) | Plan feet in world space (planted feet hold, land where the foot really is), move feet with a PD force whose reaction goes on the pelvis, and measure gait with a probe script before tuning. |
| Tucking legs on a timer while standing made a roll hop, and turning about the pelvis vaulted it into a handstand | Dip on planted feet first, tuck only once low, and let the support hold only part of the weight while tucked. |

## Rendering and art

| What happened | Rule |
| --- | --- |
| A GPU glitch was blamed on a guess | Sample screenshot pixels and reproduce first. If it can't be reproduced, ship toggles. |
| A `-s` render script couldn't see autoloads | `load()` game classes inside a deferred call. |
| Shader compile failed: `MODELVIEW_MATRIX` used in a fragment shader; a disc rendered culled | `MODELVIEW_MATRIX` is vertex-only (use `VIEW_MATRIX * MODEL_MATRIX` in fragment); Godot front faces wind clockwise. |
| Hand-built meshes were inside out but looked fine in previews (previews draw both sides) | Check face direction numerically (normals against the outward direction) on any hand-built mesh. |
| A toon shader blew lit surfaces out to flat colour: the light term ignored that `LIGHT_COLOR` already includes PI, and a white rim was added on lit faces | Normalise light so lit albedo ≈ albedo; check every shared-shader change on level, character and UI renders. |
| Thin decorative meshes cast hard shadow streaks; a cool sky ambient made warm ground read green in shadow | Only big shapes cast shadows; use a warm ambient on warm ground and sample shadow hues before blaming shaders. |
| A shader-hidden crowd twin (`VERTEX *= 0`) still cost its vertices, and Godot's primitive counter ignores MultiMesh instances, so the crowd looked cheap | Cut instances with `visible_instance_count`; count MultiMesh triangles yourself and time script cost separately. |
| Distant crowds and props cost too much | Visibility ranges (HLOD) work on `MultiMeshInstance3D`; use decimated meshes or impostors at distance. |
| Match-start hitches from first-use shader compiles (Godot 4.4+ ubershaders precompile only what is loaded at load time) | Instance every effect resource once off-screen at match start; keep GPU perf on real hardware (xvfb skews GPU frame times) and CI on draw calls, primitives and script time. |
| A humanoid character was rebuilt ten times (code lofts, Blender, Houdini, polish passes) and still read as a placeholder | Never sculpt humanoids in code. Start from a creator-made or licensed model on a standard humanoid skeleton; follow `docs/character_creation_lessons.md`. |

## Houdini and assets

| What happened | Rule |
| --- | --- |
| The cloud proxy blocked many asset sites, discovered late | On day one, test-download one file from each asset source; if blocked, fetch through the owner's machine into an asset branch. |
| An asset's polish was thrown away by the game's loader | Before building an asset the game will use, read the importer or loader code and check which data survives it. |
| Two instances of one glb shared a cached `Mesh`; per-instance override materials errored at teardown | Duplicate an instanced glb's mesh before setting surface override materials. |
| Houdini's glTF ROP exported every material as `alphaMode BLEND` | Force imported art opaque on import (or set it in the ROP) and assert `alphaMode` in the exporter test. |
| Houdini build scripts failed on missing folders (`hipFile.save` included) and drifted through copy-pasted helpers | Create hip/export/preview folders first; share helper libs (`LIB`, `read_glb`) instead of copying; every build script takes `--only=<ids>` and `--no-preview`. |
| Emissive parts blew out to white in previews | Use modest emission or a dark preview background. |
| Armor looked fitted by bounding-box overlap but clipped the body | Check fit radially: distance to the part axis minus radius >= 0. |
| Named attachment empties were lost in glTF export, and mirrored parts came out inside-out | Export in object mode (objpath + objects) with null OBJs for named empties; mirror with a negative-scale Transform plus a Reverse SOP. |
| Impostor cards and reduced meshes lost their tint masks | PolyReduce keeps vertex-colour masks; render impostor cards with flat light so masks stay tintable. |
| PowerShell 5 wrote JSON with a UTF-8 BOM that parsers rejected | Write JSON without a BOM (`[IO.File]::WriteAllText` with `UTF8Encoding($false)`). |
| A local Godot version bump rewrote every `.import` file | Never commit that churn; revert the `.import` files before staging. |

## Online

| What happened | Rule |
| --- | --- |
| Closing an ENet peer from inside its own `poll()` (a disconnect signal handler) crashed with signal 11 | Never close a MultiplayerPeer from its own signal; defer the close to the next idle frame. |
| ENet's packet throttle silently dropped about half the unreliable snapshots after a frame hitch | Switch the ENet throttle off on connect (deceleration 0) for snapshot streams. |
| A reliable events packet could exceed a relay's 1164-byte limit and was silently dropped | Split network packets by bytes under the relay limit, not by record count. |
| A net soak recorded the host pose one tick off the snapshot's stamp, tripling every measured error | Record the reference state at the exact tick the snapshot is stamped with; sanity-check a new harness on a clean link first. |
| An online-service plugin's create-user login path fired no login callback, so the runtime never learned the local user | Log in a second time after creating the device user; mock a plugin's native singleton to run its real GDScript without the binaries. |
| Secrets (online service client keys) must ship in builds but not in a public repo | Keep them in a git-ignored `config/*credentials*` file injected by the export script; never write them to memory or docs (`docs/online.md`). |

## Android/touch

| What happened | Rule |
| --- | --- |
| `dl.google.com` is blocked in the cloud sandbox, so the Android SDK could not be installed the usual way | `tools/export_android.sh` assembles JDK 17 and the SDK tools from distro packages under `$HOME`; on a real machine set `ANDROID_SDK_ROOT`. |
| The Android export refused to run | Keep `textures/vram_compression/import_etc2_astc=true` in `project.godot` (the kit has it). |
| An APK has no folder beside it, so a credentials file copied next to the build never reached the phone | Put the git-ignored credentials file in the Android preset's `include_filter`; the export script warns when it is missing. |
