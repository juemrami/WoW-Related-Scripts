aura_env.BUFFER = 250 -- ms buffer for extra swing windows
-- Events: CLEU:SPELL_EXTRA_ATTACKS:SPELL_CAST_SUCCESS:SWING_DAMAGE
aura_env.onEvent = function(allstates, event, ...)
    local timestamp, subEvent = ...
    local sourceGUID = select(4, ...)
    print(subEvent)
    if subEvent == "SPELL_EXTRA_ATTACKS" then
        local sourceUnit = aura_env.getNamePlateToken(sourceGUID)
        local spellName = select(13, ...)
        if spellName == "Thrash" then
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
        if sourceUnit and allstates[sourceUnit] then
            allstates[sourceUnit] = {
                show = false,
                changed = true,
            }
        end
    end
end
aura_env.getNamePlateToken = function(unitGUID)
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if unitGUID == UnitGUID(plate.namePlateUnitToken) then
            return plate.namePlateUnitToken
        end
    end
end
