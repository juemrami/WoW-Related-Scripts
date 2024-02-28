-- enchantID could be used to check if the player has the enchant already
---@see GetWeaponEnchantInfo

-- [itemID] -> {spellID, enchantID}
---@type {[integer]: {spellID: integer, enchantID: integer}}
local tempEnchantItems = {
  -- Poisons
  [2892] = { spellID = 2823, enchantID = 7 },       -- Deadly Poison
  [2893] = { spellID = 2824, enchantID = 8 },       -- Deadly Poison II
  [8984] = { spellID = 11355, enchantID = 626 },    -- Deadly Poison III
  [8985] = { spellID = 11356, enchantID = 627 },    -- Deadly Poison IV
  [20844] = { spellID = 25351, enchantID = 2630 },  -- Deadly Poison V
  [3775] = { spellID = 3408, enchantID = 22 },      -- Crippling Poison
  [3776] = { spellID = 11202, enchantID = 603 },    -- Crippling Poison II
  [5237] = { spellID = 5761, enchantID = 35 },      -- Mind-numbing Poison
  [6951] = { spellID = 8693, enchantID = 23 },      -- Mind-numbing Poison II
  [9186] = { spellID = 11399, enchantID = 643 },    -- Mind-numbing Poison III
  [6947] = { spellID = 8679, enchantID = 323 },     -- Instant Poison
  [6949] = { spellID = 8686, enchantID = 324 },     -- Instant Poison II
  [6950] = { spellID = 8688, enchantID = 325 },     -- Instant Poison III
  [8926] = { spellID = 11338, enchantID = 623 },    -- Instant Poison IV
  [8927] = { spellID = 11339, enchantID = 624 },    -- Instant Poison V
  [8928] = { spellID = 11340, enchantID = 625 },    -- Instant Poison VI
  [10918] = { spellID = 13219, enchantID = 703 },   -- Wound Poison
  [10920] = { spellID = 13225, enchantID = 704 },   -- Wound Poison II
  [10921] = { spellID = 13226, enchantID = 705 },   -- Wound Poison III
  [10922] = { spellID = 13227, enchantID = 706 },   -- Wound Poison IV
  -- Sharpening Stones
  [2862] = { spellID = 2828, enchantID = 40 },      -- Rough Sharpening Stone
  [2863] = { spellID = 2829, enchantID = 13 },      -- Coarse Sharpening Stone
  [2871] = { spellID = 2830, enchantID = 14 },      -- Heavy Sharpening Stone
  [3239] = { spellID = 3112, enchantID = 19 },      -- Rough Weightstone
  [3240] = { spellID = 3113, enchantID = 20 },      -- Coarse Weightstone
  [3241] = { spellID = 3114, enchantID = 21 },      -- Heavy Weightstone
  [7964] = { spellID = 9900, enchantID = 483 },     -- Solid Sharpening Stone
  [7965] = { spellID = 9903, enchantID = 484 },     -- Solid Weightstone
  [12404] = { spellID = 16138, enchantID = 1643 },  -- Dense Sharpening Stone
  [12643] = { spellID = 16622, enchantID = 1703 },  -- Dense Weightstone
  [18262] = { spellID = 22756, enchantID = 2506 },  -- Elemental Sharpening Stone
  [23122] = { spellID = 28891, enchantID = 2684 },  -- Consecrated Sharpening Stone
  [211845] = { spellID = 430392, enchantID = 7098 },-- Blackfathom Sharpening Stone
  -- Oils
  [3824] = { spellID = 3594, enchantID = 25 },      -- Shadow Oil
  [3829] = { spellID = 3595, enchantID = 26 },      -- Frost Oil
  [20744] = { spellID = 25117, enchantID = 2623 },  -- Minor Wizard Oil
  [20745] = { spellID = 25118, enchantID = 2624 },  -- Minor Mana Oil
  [20746] = { spellID = 25119, enchantID = 2626 },  -- Lesser Wizard Oil
  [20747] = { spellID = 25120, enchantID = 2625 },  -- Lesser Mana Oil
  [20748] = { spellID = 25123, enchantID = 2629 },  -- Brilliant Mana Oil
  [20749] = { spellID = 25122, enchantID = 2628 },  -- Brilliant Wizard Oil
  [20750] = { spellID = 25121, enchantID = 2627 },  -- Wizard Oil
  [23123] = { spellID = 28898, enchantID = 2685 },  -- Blessed Wizard Oil
  [211848] = { spellID = 430585, enchantID = 7099 },-- Blackfathom Mana Oil
}

