local frames
local is_pfUI
local isCasting

local function Check_pfUI()
    is_pfUI = IsAddOnLoaded("pfUI")
end

local function ShowFrames()
    if is_pfUI then
        for _, frame in pairs(frames) do
            frame:SetScript("OnUpdate", pfUI.uf.OnUpdate)
        end
    else
        for _, frame in pairs(frames) do
            frame:Show()
        end
    end
end

local function HideFrames()
    if is_pfUI then
        for _, frame in pairs(frames) do
            frame:SetScript("OnUpdate", nil)
            frame:SetAlpha(0)         
        end
    else
        for _, frame in pairs(frames) do
            frame:Hide()
        end
    end
end

local function FullHealth(unit)
    if UnitHealth(unit) == UnitHealthMax(unit) then return true end
end

local function FullMana(unit)
    local powerType = UnitPowerType(unit)
    if not (powerType == 0 or powerType == 3) then return true end  -- 0 = mana, 3 = energy
    if UnitMana(unit) == UnitManaMax(unit) then return true end
end

local function HappyPet()
    if (UnitCreatureType("pet") == "Beast") and (GetPetHappiness() > 1) then return true end
end

local function PetConditions()
    if not UnitExists("pet") then return true end
    if HappyPet() and FullHealth("pet") then return true end
end

local function PlayerConditions()
    local fullhealth = FullHealth("player")
    local fullmana = FullMana("player")
    local ooc = not UnitAffectingCombat("player")

    if fullhealth and fullmana and (not isCasting) and ooc then return true end
end

local function CheckConditions()
    local notarget = not UnitExists("target")
    local player = PlayerConditions()
    local pet = PetConditions()

    if notarget and player and pet then 
        HideFrames()
    else
        ShowFrames()
    end
end

local function overlay(parent)
    local f = CreateFrame("Button")
    f:SetAllPoints(parent)
    f:EnableMouse(true)
    f:RegisterForClicks('LeftButtonUp', 'RightButtonUp',
    'MiddleButtonUp', 'Button4Up', 'Button5Up')

    f:SetScript("OnEnter", function()
        parent:Show()
        ShowTextStatusBarText(getglobal(parent:GetName().."HealthBar"))
        ShowTextStatusBarText(getglobal(parent:GetName().."ManaBar"))
    end)

    f:SetScript("OnLeave", function()
        this:Show()
        CheckConditions()       
    end)

    f:SetScript("OnClick", function()
        this:Hide()
        getglobal(parent:GetName().."_OnClick")(arg1)
    end)
end

local function SetupFrames()
    if is_pfUI then
        if pfUI_config.unitframes.disable == "1" then
            frames = { }
            return
        else
            frames = { pfPlayer, pfPet }
        end
        
        for _, frame in pairs(frames) do
            frame:SetScript("OnEnter", function()
                this:SetScript("OnUpdate", pfUI.uf.OnUpdate)
            end)

            frame:SetScript("OnLeave", function()
                CheckConditions()
            end)
        end
    else
        frames = { PlayerFrame, PetFrame }
        for _, frame in pairs(frames) do
            overlay(frame)
        end
    end
end

local events = CreateFrame("Frame", nil, UIParent)	
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_HEALTH", "player")
events:RegisterEvent("UNIT_HEALTH", "pet")
events:RegisterEvent("UNIT_MANA", "player")
events:RegisterEvent("UNIT_ENERGY", "player")
events:RegisterEvent("SPELLCAST_START", "player")
events:RegisterEvent("SPELLCAST_CHANNEL_START", "player")
events:RegisterEvent("SPELLCAST_STOP", "player")
events:RegisterEvent("SPELLCAST_FAILED", "player")
events:RegisterEvent("SPELLCAST_INTERRUPTED", "player")
events:RegisterEvent("SPELLCAST_CHANNEL_STOP", "player")
events:RegisterEvent("PLAYER_REGEN_DISABLED") -- in combat
events:RegisterEvent("PLAYER_REGEN_ENABLED") -- out of combat
events:RegisterEvent("UNIT_PET")    

events:SetScript("OnEvent", function()
    isCasting = nil
    if (event == "PLAYER_ENTERING_WORLD") then
        if not this.loaded then
            this.loaded = true
            Check_pfUI()
            SetupFrames()
        end
    elseif ((event == "SPELLCAST_START") or (event == "SPELLCAST_CHANNEL_START") or (event == "SPELLCAST_STOP") or (event == "SPELLCAST_CHANNEL_STOP")) then
        isCasting = true
    end
    CheckConditions()
end)