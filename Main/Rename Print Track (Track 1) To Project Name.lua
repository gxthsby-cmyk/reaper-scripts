-- @description Rename Print Track (Track 1) To Project Name
-- @provides [main] .

-- Rename Track 1 to the project filename without extension

-- Get current project handle and full project path
local proj, projPath = reaper.EnumProjects(-1, "")

-- Extract filename (basename) from full path
local filename = projPath:match("([^/\\]+)$") or projPath

-- Remove extension (.rpp or anything else)
local projName = filename:match("(.+)%..+$") or filename

-- Get Track 1
local track = reaper.GetTrack(proj, 0)
if track and projName then
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", projName, true)
end