-- todo: add support for shaman castable weapon enchants
-- [spellID] -> enchantID
local tempEnchantSpells = {}



local FALLBACK_ICON = 136242
-- for 2H classes whenever i add weaponstones & oils
local playerHasOffhand = IsDualWielding
local MAX_BUTTONS = 6  -- todo: add multiple rows for more buttons
local hideDelay = 1.25 -- seconds

--- helper function for sorting by ilvl
local function getItemLevel(itemID)
  return select(4, GetItemInfo(itemID)) or 0
end

---@class ClassicPoisonsAddon : Frame
local addon = CreateFrame("Frame", "WeakAurasClassicPoisons", UIParent);
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
addon:SetSize(40, 40)
addon.icon = addon:CreateTexture()
addon.icon:SetTexture(FALLBACK_ICON)
addon.icon:SetAllPoints(addon, true)

addon.highlight = addon:CreateTexture()
addon.highlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
addon.highlight:SetAllPoints(addon, true)
addon.highlight:SetBlendMode("ADD")
addon.highlight:Hide()

--- Show/Hide item buttons on mouseover ---
local isMouseOver = addon.IsMouseOver
local isItemButtonMouseOver = function()
  for i = 1, MAX_BUTTONS do
    ---@type PoisonItemButton
    local button = _G["ClassicPoisonsButton" .. i]
    if button and button:IsMouseOver() then
      return true
    end
  end
end
function addon:IsMouseOver()
  return isMouseOver(self) or isItemButtonMouseOver()
end

function addon:StartHideTimer(callback)
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
  self.hideTimer = C_Timer.NewTimer(hideDelay, callback)
end

function addon:SetHiddenState()
  for i = 1, MAX_BUTTONS do
    ---@type PoisonItemButton
    local button = _G["ClassicPoisonsButton" .. i]
    if button then
      if button:IsVisible() then
        button.animOut:Play()
      elseif not InCombatLockdown() then
        button:Hide()
        button:Disable()
      end
    end
  end
  self.highlight:Hide()
end

function addon:Shared_OnLeave()
  if not self:IsMouseOver() then
    self:StartHideTimer(function()
      self:SetHiddenState()
    end)
    GameTooltip_Hide()
  end
end

function addon:Shared_OnEnter()
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
end

--- refreshes `self.buttonInfo` with the current enchant items in bags
function addon:RefreshButtonInfo()
  local foundIDs = {}
  ---@type {[integer]: {bag: integer, slot: integer, info: ContainerItemInfo}}
  local foundInfo = {}
  ---@type {macrotext1: string?, macrotext2: string, icon: integer, count: integer, itemID: integer}[]
  local buttonInfo = {}
  for bag = 0, 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info
          and info.itemID
          and tempEnchantItems[info.itemID]
      then
        foundInfo[info.itemID] = {
          bag = bag,
          slot = slot,
          info = info
        }
        tinsert(foundIDs, info.itemID)
      end
    end
  end
  sort(foundIDs, function(a, b)
    return getItemLevel(a) < getItemLevel(b)
  end)
  local getMacroText = function(bag, slot, weapSlot)
    return ("/use %s %s\n/use %s\n/click StaticPopup1Button1")
        :format(bag, slot, weapSlot)
  end
  for i = 1, #foundIDs do
    local itemID = foundIDs[i]
    local item = foundInfo[itemID]
    tinsert(buttonInfo, {
      macrotext1 = getMacroText(item.bag, item.slot, 16),
      macrotext2 = getMacroText(item.bag, item.slot, 17),
      -- macrotext2 = playerHasOffhand()
      --   and getMacroText(item.bag, item.slot, 17)
      --   or nil,
      icon = item.info.iconFileID,
      itemID = itemID,
      count = item.info.stackCount
    })
  end
  self.buttonInfo = buttonInfo
