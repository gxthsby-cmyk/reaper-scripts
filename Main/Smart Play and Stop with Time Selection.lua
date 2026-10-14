-- @description Smart Play and Stop with Time Selection
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

-- Smart Play/Stop for MIDI Editor
-- Stops if playing, otherwise moves to time selection start and plays

local is_playing = reaper.GetPlayState() & 1 == 1 -- 1 = playing

if is_playing then
  reaper.Main_OnCommand(1016, 0) -- Transport: Stop
else
  local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if time_sel_start ~= time_sel_end then
    reaper.SetEditCurPos(time_sel_start, true, false)
  end
  reaper.Main_OnCommand(1007, 0) -- Transport: Play
end


