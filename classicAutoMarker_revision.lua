--- Maps npcID -> "default" -> npc num -> assigned raid marker
---@type {[npcID]: {default: {[integer]: RaidMarkerIndex}}}}
local trackedEnemies = {}
---@type table<RaidMarkerIndex, unitGUID|boolean>
aura_env.activeMarks = {
    [1] = false, [2] = false, [3] = false, [4] = false,
    [5] = false, [6] = false, [7] = false, [8] = false,
}

---Release a raider marker making it available for use again.
---@param markIdx RaidMarkerIndex
aura_env.releaseMark = function(markIdx) aura_env.activeMarks[markIdx] = false end
---Release all marks for usage.
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

---Wrapper function to maintain the `activeMarks` table.
aura_env.setRaidTarget = function(unit, index)
    -- if the target is already marked with the same mark, do nothing.
    -- default wow behaviour is to clear the mark.
    if GetRaidTargetIndex(unit) == index then return end

    print("setting mark", _G["COMBATLOG_ICON_RAIDTARGET" .. index], "on unit", UnitName(unit) .. UnitGUID(unit))
    local unitGUID = UnitGUID(unit)
    if unitGUID then
        local activeGUIDs = tInvert(aura_env.activeMarks)
        local oldMarkIdx = activeGUIDs[unitGUID]
        if oldMarkIdx then
            if oldMarkIdx == index then return end
            aura_env.releaseMark(oldMarkIdx)
            print("oldMark", _G["COMBATLOG_ICON_RAIDTARGET" .. oldMarkIdx])
        end
        aura_env.activeMarks[index] = unitGUID
    else
        print("SetRaidTarget: unitGUID not found")
    end
    return _G.SetRaidTarget(unit, index)
end
---Populates the `enemies` table with the npcIDs, and assigned raid marker(s) for each npcID. Uses values set in the `aura_env.config` group options.
aura_env.updateTrackedEnemies = function()
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
                trackedEnemies[npcID] = { default = {} }
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
                    local enemyConfig = trackedEnemies[npcID]
                    if enemyConfig then
                        assert(
                            enemyConfig.default,
                            aura_env.id .. ": Tried to assign marker(s) for an NPC not yet seen in options table."
                        )
                        enemyConfig.default[priorityIdx] = marker
                    end
                end
            end
        end
    end
    local _, _, _, _, maxPlayers = GetInstanceInfo()
    if aura_env then
        if aura_env.config.optMC then
            trackedEnemies = {}
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

