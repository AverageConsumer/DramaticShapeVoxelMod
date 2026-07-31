-- Conservative camera-frustum culling for spatial voxel chunks.
--
-- The caller supplies the exact view-projection matrix used by the current
-- frame. Aspect ratio, window size, zoom, pitch and a placed battle camera are
-- therefore already represented; this module contains no device- or
-- resolution-specific constants.
--
-- Bounds are expanded in WORLD space before testing. That guard makes chunks
-- enter before their first pixel could reach the screen and keeps camera tween
-- and numerical noise from producing edge pop.
--
-- The curved-world shader makes an ordinary corner-only AABB test invalid:
-- y' = y - k((x-fx)^2 + (z-fz)^2). For each clip plane below we maximize its
-- inside half-space expression over that quadratic box exactly. If even that
-- maximum is outside, every point in the curved chunk is outside. This is both
-- conservative and tighter than wrapping the bend in a very tall box.

local ViewCull = {}

local function maxCurvedAxis(linear, yCoeff, k, focus, lo, hi)
  local function at(v)
    local d = v - focus
    return linear * v - yCoeff * k * d * d
  end
  local best = math.max(at(lo), at(hi))
  -- -yCoeff*k is the quadratic coefficient. Only a concave parabola can
  -- attain its maximum inside the interval; a convex one's maximum is at an
  -- endpoint, already covered above.
  if yCoeff * k > 0 then
    local v = focus + linear / (2 * yCoeff * k)
    if v > lo and v < hi then best = math.max(best, at(v)) end
  end
  return best
end

local function maxPlane(a, b, c, d, x0, x1, y0, y1, z0, z1,
                        k, fx, fz)
  local y = b >= 0 and b * y1 or b * y0
  return d + y
       + maxCurvedAxis(a, b, k, fx, x0, x1)
       + maxCurvedAxis(c, b, k, fz, z0, z1)
end

local function outside(a, b, c, d, x0, x1, y0, y1, z0, z1, k, fx, fz)
  -- A tiny tolerance makes a plane-touching chunk visible even after matrix
  -- roundoff. Pop prevention matters more than rejecting a zero-pixel edge.
  return maxPlane(a, b, c, d, x0, x1, y0, y1, z0, z1,
                  k, fx, fz) < -1e-6
end

function ViewCull.visible(vp, bounds, ox, oz, curveK, curveX, curveZ, guard)
  if not (vp and bounds) then return true end
  ox, oz = ox or 0, oz or 0
  guard = math.max(0, tonumber(guard) or 32)

  local x0 = (bounds.x0 or 0) + ox - guard
  local x1 = (bounds.x1 or 0) + ox + guard
  local z0 = (bounds.z0 or 0) + oz - guard
  local z1 = (bounds.z1 or 0) + oz + guard
  local y0 = (bounds.y0 or -32) - guard
  local y1 = (bounds.y1 or 160) + guard

  local k = math.max(0, tonumber(curveK) or 0)
  local fx, fz = curveX or 0, curveZ or 0

  -- Homogeneous GL clip space. Each expression is >= 0 inside its plane:
  -- x+w, w-x, y+w, w-y, z+w, w-z.
  if outside(vp[1] + vp[13], vp[2] + vp[14],
             vp[3] + vp[15], vp[4] + vp[16],
             x0, x1, y0, y1, z0, z1, k, fx, fz) then return false end
  if outside(vp[13] - vp[1], vp[14] - vp[2],
             vp[15] - vp[3], vp[16] - vp[4],
             x0, x1, y0, y1, z0, z1, k, fx, fz) then return false end
  if outside(vp[5] + vp[13], vp[6] + vp[14],
             vp[7] + vp[15], vp[8] + vp[16],
             x0, x1, y0, y1, z0, z1, k, fx, fz) then return false end
  if outside(vp[13] - vp[5], vp[14] - vp[6],
             vp[15] - vp[7], vp[16] - vp[8],
             x0, x1, y0, y1, z0, z1, k, fx, fz) then return false end
  if outside(vp[9] + vp[13], vp[10] + vp[14],
             vp[11] + vp[15], vp[12] + vp[16],
             x0, x1, y0, y1, z0, z1, k, fx, fz) then return false end
  if outside(vp[13] - vp[9], vp[14] - vp[10],
             vp[15] - vp[11], vp[16] - vp[12],
             x0, x1, y0, y1, z0, z1, k, fx, fz) then return false end
  return true
end

return ViewCull
