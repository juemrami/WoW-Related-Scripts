local loggedInstanceTypes = {
    ["raid"] = true,      -- Raids
    ["party"] = true,     -- Dungeons
    ["scenario"] = false, -- Scenarios
    ["pvp"] = false,      -- Battlegrounds
    ["arena"] = false,    -- Arenas
    ["none"] = false,     -- World
}
-- aura_env.config.stopLoggingOutside = false
aura_env.isValidInstance = function()
    local _, instanceType = GetInstanceInfo()
    assert(instanceType,
        aura_env.id .. " | OnInstanceEnter: instanceType from `GetInstanceInfo()` is `nil`")
    return loggedInstanceTypes[instanceType or "none"]
end
local shouldShowText = function()
    -- 1. show on: always
    -- 2. show on: not logging
    local options = {
        [1] = true,
        [2] = not aura_env.isLoggingOnEvent,
    }
    return options[aura_env.config.showOn or 1]
end
function aura_env.validateLoggingState()
    local isLogging = LoggingCombat() -- original state
    local isValidInstance = aura_env.isValidInstance()
    local shouldEnable = isValidInstance and not isLogging
    local shouldDisable = not isValidInstance and isLogging and aura_env.config.stopLoggingOutside
    local instanceStr = isValidInstance and "Instance" or "No instance"
    local debugMsg = "[%s] %s detected, %s"
    if shouldEnable then
        LoggingCombat(true)
    elseif shouldDisable then
        LoggingCombat(false)
    end
    aura_env.isLoggingOnEvent = LoggingCombat() -- final state
    -- state compare
    local isUpdate = isLogging ~= aura_env.isLoggingOnEvent
    if isUpdate then
        aura_env.debug(debugMsg:format(aura_env.id, instanceStr,
            aura_env.isLoggingOnEvent and COMBATLOGENABLED or COMBATLOGDISABLED))
    end
    return isUpdate
    -- return isUpdate
end

-- events: PLAYER_ENTERING_WORLD, UPDATE_COMBAT_LOGGING, PLAYER_REGEN_ENABLED
aura_env.onEvent = function(states, event, ...)
    aura_env.isLoggingOnEvent = LoggingCombat() -- original state
    if aura_env.isLoggingOnEvent == nil then
        aura_env.debug("LoggingCombat returned nil")
        -- C_Timer.After(1, WeakAuras.ScanEvents("UPDATE_COMBAT_LOGGING"))
        return
    end
    local newLoggingState                         -- state after possible update
    local isValidInstance = aura_env.isValidInstance()
    local shouldEnable = isValidInstance and not aura_env.isLoggingOnEvent
    local shouldDisable = not isValidInstance 
        and aura_env.isLoggingOnEvent 
        and aura_env.config.stopLoggingOutside
    if (shouldEnable and not aura_env.isLoggingOnEvent)
        or (shouldDisable and aura_env.isLoggingOnEvent)
    then
        assert(not (shouldEnable and shouldDisable),
            "shouldEnable/shouldDisable should be mutually exclusive")
        aura_env.debug("Combat logging state update required!")
        local newState = (shouldEnable and true)
            or (shouldDisable and false)
            or nil
        if newState ~= nil then
            newLoggingState = LoggingCombat(newState)
        end
        -- LoggingCombat() can return nil when called too frequently
        if newLoggingState == nil then
            aura_env.debug("LoggingCombat call returned nil")
            -- C_Timer.After(1, WeakAuras.ScanEvents("UPDATE_COMBAT_LOGGING"))
            return
        end
        -- aura_env.isLoggingOnEvent = newLoggingState
    end
    local finalState
    if newLoggingState ~= nil then
        finalState = newLoggingState
    elseif aura_env.isLoggingOnEvent ~= nil then
        finalState = aura_env.isLoggingOnEvent
    else
        -- try api call if still nil
        finalState =LoggingCombat()
    end 
    if finalState == nil then
        aura_env.debug("LoggingCombat() returned nil determining final state")
        -- C_Timer.After(1, WeakAuras.ScanEvents("UPDATE_COMBAT_LOGGING"))
        return
    end
    local prevState = states[""] and states[""].combatLogState 
        or aura_env.isLoggingOnEvent
    local isUpdate = prevState == nil and true or (prevState ~= finalState)
    if isUpdate then
        aura_env.debug(("prev: %s, new: %s"):format(
            states[""] and states[""].combatLogState or "nil",
            finalState and "true" or "false"))
        local debugMsg = "%s detected.\n%s"
        aura_env.debug(debugMsg:format(
            isValidInstance and "Instance" or "No instance",
            finalState and COMBATLOGENABLED or COMBATLOGDISABLED))
    end
    states[""] = {
        -- show = isValidInstance() and shouldShowText(),
        show = true,
        combatLogState = finalState,
        changed = true,
    }
    return true
end
aura_env.debug = function(...)
    local tag = "|cFFFFFF00[" .. aura_env.id .. "]|r "
    if aura_env.config.debug then print(tag, ...) end
end

---@type WA.CustomConditions
local conditions = {
    combatLogState = {
        display = "Combat Logging State",
        type = "bool",
    }
}
