-- Standalone contract test for the opt-in graphics controls.
-- Runs without the game SDK:
--   lua tests/graphics_settings_test.lua

local stored = {}
local writes = 0

local V = {
  mod = {
    id = "DRAMATIC_SHAPE",
    options = {
      get = function(_, key) return stored[key] end,
    },
  },
}

local modules = {}
function V.require(name)
  if modules[name] then return modules[name] end
  local chunk = assert(loadfile("lib/" .. name .. ".lua"))
  modules[name] = chunk(V)
  return modules[name]
end

local made = 0
local madeSizes = {}
local lastDraw = nil
local function canvas(w, h)
  return {
    getDimensions = function() return w, h end,
    setFilter = function() end,
    release = function() end,
  }
end

love = {
  graphics = {
    newCanvas = function(w, h)
      made = made + 1
      madeSizes[#madeSizes + 1] = w
      return canvas(w, h)
    end,
    getBlendMode = function() return "alpha", "alphamultiply" end,
    setBlendMode = function() end,
    setCanvas = function() end,
    setShader = function() end,
    setDepthMode = function() end,
    setColor = function() end,
    clear = function() end,
    draw = function(_, x, y, r, sx, sy)
      lastDraw = { x, y, r, sx, sy }
    end,
  },
}

local G = V.require("GraphicsSettings")

assert(G.preset:get() == "original")
assert(G.renderScale() == 1)
assert(G.softShadowEnabled())
assert(G.buildBudget().urgent == 0.012)
assert(#G.shadowSizes() == 3 and G.shadowSizes()[3] == 2048)
assert(G.shadowUpdateInterval() == 0)

local native = canvas(1920, 1080)
assert(G.present(native, 1920, 1080) == native)
assert(made == 0, "ORIGINAL must not allocate an upscale canvas")

local game = {
  save = { options = { modOptions = {} } },
  mods = { modOptions = {} },
  writeOptions = function() writes = writes + 1 end,
}

-- ORIGINAL -> QUALITY
G.preset:row().step(game, 1)
assert(G.preset:get() == "quality")
assert(G.renderScale() == 1)
assert(G.shadowSizes()[1] == 512 and #G.shadowSizes() == 1)
assert(math.abs(G.shadowUpdateInterval() - 1 / 60) < 0.0001)

-- QUALITY -> BALANCED: same native/soft image, calmer 30 Hz actor shadows.
G.preset:row().step(game, 1)
local rw, rh = G.renderSize(1920, 1080)
assert(rw == 1920 and rh == 1080)
assert(G.buildBudget().urgent == 0.006)
assert(G.softShadowEnabled())
assert(math.abs(G.shadowUpdateInterval() - 1 / 30) < 0.0001)
assert(G.fullTiltShiftLevel(3) == 3)

-- An individual adjustment makes the aggregate label honest.
G.resolution:row().step(game, 1)
assert(G.preset:get() == "custom")

-- FAST keeps native geometry but removes the expensive fullscreen blur and
-- uses one-tap shadows.
G.preset:setIndex(4, game)
G.optionChanged(G.preset.key, game)
rw, rh = G.renderSize(1920, 1080)
assert(rw == 1920 and rh == 1080)
assert(not G.softShadowEnabled())
assert(G.shadowSizes()[1] == 512)
assert(math.abs(G.shadowUpdateInterval() - 1 / 30) < 0.0001)
assert(G.fullTiltShiftLevel(3) == 0)

-- The independent resolution row still exercises the nearest-upscale path.
G.resolution:setIndex(4, game)
rw, rh = G.renderSize(1920, 1080)
local low = canvas(rw, rh)
local output = G.present(low, 1920, 1080)
assert(output ~= low and made == 1)
assert(math.abs(lastDraw[4] - 1.5) < 0.001)
assert(math.abs(lastDraw[5] - 1.5) < 0.001)

-- BATTERY turns real shadow mapping off but leaves a valid decal fallback.
G.preset:setIndex(5, game)
G.optionChanged(G.preset.key, game)
assert(not G.shadowsEnabled())
assert(G.shadowSizes() == nil)
assert(G.buildBudget().urgent == 0.003)
assert(G.fullTiltShiftLevel(3) == 0)
assert(writes > 0)

-- Regression: probing availability must not resize an already fitted shadow
-- map back to its smallest rung. Before the hotfix, a 1536/2048 outdoor map
-- was destroyed here and rebuilt again in begin() every moving frame.
G.preset:setIndex(1, game)
G.optionChanged(G.preset.key, game)
assert(G.fullTiltShiftLevel(3) == 3)
love.graphics.newShader = function()
  return { send = function() end }
end
love.graphics.setMeshCullMode = function() end
local ShadowMap = V.require("ShadowMap")
assert(ShadowMap.available())
assert(ShadowMap.begin(0, 0, 1600, 1200))
ShadowMap.finish("large")
assert(ShadowMap.res > 1024, "large view should select a higher shadow rung")
local madeAfterFit = made
assert(ShadowMap.available())
assert(made == madeAfterFit,
  "available() must retain the fitted shadow canvas instead of reallocating")

-- Static changes are immediate, while a just-finished dynamic map is reused
-- until its selected cadence allows another cast.
G.shadowRate:setIndex(5, game)
assert(not ShadowMap.stale("large", "pose-b"),
  "15 Hz motion must reuse a freshly completed map")
assert(ShadowMap.stale("new-static", "pose-b"),
  "structural shadow changes must never wait for the motion cadence")

print("graphics settings: ok")
