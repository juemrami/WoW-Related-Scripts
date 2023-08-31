if not aura_env.init then
    -- Adding Target Frame Health Text Textures
    TargetFrameTextureFrame:CreateFontString("TargetFrameHealthBarText", "BORDER", "TextStatusBarText")
    TargetFrameHealthBarText:SetPoint("CENTER", TargetFrameTextureFrame, "CENTER", -50, 3)

    TargetFrameTextureFrame:CreateFontString("TargetFrameHealthBarTextLeft", "BORDER", "TextStatusBarText")
    TargetFrameHealthBarTextLeft:SetPoint("LEFT", TargetFrameTextureFrame, "LEFT", 8, 3)

    TargetFrameTextureFrame:CreateFontString("TargetFrameHealthBarTextRight", "BORDER", "TextStatusBarText")
    TargetFrameHealthBarTextRight:SetPoint("RIGHT", TargetFrameTextureFrame, "RIGHT", -110, 3)

    -- Adding Target Frame Mana Text Textures
    TargetFrameTextureFrame:CreateFontString("TargetFrameManaBarText", "BORDER", "TextStatusBarText")
    TargetFrameManaBarText:SetPoint("CENTER", TargetFrameTextureFrame, "CENTER", -50, -8)
    TargetFrameTextureFrame:CreateFontString("TargetFrameManaBarTextLeft", "BORDER", "TextStatusBarText")
    TargetFrameManaBarTextLeft:SetPoint("LEFT", TargetFrameTextureFrame, "LEFT", 8, -8)
    TargetFrameTextureFrame:CreateFontString("TargetFrameManaBarTextRight", "BORDER", "TextStatusBarText")
    TargetFrameManaBarTextRight:SetPoint("RIGHT", TargetFrameTextureFrame, "RIGHT", -110, -8)
    -- Adding Textures to Tables
    TargetFrameHealthBar.LeftText = TargetFrameHealthBarTextLeft;
    TargetFrameHealthBar.RightText = TargetFrameHealthBarTextRight
    TargetFrameManaBar.LeftText = TargetFrameManaBarTextLeft;
    TargetFrameManaBar.RightText = TargetFrameManaBarTextRight;
    -- BlizzardAPI for Player Unit Healthbars utilized here
    UnitFrameHealthBar_Initialize("target", TargetFrameHealthBar, TargetFrameHealthBarText, true);
    UnitFrameManaBar_Initialize("target", TargetFrameManaBar, TargetFrameManaBarText, true);
    -- Setting CVARS
    aura_env.textDisplayTypes = {"NUMERIC", "PERCENT", "BOTH"}
    SetCVar("statusText", aura_env.config.statusText and "1" or "0")
    SetCVar("statusTextDisplay", aura_env.textDisplayTypes[aura_env.config.statusTextDisplay])

    -- Fix for Mobs with "0" health
    hooksecurefunc("TargetFrame_OnUpdate",
        function(frame, a)
            local healthBar = frame.healthbar;
            if not healthBar then return end

            healthBar.showPercentage = false;
            local maxValue = UnitHealthMax(frame.unit);

            -- Safety check to make sure we never get an empty bar.
            healthBar.forceHideText = false;
            if (maxValue == 0) then
                healthBar.forceHideText = true
            end
            TextStatusBar_UpdateTextString(healthBar);
        end
    )
    aura_env.optionsUpdate = function(event, ...)
        if event == "OPTIONS" then
            SetCVar("statusText", aura_env.config.statusText and "1" or "0")
            SetCVar("statusTextDisplay", aura_env.textDisplayTypes[aura_env.config.statusTextDisplay])
        end
    end
    aura_env.init = true
end
