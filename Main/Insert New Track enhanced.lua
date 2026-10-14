-- @description Insert New Track enhanced
-- @provides [main] .

reaper.Undo_BeginBlock()

local selTrack = reaper.GetSelectedTrack(0, 0)
local trackCount = reaper.CountTracks(0)

-- CASE 1: No track selected → normal insert
if not selTrack then
    reaper.InsertTrackAtIndex(trackCount, true)
    local newTrack = reaper.GetTrack(0, trackCount)
    reaper.SetTrackColor(newTrack, 100) -- default gray
    reaper.SetOnlyTrackSelected(newTrack)
    reaper.Undo_EndBlock("Insert new default track", -1)
    return
end

-- CASE 2: Track selected → smart insert
local sel_idx = reaper.GetMediaTrackInfo_Value(selTrack, "IP_TRACKNUMBER") - 1
local insert_idx = sel_idx + 1
local parent_idx = -1

-- Find folder parent
local depthSum = 0
for i = sel_idx, 0, -1 do
    local t = reaper.GetTrack(0, i)
    local depth = reaper.GetMediaTrackInfo_Value(t, "I_FOLDERDEPTH")
    depthSum = depthSum + depth
    if depth == 1 then
        parent_idx = i
        break
    end
end

-- If inside a folder, insert before the track where folder ends
if parent_idx >= 0 then
    local depth = 1
    local i = parent_idx + 1
    while i < trackCount and depth > 0 do
        local t = reaper.GetTrack(0, i)
        depth = depth + reaper.GetMediaTrackInfo_Value(t, "I_FOLDERDEPTH")
        i = i + 1
    end
    insert_idx = i - 1 -- insert just before folder ends
end

-- Insert new track
reaper.InsertTrackAtIndex(insert_idx, true)
local newTrack = reaper.GetTrack(0, insert_idx)

-- Copy color
local color = reaper.GetTrackColor(selTrack)
reaper.SetTrackColor(newTrack, color)

-- Copy groups
local ok, chunk = reaper.GetTrackStateChunk(selTrack, "", false)
local ok2, newChunk = reaper.GetTrackStateChunk(newTrack, "", false)
if ok and ok2 then
    local grp_line = chunk:match("P_TRACKGROUPS.-\n")
    if grp_line then
        newChunk = newChunk:gsub("P_TRACKGROUPS.-\n", "")
        newChunk = newChunk:gsub("(\n)$", grp_line.."%1")
        reaper.SetTrackStateChunk(newTrack, newChunk, false)
    end
end

-- Copy input
local recInput = reaper.GetMediaTrackInfo_Value(selTrack, "I_RECINPUT")
local recMon   = reaper.GetMediaTrackInfo_Value(selTrack, "I_RECMON")
reaper.SetMediaTrackInfo_Value(newTrack, "I_RECINPUT", recInput)
reaper.SetMediaTrackInfo_Value(newTrack, "I_RECMON", recMon)

-- Make sure new track is not a folder itself
reaper.SetMediaTrackInfo_Value(newTrack, "I_FOLDERDEPTH", 0)

reaper.SetOnlyTrackSelected(newTrack)
reaper.Undo_EndBlock("Insert smart track in folder with input", -1)

