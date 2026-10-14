-- @description key detecter
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

-- Detect the key of selected MIDI items in Reaper

-- Major and minor scale patterns in semitones
local majorScale = {0,2,4,5,7,9,11}
local minorScale = {0,2,3,5,7,8,10}

-- Function to count notes in each key
local function countScaleMatches(notes, scale)
    local counts = {}
    for root = 0,11 do
        counts[root] = 0
        for _, note in ipairs(notes) do
            local interval = (note - root) % 12
            for _, s in ipairs(scale) do
                if interval == s then
                    counts[root] = counts[root] + 1
                    break
                end
            end
        end
    end
    return counts
end

-- Collect all MIDI notes from selected items
local notes = {}
local itemCount = reaper.CountSelectedMediaItems(0)
if itemCount == 0 then reaper.MB("No items selected","Error",0) return end

for i=0,itemCount-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local take = reaper.GetActiveTake(item)
    if take and reaper.TakeIsMIDI(take) then
        local _, notecnt = reaper.MIDI_CountEvts(take)
        for n=0,notecnt-1 do
            local _, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, n)
            table.insert(notes, pitch)
        end
    end
end

if #notes == 0 then reaper.MB("No MIDI notes found","Error",0) return end

-- Count matches for all roots
local majorCounts = countScaleMatches(notes, majorScale)
local minorCounts = countScaleMatches(notes, minorScale)

-- Find the best match
local bestMajor, bestMajorCount = nil, -1
for root,count in pairs(majorCounts) do
    if count > bestMajorCount then
        bestMajor, bestMajorCount = root,count
    end
end

local bestMinor, bestMinorCount = nil, -1
for root,count in pairs(minorCounts) do
    if count > bestMinorCount then
        bestMinor, bestMinorCount = root,count
    end
end

-- Map root numbers to note names
local noteNames = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}

-- Compare which scale has more matches
local keyName = ""
if bestMajorCount >= bestMinorCount then
    keyName = noteNames[bestMajor+1].." Major"
else
    keyName = noteNames[bestMinor+1].." Minor"
end

reaper.MB("Detected key: "..keyName,"Key Detection",0)

