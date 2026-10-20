-- @description Set all bypassed FX offline
-- @author Jack Di Lante
-- @version 1.0
-- @about
--   Sets every bypassed track FX in the current project offline, so the
--   project loads faster next time (offline FX aren't loaded at all). Together
--   with "Auto-online FX when unbypassed", un-bypassing such an FX brings it
--   back online. Save the project afterwards to keep the change.
-- @provides [main] .

local count = 0
reaper.Undo_BeginBlock()
local function do_track(track)
  for fx = 0, reaper.TrackFX_GetCount(track) - 1 do
    if not reaper.TrackFX_GetEnabled(track, fx) and not reaper.TrackFX_GetOffline(track, fx) then
      reaper.TrackFX_SetOffline(track, fx, true)
      count = count + 1
    end
  end
end
do_track(reaper.GetMasterTrack(0))
for i = 0, reaper.CountTracks(0) - 1 do do_track(reaper.GetTrack(0, i)) end
reaper.Undo_EndBlock("Set " .. count .. " bypassed FX offline", -1)
