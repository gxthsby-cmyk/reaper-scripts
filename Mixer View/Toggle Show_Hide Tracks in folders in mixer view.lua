-- @description Toggle Show_Hide Tracks in folders in mixer view
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

-- Toggle Show/Hide Children of All Folder Tracks in Mixer
local trackCount = reaper.CountTracks(0)

for i = 0, trackCount-1 do
    local track = reaper.GetTrack(0, i)
    if track then
        -- Check if the track is a folder using GetMediaTrackInfo_Value
        local folderDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
        if folderDepth == 1 then
            -- Folder track found, toggle mixer visibility of its children
            local showState = reaper.GetMediaTrackInfo_Value(track, "I_SHOWMIX") -- 0=normal,1=minimized,2=children shown
            if showState == 2 then
                reaper.SetMediaTrackInfo_Value(track, "I_SHOWMIX", 1) -- hide children
            else
                reaper.SetMediaTrackInfo_Value(track, "I_SHOWMIX", 2) -- show children
            end
        end
    end
end

-- Refresh mixer
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

