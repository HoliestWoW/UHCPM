local addonName, UHCPM = ...

UHCPM.UI.UHPMParticles = CreateFrame("Frame", "UHPMParticleEngine", UIParent); UHCPM.UI.UHPMParticles:SetAllPoints(); UHCPM.UI.UHPMParticles:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0); UHCPM.UI.UHPMParticles:SetFrameStrata("LOW") 
local activeParticles = {}; local availableParticles = {}; local MAX_PARTICLES = 200

for i = 1, MAX_PARTICLES do
    local tex = UHCPM.UI.UHPMParticles:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark"); tex:SetBlendMode("ADD"); tex:SetSize(16, 32); tex:SetAlpha(0); tex:Hide()
    tex.isActive = false; tex.pType = -1; tex.posX = 0; tex.posY = 0; tex.velX = 0; tex.velY = 0; tex.life = 0
    table.insert(availableParticles, tex) 
end

function UHCPM.SpawnParticle(powerType, powerRatio)
    local p = table.remove(availableParticles) 
    if not p then return end 
    p.pType = powerType; p.baseAlpha = 0.9; p.posX = math.random(-(UIParent:GetWidth() / 2.5), (UIParent:GetWidth() / 2.5)); p.posY = 0
    if powerType == 1 then p:SetVertexColor(0.9, 0.1, 0.0); p.velY = math.random(30, 60); p:SetSize(12, 12) 
    elseif powerType == 0 then if math.random() > 0.5 then p:SetVertexColor(0.6, 0.2, 1.0) else p:SetVertexColor(0.2, 0.8, 1.0) end; p.velY = math.random(15, 30); local ms = math.random(8, 18); p:SetSize(ms, ms)
    elseif powerType == 3 then p:SetVertexColor(0.2, 1.0, 0.2); p.velY = math.random(300, 500); p:SetSize(math.random(5, 7), math.random(5, 20)); p.life = math.random(600, 900)/1000 else return end
    if powerType == 3 then p.velX = (UHCPM.RandomFloat() - 0.5) * 400 else p.velX = (UHCPM.RandomFloat() - 0.5) * 20 end
    if powerType == 0 then p.life = math.random(2000, 3000)/1000 else p.life = 1.0 end
    p.isActive = true; p:SetAlpha(p.baseAlpha); p:ClearAllPoints(); p:SetPoint("CENTER", UHCPM.UI.UHPMParticles, "BOTTOM", p.posX, p.posY); p:Show(); table.insert(activeParticles, p)
end

function UHCPM.UpdateParticles(elapsed)
    local now = GetTime()
    for i = #activeParticles, 1, -1 do
        local p = activeParticles[i]; p.posX = p.posX + (p.velX * elapsed); p.posY = p.posY + (p.velY * elapsed); p.life = p.life - (elapsed * 0.5) 
        if p.life <= 0 then
            p.isActive = false; p:Hide(); table.remove(activeParticles, i); table.insert(availableParticles, p)
            p:SetRotation(0); p:SetScale(1); p:SetVertexColor(1, 1, 1, 1); p:SetBlendMode("ADD"); p:SetTexCoord(0, 1, 0, 1)
        else
            local curA = math.min(p.life, 1.0) * p.baseAlpha
            if p.pType == 0 then p.posX = p.posX + (math.sin(now * 1.5 + p.velY) * 0.8); local pulse = (math.sin(now * 4 + p.velY) * 0.3) + 0.7; p:SetAlpha(curA * pulse) 
            elseif p.pType == 3 then p.velY = p.velY - (elapsed * 1200); p:SetAlpha(curA * (p.life ^ 2)) 
            else p.posX = p.posX + (math.sin(now * 3 + p.velY) * 0.5); p:SetAlpha(curA) end
            p:SetPoint("CENTER", UHCPM.UI.UHPMParticles, "BOTTOM", p.posX, p.posY)
        end
    end
end