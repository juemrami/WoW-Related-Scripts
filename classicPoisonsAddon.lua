-- enchantID could be used to check if the player has the enchant already
---@see GetWeaponEnchantInfo

-- [itemID] -> {spellID, enchantID}
---@type {[integer]: {spell: integer, enchant: integer}}
local tempEnchantItems = {
  -- Poisons
  [2892] = { spell = 2823, enchant = 7 },        -- Deadly Poison
  [2893] = { spell = 2824, enchant = 8 },        -- Deadly Poison II
  [8984] = { spell = 11355, enchant = 626 },     -- Deadly Poison III
  [8985] = { spell = 11356, enchant = 627 },     -- Deadly Poison IV
  [20844] = { spell = 25351, enchant = 2630 },   -- Deadly Poison V
  [3775] = { spell = 3408, enchant = 22 },       -- Crippling Poison
  [3776] = { spell = 11202, enchant = 603 },     -- Crippling Poison II
  [5237] = { spell = 5761, enchant = 35 },       -- Mind-numbing Poison
  [6951] = { spell = 8693, enchant = 23 },       -- Mind-numbing Poison II
  [9186] = { spell = 11399, enchant = 643 },     -- Mind-numbing Poison III
  [6947] = { spell = 8679, enchant = 323 },      -- Instant Poison
  [6949] = { spell = 8686, enchant = 324 },      -- Instant Poison II
  [6950] = { spell = 8688, enchant = 325 },      -- Instant Poison III
  [8926] = { spell = 11338, enchant = 623 },     -- Instant Poison IV
  [8927] = { spell = 11339, enchant = 624 },     -- Instant Poison V
  [8928] = { spell = 11340, enchant = 625 },     -- Instant Poison VI
  [10918] = { spell = 13219, enchant = 703 },    -- Wound Poison
  [10920] = { spell = 13225, enchant = 704 },    -- Wound Poison II
  [10921] = { spell = 13226, enchant = 705 },    -- Wound Poison III
  [10922] = { spell = 13227, enchant = 706 },    -- Wound Poison IV
  -- Sharpening Stones
  [2862] = { spell = 2828, enchant = 40 },       -- Rough Sharpening Stone
  [2863] = { spell = 2829, enchant = 13 },       -- Coarse Sharpening Stone
  [2871] = { spell = 2830, enchant = 14 },       -- Heavy Sharpening Stone
  [3239] = { spell = 3112, enchant = 19 },       -- Rough Weightstone
  [3240] = { spell = 3113, enchant = 20 },       -- Coarse Weightstone
  [3241] = { spell = 3114, enchant = 21 },       -- Heavy Weightstone
  [7964] = { spell = 9900, enchant = 483 },      -- Solid Sharpening Stone
  [7965] = { spell = 9903, enchant = 484 },      -- Solid Weightstone
  [12404] = { spell = 16138, enchant = 1643 },   -- Dense Sharpening Stone
  [12643] = { spell = 16622, enchant = 1703 },   -- Dense Weightstone
  [18262] = { spell = 22756, enchant = 2506 },   -- Elemental Sharpening Stone
  [23122] = { spell = 28891, enchant = 2684 },   -- Consecrated Sharpening Stone
  [211845] = { spell = 430392, enchant = 7098 }, -- Blackfathom Sharpening Stone
  -- Oils
  [3824] = { spell = 3594, enchant = 25 },       -- Shadow Oil
  [3829] = { spell = 3595, enchant = 26 },       -- Frost Oil
  [20744] = { spell = 25117, enchant = 2623 },   -- Minor Wizard Oil
  [20745] = { spell = 25118, enchant = 2624 },   -- Minor Mana Oil
  [20746] = { spell = 25119, enchant = 2626 },   -- Lesser Wizard Oil
  [20747] = { spell = 25120, enchant = 2625 },   -- Lesser Mana Oil
  [20748] = { spell = 25123, enchant = 2629 },   -- Brilliant Mana Oil
  [20749] = { spell = 25122, enchant = 2628 },   -- Brilliant Wizard Oil
  [20750] = { spell = 25121, enchant = 2627 },   -- Wizard Oil
  [23123] = { spell = 28898, enchant = 2685 },   -- Blessed Wizard Oil
  [211848] = { spell = 430585, enchant = 7099 }, -- Blackfathom Mana Oil
}


