aura_env.allowed_items = {
    -- Clams
    [15874] = true, -- Soft-shelled Clam
    [5523]  = true, -- Small Barnacled Clam
    [5524]  = true, -- Thick-shelled Clam
    [7973]  = true, -- Big-mouth Clam
}
aura_env.watched_frame_events = {
    BANKFRAME_OPENED = true,
    BANKFRAME_CLOSED = true,
    MAIL_SHOW = true,
    MERCHANT_SHOW = true,
    MERCHANT_CLOSED = true,
    LOOT_OPENED = true,
    LOOT_CLOSED = true,
    PLAYER_INTERACTION_MANAGER_FRAME_HIDE = true,
}
aura_env.bag_check_events = {
    BAG_UPDATE_DELAYED = true,
    PLAYER_REGEN_ENABLED = true,
    -- BAG_UPDATE_COOLDOWN = true,
    LOOT_CLOSED = true,
}
aura_env.button_id = "AutoClamButton"
aura_env.bankOpen = false
aura_env.mailOpen = false
aura_env.merchantOpen = false
aura_env.isLooting = false

aura_env.enableButton = function()
    if InCombatLockdown() then return false end
    if not aura_env.button then
        aura_env.button = _G[aura_env.button_id] or
            CreateFrame("Button", aura_env.button_id, aura_env.region, "SecureActionButtonTemplate")
        aura_env.button:SetAllPoints()
    end
    aura_env.button:SetScript("PostClick", function()
        -- open all items
    end)
    aura_env.button:Enable()
    aura_env.button:Show()
    return true
end
aura_env.removeButton = function()
    aura_env.button = _G[aura_env.button_id]
    if aura_env.button then
        aura_env.button:Hide()
        aura_env.button:Disable()
    end
end
aura_env.onWatchedFramesUpdate = function(_, event, ...)
    local frame_type, action = strsplit('_', event)
    local isOpen = action ~= "CLOSED"
    if frame_type == "BANKFRAME" then
        aura_env.bankOpen = isOpen
    elseif frame_type == "MAIL" then
        aura_env.mailOpen = isOpen
    elseif frame_type == "LOOT" then
        aura_env.isLooting = isOpen
    elseif frame_type == "MERCHANT" then
        aura_env.merchantOpen = isOpen
    else -- PLAYER_INTERACTION_MANAGER_FRAME_HIDE
        if ... == Enum.PlayerInteractionType["MailInfo"] then
            aura_env.mailOpen = false
        end
    end
end
aura_env.onBagUpdate = function(allstates, event, ...)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info
                and info.itemID
                and aura_env.allowed_items[info.itemID]
                and info.hasLoot
            then
                local changed = allstates[""]
                    and (allstates[""].bag ~= bag) or (allstates[""].slot ~= slot)
                C_Container.UseContainerItem(bag, slot)
                aura_env.enableButton(bag, slot)
                allstates[""] = {
                    changed = changed,
                    show = true,
                    itemName = info.itemName,
                    icon = info.iconFileID,
                    count = info.stackCount,
                    enabled = not info.isLocked,
                    bag = bag,
                    slot = slot,
                }
                return true
            else
            end
        end
    end
    allstates[""] = {
        changed = true,
        show = false,
    }
    return true
end

-- Events: BANKFRAME_OPENED, BANKFRAME_CLOSED, MAIL_SHOW, MERCHANT_SHOW, MERCHANT_CLOSED, LOOT_OPENED, LOOT_CLOSED, PLAYER_REGEN_ENABLED, BAG_UPDATE_DELAYED, PLAYER_INTERACTION_MANAGER_FRAME_HIDE
aura_env.onEvent = function(allstates, event, ...)
    -- print(event)
    if aura_env.watched_frame_events[event] then
        aura_env.onWatchedFramesUpdate(allstates, event, ...)
    elseif aura_env.bag_check_events[event] then
        if aura_env.bankOpen
            or aura_env.mailOpen
            or aura_env.merchantOpen
            or aura_env.isLooting
            or InCombatLockdown()
        then
            if allstates[""] then
                allstates[""].enabled = false
                allstates[""].changed = true
            end
        else
            return aura_env.onBagUpdate(allstates, event, ...)
        end
    end
end
