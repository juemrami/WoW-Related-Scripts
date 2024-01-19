local loggedInstanceTypes = {
    ["raid"] = true, -- Raids
    ["party"] = true, -- Dungeons
    ["scenario"] = false, -- Scenarios
    ["pvp"] = false, -- Battlegrounds
    ["arena"] = false, -- Arenas
    ["none"] = false, -- World
}
-- aura_env.config.stopLoggingOutside = false
aura_env.isValidInstance = function()
    local _, instanceType = GetInstanceInfo()
    assert(instanceType, 
    aura_env.id.." | OnInstanceEnter: instanceType from `GetInstanceInfo()` is `nil`")
    return loggedInstanceTypes[instanceType or "none"]
end
local shouldShowText = function()
    -- 1. show on: always
    -- 2. show on: not logging
    local options = {
        [1] = true,
        [2] = not aura_env.isLogging,
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
    if shouldEnable then LoggingCombat(true)
    elseif shouldDisable then LoggingCombat(false) end
    aura_env.isLogging = LoggingCombat() -- final state
    -- state compare
    local isUpdate = isLogging ~= aura_env.isLogging
    if isUpdate then
        print(debugMsg:format(aura_env.id, instanceStr, aura_env.isLogging and COMBATLOGENABLED or COMBATLOGDISABLED))
    end
    return isUpdate
    -- return isUpdate
end
local pollRate = 5 -- sec
-- events: PLAYER_ENTERING_WORLD, UPDATE_COMBAT_LOGGING
aura_env.onEvent = function(states, event, ...)
    local _isLogging = LoggingCombat() -- original state
    local isValidInstance = aura_env.isValidInstance()
    local shouldEnable = isValidInstance and not _isLogging
    local shouldDisable = not isValidInstance and _isLogging and aura_env.config.stopLoggingOutside
    if (shouldEnable and not _isLogging) or (shouldDisable and _isLogging) then
        if shouldEnable then LoggingCombat(true)
        elseif shouldDisable then LoggingCombat(false) end
        aura_env.isLogging = LoggingCombat() -- final state
        -- state compare
        local isUpdate = _isLogging ~= aura_env.isLogging
        if isUpdate then
            local debugMsg = "%s detected.\n%s"
            aura_env.debug(debugMsg:format(
                isValidInstance and "Instance" or "No instance", 
                aura_env.isLogging and COMBATLOGENABLED or COMBATLOGDISABLED))
        else
            C_Timer.After(pollRate, WeakAuras.ScanEvents("UPDATE_COMBAT_LOGGING"))
        end
    else aura_env.isLogging = _isLogging end
    states[""] = {
        -- show = isValidInstance() and shouldShowText(),
        show = true,
        combatLogState = aura_env.isLogging,
        changed = true,
    }
    return true
end
aura_env.debug = function(...) 
    local tag = "|cFFFFFF00["..aura_env.id.."]|r "
    if aura_env.config.debug then print(tag, ...) end
end

---@type WA.CustomConditions
local conditions = {
    combatLogState = {
        display = "Combat Logging State",
        type = "bool",
    }
}