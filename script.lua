local categories = C_Engraving.GetRuneCategories(true, true);
for _, category in ipairs(categories) do
    local runes = C_Engraving.GetRunesForCategory(category, true);
    for _, rune in ipairs(runes) do
        local macroText =
        "#showtooltip %s\n/run C_Engraving.CastRune(%d)\n/use %d\n/click StaticPopup1Button1\n\n"
        print(macroText:format(
            rune.name,
            rune.skillLineAbilityID,
            category
        ));
    end;
end;
local playerClass = select(2, UnitClass("player"))
local usesMana = UnitPowerType("player", 1) == Enum.PowerType.Mana
local usesRage = UnitPowerType("player", 2) == Enum.PowerType.Rage
local usesStones = playerClass == "ROGUE"
    or playerClass == "WARRIOR"
local usesOils = playerClass == "MAGE"
    or playerClass == "WARLOCK"
    or playerClass == "PRIEST"
if playerClass == "DRUID" or playerClass == "PALADIN" then
    local strength = UnitStat("player", 1) or 0
    local agility = UnitStat("player", 2) or 0
    local intellect = UnitStat("player", 4) or 0
    if max(strength, agility) >= intellect then
        usesOils = false
        if playerClass == "PALADIN" then
            usesStones = true
        end
    else
        usesStones = false
        usesOils = true
    end
end
local isRogue = playerClass == "ROGUE"
--- [itemID] = amount | {condition} and {amountIfTrue} or {amountIfFalse}
aura_env.evool = {
    consumes = {
        -- First-Aid
        [6450] = 20,                      -- Silk Bandage
        -- Cooking
        [3728] = 0,                       -- Tasty Lion Steak
        [5527] = 5,                       -- Goblin Deviled Clams
        -- Weapon Enchants
        [211845] = usesStones and 3 or 0, -- Blackfathom Sharpening Stone
        [211848] = usesOils and 3 or 0,   -- Blackfathom Mana Oil
        -- Engineering
        [6714] = 10,                      -- EZ-Thro Dynamite
        [4378] = 0,                       -- Heavy Dynamite
        -- Alchemy
        --- util pot
        [3386] = 0,                    -- Elixir of Poison Resistance
        --- potion cd
        [5634] = 5,                    -- Free Action Potion
        [6048] = 3,                    -- Shadow Protection Potion
        [929] = 10,                    -- Healing Potion
        [3385] = usesMana and 10 or 0, -- Lesser Mana Potion
        [3827] = 0,                    -- Mana Potion
        [5631] = usesRage and 10 or 0, -- Rage Potion
        [2459] = 0,                    -- Swiftness Potion
        --- elixirs
        [3388] = 1,                    -- Strong Troll's Blood
        [3390] = 3,                    -- Lesser Agility
        [3391] = 3,                    -- Ogre's Strength
        [3389] = 1,                    -- Defense Elixir
        [2458] = 3,                    -- Minor Fort Elixir
        -- Misc
        [211816] = 1,                  -- Warsong Battle Drum
        -- Rogue
        [6947] = isRogue and 10 or 0,  -- Instant Poison I
        [7676] = isRogue and 10 or 0,  -- Thistle Tea
    }
}


-- local printBitValues = (function()
--     local str = "0x%08X"
--     local bitFields = {
--         "COMBATLOG_OBJECT_AFFILIATION_MINE",
--         "COMBATLOG_OBJECT_AFFILIATION_PARTY",
--         "COMBATLOG_OBJECT_AFFILIATION_RAID",
--         "COMBATLOG_OBJECT_AFFILIATION_OUTSIDER",
--         "COMBATLOG_OBJECT_AFFILIATION_MASK",
--         "COMBATLOG_OBJECT_REACTION_FRIENDLY",
--         "COMBATLOG_OBJECT_REACTION_NEUTRAL",
--         "COMBATLOG_OBJECT_REACTION_HOSTILE",
--         "COMBATLOG_OBJECT_REACTION_MASK",
--         "COMBATLOG_OBJECT_CONTROL_PLAYER",
--         "COMBATLOG_OBJECT_CONTROL_NPC",
--         "COMBATLOG_OBJECT_CONTROL_MASK",
--         "COMBATLOG_OBJECT_TYPE_PLAYER",
--         "COMBATLOG_OBJECT_TYPE_NPC",
--         "COMBATLOG_OBJECT_TYPE_PET",
--         "COMBATLOG_OBJECT_TYPE_GUARDIAN",
--         "COMBATLOG_OBJECT_TYPE_OBJECT",
--         "COMBATLOG_OBJECT_TYPE_MASK",
--     }

--     for _, field in ipairs(bitFields) do
--         print(field .. ": " .. str:format(_G[field]))
--     end
-- end)()


