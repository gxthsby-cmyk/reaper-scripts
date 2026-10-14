-- @description Context aware smart delete
-- @provides [main] .

reaper.Undo_BeginBlock()

local selTrackCount = reaper.CountSelectedTracks(0)
local selItemCount  = reaper.CountSelectedMediaItems(0)

-- FUNCTION TO CHECK IF TRACK HAS SELECTED ENVELOPE POINTS
local function trackHasSelectedEnvelopePoints(tr)
    local envCount = reaper.CountTrackEnvelopes(tr)
    for e = 0, envCount-1 do
        local env = reaper.GetTrackEnvelope(tr, e)
        local br_env = reaper.BR_EnvAlloc(env, false)
        local active, visible, armed = reaper.BR_EnvGetProperties(br_env, true, true, true)
        if visible and armed then
            local pointCount = reaper.CountEnvelopePoints(env)
            for p = 0, pointCount-1 do
                local _, _, _, _, _, selected = reaper.GetEnvelopePoint(env, p)
                if selected then
                    reaper.BR_EnvFree(br_env, 0)
                    return true
                end
            end
        end
        reaper.BR_EnvFree(br_env, 0)
    end
    return false
end

-- FUNCTION TO DELETE SELECTED ENVELOPE POINTS (outside automation items)
local function deleteSelectedEnvelopePoints()
    for j = 0, selTrackCount-1 do
        local track = reaper.GetSelectedTrack(0, j)
        local env_count = reaper.CountTrackEnvelopes(track)
        for m = 0, env_count-1 do
            local env = reaper.GetTrackEnvelope(track, m)
            local br_env = reaper.BR_EnvAlloc(env, false)
            local active, visible, armed = reaper.BR_EnvGetProperties(br_env, true, true, true)
            if visible and armed then
                local env_points_count = reaper.CountEnvelopePoints(env)
                for p = env_points_count-1, 0, -1 do
                    local _, _, _, _, _, selectedOut = reaper.GetEnvelopePoint(env, p)
                    if selectedOut then
                        -- Delete normal envelope points (outside automation items)
                        reaper.BR_EnvDeletePoint(br_env, p)
                    end
                end
                reaper.BR_EnvFree(br_env, 1)
                reaper.Envelope_SortPoints(env)
            end
        end
    end
end

-- FUNCTION TO CHECK IF TRACK HAS SELECTED AUTOMATION ITEMS
local function trackHasSelectedAutomationItems(tr)
    local envCount = reaper.CountTrackEnvelopes(tr)
    for e = 0, envCount-1 do
        local env = reaper.GetTrackEnvelope(tr, e)
        local aiCount = reaper.CountAutomationItems(env)
        for i = 0, aiCount-1 do
            local selected = reaper.GetSetAutomationItemInfo(env, i, "B_UISEL", 0, false)
            if selected then return true end
        end
    end
    return false
end

-- CHECK IF ANY SELECTED TRACK HAS ENVELOPE POINTS OR AUTOMATION ITEMS
local hasSelectedEnvPoint = false
local hasSelectedAutoItem = false
for i = 0, selTrackCount-1 do
    local tr = reaper.GetSelectedTrack(0, i)
    if trackHasSelectedEnvelopePoints(tr) then hasSelectedEnvPoint = true end
    if trackHasSelectedAutomationItems(tr) then hasSelectedAutoItem = true end
    if hasSelectedEnvPoint and hasSelectedAutoItem then break end
end

-- SMART DELETE LOGIC
if selTrackCount > 0 and selItemCount == 0 and not hasSelectedEnvPoint and not hasSelectedAutoItem then
    -- Only tracks selected → delete track
    local topIndex = math.huge
    for i = 0, selTrackCount-1 do
        local tr = reaper.GetSelectedTrack(0, i)
        local idx = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
        if idx < topIndex then topIndex = idx end
    end
    local deleteIndex = math.floor(topIndex) - 1
    reaper.Main_OnCommand(40005, 0) -- Remove tracks
    local newTrackCount = reaper.CountTracks(0)
    local selectTrack = nil
    if deleteIndex > 0 then
        selectTrack = reaper.GetTrack(0, deleteIndex - 1)
    elseif newTrackCount > 0 then
        selectTrack = reaper.GetTrack(0, 0)
    end
    if selectTrack then reaper.SetOnlyTrackSelected(selectTrack) end

elseif selTrackCount > 0 and selItemCount > 0 or hasSelectedEnvPoint or hasSelectedAutoItem then
    -- Delete items, envelope points, and automation items
    if selItemCount > 0 then reaper.Main_OnCommand(40006, 0) end
    if hasSelectedEnvPoint then
        deleteSelectedEnvelopePoints()           -- normal envelope points
        reaper.Main_OnCommand(40333, 0)          -- points inside automation items
    end
    if hasSelectedAutoItem then
        reaper.Main_OnCommand(42086, 0)          -- delete selected automation items
    end

else
    -- No tracks selected → delete items/envelope points/automation items
    reaper.Main_OnCommand(40006, 0)
    if hasSelectedEnvPoint then
        deleteSelectedEnvelopePoints()
        reaper.Main_OnCommand(40333, 0)
    end
    if hasSelectedAutoItem then reaper.Main_OnCommand(42086, 0) end
end

reaper.Undo_EndBlock("Smart Delete", -1)
reaper.UpdateArrange()

