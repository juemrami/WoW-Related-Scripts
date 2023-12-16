-- events: RUNE_UPDATED, PLAYER_EQUIPMENT_CHANGED
aura_env.onEvent = function(states, event, ...)
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
            else
                states[category] = {
                    show = false,
                    changed = true,
                }
            end
        end
        return true
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
