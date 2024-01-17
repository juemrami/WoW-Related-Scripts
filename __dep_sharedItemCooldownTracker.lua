aura_env.trackedItems = {
    11020, -- Evergreen Pouch
    15846, -- Salt Shaker
}
aura_env.trackedStuns = {
    18560, -- Mooncloth
}
aura_env.transmutes = {
    25146, -- Transmute: Elemental Fire
    17187, -- Transmute: Arcanite
}
aura_env.debug = true
if not aura_env.saved then
    aura_env.saved = {
        ---@class savedCooldown
        ---@field expirationTime number
        ---@field lastCast number
        ---@field duration number
        ---@field icon string|number?
        ---@field name string
        ---@field owner string
        ---@field spellID number
        ---@field itemID number?
        ---@type table<string, table<number, savedCooldown>>
        cooldownsByCharacter = {
            -- [characterName] = {
            --     [spellID] = {
            --         expirationTime: number,
            --         lastCast: number,
            --         duration: number,
            --         icon: string,
            --         name: string,
            --         owner: string,
            --         spellID: string,
            --         itemID: string,
            --         fromItem: boolean,
            --     },
            -- },
        }
    }
end
aura_env.currentCharacter = strjoin("-", UnitFullName("player"))
do
    aura_env.trackedSpellNames = {}
    aura_env.spellToItem = {}
    for _, itemID in pairs(aura_env.trackedItems) do
        local spellName, spellID = GetItemSpell(itemID)
        if spellName and spellID then
            aura_env.trackedSpellNames[spellName] = spellID
            aura_env.spellToItem[spellID] = itemID
            aura_env.spellToItem[spellName] = itemID
        end
    end
    for _, allSpells
    in ipairs({ aura_env.trackedStuns, aura_env.transmutes })
    do
        for _, spellId in ipairs(allSpells) do
            local spellName = GetSpellInfo(spellId)
            if spellName then
                aura_env.trackedSpellNames[spellName] = spellId
            end
        end
    end
    if not aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter] then
        aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter] = {}
    end
end
-- 11020 15846
-- CLEU:SPELL_CAST_SUCCESS, PLAYER_ENTERING_WORLD:SPELL_UPDATE_COOLDOWN, REMOVE_TRACKED_COOLDOWN

-- Dont create an entry for a character -> cooldownId until we see that character actually
-- succesfully cast the proffession cooldown (item or spell)
aura_env.onEvent = function(allstates, event, ...)
    if aura_env.saved and aura_env.saved.cooldownsByCharacter then
        if event == "PLAYER_ENTERING_WORLD"
            or event == "OPTIONS" or event == "STATUS"
        then
            -- these will always check for cooldowns
            -- regardless of it being saved or not 
            aura_env.syncSavedCooldowns()
            aura_env.syncSavedSpellCooldowns()
            return aura_env.setAllStates(allstates)
        elseif event == "SPELL_UPDATE_COOLDOWN"
            and aura_env.checkOnCooldownUpdate
        then
            -- This event fires shortly after SPELL_CAST_ events
            -- client is not updated with new cooldown info until after this event
            if aura_env.debug then print("SPELL_UPDATE_COOLDOWN:", aura_env.checkOnCooldownUpdate) end
            local spellID = aura_env.checkOnCooldownUpdate
            local cooldownInfo = aura_env.getCooldownInfo(spellID)
            if cooldownInfo then
                aura_env.updateCooldownInfo(spellID, cooldownInfo)
                local key = aura_env.currentCharacter .. "-" .. tostring(spellID)
                aura_env.checkOnCooldownUpdate = nil
                return aura_env.setStateForSpell(allstates, key, spellID)
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED"
            and select(2, ...) == "SPELL_CAST_SUCCESS"
        then
            local timeCast = select(1, ...)
            local sourceGUID = select(4, ...)
            local spellName = select(13, ...)
            local spellID = aura_env.trackedSpellNames[spellName]
            if UnitGUID("player") == sourceGUID and spellID
            then
                aura_env.checkOnCooldownUpdate = spellID
            end
        elseif event == "REMOVE_TRACKED_COOLDOWN" then
            local key = ...
            local character, spellID = strsplit("-", key)
            if character and spellID then
                aura_env.saved.cooldownsByCharacter[character][spellID] = nil
                aura_env.setStateForSpell(allstates, key, spellID)
                return true
            end
        end
    end
end
aura_env.syncSavedCooldowns = function()
    local savedCooldowns = aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter]
    for spellID, _  in pairs(savedCooldowns) do
            local cooldownInfo = aura_env.getCooldownInfo(spellID)
            if cooldownInfo then
                aura_env.updateCooldownInfo(spellID, cooldownInfo)
            end
        end
