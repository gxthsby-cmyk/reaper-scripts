-- @description track show like in arrange view
-- @provides [main] .

--[[
ReaScript Name: Track Duplicate Arrange View (gfx buffer)
Author: ChatGPT
Description: Floating window that mirrors first selected track's waveform using cached peaks, drawn via gfx buffer.
Version: 1.0
--]]

local win_w, win_h = 900, 300
local playhead_x = win_w * 0.5
local pixels_per_second = 100

-- Initialize gfx
gfx.init("Track Duplicate View", win_w, win_h)

-- Keep project state count to detect changes
local proj_change_cnt = -1

--------------------------------------------------------------------------------
-- Get first selected track
local function get_first_track()
    if reaper.CountSelectedTracks(0) == 0 then return nil end
    return reaper.GetSelectedTrack(0, 0)
end

--------------------------------------------------------------------------------
-- Build peaks table from item using extra_type = 115
local function Item_GetPeaks(item)
    if not item then return end
    local take = reaper.GetActiveTake(item)
    if not take or reaper.TakeIsMIDI(take) then return end
    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    if item_len <= 0 then return end

    local n_chans = 1
    local n_spls = math.floor(item_len * pixels_per_second)
    if n_spls < 2 then n_spls = 2 end
    local want_extra_type = 115
    local buf = reaper.new_array(n_spls * n_chans * 3)
    buf.clear()

    local retval = reaper.GetMediaItemTake_Peaks(
        take, item_len, 0, n_chans, n_spls, want_extra_type, buf
    )
    local spl_cnt = retval & 0xfffff
    local ext_type = (retval & 0x1000000) >> 24

    if spl_cnt > 0 and ext_type > 0 then
        local Peaks = {}
        for i = 1, n_spls do
            local p = #Peaks
            Peaks[p+1] = buf[i]             -- max
            Peaks[p+2] = buf[n_spls + i]   -- min
            local spectral = buf[n_spls*2 + i] 
            Peaks[p+3] = spectral & 0x7fff
            Peaks[p+4] = (spectral >> 15)/16384
        end
        return Peaks
    end
end

--------------------------------------------------------------------------------
-- Draw peaks into gfx buffer
local function Peaks_Draw(Peaks)
    if not Peaks then return end
    gfx.dest = 0
    gfx.setimgdim(0, win_w, win_h)
    gfx.clear = 0x0
    local center_y = win_h * 0.5
    local scale_y = win_h * 0.4
    gfx.set(0.2,0.6,1,1)
    local n_spls = #Peaks / 4
    for i = 1, n_spls do
        local maxp = Peaks[i*4-3] or 0
        local minp = Peaks[i*4-2] or 0
        local top = center_y - maxp*scale_y
        local bot = center_y - minp*scale_y
        local x = i
        gfx.line(x, top, x, bot, true)
    end
end

--------------------------------------------------------------------------------
-- Detect project change
local function Project_IsChanged()
    local cur_cnt = reaper.GetProjectStateChangeCount(0)
    if cur_cnt ~= proj_change_cnt then
        proj_change_cnt = cur_cnt
        return true
    end
end

--------------------------------------------------------------------------------
-- Main loop
local function main()
    -- Only redraw gfx buffer when project changes
    if Project_IsChanged() then
        local track = get_first_track()
        if track then
            local cnt = reaper.CountTrackMediaItems(track)
            if cnt > 0 then
                local item = reaper.GetTrackMediaItem(track, 0)
                local Peaks = Item_GetPeaks(item)
                if Peaks then Peaks_Draw(Peaks) end
            end
        end
    end

    -- Clear main window
    gfx.set(0,0,0,1)
    gfx.rect(0,0,win_w,win_h,1)

    -- Blit the gfx buffer
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(0, 1, 0, 0, 0, win_w, win_h, 0, 0, win_w, win_h)

    -- Draw fixed vertical playhead
    gfx.set(1,0,0,1)
    gfx.line(playhead_x,0,playhead_x,win_h)

    -- Draw track name
    local track = get_first_track()
    if track then
        local _, name = reaper.GetTrackName(track, "")
        gfx.set(1,1,1,1)
        gfx.x = 4
        gfx.y = win_h - 18
        gfx.drawstr(name)
    end

    gfx.update()
    reaper.defer(main)
end

main()

