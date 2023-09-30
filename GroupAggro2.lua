-- Texture: "Interface\RaidFrame\Raid-FrameHighlights"
-- UNIT_THREAT_SITUATION_UPDATE, UNIT_THREAT_LIST_UPDATE
aura_env.onEvent = function(states, event, ...)
    if event == "UNIT_THREAT_SITUATION_UPDATE"
        or event == "UNIT_THREAT_LIST_UPDATE"
    then
        local statesUpdated = false
        for unit in WA_IterateGroupMembers() do
            local unitType = strmatch(unit, "(%a+)%d+") or ""
            local N = strmatch(unit, "%a+(%d+)") or ""
            local unitPet = unitType .. "pet" .. N
            local isUpdate = aura_env.setStateForUnit(states, unit)
            if aura_env.config.includePets then
                isUpdate = aura_env.setStateForUnit(states, unitPet) or isUpdate
            end
            statesUpdated = statesUpdated or isUpdate
        end
        return statesUpdated
    end
end
aura_env.setStateForUnit = function(states, unit)
    local status = UnitThreatSituation(unit) -- for Any Enemy
    if (status and status > 0) then
        local changed = not states[unit] or states[unit].status ~= status
        if not changed then return false end
        local unitFrame = states[unit] and states[unit].frame
            or WeakAuras.GetUnitFrame(unit)
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
    if aura_env.debug then print("anchoring") end
    if aura_env.state.frame then
        aura_env.region.texture:SetTexCoord(
            0.00781250, 0.55468750, 0.00781250, 0.27343750
        )
        aura_env.region:SetSize(aura_env.state.frame:GetSize())
        -- ViragDevTool:AddData(aura_env.state.frame, aura_env.state.unit .. " Frame")
        aura_env.region:Color(unpack(aura_env.state.color))
        if aura_env.debug then
            print("anchored to ", aura_env.state.frame:GetName())
        end
        return aura_env.state.frame
    end
    if aura_env.debug then print("no anchor found") end
end
