-- Trigger 1: Cooldown Info for player interrupt
-- Trigger 2: Casting info for nameplate units
-- events: TRIGGER:1:2
aura_env.onEvent = function(states, event, triggerNum, triggerStates)
    if triggerNum == 1 then
        aura_env.kickReady = false -- assume kick not ready
        aura_env.kickCDExpiration = triggerStates[""].expirationTime
        if (not aura_env.kickCDExpiration)
            or aura_env.kickCDExpiration <= GetTime()
        then
            aura_env.kickReady = true
        end
    elseif triggerNum == 2 then   
        --DevTool:AddData(triggerStates, "allstates")
        for _,state in pairs(states) do
            state.show = false
            state.changed = true
        end
        for cloneId, cloneState in pairs(triggerStates) do
            local castExpiration = cloneState.expirationTime
            if (aura_env.kickCDExpiration
                and castExpiration -- means unit is currently casting
                and castExpiration > GetTime() -- cast not finishing *right* now
                and castExpiration > aura_env.kickCDExpiration)
                or aura_env.kickReady
            then 
                states[cloneId] = CopyTable(cloneState)
                states[cloneId].show = true
            end
        end
        return true
    end  
end