---Finds(and locks if available) a valid & available raid marker for the given unit.
---@param unit string
---@return RaidMarkerIndex? `nil` if no raid marker available/set for unit
aura_env.getAvailableMarkerForUnit = function(unit)
    local unitGUID = UnitGUID(unit) or ""
    local _, _, _, _, _, npcID, spawnUID = strsplit("-", unitGUID)
    npcID = tonumber(npcID)
    if npcID and trackedEnemies[npcID] then
        print("getAvailableMarkerForUnit: " .. npcID)
        -- There can be multiple marker entries for the same npc, so we need to check all of them.
        -- used for packs with multiple mobs of the same npcID
        local npcPriorityList = trackedEnemies[npcID].default

        -- Setting a max here caused an error when `npcPriorityList[priority]` returns `nil` and is then used to index `activeMarks`.
        -- local maxPriority = math.max(3, #npcPriorityList)

        -- Setting a min here means that only the first 3 prio'd markers in options will ever be released.
        -- local maxPriority = math.min(3, #npcPriorityList)

        -- This will release all assigned priority markers.
        local maxPriority = #npcPriorityList

        local canReleaseMarks = (not aura_env.config.optLockAfterUse) or false

        ---Release any active marks which are being used that this NPC type is set to use.
        local releaseActiveMarksForNPC = function()
            for priority = 1, maxPriority do
                local assignedMark = npcPriorityList[priority]
                aura_env.releaseMark(assignedMark)
            end
        end


        if npcPriorityList then
            for priorityIdx = 1, maxPriority do
                local priorityMarker = npcPriorityList[priorityIdx]

                -- if npc not marked by the time we hit the last availble marker in the prio list, release all marks for this npc type
                if canReleaseMarks and priorityIdx == maxPriority then
                    releaseActiveMarksForNPC()
                end
                -- This will reassign the last prio mark for this npc type
                -- whenever executed after `releaseActiveMarksForNPC` is called.
                if aura_env.activeMarks[priorityMarker] == false then
                    return priorityMarker
                else
                    if aura_env.config.overrideMarks
                        and aura_env.activeMarks[priorityMarker] == unitGUID
                    then
                        -- dont override mark with a lower priority if unit currently has one.
                        local currentPrio = tInvert(npcPriorityList)[priorityMarker]
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
            print("no available markers for npc")
            DevTool:AddData(aura_env.activeMarks , "activeMarks None avail")
        else
            print("no npcPriorityList")
        end
        print("no marker found")
    end
end

---This function ignores locked markers and cycles/marks the given unit with any marker assigned to it. Starts at the first free marker or the unit's current marker.
---@param unit string UnitToken
aura_env.cycleMarkersForUnit = function(unit)
    print("cycleMarkersForUnit")
    local unitGUID = UnitGUID(unit) or ""
    local _, _, _, _, _, npcID, spawnUID = strsplit("-", unitGUID)
    npcID = tonumber(npcID)
    print("npcID", npcID)
    if npcID and trackedEnemies[npcID] then
        local npcPriorityList = trackedEnemies[npcID].default
        if npcPriorityList then
            local previousMark, priorityIdx = (function()
                for priorityIdx = 1, #npcPriorityList do
                    local npcPriorityMark = npcPriorityList[priorityIdx]
                    if aura_env.activeMarks[npcPriorityMark] == unitGUID then
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
                -- assign it next available mark
                local markIdx = aura_env.getAvailableMarkerForUnit(unit)
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
local throttle = 0.25 -- sec
---Attempts to marks the current mouseover unit with the appropriate raid marker.
aura_env.onMouseOverUpdate = function()
    local currentTime = GetTime()
    if currentTime > lastUpdate + throttle then
        lastUpdate = currentTime
        -- check for marking permissions
        if (CanGroupInvite() -- permission requirements as inviting
                or (UnitIsGroupAssistant("player")
                    or UnitIsGroupLeader("player")
                    or not IsInRaid()))
            and (aura_env.config.overrideMarks
                and true
                or GetRaidTargetIndex("mouseover") == nil)
        then
            local markIdx = aura_env.getAvailableMarkerForUnit("mouseover")
            if markIdx then
                aura_env.setRaidTarget("mouseover", markIdx)
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
        and UnitIsEnemy("player", "mouseover")
    then
        return aura_env.onMouseOverUpdate()
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
        return aura_env.releaseAllMarks()
    end
    if event == "OPTIONS" then
        return aura_env.updateTrackedEnemies()
    end

    if event == "MODIFIER_STATE_CHANGED"
        and aura_env.config.optCycle
        and ... == modifierMap[aura_env.config.ddCycleModifier]
        and select(2, ...) == 0 -- 0: onKeyUp, 1: onKeyDown
    then
        -- make sure the cycle and modifier keys are not the same
        if aura_env.config.ddCycleModifier ~= aura_env.config.ddModifer then
            if aura_env.isModifierPressed() then return aura_env.cycleMarkersForUnit("target") end
        end
    end
end
---Helper function use to reset the in-game raid markers.
local clearAllMarkers = function()
    for i = 1, 8 do SetRaidTarget("player", i) end
    SetRaidTarget("player", 0)
end
-- Create a button to **release** all marks with `/click CAM`. This will not "clear" the marks, but will make them available for use again.
local buttonID = "CAM"
if not _G[buttonID] then
    local ResetBtn = CreateFrame("Button", buttonID, nil, "SecureActionButtonTemplate")
    ResetBtn:RegisterForClicks("AnyUp")
    ResetBtn:SetAttribute("type", "macro")
    ResetBtn:HookScript('OnClick', function()
        WeakAuras.ScanEvents("RELEASE_ALL_RAID_TARGETS")
        if IsLeftControlKeyDown() then
            print("Marks Cleared")
            clearAllMarkers()
        end
        -- clearAllMarkers() -- uncomment to clear marks as well
    end)
end

-- init the tracked enemies table on load
aura_env.updateTrackedEnemies()
DevTool:AddData(trackedEnemies, "trackedEnemies")
DevTool:AddData(aura_env.activeMarks, "activeMarks")
---@alias RaidMarkerIndex 1|2|3|4|5|6|7|8
---@alias npcID number
---@alias unitGUID string

-- Cycle through assigned markers for target NPC by pressing the cycle key while the modifier key is pressed. (Does not work if set to same key type).

-- Allows you to remark units with already existing marks if a higher priority mark is available to be used.
