-- @description reset selected tracks faders to 0 script
-- @provides [main] .

--[[
Reaper Lua Script
Resets volume faders of all selected tracks to 0 dB
--]]

-- Begin undo block
reaper.Undo_BeginBlock()

-- Get number of selected tracks
local sel_track_count = reaper.CountSelectedTracks(0)

-- Loop through all selected tracks
for i = 0, sel_track_count - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    if track then
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1.0)  -- 1.0 = 0 dB
    end
end

-- End undo block
reaper.Undo_EndBlock("Reset selected track faders to 0 dB", -1)

