-- events: UNIT_POWER_UPDATE:player, UNIT_SPELLCAST_SUCCEEDED
aura_env.lastMana = UnitPower("player")
aura_env.onEvent = function(allstates, event, ...)
    if event == "UNIT_POWER_UPDATE" then
        aura_env.lastMana = UnitPower("player")
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" 
        and aura_env.lastMana > UnitPower("player") 
    then
        allstates[""] = { 
            show = false, 
            changed = true,
            progressType = "timed",
            duration = 5,
            expirationTime = GetTime() + 5,
            autoHide = true
        }
    end
end