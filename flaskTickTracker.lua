aura_env.DIAMOND_FLASK = "Diamond Flask"
aura_env.DIAMOND_FLASK_DURATION = 60     -- 1min
aura_env.DIAMOND_FLASK_COOLDOWN = 60 * 6 -- 6min
aura_env.DIAMOND_FLASK_TICK_INTERVAL = 5 -- 5sec
aura_env.DIAMOND_FLASK_ICON = 132788

if aura_env.config.whitelist ~= "" then
    ---@type table<string, boolean|number>
    aura_env.whitelist = {}
    local length = 0
    for _, name in ipairs({ strsplit(",", aura_env.config.whitelist or "") }) do
        name = strtrim(name)
        if name ~= "" then
            aura_env.whitelist[name] = true
            length = length + 1
        end
    end
    aura_env.whitelist.length = length
end

-- events: CLEU:SPELL_AURA_APPLIED:SPELL_PERIODIC_HEAL:SPELL_AURA_REMOVED:UNIT_DIED, WA_DIAMOND_FLASK_TICK
aura_env.onEvent = function(states, event, ...)
    local subEvent = select(2, ...)
    local sourceGUID, sourceName = select(4, ...)
    local spellName = select(13, ...)
    local anyChanged 
    if spellName == aura_env.DIAMOND_FLASK then
        if subEvent == "SPELL_AURA_APPLIED" then
            local sourceUnit = aura_env.getValidUnit(sourceName, sourceGUID)
            if sourceUnit then
                local currentTime = GetTime()
                states[sourceGUID] = {
                    show = true,
                    name = spellName,
                    active = true,
                    icon = aura_env.DIAMOND_FLASK_ICON,
                    tickAmount = 0,
                    totalTicks = aura_env.DIAMOND_FLASK_DURATION / aura_env.DIAMOND_FLASK_TICK_INTERVAL,
                    unit = sourceUnit,
                    currentTicks = 0,
                    unitName = sourceName,
                    progressType = "timed",
                    duration = aura_env.DIAMOND_FLASK_TICK_INTERVAL,
                    onCooldown = true,
                    expirationTime = currentTime + aura_env.DIAMOND_FLASK_TICK_INTERVAL,
                    castedAt = currentTime,
                    autoHide = false,
                    lastTick = currentTime,
                    changed = true,
                }
                anyChanged = true
            end
        elseif (subEvent == "SPELL_PERIODIC_HEAL"
            or event == "WA_DIAMOND_FLASK_TICK")
            -- This mock event check is not required. Here for clarity.
            -- The subEvent arg sent as part of the fake event is also "SPELL_PERIODIC_HEAL" so it will pass regardless. 
            and states[sourceGUID]
        then
            local state = states[sourceGUID]
            local currentTime = GetTime()
            -- check if state was already updated
            if currentTime >= state.lastTick + aura_env.DIAMOND_FLASK_TICK_INTERVAL
            then
                local tickAmount = select(15, ...) or state.tickAmount or 0
                local currentTicks = state.currentTicks + 1
                state.show = true
                state.tickAmount = tickAmount
                state.currentTicks = currentTicks
                state.duration = aura_env.DIAMOND_FLASK_TICK_INTERVAL
                state.expirationTime = currentTime + aura_env.DIAMOND_FLASK_TICK_INTERVAL
                state.changed = true
                state.lastTick = currentTime
                if currentTicks < state.totalTicks then
                    local varArgs = { ... }
                    C_Timer.After(
                        aura_env.DIAMOND_FLASK_TICK_INTERVAL, 
                        function()
                            WeakAuras.ScanEvents(
                                "WA_DIAMOND_FLASK_TICK", unpack(varArgs)
                            )
                        end
                    )
                elseif currentTicks == state.totalTicks then
                    if aura_env.config.trackCooldown then
                        local castAt = state.castedAt
                            or currentTime - aura_env.DIAMOND_FLASK_DURATION
                        state.changed = true
                        state.active = false
                        state.duration = aura_env.DIAMOND_FLASK_COOLDOWN
                        state.expirationTime = castAt + aura_env.DIAMOND_FLASK_COOLDOWN
                        state.autoHide = true
                    else
                        states[sourceGUID] = {
                            show = false,
                            changed = true,
                        }
                    end
                end
                anyChanged = true
            end
        elseif subEvent == "SPELL_AURA_REMOVED" and states[sourceGUID] then
            if aura_env.config.trackCooldown then
                local state = states[sourceGUID]
                local castAt = state.castedAt
                    or GetTime() - aura_env.DIAMOND_FLASK_DURATION
                state.changed = true
                state.active = false
                state.duration = aura_env.DIAMOND_FLASK_COOLDOWN
                state.expirationTime = castAt + aura_env.DIAMOND_FLASK_COOLDOWN
                state.autoHide = true
            else
                states[sourceGUID] = {
                    show = false,
                    changed = true,
                }
            end
            anyChanged = true
        end
        -- anyChanged = aura_env.clearStaleStates(states) or anyChanged
        return anyChanged
    end
    if subEvent == "UNIT_DIED" then
        local guid = select(8, ...)
        if states[guid] then
            states[guid] = {
                show = false,
                changed = true,
            }
            return true
        end
    end
    if event == "OPTIONS" then
        aura_env.setDemoState(states)
        return true
    end
