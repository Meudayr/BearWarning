local ADDON_NAME, addonTable = ...
local addon = addonTable.addon
local L = addon.L

-- Setup LibSharedMedia sound registrations
local LSM = LibStub("LibSharedMedia-3.0", true)
if LSM then
    LSM:Register("sound", "Raid Warning", "Sound\\Interface\\RaidWarning.ogg")
    LSM:Register("sound", "Bellowing Roar", "Sound\\Spells\\BellowingRoar.ogg")
    LSM:Register("sound", "Aggro Warning", "Sound\\Interface\\ur_interface_bell_ring_stereo.ogg")
    LSM:Register("sound", "LFG Roll", "Sound\\Interface\\LFG_RoleCheck.ogg")
    LSM:Register("sound", "Buzzer", "Sound\\Interface\\AlarmClockWarning3.ogg")
    LSM:Register("sound", "Whip", "Sound\\Spells\\WhipA.ogg")
end

local function GetSoundValues()
    if LSM then
        return LSM:HashTable("sound")
    else
        return {
            ["Raid Warning"] = "Sound\\Interface\\RaidWarning.ogg",
            ["Bellowing Roar"] = "Sound\\Spells\\BellowingRoar.ogg",
            ["Aggro Warning"] = "Sound\\Interface\\ur_interface_bell_ring_stereo.ogg",
        }
    end
end

