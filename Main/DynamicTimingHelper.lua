-- @description DynamicTimingHelper
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

--[[
Attack / Release Timing Helper
Author: ChatGPT (GPT-5)
Description: Displays rhythmic timing values in milliseconds for the current BPM.
Requires: ReaImGui
]]

local window_title = "Timing Helper"
local ctx = reaper.ImGui_CreateContext(window_title)

-- Convert BPM to milliseconds per note division
local function getMs(bpm, beats)
    local beat_ms = 60000 / bpm
    return beat_ms * beats
end

local function main()
    local bpm = reaper.Master_GetTempo()
    local divisions = {
        { "1 bar (4/4)", 4 },
        { "1/2 note", 2 },
        { "1/4 note", 1 },
        { "1/8 note", 0.5 },
        { "1/16 note", 0.25 },
        { "1/32 note", 0.125 },
        { "1/64 note", 0.0625 },
        { "1/128 note", 0.03125 },
        { "1/256 note", 0.015625 },
        { "1/512 note", 0.0078125 },
    }

    reaper.ImGui_Text(ctx, string.format("Project BPM: %.1f", bpm))
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Timings per beat division:")
    reaper.ImGui_Separator(ctx)

    for _, d in ipairs(divisions) do
        local ms = getMs(bpm, d[2])
        -- Remove unnecessary trailing zeros, show up to 3 decimal places
        reaper.ImGui_Text(ctx, string.format("%-15s = %.3f ms", d[1], ms))
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Tip: Use these to set compressor, delay, or LFO sync times.")
end

-- GUI loop
function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 350, 280, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, window_title, true)
    if visible then
        main()
        reaper.ImGui_End(ctx)
    end
    if open then
        reaper.defer(loop)  -- keep looping while window is open
    end
    -- Removed DestroyContext; context will be cleaned up automatically
end

reaper.defer(loop)


