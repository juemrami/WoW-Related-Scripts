if not aura_env.init then
    DefaultCompactUnitFrameOptions.displayAggroHighlight = true
    DefaultCompactMiniFrameOptions.displayAggroHighlight = true

    hooksecurefunc("DefaultCompactUnitFrameSetup", function(frame)
        print("unit frames setup: " .. type(frame))
        if not frame or frame.aggroHighlight then return end
        frame.aggroHighlight = frame:CreateTexture(
            frame:GetName() .. "AggroHighlight",
            "ARTWORK")
        frame.aggroHighlight:SetTexture("Interface\\RaidFrame\\Raid-FrameHighlights");
        frame.aggroHighlight:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750);
        frame.aggroHighlight:SetAllPoints(frame);
    end)

        function CompactUnitFrame_UpdateAggroHighlight(frame)
            if (not frame.aggroHighlight) then
                return;
            end
            if (not frame.optionTable.displayAggroHighlight) then
                if (not frame.optionTable.playLoseAggroHighlight) then
                    frame.aggroHighlight:Hide();
                end
                return;
            end

            local status = UnitThreatSituation(frame.displayedUnit);
            if (status and status > 0) then
                frame.aggroHighlight:SetVertexColor(GetThreatStatusColor(status));
                frame.aggroHighlight:Show();
            else
                frame.aggroHighlight:Hide();
            end
        end


    hooksecurefunc("CompactUnitFrame_OnEvent", function(self, event, ...)
        if (event == "UNIT_THREAT_SITUATION_UPDATE") then
            CompactUnitFrame_UpdateAggroHighlight(self);
            -- CompactUnitFrame_UpdateAggroFlash(self);
            CompactUnitFrame_UpdateHealthBorder(self);
        elseif (event == "UNIT_THREAT_LIST_UPDATE") then
            if (self.optionTable.considerSelectionInCombatAsHostile) then
                CompactUnitFrame_UpdateHealthColor(self);
                CompactUnitFrame_UpdateName(self);
            end
            -- CompactUnitFrame_UpdateAggroFlash(self);
            CompactUnitFrame_UpdateHealthBorder(self);
        elseif (event == "PLAYER_TARGET_SET_ATTACKING") then
            if (self.optionTable.considerSelectionInCombatAsHostile) then
                CompactUnitFrame_UpdateHealthColor(self);
                CompactUnitFrame_UpdateName(self);
            end
            CompactUnitFrame_UpdateHealthBorder(self);
        end
    end)
    hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
        if (UnitExists(frame.displayedUnit)) then
            CompactUnitFrame_UpdateAggroHighlight(frame);
            -- CompactUnitFrame_UpdateAggroFlash(self);
        end
    end)

    aura_env.init = true
end


-- this didnt work because the profile setting values are stored server side
-- called by GetRaidProfileOption
-- need to make a global variable to track setting value instead
-- SetRaidProfileOption calls sets the global
-- and then calls CompactUnitFrameProfiles_ApplyCurrentSettings
-- to get this working
--  CompactUnitFrameProfiles_ApplyCurrentSettings has to be hooked and
-- the displayAggroHighlight settings has to be injected into the results of GetActiveRaidProfile()
-- CompactUnitFrameProfiles_ApplyProfile will then correctly apply the setting based on the checkbox
-- for now i will just hardcode the setting to true in DefaultCompactUnitFrameOptions
-- hooksecurefunc(InterfaceOverrides, "CreateRaidFrameSettings",
-- function(category, layout)
--     do
--         -- Display Aggro Highlight
--         local defaultValue = false
--         local function GetValue()
--             return InterfaceOverrides.GetRaidProfileOption("displayAggroHighlight", defaultValue);
--         end

--         local function SetValue(value)
--             InterfaceOverrides.SetRaidProfileOption("displayAggroHighlight", value);
--         end

--         local setting = Settings.RegisterProxySetting(category, "PROXY_RAID_FRAME_AGGRO_HIGHLIGHT",
--             Settings.DefaultVarLocation,
--             Settings.VarType.Boolean,
--             COMPACT_UNIT_FRAME_PROFILE_DISPLAYAGGROHIGHLIGHT, defaultValue, GetValue,
--             SetValue
--         );
--         Settings.CreateCheckBox(category, setting,
--             OPTION_TOOLTIP_DISPLAY_RAID_AGGRO_HIGHLIGHT);
--     end
-- end)
-- hooksecurefunc(InterfaceOverrides, "RefreshRaidOptions",
-- function()
--     local setting = Settings.GetSetting("PROXY_RAID_FRAME_AGGRO_HIGHLIGHT");
--     securecallfunction(
--         setting.SetValue,
--         setting,
--         setting:GetInitValue()
--     );
-- end
-- )


-- Simple WA solution
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
                if states[unit]
                    and states[unit].status == status then
                    return false
                end
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
    aura_env.region.texture:
        SetVertexColor(unpack(aura_env.state.color))
    aura_env.region.texture:SetDrawLayer("ARTWORK", -1)
end
aura_env.attachToUnitFrame = function()
    if aura_env.state.unit then
        local unitFrame = WeakAuras.GetUnitFrame(aura_env.state.unit)
        if unitFrame then
            aura_env.region.texture:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
            aura_env.region.texture:SetDrawLayer("ARTWORK", -1)
            aura_env.region.texture:SetAllPoints(unitFrame, true)
            return unitFrame
        end
    end
end
-- conditions = {
--     threat = {
--         display = "Threat Situation",
--         type = "select",
--         values = {
--             -- [0] =  "Lower Than Tank",
--             [1] = "Higher Than Tank",
--             [2] = "Tanking But Not Highest",
--             [3] = "Tanking And Highest"
--         }
--     },
--     status = {
--         display = "Threat Status Index",
--         type = "number",
--     }
-- }
