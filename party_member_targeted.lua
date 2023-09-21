aura_env.enemiesOnThreatTable = {}
-- Events: UNIT_THREAT_LIST_UPDATE, CLEU:UNIT_DIED, UNIT_THREAT_SITUATION_UPDATE
aura_env.onEvent = function(states, event, ...)
    if event == "UNIT_THREAT_LIST_UPDATE" then
        local enemyUnit = ...
        local enemyGUID = UnitGUID(enemyUnit)
        if enemyGUID then
            aura_env.enemiesOnThreatTable[enemyGUID] = true
        end
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        local friendlyUnit = ...
        aura_env.updateStateForUnit(states, friendlyUnit)
        return true
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED"
        and select(2, ...) == "UNIT_DIED" then
        local unitGUID = select(8, ...)
        aura_env.enemiesOnThreatTable[unitGUID] = nil
    end
end
aura_env.updateStateForUnit = function(states, unit)
    -- Verify unit is in party or raid
    local unitType = aura_env.config.petsEnabled 
        and "UnitPlayerOrPet" or "Unit"
    if not _G[unitType.."InParty"] then return end
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
    for enemyGUID, _ in pairs(aura_env.enemiesOnThreatTable)
    do
        local enemy = UnitTokenFromGUID(enemyGUID)
        if enemy then
            local enemyTarget = enemy .. "target"
            if UnitIsEnemy(enemy, enemyTarget)
                and UnitIsUnit(enemyTarget, unit) then
                count = count + 1
            end
        end
    end
    return count
end
