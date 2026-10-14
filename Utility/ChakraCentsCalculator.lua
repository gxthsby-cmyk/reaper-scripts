-- @description ChakraCentsCalculator
-- @provides [main] .

-- Utility: get nearest note name for a frequency relative to master A
local noteNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

-- Returns note info and required master A to hit that note exactly
local function freqToNoteData(freq, refHz)
    refHz = refHz or 440
    local n = 12 * math.log(freq / refHz, 2)
    local rounded = math.floor(n + 0.5)
    local noteIndex = (rounded + 9) % 12 + 1 -- shift so A=refHz
    local octave = 4 + math.floor((rounded + 9) / 12)
    local noteName = string.format("%s%d", noteNames[noteIndex], octave)
    local noteHz = refHz * (2 ^ (rounded / 12))
    local diffCents = 1200 * math.log(freq / noteHz, 2)
    
    -- Calculate required A to make this freq exact note
    local requiredA = freq / (2 ^ (rounded / 12))

    return noteName, noteHz, diffCents, requiredA
end

-- Chakra data
local chakraData = {
    {name="Root", trad=256, solf=396},
    {name="Sacral", trad=288, solf=417},
    {name="Solar Plexus", trad=320, solf=528},
    {name="Heart", trad=341.3, solf=639},
    {name="Throat", trad=384, solf=741},
    {name="Third Eye", trad=426.7, solf=852},
    {name="Crown", trad=480, solf=963},
    {name="Universal / 432Hz", trad=432, solf=432},
}

local refHz = 440  -- current master tuning reference

-- GUI draw function
local function drawGUI(ctx)
    reaper.ImGui_Text(ctx, string.format("Current master tuning: A = %.2f Hz", refHz))
    reaper.ImGui_Separator(ctx)

    for _, c in ipairs(chakraData) do
        local noteNameT, noteHzT, diffT, requiredAT = freqToNoteData(c.trad, refHz)
        local noteNameS, noteHzS, diffS, requiredAS = freqToNoteData(c.solf, refHz)

        reaper.ImGui_Text(ctx, string.format("%s:", c.name))
        reaper.ImGui_Text(ctx, string.format(
            "  Traditional (C=256): %.1f Hz → %s (%.2f Hz, %+0.2f ¢), tune A = %.2f Hz",
            c.trad, noteNameT, noteHzT, diffT, requiredAT))
        reaper.ImGui_Text(ctx, string.format(
            "  Solfeggio: %.1f Hz → %s (%.2f Hz, %+0.2f ¢), tune A = %.2f Hz",
            c.solf, noteNameS, noteHzS, diffS, requiredAS))
        reaper.ImGui_Separator(ctx)
    end
end

-- Main GUI loop
local ctx = reaper.ImGui_CreateContext("Chakra Notes")
function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 450, 350, reaper.ImGui_Cond_FirstUseEver())
    if reaper.ImGui_Begin(ctx, "Chakra Notes", true) then
        drawGUI(ctx)
        reaper.ImGui_End(ctx)
    end
    reaper.defer(loop)
end
loop()

