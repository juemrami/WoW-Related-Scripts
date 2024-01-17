---@type table<unitGUID, boolean>
aura_env.enemiesInCombat = {}
-- Events: UNIT_THREAT_LIST_UPDATE, CLEU:UNIT_DIED, UNIT_THREAT_SITUATION_UPDATE
aura_env.onEvent = function(states, event, ...)
    if event == "UNIT_THREAT_LIST_UPDATE" then
        local enemyUnit = ...
        local enemyGUID = UnitGUID(enemyUnit)
        if enemyGUID then
            aura_env.enemiesInCombat[enemyGUID] = true
        end
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        -- either update the state for only the unit that changed
        -- or update the state for all units in the group
        -- 2nd one scale worse with group size but with 5 people the loop is short and worth the more accurate state imo
        -- local friendlyUnit = ...
        -- aura_env.updateStateForUnit(states, friendlyUnit)
        for unit in WA_IterateGroupMembers() do
            aura_env.updateStateForUnit(states, unit)
        end
        return true
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED"
        and select(2, ...) == "UNIT_DIED" then
        local unitGUID = select(8, ...)
        aura_env.enemiesInCombat[unitGUID] = nil
    end
end
aura_env.updateStateForUnit = function(states, unit)
    -- Verify unit is in party or raid
    local isValidUnit = aura_env.config.petsEnabled 
        and UnitPlayerOrPetInParty or UnitInParty
    if not isValidUnit() then return end

    local count = aura_env.getTargetedByCount(unit)
    local changed = not states[unit]
        or states[unit].count ~= count
    if count ~= 0 then
        states[unit] = {
            show = true,
            changed = changed,
            unit = unit,
            count = count,
            stacks = count,
        }
    elseif states[unit] then
        states[unit] = {
            show = false,
            changed = true
        }
    end
end
aura_env.getTargetedByCount = function(unit)
    local count = 0
    for enemyGUID, _ in pairs(aura_env.enemiesInCombat) do
        local enemyUnit = aura_env.UnitTokenFromGUID(enemyGUID)
        if enemyUnit then
            local enemyTarget = enemyUnit .. "target"
            if UnitIsEnemy(enemyUnit, enemyTarget)
            and UnitIsUnit(enemyTarget, unit) 
            then
                count = count + 1
            end
        end
    end
    return count
end
aura_env.UnitTokenFromGUID = function(unitGUID)
    local unitIsMatch = function(unit)
        return UnitGUID(unit) == unitGUID
    end
    -- check common units first
    for _, unit in ipairs({"target, mouseover, softenemy"}) do
        if unitIsMatch(unit) then return unit end
    end
    -- check nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if unitIsMatch(unit) then return unit end
    end
    -- lastly check group member's(and group pet's) *target*
    for _unit in WA_IterateGroupMembers() do
        local unit = _unit .. "target"
        if unitIsMatch(unit) then return unit end
    end

end