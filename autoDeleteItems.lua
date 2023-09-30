aura_env.autoDeleteItems = {
    20742 -- Winterfall Ritual Totem
}

-- Events: BAG_UPDATE_DELAYED 
aura_env.onEvent = function (states, event, ...)
    if event == "BAG_UPDATE_DELAYED" then
        for _, itemID in pairs(aura_env.autoDeleteItems) do
            local bag, slot, itemName = aura_env.searchBagForItem(itemID)
            if bag and slot then
                C_Container.PickupContainerItem(bag, slot)
                StaticPopup_Show("DELETE_ITEM", itemName)
            end
        end
    end
end

aura_env.searchBagForItem = function (itemID)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info
                and info.itemID == itemID
                and not info.isLocked
            then
                return bag,slot, info.itemName
            else
            end
        end
    end
end