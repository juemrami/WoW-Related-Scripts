-- Events: CLEU:SPELL_EXTRA_ATTACKS:SPELL_CAST_SUCCESS:SWING_DAMAGE:UNIT_DIED, PLAYER_ENTERING_WORLD
if not aura_env.saved then
    aura_env.saved = {
        thrashNPCs = {}
    }
end
aura_env.onEvent = function(states, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        print("Trash NPCs:")
        for npcID, _ in pairs(aura_env.saved.thrashNPCs) do
            print(npcID)
        end
        return
        print("--------")
    end
    local _, subEvent = ...
    local sourceGUID = subEvent == "UNIT_DIED"
        and select(8, ...) or select(4, ...)

    if subEvent == "SPELL_EXTRA_ATTACKS" then
        local spellName = select(13, ...)
        if spellName == "Thrash" then
            local sourceUnit = aura_env.getNamePlateToken(sourceGUID)
            if sourceUnit and UnitIsEnemy("player", sourceUnit) then
                local npcID = select(6, strsplit("-", sourceGUID))
                aura_env.saved.thrashNPCs[tostring(npcID)] = true
                local count = select(15, ...)
                print(subEvent, spellName, count, sourceGUID, sourceUnit)
                states[sourceGUID] = {
                    show = true,
                    changed = true,
                    unit = sourceUnit,
                    count = count,
                    extraAttacks = count,
                    icon = 132152,
                }
            end
        end
    elseif subEvent == "SWING_DAMAGE" or "UNIT_DIED" then
        if states[sourceGUID] then
            states[sourceGUID] = {
                show = false,
                changed = true,
            }
        end
    end
    return true
end
aura_env.getNamePlateToken = function(unitGUID)
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if unitGUID == UnitGUID(plate.namePlateUnitToken) then
            print(plate.namePlateUnitToken)
            return plate.namePlateUnitToken
        end
    end
    return "none"
end
