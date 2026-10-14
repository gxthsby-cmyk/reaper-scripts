-- @description PRO TOOLS TRIM TEST2
-- @provides [main] .

-- =========================================================
-- Automation Items to "End", Restart on Rewind (FIXED)
-- =========================================================

-- -----------------------------
-- Utilities
-- -----------------------------

function GetMarkerByName(name)
  local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
  for i = 0, num_markers + num_regions - 1 do
    local _, isrgn, pos, _, markname = reaper.EnumProjectMarkers(i)
    if not isrgn and markname == name then
      return pos
    end
  end
  return nil
end

function GetArmedEnvelopes(track)
  local envs = {}
  local env_count = reaper.CountTrackEnvelopes(track)
  for i = 0, env_count - 1 do
    local env = reaper.GetTrackEnvelope(track, i)
    if reaper.GetEnvelopeInfo_Value(env, "I_ARM") == 1 then
      table.insert(envs, env)
    end
  end
  return envs
end

function SetSelectedTracksAutomationMode(mode)
  local cnt = reaper.CountSelectedTracks(0)
  for i = 0, cnt - 1 do
    reaper.SetTrackAutomationMode(
      reaper.GetSelectedTrack(0, i),
      mode
    )
  end
end

-- -----------------------------
-- MAIN AUTOMATION PROCESS
-- -----------------------------

function RunAutomationProcess()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- ✅ Correct start position
  local play_state = reaper.GetPlayState()
  local start_pos

  if play_state == 1 then
    start_pos = reaper.GetPlayPosition()
  else
    start_pos = reaper.GetCursorPosition()
  end

  local end_pos = GetMarkerByName("End")
  if not end_pos or end_pos <= start_pos then
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Automation failed", -1)
    return
  end

  -- Write existing automation items
  reaper.Main_OnCommand(42090, 0) -- Write automation items to envelope

  -- Create automation items
  local sel_tracks = reaper.CountSelectedTracks(0)
  for i = 0, sel_tracks - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    for _, env in ipairs(GetArmedEnvelopes(track)) do
      reaper.InsertAutomationItem(
        env,
        -1,
        start_pos,
        end_pos - start_pos
      )
    end
  end

  -- Touch mode
  SetSelectedTracksAutomationMode(2)

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Create automation items to End", -1)
end

-- -----------------------------
-- INITIAL RUN
-- -----------------------------

RunAutomationProcess()
reaper.OnPlayButton()

-- -----------------------------
-- PLAYBACK MONITOR
-- -----------------------------

local last_play_pos = reaper.GetPlayPosition()

function MonitorPlayback()
  local play_state = reaper.GetPlayState()
  local play_pos = reaper.GetPlayPosition()

  -- Stop or pause → Trim/Read
  if play_state == 0 or play_state == 2 then
    SetSelectedTracksAutomationMode(0)
    return
  end

  -- Rewind detected → restart script
  if play_state == 1 and play_pos < last_play_pos - 0.01 then
    RunAutomationProcess()
  end

  last_play_pos = play_pos
  reaper.defer(MonitorPlayback)
end

MonitorPlayback()

