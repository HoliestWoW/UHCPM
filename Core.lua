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
    
    if string.find(z, "ragefire") or string.find(z, "molten") or string.find(z, "searing") or string.find(z, "blackrock") or string.find(z, "forge") or string.find(z, "fire") or string.find(z, "woodshop") or string.find(z, "gnomeregan") or string.find(z, "moon") then return false end
    
    if string.find(z, "mine") or string.find(z, "cave") or string.find(z, "crypt") or string.find(z, "den") or string.find(z, "lair") or string.find(z, "tomb") or string.find(z, "barrow") or string.find(z, "duskwood") or string.find(z, "scholomance") or string.find(z, "stratholme") or string.find(z, "maraudon") or string.find(z, "dire maul") or string.find(z, "scarlet monastery") or string.find(z, "shadowfang") or string.find(z, "skull rock") or string.find(z, "tunnel") or string.find(z, "hold") or string.find(z, "hive") or string.find(z, "deeps") or string.find(z, "uldaman") or string.find(z, "catacomb") or string.find(z, "vault") or string.find(z, "razorfen") or string.find(z, "naxxramas") or string.find(z, "burrow") or string.find(z, "grotto") or string.find(z, "excavation") or string.find(z, "cellar") or string.find(z, "sunken temple") or string.find(z, "atal'hakkar") then return true end
    
    return false
end

SLASH_UHCPMLEAVEPARTY1 = "/lp"
SLASH_UHCPMLEAVEPARTY2 = "/leaveparty"
SlashCmdList["UHCPMLEAVEPARTY"] = function()
    LeaveParty()
    print("You have left the party.")
end

-- Create a custom immersive alert frame for important events
local AlertFrame = CreateFrame("Frame", nil, UIParent)
AlertFrame:SetSize(400, 50)
AlertFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
AlertFrame:SetFrameStrata("HIGH")

AlertFrame.text = AlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
AlertFrame.text:SetAllPoints()
AlertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
AlertFrame:SetAlpha(0)

-- Animation group for fading in and out
AlertFrame.anim = AlertFrame:CreateAnimationGroup()
local fadeIn = AlertFrame.anim:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.5); fadeIn:SetOrder(1)
local hold = AlertFrame.anim:CreateAnimation("Alpha")
hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(2.0); hold:SetOrder(2)
local fadeOut = AlertFrame.anim:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(1.5); fadeOut:SetOrder(3)

-- Global function so you can use this for other immersive pop-ups later
function UHCPM.ShowAlert(message, r, g, b)
    AlertFrame.text:SetText(message)
    AlertFrame.text:SetTextColor(r or 1, g or 0.8, b or 0)
    AlertFrame.anim:Stop()
    AlertFrame.anim:Play()
end

-- Track group changes to trigger the alert
local wasInParty = false
local GroupTracker = CreateFrame("Frame")
GroupTracker:RegisterEvent("GROUP_ROSTER_UPDATE")
GroupTracker:RegisterEvent("PLAYER_ENTERING_WORLD")

GroupTracker:SetScript("OnEvent", function(self, event)
    local inParty = (GetNumGroupMembers() > 1)
    
    if event == "PLAYER_ENTERING_WORLD" then
        wasInParty = inParty
    elseif event == "GROUP_ROSTER_UPDATE" then
        if inParty and not wasInParty then
            UHCPM.ShowAlert("Joined Party\nType /lp to leave", 0.2, 1.0, 0.2) 
        elseif not inParty and wasInParty then
            UHCPM.ShowAlert("Left Party", 1.0, 0.2, 0.2)
        end
        wasInParty = inParty
    end
end)