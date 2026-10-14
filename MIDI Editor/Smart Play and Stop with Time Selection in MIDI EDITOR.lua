-- @description Smart Play and Stop with Time Selection in MIDI EDITOR
-- @provides [main=midi_editor] .

-- Move edit/play cursor to start of time selection (in MIDI Editor)

-- Get active MIDI editor
local midi_editor = reaper.MIDIEditor_GetActive()
if midi_editor then
  -- Get time selection
  local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if time_sel_start ~= time_sel_end then
    -- Time selection exists
    reaper.SetEditCurPos(time_sel_start, true, false)
  else
    -- No time selection, try snapping to grid or do nothing
    reaper.ShowMessageBox("No time selection set.", "Info", 0)
  end
else
  reaper.ShowMessageBox("No active MIDI editor found.", "Error", 0)
end

