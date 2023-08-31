A = function(args)
    ViragDevTool:AddData(aura_env, "aura_env")
    -- cloneId == unitId
    -- unit == unitId
    -- spedId
    if aura_env.state.unit and aura_env.state.specId and aura_env.group_specs then
        local _, spec_name, _, spec_icon, _, _, class = GetSpecializationInfoByID(aura_env.state.specId)
        aura_env.group_specs[aura_env.state.unit] = { spec_name, spec_icon, class }
        if aura_env.group_specs then
            local result = {}
            for _, spec_info in pairs(aura_env.group_specs) do
                local spec_name, _, class = unpack(spec_info)
                local color = C_ClassColor.GetClassColor(aura_env.state.class)
                local text = string.format("%s", spec_name)
                print(text)
                tinsert(result, text)
            end
            return unpack(result)
        end
    end
end
B = function(allstates, event, ...)
    if event == "OPTIONS" then
        allstates[""] = {
            show = true,
            changed = true,
            unit = "player",
            class = "Hunter",
            spec = "Unholy",
            icon = 236235,
            name = "test",
            autoHide= true,
        }
    elseif event == "TRIGGER" then
        local trigger_states = select(2, ...)
        ViragDevTool:AddData(trigger_states, "trigger_states")
        if trigger_states then
            for clone_id, state in pairs(trigger_states) do
                if state.unit and state.specId then
                    if not allstates[state.unit]
                    then
                        print("intial load for " .. state.unit)
                        local _, spec_name, _, spec_icon, _, _, class = GetSpecializationInfoByID(state.specId)
                        allstates[state.unit] = {
                            show = true,
                            changed = true,
                            progressType = "static",
                            unit = state.unit,
                            specId = state.specId,
                            class = class,
                            spec = spec_name,
                            icon = spec_icon,
                            name = state.name,
                            autoHide = true,
                        }
                    elseif (allstates[state.unit].name == state.name
                    and allstates[state.unit].specId ~= state.specId)
                    or not allstates[state.unit].spec
                    then
                        print("partial update for " .. state.unit)
                        local _, spec_name, _, spec_icon, _, _, _ = GetSpecializationInfoByID(state.specId)
                        allstates[state.unit].specId = state.specId
                        allstates[state.unit].spec = spec_name
                        allstates[state.unit].icon = spec_icon
                        allstates[state.unit].changed = true
                    else
                        print("full update for " .. state.unit)
                        if allstates[state.unit].name ~= state.name and allstates[state.unit].unit == state.unit then
                            allstates[state.unit] = {
                                show = true,
                                changed = true,
                                progressType = "static",
                                unit = state.unit,
                                specId = state.specId,
                                class = class,
                                spec = spec_name,
                                icon = spec_icon,
                                name = state.name,
                                autoHide = true,
                            }
                        end
                    end
                end
            end
        return true
        end
    else return false
    end
end

C = function(allstates, event, ...)
    if event == "TRIGGER" then
        local trigger_states = select(2, ...)
        ViragDevTool:AddData(trigger_states, "trigger_states")
        if trigger_states then
            for clone_id, state in ipairs(trigger_states) do
                print(state.unit .. " " .. state.specId)
                if state.unit and state.specId  then
                local _, spec_name, _, spec_icon, _, _, class = GetSpecializationInfoByID(state.specId)
                allstates[state.unit] = {
                    show = true,
                    changed = true,
                    unit = state.unit,
                    specId = state.specId,
                    class = class,
                    spec = spec_name,
                    icon = spec_icon,
                    name = state.name,
                }   
                end
            end
        end
    return true
    end
end