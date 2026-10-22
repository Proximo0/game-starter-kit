# Sandblood: game-specific lessons

Sandblood (working title Gladiator): an M-rated, physics-driven 1v1 melee fighter in a sand arena, in the spirit of
Half Sword (active-ragdoll fighters, the weapon hand steered by mouse, stick or touch, damage from how the weapon
connects, per-part armor, gore). Godot 4.7.2 with Jolt; CPU opponent, local 2P, online 1v1 over ENet with an EOS
service layer; Windows, Mac, Linux and Android. These are the stories as they happened, with the game's own names and
numbers, plus rows that only make sense for this game. The generic rule for each is in `docs/lessons_learned.md`.

| What happened | Rule |
| --- | --- |
| The brief said finishers start at `blood / 5.0 < 0.4`, but death is at 2.5 L, so it could never fire | Normalise between the death line and full (`health.blood_frac()`); check a new threshold against the existing ones. |
| Thin poles and an awning cast hard streaks across the sand | Only fighters, walls and big shapes cast shadows; thin decorative meshes don't. |
| Owner saw "green blood": shadows on orange sand read olive/teal because the only fill light was a blue sky ambient, and damp sand darkened the warm part | Use a warm colour ambient in a sand arena and sample shadow pixel colours (hue) in renders before blaming the blood shaders. |
| A worker typed a parameter as `Fighter` before that class was committed; CI lint failed on the pushed tree | Code against an uncommitted contract class with duck typing (`Node3D`), and lint a clean clone before pushing when workers are mid-flight. |
| Mid-fight restore of a melee diverges (0.2 m after 1 s) though idle restore and fresh starts are exact | Record matches as seed + inputs from tick 0 and replay from the start; treat mid-fight restore as approximate. |
| Same-seed bot matches split late in about 40% of fresh runs; a second match in one process always diverged | Jolt's contact order is thread-dependent: sort contacts before first-per-key debounce. Run every same-seed repeat in a fresh process. |
| A knocked-off armor prop had a layer the fighters scan but a mask that ignored them; Godot made it an immovable block that pinned a fallen fighter's thigh for 40 s (seed 5007) | Give dynamic props symmetric masks, or no layer at all; never one-sided. |
| Round 4 started from round 3's numbers (126 hits/min), but the arena-footwork brain change had already moved them to 95 | Re-measure the baseline on the current tree before tuning; numbers go stale after any brain or physics change. |
| Spear AI aimed open-loop and thrust from walking speed, so its "thrusts" were sub-3 m/s shaft touches (0 wins of 10) | For long weapons, steer on the measured blade line and check speed against `damage_min_speed`; reach comes from footwork, not arm extension. |
| Fist fights could never be won: no bleeding, and the time-out judge only compared blood | Every win rule needs a fallback for its zero case (level blood falls back to body hp). |
| Two fighters with the same weapon shared one cached glb `Mesh`; per-instance override materials on a shared mesh gave `Parameter "material" is null` at teardown | Duplicate an instanced glb's mesh before setting surface override materials. |
| A bot run hung for 15 min and wrote a 334 MB log: another worker's half-saved `fighter_brain.gd` failed to parse at launch, so every tick errored | Watch a long bot run's log size or error lines, not just its exit; re-run balance after a shared script stops changing. |
| A shader-hidden crowd twin (`VERTEX *= 0`) still cost its vertices (515k triangles per frame through the vertex stage), and the primitive counter ignores MultiMesh instances | Cut instances with `visible_instance_count` (`CrowdCull`), decimate far tiers, count MultiMesh triangles yourself. |
| A sand pool re-stamped the sand 30x a second at an unchanged radius (25 ms at high in the worst gore case), and a per-texel loop called three sines | Time sections in a scripted worst case (`perf.sh --heavy`); repaint only after the edge grew `POOL_MIN_GROW`; one 256-entry edge table per call. |
| A rate-per-second sim check failed when a bot fight ended in 4 s: the opening clash and finisher burst made the mean 36/s | Divide rates by a floor duration (8 s) so short fights do not inflate them; bursts belong to the max/s check. |
| `perf.sh` averaged `Performance.TIME_PROCESS` per frame and reported 36 ms on low (real: 5.2 ms) | Time real frames (ticks between frames, p50/p95/max) after a warm-up; never average a once-per-second monitor. |
| Fighters looked tiptoe and floating: the pelvis force carried and pushed the body while the legs were posed from a sine phase, so the PD-lagged legs trailed a stride behind with toes on the sand (planted foot pitch 48°, contact slip 1.9 m/s walking) | Plan feet in world space (`GaitLogic`: planted feet hold, land where the foot really is), move feet with a PD force whose reaction goes on the pelvis, and measure gait with `out/loco_probe.gd` before tuning. |
| Tucking legs on a timer while standing made the roll hop, and turning about the pelvis vaulted it into a handstand | Dip on planted feet first, tuck only once low, and let the support hold only part of the weight while tucked. |
| Closing the ENet peer from inside its own `poll()` (a disconnect signal handler) crashed with signal 11 | Never close a MultiplayerPeer from its own signal; defer the close to the next idle frame. |
| ENet's packet throttle silently dropped about half the unreliable snapshots after a frame hitch | Switch the ENet throttle off on connect (deceleration 0) for snapshot streams. |
| A reliable events packet could exceed the EOS relay's 1164-byte limit and be silently dropped | Split network packets by bytes, not by record count (`NetEvents.encode_chunks`). |
| EOSG's create-user login path fires no Connect login callback, so the runtime never learned the local user | Log in a second time after creating the device user; mock a plugin's native singleton to run its real GDScript without the binaries. |
| The first net soak recorded the host pose one tick off the snapshot stamp, so every error read about 3x too high (weapon tip p95 looked like 16 cm, really about 2 cm) | `sim_net_soak` records at `ht + 1`; a one-tick reference shift is the first thing to rule out in a new soak. |
| A press-once button (roll, grab) on a client tick the host skipped never played; with the client's packets gone the host repeated its last input for 5 s | `NetInputBuffer` carries press-once bits onto the next tick played; after `INPUT_STALE_TICKS` (12) quiet pops movement and buttons go neutral. |
| A soak of 50+ back-to-back bot fights on real hardware found per-match hitches (63 ms at each match start, one 596 ms first-use shader compile) | Pre-warm every gore/FX resource off-screen during the intro. |
| Container restarts killed running workers three times | Workers leave WIP in the tree; relaunch a worker on that WIP with the prior findings, never from scratch. |
| Houdini 22's glTF ROP exports every material as `alphaMode BLEND` | Force imported art opaque (or set it in the ROP); `hipFile.save` needs its folder made first; run Houdini builds with `--only=<ids>`. |
| Remote Control on the user's PC refused a git push approved through the lead | Actions on the user's PC that its permission check guards need the user's own words in that session; ask them to type it there. |
| Net sims and tests opened fixed ports (17931, 17941, 17961, 17981, discovery 17790..97, the stub's 7777), so two suites on one machine failed with "Could not listen on port 17961", and two Quick Match runs could even find each other's peers by UDP | Sims take ports from `net_port(slot)` in `tests/sim/sim_base.gd`; the stub reads `--net-port`; the game's default port is unchanged. |
