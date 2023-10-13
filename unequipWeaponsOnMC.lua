aura_env.onEvent = function(event, ...)
    local subEvent = select(2, ...)
    local spellName = select(13, ...)
    local sourceName = select(5, ...)
    local destGUID, destName = select(8, ...)
    print(destName)
    if subEvent == "SPELL_AURA_APPLIED"
        and spellName == "Possess"
        and destGUID == UnitGUID("player") then
        PickupInventoryItem(INVSLOT_MAINHAND)
        PutItemInBackpack()
    end
end