end

--- Returns the unit token associated with the name and GUID passed, given that it passes any filters set in the aura config
---@param unitName any
---@param unitGUID any
---@return string? unitToken
aura_env.getValidUnit = function(unitName, unitGUID)
    print("getting unit for ", unitName)
    if unitGUID == WeakAuras.myGUID then
        return "player"
    end
    local unitToken = nil
    if unitName and unitGUID then
        --strip realm name
        unitName = strsplit("-", unitName)
        if aura_env.whitelist 
            and aura_env.whitelist.length > 0
            and not aura_env.whitelist[unitName] 
        then
            print(unitName, " not in whitelist")
            return nil
        end
        local unitHasTankRole = function(unit)
            return GetPartyAssignment("MAINTANK", unit, false)
                or GetPartyAssignment("MAINASSIST", unit, false)
        end
        for unit in WA_IterateGroupMembers() do
            if UnitGUID(unit) == unitGUID then
                print ("found unit ", unitName)
                unitToken = unit
                break
            end
        end
        if unitToken then
            if aura_env.config.onlyShowTanks and UnitInRaid(unitToken) then
                if not unitHasTankRole(unitToken) then
                    print("unit is not a tank")
                    return nil
                end
            end
            print("returning unit ", unitToken, " for ", unitName)
            return unitToken
        end
        print("no match found for ", unitName)
    end
end

--- Just to make it pretty when the WA options are opened
aura_env.setDemoState = function(states)
    local tickHeal = { 9, 69, 123 }
    local tickNum = { 0, 3, 5, 10 }
    local units = { "player", "party1", "target" }
    for _, unit in ipairs(units) do
        local isCooldown =
            aura_env.config.trackCooldown
            and math.random(1, 2) == 1
            and true or false
        local duration = isCooldown and 30 or 6
        local expiration = GetTime() + math.random(duration / 3, duration)
        local unitName = UnitName(unit)
        states[unit] = {
            show = true,
            active = not isCooldown and true or false,
            castedAt = GetTime(),
            onCooldown = isCooldown,
            name = aura_env.DIAMOND_FLASK,
            icon = aura_env.DIAMOND_FLASK_ICON,
            tickAmount = tickHeal[math.random(1, 3)],
            currentTicks = tickNum[math.random(1, 4)],
            totalTicks = aura_env.DIAMOND_FLASK_DURATION / aura_env.DIAMOND_FLASK_TICK_INTERVAL,
            unit = unit,
            unitName = unit and unitName or "Johndoe",
            progressType = "timed",
            duration = duration,
            expirationTime = expiration,
            autoHide = true,
            changed = true,
        }
    end
end
--- not part of init code  do not include  below --
-- aura_env.FLASK_ITEM_ID = 20130
-- aura_env.FLASK_SPELL_ID = 363880
-- aura_env.FLASK_TICK_SPELL_ID = 24427
-- /dump GetPartyAssignment("MAINTANK", "target",  false)
local cv =
{
    expirationTime = true,
    duration = true,
    currentTicks = {
        type = "number",
        display = "Current Tick # (out of 12)",
    },
    tickAmount = {
        type = "number",
        display = "Tick Heal Amount",
    },
    active = {
        type = "bool",
        display = "HoT Active",
    },
    onCooldown = {
        type = "bool",
        display = "On Cooldown",
    },
}
-- function(event, ...)
--     if event == "COMBAT_LOG_EVENT_UNFILTERED" then
--         local args = {...}
--         C_Timer.After(5, 
--         function() WeakAuras.ScanEvents("TEST", unpack(args))
--         end) 
--     end
--     if event == "TEST" then
        -- print(...)
--         DevTool:AddData({...}, "args")
--     end   
-- end

