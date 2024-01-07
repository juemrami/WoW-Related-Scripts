if not aura_env.saved then
    aura_env.saved = {
        ---The value is not really needed. Meant to just be "Set" of spellIds for npcs.
        ---@type {[npcId]: {[spellId]: lastCastAt}}
        spellHistoryByNpc = {}
    }
end
---@type {[unitGUID]: {[spellId]: lastCastAt}}
aura_env.recentSpellsByGUID = {}
---Returns either cooldown or global cooldown for a given spellId. `nil` if spell has neither (ie 0s).
---@param spellId number
---@return number?
aura_env.getSpellCooldown = function(spellId)
    local durationMS, gcdMS = GetSpellBaseCooldown(spellId)
    local duration = durationMS / 1000
    local gcd = gcdMS / 1000
    return duration > 0 and duration
        or (gcd > 0 and gcd)
        or nil
end

---@param sourceFlags number Bit-field of source flags
aura_env.isSourceValid = function(sourceFlags)
    local attackableNpc = bit.bor(
    -- affiliation
        COMBATLOG_OBJECT_AFFILIATION_MASK, -- any
        COMBATLOG_OBJECT_REACTION_HOSTILE,
        -- reaction
        COMBATLOG_OBJECT_REACTION_NEUTRAL,
        -- controller
        COMBATLOG_OBJECT_CONTROL_NPC, -- for npc pets
        -- type
        COMBATLOG_OBJECT_TYPE_NPC
    )
    local valid = CombatLog_Object_IsA(
        sourceFlags,
        attackableNpc
    )
    -- aura_env.debug(("isSourceValid: 0x%08X, %s")
    --     :format(sourceFlags, valid and "true" or "false")
    -- )
    return valid
end

---Returns the name plate unit token for a given guid.
---@param guid string # Enemy unit GUID.
---@return string? # Associated nameplate unit token.
aura_env.getNameplateTokenFromGUID = function(guid)
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            if UnitGUID(unit) == guid then
                return unit
            end
        end
    end
end

---Creates 1 or more state(s) for a unit. One for each spellId in the spellHistory or in the saved data. Meant to be used in a dynamic group where auras are grouped by unit. Each cloned group will anchor to the unit nameplate.
---@param states table<string, WA.State>
---@param unit UnitToken # Nameplate unit token
---@return boolean # `true` if states were changed
aura_env.setStatesForUnit = function(states, unit)
    local guid = UnitGUID(unit)
    local isUpdate = false
    --Used when cooldown is 0 to give a ui indication that the spell was cast.
    local defaultSwipeDuration = 1.5
    if guid then
        aura_env.debug("setting state for unit: ", unit)
        --Recent spells casts by this *specific* unit
        local recentSpells = aura_env.recentSpellsByGUID[guid] or {}
        --Spells casts by this type of unit (npc id), if enabled.
        local savedSpells = (function()
            local spells = {}
            if aura_env.config.showAll then
                local npcId = select(6, strsplit("-", guid))
                npcId = tonumber(npcId)
                if npcId then
                    spells = aura_env.saved.spellHistoryByNpc[npcId]
                end
            end
            return spells
        end)()
        --All spells to show icons for
        local trackedSpells = {} --[[@as table<spellId, number>]]
        for _, spellTable in ipairs({ recentSpells, savedSpells }) do
            -- only take cast information from recent spells
            -- since saved spells is for all npcs not just the current one.
            for id, _ in pairs(spellTable) do
                trackedSpells[id] = recentSpells[id] or 0
            end
        end
        for id, lastCast in pairs(trackedSpells) do
            local key = guid .. "_" .. id
            local duration = aura_env.getSpellCooldown(id)
                -- Ranged Shoot
                or (GetSpellInfo(id) == GetSpellInfo(8646)
                    and UnitRangedDamage(unit))
                or defaultSwipeDuration

            aura_env.debug(
                ("%s. %is cd. cast %.02fs ago"):format(GetSpellInfo(id), duration, GetTime() - lastCast)
            )
            ---@class WA.State
            states[key] = {
                show = true,
                changed = true,
                duration = duration,
                expirationTime = lastCast + duration,
                progressType = "timed",
                autoHide = false,
                icon = GetSpellTexture(id),
                unit = unit,
                spellId = id,
                guid = guid,
            }
            isUpdate = true
        end
        if isUpdate then
            aura_env.debug("states updated for unit: ", unit)
        end
    else
        isUpdate = aura_env.cleanUpStates(states, unit)
    end
    return isUpdate
end

