-- @description chakratest
-- @provides [main] .

-- Chakra + Key GUI (manual key input, nearest octave cents calculation)
local noteNames = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}

-- Chakra data
local chakraData = {
    {name="Root", trad=256, solf=396},
    {name="Sacral", trad=288, solf=417},
    {name="Solar Plexus", trad=320, solf=528},
    {name="Heart", trad=341.3, solf=639},
    {name="Throat", trad=384, solf=741},
    {name="Third Eye", trad=426.7, solf=852},
    {name="Crown", trad=480, solf=963},
}

local refHz = 440
local selectedChakra = 1 -- default Root
local selectedKeyIdx = 1 -- default C

-- Base frequencies for C4 octave
local baseFreqs = {
    C=261.63,Csharp=277.18,D=293.66,Dsharp=311.13,E=329.63,F=349.23,Fsharp=369.99,
    G=392.00,Gsharp=415.30,A=440.00,Asharp=466.16,B=493.88
}

-- GUI draw
function drawGUI(ctx)
    reaper.ImGui_Text(ctx, "Manual key selection:")
    local changed, keyIdx = reaper.ImGui_Combo(ctx, "Key", selectedKeyIdx-1, table.concat(noteNames,"\0").."\0", 12)
    if changed then selectedKeyIdx = keyIdx+1 end
    local keyName = noteNames[selectedKeyIdx]

    local changedChakra, chakraIdx = reaper.ImGui_Combo(ctx, "Target Chakra", selectedChakra-1, 
        "Root\0Sacral\0Solar Plexus\0Heart\0Throat\0Third Eye\0Crown\0", 7)
    if changedChakra then selectedChakra = chakraIdx+1 end
    local chakra = chakraData[selectedChakra]

    -- Calculate cents difference (nearest octave)
    local keyFreq = baseFreqs[keyName:gsub("#","sharp")]
    local chakraFreq = chakra.solf

    -- bring the keyFreq to nearest octave of chakraFreq
    local ratio = chakraFreq / keyFreq
    local octaveShift = math.floor(math.log(ratio)/math.log(2) + 0.5)
    local nearestKeyFreq = keyFreq * 2^octaveShift
    local cents = 1200 * math.log(chakraFreq/nearestKeyFreq)/math.log(2)

    reaper.ImGui_Text(ctx, string.format("Key: %s", keyName))
    reaper.ImGui_Text(ctx, string.format("Target Chakra: %s (%.1f Hz)", chakra.name, chakraFreq))
    reaper.ImGui_Text(ctx, string.format("Cents to tune key to chakra: %+0.2f ¢", cents))
end

-- GUI loop
local ctx = reaper.ImGui_CreateContext("Chakra Key Tuner")
function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 400, 200, reaper.ImGui_Cond_FirstUseEver())
    if reaper.ImGui_Begin(ctx, "Chakra Key Tuner", true) then
        drawGUI(ctx)
        reaper.ImGui_End(ctx)
    end
    reaper.defer(loop)
end
loop()

