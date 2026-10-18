-- @description VSX system auto-pause
-- @author Jack Di Lante
-- @version 1.0
-- @about
--   Pauses the system-wide VSX (Carla) while REAPER plays or records, so other
--   apps' audio doesn't mix into the session, and resumes it when REAPER stops.
--   Runs in the background, started from Scripts/__startup.lua.
--   Needs ~/.local/bin/vsx-system (sends Carla OSC set_active on UDP 22752).
-- @provides [main] .

local cmd = os.getenv("HOME") .. "/.local/bin/vsx-system"
local paused = false

local function set_vsx(on)
  os.execute(cmd .. (on and " on" or " off") .. " >/dev/null 2>&1 &")
end

local function loop()
  local playing = reaper.GetPlayState() & 5 ~= 0 -- 1 = playing, 4 = recording
  if playing ~= paused then
    paused = playing
    set_vsx(not playing)
  end
  reaper.defer(loop)
end

reaper.atexit(function() if paused then set_vsx(true) end end)
loop()
