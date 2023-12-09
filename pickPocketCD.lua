aura_env.PICKPOCKET = GetSpellInfo(921)
aura_env.pocketRefreshDuration = 6 * 60 -- 5-6 minutes
--- From testing, there is at most a 150ms delay between the CLEU event
--- and the UNIT_FLAG event that seems to fire when mob is pickpocketed and looted.
--- the UNIT_FLAG event wont fire if the mobs pockets are empty
aura_env.MS_BUFFER_150 = 150 / 1000

aura_env.savedMobGUIDs = {}
---@param event string CLEU:SPELL_CAST_SUCCESS, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED
aura_env.onEvent = function(states, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED"
        and select(2, ...) == "SPELL_CAST_SUCCESS"
    then
        local spellName = select(13, ...)
        if spellName == aura_env.PICKPOCKET then
            local destGUID = select(8, ...)
            local castTime = GetTime()
            aura_env.savedMobGUIDs[destGUID] = castTime
            states[destGUID] = {
                show = true,
                changed = true,
                unit = aura_env.UnitTokenFromGUID(destGUID),
                progressType = "timed",
                duration = aura_env.pocketRefreshDuration,
                expirationTime = castTime + aura_env.pocketRefreshDuration,
                icon = select(3, GetSpellInfo(921)),
            }
            return true
        end
    elseif strfind(event,"NAME_PLATE") then
        aura_env.updateNameplateMatches(states)
        return true
    end
end
aura_env.updateNameplateMatches = function(states)
    for _, state in pairs(states) do
        state.show = false
        state.changed = true
    end
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local guid = UnitGUID(unit)
        if guid and aura_env.savedMobGUIDs[guid] then
            --print("found existing unit for " .. guid)
            local castTime = aura_env.savedMobGUIDs[guid]
            states[guid] = {
                show = true,
                changed = true,
                unit = unit,
                progressType = "timed",
                duration = aura_env.pocketRefreshDuration,
                expirationTime = castTime + aura_env.pocketRefreshDuration,
                icon = select(3, GetSpellInfo(921)),
            }
        end
    end
end
aura_env.UnitTokenFromGUID = UnitTokenFromGUID or function(guid)
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if guid == UnitGUID(unit) then
            return unit
        end
    end
end
