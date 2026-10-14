-- @description Adjust last touched parameter with dynamic step based on N steps
-- @version 1.05
-- @author MPL (modified)
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Step size dynamically calculated from parameter range, based on steps

local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
local STEPS = 40  -- number of steps to divide parameter into

function mainsub(step, dir)
    if not dir then return end
    local retval, trackid, fxid, paramid = reaper.GetLastTouchedFX()
    if retval then
        local take_id = fxid>>16
        local item_id = trackid>>16
        local fxid = fxid&0xFFFF
        local trackid = trackid&0xFFFF
        local track = trackid == 0 and reaper.GetMasterTrack(0) or reaper.GetTrack(0, trackid-1)
        if track then
            if item_id ~= 0 then
                local item = reaper.GetTrackMediaItem(track, item_id-1)
                local take = reaper.GetTake(item, take_id)
                local value0 = reaper.TakeFX_GetParamNormalized(take, fxid, paramid)
                local newval = math.max(0, math.min(value0 + step*dir, 1))
                reaper.TakeFX_SetParamNormalized(take, fxid, paramid, newval)
            else
                local value0 = reaper.TrackFX_GetParamNormalized(track, fxid, paramid)
                local newval = math.max(0, math.min(value0 + step*dir, 1))
                reaper.TrackFX_SetParamNormalized(track, fxid, paramid, newval)
            end
        end
    end
end

function main()
    local step = 2 / STEPS -- normalized step based on number of steps
    local dir = nil
    val = val / resolution
    if mode == 0 then
        if val > 0.5 then dir = 1 elseif val < 0.5 then dir = -1 end
    elseif mode > 0 then
        if val > 0 then dir = 1 elseif val < 0 then dir = -1 end
    end
    mainsub(step, dir)
end

reaper.defer(main)

