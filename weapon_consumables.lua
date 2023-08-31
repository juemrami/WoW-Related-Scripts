-- use GAME_ITEM_INFO_RECEIVED, item_id, exists
aura_env.saved = nil
local base_items = {
    -- insc
    ["buzzing rune"] = { 194821, 194822, 194823 },
    ["chirping rune"] = { 194824, 194825, 194826 },
    -- engi
    ["endless stack of needles"] = { 198163, 198164, 198165 },
    ["completely safe rockets"] = { 198160, 198161, 198162 },
    -- bs
    ["primal razorstone"] = { 191948, 191949, 191950 }, -- proff
    ["porous sharpening stone"] = { 171436 },           -- shadowlands
    -- lw
    ["primal weightstone"] = { 191943, 191944, 191945 },
    -- non sequential ids
    ["primal whetstone"] = { 191933, 191939, 191940 },
    ["howling rune"] = { 194817, 194819, 194820 },
}
if not aura_env.saved then
    aura_env.saved = {}
    aura_env.saved["ids_by_name"] = {}
    aura_env.saved["consumable_by_item_id"] = {}
    -- item cache setup, blizz has a bad api for this stuff
    for name, item_ids in pairs(base_items) do
        aura_env.saved["ids_by_name"][name] = item_ids
        for i, item_id in ipairs(item_ids) do
            local _, spell_id  GetItemSpell(item_id)
            local icon = GetItemIcon(item_id)
            aura_env.saved["consumable_by_item_id"][item_id] = {
                ["name"] = name,
                ["item_id"] = item_id,
                ["spell_id"] = spell_id,
                ["enchant_id"] = nil,
                ["quality"] = i,
                ["icon"] = icon,
                ["durration"] = 3600 * 2, -- 2 hours, default for DF
                ["is_rune"] = name:find("rune") and true or false,
            }
        end
    end
    aura_env.saved["item_id_by_enchant_id"] = {
        -- insert your own here, or let the WA auto populate over time
        -- will only work if the item is applied while the aura is
        -- loaded, so it's not a perfect solution 
        [6514] = 194823 -- r3 buzzing rune
    }
end
aura_env.scan_cache = function()
    if not aura_env.saved and not aura_env.saved["consumable_by_item_id"] then return end
    for item_id, consumable in pairs(aura_env.saved["consumable_by_item_id"]) do
        if not consumable.spell_id then
            print('requesting item info for item id: ', item_id)
            local _, spell_id = GetItemSpell(item_id)
            local icon = GetItemIcon(item_id)
            aura_env.saved["consumable_by_item_id"][item_id]["spell_id"] = spell_id
            aura_env.saved["consumable_by_item_id"][item_id]["icon"] = icon
            if spell_id then print('info cached for item id: ', item_id) end
        end
    end
    for enchant_id, item_id in pairs(aura_env.saved["item_id_by_enchant_id"]) do
        if not aura_env.saved["consumable_by_item_id"][item_id] then
            print('requesting item info for item id: ', item_id)
            local _, spell_id = GetItemSpell(item_id)
            local icon = GetItemIcon(item_id)
            aura_env.saved["consumable_by_item_id"][item_id]["spell_id"] = spell_id
            aura_env.saved["consumable_by_item_id"][item_id]["icon"] = icon
            aura_env.saved["consumable_by_item_id"][item_id]["enchant_id"] = enchant_id
            if spell_id then print('info cached for item id: ', item_id) end
        end
    end
end
aura_env.item_info_trigger = function(allstates, event, ...)
    local item_exists = select(2, ...)
    if event == "GAME_ITEM_INFO_RECEIVED"
    and item_exists
    and aura_env and aura_env.saved
    then
        print("3")
        local item_id = ...
        local consumable = aura_env.saved["consumable_by_item_id"][item_id]
        if consumable and not consumable.spell_id then
            local icon = GetItemIcon(item_id)
            local _, spell_id = GetItemSpell(item_id)
            local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(item_id)
            aura_env.saved["consumable_by_item_id"][item_id]["spell_id"] = spell_id
            aura_env.saved["consumable_by_item_id"][item_id]["quality"] = quality
            aura_env.saved["consumable_by_item_id"][item_id]["icon"] = icon
            ViragDevTool:AddData(aura_env.saved["consumable_by_item_id"][item_id], "item " .. item_id .. " info")
            if spell_id then print('info cached for item id: ', item_id) end
        end
    end
end
-- event(s): READY_CHECK, UNIT_INVENTORY_CHANGED, READY_CHECK_FINISHED, READY_CHECK_FINISHED, ENCHANT_APPLIED, UNIT_SPELLCAST_SUCCEEDED, GAME_ITEM_INFO_RECEIVED
aura_env.main_trigger = function(allstates, event, ...)
    if event == "READY_CHECK" then
        allstates[""] = {
            show = true,
            changed = true,
            icon = 134400,
            durration = 0,
            expirationTime = 0,
            is_main_enchant = true,
            is_off_enchant = true,
        }
        local weapons = aura_env.get_applied_consumables()
        print("applied consumables: ", weapons)
        if weapons then
            ViragDevTool:AddData(weapons, "weapons")
            local currently_showing = weapons.main.expiration > weapons.off.expiration and "main" or "off"
            allstates[""] = {
                show = true,
                changed = true,
                -- icon should instead be the icon of the consumable that will be used
                icon = weapons[currently_showing].icon,
                durration = weapons[currently_showing].durration,
                expirationTime = weapons[currently_showing].expiration,
                is_main_enchant = weapons.main and true or false,
                is_off_enchant = weapons.off and true or false,
            }
        end
    elseif event == "READY_CHECK_FINISHED" then
        allstates[""] = {
            show = false,
            changed = true,
        }
    end
    return true
end

aura_env.get_applied_consumables = function()
    local mh = GetInventoryItemID("player", 16)
    local oh = GetInventoryItemID("player", 17)
    local is_mh_ench, mh_expiration, _, mh_enchant_id,
    is_oh_ench, oh_expiration, _, oh_enchant_id = GetWeaponEnchantInfo()
    local weapons = {}
    if mh and is_mh_ench then
        weapons.main = {}
        local item_id = aura_env.saved["item_id_by_enchant_id"][mh_enchant_id]
        if item_id then 
            local consumable = aura_env.saved["consumable_by_item_id"][item_id]    
            weapons.main = consumable or {}
        end
        weapons.main.expiration = mh_expiration or 0
    end
    if oh and is_oh_ench then
        weapons.off = {}
        local item_id = aura_env.saved["item_id_by_enchant_id"][oh_enchant_id]
        if not item_id then 
            local consumable = aura_env.saved["consumable_by_item_id"][item_id]
            weapons.off = consumable or {}
        end
        weapons.off.expiration = oh_expiration or 0
    end
    return weapons
end
