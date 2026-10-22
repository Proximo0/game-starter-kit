# Sandblood lessons for the starter kit (MSI laptop, 2026-10-22)

Lessons from today's local runs (Houdini 22 asset builds, Godot 4.7.2 real-GPU perf, soak). Each row: what went wrong
or surprised us, then the rule for the starter kit and production pipeline.

## Measurement

| What happened | Rule |
|---|---|
| `perf.sh` reported 35 ms/frame on low; real frames were 5 ms. `Performance.TIME_PROCESS` updates about once a second and reports that second's slowest frame, so averaging it per frame mostly repeats spikes. | Time real frames yourself: `Time.get_ticks_usec()` between `_process` calls in a node with the lowest `process_priority`. Report mean, p95 and max of those. Use monitors only as once-per-second context. |
| The first perf run after `--import` paid one-time shader compiles and read 4x slower than a rerun. | Do one warm-up run (or warm up shaders in-scene) before measuring, and never compare a cold first run with a warm one. |
| A "missing 24 ms" hunt nearly started on a phantom. | Before profiling, rerun the number twice. A gap that vanishes on rerun was the measurement. |
| Per-script cost was unknown. | Profile by takeover: at the measured window, `set_process(false)` on every scripted node and call its `_process` from one node with timers around each call; sum by script path. Cheap, needs no editor debugger, and works in a release-like run. |
| With `--fixed-fps 60` and vsync off, game time runs faster than real time, so a "10-minute soak" covers far more game time. | Report both wall time and game time (ticks / 60) per fight. |
| Every fight had one ~63 ms hitch, and one fight had a 596 ms hitch at match start. | Track worst frame per match in soaks, not just averages; pre-warm what a new match loads. |

## Houdini → Godot asset pipeline

| What happened | Rule |
|---|---|
| Houdini 22's glTF ROP writes `alphaMode: BLEND` on every Principled material, even fully opaque ones. In Godot that can sort and flicker. | Force opaque on import (import script or material override), or patch the glb's alphaMode after export. Check `alphaMode` in the export checker. |
| An emissive laser blade rendered pure white on Karma's white preview background, so the preview looked bladeless while the mesh was fine. | Keep emissive intensity modest in previews (about 1.5) or render glowing parts on a dark background; confirm the mesh from bbox and tri count, not the picture. |
| `hou.hipFile.save()` failed in a fresh folder: the `hip/` directory didn't exist. | Every build script makes its output, preview and hip folders first. |
| Copy-pasting the geometry helpers between build scripts drifts. | New build scripts load the shared `LIB` and `read_glb` from `build_weapons.py` (or one shared module) instead of copying them. |
| A box-overlap fit check said armor clipped when it didn't, and missed a knee boss that really cut into the shin. | Check armor fit radially: the minimum distance from armor points to the body part's axis (or the head centre) minus the part radius, over the part's span. Must be ≥ 0. |
| The glTF ROP only writes empties (attach points) in object mode. | For named attach points (weapon-rack slots), parent null OBJs to the geo and export with `objpath` + `objects`, not `soppath`; the checker confirms the node names. |
| Mirrored left/right parts flipped their winding. | Mirror with a negative-scale Transform followed by a Reverse SOP. |
| Building only what changed keeps runs short. | Every build script takes `--only=<ids or group>` and `--no-preview`. |
| Crowd LODs need region masks to survive reduction. | PolyReduce keeps vertex colour; the impostor card is rendered from LOD0 with flat, even light so the R/G/B region masks stay tintable. |

## Running work on a local machine from a project chat

| What happened | Rule |
|---|---|
| A git push approved by the owner but relayed through the coordinator session was refused twice by the local auto-mode safety check. | A push from a remote-controlled PC needs the owner's own words in the thread, or a permission rule set by the owner. Ask for that up front when a job ends in a push. |
| GPU benchmarks and Houdini renders on one laptop fight over the CPU. | Run heavy jobs one at a time; write scripts in parallel while a run is going. |
| PowerShell 5 writes UTF-8 with a BOM, which some JSON readers reject. | Write data files with `[IO.File]::WriteAllText(path, text, New-Object Text.UTF8Encoding $false)`. |
| Godot 4.7.2 rewrote every `.import` file in an older checkout. | Don't commit `.import` churn from a local engine-version bump; stash it or match the project's engine version. |

## Workflow improvements found on the web

- CORRECTED: Godot 4.4+ ubershader pipeline precompilation covers Forward+ and Mobile only, NOT the Compatibility (OpenGL) renderer this game uses. So every gore material, particle and decal must be drawn once (in view for a frame, behind a loading screen) during load, or it compiles on first use mid-match. Source: Godot docs, "Reducing stutter from shader (pipeline) compilations" (4.7).
- Visibility ranges (HLOD) work on MultiMeshInstance3D, and the documented pattern is to swap to an impostor at distance. This fits the new crowd LOD set: LOD0 to LOD2 meshes up close, the impostor card for far tiers. Source: Godot docs, "Visibility ranges (HLOD)".
- Headless CI runs can't time real GPU frames; xvfb software rendering skews them. Keep GPU perf on a real-GPU machine (like this laptop) and keep CI to draw calls, primitives and script time. Sources: gdUnit4Net discussion #350, and the agent-skill guides on Godot benchmark gates.
- Houdini's glTF ROP had known alpha export gaps (per-point alpha fixed in a later major release), so keep the BLEND check in our own exporter tests. Source: SideFX forum "GLTF point Alpha export".
