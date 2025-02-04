if not C_AddOns.IsAddOnLoaded("Baganator") then return end
local buttonID = "BaganatorCustomMoneyToggleButton"
aura_env.onEvent = function(event)
    if event == "PLAYER_ENTERING_WORLD" or event == "STATUS" then
        aura_env.init()
    end
end
aura_env.init = function()
    if aura_env.initialized then return end
    local allMoneyFrames = {}
    local toggleButton = _G[buttonID] or CreateFrame("Button", buttonID)
    toggleButton.Icon = toggleButton.Icon or toggleButton:CreateTexture(nil, "ARTWORK")
    toggleButton.Icon:SetAtlas("transmog-icon-hidden", false)
    toggleButton.Icon:SetAllPoints()
    toggleButton:SetSize(16, 16)
    toggleButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    Mixin(toggleButton, ButtonStateBehaviorMixin);
    toggleButton:SetScript("OnMouseDown", toggleButton.OnMouseDown)
    toggleButton:SetScript("OnMouseUp", toggleButton.OnMouseUp)
    toggleButton:SetDisplacedRegions(1,-2, toggleButton.Icon)
    local toggleHideOnClick = function(frame)
        local newState = not frame:IsShown()
        for _, moneyFrame in pairs(allMoneyFrames) do
            moneyFrame:SetShown(newState)
        end
        return newState
    end
    local setupMoneyToggle = function(skin)
        local frameSets = {
            backpackViews = {
                "Baganator_SingleViewBackpackViewFrame", "Baganator_CategoryViewBackpackViewFrame"
            },
            bankViews = {"Baganator_SingleViewBankViewFrame", "Baganator_CategoryViewBankViewFrame"}
        }
        for _, viewPrefixes in pairs(frameSets) do
            for _, prefix in ipairs(viewPrefixes) do
                local view = _G[prefix .. skin]
                local moneyFrame
                if viewPrefixes == frameSets.bankViews then
                    moneyFrame = view and view.Character
                        and view.Character.CurrencyWidget and view.Character.CurrencyWidget.Money;
                else
                    moneyFrame = view and view.CurrencyWidget and view.CurrencyWidget.Money;
                end
                allMoneyFrames[prefix] = moneyFrame
            end
        end
        local mainView = _G[
            frameSets.backpackViews[BAGANATOR_CONFIG.bag_view_type == "single" and 1 or 2] .. skin
        ];
        local moneyFrame = mainView and mainView.CurrencyWidget and mainView.CurrencyWidget.Money
        if moneyFrame then ---@cast moneyFrame Frame
            -- toggleButton:SetParent(mainView)
            -- toggleButton:SetPoint("RIGHT", moneyFrame, "LEFT", -2, 0)
            toggleButton:SetScript("OnClick", function(_, clickType, isMouseDown)
                if isMouseDown then return end
                local isMoneyVisible = toggleHideOnClick(moneyFrame)
                toggleButton.Icon:SetDesaturated(not isMoneyVisible)
            end)
        end
    end
    Baganator.CallbackRegistry:RegisterCallback(Baganator.CallbackRegistry.Event.SettingChanged,
        function(_, settingName)
            if settingName == "current_skin" or settingName == "bag_view_type" then 
                setupMoneyToggle(BAGANATOR_CONFIG.current_skin)
            end 
        end
    )
    setupMoneyToggle(BAGANATOR_CONFIG.current_skin) -- run once on load
    aura_env.initialized = true
    WeakAuras.prettyPrint(aura_env.id, "has been loaded!")
end