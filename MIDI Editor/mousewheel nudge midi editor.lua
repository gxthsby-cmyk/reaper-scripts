-- @description mousewheel nudge midi editor
-- @provides [main=midi_editor] .

-- Mousewheel-direction MIDI note nudger for REAPER
-- Works only in MIDI Editor and detects wheel direction
-- Uses a deferred gfx loop

local nudge = 1 -- PPQ amount per wheel tick (change to taste)

-- make tiny invisible window
gfx.init("mw_nudge", 1, 1, 0, -1000, -1000)

function nudge_notes(amount)
    local editor = reaper.MIDIEditor_GetActive()
    if not editor then return end

    local take = reaper.MIDIEditor_GetTake(editor)
    if not take then return end

    reaper.Undo_BeginBlock()
    reaper.MIDI_DisableSort(take)

    local i = -1
    while true do
        local ok, sel, mut, st, en, ch, pitch, vel = reaper.MIDI_GetNote(take, i)
        if not ok then break end
        if sel then
            reaper.MIDI_SetNote(take, i, nil, nil, st + amount, en + amount, nil, nil, nil, true)
        end
        i = i + 1
    end

    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock("Mousewheel nudge MIDI notes", -1)
end

function loop()
    local char = gfx.getchar()

    -- mousewheel codes
    if char == 120 then          -- wheel UP
        nudge_notes(nudge)
    elseif char == 119 then      -- wheel DOWN
        nudge_notes(-nudge)
    end

    if char >= 0 then
        reaper.defer(loop)
    end
end

loop()

