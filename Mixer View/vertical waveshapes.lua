-- @description vertical waveshapes
-- @provides [main] .

-- Mini Vertical Arrange View 
-- Dockable, resizable, shows track names, skips muted items, follows folder children & receives

-- Load previous state from ExtState
local ext_name = "Vertical_Waveshapes"
local docked  = tonumber(reaper.GetExtState(ext_name, "docked") or 0)
local xpos    = tonumber(reaper.GetExtState(ext_name, "xpos")   or 100)
local ypos    = tonumber(reaper.GetExtState(ext_name, "ypos")   or 100)
local wlen    = tonumber(reaper.GetExtState(ext_name, "wlen")   or 800)
local hlen    = tonumber(reaper.GetExtState(ext_name, "hlen")   or 600)

-- Initial gfx window
local blackHeight = 550
local trackHeight = 40
local margin = 10
local lookahead = 5
local playheadY = blackHeight - 10

gfx.init("Vertical Waveshapes", wlen, hlen, docked, xpos, ypos)

------------------------------------------------------------
-- UTIL
------------------------------------------------------------
function intToRGB(colorInt)
    local r = (colorInt & 0xFF) / 255
    local g = ((colorInt >> 8) & 0xFF) / 255
    local b = ((colorInt >> 16) & 0xFF) / 255
    return r, g, b
end

------------------------------------------------------------
-- PEAK EXTRACTION
------------------------------------------------------------
function GetItemPeaksForWindow(take, startTime, endTime, pixels)
    local source = reaper.GetMediaItemTake_Source(take)
    if not source then return nil end

    local chans = reaper.GetMediaSourceNumChannels(source)
    local duration = endTime - startTime
    if duration <= 0 then return nil end

    local peakrate = pixels / duration
    local samples = math.floor(duration * peakrate + 0.5)
    if samples <= 0 then return nil end

    local buf = reaper.new_array(samples * chans * 2)
    buf.clear()

    local retval = reaper.GetMediaItemTake_Peaks(
        take,
        peakrate,
        startTime,
        chans,
        samples,
        0,
        buf
    )

    if retval <= 0 then return nil end
    return buf, samples, chans
end

------------------------------------------------------------
-- AUDIO ITEM DRAW
------------------------------------------------------------
function drawAudioItem(item, playPos, trackX, trackWidth)
    local muted = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
    if muted ~= 0 then return end

    local take = reaper.GetActiveTake(item)
    if not take or reaper.TakeIsMIDI(take) then return end

    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemLen   = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemEnd   = itemStart + itemLen
    if itemEnd < playPos or itemStart > playPos + lookahead then return end

    local windowStart = math.floor(math.max(itemStart, playPos) * 30) / 30
    local visibleStart = windowStart
    local visibleEnd   = math.min(itemEnd, playPos + lookahead)

    local startPct = (visibleStart - playPos) / lookahead
    local endPct   = (visibleEnd   - playPos) / lookahead
    local barTop   = playheadY - endPct * blackHeight
    local barBot   = playheadY - startPct * blackHeight

    gfx.set(0.15, 0.6, 0.15, 0.25)
    gfx.rect(trackX + 4, barTop, trackWidth - 8, barBot - barTop, 1)

    local buf, samples, chans = GetItemPeaksForWindow(take, visibleStart, visibleEnd, barBot - barTop)
    if not buf then return end

    local midX  = trackX + trackWidth / 2
    local halfW = (trackWidth - 10) / 2
    local duration = visibleEnd - visibleStart
    local peakrate = samples / duration

    for i = 0, samples - 1 do
        local maxP, minP = 0, 0
        for ch = 0, chans - 1 do
            local idx = i * chans + ch + 1
            maxP = math.max(maxP, buf[idx])
            minP = math.min(minP, buf[idx + samples * chans])
        end

        local peakTime = visibleStart + i / peakrate
        local tPct = (peakTime - playPos) / lookahead
        if tPct >= 0 and tPct <= 1 then
            local y = playheadY - tPct * blackHeight
            local x1 = midX + minP * halfW
            local x2 = midX + maxP * halfW
            gfx.set(0.1, 0.9, 0.1, 1)
            gfx.line(x1, y, x2, y)
        end
    end
