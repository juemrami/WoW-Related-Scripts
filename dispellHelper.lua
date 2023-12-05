aura_env.onShow = function()
    if aura_env.state.unit then
        DevTool:AddData(aura_env.region, "region")
        ---@type string?
        local debuffType = aura_env.state.debuffClass
        local unitFrame = WeakAuras.GetUnitFrame(aura_env.state.unit)
        DevTool:AddData(unitFrame, "unitFrame")
        if unitFrame then
            local debuffColor
            if debuffType then
                -- capitalize WA's debuffType string to match blizzard's
                debuffType = debuffType:sub(1, 1):upper() .. debuffType:sub(2)
                if DebuffTypeColor then
                    debuffColor = DebuffTypeColor[debuffType]
                end
            end
            -- Set glow color to match blizzard's debuff color scheme 
            for _, subElement in pairs(aura_env.region.subRegions or {}) do
                if subElement.type == "subglow" and debuffColor then
                    local alpha = subElement.glowColor[4] or 1
                    subElement:SetGlowColor(
                        debuffColor.r, 
                        debuffColor.g, 
                        debuffColor.b, 
                        alpha
                    )
                end
            end
            aura_env.region.icon:SetAlpha(0)
            aura_env.region:SetSize(unitFrame:GetSize())
            aura_env.region:SetAllPoints(unitFrame)
        end
    end
end
aura_env.onHide = function()
    aura_env.region.icon:SetAlpha(1)
    aura_env.region:ClearAllPoints()
end
-- /dump CompactPartyFrameMember1:GetObjectType()