-- Texture: "Interface\RaidFrame\Raid-FrameHighlights"
-- UNIT_THREAT_SITUATION_UPDATE, UNIT_THREAT_LIST_UPDATE
aura_env.onEvent = function(states, event, ...)
    if event == "UNIT_THREAT_SITUATION_UPDATE"
        or event == "UNIT_THREAT_LIST_UPDATE"
    then
        local groupSize = GetNumGroupMembers()
        local statesUpdated = false
        for N = 1, groupSize do
            local unit = "party" .. N
            local unitPet = "partypet"..N
            if N == groupSize then 
                unit = "player" 
                unitPet = "pet"
            end

            local isUpdate = aura_env.setStateForUnit(states, unit, ...)
            if aura_env.config.includePets then
                isUpdate = aura_env.setStateForUnit(states, unitPet, ...) or isUpdate
            end
            statesUpdated = statesUpdated or isUpdate
        end
        return statesUpdated
    end
end
aura_env.setStateForUnit = function(states, unit, mobUnit)
    -- local status = mobUnit and UnitThreatSituation(unit, mobUnit) or UnitThreatSituation(unit);
    local status = UnitThreatSituation(unit)
    if (status and status > 0) then
        local changed = not states[unit] or states[unit].status ~= status
        if not changed then return false end
        local unitFrame = states[unit] and states[unit].frame
            or WeakAuras.GetUnitFrame(unit)
        print(unitFrame)
        local r, g, b = GetThreatStatusColor(status)
        states[unit] = {
            show = unitFrame ~= nil,
            changed = true,
            unit = unit,
            status = status,
            frame = unitFrame,
            color = { r, g, b },
        }
    else
        states[unit] = {
            show = false,
            changed = true,
        }
    end
    return true
end
aura_env.fitTextureToFrame = function()
    -- ViragDevTool:AddData(aura_env.region, "region")
    --print(aura_env.region.id)
    -- print( aura_env.region:GetParent():GetName())
    print("anchoring")
    if aura_env.state.frame then
        aura_env.region.texture:SetTexCoord(
            0.00781250, 0.55468750, 0.00781250, 0.27343750
        )
        aura_env.region:SetSize(aura_env.state.frame:GetSize())
        -- print(aura_env.region.id, "post setallpoints")
        ViragDevTool:AddData(aura_env.state.frame, aura_env.state.unit .. " Frame")
        aura_env.region:Color(unpack(aura_env.state.color))
        print("anchored to ", aura_env.state.frame:GetParent():GetName())
        return aura_env.state.frame
    end
    print("no anchor found")
end
