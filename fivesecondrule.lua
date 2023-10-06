aura_env.onEvent = function(allstates, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then 
        allstates[""] = { show = false, changed = true, progressType= "timed", duration = 5, expirationTime = 0, autoHide = true }
    end
end