-- https://warcraft.wiki.gg/wiki/SecureStateDriver

-- todo: add support for shaman castable weapon enchants
-- [spellID] -> enchantID
local tempEnchantSpells = {
  [8017] = { enchantID = 29 },    -- Rockbiter Weapon I
  [8018] = { enchantID = 6 },     -- Rockbiter Weapon II
  [8019] = { enchantID = 1 },     -- Rockbiter Weapon III
  [10399] = { enchantID = 503 },  -- Rockbiter Weapon IV
  [16314] = { enchantID = 683 },  -- Rockbiter Weapon V
  [16315] = { enchantID = 1663 }, -- Rockbiter Weapon VI
  [16316] = { enchantID = 1664 }, -- Rockbiter Weapon VII
  [8024] = { enchantID = 5 },     -- Flametongue Weapon I
  [8027] = { enchantID = 4 },     -- Flametongue Weapon II
  [8030] = { enchantID = 3 },     -- Flametongue Weapon III
  [16339] = { enchantID = 523 },  -- Flametongue Weapon IV
  [16341] = { enchantID = 1665 }, -- Flametongue Weapon V
  [16342] = { enchantID = 1666 }, -- Flametongue Weapon VI
  [8033] = { enchantID = 2 },     -- Frostbrand Weapon I
  [8038] = { enchantID = 12 },    -- Frostbrand Weapon II
  [10456] = { enchantID = 524 },  -- Frostbrand Weapon III
  [16355] = { enchantID = 1667 }, -- Frostbrand Weapon IV
  [16356] = { enchantID = 1668 }, -- Frostbrand Weapon V
  [8232] = { enchantID = 283 },   -- Windfury Weapon I
  [8235] = { enchantID = 284 },   -- Windfury Weapon II
  [10486] = { enchantID = 525 },  -- Windfury Weapon III
  [16362] = { enchantID = 1669 }, -- Windfury Weapon IV
  [7451] = { enchantID = 64 },  -- Imbue Chest - Minor Spirit
  [7448] = { enchantID = 63 },  -- Imbue Chest - Lesser Absorb
  [7855] = { enchantID = 253 }, -- Imbue Chest - Absorb
  [7853] = { enchantID = 252 }, -- Imbue Chest - Lesser Spirit
  [7865] = { enchantID = 257 }, -- Imbue Cloak - Lesser Protection
  [7439] = { enchantID = 28 },  -- Imbue Cloak - Minor Resistance
  [7769] = { enchantID = 244 }, -- Imbue Bracers - Minor Wisdom OLD
  [7434] = { enchantID = 31 },  -- Imbue Weapon - Beastslayer
}



local FALLBACK_ICON = 136242
-- for 2H classes whenever i add weaponstones & oils
local playerHasOffhand = IsDualWielding
local MAX_ROW_BUTTONS = 4 -- todo: add multiple rows for more buttons
local MAX_ROWS = 4
local MAX_BUTTONS = MAX_ROW_BUTTONS * MAX_ROWS
local BUTTON_X_SPACING = 4
local BUTTON_Y_SPACING = 6
local dragMouseButton = "LeftButton"
local hideDelay = 0.5 -- seconds

--- helper function for sorting by ilvl
local function getItemLevel(itemID)
  return select(4, GetItemInfo(itemID)) or 0
end

