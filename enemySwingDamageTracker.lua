if not aura_env.saved then
    aura_env.saved = {
        npcDamageHistory = {
            --[npcId] = {[level] = {min, max, average, hits}}
        }
    }
end
-- PLAYER_TARGET_CHANGED, CLEU:SWING_DAMAGE
aura_env.onEvent = function(states, event, ...)
    if not aura_env.saved then return end
    local subEvent = select(2, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local sourceGUID = select(4, ...)
        if subEvent == "SWING_DAMAGE" then
            local unit = aura_env.getUnitTokenFromGUID(sourceGUID)
            if unit
                and not UnitIsFriend("player", unit) and not UnitIsPlayer(unit) then
                local npcId = select(6, strsplit("-", sourceGUID))
                npcId = tonumber(npcId)
                if npcId then
                    local level = UnitLevel(unit)
                    local amount, _, _, _, _, _, isCrit = select(12, ...)
                    print(amount, isCrit)
                    if isCrit then
                        amount = amount / 2 -- normalize crits
                    end
                    if not aura_env.saved.npcDamageHistory[npcId] then
                        aura_env.saved.npcDamageHistory[npcId] = {}
                    end
                    if not aura_env.saved.npcDamageHistory[npcId][level] then
                        aura_env.saved.npcDamageHistory[npcId][level] = {
                            min = amount,
                            max = amount,
                            average = amount,
                            hits = 1,
                            critChance = aura_env.getUnitCritChance(unit)
                        }
                    else
                        local npcData = aura_env
                            .saved.npcDamageHistory[npcId][level]
                        npcData.hits = npcData.hits + 1
                        npcData.min = math.min(npcData.min, amount)
                        npcData.max = math.max(npcData.max, amount)
                        npcData.average = (
                            npcData.average * (npcData.hits - 1) + amount
                        ) / npcData.hits
                        npcData.critChance = aura_env.getUnitCritChance(unit)
                    end
                end
            end
        end
    end
    if UnitExists("target")  then
        local targetGUID = UnitGUID("target")
        local level = UnitLevel("target")
        local npcId = select(6, strsplit("-", targetGUID)) or 0
        npcId = tonumber(npcId)
        if npcId then
            if not aura_env.saved.npcDamageHistory[npcId] then
                aura_env.saved.npcDamageHistory[npcId] = {}
            end
            local data = aura_env.saved.npcDamageHistory[npcId][level]
            if not data then
                data = {
                    min = 0,
                    max = 0,
                    average = 0,
                    critChance = aura_env.getUnitCritChance("target")
                }
            end
            states[""] = {
                show = true,
                changed = true,
                min = data.min,
                max = data.max,
                average = data.average,
                critChance = data.critChance,
                attackSpeed = UnitAttackSpeed("target"),
            }
        end
        return true
    end
end
aura_env.getUnitCritChance = function(unit)
    if not unit then return 0 end
    local mobLevel = UnitLevel(unit)
    local mobWeaponSkill = mobLevel * 5
    local playerDefense = UnitDefense("player")
    -- base crit is 5%
    -- each point that the mob's weapon skill exceeds your defense, is +0.04% crit, and -0.04% for each point below.
    local critModifier = (mobWeaponSkill - playerDefense) * 0.04
    local critChance = 5 + critModifier
    -- print(mobWeaponSkill, playerDefense, critModifier, critChance)
    return max(critChance, 0)
end
aura_env.getUnitTokenFromGUID = function(guid)
    if not guid then return nil end
    if guid == UnitGUID("target") then
        return "target"
    end
    if guid == UnitGUID("mouseover") then
        return "mouseover"
    end
    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
        local unit = plate.namePlateUnitToken
        if unit and UnitGUID(unit) == guid then
            return unit
        end
    end
    for friendlyUnit in WA_IterateGroupMembers() do
        local unitTarget = friendlyUnit .. "target"
        if UnitExists(unitTarget) and UnitGUID(unitTarget) == guid then
            return unitTarget
        end
    end
end
