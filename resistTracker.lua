if not aura_env.saved then
    aura_env.saved = {
        total = 0,
        resists = 0,
        orcSpecific = {
            total = 0,
            resists = 0,
        },
    }
end
--- events: TRIGGER:1:2
aura_env.onEvent = function(event, triggerNum, triggerStates)
    if event == "TRIGGER" then
        local state = triggerStates[""]
        -- DevTool:AddData(triggerStates, "triggerStates")
        -- DevTools_Dump(triggerStates)
        -- DevTool:AddData(aura_env, "aura_env")
        if state and state.destGUID then
            local _, _, _, race = GetPlayerInfoByGUID(state.destGUID)
            local data = aura_env.saved
            local orcData = data.orcSpecific
            if triggerNum == 1 then
                -- Trigger 1: resisted casts
                data.resists = data.resists + 1
                if race == "Orc" then
                    orcData.resists = orcData.resists + 1
                end
            elseif triggerNum == 2 then
                -- Trigger 2: any cast
                data.total = data.total + 1
                if race == "Orc" then
                    orcData.total = orcData.total + 1
                end
            end
        end
    end
end

aura_env.customText = function()
    if aura_env.state and aura_env.state.destGUID then
        local _, _, _, race = GetPlayerInfoByGUID(aura_env.state.destGUID)
        if race == "Orc" then
            local resists = aura_env.saved.orcSpecific.resists
            local total = aura_env.saved.orcSpecific.total
            if total > 0 then
                local msg = "\nOrc Resist Chance: %.2f%% (sample size: %d)"
                return msg:format(resists / total * 100, total)
            end
        end
    end
end
