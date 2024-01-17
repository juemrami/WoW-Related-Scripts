-- https://vanilla.warcraftlogs.com/character/us/crusader-strike/bigstinky
-- https://era.raider.io/characters/us/crusader-strike/Bigstinky

local build = floor(select(4, GetBuildInfo()) / 10000)
local isWrath = build == 3
local isClassicEra = build == 1
local playerRegion = GetCurrentRegionName():lower()
local wclUrlTemplate =
    (isClassicEra and "https://vanilla.warcraftlogs.com/character/%s/%s/%s")
    or (isWrath and "https://classic.warcraftlogs.com/character/%s/%s/%s")
    or "https://www.warcraftlogs.com/character/%s/%s/%s"

local raiderIoUrlTemplate =
    (isClassicEra and "https://era.raider.io/characters/%s/%s/%s")
    or (isWrath and "https://classic.raider.io/characters/%s/%s/%s")
    or "https://raider.io/characters/%s/%s/%s"

---@param realmName string
---@return string
local getFormattedRealmName = function(realmName)
    return realmName:gsub("%s+", "-"):gsub("'", ""):lower()
end

---@param urlTemplate string
---@param region string
---@param characterName string
---@param realmName string
---@return string
local buildLink = function(urlTemplate, region, characterName, realmName)
    return format(urlTemplate, region, getFormattedRealmName(realmName), characterName)
end

---@param popup StaticPopupDialog<popupData>
---@param url string
local popupButtonOnClick = function(popup, url)
    popup.data.lastUrl = url
    ---@cast popup StaticPopupDialog
    popup.editBox:SetText(url)
    popup.editBox:HighlightText()
    popup.editBox:SetCursorPosition(0)
    popup.editBox:SetFocus()
    popup.editBox:Enable()
    return true
end
local POPUP_ID = "EXTERNAL_LINKS"

---@type StaticPopupInfo<popupData>
local info = {
    text = "Choose a Site and Ctrl+C to Copy",
    hideOnEscape = true,
    button1 = "WarcraftLogs",
    button2 = "Raider.io",
    button3 = "Cancel",
    hasEditBox = 1,
    data = {}, ---@type popupData
    OnShow = function(self)
        self.editBox:SetText("select a website below")
        self.editBox.Instructions:SetText("Ctrl+C to Copy")
        -- 80% of parent width
        self.editBox:SetWidth(self:GetWidth() * 0.80)
        self.editBox:ClearFocus()
        self.editBox:Disable()
    end,
    -- WCL
    OnAccept = function(self)
        self.button2:Enable()
        self.button1:Disable()
        self.text:SetText("Showing WarcraftLogs Link for " .. (self.data.name)) 
        return popupButtonOnClick(self, self.data.wclUrl)
    end,
    -- RaiderIO
    OnCancel = function(self)
        self.button1:Enable()
        self.button2:Disable()
        self.text:SetText("Showing Raider.io Link for " .. (self.data.name)) 
        return popupButtonOnClick(self, self.data.raiderIoUrl)
    end,
    -- Close Popup
    OnAlt = function(self)
        self.editBox:SetText("")
        self.editBox:ClearFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide();
    end,
    EditBoxOnTextChanged = function(self)
        local parent = self:GetParent() --[[@as ExternalLinkPopupInfo]]
        local lastUrl = parent and parent.data.lastUrl
        if lastUrl and lastUrl ~= self:GetText() then
            self:SetText(parent.data.lastUrl)
            self:HighlightText()
            self:SetCursorPosition(0)
        end
    end
}
StaticPopupDialogs[POPUP_ID] = info
local ExternalLinkButtonMixin = CreateFromMixins(UnitPopupButtonBaseMixin)
function ExternalLinkButtonMixin:CanShow() return true end

function ExternalLinkButtonMixin:GetText() return "Show External Links" end

function ExternalLinkButtonMixin:GetTooltipText()
    return
    "Show links to WarcraftLogs and Raider.io "
end

hooksecurefunc(UnitPopupManager, "ShowMenu",
    function(self, dropdownMenu, which, _unit, _name, _userData)
        if (which == "FRIEND" or which == "PLAYER" or which == "RAID_PLAYER")
            and UIDROPDOWNMENU_MENU_LEVEL == 1
            and dropdownMenu.name then
            local name = dropdownMenu.name ---@type string
            local realm = dropdownMenu.server ---@type string?
            if not realm then -- assumed same realm as player
                realm = GetRealmName()
            end
            if not name or not realm then return end
            function ExternalLinkButtonMixin:OnClick()
                local dialog = StaticPopup_Show(POPUP_ID, nil, nil, {
                    wclUrl = buildLink(wclUrlTemplate, playerRegion, name, realm),
                    raiderIoUrl = buildLink(raiderIoUrlTemplate, playerRegion, name, realm)
                }, nil)
            end

            local menuSize = #(self:GetMenu(which):GetButtons());

            self:AddDropDownButton(UIDropDownMenu_CreateInfo(),
                dropdownMenu,
                ExternalLinkButtonMixin,
                menuSize + 1,
                UIDROPDOWNMENU_MENU_LEVEL
            )
        end
    end
)

---@alias popupData { lastUrl: string, wclUrl: string, raiderIoUrl: string }
---@alias ExternalLinkPopupInfo StaticPopupInfo<popupData>