local channelInfo = {
    -- [localizedSpellName]
    [GetSpellInfo(402174)] = { -- Penance
        durationMS = 2000,
        notInterruptible = false,
        text = CHANNELING -- bar display text
    },
    -- MISC
    [GetSpellInfo(746)] = {durationMS = 8000},      -- First Aid
    [GetSpellInfo(13278)] = {durationMS = 4000},    -- Gnomish Death Ray
    [GetSpellInfo(20577)] = {durationMS = 10000},   -- Cannibalize
    [GetSpellInfo(10797)] = {durationMS = 6000},    -- Starshards
    [GetSpellInfo(16430)] = {durationMS = 12000},   -- Soul Tap
    [GetSpellInfo(24323)] = {durationMS = 8000},    -- Blood Siphon
    [GetSpellInfo(27640)] = {durationMS = 3000},    -- Baron Rivendare's Soul Drain
    [GetSpellInfo(7290)] = {durationMS = 10000},    -- Soul Siphon
    [GetSpellInfo(24322)] = {durationMS = 8000},    -- Blood Siphon
    [GetSpellInfo(27177)] = {durationMS = 10000},   -- Defile
    [GetSpellInfo(27286)] = {durationMS = 1000},    -- Shadow Wrath (see issue #59)
    -- DRUID
    [GetSpellInfo(17401)] = {durationMS = 10000},   -- Hurricane
    [GetSpellInfo(740)] = {durationMS = 10000},     -- Tranquility
    [GetSpellInfo(20687)] = {durationMS = 10000},   -- Starfall
    -- HUNTER
    [GetSpellInfo(6197)] = {durationMS = 60000},     -- Eagle Eye
    [GetSpellInfo(1002)] = {durationMS = 60000},     -- Eyes of the Beast
    [GetSpellInfo(1510)] = {durationMS = 6000},      -- Volley
    [GetSpellInfo(136)] = {durationMS = 5000},       -- Mend Pet
    -- MAGE
    [GetSpellInfo(5143)] = {durationMS = 5000},      -- Arcane Missiles
    [GetSpellInfo(7268)] = {durationMS = 3000},      -- Arcane Missile
    [GetSpellInfo(10)] = {durationMS = 8000},        -- Blizzard
    [GetSpellInfo(12051)] = {durationMS = 8000},     -- Evocation
    -- PRIEST
    [GetSpellInfo(15407)] = {durationMS = 3000},     -- Mind Flay
    [GetSpellInfo(2096)] = {durationMS = 60000},     -- Mind Vision
    [GetSpellInfo(605)] = {durationMS = 3000},       -- Mind Control
    -- [GetSpellInfo(402174)] = {durationMS = 2000},    -- Penance (SoD)
    -- WARLOCK
    [GetSpellInfo(126)] = {durationMS = 45000},      -- Eye of Kilrogg
    [GetSpellInfo(689)] = {durationMS = 5000},       -- Drain Life
    [GetSpellInfo(5138)] = {durationMS = 5000},      -- Drain Mana
    [GetSpellInfo(1120)] = {durationMS = 15000},     -- Drain Soul
    [GetSpellInfo(5740)] = {durationMS = 8000},      -- Rain of Fire
    [GetSpellInfo(1949)] = {durationMS = 15000},     -- Hellfire
    [GetSpellInfo(755)] = {durationMS = 10000},      -- Health Funnel
    [GetSpellInfo(17854)] = {durationMS = 10000},    -- Consume Shadows
    [GetSpellInfo(6358)] = {durationMS = 15000},     -- Seduction Channel
}
hooksecurefunc("CastingBarFrame_OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_CHANNEL_START"
        and ... == self.unit
    then
        local castGUID, spellID = select(3, ...)
        local spellName, _, texture = GetSpellInfo(spellID)
        local channelInfo = channelInfo[spellName]
        local timerStart = GetTimePreciseSec()
        if channelInfo then
            print("channel start")
            self.notInterruptible = channelInfo.notInterruptible

            local startColor = CastingBarFrame_GetEffectiveStartColor(self, true);
            print(startColor:GetRGB())
            if self.flashColorSameAsStart then
                self.Flash:SetVertexColor(startColor:GetRGB());
            else
                self.Flash:SetVertexColor(1, 1, 1);
            end
            self:SetStatusBarColor(startColor:GetRGB());
            --- cast time info since UnitChannelInfo is not available for non-player units
            local duration = channelInfo.durationMS / 1000
            if castGUID then
                -- eg Cast-3-4170-0-8-84714-000CB03025
                -- the lowest 23 bits represent the timestamp of the cast measured in seconds since the UNIX epoch as returned by GetServerTime() modulo 2^23, and the higher bits appear to be an incrementing number for spell casts that occur within the same second. 
                local castID = select(6, strsplit("-", castGUID))
                local castTimeEpoch = tonumber(string.sub(castID, 5), 16);
                local serverTimestamp = GetServerTime()
                local currentEpoch = serverTimestamp - (serverTimestamp % 2^23)
                local castEpochOffset = bit.band(
                    castTimeEpoch,
                    0x7fffff
                )
                local serverCastTime = currentEpoch + castEpochOffset
            
                if serverCastTime > serverTimestamp then
                    -- This only occurs if the epoch has rolled over since the cast started (rare)
                    serverCastTime = serverCastTime - ((2^23) - 1)
                end
                self.value = duration - (serverTimestamp - serverCastTime);
            else
                self.value = duration - (GetTimePreciseSec() - timerStart);
            end
            print("value", self.value)
            self.maxValue = duration;
            self:SetMinMaxValues(0, self.maxValue);
            self:SetValue(self.value);

            if (self.Text) then
                self.Text:SetText(channelInfo.text or spellName);
            end
            if (self.Icon) then
                CastingBarFrame_SetIcon(self, texture);
            end
            if (self.Spark) then
                self.Spark:Hide();
            end

            CastingBarFrame_ApplyAlpha(self, 1.0);

            self.holdTime = 0;
            self.casting = nil;
            self.channeling = true;
            self.fadeOut = nil;
            if (self.BorderShield) then
                if (self.showShield and self.notInterruptible) then
                    self.BorderShield:Show();
                    if (self.BarBorder) then
                        self.BarBorder:Hide();
                    end
                else
                    self.BorderShield:Hide();
                    if (self.BarBorder) then
                        self.BarBorder:Show();
                    end
                end
            end
            if (self.showCastbar) then
                print("should show castbar")
                self:Show();
            end
        end
    end
end)


hooksecurefunc(ClassicCastbars , "UNIT_SPELLCAST_CHANNEL_START", 
function (self, unit, castGUID, spellID)
    local castbar = self:GetCastbarFrameIfEnabled(unit)
    if not castbar then return end
    -- This function calls UnitChannelInfo which is not available for non-player units in classic era client.
    -- self:BindCurrentCastData(castbar, unit, true)

    -- Recreate the functionality 
    local spellName, _, texture = GetSpellInfo(spellID)
    if not spellName then return end
    
    local channelInfo = channelInfo[spellName]
    if not channelInfo then return end

    local duration = channelInfo.durationMS / 1000
    local timerStart = GetTimePreciseSec()
    
    castbar._data = castbar._data or {}
    local cast = castbar._data
    
    --- spell info
    cast.spellName = spellName
    cast.spellID = spellID
    cast.icon = texture
    
    -- cast info
    cast.castID = castGUID
    cast.isChanneled = true
    cast.isUninterruptible = channelInfo.notInterruptible
    cast.isFailed = nil
    cast.isInterrupted = nil
    cast.origIsUninterruptible = nil
    cast.isCastComplete = nil
    cast.unitIsPlayer = UnitIsPlayer(castGUID)
    
    -- castbar duration info
    if castGUID then
        -- eg Cast-3-4170-0-8-84714-000CB03025
        -- the lowest 23 bits represent the timestamp of the cast measured in seconds since the UNIX epoch as returned by GetServerTime() modulo 2^23, and the higher bits appear to be an incrementing number for spell casts that occur within the same second. 
        local castID = select(6, strsplit("-", castGUID))
        local castTimeEpoch = tonumber(string.sub(castID, 5), 16);
        local serverTimestamp = GetServerTime()
        local currentEpoch = serverTimestamp - (serverTimestamp % 2^23)
        local castEpochOffset = bit.band(
            castTimeEpoch,
            0x7fffff
        )
        local serverCastTime = currentEpoch + castEpochOffset
        local serverToSystemOffset = GetTime() - serverTimestamp
        cast.timeStart = serverCastTime + serverToSystemOffset;
        cast.endTime = cast.timeStart + duration;
        
    else
        cast.timeStart = GetTime() - (GetTimePreciseSec() - timerStart);
        cast.endTime = cast.timeStart + duration;
    end
    cast.maxValue = duration;
    self:DisplayCastbar(castbar, unit)
end)

hooksecurefunc(ClassicCastbars, "COMBAT_LOG_EVENT_UNFILTERED",
    function(self)
        DevTool:AddData(self)
        local PENANCE = GetSpellInfo(402174)
        local _, eventType, _, srcGUID, _, srcFlags, _, dstGUID, _, dstFlags, _, spellID, spellName, _, missType, _, extraSchool =
            CombatLogGetCurrentEventInfo()
        if eventType == "SPELL_CAST_SUCCESS" then
            print("cast success")
            local channelCast = spellName == PENANCE and 2000
            if not channelCast and not spellID then
                -- Stop current cast on any new non-cast ability used
                if self.activeTimers[srcGUID] and GetTime() - self.activeTimers[srcGUID].timeStart > 0.25 then
                    return self:StopAllCasts(srcGUID)
                end

                return -- spell was not a cast nor channel
            end

            local isSrcPlayer = bit.band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0

            -- Channeled spells are started on SPELL_CAST_SUCCESS, and generally stops on SPELL_AURA_REMOVED instead.
            -- Also there's no castTime returned from GetSpellInfo for channeled spells so we need to get it from our own list
            if channelCast then
                print("channel")
                if spellName == PENANCE then
                    -- Penance triggers this event for every tick so ignore after first tick has been detected
                    local cast = self.activeTimers and self.activeTimers[srcGUID]
                    if cast and (cast.spellName == PENANCE) then return end
                end

                -- Channeled spell, add it
                return self:StoreCast(srcGUID, spellName, spellID, GetSpellTexture(spellID), channelCast, isSrcPlayer,
                    true)
            end

            -- Non-channeled spell, finish it.
            -- We also check the expiration timer in OnUpdate script just incase this event doesn't trigger when i.e unit is no longer in range.
            return self:DeleteCast(srcGUID, nil, nil, true)
        end
    end)

function testHealComm()
    -- LibStub.libs["LibHealComm-4.0"].HOT_HEALS
    HealComm = LibStub.GetLibrary("LibHealComm-4.0");
    LibStub.GetLibrary("LibHealComm-4.0"):GetNextHealAmount(UnitGUID("player"), LibStub.GetLibrary("LibHealComm-4.0").HOT_HEALS);
end

if C_CVar.GetCVar("enableFloatingCombatText") ~= "1" then
    C_CVar.SetCVar("enableFloatingCombatText", 1)
end