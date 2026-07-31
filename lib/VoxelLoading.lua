-- A first-build cover for the voxel world.
--
-- Returning nil from drawWorld hands the frame back to the vanilla renderer.
-- That is a useful hardware fallback, but a terrible loading state: the player
-- sees the flat map frozen for several seconds and then watches voxel chunks
-- arrive. This tiny native-sized canvas owns those frames instead. It carries
-- no scene shaders, depth buffer or post-process, leaving nearly the whole
-- frame to the cooperative mesh build.

local V = ...

local Voxel = V.require("VoxelState")

local Loading = {}

local canvas, canvasW, canvasH = nil, 0, 0
local titleFont, bodyFont, fontH = nil, nil, 0
local townMapView, townMapFont, townMapGame = nil, nil, nil
local townMapMapId, townMapFailed = nil, nil

local C = {
  ink = { 21 / 255, 25 / 255, 38 / 255, 1 },
  panel = { 245 / 255, 239 / 255, 214 / 255, 1 },
  shade = { 186 / 255, 195 / 255, 184 / 255, 1 },
  red = { 207 / 255, 62 / 255, 72 / 255, 1 },
}

local clock = (love and love.timer and love.timer.getTime) or os.clock

local function releaseObject(obj)
  if obj and obj.release then pcall(obj.release, obj) end
end

local function releaseTownMap()
  local bg = townMapView and townMapView.bg
  if bg then
    releaseObject(bg.img)
    releaseObject(bg.cursor)
    for _, quad in pairs(bg.quads or {}) do releaseObject(quad) end
  end
  releaseObject(townMapView and townMapView.nestIcon)
  townMapView, townMapFont, townMapGame = nil, nil, nil
  townMapMapId, townMapFailed = nil, nil
end

-- Reuse the engine's real Town Map viewer as a passive loading illustration.
-- It reads the Kanto tilemap, cursor and location coordinates extracted from
-- the player's own ROM; this mod therefore ships no copied map art and keeps
-- no parallel table of map-specific positions.
local function townMapForLoading()
  local mapId = Voxel.loadingMap
  if not mapId or townMapFailed == mapId then return nil end

  local okG, Game = pcall(require, "src.core.Game")
  if not (okG and Game and Game.data) then
    townMapFailed = mapId
    return nil
  end
  if not townMapView or townMapGame ~= Game then
    releaseTownMap()
    local okT, TownMap = pcall(require, "src.ui.TownMap")
    local okF, Font = pcall(require, "src.render.Font")
    local okV, view = false, nil
    if okT then okV, view = pcall(TownMap.new, Game) end
    if not (okV and view and view.mode == "grid" and view.bg
            and okF and Font) then
      townMapView = view
      releaseTownMap()
      townMapFailed = mapId
      return nil
    end
    townMapView, townMapFont, townMapGame = view, Font, Game
  end

  local loc = townMapView.byMap and townMapView.byMap[mapId]
  if not loc then
    townMapFailed = mapId
    return nil
  end
  townMapView.playerLoc = loc
  for i, candidate in ipairs(townMapView.locs or {}) do
    if candidate == loc then
      townMapView.sel = i
      break
    end
  end
  townMapMapId = mapId
  return townMapView, townMapFont
end

local function ensure(w, h)
  if canvas and canvasW == w and canvasH == h then return true end
  local ok, c = pcall(love.graphics.newCanvas, w, h)
  if not (ok and c) then return false end
  c:setFilter("nearest", "nearest")
  if canvas and canvas.release then pcall(canvas.release, canvas) end
  canvas, canvasW, canvasH = c, w, h
  return true
end

local function fonts(h)
  local target = math.max(12, math.floor(h / 28))
  if target == fontH and titleFont and bodyFont then
    return titleFont, bodyFont
  end
  local okT, tf = pcall(love.graphics.newFont, target)
  local okB, bf = pcall(love.graphics.newFont, math.max(10,
                                                       math.floor(target * 0.5)))
  if okT and tf and okB and bf then
    if titleFont and titleFont.release then pcall(titleFont.release, titleFont) end
    if bodyFont and bodyFont.release then pcall(bodyFont.release, bodyFont) end
    titleFont, bodyFont, fontH = tf, bf, target
  end
  return titleFont or love.graphics.getFont(),
         bodyFont or love.graphics.getFont()
end

local function centered(text, y, font, w)
  love.graphics.setFont(font)
  love.graphics.print(text, math.floor((w - font:getWidth(text)) * 0.5), y)
end

