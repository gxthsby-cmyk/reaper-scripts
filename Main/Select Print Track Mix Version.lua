-- @description Select Print Track Mix Version
-- @provides [main] .

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Get project folder path
local projPath = reaper.GetProjectPath("")
local sep = package.config:sub(1,1)

-- Find or create "Mix Versions" track
local mixTrack = nil
for i=0,reaper.CountTracks(0)-1 do
    local tr = reaper.GetTrack(0,i)
    local _, name = reaper.GetTrackName(tr)
    if name == "Mix Versions" then
        mixTrack = tr
        break
    end
end

if not mixTrack then
    local idx = reaper.CountTracks(0)
    reaper.InsertTrackAtIndex(idx, true)
    mixTrack = reaper.GetTrack(0, idx)
    reaper.GetSetMediaTrackInfo_String(mixTrack, "P_NAME", "Mix Versions", true)
    reaper.SetMediaTrackInfo_Value(mixTrack, "B_MUTE", 1)
    reaper.SetMediaTrackInfo_Value(mixTrack, "I_SOLO", 1)
end

reaper.SetOnlyTrackSelected(mixTrack)

-- Move playhead to marker named "Start"
local startPos = 0
local _, numMarkers, _, _ = reaper.CountProjectMarkers(0)
for i=0,numMarkers-1 do
    local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
    if not isrgn and name=="Start" then
        startPos = pos
        break
    end
end
reaper.SetEditCurPos(startPos, true, true)

-- Scan project folder (no Media subfolder!) for files with "MIX r<number>"
local function listMixFiles()
    local revFiles = {}
    local i = 0
    local file = reaper.EnumerateFiles(projPath, i)
    while file do
        local rev = file:match("[Mm][Ii][Xx]%s*[Rr]%s*(%d+)")
        if rev then
            rev = tonumber(rev)
            revFiles[rev] = revFiles[rev] or {}
            table.insert(revFiles[rev], file)
        end
        i = i + 1
        file = reaper.EnumerateFiles(projPath, i)
    end
    return revFiles
end

local revFiles = listMixFiles()

-- No revisions found → message
local revNums = {}
for rev,_ in pairs(revFiles) do table.insert(revNums, rev) end
table.sort(revNums)
if #revNums == 0 then
    reaper.ShowMessageBox("No mix versions found in project folder:\n"..projPath,"Info",0)
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Insert Mix Revision", -1)
    return
end

-- Build menu string
local menuStr = ""
for i, rev in ipairs(revNums) do
    menuStr = menuStr .. "r" .. rev .. "|"
end
menuStr = menuStr:sub(1, -2)

-- Show menu
gfx.init("Select Mix Revision", 1, 1)
local choiceIndex = gfx.showmenu(menuStr)
gfx.quit()
if choiceIndex == 0 then
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Insert Mix Revision", -1)
    return
end

-- Get chosen revision
local choice = revNums[choiceIndex]
local filesForRev = revFiles[choice]
local selectedFile = filesForRev[1]

-- Remove existing items on Mix Versions track
for i = reaper.CountTrackMediaItems(mixTrack)-1,0,-1 do
    local item = reaper.GetTrackMediaItem(mixTrack,i)
    reaper.DeleteTrackMediaItem(mixTrack,item)
end

-- Insert selected file at Start marker
reaper.InsertMedia(projPath .. sep .. selectedFile, 0)
local item = reaper.GetTrackMediaItem(mixTrack,0)
if item then
    reaper.SetMediaItemInfo_Value(item,"D_POSITION",startPos)
end

-- Trim or delete anything after "End" marker
local endPos = nil
local _, numMarkers, _, _ = reaper.CountProjectMarkers(0)
for i=0,numMarkers-1 do
    local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
    if not isrgn and name=="End" then
        endPos = pos
        break
    end
end

if endPos then
    for i = reaper.CountTrackMediaItems(mixTrack)-1,0,-1 do
        local item = reaper.GetTrackMediaItem(mixTrack,i)
        local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEnd = itemPos + itemLen
        if itemPos >= endPos then
            reaper.DeleteTrackMediaItem(mixTrack, item)
        elseif itemEnd > endPos then
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", endPos - itemPos)
        end
    end
end

-- Move playhead to Start marker
if startPos then
    reaper.SetEditCurPos(startPos, true, true)
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Insert Mix Revision on 'Mix Versions' track", -1)