end

------------------------------------------------------------
-- TRACK ITEM COLLECTION WITH FOLDERS & RECEIVES
------------------------------------------------------------
function getAllItems(track, visited)
    visited = visited or {}
    if visited[track] then return {} end
    visited[track] = true

    local items = {}

    -- Add this track's audio items
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
        table.insert(items, reaper.GetTrackMediaItem(track,i))
    end

    -- Include folder children recursively
    local folderDepth = reaper.GetMediaTrackInfo_Value(track,"I_FOLDERDEPTH")
    if folderDepth > 0 then
        local idx = reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER") - 1
        local depth = folderDepth
        for i = idx+1, reaper.CountTracks(0)-1 do
            local child = reaper.GetTrack(0,i)
            depth = depth + reaper.GetMediaTrackInfo_Value(child,"I_FOLDERDEPTH")
            local childItems = getAllItems(child, visited)
            for _, it in ipairs(childItems) do table.insert(items,it) end
            if depth <= 0 then break end
        end
    end

    -- Include all tracks that send audio to this track (receives)
    local recvCount = reaper.GetTrackNumSends(track, -1) -- -1 = receives
    for i=0, recvCount-1 do
        local src = reaper.BR_GetMediaTrackSendInfo_Track(track, -1, i, 0)
        if src then
            local recvItems = getAllItems(src, visited)
            for _, it in ipairs(recvItems) do table.insert(items,it) end
        end
    end

    return items
end

------------------------------------------------------------
-- DRAW TRACKS
------------------------------------------------------------
function drawTracks()
    -- Vertical scaling
    local totalH = gfx.h
    if totalH > blackHeight + trackHeight then
        local scale = totalH / (blackHeight + trackHeight)
        blackHeight = blackHeight * scale
        trackHeight = trackHeight * scale
    end
    playheadY = blackHeight - 10

    gfx.set(0, 0, 0, 1)
    gfx.rect(0, 0, gfx.w, blackHeight, 1)

    local tc = reaper.CountSelectedTracks(0)
    if tc == 0 then
        gfx.set(1, 1, 1, 1)
        gfx.drawstr("No track selected", 10, blackHeight / 2 - 8)
        return
    end

    local playPos = reaper.GetPlayPosition()
    local tw = (gfx.w - margin * 2) / tc

    -- horizontal playhead
    gfx.set(1, 0, 0, 1)
    gfx.line(margin, playheadY, gfx.w - margin, playheadY)

    for i = 0, tc - 1 do
        local tr = reaper.GetSelectedTrack(0, i)
        local tx = margin + i * tw

        local r, g, b = 0.4, 0.4, 0.4
        local col = reaper.GetTrackColor(tr)
        if col ~= 0 then r, g, b = intToRGB(col) end

        gfx.set(r, g, b, 1)
        gfx.rect(tx, blackHeight, tw - 5, trackHeight, 1)

        local allItems = getAllItems(tr)
        for _, item in ipairs(allItems) do
            drawAudioItem(item, playPos, tx, tw)
        end

        local _, name = reaper.GetTrackName(tr)
        
        -- set text color to black
        gfx.set(0, 0, 0, 1)
        
        -- measure text
        local text_w, text_h = gfx.measurestr(name)
        
        -- center text horizontally & vertically in track box
        gfx.x = tx + (tw - text_w) / 2
        gfx.y = blackHeight + (trackHeight - text_h) / 2
        
        gfx.drawstr(name)
        
    end
end

------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------
function main()
    gfx.setfont(1, "Arial", 14)
    drawTracks()

    -- Save dock, position, size every frame
    local dock = gfx.dock(-1)
    reaper.SetExtState(ext_name, "docked", tostring(dock), true)
    reaper.SetExtState(ext_name, "xpos", tostring(gfx.x), true)
    reaper.SetExtState(ext_name, "ypos", tostring(gfx.y), true)
    reaper.SetExtState(ext_name, "wlen", tostring(gfx.w), true)
    reaper.SetExtState(ext_name, "hlen", tostring(gfx.h), true)

    if gfx.getchar() >= 0 then
        reaper.defer(main)
    end
end

main()

