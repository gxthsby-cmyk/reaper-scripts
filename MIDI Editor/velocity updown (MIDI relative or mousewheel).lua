-- @description velocity updown (MIDI relative or mousewheel)
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main=midi_editor] .

--[[
Fine-tuned Shift + Mousewheel Velocity Script
- Works only with mousewheel/relative action
- Supports very small increments for fine control
- Maintains integer velocity for Reaper
--]]

local _, _, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
if not val or val == 0 then return end

local midiEditor = reaper.MIDIEditor_GetActive()
if not midiEditor then return end
local take = reaper.MIDIEditor_GetTake(midiEditor)
if not take or not reaper.TakeIsMIDI(take) then return end

local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
if noteCount == 0 then return end

-- Use a small floating-point step for fine control
local step = 0.25  -- very fine increment

for i = 0, noteCount-1 do
    local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if sel then
        -- Track velocity as float for smooth fine adjustments
        local newVel = (vel or 0) + val * step
        -- Round to nearest integer for Reaper
        local roundedVel = math.floor(newVel + 0.5)
        -- Clamp between 1 and 127
        if roundedVel < 1 then roundedVel = 1 end
        if roundedVel > 127 then roundedVel = 127 end
        reaper.MIDI_SetNote(take, i, nil, nil, nil, nil, nil, nil, roundedVel, true)
    end
end

reaper.MIDI_Sort(take)

