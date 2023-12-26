aura_env.baseSpellIds = {
    -- General kicks
    72, -- Shield Bash 
    1766, -- Kick
    2139, -- Counterspell
    6552, -- Pummel
    8042, -- Earth Shock
    412787, -- Disrupt
    414621, -- Skull Bash
    425609, -- Rebuke
    19244, -- Spell Lock
    -- NPC specific kicks
    10887, -- Crowd Pummel
    19129, -- Massive Tremor
    21832, -- Boulder
}
---Table containing localized spell names. Maps name to base spell id.
---This should account for multiple ranks of the same spell.
---@type table<spellName, spellID>
aura_env.trackedSpells = {}
for _, spellId in ipairs(aura_env.baseSpellIds) do
    -- localize 
    local spellName = GetSpellInfo(spellId)
    if spellName then
        aura_env.trackedSpells[spellName] = spellId
    end
end
---@type table<unitGUID, table<spellID, timestamp>>
aura_env.recentKicks = {}
--Events: CLEU:SPELL_CAST_SUCCESS, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED
aura_env.onEvent = function(states, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local spellName = select(13, ...)
    local sourceFlags = select(6, ...)
    if aura_env.trackedSpells[spellName] and aura_env.isSourceValid(sourceFlags) then
        -- print("Kick detected: ", spellName)
        -- print("Source is valid")
        local sourceGUID = select(4, ...)
        local spellId = select(12, ...) or aura_env.trackedSpells[spellName]
        local recentKicks = aura_env.recentKicks[sourceGUID] or {}
        recentKicks[spellId] = GetTime()
        aura_env.recentKicks[sourceGUID] = recentKicks
        
        if aura_env.config.debug then
            local sourceName = select(5, ...)
            local destName = select(9, ...)
            local spellLink = GetSpellLink(spellId)
            local str = "Kick detected: %s used %s on %s. %ds cooldown."
            local cooldown = GetSpellBaseCooldown(spellId)/1000
            print(str:format(sourceName, spellLink, destName, cooldown))
        end
        -- set up state
        local sourceUnit = aura_env.getUnitTokenFromGUID(sourceGUID)
        if sourceUnit then 
            return aura_env.setStateForUnit(states,sourceUnit)
        end
       end
    else -- NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED
        local unit = ...
        return aura_env.setStateForUnit(states, unit)
    end
end
---Set the state for the unit given a unitToken or guid.
---@param states table
---@param unit unitToken?
---@param guid unitGUID?
---@return boolean changed if state was changed
aura_env.setStateForUnit = function(states, unit, guid)
    if not (unit or guid) then return false end
    local guid = guid or UnitGUID(unit --[[@as string]])
    ---@cast guid string
    local changed = false
    local recentKicks = aura_env.recentKicks[guid]
    for spellID, castTime in pairs(recentKicks or {}) do
        local icon = GetSpellTexture(spellID)
        local cooldown = (function ()
            local baseCD = GetSpellBaseCooldown(spellID)/1000
            return baseCD > 0 and baseCD or 1
        end)()
        local key = guid .. spellID
        states[key] = {
            show = true,
            changed = true,
            icon = icon,
            progressType = "timed",
            autoHide = true,
            duration = cooldown,
            expirationTime = castTime + cooldown,
            unit = unit,
        }
        changed = true
        -- for now return 1 tracked spell per unit
        -- most units only have 1 kick anyways.
        -- except prot warriors
        return changed
    end
end
aura_env.isSourceValid = function(sourceFlags)
    -- include: Hostile, Neutral
    -- Player Controlled if onlyTrackPlayers is true
    local filter = bit.bor(
        COMBATLOG_OBJECT_AFFILIATION_MASK,
        COMBATLOG_OBJECT_REACTION_HOSTILE,
        COMBATLOG_OBJECT_REACTION_NEUTRAL,
        aura_env.config.onlyTrackPlayers and COMBATLOG_OBJECT_CONTROL_PLAYER or COMBATLOG_OBJECT_CONTROL_MASK,
        COMBATLOG_OBJECT_TYPE_MASK
    ) 
    local valid = CombatLog_Object_IsA(
        sourceFlags,
        filter
    )
    if aura_env.config.debug then
        print("isHostile", FlagsUtil.IsSet(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE))
        print("isValidUnit", valid)
    end
    return valid
end
aura_env.getUnitTokenFromGUID = function(guid)
    if not guid then return nil end
    -- if guid == UnitGUID("target") then
    --     return "target"
    -- end
    -- if guid == UnitGUID("mouseover") then
    --     return "mouseover"
    -- end
    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
        ---@type string?
        local unit = plate.namePlateUnitToken
        if unit and UnitGUID(unit) == guid then
            return unit
        end
    end
end
---@alias spellName string
---@alias spellID number
---@alias unitGUID string
---@alias timestamp number
---@alias unitToken string