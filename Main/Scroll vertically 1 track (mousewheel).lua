-- @description Scroll vertically 1 track (mousewheel)
-- @provides [main] .

-- Scroll vertically by exactly one track height (zoom-aware)
-- Requires JS_ReaScriptAPI

local _, _, _, _, _, _, mousewheel = reaper.get_action_context()
if not mousewheel or mousewheel == 0 then return end

-- Normalize mousewheel (±120 → ±1)
local direction = mousewheel > 0 and 1 or -1

-- Get mouse position
local x, y = reaper.GetMousePosition()

-- Get track under mouse
local track = reaper.GetTrackFromPoint(x, y)
if not track then return end

-- Get actual TCP track height (zoom/theme aware)
local track_h = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
if track_h <= 0 then return end

-- Get TCP window
local tcp = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)
if not tcp then return end

-- Get current vertical scroll position
local _, scroll_y = reaper.JS_Window_GetScrollInfo(tcp, "v")

-- Scroll by exactly one track
local new_scroll = scroll_y - (direction * track_h)

-- Apply scroll
reaper.JS_Window_SetScrollPos(tcp, "v", new_scroll)

