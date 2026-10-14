-- @description Open plugins main monitor
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

--[[ 
FX Window Main Monitor Script
Forces new FX windows to open on your main monitor,
but respects manual repositioning after first open.
--]]

function main()
    local hwnd = reaper.JS_Window_GetForeground() -- get current window
    if not hwnd then return end
    
    -- check if window is an FX window
    local title = reaper.JS_Window_GetTitle(hwnd)
    if title:match("FX:") then
        local screenX = reaper.GetSystemMetrics(0) -- screen width
        local screenY = reaper.GetSystemMetrics(1) -- screen height

        -- desired top-left position on main monitor
        local left = 100
        local top = 100

        -- get current position
        local curLeft, curTop, curRight, curBottom = reaper.JS_Window_GetRect(hwnd)
        
        -- only move if window is off main monitor (e.g., left < 0)
        if curLeft < 0 or curTop < 0 then
            reaper.JS_Window_SetPosition(hwnd, left, top)
        end
    end
end

reaper.defer(main)

