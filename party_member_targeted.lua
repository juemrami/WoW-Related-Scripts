aura_env.enemyTargetTable = {}
-- Events: UNIT_THREAT_LIST_UPDATE, CLEU:UNIT_DIED, UNIT_THREAT_SITUATION_UPDATE
aura_env.onEvent = function(states, event, ...)
    if event == "UNIT_THREAT_LIST_UPDATE" then
        local enemyUnit = ... or "none"
        local groupSize = GetNumGroupMembers()
        for N = 1, groupSize do
            local partyUnit = "party" .. N
            if N == groupSize then partyUnit = "player" end
            if UnitIsEnemy(partyUnit, enemyUnit) then
                local enemyTarget = enemyUnit .. "target"
                if UnitIsUnit(enemyTarget, partyUnit) then
                    local enemyGUID = UnitGUID(enemyUnit)
                    if enemyGUID then
                        aura_env.enemyTargetTable[enemyGUID] = partyUnit
                    end
                end
                aura_env.setStateForUnit(states, partyUnit)
            end
        end
        return true
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        local friendlyUnit = ...
        local status = UnitThreatSituation(friendlyUnit)
        if (not status or status < 1) and states[friendlyUnit] then
            states[friendlyUnit] = {
                show = false,
                changed = true,
            }
        else
            aura_env.setStateForUnit(states, friendlyUnit)
        end
        return true
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED"
        and select(2, ...) == "UNIT_DIED" then
        local unitGUID = select(8, ...)
        aura_env.enemyTargetTable[unitGUID] = nil
    end
end
aura_env.setStateForUnit= function(states, unit)
    local count = aura_env.getTargetedByCount(unit)
    local changed = not states[unit]
        or states[unit].count ~= count
    if count ~= 0
    then
        states[unit] = {
            show = true,
            changed = changed,
            unit = unit,
            count = count,
            stacks = count,
        }
    else
        if states[unit] then
            states[unit].show = false
            states[unit].changed = true
        end
    end
end
aura_env.getTargetedByCount = function(unit)
    local count = 0
    for _enemy, target in pairs(aura_env.enemyTargetTable)
    do
        if UnitIsUnit(target, unit) then
            count = count + 1
        end
    end
    return count
end

