local addonName, UHCPM = ...
local originalVolumes = {}; local audioIsMuffled = false

function UHCPM.MuffleAudio(severity)
    if type(severity) == "number" and severity > 0 then
        if not audioIsMuffled then
            originalVolumes.sfx = GetCVar("Sound_SFXVolume"); originalVolumes.music = GetCVar("Sound_MusicVolume"); originalVolumes.ambience = GetCVar("Sound_AmbienceVolume"); originalVolumes.dialog = GetCVar("Sound_DialogVolume"); audioIsMuffled = true
        end
        local dropOff = math.max((1.0 - severity) ^ 3, 0.01) 
        SetCVar("Sound_SFXVolume", tostring(tonumber(originalVolumes.sfx or 1) * dropOff)); SetCVar("Sound_MusicVolume", tostring(tonumber(originalVolumes.music or 1) * dropOff)); SetCVar("Sound_AmbienceVolume", tostring(tonumber(originalVolumes.ambience or 1) * dropOff))
        SetCVar("Sound_DialogVolume", tostring(math.min(severity ^ 1.5, 1.0)))
    elseif audioIsMuffled then
        if originalVolumes.sfx then SetCVar("Sound_SFXVolume", originalVolumes.sfx); SetCVar("Sound_MusicVolume", originalVolumes.music); SetCVar("Sound_AmbienceVolume", originalVolumes.ambience); SetCVar("Sound_DialogVolume", originalVolumes.dialog) end
        audioIsMuffled = false
    end
end