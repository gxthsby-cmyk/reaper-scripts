-- @description oxygen pro mini daw control fk1
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

-- Oxygen Pro Mini - Smooth Fader + Knob Mapping for Selected Tracks
-- Faders 1–4: Volume (0dB to -30dB, below 0.01 = silent)
-- Knobs 1–4: Pan (snap to fixed positions)
-- Author: ChatGPT

-----------------------------------------
-- CONFIGURATION
-----------------------------------------
local fader_ccs = {33, 34, 35, 36}   -- CC numbers for faders 1–4
local knob_ccs  = {37, 38, 39, 40}   -- CC numbers for knobs 1–4
local midi_chan = 0                   -- 0 = MIDI Channel 1
local smoothing = 0.18                 -- interpolation factor (0.0–1.0, higher = faster)

-- Snap positions for pan (-1.0 to +1.0)
local snap_points = {
    -1.0, -0.9, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1,
     0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0
}

-----------------------------------------
-- STATE
-----------------------------------------
local target_volumes = {}  -- target volume per fader index
local last_volumes = {}    -- current interpolated volume per track

-----------------------------------------
-- FUNCTIONS
-----------------------------------------

-- Linear mapping from CC to volume between 0dB and -30dB, with values below 0.01 set to 0 (silent)
local function cc_to_vol(cc)
    local db_min = -30
    local db_max = 0
    local norm = cc / 127
    local db = db_min + (db_max - db_min) * norm
    local vol = 10^(db / 20)
    if vol < 0.05 then vol = 0 end
    if vol > 0.95 then vol = 1 end
    return vol
end

-- Snap knob value to nearest snap point
local function cc_to_pan(cc)
    local norm = cc / 127
    local pan = (norm * 2) - 1
    local closest = snap_points[1]
    local min_diff = math.abs(pan - closest)
    for _, p in ipairs(snap_points) do
        local diff = math.abs(pan - p)
        if diff < min_diff then
            min_diff = diff
            closest = p
        end
    end
    return closest
end

-- Get currently selected tracks
local function get_sel_tracks()
    local tracks = {}
    local count = reaper.CountSelectedTracks(0)
    for i = 0, count - 1 do
        table.insert(tracks, reaper.GetSelectedTrack(0, i))
    end
    return tracks
end

-- Smooth interpolation
local function interpolate(current, target)
    return current + (target - current) * smoothing
end

-----------------------------------------
-- MAIN LOOP
-----------------------------------------
local function handle_midi()
    local retval, msg, ts = reaper.MIDI_GetRecentInputEvent(0)
    if retval then
        local status = msg:byte(1)
        local data1 = msg:byte(2)
        local data2 = msg:byte(3)
        local msg_type = status & 0xF0
        local chan = status & 0x0F

        if msg_type == 0xB0 and chan == midi_chan then
            local tracks = get_sel_tracks()

            -- FADERS: set target volumes
            for i, cc in ipairs(fader_ccs) do
                if data1 == cc and i <= #tracks then
                    target_volumes[i] = cc_to_vol(data2)
                end
            end

            -- KNOBS: set pan immediately (snapping)
            for i, cc in ipairs(knob_ccs) do
                if data1 == cc and i <= #tracks then
                    local track = tracks[i]
                    local pan = cc_to_pan(data2)
                    reaper.SetMediaTrackInfo_Value(track, "D_PAN", pan)
                end
            end
        end
    end

    -- Smoothly apply volumes
    local tracks = get_sel_tracks()
    for i, track in ipairs(tracks) do
        local target = target_volumes[i] or reaper.GetMediaTrackInfo_Value(track, "D_VOL")
        local current = last_volumes[i] or target
        local smoothed = interpolate(current, target)
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", smoothed)
        last_volumes[i] = smoothed
    end

    reaper.defer(handle_midi)
end

-----------------------------------------
-- INIT
-----------------------------------------
reaper.defer(handle_midi)

