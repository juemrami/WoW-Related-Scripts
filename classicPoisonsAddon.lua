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
local MAX_ROW_BUTTONS = 3 -- todo: add multiple rows for more buttons
local MAX_ROWS = 3
local MAX_BUTTONS = MAX_ROW_BUTTONS * MAX_ROWS
local BUTTON_X_SPACING = 4
local BUTTON_Y_SPACING = 6
local hideDelay = 1.25 -- seconds

--- helper function for sorting by ilvl
local function getItemLevel(itemID)
  return select(4, GetItemInfo(itemID)) or 0
end

local ADDON_ID = "ClassicWeaponEnchants"
local BASE_BUTTON_ID = ADDON_ID .. "Button"
---@class ClassicPoisonsAddon : Frame
local addon = CreateFrame("Frame", ADDON_ID, UIParent,"SecureHandlerEnterLeaveTemplate");
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("PLAYER_REGEN_DISABLED")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
addon:SetSize(40, 40)

addon.icon = addon:CreateTexture()
addon.icon:SetTexture(FALLBACK_ICON)
addon.icon:SetAllPoints(addon, true)
addon.icon:SetDrawLayer("BACKGROUND")
--[[
  Highlight texture shown on mouseover and while the flyout is open.
]]
addon.highlight = addon:CreateTexture()
addon.highlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
addon.highlight:SetAllPoints(addon, true)
addon.highlight:SetBlendMode("ADD")
addon.highlight:Hide()
--[[
  Arrow texture to indicate flyout direction
]]
addon.arrow = addon:CreateTexture()
addon.arrow:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
addon.arrow:SetTexCoord(0.625, 0.984375, 0.7421875, 0.828125)
addon.arrow:SetSize(23, 11)
addon.arrow:SetPoint("CENTER", addon.icon, "TOP", 0, 0)
addon.arrow:SetDrawLayer("ARTWORK")
--[[
  Flyout frame for enchant buttons 
]]
addon.EnchantButtonFlyout = CreateFrame("Frame", nil, addon, "BackdropTemplate,ResizeLayoutFrame")
-- addon.EnchantButtonFlyout.minWidth = 40
-- addon.EnchantButtonFlyout.minHeight = 40
addon.EnchantButtonFlyout:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
 	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
 	tile = true,
 	tileEdge = true,
 	tileSize = 8,
 	edgeSize = 8,
 	insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
addon.EnchantButtonFlyout:SetBackdropColor(0, 0, 0, 0.67)
addon.EnchantButtonFlyout:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.95)
addon.EnchantButtonFlyout:SetPoint("BOTTOMLEFT", addon, "TOPLEFT", 0, BUTTON_Y_SPACING-1)
local LAYOUT_VERTICAL_PADDING = 0
local LAYOUT_HORIZONTAL_PADDING = 0
addon.EnchantButtonFlyout:SetHeightPadding(LAYOUT_HORIZONTAL_PADDING)
addon.EnchantButtonFlyout.widthPadding = LAYOUT_VERTICAL_PADDING
addon.EnchantButtonFlyout:Hide()

local CreateFlyoutButton = function(parent, name)
  ---@class FlyoutButton : Button
  button = CreateFrame("Button", name, parent,
    "SecureActionButtonTemplate, ItemButtonTemplate");
  button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
  button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")

  button:HookScript("OnLeave",function()
    addon:Shared_OnLeave()
  end)
  local size = button:GetSize()
  local scale = 30 / size -- scale to 30x30
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
    else
    end
  end)
  -- function button:Hide()
  --   if not InCombatLockdown() then
  --     if self.hideAnim then
  --       self.hideAnim:Play()
  --     else
  --       nativeHide(self)
  --     end
  --   end
  -- end

  -- hack to get `SetItemButtonCount` to include count == 1
  button.isBag = true
  return button
end
local SetFlyoutButtonAttributes = function(self, attributes)
  for attribute, value in pairs(attributes) do
    self:SetAttribute(attribute, value)
  end
