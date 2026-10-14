-- @description MonsKnob
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

-- ====================================================
-- Lua script: Monsgeek knob controlling last touched FX
-- ====================================================

-- Settings
local midi_device_name = "MonsKnob"
local midi_cc = 67      -- same as AHK
local step_size = 0.005 -- how much each tick changes parameter (0-1)

-- Helper to get last touched FX
function set_last_touched_param(delta)
    local track, fx, param = reaper.GetLastTouchedFX()
    if track then
        local cur = reaper.TrackFX_GetParam(track, fx, param)
        local new_val = math.max(0, math.min(1, cur + delta))
        reaper.TrackFX_SetParam(track, fx, param, new_val)
    end
end

-- Main loop
function main()
    -- get incoming MIDI messages
    local retval, midi_events = reaper.StuffMIDI_GetIncomingEvents(midi_device_name)
    if retval then
        for _, msg in ipairs(midi_events) do
            -- Check for CC message
            local status = msg[1]
            local cc_num = msg[2]
            local value = msg[3]
            if status >= 176 and status <= 191 and cc_num == midi_cc then
                if value == 1 then
                    set_last_touched_param(step_size)
                elseif value == 0 then
                    set_last_touched_param(-step_size)
                end
            end
        end
    end
    reaper.defer(main)
end

main()

