---@diagnostic disable: undefined-global
if not C_AddOns.IsAddOnLoaded("Talented") then return end
if Talented.UpdatePlayerSpecs then 
    WeakAuras.prettyPrint(WrapTextInColorCode(aura_env.id, ARTIFACT_GOLD_COLOR:GenerateHexColor())..": Native Talented support already loaded. Not loading mod.")
    return;
end
local Talented_ViewTalentGroup = function(specIndex)
    assert(Talented, "Talented not found")
    if specIndex == GetActiveTalentGroup() then
        Talented:OpenTemplate(Talented.current)
    else
        local template = TalentedFrame.specTabs[specIndex].template
        if template then
            print("Opening alternate spec template")
            Talented:OpenTemplate(CopyTable(template))
        else
            print("no template found for spec" .. specIndex .. "!")
        end
    end
end
local IsTemplateBeingViewed = function(template)
    assert(Talented, "Talented not found")
    if template then 
        return Talented.base.view.template.name == template.name
    end
end
local function SetSpecTabPositions()
    if TalentedFrame.specTabs then
        for i = 1, #TalentedFrame.specTabs do
            local tab = TalentedFrame.specTabs[i]
            if i == 1 then
                tab:SetPoint("TOPLEFT", TalentedFrame, "TOPRIGHT", 0, -65)
            else
                local prev = TalentedFrame.specTabs[i - 1]
                tab:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -22)
            end
        end
    end
end
local SpecTabs_SetBestChecked = function()
    local found = false
    if TalentedFrame.specTabs then
        for i = 1, #TalentedFrame.specTabs do
            local tab = TalentedFrame.specTabs[i]
            if IsTemplateBeingViewed(tab.template) then
                tab:SetChecked(true)
                found = true 
            else
                tab:SetChecked(false)
            end
        end
        if not found then
            TalentedFrame.specTabs[GetActiveTalentGroup()]:SetChecked(true)
        end
    end
end
local BuildTalentGroupTemplate = function(specIndex)
    assert(Talented, "Talented not found")
    assert(TalentedFrame and TalentedFrame.specTabs, "TalentedFrame and or specTabs not found")
    local currentSpec = GetActiveTalentGroup()
    local template
    if specIndex == currentSpec and Talented.current then
        template = CopyTable(Talented.current)
    else
        --- build for spec index
        Talented:createNew2OldIdx()
        template = {}
        for tabIdx = 1, GetNumTalentTabs() do
            template[tabIdx] = {}
            for talentIdx = 1, GetNumTalents(tabIdx) do
                local rank = select(
                    5, GetTalentInfo(tabIdx, Talented:GetNewIdx(tabIdx, talentIdx), nil, nil, specIndex)
                ) or 0;
                template[tabIdx][talentIdx] = rank
            end
        end
        template.class = select(2, UnitClass("player"))
        template.name = specIndex == 1 and TALENT_SPEC_PRIMARY or TALENT_SPEC_SECONDARY
    end
    TalentedFrame.specTabs[specIndex].template = template
    return template
end
local function TalentFrameToggle_RunOnce()
    if TalentedFrame and not Talented.specTabsAdded then
        PlayerTalentFrame_LoadUI() -- loads in PlayerSpecTab1, PlayerSpecTab2, etc.
        local numSpecs = GetNumTalentGroups()
        if numSpecs > 1 then
            for i = 1, numSpecs do
                if not TalentedFrame.specTabs then
                    TalentedFrame.specTabs = {} ---@type SpecTab[]
                end
                assert(_G["PlayerSpecTab" .. i], "PlayerSpecTab" .. i .. " not found")
                TalentedFrame.specTabs[i] = _G["PlayerSpecTab" .. i]
                ---@class SpecTab: CheckButton
                local specTab = TalentedFrame.specTabs[i]
                specTab:SetParent(TalentedFrame)
                specTab:SetID(i)
                specTab:RegisterForClicks("LeftButtonUp")
                specTab:SetScript("OnClick", function(self)
                    self:SetChecked(false) -- revert default checkbox behavior
                    Talented_ViewTalentGroup(self:GetID())

                    -- hack to "remove" the added tooltip line
                    PlayerSpecTab_OnEnter(self)
                end)
                specTab:HookScript("OnEnter", function(self)
                    if self.template
                    and not IsTemplateBeingViewed(self.template)
                    then
                        GameTooltip:AddLine("<Left-click to View>", GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
                    end
                end)
                specTab.template = BuildTalentGroupTemplate(i)
                specTab:SetChecked(
                    IsTemplateBeingViewed(specTab.template)
                )
            end
            SetSpecTabPositions()
            Talented.specTabsAdded = true
            TalentFrameToggle_RunOnce = nil; -- "unhook" this function
        end
        -- reimplement this function to include SoD level caps
        function Talented:IsTemplateAtCap(template)
            local maxTalentPoints = GetMaxPlayerLevel() - 9;
            if not RAID_CLASS_COLORS[template.class] then
                maxTalentPoints = 20; --20 points for hunter pets
            end
            return (
                self.db.profile.level_cap
                and self:GetPointCount(template) >= maxTalentPoints
            );
        end

        -- add the activate spec button
        local aButton = CreateFrame("Button", nil, TalentedFrame, "UIPanelButtonTemplate")
        aButton:SetNormalFontObject(GameFontNormal)
        aButton:SetHighlightFontObject(GameFontHighlight)
        aButton:SetDisabledFontObject(GameFontDisable)
        aButton:SetText(TALENT_SPEC_ACTIVATE)
        aButton:SetSize(aButton:GetTextWidth() + 40, 22)
        aButton:SetScript("OnClick", function(self)
            if self.talentGroup then
                SetActiveTalentGroup(self.talentGroup)
            end
        end)
        aButton:SetPoint("BOTTOM", 0, 6)
        aButton:SetFrameLevel(TalentedFrame:GetFrameLevel() + 2)
        aButton:Disable()
        aButton:Hide()
        -- make the button show any time the secondary currently incactive spec is viewed to offer user options to swap to it.
        hooksecurefunc(Talented.base.view, "Update", function(self)
            local inactiveSpec = GetActiveTalentGroup() == 1 and 2 or 1
            aButton.talentGroup = inactiveSpec
            local viewingAltSpec = IsTemplateBeingViewed(
                TalentedFrame.specTabs[inactiveSpec].template
            );
            aButton:SetEnabled(viewingAltSpec)
            aButton:SetShown(viewingAltSpec)
            SpecTabs_SetBestChecked()
        end)
    end
end
if not Talented.toggleHooked then
    hooksecurefunc(Talented, "ToggleTalentFrame", TalentFrameToggle_RunOnce)
    Talented.toggleHooked = true
end
aura_env.onEvent = function(event, ...)
    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        local newSpec, oldSpec = ...
        Talented:Update() -- set current template
        BuildTalentGroupTemplate(1)
        BuildTalentGroupTemplate(2)
        Talented_ViewTalentGroup(newSpec)
        -- fix to reposition the tabs on successful spec swaps
        SetSpecTabPositions()
    end
end
