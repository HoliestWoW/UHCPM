local addonName, UHCPM = ...

UHCPM.state = {
    playerHealth = 100, playerMaxHealth = 100, playerPowerType = -1, playerCurrentPower = 0, playerMaxPower = 0,
    playerPowerRatio = 0, targetCpRatio = 0, isToxified = false, isAsphyxiating = false, isCastingMagic = false,
    isIndoors = false, entranceX = nil, entranceY = nil, currentCastSchool = 0, lightPulse = 0
}

UHCPM.UI = {}
UHCPM.constants = { MAX_FLASH_DURATION = 4.0, MAX_HEARTS = 10, LIGHT_SCHOOLS = bit.bor(2, 4, 64) }

-- Cached Colors (Zero allocation)
UHCPM.colors = {
    transparent = CreateColor(0, 0, 0, 0),
    bloodDark = CreateColor(0.12, 0, 0, 1),
    powerGrads = {
        [0] = { CreateColor(0.1, 0.4, 1, 0.5), CreateColor(0.1, 0.4, 1, 0) }, -- Mana
        [1] = { CreateColor(1, 0.1, 0, 0.5), CreateColor(1, 0.1, 0, 0) },     -- Rage
        [3] = { CreateColor(1, 0.8, 0, 0.4), CreateColor(1, 0.8, 0, 0) }      -- Energy
    }
}

UHCPM.coreFrame = CreateFrame("Frame", "UHProMaxCore", UIParent)

function UHCPM.RandomFloat() return math.random(0, 1000) / 1000 end

function UHCPM.GetEquippedLightLevel()
    local slots = {16, 17, 18}
    local keywords = {"torch", "lantern", "lamp", "beacon", "candle", "flame", "fire", "brazier"}
    local bestLight = 1.0 
    for _, slot in ipairs(slots) do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local lowerLink = string.lower(itemLink)
            for _, keyword in ipairs(keywords) do if string.find(lowerLink, keyword) then return 0.40 end end
            local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfo(itemLink)
            if classID and classID == 2 and subclassID == 19 then bestLight = 0.60 end
        end
    end
    return bestLight
end

function UHCPM.IsDarkSubZone(zoneName)
    if not zoneName then return false end
    local z = string.lower(zoneName)
    if string.find(z, "ragefire") or string.find(z, "molten") or string.find(z, "searing") or string.find(z, "blackrock") or string.find(z, "forge") or string.find(z, "fire") or string.find(z, "woodshop") then return false end
    if string.find(z, "mine") or string.find(z, "cave") or string.find(z, "crypt") or string.find(z, "den") or string.find(z, "lair") or string.find(z, "tomb") or string.find(z, "barrow") or string.find(z, "duskwood") or string.find(z, "scholomance") or string.find(z, "stratholme") or string.find(z, "maraudon") or string.find(z, "dire maul") or string.find(z, "scarlet monastery") or string.find(z, "shadowfang") then return true end
    return false
end