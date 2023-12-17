aura_env.lastHP = UnitHealth("player")
aura_env.lastTick = GetTime()
aura_env.lastMana = UnitPower("player", 0)
aura_env.tickDuration = 2.0
aura_env.SERVER_REGEN_EVENT = "SERVER_REGEN_EVENT"
-- events: UNIT_HEALTH_FREQUENT:player, UNIT_POWER_UPDATE:player, UNIT_SPELLCAST_SUCCEEDED:playeer, SERVER_REGEN_TICK, PLAYER_REGEN_ENABLED
aura_env.onEvent = function(states, event, ...)
    if not InCombatLockdown() then
        local currentHP = UnitHealth("player")
        local currentMana = UnitPower("player", 0)
        if event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_POWER_UPDATE" then
            if currentHP > aura_env.lastHP
                or  currentMana > aura_env.lastMana
            then
                local currentTime = GetTime()
                print((abs(currentTime - aura_env.lastTick)-aura_env.tickDuration))
                if currentTime >= aura_env.lastTick then
                    aura_env.lastTick = currentTime
                    states[""] = {
                        show = true,
                        changed = true,
                        duration = aura_env.tickDuration,
                        expirationTime = currentTime + aura_env.tickDuration,
                        progressType = "timed",
                        autoHide = true
                    }
                    C_Timer.After(
                        aura_env.tickDuration,
                        function()
                            WeakAuras.ScanEvents(aura_env.SERVER_REGEN_EVENT, true)
                        end
                    )
                end
            end
            aura_env.lastHP = currentHP
            aura_env.lastMana = currentMana
            if states[""] and states[""].show and states[""].changed then 
                return true
            end
        end
    end
    if event == aura_env.SERVER_REGEN_EVENT then
        aura_env.lastTick = GetTime()
        states[""] = {
            show = true,
            changed = true,
            duration = aura_env.tickDuration,
            expirationTime = aura_env.lastTick  + aura_env.tickDuration,
            progressType = "timed",
            autoHide = true
        }
        C_Timer.After(
            aura_env.tickDuration, 
            function() 
                WeakAuras.ScanEvents(aura_env.SERVER_REGEN_EVENT, true) 
            end
        )
        return true
    end
end
