-- @description FL_Style_Duplicate_Notes_CtrlB
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main=midi_editor] .

-- Smart Ctrl+B: Duplicate MIDI time selection if present, else selected notes forward by one grid

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local take = reaper.MIDIEditor_GetTake(editor)
if not take or not reaper.TakeIsMIDI(take) then return end

local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local hasTimeSel = (timeEnd - timeStart) > 0
local _, noteCount = reaper.MIDI_CountEvts(take)

reaper.Undo_BeginBlock()

if hasTimeSel then
  -- TIME SELECTION MODE: Duplicate all notes in time selection
  local ppqStart = reaper.MIDI_GetPPQPosFromProjTime(take, timeStart)
  local ppqEnd   = reaper.MIDI_GetPPQPosFromProjTime(take, timeEnd)
  local offset   = ppqEnd - ppqStart

  for i = 0, noteCount - 1 do
    local _, sel, mute, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if startppq >= ppqStart and endppq <= ppqEnd then
      reaper.MIDI_InsertNote(take, true, mute, startppq + offset, endppq + offset, chan, pitch, vel, false)
    end
  end

else
  -- SELECTED NOTES MODE: Duplicate selected notes one grid unit forward
  local gridLenQN = reaper.MIDIEditor_GetGrid(editor)
  local gridLenPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, gridLenQN) - reaper.MIDI_GetPPQPosFromProjQN(take, 0)

  for i = 0, noteCount - 1 do
    local _, sel, mute, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if sel then
      reaper.MIDI_InsertNote(take, true, mute, startppq + gridLenPPQ, endppq + gridLenPPQ, chan, pitch, vel, false)
    end
  end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Smart Duplicate Notes (FL Ctrl+B style)", -1)

