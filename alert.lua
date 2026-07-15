local ADDON_NAME, addonTable = ...
local addon = addonTable.addon
local L = addon.L

-- Fetch LibSharedMedia
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Create the secure frame
local alertFrame = CreateFrame("Button", "BearFormAlertFrame", UIParent, "SecureActionButtonTemplate")
alertFrame:RegisterForClicks("AnyDown", "AnyUp")
addon.alertFrame = alertFrame

-- Separate secure handler for keybind management (binds only when alert condition is active)
local bindHandler = CreateFrame("Frame", "BearFormAlertBindHandler", UIParent, "SecureHandlerStateTemplate")
addon.bindHandler = bindHandler
bindHandler:SetAttribute("_onstate-keybinds", [[
    if newstate == "active" then
        local buttonName = self:GetAttribute("buttonName")
        if buttonName and buttonName ~= "" then
            for i = 1, 3 do
                local key = self:GetAttribute("hotkey" .. i)
                if key and key ~= "" then
                    self:SetBindingClick(true, key, buttonName, "LeftButton")
                end
            end
        end
    else
        self:ClearBindings()
    end
]])


-- Set up frame visuals
alertFrame:SetFrameStrata("HIGH")
alertFrame:SetClampedToScreen(true)

-- Glow Border (Spell proc alert style) - Put on BACKGROUND layer so it sits behind the icon
local glow = alertFrame:CreateTexture(nil, "BACKGROUND")
glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
glow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
glow:SetBlendMode("ADD")
glow:SetPoint("TOPLEFT", alertFrame, "TOPLEFT", -12, 12)
glow:SetPoint("BOTTOMRIGHT", alertFrame, "BOTTOMRIGHT", 12, -12)
alertFrame.glow = glow

-- Icon Texture - Put on ARTWORK layer so it renders on top of the glow, masking the inner glow lines
local icon = alertFrame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(alertFrame)
alertFrame.icon = icon

-- Warning Text under icon
local text = alertFrame:CreateFontString(nil, "OVERLAY")
text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
text:SetPoint("TOP", alertFrame, "BOTTOM", 0, -8)
alertFrame.text = text

-- Hotkey Text label
local hotkeyText = alertFrame:CreateFontString(nil, "OVERLAY")
hotkeyText:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -4, -4)
hotkeyText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
hotkeyText:SetTextColor(1, 0.8, 0.2)
alertFrame.hotkeyText = hotkeyText

-- Screen Flash Overlay Frame
local flashFrame = CreateFrame("Frame", "BearFormAlertFlashFrame", UIParent)
flashFrame:SetAllPoints(UIParent)
flashFrame:SetFrameStrata("DIALOG") -- Draw on top of standard UI elements
flashFrame:EnableMouse(false)
flashFrame:Hide()

local flashTex = flashFrame:CreateTexture(nil, "BACKGROUND")
flashTex:SetAllPoints(flashFrame)
flashTex:SetTexture("Interface\\FullScreenTextures\\LowHealth")
flashTex:SetDesaturated(true)
flashTex:SetBlendMode("ADD")
flashFrame.texture = flashTex

-- Create a non-secure anchor frame for dragging (to prevent secure frame taint)
local anchorFrame = CreateFrame("Frame", "BearFormAlertAnchorFrame", UIParent)
anchorFrame:SetFrameStrata("MEDIUM")
anchorFrame:SetClampedToScreen(true)
anchorFrame:SetMovable(true)
anchorFrame:RegisterForDrag("LeftButton")
addon.anchorFrame = anchorFrame

-- Set up drag handlers on the secure alert frame to forward to the non-secure anchor
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() and not addon.db.profile.lockFrame then
        anchorFrame:StartMoving()
        anchorFrame.isMoving = true
    end
end)
alertFrame:SetScript("OnDragStop", function(self)
    if anchorFrame.isMoving then
        anchorFrame:StopMovingOrSizing()
        anchorFrame.isMoving = false
        
        -- Save coordinates
        local point, _, _, xOfs, yOfs = anchorFrame:GetPoint()
        addon.db.profile.point = point
        addon.db.profile.posX = xOfs
        addon.db.profile.posY = yOfs
    end
end)

