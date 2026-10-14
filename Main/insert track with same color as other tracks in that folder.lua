-- @description insert track with same color as other tracks in that folder
-- @provides [main] .

-- Insert track with same color as its folder (parent track)

local track = reaper.GetSelectedTrack(0,0)
if not track then return end

-- Check if selected track is folder parent
local depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

-- If selected track is NOT a folder parent, find its parent
local function get_parent(t)
    local idx = reaper.GetMediaTrackInfo_Value(t, "IP_TRACKNUMBER")
    local depth = 0
    for i = idx-1, 1, -1 do
        local tr = reaper.GetTrack(0, i-1)
        depth = depth + reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
        if depth < 0 then return tr end
    end
end

local parent = nil

if depth == 1 then
    -- Selected track IS a folder parent
    parent = track
else
    -- Find parent
    parent = get_parent(track)
end

if not parent then return end

-- Get parent track color
local color = reaper.GetTrackColor(parent)

-- Determine insert index
local parent_idx = reaper.GetMediaTrackInfo_Value(parent, "IP_TRACKNUMBER")
local insert_idx = parent_idx -- Insert as first child

-- Insert new track
reaper.InsertTrackAtIndex(insert_idx, true)
local newTrack = reaper.GetTrack(0, insert_idx)

-- Apply color
reaper.SetTrackColor(newTrack, color)

-- Select the new track
reaper.SetOnlyTrackSelected(newTrack)