local ADDON_ID = "ClassicWeaponEnchants"
local BASE_BUTTON_ID = ADDON_ID .. "Button"
local MAIN_BUTTON_SIZE = 35 -- square
---@class Addon : Frame
local addon = CreateFrame("Frame", ADDON_ID, UIParent, "SecureHandlerBaseTemplate");
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("PLAYER_REGEN_DISABLED")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")

--[[
  Hover Icon Frame aka the Flyout "toggle".
]]
---@class FlyoutToggleButton : Frame
addon.FlyoutButton = CreateFrame("Frame", nil, addon, "SecureHandlerEnterLeaveTemplate, SecureHandlerDragTemplate")

function addon.FlyoutButton:Init()
  self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  self:SetSize(MAIN_BUTTON_SIZE, MAIN_BUTTON_SIZE)
  
  -- Button Icon
  local iconSize = MAIN_BUTTON_SIZE - 2
  self.Icon = self:CreateTexture(nil, "BACKGROUND", nil)
  self.Icon:SetTexture(FALLBACK_ICON)
  self.Icon:SetTexCoord(0.01, 0.99, 0.01, 0.99)
  self.Icon:SetSize(iconSize, iconSize)
  self.Icon:SetPoint("CENTER")
  -- self.Icon:Hide()

  --- Textures shown on mouseover and while the flyout is open.
  -- Highlight
  self.Highlight = self:CreateTexture(nil, "HIGHLIGHT", nil)
  self.Highlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
  self.Highlight:SetAllPoints(self.Icon, true)
  self.Highlight:SetBlendMode("ADD")
  self.Highlight:Hide()
  
  -- Border
  local border = self:CreateTexture(nil, "OVERLAY", nil, 1)
  local borderSize = iconSize + 2
  border:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
  border:SetTexCoord(0.01562500, 0.67187500, 0.39843750, 0.72656250)
  border:SetSize(borderSize, borderSize)
  border:SetPoint("CENTER", self.Icon)
  self.Border = border
  
  -- Border Shadow
  local shadowSize = borderSize + 6; 
  local borderShadow = self:CreateTexture(nil, "OVERLAY", nil, 1)
  borderShadow:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
  borderShadow:SetTexCoord(0.01562500, 0.76562500, 0.00781250, 0.38281250)
  borderShadow:SetPoint("CENTER", border)
  borderShadow:SetSize(shadowSize, shadowSize)
  borderShadow:Hide()
  self.BorderShadow = borderShadow
  
  -- Arrow texture to indicate flyout direction
  -- see "Interface\FrameXML\ActionButtonTemplate.xml"
  self.FlyoutArrow = self:CreateTexture(nil, "OVERLAY", nil, 2)
  self.FlyoutArrow:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
  self.FlyoutArrow:SetTexCoord(0.625, 0.984375, 0.7421875, 0.828125)
  self.FlyoutArrow:SetSize(MAIN_BUTTON_SIZE/(1.83), MAIN_BUTTON_SIZE/(3.82))
  self.FlyoutArrow:SetPoint("CENTER", border, "TOP", 0, 2)

  --- Make Toggle draggable
  self:SetMovable(true)
  self:EnableMouse(true)
  self:RegisterForDrag(dragMouseButton)
  self:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  self:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)
end
addon.FlyoutButton:Init()

---@param shown boolean is flyout shown
local SetFlyoutButtonHoverTextures = function(shown)
  local flyoutButton = addon.FlyoutButton
  if shown then 
    -- flyoutButton.Highlight:Show()
    flyoutButton.FlyoutArrow:SetRotation(math.pi)
    flyoutButton.BorderShadow:Show()
  else
    flyoutButton.Highlight:Hide()
    flyoutButton.FlyoutArrow:SetRotation(0)
    flyoutButton.BorderShadow:Hide()
  end
end

