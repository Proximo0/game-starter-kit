# Skate Park: game-specific lessons

Skate Park: a kid-friendly, cartoony skateboarding game in the spirit of Tony Hawk's Underground 2 (Godot 4.7, one
skatepark, full trick controls, placeholder art behind art slots). These are the stories as they happened, with the
game's own names and numbers, plus rows that only make sense for this game. The generic rule for each is in
`docs/lessons_learned.md`; the character saga is in `docs/character_creation_lessons.md`.

| What happened | Rule |
| --- | --- |
| Wall ends were accepted as floor (`floor_max_angle` 80°), so a fake vert launch cut speed to 15% | Measure snags with `tools/snag_sweep.sh`, then fix the traced mechanism. |
| A lab WARN almost undid a design choice (strong halfpipe pump) | Check a WARN against the player's stated wishes before tuning it away. |
| A z-fighting floor pad | Lift the mesh, never the collider (`PieceKit.floor_pad`). |
| Ramps had knife-edge side walls under 0.3 m | Piece rule: no collision edge under the skater's radius, side walls run below ground, no coplanar floors. |
| A gap needing MANUAL at its start was unreachable: the rider enters the zone in AIR, then lands into the manual inside it | `Gaps.start_in_zone` runs on every state change for zones the rider is inside; size start zones to cover where the landing happens. |
| Character took four rounds: a primitive look, 1.25 m tall, barrel chest, low clipping bust, garments clipping the legs | Follow `docs/character_creation_lessons.md`: research references, write a numeric spec, size the skeleton to it, use elliptical lofts, offset garments from skin sections, check a pose grid. |
| Character remade six more times (code lofts, Blender, Houdini, polish passes) and still read as a placeholder | Never sculpt humanoids in code. Start from a creator-made or licensed model (VRoid/VRM), standard humanoid bone names, test asset-site downloads on day one. See `docs/character_creation_lessons.md` round two. |
| Untracked new files from a finished worker vanished from the shared tree while other workers were still running (`secondary_motion.gd`) | Commit a finished worker's files promptly, or back them up to `/tmp/lead/backup/` first. Tell workers never to run git clean, git stash -u or checkout on the shared tree. |
| Polish passes: evaluators reported "score stays 0" and "grey speech bubble" that were capture artefacts (bot teleports wiped open combos; a bubble caught mid-fade) | Before fixing an evaluator finding, reproduce it in the live scene; have bots wait for open combos to land before teleporting and log `landed_total`. |
| Toon shader: ramps blew out to flat yellow because the toon light term ignored that `LIGHT_COLOR` already includes PI, and a white rim was added on lit faces | Normalise light so lit albedo ≈ albedo; check every shared-shader change on park, skater and shop renders. |
| A worker reported "sims and bot skipped as instructed" when the brief asked for them | The lead reruns check_all and the bot before every commit of park, camera or physics-adjacent files. |
| Unit tests passed in the working tree but failed in CI | Other workers' uncommitted edits hide failures. Run the full suite in a clean `git worktree` of HEAD before committing. |
| `tools/bot_run.sh` reported a false "crash" on big outputs | Under `set -o pipefail`, `echo "$out" \| grep -q` fails when grep exits early (SIGPIPE). Use a here-string: `grep -q pat <<<"$out"`. |
| The art direction changed mid-build: kid-friendly became a Teen or M rating | Ask for the target rating and tone on day one and write it into memory and the art spec. |
