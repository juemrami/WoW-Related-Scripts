aura_env.allowed_items = {
    -- Pick Pocket
    [16882] = true, -- Battered Junkbox
    [16883] = true, -- Worn Junkbox
    [16884] = true, -- Sturdy Junkbox
    [16885] = true, -- Heavy Junkbox
    -- Clams
    [15874] = true, -- Soft-shelled Clam
    [5523]  = true, -- Small Barnacled Clam
    [5524]  = true, -- Thick-shelled Clam
    [7973]  = true, -- Big-mouth Clam
    -- Lockboxes
    [5760]  = true, -- Eternium Lockbox
    [5759]  = true, -- Thorium Lockbox
    [5758]  = true, -- Mithril Lockbox
    [4638]  = true, -- Reinforced Steel Lockbox
    [4637]  = true, -- Steel Lockbox
    [4636]  = true, -- Strong Iron Lockbox
    [4634]  = true, -- Iron Lockbox
    [4633]  = true, -- Heavy Bronze Lockbox
    [4632]  = true, -- Ornate Bronze Lockbox
}
aura_env.lockpicking_spells = {
    [1804] = true, -- Pick Lock
    -- add bs/engi items if needed
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
aura_env.button_update_events = {
    BAG_UPDATE_DELAYED = true,
    PLAYER_REGEN_ENABLED = true,
    -- BAG_UPDATE_COOLDOWN = true,
    LOOT_CLOSED = true,
}
aura_env.button_id = "AutoOpenItemsButton"
aura_env.scantip_id = "AutoOpenItemsScantip"

aura_env.bankOpen = false
aura_env.mailOpen = false
aura_env.merchantOpen = false
aura_env.isLooting = false
-- locals shared between aura_env and the game environment for the button

aura_env.getTooltipScanner = function()
    local tip = _G[aura_env.scantip_id] 
        or CreateFrame("GameTooltip", aura_env.scantip_id, nil, "SharedTooltipTemplate")
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    return tip --[[@as GameTooltip]]
end
aura_env.isBagItemLocked = function(bag, slot)
    local tip = aura_env.getTooltipScanner()
    tip:ClearLines()
    tip:SetBagItem(bag, slot)
    for i = 1, tip:NumLines() do
        local text = _G[aura_env.scantip_id .. "TextLeft" .. i]:GetText()
        if text and text:find(LOCKED) then
            return true
        end
    end
    tip:Hide()
    return false
end
aura_env.setAutoOpenButton = function(bagId, slotId, should_unlock)
    if InCombatLockdown() then return false end
    local button = _G[aura_env.button_id] 
    if not button then
        button = CreateFrame("Button", aura_env.button_id, aura_env.region, "SecureActionButtonTemplate")
        -- only register mouse up events
        -- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetAllPoints()
        button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
        button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")
    end
    local bag_slot = ("%s %s"):format(bagId, slotId)
    if should_unlock then
        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext", "/cast Pick Lock \n/use " .. bag_slot)
        -- button:SetAttribute("target-item", bag_slot)
    else
        button:SetAttribute("type1", "item")
        button:SetAttribute("item", bag_slot)
    end
    button:Enable()
    button:Show()
end
aura_env.removeButton = function()
    local button = _G[aura_env.button_id]
    if button then
        button:Hide()
        button:Disable()
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
aura_env.buttonUpdateHandler = function(allstates)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info
                and info.itemID
                and aura_env.allowed_items[info.itemID]
                and info.hasLoot
            then
                local changed = true
                if allstates[""] then
                    changed = (allstates[""].bag ~= bag) 
                        or (allstates[""].slot ~= slot)
                end
                local is_unlock_required = aura_env.isBagItemLocked(bag, slot)

                if changed then
                    print(("AutoOpenItems: Next lootable item - %s. %s")
                        :format(
                            info.hyperlink or info.itemName,
                            is_unlock_required and "Requires unlocking!" or ""
                        ))
                end
                aura_env.setAutoOpenButton(bag, slot, is_unlock_required)
                --C_Container.UseContainerItem(bag, slot)
                allstates[""] = {
                    changed = changed,
                    show = true,
                    itemName = info.itemName,
                    icon = info.iconFileID,
                    count = info.stackCount,
                    itemId = info.itemID,
                    isLocked = is_unlock_required,
                    enabled = not info.isLocked,
                    bag = bag,
                    slot = slot,
                }
                return true
            end
        end
    end
    allstates[""] = {
        changed = true,
        show = false,
    }
    return true
end

-- Events: BANKFRAME_OPENED, BANKFRAME_CLOSED, MAIL_SHOW, MERCHANT_SHOW, MERCHANT_CLOSED, LOOT_OPENED, LOOT_CLOSED, PLAYER_REGEN_ENABLED, BAG_UPDATE_DELAYED, BAG_UPDATE_COOLDOWN, PLAYER_INTERACTION_MANAGER_FRAME_HIDE, UI_ERROR_MESSAGE, ITEM_UNLOXKW
aura_env.onEvent = function(allstates, event, ...)
    if aura_env.watched_frame_events[event] then
        aura_env.onWatchedFramesUpdate(allstates, event, ...)
    elseif aura_env.button_update_events[event] then
        if aura_env.bankOpen
            or aura_env.mailOpen
            or aura_env.merchantOpen
            or aura_env.isLooting
            or InCombatLockdown()
        then
            if allstates[""] then
                allstates[""].changed = true
                allstates[""].disabled = true
            end
            aura_env.removeButton()
            return true
        else
            return aura_env.buttonUpdateHandler(allstates)
        end
    end
    -- force update button after box has been picked.
    -- fixes bug where the button would not update after the box has been picked.
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and aura_env.lockpicking_spells[spellID] then
            return aura_env.buttonUpdateHandler(allstates)
        end
    end 
end
