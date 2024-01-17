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

aura_env.bankOpen = false
aura_env.mailOpen = false
aura_env.merchantOpen = false
aura_env.isLooting = false
-- locals shared between aura_env and the game environment for the button
local last_locked_item = { bag = nil, slot = nil }
local pick_if_locked = function(bag, slot)
    if last_locked_item.bag == bag
        and last_locked_item.slot == slot then
        return IsSpellKnown(1804) -- Pick Lock
            and CastSpellByID(1804)
    end
end
aura_env.setButton = function(bagId, slotId)
    if InCombatLockdown() then return false end
    if not aura_env.button then
        aura_env.button = _G[aura_env.button_id] or
            CreateFrame("Button", aura_env.button_id, aura_env.region, "SecureActionButtonTemplate")
        -- only register mouse up events
        -- aura_env.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        aura_env.button:SetScript("PreClick", function()
            return pick_if_locked(bagId, slotId)
        end)
        aura_env.button:SetAttribute("type1", "item")
        aura_env.button:SetAllPoints()
        aura_env.button
            :SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
        aura_env.button
            :SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")
    end
    local bag_slot = ("%s %s"):format(bagId, slotId)
    if aura_env.button:GetAttribute("item") ~= bag_slot then
        -- print("making button for " .. bag_slot)
        aura_env.button:SetAttribute("item", bag_slot)
    end
    aura_env.button:Enable()
    aura_env.button:Show()
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
                    changed = (allstates[""].bag ~= bag) or (allstates[""].slot ~= slot)
                end
                local is_container_locked = last_locked_item
                    and last_locked_item.bag == bag
                    and last_locked_item.slot == slot
                -- disable this for now
                is_container_locked = false


                if changed then
                    print("AutoOpenItems: Next lootable item - " .. info.hyperlink .. ".")
                end
                --C_Container.UseContainerItem(bag, slot)
                aura_env.setButton(bag, slot)
                allstates[""] = {
                    changed = changed,
                    show = true,
                    itemName = info.itemName,
                    icon = info.iconFileID,
                    count = info.stackCount,
                    enabled = not info.isLocked and aura_env.setButton(bag, slot),
                    bag = bag,
                    slot = slot,
                }
                return true
            else
                print("AutoOpenItems: Item " .. info.hyperlink .. " locked. Temporarily ignoring.")
            end
        end
    end
    allstates[""] = {
        changed = true,
        show = false,
    }
    return true
end

-- Events: BANKFRAME_OPENED, BANKFRAME_CLOSED, MAIL_SHOW, MERCHANT_SHOW, MERCHANT_CLOSED, LOOT_OPENED, LOOT_CLOSED, PLAYER_REGEN_ENABLED, BAG_UPDATE_DELAYED, BAG_UPDATE_COOLDOWN, PLAYER_INTERACTION_MANAGER_FRAME_HIDE, UI_ERROR_MESSAGE
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
    if event == "UI_ERROR_MESSAGE"
        and select(2, ...) == ERR_ITEM_LOCKED then
        if allstates[""] then
            last_locked_item = {
                bag = allstates[""].bag,
                slot = allstates[""].slot
            }
        end
    end
end
