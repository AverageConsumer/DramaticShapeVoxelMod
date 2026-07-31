-- Standalone contract test for conservative camera-frustum culling.
-- Runs without LOVE or the game SDK:
--   lua tests/view_cull_test.lua

local Mat4 = assert(loadfile("lib/Mat4.lua"))()
local ViewCull = assert(loadfile("lib/ViewCull.lua"))()

local function box(x0, x1, y0, y1, z0, z1)
  return { x0 = x0, x1 = x1, y0 = y0, y1 = y1, z0 = z0, z1 = z1 }
end

local function yes(label, value)
  assert(value, label .. " should be visible")
end

local function no(label, value)
  assert(not value, label .. " should be culled")
end

local I = Mat4.identity()
yes("identity centre", ViewCull.visible(I, box(-0.2, 0.2, -0.2, 0.2,
                                               -0.2, 0.2), 0, 0, 0, 0, 0, 0))
no("identity left", ViewCull.visible(I, box(-3, -2, -0.2, 0.2,
                                            -0.2, 0.2), 0, 0, 0, 0, 0, 0))
no("translated outside", ViewCull.visible(I, box(-0.2, 0.2, -0.2, 0.2,
                                                 -0.2, 0.2),
                                           3, 0, 0, 0, 0, 0))
yes("translated inside", ViewCull.visible(I, box(-0.2, 0.2, -0.2, 0.2,
                                                 -0.2, 0.2),
                                           0.5, 0, 0, 0, 0, 0))

-- The world-space guard brings a just-offscreen chunk in early.
no("unguarded edge", ViewCull.visible(I, box(1.1, 1.2, -0.1, 0.1,
                                             -0.1, 0.1), 0, 0, 0, 0, 0, 0))
yes("guarded edge", ViewCull.visible(I, box(1.1, 1.2, -0.1, 0.1,
                                            -0.1, 0.1), 0, 0, 0, 0, 0, 0.2))

-- Aspect and zoom are properties of VP, not hard-coded screen assumptions.
local narrow = Mat4.ortho(-100, 100, -100, 100, 1, 100)
local wide = Mat4.ortho(-200, 200, -100, 100, 1, 100)
local side = box(130, 140, -5, 5, -20, -10)
no("narrow aspect", ViewCull.visible(narrow, side, 0, 0, 0, 0, 0, 0))
yes("wide aspect", ViewCull.visible(wide, side, 0, 0, 0, 0, 0, 0))

local zoomedIn = Mat4.ortho(-50, 50, -50, 50, 1, 100)
local zoomedOut = Mat4.ortho(-200, 200, -200, 200, 1, 100)
local distant = box(80, 90, -5, 5, -20, -10)
no("zoomed in", ViewCull.visible(zoomedIn, distant, 0, 0, 0, 0, 0, 0))
yes("zoomed out", ViewCull.visible(zoomedOut, distant, 0, 0, 0, 0, 0, 0))

-- Exercise the same perspective/look-at form used by the actual renderer.
local view = Mat4.lookAt({ 0, 100, 120 }, { 0, 0, 0 }, { 0, 1, 0 })
local proj = Mat4.perspective(math.rad(60), 16 / 9, 1, 2000)
local vp = Mat4.mul(proj, view)
yes("perspective centre", ViewCull.visible(vp, box(-8, 8, 0, 32, -8, 8),
                                            0, 0, 0, 0, 0, 0))
no("perspective side", ViewCull.visible(vp, box(5000, 5010, 0, 10, 0, 10),
                                         0, 0, 0, 0, 0, 0))
no("behind camera", ViewCull.visible(vp, box(-5, 5, 90, 110, 150, 170),
                                      0, 0, 0, 0, 0, 0))

-- Reproduce Voxel3D's real orbit camera rather than testing only abstract
-- projection matrices. The same world chunk changes visibility with both
-- gameplay zoom and a phone/handheld's wider display.
local function orbitVP(vw, vh, angle)
  local dist = vh
  local fov = 2 * math.atan(0.5)
  local eye = { 0, dist * math.cos(angle), dist * math.sin(angle) }
  local up = { 0, math.sin(angle), -math.cos(angle) }
  local p = Mat4.perspective(fov, vw / vh,
                             math.max(1, dist * 0.05), dist * 4 + 4096)
  p = Mat4.mul(Mat4.scale(1, -1, 1), p)
  return Mat4.mul(p, Mat4.lookAt(eye, { 0, 0, 0 }, up))
end

local angle = math.rad(50)
local zoomProbe = box(90, 100, 0, 10, -5, 5)
no("real camera zoomed in",
   ViewCull.visible(orbitVP(128, 72, angle), zoomProbe,
                    0, 0, 0, 0, 0, 0))
yes("real camera zoomed out",
    ViewCull.visible(orbitVP(512, 288, angle), zoomProbe,
                     0, 0, 0, 0, 0, 0))

local aspectProbe = box(145, 155, 0, 10, -5, 5)
no("real camera 4:3",
   ViewCull.visible(orbitVP(192, 144, angle), aspectProbe,
                    0, 0, 0, 0, 0, 0))
yes("real camera 20:9",
    ViewCull.visible(orbitVP(320, 144, angle), aspectProbe,
                     0, 0, 0, 0, 0, 0))

-- A point above the flat frustum can bend into view. The conservative curve
-- enclosure must retain it; without the curve the same box is safely absent.
local curveView = Mat4.ortho(-200, 200, -10, 10, 1, 100)
local curved = box(99, 101, 99, 101, -20, -10)
no("flat high box", ViewCull.visible(curveView, curved,
                                     0, 0, 0, 0, 0, 0))
yes("curved high box", ViewCull.visible(curveView, curved,
                                        0, 0, 0.01, 0, 0, 0))

-- Missing render state always falls back to drawing.
yes("missing matrix", ViewCull.visible(nil, curved))
yes("missing bounds", ViewCull.visible(I, nil))

print("view cull tests: ok")
