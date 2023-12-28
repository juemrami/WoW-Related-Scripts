if not aura_env.saved then
    aura_env.saved = {
        ---@type {[npcId]: spellId[]}
        npcSpells = {}
    }
end

---unitGUID -> spellId -> expirationTime
---@type {[unitGUID]: {[spellId]: number}}
aura_env.spellHistory = { }

---@param spellId number
aura_env.getSpellCooldown = function(spellId)
    local durationMS, gcdMS = GetSpellBaseCooldown(spellId)
    local duration = durationMS / 1000
    return durationMS > 0
        and (durationMS / 1000)
        or (gcdMS / 1000)
        or 1.5 -- any base. For showing the icon after a cast.
end
---@param sourceFlags number Bit-field of source flags
aura_env.isSourceValid = function(sourceFlags)
    -- include: Hostile, Neutral
    -- Player Controlled if onlyTrackPlayers is true
    local attackableNpc = bit.bor(
        COMBATLOG_OBJECT_AFFILIATION_MASK,
        COMBATLOG_OBJECT_REACTION_HOSTILE,
        COMBATLOG_OBJECT_REACTION_NEUTRAL,
        COMBATLOG_OBJECT_CONTROL_NPC,
        COMBATLOG_OBJECT_TYPE_NPC
    )
    local valid = CombatLog_Object_IsA(
        sourceFlags,
        attackableNpc
    )
    return valid
end

---Creates 1 or many states for a unit. 1 for each spellId in the spellHistory or in the saved data. Meant to be used in a dynamic group where auras are grouped by unit. Each cloned group will anchor to the unit nameplate.
---@param states table<any, WA.State>
---@param unit UnitToken # Nameplate unit token
aura_env.setStateForUnit = function(states, unit)
    local guid = UnitGUID(unit)
    if guid and aura_env.spellHistory[guid] then
        if aura_env.config.showAll then
            local npcId = select(6, strsplit("-", guid))
            npcId = tonumber(npcId)
            if npcId then
                for _, id in
                ipairs(npcId and aura_env.saved.npcSpells[npcId] or {})
                do
                    local key = guid .. id
                    local duration = aura_env.getSpellCooldown(id)
                    local castTime = aura_env.spellHistory[guid]
                        and aura_env.spellHistory[guid][id] or 0
                    states[key] = {
                        show = true,
                        changed = true,
                        duration = duration,
                        expirationTime = castTime + duration,
                        progressType = "timed",
                        autoHide = false,
                        icon = GetSpellTexture(id),
                        unit = unit,
                        spellId = id,
                        guid = guid,
                    }
                end
            else
                for id, castTime in pairs(aura_env.spellHistory[guid]) do
                    local key = guid .. id
                    local duration = aura_env.getSpellCooldown(id)
                    states[key] = {
                        show = true,
                        changed = true,
                        duration = duration,
                        expirationTime = castTime + duration,
                        progressType = "timed",
                        autoHide = false,
                        icon = GetSpellTexture(id),
                        unit = unit,
                        spellId = id,
                        guid = guid,
                    }
                end
            end
        end
    end
end

---Clean up states for any unit that no longer exists or is dead.
---@param states table<any, WA.State>
aura_env.cleanUpStates = function(states)
    for key, state in pairs(states) do
        if state.unit
            and (not UnitExists(state.unit)
            or UnitIsDead(state.unit))
        then
            states[key] = {
                show = false,
                changed = true,
            }
        end
    end
end

---@param states table<any, WA.State>
---@param event Events
---@param ... any
local onEvent = function(states, event, ...)
    -- on subevent's SPELL_CAST_SUCCESS, UNIT_DIED only
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local subEvent = select(2, ...)
        if subEvent == "SPELL_CAST_SUCCESS" then
            local sourceFlags = select(6, ...)
            if aura_env.isSourceValid(sourceFlags) then
                local spellName = select(13, ...)
                local spellId = select(12, ...)
                local sourceGUID = select(4, ...)
                local npcId = select(6, strsplit("-", sourceGUID))
                local current
                npcId = tonumber(npcId)
                if npcId then -- should always be defined if flags are valid.
                    local npcSpells = aura_env.saved.npcSpells[npcId]
                    if not npcSpells then
                        npcSpells = {}
                        aura_env.saved.npcSpells[npcId] = npcSpells
                    end
                    tinsert(npcSpells, spellId)
                end

                local sourceUnit = aura_env.getUnitTokenFromGUID(sourceGUID)
                if sourceUnit then
                    aura_env.setStateForUnit(states, sourceUnit)
                    return true
                end
            end
        elseif subEvent == "UNIT_DIED" then
            local destGUID = select(8, ...)
            aura_env.spellHistory[destGUID] = nil
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        aura_env.setStateForUnit(states, ...)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        aura_env.cleanUpStates(states)
    end
end
---@alias Events
---| "COMBAT_LOG_EVENT_UNFILTERED"
---| "NAME_PLATE_UNIT_ADDED"
---| "NAME_PLATE_UNIT_REMOVED"

---@alias spellId number
---@alias npcId number
--Events: CLEU:SPELL_CAST_SUCCESS:UNIT_DIED, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED attackable
