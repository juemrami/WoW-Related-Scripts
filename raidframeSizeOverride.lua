hooksecurefunc(InterfaceOverrides, "CreateRaidFrameSettings", function(category, _)
    local NATIVE_UNIT_FRAME_HEIGHT = 9
    local NATIVE_UNIT_FRAME_WIDTH = 18
    local function FormatScaledPercentage(value)
        return FormatPercentage(value / NATIVE_UNIT_FRAME_WIDTH);
    end
    local setting = Settings.GetSetting("PROXY_RAID_FRAME_WIDTH")
    local minValue, maxValue, step = NATIVE_UNIT_FRAME_WIDTH, 144, 2;
    local options = Settings.CreateSliderOptions(minValue, maxValue, step);
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatScaledPercentage);
    Settings.CreateSlider(category, setting, options, nil);
    local function FormatScaledPercentage(value)
        return FormatPercentage(value / NATIVE_UNIT_FRAME_HEIGHT);
    end
    local setting = Settings.GetSetting("PROXY_RAID_FRAME_HEIGHT")
    local minValue, maxValue, step = NATIVE_UNIT_FRAME_HEIGHT, 72, 2;
    local options = Settings.CreateSliderOptions(minValue, maxValue, step);
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatScaledPercentage);
    Settings.CreateSlider(category, setting, options, nil);
end)

hooksecurefunc("DefualtCompactFrameSetup", function(frame) 
    
end)