-- returns true if:  The nameplate unit is casting a spell that will end *before* kick is off cooldown or if the unit is not casting
-- (when we should hide the icon)
local cf = function(triggers)
    DevTool:AddData(triggers, "triggers")
    local kickState = triggers[1]
    local nameplateCastState = triggers[2]
    -- 
    local kickReady = kickState.expirationTime <= GetTime()
    local castExpiration = nameplateCastState.expirationTime
    local kickCDExpiration = kickState.expirationTime
    if not kickReady -- kick is not ready
        and (not castExpiration  -- unit is not casting
        or castExpiration < kickCDExpiration) -- cast will end before kick ready
    then
        -- hide the icon
        return true
    end
end

local kr = function(event, triggerNum, triggerStates)
    if triggerNum == 2 then DevTool:AddData(triggerStates, "allstates") end
    -- first trigger is spell cooldown on kick
    if triggerNum == 1 then
        aura_env.kickReady = false -- assume kick not ready
        aura_env.kickCDExpiration = triggerStates[""].expirationTime
        if (not aura_env.kickCDExpiration)
        or aura_env.kickCDExpiration <= GetTime() -- this checks if kick *just* finished CD
        then -- our kick is off cd
            aura_env.kickReady = true
            return true
        end
    elseif triggerNum == 2 then   
        --DevTool:AddData(triggerStates, "allstates")
        if aura_env.kickReady then 
            return true
        end 
        for cloneId, triggerState in pairs(triggerStates) do
            local castExpiration = triggerStates[""].expirationTime
            if aura_env.kickCDExpiration
                and castExpiration -- means unit is currently casting
                and castExpiration > GetTime() -- cast not finishing *right* now
                and castExpiration > aura_env.kickCDExpiration
            then 
                return true
            end
        end
    end
end

-- events: NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED, UNIT_HEALTH, CLEU:SPELL_AURA_APPLIED
local hm = function(states, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local sourceGUID, sourceName = select(4, ...)
            local destGUID, destName = select(8, ...)
            local spellName = select(13, ...)
            if spellName == "Hunter's Mark" 
                and sourceGUID == WeakAuras.myGUID
            then
                states[""] = {
                    show = false,
                    changed = true,
                }
            end
        else
        if event == "NAME_PLATE_UNIT_ADDED" then
            if aura_env.isValidUnit(...) 
            then
                if aura_env.isUnitHealthValid(...) then
                    aura_env.trackedUnits[destGUID] = true
                end
                if (not states[""] or states[""].show == false) 
                    and aura_env.trackedUnits[destGUID] 
                then
                    states[""] = {
                        show = true,
                        changed = true,
                    }
                end
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            aura_env.trackedUnits[UnitGUID(...)] = nil
        elseif event == "UNIT_HEALTH" then end
        
    end
end
end
aura_env.isValidUnit = function(unit)
    if not aura_env.whitelist then
        -- create a whitelist lookup table
    end
    return  not UnitIsFriend("player", unit) 
        and not UnitIsDeadOrGhost(unit)
        -- and aura_env.whitelist[UnitName(unit)] 
end
aura_env.isUnitHealthValid = function(unit)
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local healthPercent = health / maxHealth * 100
    return healthPercent > 80
end
--- Removes any states that may have gone stale. Usually happens when a tracked unit stops receiving heal tick events from the flask (like when they die) and causes their their display to get "stuck"
aura_env.clearStaleStates = function(states)
    local currentTime = GetTime()
    for guid, state in pairs(states) do
        if state.active
            and currentTime > state.castedAt + aura_env.DIAMOND_FLASK_DURATION
            and state.currentTicks < state.totalTicks
        then
            states[guid] = {
                show = false,
                changed = true,
            }
        end
    end
end

local test = function(event, triggerNum, triggerStates)
    -- first trigger is spell cooldown on kick
    if triggerNum == 1 then
        --DevTool:AddData(triggerStates[""], pegasusDev1)
        --DevTool:AddData(GetTime(), pegasusDev2)
        aura_env.kickCDExpiration = triggerStates[""].expirationTime
        if (not aura_env.kickCDExpiration)
        or aura_env.kickCDExpiration <= GetTime() -- this checks if kick *just* finished CD
        then -- our kick is off cd
            aura_env.kickReady = True
            return True
        end
        -- second trigger checks if the spell being cast will end after kick returning 
        
    else if triggerNum == 2 then
            DevTool:AddData(triggerStates[""], pegasusDev2)
            if aura_env.kickReady then 
                return True
            end 
            local castExpiration = triggerStates[""].expirationTime
            if aura_env.kickCDExpiration
            and castExpiration -- means unit is currently casting
            and castExpiration > GetTime() -- cast not finishing *right* now
            and castExpiration > aura_env.kickCDExpiration
            then 
                return True
            end
        end
    end
end
