---@alias TriggerEvents
---| "PLAYER_MOUNT_DISPLAY_CHANGED"
---| "PLAYER_REGEN_ENABLED"
---| "PLAYER_EQUIPMENT_CHANGED"

aura_env.carrot = 11122
---@type {[13]?: number, [14]?: number}
aura_env.queued_by_slot = {}
if not aura_env.saved then
    aura_env.saved = {
        ---@type 13 | 14 | nil
        preferred_carrot_slot = nil,
        ---@type {[13]?: number, [14]?: number}
        combat_trinket_by_slot = {}
    }
end
--- Returns `true` if item was successfully equipped. Otherwise returns `false` and queues the item equip.
---@param slot 13 | 14
---@param item_id number
---@param player_equipped? boolean # default `nil`
---@return boolean equipped
local function equip_or_queue_item(slot, item_id, player_equipped)
    local equipped = false
    if item_id == GetInventoryItemID("player", slot) then
        equipped = true
    end
    --print("equipping item from ", caller)
    print("equipping... item: ", GetItemInfo(item_id), "slot: ", slot)

    if not InCombatLockdown() then
        EquipItemByName(item_id, slot)
        aura_env.auto_equipped = not player_equipped
        aura_env.queued_by_slot[slot] = nil
        equipped = true
    else
        aura_env.queued_by_slot[slot] = {
            slot = slot,
            item = item_id,
        }
    end
    return equipped
