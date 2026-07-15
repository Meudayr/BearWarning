local ADDON_NAME, addonTable = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
addonTable.addon = addon

-- Save reference globally
_G[ADDON_NAME] = addon

-- Fetch localization
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
addon.L = L

-- Default settings database structure
local defaults = {
    profile = {
        enabled = true,
        guardianOnly = true,
        lockFrame = false,
        
        -- zone restrictions
        enableWorld = true,
        enableInstances = true,
        enablePvP = true,
        
        -- visual settings
        frameSize = 80,
        frameOpacity = 1.0,
        enableGlow = true,
        glowColor = { r = 0.9, g = 0.1, b = 0.1, a = 0.8 },
        showText = true,
        textSize = 14,
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        enableScreenFlash = true,
        flashIntensity = 0.4,
        flashColor = { r = 1, g = 0, b = 0 },
        
        -- audio settings
        enableSound = true,
        soundFile = "Raid Warning",
        soundChannel = "Master",
        soundInterval = 1.5,
        
        -- duration settings
        enableDuration = false,
        alertDuration = 5.0,
        
        -- interaction
        enableClickToShift = true,
        hotKey = "",
        hotKey2 = "",
        hotKey3 = "",
        
        -- position
        posX = 0,
        posY = 100,
        point = "CENTER",
    }
}

-- Native Event Registering implementation (removes dependency on AceEvent-3.0)
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if eventHandlers[event] then
        eventHandlers[event](...)
    end
end)

function addon:RegisterEvent(event, method)
    eventFrame:RegisterEvent(event)
    eventHandlers[event] = function(...)
        if type(method) == "string" then
            if addon[method] then
                addon[method](addon, event, ...)
            end
        else
            method(event, ...)
        end
    end
end

function addon:UnregisterEvent(event)
    eventFrame:UnregisterEvent(event)
    eventHandlers[event] = nil
end

-- Custom print method (removes dependency on AceConsole-3.0)
function addon:Print(msg)
    print("|cff00ff00" .. ADDON_NAME .. "|r: " .. tostring(msg))
end

-- Native Database initialization (removes dependency on AceDB-3.0)
function addon:InitializeDB()
    if type(_G.BearWarningDB) ~= "table" then
        _G.BearWarningDB = {}
    end
    
    self.db = {
        profile = _G.BearWarningDB
    }
    
    -- Set defaults
    for k, v in pairs(defaults.profile) do
        if self.db.profile[k] == nil then
            if type(v) == "table" then
                self.db.profile[k] = {}
                for subK, subV in pairs(v) do
                    self.db.profile[k][subK] = subV
                end
            else
                self.db.profile[k] = v
            end
        elseif type(v) == "table" and type(self.db.profile[k]) == "table" then
            for subK, subV in pairs(v) do
                if self.db.profile[k][subK] == nil then
                    self.db.profile[k][subK] = subV
                end
            end
        end
    end
end

-- Initialize Addon
function addon:OnInitialize()
    -- Initialize database
    self:InitializeDB()
    
    -- Setup configuration options
    self:SetupOptions()
    
    -- Register slash commands natively
    SLASH_BearWarning1 = "/bw"
    SLASH_BearWarning2 = "/bearwarning"
    SlashCmdList["BearWarning"] = function()
        addon:ToggleConfig()
    end
    
    -- Print welcome message
    self:Print(L["WelcomeMessage"])
end

-- Open/Close Config Panel
function addon:ToggleConfig()
    if not self.optionsCategoryId then return end
    
    if Settings and Settings.OpenToCategory then
        local category
        pcall(function() category = Settings.GetCategory(self.optionsCategoryId) end)
        
        local success
        if category then
            success = pcall(Settings.OpenToCategory, category)
        end
        if not success then
            pcall(Settings.OpenToCategory, self.optionsCategoryId)
        end
    elseif self.optionsFrame then
        pcall(InterfaceOptionsFrame_OpenToCategory, self.optionsFrame)
    end
end