--[[
  The Flyout frame itself.
]]
local LAYOUT_VERTICAL_PADDING = 4
local LAYOUT_HORIZONTAL_PADDING = 4
addon.FlyoutFrame = CreateFrame("Frame", nil, addon, "BackdropTemplate,ResizeLayoutFrame, SecureFrameTemplate")
---@diagnostic disable-next-line: undefined-field
addon.FlyoutFrame:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
 	edgeFile = "Interface\\ArenaEnemyFrame\\UI-Arena-Border",
 	tile = true,
 	tileEdge = true,
 	tileSize = 8,
 	edgeSize = 2,
 	-- insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
---@diagnostic disable-next-line: undefined-field
addon.FlyoutFrame:SetBackdropColor(0, 0, 0, 0.75)
---@diagnostic disable-next-line: undefined-field
addon.FlyoutFrame:SetBackdropBorderColor(0.9, 0.9, 0.9, 0.95)
---@diagnostic disable-next-line: undefined-field
addon.FlyoutFrame:SetHeightPadding(LAYOUT_HORIZONTAL_PADDING)
---@diagnostic disable-next-line: inject-field
addon.FlyoutFrame.widthPadding = LAYOUT_VERTICAL_PADDING

addon.FlyoutFrame:SetPoint("BOTTOMLEFT", addon.FlyoutButton, "TOPLEFT", 0, BUTTON_Y_SPACING-1)
addon.FlyoutFrame:Hide()

--- create a secure action button to use inside of the flyout.
local CreateButtonForFlyout = function(parent, name)
  ---@class ButtonInFlyout : Button
  button = CreateFrame("Button", name, parent,
    "SecureActionButtonTemplate, ItemButtonTemplate");
  button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
  button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")
  button:HookScript("OnLeave", GameTooltip_Hide)
  local size = button:GetSize()
  local scale = (MAIN_BUTTON_SIZE * 0.9) / size -- scale to NxN via "N/size"
  button:SetScale(scale)
  local nativeHide = button.Hide
  button.hideAnim = button:CreateAnimationGroup()
  local fade = button.hideAnim:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0)
  fade:SetDuration(0.25)
  button.hideAnim:HookScript("OnFinished", function()
    if not InCombatLockdown() then
      nativeHide(button)
    end
  end)

  -- hack to get `SetItemButtonCount` to include count == 1
  button.isBag = true
  return button
end
local SetButtonAttributes = function(self, attributes)
  for attribute, value in pairs(attributes) do
    self:SetAttribute(attribute, value)
  end
end
local SetButtonQuality = function(self, quality)
  if quality then
		if quality >= LE_ITEM_QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[quality] then
			self.IconBorder:Show()
			self.IconBorder:SetVertexColor(
        BAG_ITEM_QUALITY_COLORS[quality].r, 
        BAG_ITEM_QUALITY_COLORS[quality].g, 
        BAG_ITEM_QUALITY_COLORS[quality].b
      )
		else
			self.IconBorder:Hide()
		end
	else
		self.IconBorder:Hide()
	end
