aura_env.enemyTargetTable = {}
aura_env.isSameUnit = function(unit1, unit2)
    if unit1 == unit2 then
        return true
    else
        return UnitGUID(unit1) == UnitGUID(unit2)
    end
end
-- Events: UNIT_THREAT_LIST_UPDATE, CLEU:UNIT_DIED
aura_env.onEvent = function(allstates, event, ...)
    if event == "UNIT_THREAT_LIST_UPDATE" then
        local unitId = ... or "none"
        for N = 1, 5 do
            local partyUnit = "party" .. N
            if N == 5 then partyUnit = "player" end
            if UnitIsEnemy(partyUnit, unitId) then
                local enemyTargetUnit = unitId .. "target"
                if aura_env.isSameUnit(enemyTargetUnit, partyUnit) then
                    local enemyGUID = UnitGUID(unitId)
                    if enemyGUID then
                        aura_env.enemyTargetTable[enemyGUID] = partyUnit
                    end
                end
                local targetedByCount = 0
                for _, targetUnit in pairs(aura_env.enemyTargetTable)
                do
                    if aura_env.isSameUnit(targetUnit, partyUnit) then
                        targetedByCount = targetedByCount + 1
                    end
                end
                if targetedByCount ~= 0 then
                    allstates[partyUnit] = {
                        show = true,
                        changed = true,
                        unit = partyUnit,
                        count = targetedByCount,
                        stacks = targetedByCount,
                    }
                else
                    if allstates[partyUnit] then
                    allstates[partyUnit].show = false
                    allstates[partyUnit].changed = true
                    end
                end
            end
        end
        return true
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED"
        and select(2, ...) == "UNIT_DIED" then
        local unitGUID = select(8, ...)
        aura_env.enemyTargetTable[unitGUID] = nil
    end
end

aura_env.anchorFunction = function()
    if aura_env.state.unit then
        return WeakAuras.GetUnitFrame(aura_env.state.unit)
    end
end
