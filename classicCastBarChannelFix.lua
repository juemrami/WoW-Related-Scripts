-- For ClassicCastbars v1.7.4 add Channeled Spell support
if not aura_env.init
    and C_AddOns.IsAddOnLoaded("ClassicCastbars")
    and ClassicCastbars
    and not ClassicCastbars.isChannelFixHooked
then
    local ClassicCastbars = ClassicCastbars --[[@as Frame]]
    print(ClassicCastbars.isChannelFixHooked)
    -- Unique spells
    --- {[localizedName]: { durationMS: number, notInterruptible: boolean? }}
    local channelData = {
        -- SoD
        [GetSpellInfo(402174)] = {                      -- Penance
            durationMS = 2000,                          -- channel duration in MS
            notInterruptible = nil,                     -- if channel is interruptible.
        },
        [GetSpellInfo(401417)] = { durationMS = 3000 }, -- Regeneration
        [GetSpellInfo(412510)] = { durationMS = 3000 }, -- Mass Regeneration
        -- MISC
        [GetSpellInfo(746)] = { durationMS = 8000 },    -- First Aid
        [GetSpellInfo(13278)] = { durationMS = 4000 },  -- Gnomish Death Ray
        [GetSpellInfo(20577)] = { durationMS = 10000 }, -- Cannibalize
        [GetSpellInfo(10797)] = { durationMS = 6000 },  -- Starshards
        [GetSpellInfo(16430)] = { durationMS = 12000 }, -- Soul Tap
        [GetSpellInfo(24323)] = { durationMS = 8000 },  -- Blood Siphon
        [GetSpellInfo(27640)] = { durationMS = 3000 },  -- Baron Rivendare's Soul Drain
        [GetSpellInfo(7290)] = { durationMS = 10000 },  -- Soul Siphon
        [GetSpellInfo(24322)] = { durationMS = 8000 },  -- Blood Siphon
        [GetSpellInfo(27177)] = { durationMS = 10000 }, -- Defile
        [GetSpellInfo(27286)] = { durationMS = 1000 },  -- Shadow Wrath (see issue #59)
        -- DRUID
        [GetSpellInfo(17401)] = { durationMS = 10000 }, -- Hurricane
        [GetSpellInfo(740)] = { durationMS = 10000 },   -- Tranquility
        [GetSpellInfo(20687)] = { durationMS = 10000 }, -- Starfall
        -- HUNTER
        [GetSpellInfo(6197)] = { durationMS = 60000 },  -- Eagle Eye
        [GetSpellInfo(1002)] = { durationMS = 60000 },  -- Eyes of the Beast
        [GetSpellInfo(1510)] = { durationMS = 6000 },   -- Volley
        [GetSpellInfo(136)] = { durationMS = 5000 },    -- Mend Pet
        -- MAGE
        [GetSpellInfo(5143)] = { durationMS = 5000 },   -- Arcane Missiles
        [GetSpellInfo(7268)] = { durationMS = 3000 },   -- Arcane Missile
        [GetSpellInfo(10)] = { durationMS = 8000 },     -- Blizzard
        [GetSpellInfo(12051)] = { durationMS = 8000 },  -- Evocation
        -- PRIEST
        [GetSpellInfo(15407)] = { durationMS = 3000 },  -- Mind Flay
        [GetSpellInfo(2096)] = { durationMS = 60000 },  -- Mind Vision
        [GetSpellInfo(605)] = { durationMS = 3000 },    -- Mind Control
        -- WARLOCK
        [GetSpellInfo(126)] = { durationMS = 45000 },   -- Eye of Kilrogg
        [GetSpellInfo(689)] = { durationMS = 5000 },    -- Drain Life
        [GetSpellInfo(5138)] = { durationMS = 5000 },   -- Drain Mana
        [GetSpellInfo(1120)] = { durationMS = 15000 },  -- Drain Soul
        [GetSpellInfo(5740)] = { durationMS = 8000 },   -- Rain of Fire
        [GetSpellInfo(1949)] = { durationMS = 15000 },  -- Hellfire
        [GetSpellInfo(755)] = { durationMS = 10000 },   -- Health Funnel
        [GetSpellInfo(17854)] = { durationMS = 10000 }, -- Consume Shadows
        [GetSpellInfo(6358)] = { durationMS = 15000 },  -- Seduction Channel
    }
    local uninterruptibleChannels = {
        -- these are technically uninterruptible but breaks on dmg
        [GetSpellInfo(13278)] = true, -- Gnomish Death Ray
        [GetSpellInfo(746)] = true,   -- First Aid
        [GetSpellInfo(20577)] = true, -- Cannibalize
        [GetSpellInfo(1510)] = true,  -- Volley
    }
    --- Have chance to ignore pushback when talented, or are always immune.
    local pushbackImmuneChannels = {
        [GetSpellInfo(7268)] = true,  -- Arcane Missiles
        [GetSpellInfo(13278)] = true, -- Gnomish Death Ray
    }
    local interruptImmunities = {
        [GetSpellInfo(642)] = true, -- Divine Shield
        [GetSpellInfo(498)] = true, -- Divine Protection
    }
    ---Track recent channel casts. Used for TARGET_CHANGED
    ---@type table<string, string> # { [unitGUID]: castGUID }
    local currentChannels = {}

    -- General channeled cast support
    hooksecurefunc(ClassicCastbars, "UNIT_SPELLCAST_CHANNEL_START",
    function(self, unit, castGUID, spellID)
            if unit and not castGUID then 
             -- When the target of a channel is the player casting it,
             -- the castGUID will be `nil` for this event.

             -- This will cause a bug where unless the player has themselves targeted initially the target castbar will not show up for channels when the player targets themselves.

             --So we can either:
             -- A. use the info from UnitChannelInfo and add the bit of the function that sets the castbar data (see below)) to this condition branch
             -- B. use the info from UnitChannelInfo and make a pseudo castGUID using the endTimeMS and then re-call this function with that guid.
             -- C. Ignore the bug since its such a rare case.
             
            end
            currentChannels[UnitGUID(unit)] = castGUID
            DevTool:AddData({unit, castGUID, spellID} , "UNIT_SPELLCAST_CHANNEL_START")
            DevTool:AddData(currentChannels, "currentTrackedChannels added")
            local castbar = self:GetCastbarFrameIfEnabled(unit)
            if not castbar then return end
            -- This function calls UnitChannelInfo which is not available for non-player units in classic era client.
            -- self:BindCurrentCastData(castbar, unit, true)

            -- Recreate the functionality
            local spellName, _, texture = GetSpellInfo(spellID)
            if not spellName then return end

            local channel = channelData[spellName]
            if not channel then return end

            local duration = channel.durationMS / 1000
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
            cast.isUninterruptible = channel.notInterruptible
            cast.isFailed = nil
            cast.isInterrupted = nil
            cast.origIsUninterruptible = nil
            cast.isCastComplete = nil
            cast.unitIsPlayer = UnitIsPlayer(unit)

            -- castbar duration info
            if castGUID then
                -- eg Cast-3-4170-0-8-84714-000CB03025
                -- the lowest 23 bits represent the timestamp of the cast measured in seconds since the UNIX epoch as returned by GetServerTime() modulo 2^23, and the higher bits appear to be an incrementing number for spell casts that occur within the same second.
                local castID = select(6, strsplit("-", castGUID))
                local castTimeEpoch = tonumber(string.sub(castID, 5), 16);
                local serverTimestamp = GetServerTime()
                local currentEpoch = serverTimestamp - (serverTimestamp % 2 ^ 23)
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

            if not cast.isUninterruptible then
                local unitIsKickImmune = function()
                    for i = 1, 40 do
                        local buffName = UnitAura(unit, i, "HELPFUL")
                        if not buffName then break end
                        if interruptImmunities[buffName] then
                            return true
                        end
                    end
                end
                local unitCastIsUninterruptible = function()
                    if cast.unitIsPlayer then
                        return uninterruptibleChannels[spellName]
                    else
                        local npcID = select(6, strsplit("-", UnitGUID(unit) or ""))
                        local uninterruptibleNpcSpells = ClassicCastbarsDB
                            and ClassicCastbarsDB.npcCastUninterruptibleCache
                            or nil
                        if npcID and uninterruptibleNpcSpells then
                            return uninterruptibleNpcSpells[npcID .. spellName]
                        end
                    end
                end
                cast.isUninterruptible = unitCastIsUninterruptible()
                    or unitIsKickImmune()
            end
            currentChannels[UnitGUID(unit)] = castGUID
            self:DisplayCastbar(castbar, unit)
        end
    )
    
    -- Adding target change functionality to show target castbar for channeled spells when not originally targeted. 
    hooksecurefunc(ClassicCastbars, "UNIT_SPELLCAST_CHANNEL_STOP",
        function(self, unit, castGUID, spellID)
            if currentChannels then
                currentChannels[UnitGUID(unit)] = nil
            end
        end
    )
    hooksecurefunc(ClassicCastbars, "PLAYER_TARGET_CHANGED",
        function(self)
            if currentChannels then
                local castGUID = currentChannels[UnitGUID("target")]
                DevTool:AddData(currentChannels, "currentTrackedChannels")
                if castGUID then
                    local spellID = tonumber(select(6, strsplit("-", castGUID)))
                    print("spellID found: " .. spellID, " sending to UNIT_SPELLCAST_CHANNEL_START")
                    self:UNIT_SPELLCAST_CHANNEL_START("target", castGUID, spellID)
                end
            end
        end
    )

    -- Cast pushback support for channels (based on code from ClassicCastbars)
    hooksecurefunc(ClassicCastbars, "COMBAT_LOG_EVENT_UNFILTERED",
        function(self)
            local _, subEvent, _, _, _, _, _, destGUID, _, destFlags = CombatLogGetCurrentEventInfo()
            if subEvent == "SWING_DAMAGE"
                or subEvent == "ENVIRONMENTAL_DAMAGE"
                or subEvent == "RANGE_DAMAGE"
                or subEvent == "SPELL_DAMAGE"
            then
                ---@cast destFlags number
                if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
                    local unit = self:GetFirstAvailableUnitIDByGUID(destGUID)
                    if not unit then return end
                    print(unit)
                    local castbar = self:GetCastbarFrameIfEnabled(unit)
                    if not castbar then return end
                    print("castbar found")
                    DevTool:AddData(castbar, "target castbar")
                    local cast = castbar._data or nil
                    if not cast then return end
                    print("cast found")
                    if not cast.isChanneled then return end

                    -- if cast.isComplete then return end
                    -- ClassicCastbars_NonClassic.lua @ 386 sets this to true after every tick of a channel for some reason.

                    if pushbackImmuneChannels[cast.spellName] then return end
                    print("pushback detected")
                    -- channels are reduced by 25% per hit
                    cast.maxValue = cast.maxValue - (0.25 * cast.maxValue)
                    cast.endTime = cast.endTime - (0.25 * cast.endTime)

                    self:DisplayCastbar(castbar, unit)
                end
            end
        end
    )
    ClassicCastbars:RegisterEvent("PLAYER_REGEN_ENABLED")
    function ClassicCastbars:PLAYER_REGEN_ENABLED()
        if currentChannels then
            wipe(currentChannels)
        end
    end

    ClassicCastbars.isChannelFixHooked = true
    aura_env.init = ClassicCastbars.isChannelFixHooked
    WeakAuras.prettyPrint("ClassicCastbars Channeled Spells Fix: Loaded.")
end

---Notes:
-- 1. The UNIT_SPELLCAST_CHANNEL_START event does not contain the castGUID payload when the the player is the target of the channel. it contains `UnitToken, nil, spellID`.
-- 2. Each channel has an associated `SPELL_CAST_SUCCESS` event, the issue is that the `spellID` payload is usually the same as the `spellID` payload from the `UNIT_SPELLCAST_CHANNEL_START` event. The SpellName might also not be the same, but theres no way to check for sure without crawling the dbc tables and youd have to build a hardcoded list to match them up. 