end
--- note that OnShow is only called when the frame was previously hidden.
--- meaning this wont be called to update the flyout if the flyout is already displayed.
local UpdateFlyoutFrame = function(self)
  local buttonInfo = addon:RefreshButtonInfo()
  local numButtons = #buttonInfo
  local numRows = math.ceil(numButtons / MAX_ROW_BUTTONS)
  -- generate flyout buttons
  for row = 1, numRows do
    local rowLength = min(MAX_ROW_BUTTONS, numButtons - (row - 1) * MAX_ROW_BUTTONS)
    for col = 1, rowLength do
      local buttonIdx = (row - 1) * MAX_ROW_BUTTONS + col
      local button = _G[BASE_BUTTON_ID .. buttonIdx]
      if not button then
        button = CreateButtonForFlyout(self, (BASE_BUTTON_ID .. buttonIdx))
      end
      -- print(buttonIdx)
      local info = buttonInfo[buttonIdx]
      ---@cast button ButtonInFlyout
      -- position buttons
      if col == 1 then
        local flyoutEdgeSize = self:GetEdgeSize()
        
        -- usually anchor to first of previous row
        local relativeTo = _G[BASE_BUTTON_ID .. max(1, buttonIdx - MAX_ROW_BUTTONS)]
        local relativePoint = "TOPLEFT"
        local xOffset = 0
        local yOffset = BUTTON_Y_SPACING
        
        -- but for first of initial row only anchor to flyout 
        if row == 1 then
          relativeTo = self
          relativePoint = "BOTTOMLEFT"
          xOffset = flyoutEdgeSize + 1 + LAYOUT_HORIZONTAL_PADDING
          yOffset = flyoutEdgeSize + 1 + LAYOUT_VERTICAL_PADDING
        end

        button:SetPoint("BOTTOMLEFT", relativeTo, relativePoint, xOffset, yOffset)
      else
        -- anchor to button directly to left button if not initial row button
        button:SetPoint("LEFT", _G[(BASE_BUTTON_ID .. (buttonIdx - 1))], "RIGHT", BUTTON_X_SPACING, 0)
      end
      -- add tooltip
      button:HookScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        -- use ItemSpell if enchant comes from item, else use spellID
        local spell = info.itemID 
          and select(2, GetItemSpell(info.itemID))
          or info.spellID
        GameTooltip:SetSpellByID(spell)
        GameTooltip:Show()
      end)

      -- set button attributes
      SetButtonAttributes(button, info.attributes)
      -- button:Show() -- should be called by parent

      ---@diagnostic disable-next-line: undefined-global
      SetItemButtonTexture(button, info.icon)
      if info.itemID then
        ---@diagnostic disable-next-line: undefined-global
        SetItemButtonCount(button, GetItemCount(info.itemID, false, true))
        SetButtonQuality(button, select(3, GetItemInfo(info.itemID)))
      end
    end

  end
  -- hide unused buttons
  for i = numButtons + 1, MAX_BUTTONS do
    local button = _G[BASE_BUTTON_ID .. i]
    if button
    and not InCombatLockdown() 
    then
      self:MarkIgnoreInLayout(button)
      button:SetScript("OnEnter", nil)
      ---@diagnostic disable-next-line: undefined-global
      SetItemButtonTexture(button, nil);
      -- button:ClearAllPoints()
      button:Hide()
      -- button:Disable()
    end
  end
  -- This is required after you're done laying out your contents; on the
  -- end of the current game tick (OnUpdate) the Layout method provided
  -- by ResizeLayoutMixin will be called which will resize this frame to
  -- the total extents of all child regions.
  self:MarkDirty();
end
addon.FlyoutFrame:HookScript("OnShow", function(flyout)
  UpdateFlyoutFrame(flyout)
  -- if any button show update hover textures
  if _G[BASE_BUTTON_ID .. 1] 
  and _G[BASE_BUTTON_ID .. 1]:IsVisible() 
  then
    SetFlyoutButtonHoverTextures(true)
  else
    flyout:hide()
  end
end)

local FlyoutFrame_OnHide = function()
  SetFlyoutButtonHoverTextures(false)
  GameTooltip_Hide()
end
addon.FlyoutFrame:HookScript("OnHide", FlyoutFrame_OnHide)

--- refreshes `self.buttonInfo` with the current enchant items in bags
function addon:RefreshButtonInfo()
  local foundIDs = {}
  ---@type {[integer]: {bag: integer, slot: integer, info: ContainerItemInfo}}
  local itemInfo = {}
