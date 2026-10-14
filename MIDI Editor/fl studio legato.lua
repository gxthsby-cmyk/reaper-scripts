-- @description fl studio legato
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main=midi_editor] .

--[[
Reaper Lua Script: FL Studio Ctrl+L Note Legato
- Selected notes stretch to the next UNSELECTED note's start
- If no unselected note ahead, stretch to end of MIDI item
--]]
function main()
    local midiEditor = reaper.MIDIEditor_GetActive()
    if not midiEditor then return end
    local take = reaper.MIDIEditor_GetTake(midiEditor)
    if not take or not reaper.TakeIsMIDI(take) then return end
    local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
    if noteCount == 0 then return end
    local item = reaper.GetMediaItemTake_Item(take)
    local itemEndTime = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, itemEndTime)

    -- Gather all notes
    local allNotes = {}
    for i = 0, noteCount-1 do
        local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        allNotes[#allNotes+1] = {index=i, sel=sel, start=startppq, endppq=endppq}
    end

    -- Build sorted unique start positions from UNSELECTED notes only
    local unselStarts = {}
    local startMap = {}
    for _, note in ipairs(allNotes) do
        if not note.sel and not startMap[note.start] then
            unselStarts[#unselStarts+1] = note.start
            startMap[note.start] = true
        end
    end
    table.sort(unselStarts)

    -- Collect edits
    local edits = {}
    for _, note in ipairs(allNotes) do
        if note.sel then
            local nextStart = itemEndPPQ
            for _, uStart in ipairs(unselStarts) do
                if uStart > note.start then
                    nextStart = uStart
                    break
                end
            end
            edits[#edits+1] = {index=note.index, newEnd=nextStart}
        end
    end

    -- Apply in reverse index order
    table.sort(edits, function(a,b) return a.index > b.index end)
    for _, edit in ipairs(edits) do
        reaper.MIDI_SetNote(take, edit.index, nil, nil, nil, edit.newEnd, nil, nil, nil, true)
    end

    reaper.MIDI_Sort(take)
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("FL Studio Ctrl+L Note Legato", -1)
