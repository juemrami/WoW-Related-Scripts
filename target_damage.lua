aura_env.combatHistoryByGUID = {}
aura_env.getUnitCritChance = function(guid)
    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
        local unit = plate.namePlateUnitToken
        if unit and UnitGUID(unit) == guid then
            local mobLevel = UnitLevel(unit)
            local mobWeaponSkill = mobLevel * 5
            local playerDefense = UnitDefense("player")
            -- base crit is 5%
            -- each point that the mob's weapon skill exceeds your defense, is +0.04% crit, and -0.04% for each point below.
            local critModifier = (mobWeaponSkill - playerDefense) * 0.04
            local critChance = 5 + critModifier
            print(mobWeaponSkill, playerDefense, critModifier, critChance)
            

        end
    end
end
aura_env.onEvent = function(allstates, event, ...)
    local subEvent = select(2, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local destGUID = select(8, ...)
        if subEvent == "SWING_DAMAGE" then
            local sourceGUID = select(4, ...)
            local amount, _, _, _, _, _, isCrit = select(12, ...)
            if isCrit then 
                amount = amount/2 -- normalize crits
            end
            if not aura_env.combatHistoryByGUID[sourceGUID] then
                aura_env.combatHistoryByGUID[sourceGUID] = {
                    hits = 1,
                    min = amount,
                    average = amount,
                    max = amount,
                    critChance = aura_env.getUnitCritChance(sourceGUID),
                }
            else
                local state = aura_env.combatHistoryByGUID[sourceGUID]
                state.hits = state.hits + 1
                state.min = math.min(state.min, amount)
                state.max = math.max(state.max, amount)
                state.average = (state.average * (state.hits - 1) + amount) / state.hits
                state.critChance = aura_env.getUnitCritChance(sourceGUID)
            end
            local targetGUID = UnitGUID("target")
            if targetGUID == sourceGUID then
                allstates[""] = aura_env.combatHistoryByGUID[sourceGUID]
                allstates[""].changed = true
                allstates[""].show = true
            end
        elseif subEvent == "UNIT_DIED" then
            print(destGUID)
            aura_env.combatHistoryByGUID[destGUID] = nil
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        local targetGUID = UnitGUID("target")
        if targetGUID then
            allstates[""] = aura_env.combatHistoryByGUID[targetGUID] or {}
            allstates[""].changed = true
            allstates[""].show = true
        else
            allstates[""] = { show = false, changed = true }
        end
    end
    return true
end
