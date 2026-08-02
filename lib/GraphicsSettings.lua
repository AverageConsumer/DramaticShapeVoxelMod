-- User-tunable performance controls for the voxel renderer.
--
-- Fresh Android installs default to the tested balanced profile: native
-- resolution, 512px shadows at 30 Hz, soft shadows and smooth mesh builds.
-- Explicit values from an existing save still win.
--
-- T-SHIFT remains its own pipeline row because it is expensive enough to
-- benchmark independently. QUALITY and BALANCED retain the miniature look;
-- FAST and BATTERY switch it off, and it remains freely adjustable afterwards.

local V = ...

local ModSetting = V.require("ModSetting")

local GraphicsSettings = {}

GraphicsSettings.preset = ModSetting.new(
  "graphicsPreset", "V-PRESET",
  { "original", "quality", "balanced", "fast", "battery", "custom" },
  { "ORIGINAL", "QUALITY", "BALANCED", "FAST", "BATTERY", "CUSTOM" }, 3)

GraphicsSettings.resolution = ModSetting.new(
  "renderScale", "V-RES",
  { 1.00, 0.8333, 0.75, 0.6667, 0.50 },
  { "100%", "83%", "75%", "67%", "50%" })

GraphicsSettings.shadows = ModSetting.new(
  "shadowQuality", "V-SHADOW",
  { "auto", "1024", "768", "512", "off" },
  { "AUTO", "1024", "768", "512", "OFF" }, 4)

GraphicsSettings.shadowRate = ModSetting.new(
  "shadowRate", "V-SRATE",
  { 0, 60, 30, 20, 15 },
  { "LIVE", "60", "30", "20", "15" }, 3)

GraphicsSettings.softShadows = ModSetting.new(
  "softShadows", "V-SOFT",
  { true, false }, { "ON", "OFF" })

GraphicsSettings.build = ModSetting.new(
  "buildBudget", "V-BUILD",
  { "normal", "smooth", "minimal" },
  { "NORMAL", "SMOOTH", "MIN" }, 2)

local controls = {
  GraphicsSettings.resolution,
  GraphicsSettings.shadows,
  GraphicsSettings.shadowRate,
  GraphicsSettings.softShadows,
  GraphicsSettings.build,
}

-- Indices into the five setting ladders above.  At 1080p these render-scale
-- rungs correspond to approximately 1080p, 900p, 810p, 720p and 540p.
local PRESETS = {
  original = { 1, 1, 1, 1, 1 },
  -- Measured on Snapdragon 8 Gen 2 at 1080p/60 with T-SHIFT 3: resolution
  -- scaling and one-tap filtering bought little, while 512 shadow texels and
  -- the split static/actor cache held native output at the cap.
  quality =  { 1, 4, 2, 1, 1 },
  balanced = { 1, 4, 3, 1, 2 },
  fast =     { 1, 4, 3, 2, 2 },
  battery =  { 3, 5, 5, 2, 3 },
}
local PRESET_TILT = { balanced = 3, fast = 0, battery = 0 }

local CUSTOM_INDEX = #GraphicsSettings.preset.values

local function setTiltShift(game, level)
  if level == nil then return end
  local ok, Pipelines = pcall(require, "src.render.Pipelines")
  if not (ok and Pipelines and Pipelines.setLevel) then return end
  Pipelines.setLevel("tiltshift", level)
  local opts = game and game.save and game.save.options
  if opts and Pipelines.syncOptions then Pipelines.syncOptions(opts) end
  if game and game.writeOptions then pcall(game.writeOptions, game) end
end

local function applyPreset(game)
  local name = GraphicsSettings.preset:get()
  local values = PRESETS[name]
  if not values then return end
  for i, setting in ipairs(controls) do
    setting:setIndex(values[i], game)
  end
  setTiltShift(game, PRESET_TILT[name])
end

local function markCustom(game)
  if GraphicsSettings.preset:read() ~= CUSTOM_INDEX then
    GraphicsSettings.preset:setIndex(CUSTOM_INDEX, game)
  end
end

-- ModSetting calls this only for an in-game OPTIONS row step.  Programmatic
-- writes made while applying a preset do not recursively turn it into CUSTOM.
GraphicsSettings.preset.onStep = function(_, game, dir)
  -- CUSTOM describes hand-tuned controls; it is not a no-op preset the
  -- player should have to step through between the authored rungs.
  if GraphicsSettings.preset:get() == "custom" then
    GraphicsSettings.preset:setIndex((dir or 1) < 0 and 5 or 1, game)
  end
  applyPreset(game)
end
for _, setting in ipairs(controls) do
  setting.onStep = function(_, game) markCustom(game) end
end

