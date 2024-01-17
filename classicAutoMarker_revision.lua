--- Maps npcID -> "default" -> npc num -> assigned raid marker
---@type {[npcID]: {default: {[integer]: RaidMarkerIndex}}}}
local enemiesConfig = {}

---For context, an inactive mark means that this addon is free to use it for marking whenever a mouseover unit is found to be a valid target. (ie its in the options and uses a marker that is not "locked" or active).
---Releasing a mark, simply means unlocked or making it de-active. No removal of the actual mark is done.
---So a mark can be unlocked|released|inactive, but still be visible on a unit.
---@type table<RaidMarkerIndex, unitGUID|boolean>
aura_env.activeMarks = {
    [1] = false, [2] = false, [3] = false, [4] = false,
    [5] = false, [6] = false, [7] = false, [8] = false,
}

---Release a raid marker making it available for use again.
---@param markIdx RaidMarkerIndex
aura_env.releaseMark = function(markIdx)
    if (markIdx < 1) or (markIdx > 8) then return end
    aura_env.activeMarks[markIdx] = false
end

---Release all marks for re-usage.
aura_env.releaseAllMarks = function()
    for i = 1, 8 do aura_env.activeMarks[i] = false end
    DevTool:AddData(aura_env.activeMarks, "activeMarks after release")
end

---Checks if the currently set modifier key is currently pressed.
---@return boolean `true` if the key is pressed.
aura_env.isModifierPressed = function()
    local modCheckFunctions = {
        [1] = IsAltKeyDown,
        [2] = IsControlKeyDown,
        [3] = IsShiftKeyDown,
    }
    local modKey = tonumber(aura_env.config.ddModifer) or 2
    return modCheckFunctions[modKey]()
end

---Helper to get the npcID from a unitGUID.
---@param unit string `UnitToken|UnitGUID`
---@return npcID? number `nil` if not an npc.
aura_env.getUnitNpcID = function(unit)
    local unitGUID = UnitGUID(unit) or unit
    local npcID = select(6, strsplit("-", unitGUID))
    return tonumber(npcID)
end

aura_env.isValidUnit = function(unit)
    local npcID = aura_env.getUnitNpcID(unit)

    return npcID and enemiesConfig[npcID]
        and UnitIsEnemy("player", unit)
end
---Wrapper function to maintain the `activeMarks` table.
---@param unit string UnitToken
---@param index RaidMarkerIndex 1-8
aura_env.setRaidTarget = function(unit, index)
    -- if the target is already marked with the same mark, do nothing.
    -- default wow behaviour is to clear the mark.
    if GetRaidTargetIndex(unit) == index then return end
    local unitGUID = UnitGUID(unit)
    if unitGUID then
        local activeGUIDs = tInvert(aura_env.activeMarks)
        local oldMarkIdx = activeGUIDs[unitGUID]
        if oldMarkIdx then
            aura_env.releaseMark(oldMarkIdx)
            print("oldMark", _G["COMBATLOG_ICON_RAIDTARGET" .. oldMarkIdx])
        end
        aura_env.activeMarks[index] = unitGUID
    end
    print("setting mark", _G["COMBATLOG_ICON_RAIDTARGET" .. index], "on unit " .. UnitName(unit))
    return _G.SetRaidTarget(unit, index)
end

