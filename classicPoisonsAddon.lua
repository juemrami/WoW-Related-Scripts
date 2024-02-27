-- enchantID could be used to check if the player has the enchant already
---@see GetWeaponEnchantInfo
local tempEnchantItems = {
    [2893] = { -- Deadly Poison II
      spellID = 2824, enchantID = 8,
    },
    [2892] = { -- Deadly Poison
      spellID = 2823, enchantID = 7,
    },
    [3775] = { -- Crippling Poison
      spellID = 3408, enchantID = 22,
    },
    [3776] = { -- Crippling Poison II
      spellID = 11202, enchantID = 603,
    },
    [5237] = { -- Mind Numbing Poison
      spellID = 5761, enchantID = 35,
    },
    [6949] = { -- Instant Poison II
      spellID = 8686, enchantID = 324,
    },
    [6950] = { -- Instant Poison III
      spellID = 8688, enchantID = 325,
    },
    [8927] = { -- Instant Poison V
      spellID = 11339, enchantID = 624,
    },
    [9186] = { -- Mind-Numbing Poison III
    spellID = 11399, enchantID = 643,
    },
    [8985] = { -- Deadly Poison IV
      spellID = 11356, enchantID = 627,
    },
    [8928] = { -- Instant Poison VI
      spellID = 11340, enchantID = 625,
    },
    [6951] = { -- Mind-numbing Poison II
      spellID = 8693, enchantID = 23,
    },
    [10921] = { -- Wound Poison III
      spellID = 13226, enchantID = 705,
    },
    [10922] = { -- Wound Poison IV
      spellID = 13227, enchantID = 706,
    },
    [10920] = { -- Wound Poison II
      spellID = 13225, enchantID = 704,
    },
    [10918] = { -- Wound Poison
      spellID = 13219, enchantID = 703,
    },
    [8926] = { -- Instant Poison IV
      spellID = 11338, enchantID = 623,
    },
    [8984] = { -- Deadly Poison III
      spellID = 11355, enchantID = 626,
    },
    [6947] = { -- Instant Poison
      spellID = 8679, enchantID = 323,
    },
    [20844] = { -- Deadly Poison V
      spellID = 25351, enchantID = 2630,
    },
    [202316] = { -- Crippling Poison
      spellID = 398608, enchantID = 22,
    },
    -- [3824] = { -- Shadow Oil
    -- spellID = 3594
    -- }
  }

local FALLBACK_ICON = 136242
-- for 2H classes whenever i add weaponstones & oils
local playerHasOffhand = IsDualWielding
local MAX_BUTTONS = 6 -- todo: add multiple rows for more buttons
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
    local button =  _G["ClassicPoisonsButton"..i]
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
      local button =  _G["ClassicPoisonsButton"..i]
      if button and button:IsVisible() then
          button.animOut:Play()
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
-- Update button attributes and textures for current bag items 
function addon:UpdateItemButtons()
  local itemInfo = {}
  local itemsFound = {}
  local addonFrame = self
  for bag = 0, 4 do
      for slot = 1, C_Container.GetContainerNumSlots(bag) do
          local info = C_Container.GetContainerItemInfo(bag, slot)
          if info
          and info.itemID
          and tempEnchantItems[info.itemID]
          then
              itemInfo[info.itemID] = {
                  bag = bag, 
                  slot = slot, 
                  info = info
              }
              tinsert(itemsFound, info.itemID)
          end
      end
  end
  sort(itemsFound, function(a, b)
    return getItemLevel(a) < getItemLevel(b)
  end)
  for i = 1, MAX_BUTTONS do
      local button =  _G["ClassicPoisonsButton"..i]
      if not button then
          ---@class PoisonItemButton : Button
          button = CreateFrame("Button", "ClassicPoisonsButton"..i, addonFrame, "SecureActionButtonTemplate, ItemButtonTemplate")
          button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
          button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")

          local animOut = button:CreateAnimationGroup()
          local fadeOut = animOut:CreateAnimation("Alpha")
          fadeOut:SetFromAlpha(1)
          fadeOut:SetToAlpha(0)
          fadeOut:SetDuration(0.25)
          animOut:HookScript("OnFinished", function()
            button:SetShown(false)
            button:Disable()
            button:SetAlpha(1) -- reset alpha for next "show"
          end)
          button.animOut = animOut
          button:SetScript("OnLeave",
          function()
            addonFrame:Shared_OnLeave()
          end)
      end
      button:SetAttribute("type1", nil)
      button:SetAttribute("macrotext1", nil)
      button:SetAttribute("type2", nil)
      button:SetAttribute("macrotext2", nil)
      button:Disable()
      button:Hide()

      local itemID = itemsFound[i]
      if itemID then
          ---@type {bag: integer, slot: integer, info: ContainerItemInfo}
          local item = itemInfo[itemID]
          local getMacroText = function(invSlot)
            return ("/use %s %s\n/use %s\n/click StaticPopup1Button1")
                :format(item.bag, item.slot, invSlot)
          end
          button:SetAttribute("type1", "macro")
          button:SetAttribute("macrotext1", getMacroText(16))
          button:SetAttribute("type2", "macro")
          button:SetAttribute("macrotext2", getMacroText(17))
          SetItemButtonTexture(button, item.info.iconFileID)
          SetItemButtonCount(button, item.info.stackCount)

          -- position first button ontop of the hover icon
          if i == 1 then
            button:SetPoint("BOTTOMLEFT", addonFrame, "TOPLEFT", 0, 5)
          else
            button:SetPoint("LEFT", _G["ClassicPoisonsButton"..(i-1)], "RIGHT", 5, 0)
          end

          button:SetScript("OnEnter", function(button)
            addonFrame:Shared_OnEnter()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(select(2,GetItemSpell(itemID)))
            GameTooltip:Show()
          end)
          button:Enable()
      end
  end
end
-- Show all enabled item buttons
function addon:ShowItemButtons()
  local shown = 0
  for i = 1, MAX_BUTTONS do
    local button =  _G["ClassicPoisonsButton"..i]
    if button and button:IsEnabled() then
      button:Show()
      shown = shown + 1
    end
  end
  if shown > 0 then
    self.highlight:Show()
  end
end
addon:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_NONE")
  GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 3, 0)
  GameTooltip:SetText("Left-click a poison to apply on main-hand.\nRight-click to apply on off-hand.")
  self:Shared_OnEnter()
  self:UpdateItemButtons()
  self:ShowItemButtons()
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

