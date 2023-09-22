aura_env.BUFFER = .250 -- ms buffer for extra swing windows
-- Events: CLEU:SPELL_EXTRA_ATTACKS:SPELL_CAST_SUCCESS:SWING_DAMAGE
aura_env.onEvent = function(allstates, event, ...)
    local timestamp, subEvent = ...
    local sourceGUID = select(4, ...)
    if subEvent == "SPELL_EXTRA_ATTACKS" then
        local sourceUnit = aura_env.getNamePlateToken(sourceGUID)
        local spellName = select(13, ...)
        if spellName == "Thrash" then
            print(subEvent, timestamp)
            if sourceUnit and UnitIsEnemy("player", sourceUnit) then
                local count = select(15, ...)
                allstates[sourceUnit] = {
                    show = true,
                    changed = true,
                    unit = sourceUnit,
                    count = count,
                    icon = 132152,
                }
            end
        end
    elseif subEvent == "SWING_DAMAGE"
    then
        local sourceUnit = aura_env.getNamePlateToken(sourceGUID)
        if UnitIsEnemy("player", sourceUnit) then
            print(subEvent, timestamp)
            local inBuffer = aura_env.lastSwing
            and (timestamp - aura_env.lastSwing) < aura_env.BUFFER
            print(timestamp - (aura_env.lastSwing or 0))
            if inBuffer then return end
            aura_env.lastSwing = timestamp
            if sourceUnit and allstates[sourceUnit] then
                allstates[sourceUnit] = {
                    show = false,
                    changed = true,
                }
            end
        end
    end
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
