-- events: PLAYER_EQUIPMENT_CHANGED ITEM_DATA_LOAD_RESULT
aura_env.onEvent = function(states, event, ...)
    if event == "ITEM_DATA_LOAD_RESULT" 
        and not (aura_env.tracked and aura_env.tracked[...]) 
    then 
        return 
    end
    local mainHand = GetInventoryItemID("player", INVSLOT_MAINHAND)
    local offHand = GetInventoryItemID("player", INVSLOT_OFFHAND)
    for _, state in pairs(states) do
        state.show = false
        state.changed = true
    end
    for i, slot in ipairs({INVSLOT_MAINHAND, INVSLOT_OFFHAND}) do
        local weaponId = GetInventoryItemID("player", slot)
        if weaponId then
            aura_env.tracked = aura_env.tracked or {}
            aura_env.tracked[weaponId] = true
            local name, link, quality, _, _, _, _, _, _, texture = GetItemInfo(weaponId)
            states[slot] = {
                index = i,
                show = true,
                changed = true,
                name = name,
                icon = texture,
                link = link,
                quality = quality
            }
        end
    end
    return true
end