end
-- differnece here is that if no cooldown info is found 
-- we nil the entry in the saved db instead of skipping it
-- this is probably not the correct behaviour but im using it for now
-- for the sake of being able to test the mechanism that only adds to saved when you first cast the spell
aura_env.syncSavedSpellCooldowns = function()
    local savedCooldowns = aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter]
    for spellID, _ in pairs(savedCooldowns) do
        local cooldownInfo = aura_env.getCooldownInfo(spellID)
        aura_env.updateCooldownInfo(spellID, cooldownInfo)
    end
end
aura_env.getCooldownInfo = function(spellID)
    if not spellID then return nil end
    local info
    local savedInfo = aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter][spellID]
    local itemID = aura_env.spellToItem[spellID]
    if itemID then
        if aura_env.debug then print("associated item id found") end
        local bagId, slotId, itemInfo = aura_env.searchBagForItem(itemID)
        if bagId and slotId and itemInfo then
            local lastCast, duration, _ = C_Container.GetContainerItemCooldown(bagId, slotId)
            if lastCast == 0 and savedInfo then
                lastCast = savedInfo.lastCast
            end
            if aura_env.debug then print("lastCast: ", lastCast, "duration: ", duration) end
            if lastCast > 0 and duration > 0 then
                info = {
                    expirationTime = lastCast + duration,
                    lastCast = lastCast,
                    duration = duration,
                    icon = itemInfo.iconFileID,
                    name = itemInfo.itemName,
                    fromItem = true,
                    owner = aura_env.currentCharacter,
                    spellID = spellID,
                    itemID = itemID,
                }
            end
        end
    else
        local lastCast, duration = GetSpellCooldown(spellID)
        if lastCast == 0 and savedInfo then
            lastCast = savedInfo.lastCast
        end
        if duration == 0 then
            duration = (GetSpellBaseCooldown(spellID) or 0) / 1000
        end
        if lastCast > 0 and duration > 0 then
            local spellName, _, icon = GetSpellInfo(spellID)
            info = {
                expirationTime = lastCast + duration,
                lastCast = lastCast,
                duration = duration,
                icon = icon,
                name = spellName,
                fromItem = false,
                spellID = spellID,
                owner = aura_env.currentCharacter,
            }
        end
    end
    if info then
        ViragDevTool:AddData(info, "info for " .. info.name)
        return info
    end
end
aura_env.updateCooldownInfo = function(spellID, cooldownInfo)
    if spellID then
        aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter]
        [spellID] = cooldownInfo
    end
end
aura_env.setAllStates = function(allstates)
    for character, cooldowns in pairs(aura_env.saved.cooldownsByCharacter) do
        for itemID, cooldownInfo in pairs(cooldowns) do
            local key = character .. "-" .. tostring(itemID)
            allstates[key] = CopyTable(cooldownInfo)
            allstates[key].show = true
            allstates[key].changed = true
            allstates[key].progressType = "timed"
            allstates[key].autoHide = false
        end
    end
    ViragDevTool:AddData(allstates, "all cooldown states")
    ViragDevTool:AddData(aura_env.saved.cooldownsByCharacter, "cooldowns db")
    return true
end
aura_env.setStateForSpell = function(states, key, spellID)
    local characterCooldowns = aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter]
    if characterCooldowns then
        local cooldownInfo = characterCooldowns[spellID]
        if cooldownInfo then
            states[key] = CopyTable(cooldownInfo)
            states[key].show = true
            states[key].changed = true
            states[key].progressType = "timed"
            states[key].autoHide = false
            if aura_env.debug then print("Item added to states with key: ", key) end
            return true
        else
            if aura_env.debug then print("Item has no duration. no state made") end
        end
    end
end
aura_env.searchBagForItem = function(itemID)
    if not itemID then return nil end
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info
                and info.itemID == itemID
            then
                return bag, slot, info
            end
        end
    end
end
aura_env.setClickHandler = function()
    ViragDevTool:AddData(aura_env.state, "state")
    if aura_env.state and aura_env.state.spellID then
        local key = aura_env.currentCharacter .. "-" .. tostring(aura_env.state.spellID)

        print(button)
        button:SetScript("PostClick", function(self, button, down)
            local region = self:GetParent()
            print("button")
            if button == "RightButton" and IsLeftShiftKeyDown() and not down then
                print("should remove ", key)
                -- WeakAuras.ScanEvents("REMOVE_TRACKED_COOLDOWN", region.clondId)
            end
        end)
    end
end
aura_env.formatTime = function(expirationTime, duration)
local remaining = expirationTime - GetTime()
    if remaining > 0 then
        local minutes = floor(remaining / 60)
        local minutes = minutes == 0 and format("%.1f", remaining / 60) or minutes
        local seconds = remaining - (minutes * 60)
        if minutes > 0 then
            return string.format("%dm %ds", minutes, seconds)
        else
            return string.format("%ds", seconds)
        end
    else
        return ""
    end
end




