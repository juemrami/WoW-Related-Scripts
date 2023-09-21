-- Texture: "Interface\RaidFrame\Raid-FrameHighlights"
-- UNIT_THREAT_SITUATION_UPDATE, UNIT_THREAT_LIST_UPDATE
aura_env.onEvent = function(states, event, ...)
    if event == "UNIT_THREAT_SITUATION_UPDATE"
        or event == "UNIT_THREAT_LIST_UPDATE"
    then
        local groupSize = GetNumGroupMembers()
        for N = 1, groupSize do
            local unit = "party" .. N
            if N == groupSize then unit = "player" end
            local status = event == "UNIT_THREAT_SITUATION_UPDATE"
                and UnitThreatSituation(unit) or UnitThreatSituation(unit, ...);
            if (status and status > 0) then
                -- if states[unit]
                --     and states[unit].status == status then
                --     return false
                -- end
                local r, g, b = GetThreatStatusColor(status)
                states[unit] = {
                    show = true,
                    changed = true,
                    unit = unit,
                    status = status,
                    color = { r, g, b }
                }
            else
                states[unit] = {
                    show = false,
                    changed = true,
                }
            end
        end
        return true
    end
end
aura_env.setTextureColor = function()
    ViragDevTool:AddData(aura_env.region, "region")
    print(aura_env.region.id)
    print(aura_env.region:GetParent():GetName())
    
    if aura_env.state then
        if aura_env.region:GetParent():GetObjectType() ~= "Button" then
            print(aura_env.state.unit)
            local unitFrame = WeakAuras.GetUnitFrame(aura_env.state.unit)
            if not unitFrame then print("nothing to attach to") return end
            aura_env.region:SetParent(unitFrame)    
        end
        aura_env.region:Color(unpack(aura_env.state.color))
        print(aura_env.region.id, "post color")
        aura_env.region.texture:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
        print(aura_env.region.id, "post settexturecords")
        aura_env.region:SetAllPoints()
        print(aura_env.region.id, "post setallpoints")
    end
end
