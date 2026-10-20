-- @description Scroll vertically 1 track (mousewheel)
-- @author Jack Di Lante
-- @version 1.3
-- @changelog Also scrolls with the mouse over the arrange view (not only the track panel). Fast wheel spins are combined instead of redrawing on every tick, and the scroll position is kept in range.
-- @provides [main] .

-- Scroll vertically by exactly one track height per wheel tick (zoom-aware)
-- Requires JS_ReaScriptAPI
--
-- With the mouse over the arrange view GetTrackFromPoint often finds no track,
-- so the track at the top of the view is used for the height instead.
-- A fast wheel spin (especially on high-resolution wheels) launches this script
-- up to ~100 times per second; ticks that arrive sooner than REAPER can redraw
-- are saved and added to the next scroll. The script never defers, so each
-- launch finishes immediately.

local SECTION = "JDL_ScrollVertically1Track"
local MIN_INTERVAL = 1 / 60 -- never scroll more often than this
local MAX_INTERVAL = 0.1 -- even after a slow redraw, scroll again this soon
local PENDING_MAX_AGE = 0.3 -- saved ticks older than this are dropped

local _, _, _, _, _, _, mousewheel = reaper.get_action_context()
if not mousewheel or mousewheel == 0 then return end

local function get_num(key)
  return tonumber(reaper.GetExtState(SECTION, key)) or 0
end

local function set_num(key, value)
  reaper.SetExtState(SECTION, key, tostring(value), false)
end

local now = reaper.time_precise()

-- Normalize mousewheel (any positive/negative step → ±1) and add saved ticks
local ticks = mousewheel > 0 and 1 or -1
if now - get_num("pending_time") < PENDING_MAX_AGE then
  ticks = ticks + get_num("pending")
end

-- Too soon after the last scroll: save the ticks for the next one
local interval = math.min(MAX_INTERVAL, math.max(MIN_INTERVAL, get_num("redraw_cost") * 1.5))
if now - get_num("last_apply") < interval then
  set_num("pending", ticks)
  set_num("pending_time", now)
  return
end
set_num("pending", 0)
set_num("last_apply", now)
if ticks == 0 then return end

-- Topmost track visible in the TCP
local function top_visible_track()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    if reaper.IsTrackVisible(tr, false) then
      local top = reaper.GetMediaTrackInfo_Value(tr, "I_TCPY")
      if top + reaper.GetMediaTrackInfo_Value(tr, "I_TCPH") > 0 then return tr end
    end
  end
end

-- Get track under mouse, or the top track in view
local x, y = reaper.GetMousePosition()
local track = reaper.GetTrackFromPoint(x, y) or top_visible_track()
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
new_scroll = math.floor(math.max(min_y, math.min(new_scroll, max_y - page + 1)))

-- Already at the top/bottom: don't trigger a redraw for nothing
if new_scroll == scroll_y then return end

-- Apply scroll, and remember how long REAPER took so fast spins wait for it
reaper.JS_Window_SetScrollPos(tcp, "v", new_scroll)
set_num("redraw_cost", reaper.time_precise() - now)