---Populates the `enemiesConfig` table with the npcIDs, and assigned raid marker(s) for each npcID. Uses values set in the `aura_env.config` group options.
aura_env.updateEnemyConfig = function()
    local setTrackedEnemies = function(optsTable)
        -- Set the keys for the *enabled* npcIds and the default table.
        for k, isEnabled in pairs(optsTable) do
            if k:match("^target-") and isEnabled then
                local _, npcID = string.match(k or "", "(.*)-(.*)")
                npcID = tonumber(npcID)
                assert(
                    npcID,
                    aura_env.id ..
                    ": Format error in Options key for tracked enemy. use `target-{npcID}`, without the braces, where npcID is a number."
                )
                enemiesConfig[npcID] = { default = {} }
            end
        end
        -- Add multiple mobs for the same npcId if they exist (priority order)
        -- and the assigned raid marker for each mob prio (set in WA Options)
        for k, marker in pairs(optsTable) do
            if k:match("^p%d+-")
                and type(marker) == "number" and marker < 9
            then
                local priorityIdx, npcID = string.match(k or "", "(%d*)-(.*)")
                priorityIdx, npcID = tonumber(priorityIdx), tonumber(npcID)
                assert(
                    priorityIdx and npcID,
                    aura_env.id ..
                    ": Format error in Options key for tracked enemy. use `p{priority}-{npcID}`(no braces) where priority and npcID are numbers."
                )
                if npcID and priorityIdx then
                    local config = enemiesConfig[npcID]
                    if config then
                        assert(
                            config.default,
                            aura_env.id .. ": Tried to assign marker(s) for an NPC not yet seen in options table."
                        )
                        config.default[priorityIdx] = marker
                    end
                end
            end
        end
    end
    local _, _, _, _, maxPlayers = GetInstanceInfo()
    if aura_env then
        if aura_env.config.optMC then
            enemiesConfig = {}
            if maxPlayers and maxPlayers == 40 then
                setTrackedEnemies(aura_env.config.optMC)
                setTrackedEnemies(aura_env.config.optBWL)
                setTrackedEnemies(aura_env.config.optAQ40)
                setTrackedEnemies(aura_env.config.optNAXX)
            else
                setTrackedEnemies(aura_env.config.optZG)
                setTrackedEnemies(aura_env.config.optAQ20)
            end
        end
    end
end
--TODO-- Refactor this function to  `setNextAvailableMarkForUnit` and use it in `cycleMarkersForUnit` as well.