end
-- i want to update my code so that both combat trinkets are saved.
---@param allstates table
---@param event TriggerEvents
---@param ... any
---@return boolean stateUpdated
aura_env.onEvent = function(allstates, event, ...)
    -- Event fires when the player character model mounts some game object.
    if event == "PLAYER_MOUNT_DISPLAY_CHANGED"
        or event == "OPTIONS"
    then
        local equipped = {
            [INVSLOT_TRINKET1] = GetInventoryItemID("player", INVSLOT_TRINKET1),
            [INVSLOT_TRINKET2] = GetInventoryItemID("player", INVSLOT_TRINKET2)
        }
        local saved_trinkets = aura_env.saved.combat_trinket_by_slot
        local equipped_trinket_1 = equipped[INVSLOT_TRINKET1] 
        local equipped_trinket_2 = equipped[INVSLOT_TRINKET2]
    
        -- This weakaura will still try and equip trinkets even when no state is changed. state is just for the visual part of the weakaura. not the internal part.
        local stateChanged = false
        
        -- Flight paths are considered mounted. Early exit.
        if UnitOnTaxi("player") then
            -- hide any weakaura state
            if allstates[''] and allstates[''].show then
                allstates[''] = {
                    show = false,
                    changed = true,
                }
            end
            stateChanged = true
            return stateChanged

        -- Player has just mounted
        elseif IsMounted() then
            local isCarrotAvailable = GetItemCount(aura_env.carrot) ~= 0
            if not isCarrotAvailable then return false end

            -- check if we have it equipped already
            local current_carrot_slot = tInvert(equipped)[aura_env.carrot]
            if current_carrot_slot then
                -- only thing we might want to do here 
                --is update the saved combat trinkets
                local saved_trinket_at_carrot_slot = aura_env.saved
                    .combat_trinket_by_slot[current_carrot_slot]
                
                -- if slot is empty we can store the carrot as combat trinket
                -- this should only happen on characters with 1 trinket 
                if not saved_trinket_at_carrot_slot then
                    saved_trinket_at_carrot_slot = aura_env.carrot
                end

                return stateChanged
            else -- When carrot is not equipped
                -- Firstly, we save our currently equipped trinkets
                saved_trinkets[INVSLOT_TRINKET1] = equipped[INVSLOT_TRINKET1]
                saved_trinkets[INVSLOT_TRINKET2] = equipped[INVSLOT_TRINKET2]
                
                -- Then, find what slot the player prefers to have the carrot in
                if not aura_env.preferred_carrot_slot then
                    -- default to trinket slot 2 if there is nothing there
                    -- otherwise trinket slot 1
                    aura_env.preferred_carrot_slot = 
                        equipped[INVSLOT_TRINKET2] == nil 
                        and INVSLOT_TRINKET2 or INVSLOT_TRINKET1
                end

                -- Finally try equip carrot in preferred slot
                local carrot_equipped = equip_or_queue_item(
                    aura_env.preferred_carrot_slot,
                    aura_env.carrot
                )
                if carrot_equipped and not IsInventoryItemLocked(aura_env.preferred_carrot_slot) then
                    allstates[''] = {
                        show = true,
                        changed = true,
                        name = "Autocarrot",
                        trinket1 = GetItemInfo(saved_trinkets[INVSLOT_TRINKET1] or 0),
                        trinket2 = GetItemInfo(saved_trinkets[INVSLOT_TRINKET2] or 0),
                    }
                    stateChanged = true
                end
            end
        -- Player has just dismounted
        elseif not IsMounted() then
            -- Try to restore saved trinkets
            local changed = false
            for slot, item_id 
                in ipairs(aura_env.saved.combat_trinket_by_slot)
            do if equip_or_queue_item(slot, item_id) then
                changed = true
               end 
            end
            if changed then
                allstates[''] = {
                    show = true,
                    changed = true,
                    name = "Autocarrot",
                    trinket1 = GetItemInfo(saved_trinkets[INVSLOT_TRINKET1] or 0),
                    trinket2 = GetItemInfo(saved_trinkets[INVSLOT_TRINKET2] or 0),
                }
                stateChanged = true
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- equip any queued items once we're out of combat
        for slot, item in pairs(aura_env.queued_by_slot) do
            equip_or_queue_item(slot, item)
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        ---@type number, boolean 
        local changed_slot, is_slot_empty = ...
        
        if changed_slot ~= INVSLOT_TRINKET1 
            and changed_slot ~= INVSLOT_TRINKET2 
        then
            return false
        end

        local equipped = {
            [INVSLOT_TRINKET1] = GetInventoryItemID("player", INVSLOT_TRINKET1),
            [INVSLOT_TRINKET2] = GetInventoryItemID("player", INVSLOT_TRINKET2)
        }
        local saved_trinkets = aura_env.saved.combat_trinket_by_slot
        if equipped[changed_slot] then
            local name = GetItemInfo(equipped[changed_slot])
            print("Trinket equipped: " .. name .. " | Auto Equipped: ", aura_env.auto_equipped)

            -- Check
            if not tContains(equipped, aura_env.carrot) then
                -- if not, then  update saved combat trinkets
                for slot, item in pairs(equipped) do
                    saved_trinkets[slot] = item
                end
            else 
                -- If it is equipped
                local carrot_slot = 
                    equipped[INVSLOT_TRINKET1] == aura_env.carrot 
                    and INVSLOT_TRINKET1 or INVSLOT_TRINKET2
                
                -- Check if its slot was updated manually
                if aura_env.saved.preferred_carrot_slot ~= carrot_slot 
                    and not aura_env.auto_equipped 
                then
                     -- Update preferred carrot slot if so.
                    aura_env.saved.preferred_carrot_slot = carrot_slot

                    -- following code might not be helpful. usually when you swap ur carrot around if you have it equipped its to get your other trinket on ur prefered on use slot.

                    -- -- Check if the other trinket has also been changed
                    -- -- ie trinkets swapped location
                    -- local other_slot = 
                    --     carrot_slot == INVSLOT_TRINKET1 
                    --     and INVSLOT_TRINKET2 or INVSLOT_TRINKET1

                    -- -- If the trinkets 2 equipped trinks were simply swapped 
                    -- if saved_trinkets[other_slot] ~= equipped[other_slot] then
                    --     -- save old saved trinket
                    --     local old_trinket = saved_trinkets[other_slot]
                    --     -- update the saved trinket for that slot
                    --     saved_trinkets[other_slot] = GetInventoryItemID("player", other_slot)
                    --     -- store the old trinket in the carrot slot
                        
                    --     local saved_trinket = old_trinket ~= aura_env.carrot 
                    --         and old_trinket or nil
                    -- end
                end
            end
            -- if carrot is manually equipped while mounted
            if not aura_env.auto_equipped
                and GetInventoryItemID("player", changed_slot) == aura_env.carrot
            then -- update preferred carrot slot
                aura_env.preferred_carrot_slot = changed_slot
            end
            -- cleanup
            aura_env.queued_by_slot[changed_slot] = nil
            aura_env.auto_equipped = false
        end
        allstates[''] = {
            changed = true,
            show = true,
            name = "Autocarrot",
            trinket1 = GetItemInfo(aura_env.saved.combat_trinket_by_slot[INVSLOT_TRINKET1] or 0),
            trinket2 = GetItemInfo(aura_env.saved.combat_trinket_by_slot[INVSLOT_TRINKET2] or 0),
        }
    end
    return true
end
