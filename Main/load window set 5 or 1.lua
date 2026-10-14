-- @description load window set 5 or 1
-- @provides [main] .

-- Toggles between window set 2 and window set 1

local setA = 5
local setB = 1

-- Track last loaded window set
local last = tonumber(reaper.GetExtState("WindowSetToggle", "last") or 0)

if last == setA then
    -- Last loaded was desired set, load setB
    reaper.Main_OnCommand(40028 + setB, 0)
    reaper.SetExtState("WindowSetToggle", "last", setB, true)
else
    -- Load setA
    reaper.Main_OnCommand(40028 + setA, 0)
    reaper.SetExtState("WindowSetToggle", "last", setA, true)
end

