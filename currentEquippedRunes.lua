-- events: RUNE_UPDATED, PLAYER_EQUIPMENT_CHANGED, UNIT_SPELLCAST_SUCCEEDED:player
aura_env.spellForEquipmentSlot = {}
aura_env.updateRuneEvents = {
    ["RUNE_UPDATED"] = true,
    ["OPTIONS"] = true,
    ["STATUS"] = true,
    ["PLAYER_EQUIPMENT_CHANGED"] = true,
}
aura_env.onEvent = function(states, event, ...)
    if aura_env.updateRuneEvents[event] then
        if C_Engraving and C_Engraving.IsEngravingEnabled() then
            local categories = C_Engraving.GetRuneCategories(false, true)
            for _, category in pairs(categories) do
                local rune = C_Engraving.GetRuneForEquipmentSlot(category)
                if rune then
                    states[category] = {
                        show = true,
                        changed = true,
                        unit = "player",
                        name = rune.name,
                        shortName = aura_env.shortenString(rune.name),
                        icon = rune.iconTexture,
                        slot = GetItemInventorySlotInfo(rune.equipmentSlot),
                    }
                    aura_env.spellForEquipmentSlot[category] = rune.learnedAbilitySpellIDs[1]
                else
                    states[category] = {
                        show = false,
                        changed = true,
                    }
                end
            end
            aura_env.slotForSpellId = tInvert(aura_env.spellForEquipmentSlot)
            aura_env.setAllRuneCooldowns(states)
            return true
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spellId = select(3, ...)
        local slot = aura_env.slotForSpellId[spellId]
        if slot then
            return aura_env.setRuneCooldown(states, slot)
        end
    end
end
---Make an english word/phrase into initial, or truncate it if one word.
---Likely wont make sense for non-english clients.
---@param inputStr string
---@return string shortStr
aura_env.shortenString = function(inputStr)
    -- otherwise truncate at next non-vowel
    if #inputStr <= 5 then return inputStr end
    -- if single word, check third letter.
    if inputStr:find("%s") == nil then
        -- if not vowel truncate to 3 letters.
        if inputStr:sub(3, 3):find("[aeiou]") == nil then
            return inputStr:sub(1, 3)
        else
            -- otherwise truncate at next vowel
            local nextVowel = inputStr:find("[aeiou]", 4)
            return inputStr:sub(1, nextVowel - 1)
        end
    end
    local shortStr = ""
    for word in inputStr:gmatch("%S+") do
        shortStr = shortStr .. word:sub(1, 1)
    end
    return shortStr
end
aura_env.setAllRuneCooldowns = function(states)
    local anyChanged = false
    for slot, state in pairs(states) do
        if state.show then
            local spellId = aura_env.spellForEquipmentSlot[slot]
            local lastCast = GetSpellCooldown(spellId)
            local duration = (GetSpellBaseCooldown(spellId) or 0) / 1000
            if lastCast > 0 and duration > 0 then
                state.changed = true
                state.expirationTime = lastCast + duration
                state.duration = duration
                state.progressType = "timed"
                state.autoHide = false
                anyChanged = true
            end
        end
    end
    return anyChanged
end
aura_env.setRuneCooldown = function(states, slot)
    local spellID = aura_env.spellForEquipmentSlot[slot]
    if spellID then
        local lastCast = GetSpellCooldown(spellID)
        local duration = (GetSpellBaseCooldown(spellID) or 0) / 1000
        if lastCast > 0 and duration > 0 and states[slot] then
            states[slot].changed = true
            states[slot].expirationTime = lastCast + duration
            states[slot].duration = duration
            states[slot].progressType = "timed"
            states[slot].autoHide = false
            return true
        end
    end
end

----
for i = 1, select("#",  GetInventoryItemLink("player", INVSLOT_CHEST)) do 
nd