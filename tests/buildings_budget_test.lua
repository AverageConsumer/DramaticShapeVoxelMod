-- Regression: stamping one cached authored building must stay cooperative.
-- The geometry copy used to be one atomic 60-120 ms operation on Android.

local now = 0
love = {
  timer = {
    getTime = function()
      now = now + 0.001
      return now
    end,
  },
}

local Budget = assert(loadfile("lib/BuildBudget.lua"))()
local V = {
  require = function(name)
    assert(name == "BuildBudget")
    return Budget
  end,
}
local Buildings = assert(loadfile("lib/Buildings.lua"))(V)

local quads = {}
for i = 1, 160 do
  quads[i] = {
    { i, 0, 0 }, { i + 1, 0, 0 },
    { i + 1, 1, 0 }, { i, 1, 0 },
    uv = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 0, 1 } },
    shade = 1,
  }
end

local S = {
  objectQuads = {},
  shapeAt = {},
  skip = {},
  ground = {},
  tileAt = {},
}
local co = coroutine.create(function()
  Buildings.stamp(S, {}, quads, 3, 4, 2, 2)
end)

local yields = 0
while coroutine.status(co) ~= "dead" do
  Budget.begin(co, 0.004)
  local ok, why = coroutine.resume(co)
  Budget.finish()
  assert(ok, why)
  if coroutine.status(co) ~= "dead" then
    assert(why == "budget")
    yields = yields + 1
  end
end

assert(yields > 0, "building stamp never yielded to its frame budget")
assert(#S.objectQuads == #quads, "building stamp lost geometry across a yield")
assert(S.objectQuads[1][1][1] == quads[1][1][1] + 24)
assert(S.objectQuads[1][1][3] == quads[1][1][3] + 32)
assert(S.objectQuads[#quads].uv == quads[#quads].uv)

print("buildings budget tests: ok")
