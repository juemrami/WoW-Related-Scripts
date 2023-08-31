aura_env.debug = false
aura_env.info_request_sent = {}
if not aura_env.saved then
    print("cache reset")
    aura_env.saved = {
        ["item_cache"] = {},
    }
end
aura_env.createAuraButton = function()
    if aura_env.button
    then
        print("Delete button before creating a new one.")
        return
    end
    if not aura_env.button_macro
    then
        print("No macro script to add to button.")
        return
    end
    aura_env.button = CreateFrame("Button",
        "WA_FlaskReminder_MacroButton",
        aura_env.region,
        "SecureActionButtonTemplate")
    aura_env.button:RegisterForClicks("AnyDown", "AnyUp")
    aura_env.button:SetAllPoints()
    aura_env.button:SetMouseClickEnabled(true)
    aura_env.button:SetAttribute("unit", "player")
    aura_env.button:SetAttribute("type1", "macro")
    aura_env.button:SetAttribute("shift-type1", "macro")
    aura_env.button:SetAttribute("shift-macrotext1", "/use item:2723;")
    aura_env.button:SetAttribute("macrotext1", string.format(aura_env.button_macro))
    aura_env.button:SetScript("PostClick", function(self, btn, down)
        if (down) then
            print("POSTCLICK: Clicked button=", self:GetName(), "  btn=", btn, "  down=", down, "  macroTxt=",
                self:GetAttribute("macrotext1"))
        end
    end)
    if aura_env.debug then print(("macro: |n%s"):format(aura_env.button_macro)) end
    print("Button created")
    -- ViragDevTool:AddData(aura_env.button, "button")
end
aura_env.deleteAuraButton = function()
    if not aura_env.button then
        return
    else
        aura_env.button:ClearAllPoints()
        aura_env.button = nil
        print("Button Deleted")
    end
end
aura_env.updateButtonMacro = function(item_ids)
    local base = "/use item:%s;\n"
    local macro_script
    if not item_ids then return end
    print("item ids", unpack(item_ids))
    for _, id in ipairs(item_ids) do
        macro_script = macro_script and
            macro_script .. string.format(base, id)
            or string.format(base, id)
    end
    if macro_script and aura_env.button_macro ~= macro_script
    then
        print("Macro updated.")
        aura_env.button_macro = macro_script
        return true
    end
end
aura_env.getFlaskItemInfo = function(item_name)
    local name, item_link, _, _, _, _, _, _, _, icon = GetItemInfo(item_name)
    local names_match = name and string.lower(name) == string.lower(item_name)
    if aura_env.saved and names_match and aura_env.saved["item_cache"][name] then
        local item_ids, buff_id, icon = unpack(aura_env.saved["item_cache"][name])
        return item_ids, buff_id, icon, name
    end
    if not item_link then
        if not aura_env.info_request_sent[item_name] then
            aura_env.info_request_sent[item_name] = true
        else
            print(string.format(
                [[|cFFdfa700FlaskReminder Warning!|r Item, "%s" not found in cache. Please add item to inventory or verify item name.]],
                item_name))
        end
        return
    end
    local item_id = string.match(item_link or "", "Hitem:(%d+):")
    if not item_id then return end
    local _, buff_id = GetItemSpell(item_id)
    buff_id = tonumber(buff_id)
    if not buff_id then
        print(([[|cFFdfa700FlaskReminder Warning!|r. No flask buff data found for item, "%s". Please verify item is a flask.]])
            :format(item_name))
        return nil
    end
    local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(item_id)
    local item_ids = {}
    -- print("quality: ", quality)
    if quality == 1 then
        item_ids = { item_id, item_id + 1, item_id + 2 }
    elseif quality == 2 then
        item_ids = { item_id - 1, item_id, item_id + 1 }
    elseif quality == 3 then
        item_ids = { item_id - 2, item_id - 1, item_id }
    else
        item_ids = { item_id }
    end
    local all_match = true
    for _, id in ipairs(item_ids) do
        local _, flask_buff = GetItemSpell(id)
        -- print("itemspell: ", flask_buff, buff_id)
        if flask_buff ~= buff_id then
            WeakAuras.prettyPrint("|cFFdf0000FlaskReminder Warning: Flask buff data mismatch for item " ..
            item_name .. ". Please report this to the author.")
            all_match = false
        end
    end
    print("all qualities found")
    if all_match then
        print("all qualities ok")
        aura_env.saved["item_cache"][name] = { item_ids, buff_id, icon }
    end
    return item_ids, buff_id, icon, name
