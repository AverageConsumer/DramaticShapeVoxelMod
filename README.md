# Dramatic Shape Voxel Mod

A mod for the [Pokémon Gen 1 Recompilation
Project](https://github.com/bryanthaboi/pokemon-gen1-recomp-project).

The overworld as a voxelized 3D diorama. Also supports experimental first-person and VR.

## Controls

Every key is free-roam only, and each one is also a row on the OPTIONS
menu.

| control | does |
| --- | --- |
| `3`, or the **VOXEL** options row | OFF → 15 → 35 → 50 → 75 → 1ST → OFF (camera pitch) |
| `SELECT` (pad / touch) | the same step as `3` — for the machines with no number row |
| `5`, or the **V-GRID** options row | OFF / ON — a one-pixel wireframe on every voxel |
| `6`, or the **T-SHIFT** options row | OFF → 1 → 2 → 3 → OFF (miniature blur) |
| `7`, or the **V-CURVE** options row | OFF → 1 → 2 → 3 — bend the world over the horizon |
| `8`, or the **3D-BTL** options row | ON / OFF — fight on the map instead of on a white field |
| `9`, or the **WATER** options row | FULL / SKY / OFF — waves and reflections on water. **SKY** gives the surface its pixel-tall wave columns and puts the sky, the sun, the moon and the cast in them; **FULL** adds a screen-space ray march that also reflects the shoreline, the trees and the buildings standing behind it |
| the **BACK SPRITES** options row | OFF / ON — keep your own Pokémon on the battle menu, seen from behind in its classic slot, instead of standing it on the map; the foe is still out there. Only on the menu while **3D-BTL** is on, because it decides nothing without it |
| the **AA** options row | OFF / 2X / 4X — smooth the stair-stepped edges of the 3D world by rendering the diorama larger than the window and folding it back down. The ladder is samples per display pixel: 2X is a canvas root-two wider and taller, 4X one exactly twice the size. Every edge in the projected picture softens with the silhouettes — the tileset's own texels are quads in a perspective view and cross the pixel grid at the same arbitrary angles — so the diorama reads smoother rather than sharper. The most expensive row in the mod, so it is OFF by default and **FULL** leaves it alone |
| the **DAYTIME** options row | SYNC / DAY / NIGHT / DUSK / DAWN / CYCLE — what time it is outdoors, on the diorama *and* on the flat 2D world; held at SYNC (and off the menu) while VOXEL is FULL |

## VR

The **VR** options row (OFF / ON, off by default) drives a PCVR headset
through OpenXR on Windows — SteamVR, Oculus or WMR.

The **SMOOTH TURN** row appears under it while VR is ON (OFF by
default): ON turns the right stick into a continuous turn instead of the
45° snap. The snap is the default deliberately — a software turn moves
the world past a head that did not move, which is the most reliable way
to make somebody ill in a headset — but it costs continuity, so the
choice is yours.

### VR controls

Suggested onto Touch, Index and WMR controllers (rebindable in the
runtime's own binding UI); pad, keyboard and mouse all keep working
alongside.

| control | does |
| --- | --- |
| left stick | move — grid-walks the diorama, free-walks 1ST |
| A / B (X / Y on the left hand) | A / B |
| either trigger | START |
| left stick click | step the VOXEL angle ladder (same as the "3" key) |
| right stick up / down | *diorama only* — zoom the model |
| right stick left / right | *1ST only* — snap-turn 45°, or turn smoothly with **SMOOTH TURN** on |
| grip squeeze + raise / lower that hand | *diorama only* — drag the table's height |
| head | *1ST and battles* — look; FreeMove walks where you look |
| left hand | *1ST and battles* — the Pokédex: menus, dialogs and the 2D battle screen on its screen |

## Licenses

This mod is released under the **MIT License** — see [`LICENSE`](LICENSE).

It redistributes one third-party binary:

- **`assets/vr/openxr_loader.dll`** — the Khronos OpenXR loader
  (version 1.0.10.2, x64, unmodified), © The Khronos Group Inc.,
  licensed under the **Apache License 2.0**. The full license text ships
  alongside the DLL at
  [`assets/vr/LICENSE-openxr_loader.txt`](assets/vr/LICENSE-openxr_loader.txt),
  as the license requires; keep the two files together if you
  redistribute this mod. Source:
  [KhronosGroup/OpenXR-SDK](https://github.com/KhronosGroup/OpenXR-SDK).

Everything else in this mod is original to it, except that the voxel
geometry and shape profiles are derived from the tile and sprite data of
the original game, as documented by the
[pret/pokered](https://github.com/pret/pokered) disassembly. No ROM
data, artwork or audio is included; the mod reads the assets the host
game already has.

Everything the battle screen draws as a box — the two HUD blocks, the text
box and the menus over it — sits on frosted glass rather than on the white
field it used to have behind it: the world underneath, blurred and laid back
down translucent, with the ink flipping white where the ground it lands on is
dark. Nothing the engine draws inside a box moves; only the paper is gone.

### Graphics tuning

The graphics rows leave the original renderer untouched until you choose a
different rung. They remain available while **VOXEL** is **FULL**:

| row | controls |
|---|---|
| **V-PRESET** | ORIGINAL / QUALITY / BALANCED / FAST / BATTERY / CUSTOM |
| **V-RES** | internal 3D resolution: 100 / 83 / 75 / 67 / 50 percent |
| **V-SHADOW** | original adaptive shadow map, fixed 1024 / 768 / 512, or OFF |
| **V-SRATE** | maximum real-shadow refresh rate: LIVE / 60 / 30 / 20 / 15 |
| **V-SOFT** | four-tap soft shadow edges or a one-tap hard edge |
| **V-BUILD** | NORMAL / SMOOTH / MIN terrain-streaming time per frame |

The measured 1080p starting points keep the scene native whenever shadows are
enabled. **QUALITY** uses 512 soft shadows with 60 Hz character updates;
**BALANCED** uses the same image quality at 30 Hz. Both retain **T-SHIFT 3**.
**FAST** keeps native geometry and 30 Hz shadows but switches the soft filter
and T-SHIFT off. **BATTERY** renders at 75%, disables real shadow maps and uses
the lightweight character decals. Every row remains independently adjustable;
changing one marks the aggregate preset as **CUSTOM**.

The first visit to an uncached map may briefly show the original Gen 1 Kanto
Town Map while the current terrain, connected-map bodies and shadow chunks are
prepared. The destination uses the ROM-extracted location coordinates and
blinks under the original cursor; stale asset builds retain the lightweight
**BUILDING KANTO** fallback. Gameplay and input pause behind this cover, and
the builder uses the time as a loading budget. T-SHIFT is temporarily bypassed
for the cover so its pixel art stays sharp, without changing the saved setting.
The outer letterbox uses the same pure black as Gen1Recomp's 4:3 menus; cached
revisits and ordinary crossings remain seamless.

Visible terrain, tall grass and flowers are camera-culled in spatial chunks.
The culler uses the live camera matrix rather than a fixed screen rectangle,
so every gameplay zoom, window aspect and battle camera receives the same
exact-fidelity optimization. A conservative edge guard and whole-mesh fallback
keep geometry from popping at the screen boundary or on limited drivers.