function addon:SetupOptions()
    local options = {
        name = "Bear Warning",
        type = "group",
        args = {
            general = {
                order = 1,
                type = "group",
                name = L["GeneralSettings"],
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = L["EnableAddon"],
                        desc = L["EnableAddonDesc"],
                        get = function(info) return addon.db.profile.enabled end,
                        set = function(info, val) 
                            addon.db.profile.enabled = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    lockFrame = {
                        order = 2,
                        type = "toggle",
                        name = L["LockFrame"],
                        desc = L["LockFrameDesc"],
                        get = function(info) return addon.db.profile.lockFrame end,
                        set = function(info, val)
                            addon.db.profile.lockFrame = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    guardianOnly = {
                        order = 3,
                        type = "toggle",
                        name = L["GuardianOnly"],
                        desc = L["GuardianOnlyDesc"],
                        get = function(info) return addon.db.profile.guardianOnly end,
                        set = function(info, val)
                            addon.db.profile.guardianOnly = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    testMode = {
                        order = 4,
                        type = "toggle",
                        name = L["TestMode"],
                        desc = L["TestModeDesc"],
                        get = function(info) return addon.isTestMode end,
                        set = function(info, val)
                            addon:SetTestMode(val)
                        end,
                    },
                    enableDuration = {
                        order = 4.1,
                        type = "toggle",
                        name = L["EnableDuration"],
                        desc = L["EnableDurationDesc"],
                        get = function(info) return addon.db.profile.enableDuration end,
                        set = function(info, val)
                            addon.db.profile.enableDuration = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    alertDuration = {
                        order = 4.2,
                        type = "range",
                        name = L["AlertDuration"],
                        desc = L["AlertDurationDesc"],
                        min = 1, max = 30, step = 0.5,
                        disabled = function() return not addon.db.profile.enableDuration end,
                        get = function(info) return addon.db.profile.alertDuration end,
                        set = function(info, val)
                            addon.db.profile.alertDuration = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    enableWorld = {
                        order = 4.3,
                        type = "toggle",
                        name = L["EnableWorld"],
                        desc = L["EnableWorldDesc"],
                        get = function(info) return addon.db.profile.enableWorld end,
                        set = function(info, val)
                            addon.db.profile.enableWorld = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    enableInstances = {
                        order = 4.4,
                        type = "toggle",
                        name = L["EnableInstances"],
                        desc = L["EnableInstancesDesc"],
                        get = function(info) return addon.db.profile.enableInstances end,
                        set = function(info, val)
                            addon.db.profile.enableInstances = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    enablePvP = {
                        order = 4.5,
                        type = "toggle",
                        name = L["EnablePvP"],
                        desc = L["EnablePvPDesc"],
                        get = function(info) return addon.db.profile.enablePvP end,
                        set = function(info, val)
                            addon.db.profile.enablePvP = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    reset = {
                        order = 5,
                        type = "execute",
                        name = "Reset Settings",
                        desc = "Reset all settings to default values.",
                        func = function()
                            _G.BearFormAlertDB = {}
                            addon:InitializeDB()
                            addon:UpdateAlertSettings()
                            addon:Print("Settings reset to defaults.")
                        end,
                    },
                }
            },
            visual = {
                order = 2,
                type = "group",
                name = L["VisualSettings"],
                inline = true,
                args = {
                    frameSize = {
                        order = 1,
                        type = "range",
                        name = L["FrameSize"],
                        desc = L["FrameSizeDesc"],
                        min = 40, max = 200, step = 1,
                        get = function(info) return addon.db.profile.frameSize end,
                        set = function(info, val)
                            addon.db.profile.frameSize = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    frameOpacity = {
                        order = 2,
                        type = "range",
                        name = L["FrameOpacity"],
                        desc = L["FrameOpacityDesc"],
                        min = 0.1, max = 1.0, step = 0.05,
                        get = function(info) return addon.db.profile.frameOpacity end,
                        set = function(info, val)
                            addon.db.profile.frameOpacity = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    enableGlow = {
                        order = 3,
                        type = "toggle",
                        name = L["EnableGlow"],
                        desc = L["EnableGlowDesc"],
                        get = function(info) return addon.db.profile.enableGlow end,
                        set = function(info, val)
                            addon.db.profile.enableGlow = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    glowColor = {
                        order = 4,
                        type = "color",
                        name = L["GlowColor"],
                        desc = L["GlowColorDesc"],
                        hasAlpha = true,
                        arg = { default = { r = 0.9, g = 0.1, b = 0.1, a = 0.8 } },
                        disabled = function() return not addon.db.profile.enableGlow end,
                        get = function(info)
                            local c = addon.db.profile.glowColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(info, r, g, b, a)
                            addon.db.profile.glowColor = { r = r, g = g, b = b, a = a }
                            addon:UpdateAlertSettings()
                        end,
                    },
                    showText = {
                        order = 5,
                        type = "toggle",
                        name = L["ShowText"],
                        desc = L["ShowTextDesc"],
                        get = function(info) return addon.db.profile.showText end,
                        set = function(info, val)
                            addon.db.profile.showText = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    textSize = {
                        order = 6,
                        type = "range",
                        name = L["TextSize"],
                        desc = L["TextSizeDesc"],
                        min = 8, max = 24, step = 1,
                        disabled = function() return not addon.db.profile.showText end,
                        get = function(info) return addon.db.profile.textSize end,
                        set = function(info, val)
                            addon.db.profile.textSize = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    textColor = {
                        order = 7,
                        type = "color",
                        name = L["TextColor"],
                        desc = L["TextColorDesc"],
                        hasAlpha = true,
                        arg = { default = { r = 1, g = 1, b = 1, a = 1 } },
                        disabled = function() return not addon.db.profile.showText end,
                        get = function(info)
                            local c = addon.db.profile.textColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(info, r, g, b, a)
                            addon.db.profile.textColor = { r = r, g = g, b = b, a = a }
                            addon:UpdateAlertSettings()
                        end,
                    },
                    screenFlash = {
                        order = 8,
                        type = "toggle",
                        name = L["ScreenFlash"],
                        desc = L["ScreenFlashDesc"],
                        get = function(info) return addon.db.profile.enableScreenFlash end,
                        set = function(info, val)
                            addon.db.profile.enableScreenFlash = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    flashColor = {
                        order = 8.5,
                        type = "color",
                        name = L["FlashColor"] or "Screen Flash Color",
                        desc = L["FlashColorDesc"] or "Set the color of the screen edge flash vignette.",
                        hasAlpha = false,
                        arg = { default = { r = 1, g = 0, b = 0 } },
                        disabled = function() return not addon.db.profile.enableScreenFlash end,
                        get = function(info)
                            local c = addon.db.profile.flashColor or { r = 1, g = 0, b = 0 }
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            addon.db.profile.flashColor = { r = r, g = g, b = b }
                            addon:UpdateAlertSettings()
                        end,
                    },
                    flashIntensity = {
                        order = 9,
                        type = "range",
                        name = L["FlashIntensity"],
                        desc = L["FlashIntensityDesc"],
                        min = 0.1, max = 1.0, step = 0.05,
                        disabled = function() return not addon.db.profile.enableScreenFlash end,
                        get = function(info) return addon.db.profile.flashIntensity end,
                        set = function(info, val)
                            addon.db.profile.flashIntensity = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                }
            },
            audio = {
                order = 3,
                type = "group",
                name = L["AudioSettings"],
                inline = true,
                args = {
                    playWarning = {
                        order = 1,
                        type = "toggle",
                        name = L["PlaySound"],
                        desc = L["PlaySoundDesc"],
                        get = function(info) return addon.db.profile.enableSound end,
                        set = function(info, val)
                            addon.db.profile.enableSound = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    soundFile = {
                        order = 2,
                        type = "select",
                        dialogControl = LSM and "LSM30_Sound" or nil,
                        name = L["SoundFile"],
                        desc = L["SoundFileDesc"],
                        disabled = function() return not addon.db.profile.enableSound end,
                        values = GetSoundValues(),
                        get = function(info) return addon.db.profile.soundFile end,
                        set = function(info, val)
                            addon.db.profile.soundFile = val
                            addon:UpdateAlertSettings()
                            -- Play sample sound to let user hear the selection
                            addon:PlayWarningSound()
                        end,
                    },
                    soundChannel = {
                        order = 3,
                        type = "select",
                        name = L["SoundChannel"],
                        desc = L["SoundChannelDesc"],
                        disabled = function() return not addon.db.profile.enableSound end,
                        values = {
                            ["Master"] = L["SoundChannelMaster"],
                            ["SFX"] = L["SoundChannelSFX"],
                            ["Music"] = L["SoundChannelMusic"],
                            ["Ambience"] = L["SoundChannelAmbience"],
                            ["Dialog"] = L["SoundChannelDialog"],
                        },
                        get = function(info) return addon.db.profile.soundChannel end,
                        set = function(info, val)
                            addon.db.profile.soundChannel = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    soundVolume = {
                        order = 3.5,
                        type = "range",
                        name = L["SoundVolume"],
                        desc = L["SoundVolumeDesc"],
                        min = 0, max = 1.0, step = 0.05,
                        isPercent = true,
                        disabled = function() return not addon.db.profile.enableSound end,
                        get = function(info)
                            local channel = addon.db.profile.soundChannel or "Master"
                            local cvar = "Sound_" .. channel .. "Volume"
                            return tonumber(GetCVar(cvar)) or 1.0
                        end,
                        set = function(info, val)
                            local channel = addon.db.profile.soundChannel or "Master"
                            local cvar = "Sound_" .. channel .. "Volume"
                            SetCVar(cvar, val)
                        end,
                    },
                    soundInterval = {
                        order = 4,
                        type = "range",
                        name = L["SoundInterval"],
                        desc = L["SoundIntervalDesc"],
                        min = 0.5, max = 5.0, step = 0.1,
                        disabled = function() return not addon.db.profile.enableSound end,
                        get = function(info) return addon.db.profile.soundInterval end,
                        set = function(info, val)
                            addon.db.profile.soundInterval = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                }
            },
            interaction = {
                order = 4,
                type = "group",
                name = L["InteractionSettings"],
                inline = true,
                args = {
                    enableClickToShift = {
                        order = 1,
                        type = "toggle",
                        name = L["EnableClickToShift"],
                        desc = L["EnableClickToShiftDesc"],
                        get = function(info) return addon.db.profile.enableClickToShift end,
                        set = function(info, val)
                            addon.db.profile.enableClickToShift = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    hotKey = {
                        order = 2,
                        type = "keybinding",
                        name = L["HotKey"],
                        desc = L["HotKeyDesc"],
                        disabled = function() return not addon.db.profile.enableClickToShift end,
                        get = function(info) return addon.db.profile.hotKey end,
                        set = function(info, val)
                            addon.db.profile.hotKey = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    hotKey2 = {
                        order = 3,
                        type = "keybinding",
                        name = L["EmergencyKey2"],
                        desc = L["HotKeyDesc"],
                        disabled = function() return not addon.db.profile.enableClickToShift end,
                        get = function(info) return addon.db.profile.hotKey2 end,
                        set = function(info, val)
                            addon.db.profile.hotKey2 = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                    hotKey3 = {
                        order = 4,
                        type = "keybinding",
                        name = L["EmergencyKey3"],
                        desc = L["HotKeyDesc"],
                        disabled = function() return not addon.db.profile.enableClickToShift end,
                        get = function(info) return addon.db.profile.hotKey3 end,
                        set = function(info, val)
                            addon.db.profile.hotKey3 = val
                            addon:UpdateAlertSettings()
                        end,
                    },
                }
            }
        }
    }
    
    -- Register AceConfig options
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, options)
    
    self.optionsFrameName = ADDON_NAME
    local optionsFrame, categoryId = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_NAME)
    self.optionsFrame = optionsFrame
    self.optionsCategoryId = categoryId
end