end

-- Update all button attributes and textures to match `self.ButtonInfo` table.
-- This function calls protected functions, so it needs to be called while not `InCombatLockdown`
function addon:UpdateItemButtons()
  if InCombatLockdown() then return end
  local addonFrame = self
  local foundButtonInfo = self.buttonInfo or {}
  for i = 1, MAX_BUTTONS do
    local button = _G["ClassicPoisonsButton" .. i]
    -- Initialize all buttons (maybe be better to just initialize on demand)
    if not button then
      ---@class PoisonItemButton : Button
      button = CreateFrame("Button", "ClassicPoisonsButton" .. i, addonFrame,
        "SecureActionButtonTemplate, ItemButtonTemplate")
      button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
      button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")

      button:SetScript("OnLeave", function()
        addonFrame:Shared_OnLeave()
      end)

      button.animOut = button:CreateAnimationGroup()
      local fadeOut = button.animOut:CreateAnimation("Alpha")
      fadeOut:SetFromAlpha(1)
      fadeOut:SetToAlpha(0)
      fadeOut:SetDuration(0.25)
      button.animOut
          :HookScript("OnFinished", function()
            if not InCombatLockdown() then
              button:SetShown(false)
              button:Disable()
              button:SetAlpha(1) -- reset alpha for next "show"
            end
          end)

      button:Hide()
      button:Disable()
    end
    if foundButtonInfo[i] then
      local info = foundButtonInfo[i]
      button:SetAttribute("type1", "macro")
      button:SetAttribute("macrotext1", info.macrotext1)
      button:SetAttribute("type2", "macro")
      button:SetAttribute("macrotext2", info.macrotext2)
      ---@diagnostic disable-next-line: undefined-global
      SetItemButtonTexture(button, info.icon)
      ---@diagnostic disable-next-line: undefined-global
      SetItemButtonCount(button, info.count)

      -- position first button ontop of the hover icon
      if i == 1 then
        button:SetPoint("BOTTOMLEFT", addonFrame, "TOPLEFT", 0, 5)
      else
        button:SetPoint("LEFT", _G["ClassicPoisonsButton" .. (i - 1)], "RIGHT", 5, 0)
      end

      button:SetScript("OnEnter", function(button)
        addonFrame:Shared_OnEnter()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(select(2, GetItemSpell(info.itemID)))
        GameTooltip:Show()
      end)
      -- dont "show" button yet
      button:Enable()
    else
      button:Hide()
      button:Disable()
    end
  end
end

-- Show all enabled item buttons
function addon:ShowItemButtons()
  local anyShown = false
  for i = 1, MAX_BUTTONS do
    ---@type PoisonItemButton?
    local button = _G["ClassicPoisonsButton" .. i]
    if button and button:IsEnabled() then
      button:Show()
      anyShown = true
    end
  end
  if anyShown then
    self.highlight:Show()
  end
end

addon:SetScript("OnEnter", function(self)
  ---@cast self ClassicPoisonsAddon

  self:Shared_OnEnter()
  self:RefreshButtonInfo()
  if not InCombatLockdown() then
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 3, 0)
    GameTooltip:SetText("Left-click a poison to apply on main-hand.\nRight-click to apply on off-hand.")
    self:UpdateItemButtons()
    self:ShowItemButtons()
  end
end)
addon:SetScript("OnLeave", function(self)
  self:Shared_OnLeave()
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