---Clean up states for any unit that no longer exists or is dead or has no tracked spells.
---@param states table<string, WA.State>
---@param unit? string # A specific unit to check, if nil all units will be checked.
---@return boolean # `true` if states were changed
aura_env.cleanUpStates = function(states, unit)
    local isUpdate = false
    if unit then
        for key, state in pairs(states) do
            if state.unit == unit then
                states[key] = {
                    show = false,
                    changed = true,
                }
                isUpdate = true
            end
        end
    else
        for key, state in pairs(states) do
            if state.unit
                and UnitGUID(state.unit) ~= state.guid
                or not UnitExists(state.unit)
                or UnitIsDead(state.unit)
                or not aura_env.recentSpellsByGUID[state.guid]
            then
                states[key] = {
                    show = false,
                    changed = true,
                }
                isUpdate = true
            end
        end
    end
    return isUpdate
end

---Creates demo states for testing and when WA Options is shown.
---@param states table<string, WA.State>
---@return boolean
aura_env.createDemoStates = function(states)
    local currentTime = GetTime()
    local unit = "nameplate1"
    local spells = {
        8124,  -- Psychic Scream
        7744,  -- Will of the Forsaken
        12328, -- Death Wish
    }
    for _, id in ipairs(spells) do
        local key = unit .. id
        local duration = aura_env.getSpellCooldown(id)
        if not states[key]
            or states[key].expirationTime <= currentTime
        then
            states[key] = {
                show = true,
                changed = true,
                duration = duration,
                expirationTime = currentTime + (duration / random(2, 4)),
                progressType = "timed",
                autoHide = true,
                icon = GetSpellTexture(id),
                unit = unit,
                spellId = id,
                guid = UnitGUID(unit),
            }
        end
    end
    return true
end

---Trigger on events: CLEU:SPELL_CAST_SUCCESS:UNIT_DIED, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED
---@param states table<any, WA.State>
---@param event Events
---@param ... any
aura_env.onEvent = function(states, event, ...)
    -- on subevent's SPELL_CAST_SUCCESS, UNIT_DIED only
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local subEvent = select(2, ...)
        if subEvent == "SPELL_CAST_SUCCESS" then
            local sourceFlags = select(6, ...)
            if aura_env.isSourceValid(sourceFlags) then
                local spellName = select(13, ...)
                local spellId = select(12, ...)
                local sourceGUID = select(4, ...)
                local currentTime = GetTime()
                -- check for first seen
                aura_env.recentSpellsByGUID[sourceGUID] =
                    aura_env.recentSpellsByGUID[sourceGUID]
                    or {}
                aura_env.recentSpellsByGUID[sourceGUID][spellId] = currentTime

                local npcId = select(6, strsplit("-", sourceGUID))
                npcId = tonumber(npcId)
                aura_env.debug(
                    ("Enemy Spell Seen: %s cast %s. npcId: %s, spellId: %s")
                    :format(
                        select(5, ...), -- sourceName
                        GetSpellLink(spellId) or spellName,
                        npcId,
                        spellId
                    )
                )
                if npcId then -- should always be defined if flags are valid.
                    local savedSpells = aura_env.saved.spellHistoryByNpc[npcId]
                    if not savedSpells then
                        savedSpells = {}
                        aura_env.saved.spellHistoryByNpc[npcId] = savedSpells
                    end
                    savedSpells[spellId] = currentTime
                    -- add any spells seen but not saved for some reason.
                    for id, castTime in
                    pairs(aura_env.recentSpellsByGUID[sourceGUID])
                    do
                        if not savedSpells[id] then
                            savedSpells[id] = castTime
                        end
                    end
                end

                local sourceUnit = aura_env.getNameplateTokenFromGUID(sourceGUID)
                if sourceUnit then
                    return aura_env.setStatesForUnit(states, sourceUnit)
                end
            end
        elseif subEvent == "UNIT_DIED" then
            local destGUID = select(8, ...)
            aura_env.recentSpellsByGUID[destGUID] = nil
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        return aura_env.setStatesForUnit(states, ...)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        return aura_env.cleanUpStates(states, ...)
    elseif event == "OPTIONS" then
        return aura_env.createDemoStates(states)
    end
end

---@alias Events
---| "COMBAT_LOG_EVENT_UNFILTERED"
---| "NAME_PLATE_UNIT_ADDED"
---| "NAME_PLATE_UNIT_REMOVED"

---@alias spellId number
---@alias npcId number
---@alias lastCastAt number
---@alias AllStates table<string|number, WA.State>
aura_env.debug = function(...)
    if aura_env.config.debug then
        WeakAuras.prettyPrint(aura_env.id .. ": ", ...)
    end
end

--- Do not Include in "On Init" Below ---
---@type WA.CustomConditions
local conditions = {
    expirationTime = true,
    duration = true,
    value = true,
    total = true,
    onCooldown = {
        display = "On Cooldown",
        type = "bool",
        test = function (state, needle)
            return
        end
    }

}