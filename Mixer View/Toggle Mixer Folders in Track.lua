-- @description Toggle Mixer Folders in Track
-- @provides [main] .

-- Toggle Mixer Visibility for "Mix" Folder and All Tracks
-- Toggles between:
-- 1. Showing only "Mix" folder and its children
-- 2. Showing all tracks

-- Get current toggle state from project (0 = all shown, 1 = only Mix)
local _, state = reaper.GetProjExtState(0, "MixToggle", "State")
state = tonumber(state) or 0

-- Count tracks
local trackCount = reaper.CountTracks(0)

-- Find the "Mix" track
local mixTrack = nil
for i = 0, trackCount - 1 do
    local track = reaper.GetTrack(0, i)
    local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if trackName == "Mix" then
        mixTrack = track
        break
    end
end

-- Function to check if a track is child of a folder
local function IsChildOf(track, parentTrack)
    local t = track
    while t do
        t = reaper.GetParentTrack(t)
        if t == parentTrack then return true end
    end
    return false
end

if state == 0 then
    -- Hide everything except Mix and its children
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        if track == mixTrack or (mixTrack and IsChildOf(track, mixTrack)) then
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
        else
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
        end
    end
    state = 1
else
    -- Show all tracks
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
    end
    state = 0
end

-- Save new state
reaper.SetProjExtState(0, "MixToggle", "State", tostring(state))
reaper.TrackList_AdjustWindows(false)

