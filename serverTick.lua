aura_env.lastHP = UnitHealth("player")
-- aura_env.lastTick = GetTime()
aura_env.lastMana = UnitPower("player", 0)
aura_env.tickDuration = 2.0
aura_env.SERVER_REGEN_EVENT = "SERVER_REGEN_EVENT"
aura_env.MS_BUFFER_250 = 0.25 -- buffer for server tick related events

-- -- events: UNIT_HEALTH_FREQUENT:player, UNIT_POWER_UPDATE:player SERVER_REGEN_EVENT
-- aura_env.onEvent = function(states, event, ...)
--     local currentHP = UnitHealth("player")
--     local currentMana = UnitPower("player", 0)
--     local isRegenTick = false
--     if event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_POWER_UPDATE" then
--         if currentHP > aura_env.lastHP
--             or currentMana > aura_env.lastMana
--         then
--             local offSetStart = GetTimePreciseSec()
--             local serverTime = GetServerTime()
--             local currentTime = GetTime()
--             if aura_env.nextTick and not aura_env.nextTickTimestamp then
--                 local diff = currentTime - aura_env.nextTick
--                 print("tick was " .. diff .. "s " .. (diff > 0 and "late" or "early"))
--                 print("event: ", event)
--                 if diff == 0 then
--                     aura_env.handleTrueTick(offSetStart, serverTime)
--                 end
--             end
--             if aura_env.nextTickTimestamp
--                 and aura_env.nextTickTimestamp > serverTime
--             then
--                 local remaining = aura_env.nextTickTimestamp - serverTime
--                 states[""] = {
--                     show = true,
--                     changed = true,
--                     duration = aura_env.tickDuration,
--                     expirationTime = GetTime() - remaining,
--                     progressType = "timed",
--                     autoHide = true
--                 }
--                 aura_env.nextTickTimestamp = aura_env.nextTickTimestamp + aura_env.tickDuration
--                 C_Timer.After(
--                     remaining,
--                     function()
--                         WeakAuras.ScanEvents(aura_env.SERVER_REGEN_EVENT, true)
--                     end
--                 )
--             elseif
--                 abs(abs(currentTime - aura_env.lastTick) - 2) <= aura_env.MS_BUFFER_250
--             then
--                 aura_env.nextTick = currentTime + aura_env.tickDuration
--                 states[""] = {
--                     show = true,
--                     changed = true,
--                     duration = aura_env.tickDuration,
--                     expirationTime = aura_env.nextTick,
--                     progressType = "timed",
--                     autoHide = true
--                 }
--                 C_Timer.After(
--                     aura_env.tickDuration,
--                     function()
--                         WeakAuras.ScanEvents(aura_env.SERVER_REGEN_EVENT, true)
--                     end
--                 )
--             end
--             aura_env.lastTick = currentTime
--         end
--         aura_env.lastHP = currentHP
--         aura_env.lastMana = currentMana
--         if states[""] and states[""].show and states[""].changed then
--             return true
--         end
--     elseif event == aura_env.SERVER_REGEN_EVENT and not states[""] then
--         local flag = select(2, ...)
--         aura_env.lastTick = GetTime()
--         local serverTime = GetServerTime()
--         print("event: ", event)
--         if aura_env.nextTickTimestamp
--             and aura_env.nextTickTimestamp > serverTime
--         then
--             local remaining = aura_env.nextTickTimestamp - serverTime
--             states[""] = {
--                 show = true,
--                 changed = true,
--                 duration = aura_env.tickDuration,
--                 expirationTime = GetTime() - remaining,
--                 progressType = "timed",
--                 autoHide = true
--             }
--             aura_env.nextTickTimestamp = aura_env.nextTickTimestamp + aura_env.tickDuration
--             C_Timer.After(
--                 remaining,
--                 function()
--                     WeakAuras.ScanEvents(aura_env.SERVER_REGEN_EVENT, true)
--                 end
--             )
--         else
--             states[""] = {
--                 show = true,
--                 changed = true,
--                 duration = aura_env.tickDuration,
--                 expirationTime = aura_env.lastTick + aura_env.tickDuration,
--                 progressType = "timed",
--                 autoHide = true,
--             }
--             C_Timer.After(
--                 aura_env.tickDuration,
--                 function()
--                     WeakAuras.ScanEvents(aura_env.SERVER_REGEN_EVENT, false)
--                 end
--             )
--         end
--         return true
--     end
-- end
---@param offSetStart number
---@param serverTimestamp number
aura_env.handleTrueTick = function(offSetStart, serverTimestamp)
    print("connected to server tick")
    local offSet = offSetStart - GetTimePreciseSec()
    local serverTickTimestamp = serverTimestamp + offSet
    aura_env.nextTickTimestamp = serverTickTimestamp + aura_env.tickDuration
