-- @description Startup children visible in tracks
-- @provides [main] .

-- Select all folder tracks
reaper.Undo_BeginBlock()

local num_tracks = reaper.CountTracks(0)
local folder_tracks = {}

-- First, deselect all tracks
for i = 0, num_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    reaper.SetTrackSelected(track, false)
end

-- Select folder tracks
for i = 0, num_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    local _, folder_depth = reaper.GetTrackInfo_Value(track, "I_FOLDERDEPTH")
    if folder_depth > 0 then
        reaper.SetTrackSelected(track, true)
        table.insert(folder_tracks, track)
    end
end

-- Function to get children of a folder track
function getFolderChildren(folder)
    local children = {}
    local folder_depth = reaper.GetTrackDepth(folder)
    local folder_idx = reaper.GetMediaTrackInfo_Value(folder, "IP_TRACKNUMBER") - 1
    for i = folder_idx + 1, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local depth = reaper.GetTrackDepth(track)
        if depth <= folder_depth then break end
        table.insert(children, track)
    end
    return children
end

-- Check children visibility and make them visible if any hidden
for _, folder in ipairs(folder_tracks) do
    local children = getFolderChildren(folder)
    local all_visible = true
    for _, child in ipairs(children) do
        local vis = reaper.GetMediaTrackInfo_Value(child, "B_SHOWINTCP")
        if vis == 0 then
            all_visible = false
            break
        end
    end
    if not all_visible then
        for _, child in ipairs(children) do
            reaper.SetMediaTrackInfo_Value(child, "B_SHOWINTCP", 1) -- show in TCP
            reaper.SetMediaTrackInfo_Value(child, "B_SHOWINMIXER", 1) -- show in Mixer
        end
    end
end

reaper.TrackList_AdjustWindows(false)
reaper.Undo_EndBlock("Select all folder tracks and show hidden children", -1)

