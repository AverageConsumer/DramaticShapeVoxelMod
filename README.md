# Dramatic Shape Voxel Mod

> [!IMPORTANT]
> This is an **unofficial Android-only Kanto Gear performance fork**, based on
> Dramatic Shape Voxel Mod 1.5.5. We love the original mod: on PC, use the
> [official project](https://github.com/DramaticShape/DramaticShapeVoxelMod).
> This package exists because Android handhelds need additional frame-pacing
> work. It belongs to the tested
> [Kanto Gear](https://github.com/AverageConsumer/kanto-gear) release set and is
> verified on an AYN Thor. Comparable Android handhelds are intended targets,
> but their performance and driver behavior still need community testing.

A mod for the [Pokémon Gen 1 Recompilation
Project](https://github.com/bryanthaboi/pokemon-gen1-recomp-project).

The overworld as a voxelized 3D diorama, with the original project's
first-person, third-person, staged-battle and VR features preserved.

## Install on Android

Download `DRAMATIC_SHAPE-1.5.5-android.1.zip` from this repository's release page and
import it through **MODS > Import mod .zip**. Remove the official Voxel Mod
first if it is installed; both packages intentionally use the same mod ID.
Confirm the experimental-mod warning and enable it. A fresh setup starts at
**VOXEL 35**, **BALANCED**, **T-SHIFT 3** and **V-CURVE OFF**; existing saved
choices remain untouched.

This fork does not offer launcher updates. Install the matching Kanto Gear
release set manually so an upstream package cannot replace its Android fixes.

## Performance fork scope

This fork keeps the upstream renderer and adds cooperative terrain builds,
camera-culling for spatial mesh chunks, split static/dynamic shadow updates,
deferred mesh release and optional graphics presets. These changes primarily
target stalls and frame pacing rather than promising a higher average FPS.
The unrelated upstream Horde minigame is not activated in this Android build.

Known on the tested Thor: fancy water with V-CURVE can fall back to ordinary
animated water tiles. This fork does not carry a separate workaround.

## Controls

Every key is free-roam only, and each one is also a row on the OPTIONS
menu.

| control | does |
| --- | --- |
| `3`, or the **VOXEL** options row | OFF → 15 → 35 → 50 → 75 → 1ST → 3RD → OFF (camera pitch) |
| `SELECT` (pad / touch) | the same step as `3` — for the machines with no number row |
| `5`, or the **V-GRID** options row | OFF / ON — a one-pixel wireframe on every voxel |
| `6`, or the **T-SHIFT** options row | OFF → 1 → 2 → 3 → OFF (miniature blur) |
| `7`, or the **V-CURVE** options row | OFF → 1 → 2 → 3 — bend the world over the horizon |
| `8`, or the **3D-BTL** options row | ON / OFF — fight on the map instead of on a white field |
| `9`, or the **WATER** options row | FULL / SKY / OFF — waves and reflections on water. **SKY** gives the surface its pixel-tall wave columns and puts the sky, the sun, the moon and the cast in them; **FULL** adds a screen-space ray march that also reflects the shoreline, the trees and the buildings standing behind it |
| the **BACK SPRITES** options row | OFF / ON — keep your own Pokémon on the battle menu, seen from behind in its classic slot, instead of standing it on the map; the foe is still out there. Only on the menu while **3D-BTL** is on, because it decides nothing without it |
| the **AA** options row | OFF / 2X / 4X — smooth the stair-stepped edges of the 3D world by rendering the diorama larger than the window and folding it back down. The ladder is samples per display pixel: 2X is a canvas root-two wider and taller, 4X one exactly twice the size. Every edge in the projected picture softens with the silhouettes — the tileset's own texels are quads in a perspective view and cross the pixel grid at the same arbitrary angles — so the diorama reads smoother rather than sharper. The most expensive row in the mod, so it is OFF by default and **FULL** leaves it alone |
| the **DAYTIME** options row | SYNC / DAY / NIGHT / DUSK / DAWN / CYCLE — what time it is outdoors, on the diorama *and* on the flat 2D world; held at SYNC (and off the menu) while VOXEL is FULL |

## Free-roam cameras (1ST / 3RD)

The last two rungs of the **VOXEL** ladder are experimental, and they are
the same camera: **1ST** stands it in the player's own eyes, **3RD** pulls
it back onto a boom behind their shoulder. Both steer, and on both the grid
walk is replaced by continuous camera-relative movement — push in any
direction and you go there, at any angle, not just along the four compass
lines. Collision, warps, ledges, encounters and scripts all still run
through the engine's own machinery.

| control | does |
| --- | --- |
| mouse | look (the cursor is captured; left click is A, right click is B) |
| right stick | look |
| a touch drag off the overlay's controls | look |
| left stick / touch d-pad / arrow keys | walk, relative to where the camera looks |
| wheel, `Q` / `E`, pinch, or a stick click | **3RD only** — let the boom out and pull it in (`Q` and left stick click out, `E` and right stick click in) |

On an **orbit rung** the same wheel, `Q`/`E` and pinch drive the engine's own
survey zoom. On **1ST** they do nothing at all: the eye is in your head, and
there is no distance to change.

On **3RD** the boom shortens against whatever is behind you, so backing into
a wall walks the camera in to your shoulders rather than through it — squeeze
it all the way in and the view is 1ST until you step clear. The character
turns to face where they are walking, and every sprite in the world — yours,
the NPCs', the figures drawn into the furniture — turns to face the camera
and shows the frame it would look like from where the camera actually
stands, so walking behind someone shows you their back.

## The battle camera

A fight staged on the map (**3D-BTL**, on by default) is shot with a solved
over-the-shoulder rig — and you can steer it.

| control | does |
| --- | --- |
| right stick, a touch drag, or the mouse | swing the shot around the arena (→) and raise the seat (↑) |
| wheel, `Q` / `E`, pinch, or a stick click | the lens (`Q` / left stick click out, `E` / right stick click in) |

Both axes stop where the composition does. Left stops at the shot the rig was
solved for — there is nothing to the left of it. Right ends **side-on**: the
eye square to the arena's axis, both Pokémon at the same distance instead of
one behind the other. Down stops at the rig's own low stance; up is 45° above
it. The lens opens as you swing or climb, by exactly the amount the two
Pokémon spread apart, so they stay framed at every angle. Move animations
follow the pair's position *and* its separation, so a beam still lands on the
Pokémon it was aimed at.

Where you leave the camera is where the next battle opens.

**BACK SPRITES locks it.** That setting pins your own Pokémon to the GB's slot
on the menu while the foe stands out on the map, and no angle holds a
composition that is half frame and half world — so with it on, the shot holds
the one the rig was solved for.

## VR

The **VR** options row (OFF / ON, off by default) drives a PCVR headset
through OpenXR on Windows — SteamVR, Oculus or WMR.

Both free-roam rungs put the headset in the player's *head*: a boom that
seats its wearer three cells behind their own body is a reliable way to make
people ill, so **3RD** in VR is **1ST** in VR. The rung still changes the
walk and the sprites the same way.

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

This fork is not distributed or supported as a PC replacement. Its Android
release ZIP omits the upstream Windows OpenXR runtime. PC and PCVR users should
use the official Dramatic Shape release, where those platforms are developed
and documented.

## Licenses

All authorship stays with DramaticShape and the original contributors. The
upstream project added an MIT license in 1.5.4; this fork carries that license
without claiming upstream endorsement. Our Android changes use the same terms.
See [`LICENSE`](LICENSE).

The source repository retains one upstream third-party binary for parity with
the original project; the Android release ZIP does not include it:

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
