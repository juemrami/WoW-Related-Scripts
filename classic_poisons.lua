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
  }

-- SIE -> filter by name then rip ID (enchantID)
-- SE -> filter by EffectMiscValue_0 using SIE ripped values
    -- from SE take SpellID (spell cast id)
-- IE -> filter by SPELLID from SE; take ParentItemID
-- make table [ParentItemID] = {spellID, enchantID}


-- to assume we have wf/wildstrikes 
    -- did we have buff last combat?
    -- do we have druid/shaman in group currently


-- a. start with table of itemIDs for all related weap enchants
    -- GetItemSpell -> spellID of enchants
    -- GetWeaponEnchantInfo -> duration/EnchantID/charges
        ---@see GetWeaponEnchantInfo
    -- Get enchantID -> spellID using db tables

-- 0. search bags for each item 
    -- add option to consilidate ranks to use the lowest rank first
    -- for rogue poisons with I II III... etc

-- 1. make an icon button for each item
 -- left = apply to main
 -- right = apply to oh (if OH equipped)

local FALLBACK_ICON = 136242
local playerHasOffhand = IsDualWielding()
local MAX_BUTTONS = 6

local function updateItemButtons(parent)
    local itemInfo = {}
    local itemsFound = {}
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
    for i = 1, MAX_BUTTONS do
        local button =  _G["WeakAurasClassicPoisonsButton"..i]
        if not button then
            button = CreateFrame("Button", "WeakAurasClassicPoisonsButton"..i, parent, "SecureActionButtonTemplate")
            button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
            button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")

        end
        
        button:Disable()
        button:Hide()
        local itemID = itemsFound[i]
        if itemID then
            ---@type integer, integer, ContainerItemInfo
            local bag, slot, info = unpack(itemInfo[itemID])
            local bagSlotStr = ("%s %s"):format(bag, slot)
                button:SetAttribute("type1", "macro")
                button:SetAttribute("macrotext1", "/use " .. bagSlotStr.."\n/use 16\n /click StaticPopup1Button1")
                button:SetAttribute("type2", "macro")
                button:SetAttribute("macrotext2", "/use " .. bagSlotStr.."\n/use 17\n /click StaticPopup1Button1")
            button:Enable()
            button:Show()
        end
        
    end
end 

aura_env.onEvent = function(allstates, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" 
    then
        local args = {...}
        if args[2] == "ENCHANT_APPLIED" 
        and args[8] == WeakAuras.myGUID
        then
            -- aura_env.UpdateAuraWeaponStates(allstates)
        end
    elseif event == "BAG_UPDATE_DELAYED" 
    then
        aura_env.updateItemButtons()
        aura_env.UpdateAuraWeaponStates(allstates)
    end
end





---@alias events "COMBAT_LOG_EVENT_UNFILTERED" "BAG_UPDATE_DELAYED"