local function drawTownMap(g, w, h, pending, elapsed)
  local view, Font = townMapForLoading()
  if not (view and Font) then return false end

  -- The original screen is 160x144. Add one three-tile message box beneath
  -- it, then integer-scale the 160x168 composition so every Game Boy pixel
  -- stays hard on every display size and aspect ratio.
  local logicalW, logicalH = 160, 168
  local scale = math.max(1, math.floor(
    math.min((w - 8) / logicalW, (h - 8) / logicalH)))
  local x = math.floor((w - logicalW * scale) * 0.5)
  local y = math.floor((h - logicalH * scale) * 0.5)

  g.push()
  g.translate(x, y)
  g.scale(scale, scale)
  g.setLineWidth(1)
  view.blink = math.floor(elapsed * 60) % 32
  local ok = pcall(view.draw, view)
  if ok then
    Font.drawBox(0, 18, 20, 3)
    g.setColor(0, 0, 0, 1)
    local text = "BUILDING VOXELS"
    if pending and pending > 1 and math.floor(elapsed / 2) % 2 == 1 then
      text = tostring(pending) .. " AREAS LEFT"
    end
    Font.draw(text, math.floor((logicalW - Font.width(text)) * 0.5), 152)
  end
  g.pop()
  g.setColor(1, 1, 1, 1)

  if not ok then
    local failed = townMapMapId or Voxel.loadingMap
    releaseTownMap()
    townMapFailed = failed
    return false
  end
  return true
end

function Loading.draw(w, h, pending)
  if not (love.graphics and love.graphics.newCanvas) then return nil end
  if not ensure(w, h) then return nil end

  local g = love.graphics
  g.setCanvas(canvas)
  g.setShader()
  g.setBlendMode("alpha")
  g.origin()
  -- Match Gen1Recomp's own 4:3 menu letterbox exactly. The fallback card
  -- still uses the softer ink colour inside its artwork.
  g.clear(0, 0, 0, 1)

  local elapsed = clock() - (Voxel.loadingSince or clock())
  if drawTownMap(g, w, h, pending, elapsed) then
    g.setColor(1, 1, 1, 1)
    g.setCanvas()
    return canvas
  end

  local unit = math.max(2, math.floor(math.min(w / 640, h / 360)))
  local panelW = math.min(w - unit * 24, unit * 176)
  local panelH = math.min(h - unit * 16, unit * 72)
  local x = math.floor((w - panelW) * 0.5)
  local y = math.floor((h - panelH) * 0.5)

  -- Hard pixel corners and a two-tone offset shadow keep this in the game's
  -- graphic language without depending on any ROM-derived asset.
  g.setColor(C.red)
  g.rectangle("fill", x + unit * 4, y + unit * 4, panelW, panelH)
  g.setColor(C.panel)
  g.rectangle("fill", x, y, panelW, panelH)
  g.setColor(C.ink)
  g.setLineWidth(unit * 2)
  g.rectangle("line", x, y, panelW, panelH)

  local tf, bf = fonts(h)
  g.setColor(C.ink)
  centered("BUILDING KANTO", y + unit * 12, tf, w)
  centered("PREPARING THE VOXEL WORLD", y + unit * 34, bf, w)

  local barW, barH = panelW - unit * 32, unit * 8
  local bx, by = x + unit * 16, y + panelH - unit * 20
  g.setColor(C.ink)
  g.rectangle("fill", bx, by, barW, barH)
  g.setColor(C.shade)
  g.rectangle("fill", bx + unit * 2, by + unit * 2,
              barW - unit * 4, barH - unit * 4)

  -- Honest indeterminate progress: mesh jobs vary by two orders of magnitude,
  -- so a fake percentage would sit at zero and then jump. Four voxel blocks
  -- travel through the rail while the real completion condition is pending=0.
  local cells = 20
  local head = math.floor(elapsed * 10) % cells
  local innerW = barW - unit * 4
  local cellW = innerW / cells
  g.setColor(C.red)
  for i = 0, 3 do
    local cell = (head + i) % cells
    g.rectangle("fill", bx + unit * 2 + math.floor(cell * cellW),
                by + unit * 2, math.ceil(cellW), barH - unit * 4)
  end

  if pending and pending > 1 then
    g.setColor(C.ink)
    centered(tostring(pending) .. " AREAS REMAINING",
             y + panelH + unit * 12, bf, w)
  end

  g.setColor(1, 1, 1, 1)
  g.setCanvas()
  return canvas
end

function Loading.invalidate()
  if canvas and canvas.release then pcall(canvas.release, canvas) end
  if titleFont and titleFont.release then pcall(titleFont.release, titleFont) end
  if bodyFont and bodyFont.release then pcall(bodyFont.release, bodyFont) end
  releaseTownMap()
  canvas, canvasW, canvasH = nil, 0, 0
  titleFont, bodyFont, fontH = nil, nil, 0
end

return Loading
