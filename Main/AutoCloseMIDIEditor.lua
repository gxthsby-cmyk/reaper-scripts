-- @description Auto-close MIDI Editor on deselect
function Main()
  local ed = reaper.MIDIEditor_GetActive()
  local sel = reaper.CountSelectedMediaItems(0)
  local midiSel = false
  for i = 0, sel-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if reaper.TakeIsMIDI(reaper.GetActiveTake(item)) then midiSel = true break end
  end
  if ed and not midiSel then
    reaper.MIDIEditor_OnCommand(ed, 2) -- close window
  end
  reaper.defer(Main)
end
Main()

