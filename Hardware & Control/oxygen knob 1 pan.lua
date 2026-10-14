-- @description oxygen knob 1 pan
-- @provides [main] .

-- CC37 Pan → 1st selected track
local hwnd = reaper.JS_Window_GetForeground()
if not hwnd then return end
local class = reaper.JS_Window_GetClassName(hwnd)
if class ~= "REAPER" and class ~= "REAPERDock" then return end

local count = reaper.CountSelectedTracks(0)
if count < 1 then return end
local track = reaper.GetSelectedTrack(0, 0)

local cc = tonumber(reaper.GetExtState("CC37","val")) or 0

-- Snap positions
local snap = {-1,-0.8,-0.6,-0.4,-0.2,0,0.2,0.4,0.6,0.8,1}
local idx = math.floor(cc/127*#snap + 0.5)
idx = math.max(1, math.min(#snap, idx))

reaper.SetMediaTrackInfo_Value(track, "D_PAN", snap[idx])