---Finds(and locks if available) a valid & available raid marker for the given unit.
---@param npcID number
---@param unit UnitToken
---@return RaidMarkerIndex? `nil` if no raid marker available/set for unit
aura_env.getFirstInactiveMarkForNPC = function(npcID, unit)
    if enemiesConfig[npcID] then
        -- There can be multiple marker entries for the same npc, so we need to check all of them.
        -- used for packs with multiple mobs of the same npcID
        local npcPriorityList = enemiesConfig[npcID].default

        -- Setting a max here caused an error when `npcPriorityList[priority]` returns `nil` and is then used to index `activeMarks`.
        -- local maxPriority = math.max(3, #npcPriorityList)

        -- Setting a min here means that only the first 3 prio'd markers in options will ever be released.
        -- local maxPriority = math.min(3, #npcPriorityList)

        -- This will release all assigned priority markers.
        local maxPriorityIdx = #npcPriorityList

        --- TODO -- remove this side effect and handle this in the calling function.
        local canReleaseMarks = (not aura_env.config.optLockAfterUse) or false
        ---Release any active marks which are being used that this NPC type is set to use.
        ---@param limit number? # optional, if set, will only release this amount of marks.(released from least to highest prio)
        local releaseNPCPriorityMarkers = function(limit)
            limit = limit and
                -- take min to avoid out of bounds error.
                math.min(limit, maxPriorityIdx)
                or 0
            -- reverse loop to release marks from lowest to highest prio
            for prioIdx = maxPriorityIdx, (maxPriorityIdx - limit + 1), -1 do
                local assignedMark = npcPriorityList[prioIdx]
                assert(
                    assignedMark,
                    (aura_env.id .. ": Tried to access a priority mark that was not assigned to this npc type. total: %d, idx: %d")
                    :format(maxPriorityIdx, prioIdx)
                )
                aura_env.releaseMark(assignedMark)
            end
        end
        -------

        if npcPriorityList then
            local prioForMarker = tInvert(npcPriorityList)
            print("getAvailableMarkerForUnit: " .. npcID)
            for priorityIdx = 1, maxPriorityIdx do
                local priorityMarker = npcPriorityList[priorityIdx]

                -- if npc not marked by the time we hit the last availble marker in the prio list, release all marks for this npc type
                if canReleaseMarks and priorityIdx == maxPriorityIdx then
                    releaseNPCPriorityMarkers(3)
                end
                -- This will reassign the last prio mark for this npc type
                -- whenever executed after `releaseActiveMarksForNPC` is called.
                if aura_env.activeMarks[priorityMarker] == false then
                    return priorityMarker
                else
                    --- TODO ---
                    -- move this out of this function and into the calling function.
                    if aura_env.config.overrideMarks
                        and aura_env.activeMarks[priorityMarker] == UnitGUID(unit)
                    then
                        -- dont override mark with a lower priority if unit currently has one.
                        local currentPrio = prioForMarker[priorityMarker]
                        if priorityIdx >= currentPrio then
                            print("npc arleady has highest prio mark available for it " ..
                                _G["COMBATLOG_ICON_RAIDTARGET" .. priorityMarker])
                            return
                        end
                        -- higher index = lower prio, return when priority index exceeds current prio, ie a lower prio mark is found.
                    end
                    print("mark " .. _G["COMBATLOG_ICON_RAIDTARGET" .. priorityMarker] .. " already in use")
                end
            end
            print("no available markers for this npc")
            DevTool:AddData(aura_env.activeMarks, "activeMarks None avail")
        end
    end
end
-- Get next (lower) priority marker that is not already assigned to a unit of the same type as the passed unit.
---@param unit string
---@param forceNext boolean? # optional, if set, will return the next marker in the priority list even if it is already assigned to any other unit.
---@return RaidMarkerIndex? `nil` if all priority markers already used on this npc type.
aura_env.getNextUnsetPriorityMarkerOnUnit = function(unit, forceNext)
    --- get priority  table for npc id
    local npcID = aura_env.getUnitNpcID(unit)
    if npcID and enemiesConfig[npcID] then
        local npcPriorityList = enemiesConfig[npcID].default
        if npcPriorityList then
            --- get markers for priority table entries
            for priority, marker in pairs(npcPriorityList) do
                --- check active marks for each marker
                --- return first marker thats free or has a different npcID
                if (aura_env.activeMarks[marker] == false)
                    or forceNext 
                then
                    return marker
                else
                    local currentMarkNpcID = aura_env
                        .getUnitNpcID(aura_env.activeMarks[marker])
                    if currentMarkNpcID ~= npcID then
                        return marker
                    end
                end
            end
        end
    end
end

---This function ignores locked markers and cycles/marks the given unit with any marker assigned to it. Starts at the first free marker **for this unit** or the unit's current marker.
---@param unit string UnitToken
---@param startIdx number? # optional, priority index to start at. If not set, will start at the unit's current marker.
aura_env.cyclePriorityMarkersForUnit = function(unit, startIdx)
    local npcID = aura_env.getUnitNpcID(unit)
    if npcID and enemiesConfig[npcID] then
        local npcPriorityList = enemiesConfig[unit].default
        if npcPriorityList then
            print("cycleMarkersForUnit: " .. unit)
            local previousMark, priorityIdx = (function()
                if startIdx then
                    return npcPriorityList[startIdx], startIdx
                end
                for priorityIdx = 1, #npcPriorityList do
                    local npcPriorityMark = npcPriorityList[priorityIdx]
                    if aura_env
                        .activeMarks[npcPriorityMark] == UnitGUID(unit)
                    then
                        return npcPriorityMark, priorityIdx
                    end
                end
            end)()
            if previousMark then -- update the mark to the next in the list
                local totalIndices = #npcPriorityList
                local newIndex = priorityIdx % totalIndices + 1
                local nextMark = npcPriorityList[newIndex]

                -- calling `SetRaidTarget` with the same arguments will clear the mark, so we need to check for that to not clear marks on npcs with 1 prio only.
                if nextMark ~= previousMark then
                    aura_env.releaseMark(previousMark)
                    aura_env.setRaidTarget(unit, nextMark)
                end
            else
                -- assign it next unused priority mark by this unit's npc type
                local markIdx = aura_env.getNextUnsetPriorityMarkerOnUnit(unit)
                if markIdx then
                    return aura_env.setRaidTarget(unit, markIdx)
                else
                    -- if no marks available, assign the highest priority mark
                    local npcPriorityMark = npcPriorityList[1]
                    return aura_env.setRaidTarget(unit, npcPriorityMark)
                end
            end
        end
    end
end

local lastUpdate = GetTime()
local lastOverrideUnit
local throttle = 0.25 -- sec
---Attempts to marks the current mouseover unit with the appropriate raid marker.
aura_env.onValidMouseoverUnit = function()
    local currentTime = GetTime()
    if currentTime > lastUpdate + throttle then
        lastUpdate = currentTime
        -- check for marking permissions
        if (CanGroupInvite() -- permission requirements as inviting
                or (UnitIsGroupAssistant("player")
                    or UnitIsGroupLeader("player")
                    or not IsInRaid()))
        then
            local currentMark = GetRaidTargetIndex("mouseover")
            local npcID = aura_env.getUnitNpcID("mouseover")
            if not npcID then return end

            if not currentMark then -- no mark set, look for first match.
                local markIdx = aura_env
                    .getFirstInactiveMarkForNPC(npcID, "mouseover")
                if not markIdx then return end

                aura_env.setRaidTarget("mouseover", markIdx)
            elseif aura_env.config.overrideMarks -- else, look for higher prio mark.
                and not lastOverrideUnit == UnitGUID("mouseover")
            then
                local markIdx = aura_env
                    .getFirstInactiveMarkForNPC(npcID, "mouseover")
                -- only override with a higher priority mark (lower idx)
                if markIdx and markIdx < currentMark then
                    aura_env.setRaidTarget("mouseover", markIdx)
                    lastOverrideUnit = UnitGUID("mouseover")
                end
            end
        end
    end
end
local modifierMap = {
    [1] = "LALT",
    [2] = "LCTRL",
    [3] = "LSHIFT",
}

-- Main event handler
-- events: UPDATE_MOUSEOVER_UNIT, PLAYER_REGEN_ENABLED, PLAYER_ENTERING_WORLD, CLEU:UNIT_DIED, OPTIONS, MODIFIER_STATE_CHANGED, RELEASE_ALL_RAID_TARGETS
aura_env.onEvent = function(event, ...)
    if (not aura_env.config.optModifier or aura_env.isModifierPressed())
        and event == "UPDATE_MOUSEOVER_UNIT"
        and aura_env.isValidUnit("mouseover")
    then
        return aura_env.onValidMouseoverUnit()
    end
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
        return aura_env.releaseAllMarks()
    end
    -- See if a dead unit has a raid marker bitfield set and reset the mark.
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, _, _, _, destRaidFlags = ...
        if subEvent == "UNIT_DIED" then
            local raidFlag = tonumber(destRaidFlags) or 0
            local markIdx = 1 + math.log10(raidFlag) / math.log10(2)
            if markIdx > 0 and markIdx < 9 then
                return aura_env.releaseMark(markIdx)
            end
        end
    end
    if event == "RELEASE_ALL_RAID_TARGETS" then
        if aura_env.config.clearMarksOnRelease then
            aura_env.releaseAllMarks()
            aura_env.clearAllMarkers()
            print("All Raid Markers Cleared!")
        else
            aura_env.releaseAllMarks()
            print("All Raid Markers Released.")
        end
        return
    end
    if event == "OPTIONS" then
        return aura_env.updateEnemyConfig()
    end
    if event == "MODIFIER_STATE_CHANGED"
        and aura_env.config.optCycle
        and ... == modifierMap[aura_env.config.ddCycleModifier]
        and select(2, ...) == 0 -- 0: onKeyUp, 1: onKeyDown
    then
        -- make sure the cycle and modifier keys are not the same
        if aura_env.config.ddCycleModifier ~= aura_env.config.ddModifer 
        and aura_env.isModifierPressed()
        and aura_env.isValidUnit("target")
        then
            return aura_env.cyclePriorityMarkersForUnit("target")
        end
    end
end
---Helper function use to reset the in-game raid markers.
aura_env.clearAllMarkers = function()
    for i = 1, 8 do SetRaidTarget("player", i) end
    SetRaidTarget("player", 0)
end
-- Create a button to "release" all marks with `/click CAM`. (it just send an event for the wa to handle)
local buttonID = "CAM"
if not _G[buttonID] then
    local ResetBtn = CreateFrame("Button", buttonID, nil, "SecureActionButtonTemplate")
    ResetBtn:RegisterForClicks("AnyUp")
    ResetBtn:SetAttribute("type", "macro")
    ResetBtn:HookScript('OnClick', function()
        WeakAuras.ScanEvents("RELEASE_ALL_RAID_TARGETS")
    end)
end

-- init the tracked enemies table on load
aura_env.updateEnemyConfig()
DevTool:AddData(enemiesConfig, "trackedEnemies")
DevTool:AddData(aura_env.activeMarks, "activeMarks")
---@alias RaidMarkerIndex 1|2|3|4|5|6|7|8
---@alias npcID number
---@alias unitGUID string

-- Cycle through assigned markers for target NPC by pressing the cycle key while the modifier key is pressed. (Does not work if set to same key type).

-- Allows you to remark units with already existing marks if a higher priority mark is available to be used.
