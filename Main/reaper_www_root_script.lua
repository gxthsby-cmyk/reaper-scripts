-- @description reaper_www_root_script
-- @provides [main] .

-- =========================================
-- Vertical Waveshape Engine (Cached Peaks)
-- Uses existing REAPER peak cache
-- Foolproof: copies needed .reapeaks to web folder, outputs web-relative paths
-- =========================================

-- FIX for dkjson.lua path
package.path = package.path .. ";E:/01 Reaper/REAPER/Scripts/?.lua"
local json = require("dkjson")  -- now it will find dkjson.lua

-- SETTINGS
local ext_name = "Vertical_Waveshapes_Engine"
local lookahead = 5.0   -- seconds of visible waveform

-- Web folder for JSON output (must exist)
local www_path = "E:/01 Reaper/REAPER/reaper_www_root/peaks/"
os.execute("mkdir \""..www_path.."\"")  -- create folder if missing

-- Path to REAPER peak cache (nested)
local peakCachePath = "E:/01 Reaper/Reaper Peaks/"
peakCachePath = peakCachePath:gsub("\\","/")  -- use forward slashes

-- UTIL: convert track color
local function intToRGB(colorInt)
    local r = (colorInt & 0xFF)/255
    local g = ((colorInt >> 8) & 0xFF)/255
    local b = ((colorInt >> 16) & 0xFF)/255
    return r,g,b
end

-- RECURSIVE scan of nested peaks folder to build lookup table
local peak_lookup = {}
local function scanPeaksFolder(folder)
    for file in io.popen('dir "'..folder..'" /b /s'):lines() do
        if file:match("%.reapeaks$") then
            local guid = file:match("([a-f0-9%-]+)%.reapeaks$")
            if guid then
                peak_lookup[guid] = file:gsub("\\","/")
            end
        end
    end
end
scanPeaksFolder(peakCachePath)

-- COPY peak file into web folder, return web-relative path
local function copyPeakToWeb(item)
    local guid = reaper.BR_GetMediaItemGUID(item)
    if not guid then return nil end
    local src = peak_lookup[guid]
    if not src then return nil end
    local dst = www_path .. guid .. ".reapeaks"

    -- copy file
    local fsrc = io.open(src,"rb")
    if not fsrc then return nil end
    local data = fsrc:read("*all")
    fsrc:close()
    local fdst = io.open(dst,"wb")
    if not fdst then return nil end
    fdst:write(data)
    fdst:close()

    return "peaks/" .. guid .. ".reapeaks"  -- web-relative path
end

-- GATHER track/items info recursively (folders + receives)
local function collectTracks()
    local tracks = {}
    local tcount = reaper.CountTracks(0)
    for i=0,tcount-1 do
        local tr = reaper.GetTrack(0,i)
        local _, tname = reaper.GetTrackName(tr)
        local col = reaper.GetTrackColor(tr)
        local r,g,b = intToRGB(col)
        local track = {id=i,name=tname,color={r,g,b},items={}}
        local icount = reaper.CountTrackMediaItems(tr)
        for j=0,icount-1 do
            local it = reaper.GetTrackMediaItem(tr,j)
            local take = reaper.GetActiveTake(it)
            if take and not reaper.TakeIsMIDI(take) then
                local startPos = reaper.GetMediaItemInfo_Value(it,"D_POSITION")
                local endPos = startPos + reaper.GetMediaItemInfo_Value(it,"D_LENGTH")
                local peakfile = copyPeakToWeb(it)
                if peakfile then
                    table.insert(track.items,{
                        id=i.."-"..j,
                        start=startPos,
                        endp=endPos,
                        peakfile=peakfile
                    })
                end
            end
        end
        table.insert(tracks,track)
    end
    return tracks
end

-- MAIN engine loop
function engineMain()
    local playPos = reaper.GetPlayPosition()
    local data = {
        project_time = playPos,
        lookahead = lookahead,
        tracks = collectTracks()
    }

    local jsonFile = www_path.."tracks.json"
    local f = io.open(jsonFile,"w")
    if f then
        f:write(json.encode(data))
        f:close()
    end

    reaper.defer(engineMain)
end

engineMain()

