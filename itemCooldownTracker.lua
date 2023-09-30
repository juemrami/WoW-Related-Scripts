aura_env.trackedItems = {
    11020, -- Evergreen Pouch
    15846, -- Salt Shaker
}
aura_env.trackedSpells = {
    18560, -- Mooncloth
}
aura_env.transmutes = {
    25146, -- Transmute: Elemental Fire
    17187, -- Transmute: Arcanite
}
aura_env.debug = true
if not aura_env.saved then
    aura_env.saved = {
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
    in ipairs({ aura_env.trackedSpells, aura_env.transmutes })
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
                aura_env.addToCharacterCooldowns(spellID, cooldownInfo)
                local key = aura_env.currentCharacter .. "-" .. tostring(spellID)
                aura_env.checkOnCooldownUpdate = nil
                aura_env.setAllStates(allstates)
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED"
            and select(2, ...) == "SPELL_CAST_SUCCESS"
        then
            local sourceGUID = select(4, ...)
            local spellName = select(13, ...)
            local spellID = aura_env.trackedSpellNames[spellName]
            if UnitGUID("player") == sourceGUID and spellID
            then
                aura_env.checkOnCooldownUpdate = spellID
            end
        elseif event == "REMOVE_TRACKED_COOLDOWN" then
            local key = ...
            local name, realm , spellID = strsplit("-", key)
            print(key)
            if name and realm and spellID then
                local character = name .. "-" .. realm
                aura_env.saved.cooldownsByCharacter[character][spellID] = nil
                return aura_env.setAllStates(allstates)
            end
        end
    end
end
aura_env.syncSavedCooldowns = function()
    local savedCooldowns = aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter]
    for spellID, _ in pairs(savedCooldowns) do
        local cooldownInfo = aura_env.getCooldownInfo(spellID)
        if cooldownInfo then
            aura_env.addToCharacterCooldowns(spellID, cooldownInfo)
        end
    end
end
-- differnece here is that if no cooldown info is found
-- we nil the entry in the saved db instead of skipping it
-- this is probably not the correct behaviour but im using it for now
-- for the sake of being able to test the mechanism that only adds to saved when you first cast the spell
aura_env._syncSavedSpellCooldowns = function()
    local savedCooldowns = aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter]
    for spellID, _ in pairs(savedCooldowns) do
        local cooldownInfo = aura_env.getCooldownInfo(spellID)
        aura_env.addToCharacterCooldowns(spellID, cooldownInfo)
    end
end

aura_env.getCooldownInfo = function(spellID)
    if not spellID then return nil end
    local info
    local savedInfo = aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter][spellID]
    local itemID = aura_env.spellToItem[spellID]
    if itemID then
        local bagId, slotId, itemInfo = aura_env.searchBagForItem(itemID)
        if bagId and slotId and itemInfo then
            if aura_env.debug then print("associated item id found: ", itemID) end
            local lastCast, duration, _ = C_Container.GetContainerItemCooldown(bagId, slotId)
            if savedInfo then
                lastCast = math.max(savedInfo.lastCast, lastCast)
                duration = savedInfo.duration
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
        if savedInfo then
            lastCast = math.max(savedInfo.lastCast, lastCast)
            duration = savedInfo.duration
        end
        -- this might not be neccessary
        if duration < 1 then
            duration = (GetSpellBaseCooldown(spellID) or 0) / 1000
        end
        if lastCast > 0 then
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
aura_env.addToCharacterCooldowns = function(spellID, cooldownInfo)
    if spellID then
        aura_env.saved.cooldownsByCharacter[aura_env.currentCharacter]
        [spellID] = cooldownInfo
    end
end
aura_env.setAllStates = function(allstates)
    for character, cooldowns in pairs(aura_env.saved.cooldownsByCharacter) do
        for spellID, cooldownInfo in pairs(cooldowns) do
            local key = character .. "-" .. tostring(spellID)
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
    local name, realm = strsplit("-", key)
    if not name or not realm or not spellID then return nil end
    local character = name .. "-" .. realm
    local characterCooldowns = aura_env.saved.cooldownsByCharacter[character]
    if characterCooldowns then
        local cooldownInfo = characterCooldowns[spellID]
        if cooldownInfo then
            states[key] = CopyTable(cooldownInfo)
            states[key].show = true
            states[key].changed = true
            states[key].progressType = "timed"
            states[key].autoHide = false
            if aura_env.debug then print("Item added to states with key: ", key) end
        else
            if aura_env.debug then print("Item has no duration. no state made") end
            states[key] = {
                show = false,
                changed = true,
            }
         end
        return true
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
    if aura_env.state and aura_env.state.spellID and aura_env.region.icon then
        aura_env.region:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" and IsLeftShiftKeyDown() then
                print("removing cooldown: ", self.cloneId)
                WeakAuras.ScanEvents("REMOVE_TRACKED_COOLDOWN", self.cloneId)
            end
        end)
    end
end

-- function that prints out NdNhNs from a duration in seconds
-- if days is 0 it will not be printed
--
aura_env.formatTime = function(expirationTime, duration, ...)
    if not expirationTime or not duration then return "" end
    local remaining = expirationTime - GetTime()
    local str = ""
    if remaining > 0 then
        local days = math.floor(remaining / (60 * 60 * 24))
        if days >= 1 then
            remaining = remaining - (days * 60 * 60 * 24)
            str = str .. days .. "d"
        end
        local hours = math.floor(remaining / (60 * 60))
        if hours >= 1 then
            remaining = remaining - (hours * 60 * 60)
            str = str .. hours .. "h"
        end
        local minutes = math.floor(remaining / 60)
        if minutes >= 1  and days < 1 then
            remaining = remaining - (minutes * 60)
            str = str .. minutes .. "m"
        end
        local seconds = remaining
        if seconds > 0 and minutes < 5 and days < 1 and hours < 1 then
            if seconds < 5 and minutes == 0 then
                str = str .. string.format("%.1f", seconds) .. "s"
            else
                str = str .. math.floor(seconds) .. "s"
            end
        end
    end
    return str
end