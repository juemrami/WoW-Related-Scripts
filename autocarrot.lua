-- PLAYER_MOUNT_DISPLAY_CHANGED
-- PLAYER_REGEN_ENABLED
-- PLAYER_EQUIPMENT_CHANGED
aura_env.carrot = 11122
aura_env.queued_by_slot = {}
if not aura_env.saved then
    aura_env.saved = {
        preferred_carrot_slot = nil,
        combat_trinket_by_slot = {
            [13] = nil,
            [14] = nil,
        }
    }
end
local function hide_states(allstates) 
allstates[''] = {
    show = false,
    changed = true,
}
end
--[[ args: slot, item. returns: true if item was equipped, false if queued]]
local function equip_or_queue_item(slot, item, caller)
    if not item then return true end
    if item == GetInventoryItemID("player", slot) then
        return true
    end
    --print("equipping item from ", caller)
    print("equipping... item: ", GetItemInfo(item), "slot: ", slot)

    if not InCombatLockdown() then
        EquipItemByName(item, slot)
        aura_env.auto_equipped = true
        aura_env.queued_by_slot[slot] = nil
    elseif aura_env.queued_by_slot then
        aura_env.queued_by_slot[slot] = {
            slot = slot,
            item = item,
        }
    end
end
-- i want to update my code so that both combat trinkets are saved.
aura_env.f = function(allstates, event, ...)
    --print("event: ", event)
    if event == "PLAYER_MOUNT_DISPLAY_CHANGED" or 
        event == "OPTIONS" 
    then
        local trinket_1 = GetInventoryItemID("player", 13)
        local trinket_2 = GetInventoryItemID("player", 14)
        if UnitOnTaxi("player") then 
            --hide_states(allstates)
            return
        end -- don't do anything if we're on a taxi
        if IsMounted() then
            local isCarrotAvailable = GetItemCount(aura_env.carrot) ~= 0
            if not isCarrotAvailable then return end
            -- 
            -- check if we have it equipped already
            if trinket_1 == aura_env.carrot 
                or trinket_2 == aura_env.carrot 
            then
                local equipped_carrot_slot = trinket_1 == aura_env.carrot and 13 or 14
                -- if we have no saved trinket in that slot
                if not aura_env.saved.combat_trinket_by_slot[equipped_carrot_slot]
                then
                    -- its okay to save the carrot as the non mounted trinket
                    aura_env.saved.combat_trinket_by_slot[equipped_carrot_slot] = aura_env.carrot
                end
                -- carrot equipped so do nothing
                return false
            else -- when carrot is not equipped
                -- save our combat trinkets, existing or nil
                aura_env.saved.combat_trinket_by_slot[13] = trinket_1
                aura_env.saved.combat_trinket_by_slot[14] = trinket_2
                if not aura_env.preferred_carrot_slot then
                    -- choose a slot. slot 2 if it is nil, or slot 1 (nil or not)
                    aura_env.preferred_carrot_slot = trinket_2 == nil and 14 or 13
                end
                local slot_to_equip = aura_env.preferred_carrot_slot
                equip_or_queue_item(slot_to_equip, aura_env.carrot, event..":PLAYER_MOUNTED")
                allstates[''] = {
                    show = true,
                    changed = true,
                    name = "Autocarrot",
                    trinket1 = GetItemInfo(aura_env.saved.combat_trinket_by_slot[13] or 0),
                    trinket2 = GetItemInfo(aura_env.saved.combat_trinket_by_slot[14] or 0),
                }
            end
        elseif not IsMounted() then -- if not IsMounted(), restore combat trinkets
            --hide_states(allstates)
            for _,slot in ipairs({13,14}) do
               equip_or_queue_item(slot, aura_env.saved.combat_trinket_by_slot[slot], event..":PLAYER_DISMOUNTED")
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- equip any queued items once we're out of combat
        if #aura_env.queued_by_slot > 0 then
            for _,slot in ipairs({13,14}) do
                local queued = aura_env.queued_by_slot[slot]
                if queued then
                    equip_or_queue_item(queued.slot, queued.item, event)
                end
            end
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot, is_empty = ...
        if slot == 13
            or slot == 14
            and not is_empty
        then
            local name = GetItemInfo(GetInventoryItemID("player", slot) or 0)
            print("Trinket equipped: ".. name .." | Auto Equipped: ", aura_env.auto_equipped)
            
            -- if carrot is not unequipped
            if GetInventoryItemID("player", 13) ~= aura_env.carrot
            and GetInventoryItemID("player", 14) ~= aura_env.carrot
            then -- update saved combat trinkets
                for _,slot in ipairs({13,14}) do
                    aura_env.saved.combat_trinket_by_slot[slot] = GetInventoryItemID("player", slot)
                end
            else -- if it is equipped
                local equipped_carrot_slot = GetInventoryItemID("player", 13) == aura_env.carrot and 13 or 14
                -- check if its slot has been updated
                if aura_env.saved.preferred_carrot_slot ~= equipped_carrot_slot then -- if it has
                    -- update preferred carrot slot
                    aura_env.saved.preferred_carrot_slot = equipped_carrot_slot
                    -- check if the other trinket has also been updated
                    local other_slot = equipped_carrot_slot == 13 and 14 or 13
                    if aura_env.saved.combat_trinket_by_slot[other_slot] ~= GetInventoryItemID("player", other_slot) then -- if it has
                        -- save old saved trinket
                        local old_trinket = aura_env.saved.combat_trinket_by_slot[other_slot]
                        -- update the saved trinket for that slot
                        aura_env.saved.combat_trinket_by_slot[other_slot] = GetInventoryItemID("player", other_slot)
                        -- store the old trinket in the carrot slot
                        aura_env.saved.combat_trinket_by_slot[equipped_carrot_slot] = old_trinket ~= aura_env.carrot and old_trinket or nil
                    end
                end
            end
            -- if carrot is manually equipped while mounted
            if not aura_env.auto_equipped 
            and GetInventoryItemID("player", slot) == aura_env.carrot
            then -- update preferred carrot slot
                aura_env.preferred_carrot_slot = slot
            end
            -- cleanup
            aura_env.queued_by_slot[slot] = nil
            aura_env.auto_equipped = false
        end
        allstates[''] = {
            changed = true,
            show = true,
            name = "Autocarrot",
            trinket1 = GetItemInfo(aura_env.saved.combat_trinket_by_slot[13] or 0),
            trinket2 = GetItemInfo(aura_env.saved.combat_trinket_by_slot[14] or 0),
        }
    end
    return true
end
