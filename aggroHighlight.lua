if not aura_env.init then
    DefaultCompactUnitFrameOptions.displayAggroHighlight = true
    hooksecurefunc("DefaultCompactUnitFrameSetup", function(frame)
        if not frame or frame.aggroHighlight then return end
        frame.aggroHighlight = frame:CreateTexture(
            frame:GetName() .. "AggroHighlight",
            "ARTWORK")
        frame.aggroHighlight:SetTexture("Interface\\RaidFrame\\Raid-FrameHighlights");
        frame.aggroHighlight:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750);
        frame.aggroHighlight:SetAllPoints(frame);
    end)

    if type(CompactUnitFrame_UpdateAggroHighlight) ~= "function" then
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
