-- @description Insert Note And Use Last Notes Note Length
-- @provides [main=midi_editor] .

--[[
Deferred script to automatically set new note length
to the first selected note in the active MIDI editor.

Behavior:
- Monitors selection changes in the MIDI editor.
- Updates the "current note length" whenever a note is selected.
- Works automatically while the script is running.
]]

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local take = reaper.MIDIEditor_GetTake(editor)
if not take or not reaper.TakeIsMIDI(take) then return end

-- store last selection to detect changes
local lastSelectedNote = -1

function main()
    local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
    local newSelectedNote = -1
    -- find first selected note
    for i = 0, noteCount - 1 do
        local retval, selected, muted, startPPQ, endPPQ = reaper.MIDI_GetNote(take, i)
        if selected then
            newSelectedNote = i
            break
        end
    end

    if newSelectedNote ~= -1 and newSelectedNote ~= lastSelectedNote then
        -- selection changed, update new note length
        local _, _, _, startPPQ, endPPQ = reaper.MIDI_GetNote(take, newSelectedNote)
        local length = endPPQ - startPPQ
        -- store the current note length in ExtState
        reaper.SetExtState("AutoNoteLength", "length", tostring(length), false)
        lastSelectedNote = newSelectedNote
        -- Optional: show brief message (comment out if annoying)
        -- reaper.ShowConsoleMsg("New note length set to "..length.." PPQ\n")
    elseif newSelectedNote == -1 then
        lastSelectedNote = -1
    end

    -- defer this script to run again
    reaper.defer(main)
end

-- start the deferred loop
main()