-- Anchor visual background (visible only when unlocked or in test mode)
local anchorBG = anchorFrame:CreateTexture(nil, "BACKGROUND")
anchorBG:SetAllPoints(anchorFrame)
anchorBG:SetColorTexture(0, 1, 0, 0.3) -- Translucent green block
anchorBG:Hide()
anchorFrame.bg = anchorBG

-- Draggable setup for the non-secure anchor frame
anchorFrame:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then
        self:StartMoving()
        self.isMoving = true
    end
end)

anchorFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self.isMoving = false
    
    -- Save coordinates
    local point, _, _, xOfs, yOfs = self:GetPoint()
    addon.db.profile.point = point
    addon.db.profile.posX = xOfs
    addon.db.profile.posY = yOfs
end)

-- Pulse and Scale Animations
local elapsed = 0
local pulseSpeed = 4.5

alertFrame:SetScript("OnShow", function(self)
    local db = addon.db.profile
    self.shownTime = 0
    self.durationExpired = false
    self:SetAlpha(db.frameOpacity)
    if db.enableScreenFlash then
        flashFrame:Show()
    end
    addon:StartAudioAlert()
end)

alertFrame:SetScript("OnHide", function(self)
    flashFrame:Hide()
    addon:StopAudioAlert()
end)

alertFrame:SetScript("OnUpdate", function(self, elap)
    local db = addon.db.profile
    elapsed = elapsed + elap
    
    if db.enableDuration and not self.durationExpired then
        self.shownTime = (self.shownTime or 0) + elap
        if self.shownTime >= db.alertDuration then
            self.durationExpired = true
            self:SetAlpha(0)
            flashFrame:Hide()
            addon:StopAudioAlert()
        end
    end
    
    if not self.durationExpired then
        -- Pulsing breath animations
        if db.enableGlow then
            local alpha = 0.3 + 0.7 * (0.5 + 0.5 * sin(elapsed * pulseSpeed))
            glow:SetAlpha(alpha * db.glowColor.a)
        end
        
        if db.enableScreenFlash and flashFrame:IsShown() then
            local flashAlpha = db.flashIntensity * (0.5 + 0.5 * sin(elapsed * pulseSpeed))
            flashFrame:SetAlpha(flashAlpha)
        end
    end
end)

-- Fetch spell icon and localized name dynamically
addon.iconTexture = "Interface\\Icons\\Ability_Druid_BearForm"
addon.bearFormName = "Bear Form"

local function ResolveSpellName()
    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(5487)
        if spellInfo then
            if spellInfo.name then
                addon.bearFormName = spellInfo.name
            end
            if spellInfo.iconID then
                addon.iconTexture = spellInfo.iconID
            end
        end
    else
        -- Fallback for older versions
        local name = GetSpellInfo and GetSpellInfo(5487)
        if name then
            addon.bearFormName = name
        end
    end
end
ResolveSpellName() -- Resolve initial values at load

-- Keybinding functions
function addon:SetupAlertBindings()
    local db = self.db.profile
    if InCombatLockdown() then return end
    
    bindHandler:SetAttribute("hotkey1", db.hotKey or "")
    bindHandler:SetAttribute("hotkey2", db.hotKey2 or "")
    bindHandler:SetAttribute("hotkey3", db.hotKey3 or "")
    bindHandler:SetAttribute("buttonName", alertFrame:GetName())
end

function addon:ClearAlertBindings()
    if InCombatLockdown() then return end
    UnregisterStateDriver(bindHandler, "keybinds")
    ClearOverrideBindings(bindHandler)
    bindHandler:SetAttribute("hotkey1", "")
    bindHandler:SetAttribute("hotkey2", "")
    bindHandler:SetAttribute("hotkey3", "")
    bindHandler:SetAttribute("buttonName", "")
end

-- Audio warn loop
local soundTicker
function addon:StartAudioAlert()
    local db = self.db.profile
    if not db.enableSound then return end
    
    self:PlayWarningSound()
    
    if soundTicker then
        soundTicker:Cancel()
    end
    
    soundTicker = C_Timer.NewTicker(db.soundInterval, function()
        addon:PlayWarningSound()
    end)
end

function addon:StopAudioAlert()
    if soundTicker then
        soundTicker:Cancel()
        soundTicker = nil
    end
end