GraphicsSettings.entries = {
  {
    GraphicsSettings.preset,
    "Set the voxel renderer's resolution, shadows and streaming budget "
      .. "together. ORIGINAL is the unmodified renderer; QUALITY and BALANCED "
      .. "keep T-SHIFT 3, while FAST and BATTERY start with it off.",
  },
  {
    GraphicsSettings.resolution,
    "Internal 3D resolution. The result is nearest-upscaled to the native "
      .. "framebuffer, so menus and the rest of the game remain full size.",
  },
  {
    GraphicsSettings.shadows,
    "Real cast-shadow map resolution. AUTO is the original adaptive "
      .. "1024/1536/2048 ladder; OFF keeps lightweight character decals.",
  },
  {
    GraphicsSettings.shadowRate,
    "Maximum real-shadow updates per second. LIVE preserves the historical "
      .. "every-change path; lower rates reuse the world-anchored map between "
      .. "updates while movement and animation continue normally.",
  },
  {
    GraphicsSettings.softShadows,
    "ON samples four shadow texels for a soft edge; OFF uses one sample.",
  },
  {
    GraphicsSettings.build,
    "How much CPU time terrain streaming may use in one frame. Lower "
      .. "budgets reduce hitches but make new map geometry appear later.",
  },
}

-- FULL historically starts T-SHIFT at maximum. Keep that default for
-- ORIGINAL/QUALITY, respect the authored presets, and leave a hand-tuned CUSTOM
-- value alone.
function GraphicsSettings.fullTiltShiftLevel(maximum)
  local name = GraphicsSettings.preset:get()
  if name == "custom" then return nil end
  if PRESET_TILT[name] ~= nil then return PRESET_TILT[name] end
  return maximum
end

-- The mod manager writes a single option at a time rather than stepping an
-- OPTIONS row, so mirror the row behaviour explicitly for that route.
function GraphicsSettings.optionChanged(key, game)
  if key == GraphicsSettings.preset.key then
    applyPreset(game)
    return
  end
  for _, setting in ipairs(controls) do
    if key == setting.key then
      markCustom(game)
      return
    end
  end
end

function GraphicsSettings.renderScale()
  return tonumber(GraphicsSettings.resolution:get()) or 1
end

function GraphicsSettings.renderSize(w, h)
  local scale = GraphicsSettings.renderScale()
  if scale >= 0.999 then return w, h end
  return math.max(1, math.floor(w * scale + 0.5)),
         math.max(1, math.floor(h * scale + 0.5))
end

local SHADOW_SIZES = {
  auto = { 1024, 1536, 2048 },
  ["1024"] = { 1024 },
  ["768"] = { 768 },
  ["512"] = { 512 },
}

function GraphicsSettings.shadowSizes()
  return SHADOW_SIZES[GraphicsSettings.shadows:get()]
end

function GraphicsSettings.shadowsEnabled()
  return GraphicsSettings.shadowSizes() ~= nil
end

function GraphicsSettings.softShadowEnabled()
  return GraphicsSettings.softShadows:get() and true or false
end

function GraphicsSettings.shadowUpdateInterval()
  local fps = tonumber(GraphicsSettings.shadowRate:get()) or 0
  return fps > 0 and (1 / fps) or 0
end

local BUILD_BUDGETS = {
  normal = { urgent = 0.012, idle = 0.0050, covered = 0.030 },
  smooth = { urgent = 0.006, idle = 0.0025, covered = 0.020 },
  minimal = { urgent = 0.003, idle = 0.0015, covered = 0.012 },
}

function GraphicsSettings.buildBudget()
  return BUILD_BUDGETS[GraphicsSettings.build:get()]
         or BUILD_BUDGETS.normal
end

-- A low-resolution 3D canvas cannot be returned directly: the engine's
-- Android compositor expects a native-pixel-sized canvas and applies its own
-- DPI transform.  Upscale into a cached native canvas first, preserving the
-- public contract while moving all expensive 3D shading to the smaller one.
local presentCanvas, presentW, presentH = nil, 0, 0

local function releasePresent()
  if presentCanvas and presentCanvas.release then
    pcall(presentCanvas.release, presentCanvas)
  end
  presentCanvas, presentW, presentH = nil, 0, 0
end

function GraphicsSettings.present(canvas, w, h)
  if not canvas then return nil end
  if GraphicsSettings.renderScale() >= 0.999 then
    releasePresent()
    return canvas
  end
  if not (love.graphics and love.graphics.newCanvas) then return nil end

  if not presentCanvas or presentW ~= w or presentH ~= h then
    releasePresent()
    local ok, made = pcall(love.graphics.newCanvas, w, h)
    if not (ok and made) then return nil end
    presentCanvas, presentW, presentH = made, w, h
    pcall(presentCanvas.setFilter, presentCanvas, "nearest", "nearest")
  end

  local cw, ch = canvas:getDimensions()
  local prevBlend, prevAlpha = love.graphics.getBlendMode()
  local ok = pcall(function()
    love.graphics.setCanvas(presentCanvas)
    love.graphics.setShader()
    if love.graphics.setDepthMode then love.graphics.setDepthMode() end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("replace", "premultiplied")
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(canvas, 0, 0, 0, w / cw, h / ch)
  end)
  love.graphics.setCanvas()
  love.graphics.setShader()
  love.graphics.setBlendMode(prevBlend or "alpha", prevAlpha)
  love.graphics.setColor(1, 1, 1, 1)
  return ok and presentCanvas or nil
end

function GraphicsSettings.invalidate()
  releasePresent()
end

return GraphicsSettings