end
local SetFlyoutButtonQuality = function(self, quality)
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
local UpdateEnchantButtonFlyout = function(self)
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
        button = CreateFlyoutButton(self, (BASE_BUTTON_ID .. buttonIdx))
      end
      -- print(buttonIdx)
      local info = buttonInfo[buttonIdx]
      ---@cast button FlyoutButton
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
      button:SetScript("OnEnter", function(button)
        addon:Shared_OnEnter()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        -- use ItemSpell if enchant comes from item, else use spellID
        local spell = info.itemID 
          and select(2, GetItemSpell(info.itemID))
          or info.spellID
        GameTooltip:SetSpellByID(spell)
        GameTooltip:Show()
      end)

      -- set button attributes
      SetFlyoutButtonAttributes(button, info.attributes)
      -- button:Show() -- should be called by parent

      ---@diagnostic disable-next-line: undefined-global
      SetItemButtonTexture(button, info.icon)
      ---@diagnostic disable-next-line: undefined-global
      if info.itemID then
        SetItemButtonCount(button, GetItemCount(info.itemID, false, true))
        SetFlyoutButtonQuality(button, select(3, GetItemInfo(info.itemID)))
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
      -- button:Disable()
    end
  end
  -- This is required after you're done laying out your contents; on the
  -- end of the current game tick (OnUpdate) the Layout method provided
  -- by ResizeLayoutMixin will be called which will resize this frame to
  -- the total extents of all child regions.
  self:MarkDirty();
end
addon.EnchantButtonFlyout:HookScript("OnShow", function(flyout)
  UpdateEnchantButtonFlyout(flyout)
  -- if any button show update hover textures
  if _G[BASE_BUTTON_ID .. 1] 
  and _G[BASE_BUTTON_ID .. 1]:IsVisible() 
  then
    addon.arrow:SetRotation(math.pi)
    addon.highlight:Show()
  else
    flyout:hide()
  end
end)


local EnchantButtonFlyout_OnHide = function()
  addon.arrow:SetRotation(0)
  addon.highlight:Hide()
end
addon.EnchantButtonFlyout:SetScript("OnHide", EnchantButtonFlyout_OnHide)

addon.EnchantButtonFlyout:HookScript("OnLeave", function()
    addon:Shared_OnLeave()
end)

local function isMouseOverRecursive(parent)
  local children = {parent:GetChildren()}
  for i = 1, #children do
    local child = children[i]
    if child:IsMouseOver() or isMouseOverRecursive(child) then
      return true
    end
  end
  return parent:IsMouseOver()
end
function addon:IsMouseOverRecursive()
  return isMouseOverRecursive(self)
end

local sharedHideTimer
local TryHideFlyoutAfterDelay = function(delay)
  if delay and delay > 0 then
    if sharedHideTimer then
      sharedHideTimer:Cancel()
    end
    -- print("Delay Hide Started")
    sharedHideTimer = C_Timer.NewTimer(delay, 
      function()
        local isMouseOver = addon:IsMouseOverRecursive()
        local InCombatLockdown = InCombatLockdown()
        if not isMouseOver and not InCombatLockdown then
          addon.EnchantButtonFlyout:Hide()
        end
      end
    )
  end
end
function addon:Shared_OnLeave()
  TryHideFlyoutAfterDelay(0.15)
  GameTooltip_Hide()
end
function addon:Shared_OnEnter()
  if sharedHideTimer then
    sharedHideTimer:Cancel()
  end
end


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


addon:SetFrameRef("Flyout", addon.EnchantButtonFlyout)
addon:SetAttribute("_onenter", [=[
  local flyout = self:GetFrameRef("Flyout");
  flyout:Show();
]=])
addon:HookScript("OnEnter", function(self)
  ---@cast self ClassicPoisonsAddon
  self:Shared_OnEnter()
  -- self:RefreshButtonInfo()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 3, 0)
    GameTooltip:SetText("Left-click a poison to apply on main-hand.\nRight-click to apply on off-hand.")
end)
addon:SetAttribute("_onleave", [=[
  local flyout = self:GetFrameRef("Flyout");
  if not self:IsUnderMouse(true) and PlayerInCombat() then
    flyout:Hide();
  end
]=])
addon:HookScript("OnLeave", function(self)
  if not InCombatLockdown() 
  and addon.EnchantButtonFlyout:IsShown() 
  then
    self:Shared_OnLeave()
  else
    self.shouldHideAfterCombat = true
  end

end)
addon:HookScript("OnEvent", function(self, event)
  -- print(event)
  if event == "BAG_UPDATE_DELAYED" then
    if not InCombatLockdown() then
      UpdateEnchantButtonFlyout(self.EnchantButtonFlyout)
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- 
    addon.icon:SetDesaturated(true)
  elseif event == "PLAYER_REGEN_ENABLED" then
    if self.shouldHideAfterCombat then
      self.shouldHideAfterCombat = false
      -- self.EnchantButtonFlyout:Hide()
    end
    addon.icon:SetDesaturated(false)
  end
end)

--- Make draggable ---
addon:SetMovable(true)
addon:EnableMouse(true)
addon:RegisterForDrag("LeftButton")
addon:SetScript("OnDragStart", function(self)
  self:StartMoving()
end)
addon:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
end)
