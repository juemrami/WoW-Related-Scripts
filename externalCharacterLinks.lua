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
local hookedPopups = {
    FRIEND = true,
    PLAYER = true,
    RAID_PLAYER = true,
}
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

function ExternalLinkButtonMixin:OnClick()
    local dropdownMenu = (UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU)
    local name = dropdownMenu.name
    local realm = dropdownMenu.server or GetRealmName()
    if not name or not realm then return end
    StaticPopup_Show(POPUP_ID, nil, nil, {
        name = name,
        wclUrl = buildLink(wclUrlTemplate, playerRegion, name, realm),
        raiderIoUrl = buildLink(raiderIoUrlTemplate, playerRegion, name, realm)
    }, nil)
end

local GuildInviteButtonMixin = CreateFromMixins(UnitPopupButtonBaseMixin)
function GuildInviteButtonMixin:CanShow()
    local dropDown = (UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU)
    local guid = dropDown.guid
        or UnitGUID(dropDown.unit or "")
        or C_ChatInfo.GetChatLineSenderGUID(dropDown.lineID or 0)
    return IsInGuild() and (guid and not IsGuildMember(guid))
end
function GuildInviteButtonMixin:IsEnabled() return CanGuildInvite() end
function GuildInviteButtonMixin:GetText() return "Guild Invite" end
function GuildInviteButtonMixin:OnClick()
    local dropDown = (UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU)
    if dropDown.name then
        GuildInvite(dropDown.name)
    elseif dropDown.unit then
        GuildInvite(UnitNameUnmodified(dropDown.unit))
    end
end

-- Blizzards enable function doesn't account for for the "FRIEND" dropdown created from chat player links.
local AddFriendButtonMixin =
    CreateFromMixins(UnitPopupAddCharacterFriendButtonMixin)
function AddFriendButtonMixin:IsEnabled()
    local dropdown = (UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU)
    local guid = dropdown.guid
        or UnitGUID(dropdown.unit or "")
        or C_ChatInfo.GetChatLineSenderGUID(dropdown.lineID or 0)
    if guid then
        return C_PlayerInfo.UnitIsSameServer(
            PlayerLocation:CreateFromGUID(guid)
        ) and not C_FriendList.IsFriend(guid)
    end
    if dropdown.name then
        print("no guid using name")
        print("no server in dd?", dropdown.server == nil)
        print("server == realm?", dropdown.server == GetNormalizedRealmName())
        print("is not friend?", C_FriendList.GetFriendInfo(dropdown.name) == nil)
        return (dropdown.sever == nil
            and true
            or dropdown.server == GetNormalizedRealmName()
        ) and C_FriendList.GetFriendInfo(dropdown.name) == nil
    end
end

hooksecurefunc(UnitPopupManager, "ShowMenu",
    function(self, dropdownMenu, which, _unit, _name, _userData)
        if (hookedPopups[which])
            and UIDROPDOWNMENU_MENU_LEVEL == 1
            and dropdownMenu.name
        then
            ViragDevTool:AddData(self:GetMenu(which), "internal menu object")
            ViragDevTool:AddData((UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU), "dropdownmenu frame")
        end
    end
)
-- update popup menus to include the new buttons
local extraButtonsForMenu = {
    SELF = { ExternalLinkButtonMixin },
    FRIEND = {
        AddFriendButtonMixin,
        GuildInviteButtonMixin,
        ExternalLinkButtonMixin
    },
    PLAYER = { GuildInviteButtonMixin, ExternalLinkButtonMixin },
    RAID_PLAYER = { GuildInviteButtonMixin, ExternalLinkButtonMixin },
}
for which, extraButtonMixins in pairs(extraButtonsForMenu) do
    local menu = UnitPopupMenus[which]
    if menu then
        local buttonMixins = menu:GetButtons()
        local interactIndex
        local otherIndex
        for i, button in ipairs(buttonMixins) do
            if button.isSubsectionTitle then
                local buttonText = button:GetText()
                if buttonText == UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_INTERACT then
                    interactIndex = i
                    -- print("interact index ", interactIndex)
                elseif buttonText == UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_OTHER then
                    otherIndex = i
                    -- print("other index ", otherIndex)
                end
            end
        end
        for _, button in ipairs(extraButtonMixins) do
            if button == AddFriendButtonMixin and interactIndex then
                -- add it 2 spaces before the Interact Subsection
                table.insert(buttonMixins, interactIndex - 2, button);
                -- push down the otherIndex to account for inserting a new button before it.
                otherIndex = otherIndex and otherIndex + 1 or nil
            elseif button == GuildInviteButtonMixin and otherIndex then
                -- add it to the bottom of the Interact Subsection (2 spaces before the Other Subsection)
                table.insert(buttonMixins, otherIndex - 2, button)
            else
                -- add it to the bottom of the Other Subsection (push down cancel).
                table.insert(buttonMixins, #buttonMixins, button)
            end
        end
        function menu:GetButtons() return buttonMixins end
    end
end
---@alias popupData { lastUrl: string, wclUrl: string, raiderIoUrl: string }
---@alias ExternalLinkPopupInfo StaticPopupInfo<popupData>