end
aura_env.getFlaskCountInfoByIds = function(item_ids)
    if not item_ids then return 0,0 end
    local item_counts = {}
    local total = 0
    for i = 1, #item_ids do
        local i_count = GetItemCount(item_ids[i]) or 0
        if aura_env.debug then print("Quality " .. i .. " count: " .. i_count) end
        total = total + i_count
        item_counts[i] = i_count
    end
    if aura_env.debug then print("Total: ", total) end
    return item_counts, total
end
print("INIT_CALLED")
if aura_env.config.flask_name
    and not aura_env.button then
    local item_ids, _, _, _ = aura_env.getFlaskItemInfo(aura_env.config.flask_name)
    aura_env.updateButtonMacro(item_ids)
    --aura_env.createAuraButton()
end
-- events: OPTIONS,BAG_UPDATE_DELAYED, READY_CHECK, READY_CHECK_FINISHED, PLAYER_REGEN_DISABLED, STATUS, UNIT_SPELLCAST_SUCCEEDED
aura_env.trigger_1 = function(allstates, event, ...)
    if event == "OPTIONS" or event == "READY_CHECK" then
        local item_ids, buff_id, icon, name = aura_env.getFlaskItemInfo(aura_env.config.flask_name)
        if not (item_ids and buff_id and icon and name) then
            print("no items for given flask name")
            allstates[""] = {
                icon = 134400,
                show = true,
                changed = true,
                autoHide = event == "OPTIONS"
            }
            return true
        end
        local is_update = aura_env.updateButtonMacro(item_ids)
        if is_update then aura_env.deleteAuraButton() end
        local flask_counts, total_count = aura_env.getFlaskCountInfoByIds(item_ids)
        local flask_aura = C_UnitAuras.GetPlayerAuraBySpellID(buff_id)
        local available_quality
        for i = 1, #flask_counts do
            if flask_counts[#flask_counts - i + 1] > 0 then
                available_quality = #flask_counts - i + 1
                break
            end
        end
        allstates[""] = {
            show = true,
            changed = true,
            progressType = "timed",
            expirationTime = flask_aura and flask_aura.expirationTime or 0,
            duration = flask_aura and flask_aura.duration,
            buffActive = flask_aura and true or false,
            name = name,
            icon = icon,
            buffId = buff_id,
            stacks = total_count,
            autoHide = event == "OPTIONS",
            quality = available_quality,
            index = 0,
        }
        if event == "READY_CHECK" then
            aura_env.createAuraButton()
        end
        return true
    elseif event == "READY_CHECK_FINISHED" or event == "PLAYER_REGEN_DISABLED" or event == "STATUS" then
        allstates[""] = nil
        aura_env.deleteAuraButton()
        return true
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and allstates then
        local unit = ...
        local spell_id = select(3, ...)
        if unit == "player" and spell_id and allstates[""]
            and allstates[""].buffId == spell_id
        then
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(spell_id)
            if not aura then return end
            allstates[""].expirationTime = aura.expirationTime
            allstates[""].duration = aura.duration
            allstates[""].buffActive = true
            allstates[""].changed = true
            return true
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        if not allstates[""] then return end
        local item_ids, _, _, _ = aura_env.getFlaskItemInfo(aura_env.config.flask_name)
        
        local _, count = aura_env.getFlaskCountInfoByIds(item_ids)
        if allstates[""] and count ~= allstates[""].stacks then
            if aura_env.debug then print("New Count: ", count) end
            allstates[""].stacks = count
            allstates[""].changed = true
            return true
        end
    end
end
aura_env.custom_text = function()
    if aura_env.state and aura_env.state.quality then
        return CreateAtlasMarkupWithAtlasSize("Professions-Icon-Quality-Tier"..aura_env.state.quality.."-Small")
    end
end
