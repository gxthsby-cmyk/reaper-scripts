-- @description add fx to selected or last touched track
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

-- Step 1: Get the first selected track
local track = reaper.GetSelectedTrack(0, 0)

-- Step 2: Do nothing if no track is selected
if not track then
    reaper.ShowConsoleMsg("No track selected.\n")
    return
end

-- Step 3: Remember current selection
local original_tracks = {}
for i = 0, reaper.CountSelectedTracks(0)-1 do
    original_tracks[i+1] = reaper.GetSelectedTrack(0,i)
end

-- Step 4: Select only our target track
reaper.SetOnlyTrackSelected(track)

-- Step 5: Open the FX chain window
reaper.TrackFX_Show(track, -1, 1)

-- Step 6: Trigger the Add FX action (Insert button)
reaper.Main_OnCommand(40297, 0)

-- Step 7: Restore original selection
reaper.Main_OnCommand(40289, 0) -- "Unselect all tracks"
for _, t in ipairs(original_tracks) do
    reaper.SetTrackSelected(t, true)
end

