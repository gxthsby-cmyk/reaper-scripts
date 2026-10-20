-- @description Scroll vertically 1 track (mousewheel)
-- @author Jack Di Lante
-- @version 1.1
-- @changelog Fast scrolling no longer freezes REAPER: wheel ticks are combined and applied at most ~60 times per second, and the scroll position is kept in range.
-- @provides [main] .

-- Scroll vertically by exactly one track height per wheel tick (zoom-aware)
-- Requires JS_ReaScriptAPI
--
-- A fast wheel spin launches this script many times per second. Scrolling on
-- every launch made REAPER redraw the TCP and arrange view for each tick until
-- it locked up, so each launch only adds its tick to a shared counter and the
-- total is applied at most once per frame.

local SECTION = "JDL_ScrollVertically1Track"
local MIN_INTERVAL = 1 / 60

-- When launched again while a previous launch is still waiting to apply its
-- scroll, stop the old one and run the new one (no "already running" prompt).
if reaper.set_action_options then reaper.set_action_options(1 | 2) end

local _, _, _, _, _, _, mousewheel = reaper.get_action_context()
if not mousewheel or mousewheel == 0 then return end

local function get_num(key)
  return tonumber(reaper.GetExtState(SECTION, key)) or 0
end

-- Normalize mousewheel (±120 → ±1) and add it to the ticks not yet applied
reaper.SetExtState(SECTION, "pending", tostring(get_num("pending") + (mousewheel > 0 and 1 or -1)), false)

local function apply()
  local ticks = get_num("pending")
  reaper.SetExtState(SECTION, "pending", "0", false)
  reaper.SetExtState(SECTION, "last_apply", tostring(reaper.time_precise()), false)
  if ticks == 0 then return end

  -- Get track under mouse
  local x, y = reaper.GetMousePosition()
  local track = reaper.GetTrackFromPoint(x, y)
  if not track then return end

  -- Get actual TCP track height (zoom/theme aware)
  local track_h = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
  if track_h <= 0 then return end

  -- Get TCP window
  local tcp = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)
  if not tcp then return end

  -- Get current vertical scroll position and range
  local ok, scroll_y, page, min_y, max_y = reaper.JS_Window_GetScrollInfo(tcp, "v")
  if not ok then return end

  -- Scroll by one track per tick, kept inside the scrollable range
  local new_scroll = scroll_y - (ticks * track_h)
  new_scroll = math.max(min_y, math.min(new_scroll, max_y - page + 1))

  -- Already at the top/bottom: don't trigger a redraw for nothing
  if new_scroll ~= scroll_y then
    reaper.JS_Window_SetScrollPos(tcp, "v", math.floor(new_scroll))
  end
end

-- Apply now if the last scroll was long enough ago, otherwise wait for the
-- rest of the frame (newer ticks that arrive meanwhile are added to the total)
local wait_until = get_num("last_apply") + MIN_INTERVAL
local function wait()
  if reaper.time_precise() >= wait_until then apply() else reaper.defer(wait) end
end
wait()