function addon:PlayWarningSound()
    local db = self.db.profile
    if not db.enableSound then return end
    
    local soundPath = "Sound\\Interface\\RaidWarning.ogg"
    if LSM then
        soundPath = LSM:Fetch("sound", db.soundFile) or soundPath
    end
    
    PlaySoundFile(soundPath, db.soundChannel or "Master")
end

function addon:SetTestMode(enabled)
    if InCombatLockdown() then
        return
    end
    self.isTestMode = enabled
    self:UpdateAlertSettings()
end

-- Helper to check zone restrictions
local function IsAddonEnabledInCurrentZone()
    local db = addon.db.profile
    local inInstance, instanceType = IsInInstance()
    
    if inInstance then
        if instanceType == "pvp" or instanceType == "arena" then
            return db.enablePvP
        elseif instanceType == "party" or instanceType == "raid" or instanceType == "scenario" then
            return db.enableInstances
        else
            -- Fallback for any other instance type
            return db.enableWorld
        end
    else
        return db.enableWorld
    end
end

-- Main function to apply user options
function addon:UpdateAlertSettings()
    local db = self.db.profile
    
    -- Defend against in-combat updates
    if InCombatLockdown() then
        self.pendingUpdate = true
        return
    end
    
    -- Resolve spell name out of combat to ensure cache is ready
    ResolveSpellName()
    
    -- Verify class is Druid and addon is enabled (bypass class and zone checks in test mode)
    local _, classFilename = UnitClass("player")
    local isDruid = classFilename == "DRUID"
    local isEnabled = db.enabled and (isDruid or self.isTestMode) and (self.isTestMode or IsAddonEnabledInCurrentZone())
    
    if not isEnabled then
        UnregisterStateDriver(alertFrame, "visibility")
        alertFrame:Hide()
        anchorBG:Hide()
        anchorFrame:EnableMouse(false)
        flashFrame:Hide()
        self:ClearAlertBindings()
        return
    end
    
    -- Size and position the non-secure anchor frame
    anchorFrame:SetSize(db.frameSize, db.frameSize)
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(db.point, UIParent, db.point, db.posX, db.posY)
    
    -- Anchor the secure frame to the non-secure anchor frame
    alertFrame:SetSize(db.frameSize, db.frameSize)
    alertFrame:SetAlpha(db.frameOpacity)
    alertFrame:ClearAllPoints()
    alertFrame:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
    
    -- Show/hide anchor background based on lock state and test mode (out of combat only)
    if not InCombatLockdown() and self.isTestMode and not db.lockFrame then
        anchorBG:Show()
        anchorFrame:EnableMouse(true)
    else
        anchorBG:Hide()
        anchorFrame:EnableMouse(false)
    end
    
    -- Adjust glow offsets dynamically based on frame size (approx 15%)
    local glowOffset = db.frameSize * 0.15
    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", alertFrame, "TOPLEFT", -glowOffset, glowOffset)
    glow:SetPoint("BOTTOMRIGHT", alertFrame, "BOTTOMRIGHT", glowOffset, -glowOffset)
    
    -- Icon texture
    icon:SetTexture(self.iconTexture)
    
    -- Glow toggle and coloring
    if db.enableGlow then
        glow:Show()
        glow:SetVertexColor(db.glowColor.r, db.glowColor.g, db.glowColor.b, db.glowColor.a)
    else
        glow:Hide()
    end
    
    -- Text warning
    if db.showText then
        text:SetFont("Fonts\\FRIZQT__.TTF", db.textSize, "OUTLINE")
        text:SetText("BEAR FORM!")
        text:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a)
        text:Show()
    else
        text:Hide()
    end
    
    -- Hotkey Text label
    if db.enableClickToShift then
        local keys = {}
        if db.hotKey and db.hotKey ~= "" then table.insert(keys, db.hotKey) end
        if db.hotKey2 and db.hotKey2 ~= "" then table.insert(keys, db.hotKey2) end
        if db.hotKey3 and db.hotKey3 ~= "" then table.insert(keys, db.hotKey3) end
        if #keys > 0 then
            hotkeyText:SetText(table.concat(keys, "/"))
            hotkeyText:Show()
        else
            hotkeyText:Hide()
        end
    else
        hotkeyText:Hide()
    end
    
    -- Click action setup
    if db.enableClickToShift then
        local macrotext = string.format("/cast [noform:1] %s", addon.bearFormName)
        alertFrame:SetAttribute("clickToShiftEnabled", true)
        alertFrame:SetAttribute("type", "macro")
        alertFrame:SetAttribute("macrotext", macrotext)
        alertFrame:SetAttribute("type1", "macro")
        alertFrame:SetAttribute("macrotext1", macrotext)
        alertFrame:EnableMouse(true)
        self:SetupAlertBindings()
    else
        alertFrame:SetAttribute("clickToShiftEnabled", nil)
        alertFrame:SetAttribute("type", nil)
        alertFrame:SetAttribute("macrotext", nil)
        alertFrame:SetAttribute("type1", nil)
        alertFrame:SetAttribute("macrotext1", nil)
        self:ClearAlertBindings()
        
        -- Lock mode click-through configuration
        if db.lockFrame then
            alertFrame:EnableMouse(false)
        else
            alertFrame:EnableMouse(true) -- allow dragging
        end
    end

    -- Dynamic drag registration based on lockFrame out of combat
    if not db.lockFrame then
        alertFrame:RegisterForDrag("LeftButton")
    else
        alertFrame:RegisterForDrag()
    end
    
    -- Screen flash update
    if db.enableScreenFlash and (alertFrame:IsShown() or self.isTestMode) then
        flashFrame:Show()
        local fc = db.flashColor or { r = 1, g = 0, b = 0 }
        flashTex:SetVertexColor(fc.r, fc.g, fc.b, 1)
    else
        flashFrame:Hide()
    end
    
    -- State Driver setup
    local stateString
    if self.isTestMode then
        if db.guardianOnly then
            stateString = "[combat,spec:3,noform:1] show; [combat] hide; show"
        else
            stateString = "[combat,noform:1] show; [combat] hide; show"
        end
    else
        if db.guardianOnly then
            stateString = "[combat,spec:3,noform:1] show; hide"
        else
            stateString = "[combat,noform:1] show; hide"
        end
    end
    
    RegisterStateDriver(alertFrame, "visibility", stateString)
    
    -- Keybind state driver: uses a specific condition separate from visibility
    -- to ensure keys are only bound when the player is NOT in Bear Form.
    if db.enableClickToShift then
        local bindState
        if db.guardianOnly then
            if self.isTestMode then
                bindState = "[combat,spec:3,noform:1] active; [nocombat,noform:1] active; inactive"
            else
                bindState = "[combat,spec:3,noform:1] active; inactive"
            end
        else
            if self.isTestMode then
                bindState = "[noform:1] active; inactive"
            else
                bindState = "[combat,noform:1] active; inactive"
            end
        end
        
        bindHandler:SetAttribute("state-keybinds", "forced_reset")
        RegisterStateDriver(bindHandler, "keybinds", bindState)
        
        -- Out of combat, if test mode is OFF, ensure bindings are cleared immediately in Lua
        if not InCombatLockdown() and not self.isTestMode then
            ClearOverrideBindings(bindHandler)
        end
    else
        UnregisterStateDriver(bindHandler, "keybinds")
        ClearOverrideBindings(bindHandler)
    end
end

-- Event Handling
function addon:OnPlayerEnteringWorld()
    self:UpdateAlertSettings()
end

function addon:OnPlayerRegenDisabled()
    -- Lock down settings if combat starts while testing/dragging
    if self.isTestMode then
        self.isTestMode = false
        self.pendingUpdate = true
        
        -- Transition non-secure parts safely in combat
        if anchorBG then anchorBG:Hide() end
        if anchorFrame then anchorFrame:EnableMouse(false) end
    end
    if anchorFrame.isMoving then
        anchorFrame:StopMovingOrSizing()
        anchorFrame.isMoving = false
    end
end

function addon:OnPlayerRegenEnabled()
    -- Always update settings out of combat to ensure keybind states and test mode are synchronized
    self.pendingUpdate = false
    self:UpdateAlertSettings()
end

function addon:OnUpdateBindings()
    self:UpdateAlertSettings()
end

function addon:OnZoneChangedNewArea()
    self:UpdateAlertSettings()
end

addon:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
addon:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayerRegenDisabled")
addon:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
addon:RegisterEvent("UPDATE_BINDINGS", "OnUpdateBindings")
addon:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChangedNewArea")