end

-- events: UNIT_HEALTH_FREQUENT:player, UNIT_POWER_UPDATE:player SERVER_REGEN_EVENT
aura_env.lastCheck = GetTime()
aura_env.nextTick = aura_env.lastCheck
aura_env._lastCheck = GetTimePreciseSec()
aura_env.onEvent = function(states, event, ...)
    local currentTime = GetTime()
    local currentMana = UnitPower("player", 0)
    local currentHP = UnitHealth("player")
    local checkStart = GetTimePreciseSec()
    if aura_env.config.debug then print("event: ", event) end
    local isServerTick = function ()
        local checkDiff = currentTime - aura_env.lastCheck
        -- ignore any power updates that outside of tick interval (with leeway)
        if abs(checkDiff - aura_env.tickDuration) > aura_env.MS_BUFFER_250 then
            if aura_env.config.debug then
                print("check not within tick interval:  ".. checkDiff.."s")
            end
            return false
        end

        if currentHP > aura_env.lastHP 
            or currentMana > aura_env.lastMana 
        then
            if aura_env.config.debug then
                print("checked after " .. checkDiff .. "s")
            end
            return true
        end
        -- lower priority check. prefer health/mana check
        if event == aura_env.SERVER_REGEN_EVENT then
            return true
        end
    end
    local isTrueTick = function ()
        local diff = aura_env.nextTick - currentTime
        if aura_env.config.debug then
            print("tick was " .. diff .. "s " .. (diff > 0 and "late" or "early"))
        end
        if event ~= aura_env.SERVER_REGEN_EVENT 
            and diff == aura_env.tickDuration
            and (
                currentHP > aura_env.lastHP
                or currentMana > aura_env.lastMana
            )
        then
            return true
        end
    end
    if isServerTick() then
        aura_env.nextTick = (function() 
            if not aura_env.serverTickTimestamp and isTrueTick() then
                if aura_env.config.debug then 
                    print("connected to server tick")
                end
                aura_env.serverTickTimestamp = GetServerTime()
            end
            if aura_env.serverTickTimestamp then
                -- Server to system time offset
                local offset = currentTime - aura_env.serverTickTimestamp
                local nextTimestamp = aura_env.serverTickTimestamp + aura_env.tickDuration
                return nextTimestamp + offset
            else
                return currentTime + aura_env.tickDuration
            end
        end)()
        states[""] = {
            show = true,
            changed = true,
            duration = aura_env.tickDuration,
            expirationTime = aura_env.nextTick,
            progressType = "timed",
            autoHide = true
        }

        -- use fake tick when full health/mana or in combat.
        if currentHP == UnitHealthMax("player") 
            and currentMana == UnitPowerMax("player", 0)
            or InCombatLockdown()
        then 
            C_Timer.After(
                aura_env.nextTick - GetTime(),
                function()
                    WeakAuras.ScanEvents(aura_env.SERVER_REGEN_EVENT, aura_env.serverTickTimestamp)
                end
            )
        end
    end
    aura_env.lastHP = currentHP
    aura_env.lastMana = currentMana
    aura_env.lastCheck = currentTime
    return true
end