-- Standalone contract test for strict visible mesh-build slices.
-- Runs without LOVE or the game SDK:
--   lua tests/build_budget_test.lua

local now = 0
love = {
  timer = {
    getTime = function() return now end,
  },
}

local Budget = assert(loadfile("lib/BuildBudget.lua"))()
local ticks = 0
local co = coroutine.create(function()
  while ticks < 10 do
    ticks = ticks + 1
    now = now + 0.004
    Budget.tick()
  end
end)

Budget.begin(co, 0.005)
local ok, why = coroutine.resume(co)
Budget.finish()

assert(ok, tostring(why))
assert(why == "budget", "visible build did not yield at its deadline")
assert(ticks == 2, "visible build batched clock checks: " .. tostring(ticks))
assert(coroutine.status(co) == "suspended")

-- Outside the actively pumped coroutine tick() remains a no-op.
Budget.tick()

print("build budget tests: ok")