---@type {attributes: table<string,any>, icon: integer, count: integer?, itemID: integer?, spellID: number}[]
  local buttonInfo = {}
  for bag = 0, 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info
          and info.itemID
          and tempEnchantItems[info.itemID]
      then
        if not itemInfo[info.itemID] then
          itemInfo[info.itemID] = {
            bag = bag,
            slot = slot,
            info = info
          }
          tinsert(foundIDs, info.itemID)
        else
          -- for multiple stacks of the same item
          -- only make a button for the one with the lowest amount of stacks + charges
          local prevItem = itemInfo[info.itemID]       
          if info.stackCount < prevItem.info.stackCount then
            itemInfo[info.itemID] = {
              bag = bag,
              slot = slot,
              info = info
            }
          end
        end
      end
    end
  end
  for spellID, _ in pairs(tempEnchantSpells) do
    if IsSpellKnownOrOverridesKnown(spellID) then
      tinsert(foundIDs, spellID)
    end
  end
  sort(foundIDs, function(a, b)
    return getItemLevel(a) < getItemLevel(b)
  end)
  local getItemMacroText = function(bag, slot, weapSlot)
    return ("/use %s %s\n/use %s\n/click StaticPopup1Button1")
        :format(bag, slot, weapSlot)
  end
  for i = 1, #foundIDs do
    local foundID = foundIDs[i]
    local item = itemInfo[foundID]
    if item then -- isItem
      -- https://warcraft.wiki.gg/wiki/SecureActionButtonTemplate
      local attributes = {
        type1 = "macro",
        type2 = "macro",
        macrotext1 = getItemMacroText(item.bag, item.slot, 16),
        macrotext2 = getItemMacroText(item.bag, item.slot, 17),
        -- macrotext2 = playerHasOffhand()
        --   and getMacroText(item.bag, item.slot, 17)
        --   or nil,
      }
      tinsert(buttonInfo, {
        macrotext1 = getItemMacroText(item.bag, item.slot, 16),
        macrotext2 = getItemMacroText(item.bag, item.slot, 17),
        attributes = attributes,
        -- spellID = tempEnchantItems[foundID].spell,
        icon = item.info.iconFileID,
        itemID = foundID,
        count = item.info.stackCount
      })
    else -- isSpell
      local spellName = GetSpellInfo(foundID)
      local attributes = {
        type1 = "macro",
        macrotext1 = spellName and("/cast %s"):format(spellName)
      }
      tinsert(buttonInfo, {
        attributes = attributes,
        spellID = foundID,
        icon = GetSpellTexture(foundID)
      })
    end
  end  self.buttonInfo = buttonInfo
  return buttonInfo
end

--[[
  Setting up Secure Auto Hide for the flyout.
  allows in combat support
]]
local flyout = "FlyoutFrame"
local toggle = "FlyoutButton"
---@diagnostic disable-next-line: undefined-field
addon.FlyoutButton:SetFrameRef(flyout, addon.FlyoutFrame)
---@diagnostic disable-next-line: undefined-field
addon.FlyoutButton:SetFrameRef(toggle, addon.FlyoutButton)
local ShowFlyoutAndSetAutoHide = ([=[
  local flyout = self:GetFrameRef("%s");
  local toggle = self:GetFrameRef("%s");
  flyout:Show();
  flyout:RegisterAutoHide(%.2f);
  flyout:AddToAutoHide(toggle);
]=]):format(flyout, toggle, hideDelay);
addon.FlyoutButton:SetAttribute("_onenter", ShowFlyoutAndSetAutoHide);
addon.FlyoutButton:SetAttribute("_onreceivedrag", ShowFlyoutAndSetAutoHide);
addon.FlyoutButton:HookScript("OnEnter", function(self)
  -- self:RefreshButtonInfo()
  GameTooltip:SetOwner(self, "ANCHOR_NONE")
  GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 3, 0)
  GameTooltip:SetText("Left-click an enchant to apply to main-hand.\nRight-click to apply to off-hand.")
end);

addon.FlyoutButton:HookScript("OnLeave", function(self)
  GameTooltip_Hide()
end)
addon:HookScript("OnEvent", function(self, event)
  -- print(event)
  if event == "BAG_UPDATE_DELAYED" then
    if not InCombatLockdown() then
      UpdateFlyoutFrame(self.FlyoutFrame)
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- addon.icon:SetDesaturated(true)
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- addon.icon:SetDesaturated(false)
  end
end)