-- PLAYER_TARGET_CHANGED, UNIT_STATS:player, PLAYER_EQUIPMENT_CHANGED, COMBAT_RATING_UPDATE, PLAYER_DAMAGE_DONE_MODS
aura_env.playerClass = select(2, UnitClass("player"))
aura_env.resetTable = function()
    aura_env.possibleResults = {
        "Miss", "Dodge", "Parry", "Block",
        "Glancing", "Crit", "Ordinary Hit"
    }
    aura_env.tableInfo = {
        ["Miss"] = 0,
        ["Dodge"] = 0,
        ["Parry"] = 0,
        ["Block"] = 0,
        ["Glancing"] = 0,
        ["Glance DR"] = 0,
        ["Crit"] = 0,
        ["Ordinary Hit"] = 0,
        ["Crit Cap"] = 0,
    }
    aura_env.offHandTableInfo = CopyTable(aura_env.tableInfo)
end
aura_env.showFunc = {
    -- "Enemy Target",
    [1] = function()
        return UnitExists("target") and not UnitIsFriend("player", "target")
    end,
    -- "Any Target",
    [2] = function() return UnitExists("target") end,
    -- "Always Show"
    [3] = function() return true end
}
aura_env.lastTargetLevel = nil ---@type number?
aura_env.resetTable()
aura_env.onEvent = function(states, event, ...)
    if event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_STATS"
        or event == "COMBAT_RATING_UPDATE"
        or event == "SKILL_LINES_CHANGED"
        or (event == "PLAYER_DAMAGE_DONE_MODS" and ... == "player")
        or (event == "PLAYER_EQUIPMENT_CHANGED"
            and (... == INVSLOT_MAINHAND or ... == INVSLOT_OFFHAND))
        or event == "OPTIONS" or event == "STATUS"
    then
        if event == "OPTIONS" then aura_env.lastTargetLevel = nil end
        local meetsShowCondition = aura_env.showFunc[aura_env.config.showOn]()
        if meetsShowCondition then
            -- if event == "STATUS" then print("status event show") end
            local useFakeTarget = aura_env.config.showOn == 3 -- always show
                and not UnitExists("target")
            local targetLevel = useFakeTarget and -1 or UnitLevel("target")
            -- print("targetLevel", targetLevel)
            -- print("lastTargetLevel", aura_env.lastTargetLevel)
            if event == "PLAYER_TARGET_CHANGED" and (not aura_env.lastTargetLevel
                or aura_env.lastTargetLevel ~= targetLevel)
                or true
            then
                -- print("level update. remaking table")
                -- if event == "STATUS" then print("status event make table") end
                aura_env.resetTable()
                aura_env.makeTable(useFakeTarget)
                if aura_env.shouldUseOffhand() then
                    aura_env.makeTable(useFakeTarget, true)
                end
                aura_env.lastTargetLevel = targetLevel
                states[""] = { show = true, changed = true }
                return true
            end
        else
            states[""] = { show = false, changed = true }
            return true
        end
    end
end

aura_env.playerCanAttack = function()
    return UnitExists("target") and not UnitIsFriend("player", "target")
end

---Generate the attack table for the player's current target.
---@param useRaidTarget boolean? Force the table to be generated with a +3 level target.
aura_env.makeTable = function(useRaidTarget, calcOffHand)
    -- "Constants"
    local playerLevel = UnitLevel("player")
    local targetLevel = useRaidTarget and -1 or UnitLevel("target")
    -- ?? mobs are treated as being +3 levels
    if targetLevel == -1 then
        targetLevel = playerLevel + 3
    end
    if aura_env.config.capTargetLevel then
        targetLevel = min(targetLevel, playerLevel + aura_env.config.maxLevelGap)
    end
    -- TODO: offhand stuff for different weapon types
    local mainWeaponSkill, offWeaponSkill = aura_env.getWeaponSkills()
    if not mainWeaponSkill then return end
    local hitTable = aura_env.tableInfo
    if calcOffHand and offWeaponSkill then
        hitTable = aura_env.offHandTableInfo
        mainWeaponSkill = offWeaponSkill
    end
    local targetDefenseSkill = targetLevel * 5                      -- 315 for level 63 mobs
    local defenseAttackSkillDiff = targetDefenseSkill - mainWeaponSkill
    local cappedWeaponSkill = min(mainWeaponSkill, playerLevel * 5) -- 300 @ 60
    local extraWeaponSkill = max(0, mainWeaponSkill - cappedWeaponSkill)
    local hitRating = GetHitModifier()

    -- Entry Calculations
    -- Miss chance
    local missMod = defenseAttackSkillDiff > 10 and 0.2 or 0.1
    local dualWieldPenalty = IsDualWielding() and 19 or 0
    local baseMissChance = 5 + defenseAttackSkillDiff * missMod
    -- TODO: custom option for yellow hit table
    local yellowMissChance = baseMissChance
    if aura_env.config.useYellowAttackTable then
        baseMissChance = yellowMissChance
    else
        baseMissChance = baseMissChance + dualWieldPenalty
    end
    -- code in 1.12 explicitly adds a modifier that causes the first 1% of +hit gained from talents or gear to be ignored against monsters with more than 10 Defense Skill above the attacking player’s Weapon Skill.
    local hitPenalty = defenseAttackSkillDiff > 10 and 1 or 0
    local missChance = max(baseMissChance - (hitRating - hitPenalty), 0)
    hitTable["Miss"] = missChance

    -- A ranged attack cannot result in a dodge, parry, or glancing blow
    if aura_env.playerClass ~= "HUNTER" then
        -- Dodge chance
        local dodgeChance = max(5 + defenseAttackSkillDiff * 0.1, 0) or 0
        hitTable["Dodge"] = dodgeChance

        -- Parry
        -- Seems to be 14% vs +3 lvl targets, unaffected by weapon skill
        -- Unknown how it works vs lower lvl targets
        -- assume the behavior is the same as dodge and block
        local parryChance = aura_env.config.isTargetFacingPlayer
            and ((targetLevel - playerLevel > 2 and 14)
                or max(5 + defenseAttackSkillDiff * 0.1, 0)
            )
            or 0
        hitTable["Parry"] = parryChance

        -- Glancing blows
        -- extra weapon skill does not affect the chance of glancing blows
        local glancingChance = 10 + max(
            (targetDefenseSkill - cappedWeaponSkill) * 2,
            0
        )
        -- https://github.com/magey/classic-warrior/wiki/Attack-table#glancing-blows values from here
        local lowEnd = max(min(1.3 - (defenseAttackSkillDiff * 0.05), 0.91), 0.01)
        local highEnd = max(min(1.2 - (defenseAttackSkillDiff * 0.03), 0.99), 0.2)
        local glanceDR = (1 - ((lowEnd + highEnd) / 2)) * 100
        hitTable["Glancing"] = glancingChance
        hitTable["Glance DR"] = glanceDR
    end
    -- Block
    -- Mobs never have higher than 5% block chance.
    local blockChance = aura_env.config.isTargetFacingPlayer
        and min(5, max(5 + defenseAttackSkillDiff * 0.1, 0))
        or 0
    hitTable["Block"] = blockChance
    -- Order is Parry -> Glancing -> Block
    -- If the total combined chance of a miss, dodge, parry, or block is 100% or higher, not only can the attack not be an ordinary hit, the attack also cannot be a crit or a crushing blow.

    -- Crit chance
    -- GetCritChance() includes pvp 0.04 per extra weapon skill scaling
    local baseCrit = GetCritChance() - extraWeaponSkill * 0.04
    local cappedSkillDiff = cappedWeaponSkill - targetDefenseSkill
    local critMod = cappedSkillDiff < 0 and 0.2 or 0.04
    local critChance = baseCrit + cappedSkillDiff * critMod
    -- A flat (-1.8%) mod placed on your crit gained from auras when fighting +3 level mobs
    -- if aura crit > 0
    local auraCrit = (baseCrit - aura_env.getCritChanceFromAgility())
    local auraCritPenalty = (targetLevel - playerLevel > 3 and auraCrit > 0)
        and 1.8 or 0
    critChance = max(critChance - auraCritPenalty, 0)
    hitTable["Crit"] = critChance

    -- Generate the Table
    local remainingChance = 100
    local tableOverflow = false
    for _, attackResult
    -- Entry order: Miss, dodge, parry, glancing blows, blocks, crit, normal hit
    in ipairs(aura_env.possibleResults)
    do
        if hitTable[attackResult] then
          if calcOffHand then 
            print(("checking %s | %.02f%% remaining | %.02f%% required"):format(attackResult, remainingChance, hitTable[attackResult]))
          end
            if remainingChance == 0 or tableOverflow then
                hitTable[attackResult] = 0
            end
            remainingChance = remainingChance - hitTable[attackResult]
            if remainingChance < 0 then
              print("remainingChance < 0", attackResult, remainingChance, hitTable[attackResult])
                -- when the table is overflown
                -- correct the entry to not include overflown amount
                hitTable[attackResult] = 
                  hitTable[attackResult] + remainingChance;
                tableOverflow = true
            end
        end
    end
    -- actual hit chance is whatever is left from the 100% after all other entries
    hitTable["Ordinary Hit"] = remainingChance
    
    -- "Crit Cap" is the same as effective crit.
    -- It is the amount of space for Crit on the table after Block.
    -- If the space for calculated Crit is insufficient then,
    -- it is capped at whatever space is left to fill the table.
    -- If there is no space for crit, your crit is capped at 0%, ineffective.
    hitTable["Crit Cap"] =
        remainingChance + hitTable["Crit"]
end
------------------------------------------------------------------------
---Returns the total weapon skill of the main hand, and off hand weapon if used.
---@return integer? mhWeaponSkill
---@return integer? ohWeaponSkill
aura_env.getWeaponSkills = function()
    if aura_env.playerClass == "DRUID" then
        return 5 * UnitLevel("player")
    elseif aura_env.playerClass == "HUNTER" then
        local base, bonus = UnitRangedAttack("player")
        return base + bonus
    end
    -- note: this api will return unarmed for offhand even when a 2h is equipped
    local mhBase, mhExtra, ohBase, ohExtra = UnitAttackBothHands("player")
    local mhSkill = mhBase + mhExtra
    -- local mhItemId = GetInventoryItemID("player", INVSLOT_MAINHAND)
    -- local _, mhWeaponID = select(6, GetItemInfoInstant(mhItemId or ""))
    local ohSkill = IsDualWielding() and (ohBase + ohExtra) or nil
    return mhSkill, ohSkill
end
aura_env.shouldUseOffhand = function()
  local mhSkill, ohSkill = aura_env.getWeaponSkills()
  return IsDualWielding() and ohSkill and ohSkill ~= mhSkill
end
------------------------------------------------------------------------
local agiPerCritAt60 = {
    ["HUNTER"] = 53,
    ["ROGUE"] = 29,
    ["WARRIOR"] = 20,
    ["SHAMAN"] = 20,
    ["DRUID"] = 20,
    ["PALADIN"] = 20,
}
-- level modifier for the agiPerCrit table
-- Based on in-game comparing for rogue at lvl 25/40 vs 60
-- 0.0950 @ 25. approximately
-- 0.0550 @ 40
-- 0.0345 @ 60 (1/29)
local f = { 
    {x = 25, y = 0.0950},
    {x = 40, y = 0.0550},
    {x = 60, y = 0.0345},
}
-- Lagrange coefficients
local L = function(k, x)
    local m = #f
    local prod = 1
    for n = 1 , m do
        if n ~= k then
            prod = prod * (x - f[n].x) / (f[k].x - f[n].x)
        end
    end
    return prod
end
-- Interpolating polynomial
local P = function(x)
    local m = #f
    local sum = 0
    for n = 1 , m do
        sum = sum + f[n].y * L(n, x)
    end
    return sum
end
aura_env.getAgiPerCritTable = function()
    local playerLevel = UnitLevel("player")
    local agiPerCrit = agiPerCritAt60
    if playerLevel ~= 60 then
        -- verify interpolation
        assert(P(f[1].x) == f[1].y);
        assert(P(f[2].x) == f[2].y);
        assert(P(f[3].x) == f[3].y);

        -- mod between max and current level scaling for rogue
        local currentCritPerAgi = P(playerLevel)
        local maxCritPerAgi = P(60)
        local levelMod = maxCritPerAgi / currentCritPerAgi

        -- apply ratio from rogue to all other classes
        for class, maxAgiPerCrit in pairs(agiPerCritAt60) do
            agiPerCrit[class] = maxAgiPerCrit * levelMod
        end
    end
    return agiPerCrit
end
---Returns the crit chance gained from agility for the player's class.
---Level 60 values from https://vanilla-wow-archive.fandom.com/wiki/Attributes
---@return number
aura_env.getCritChanceFromAgility = function()
    local class = select(2, UnitClass("player"))
    local agility = UnitStat("player", 2)

    if not agiPerCritAt60[class] then
        return 0
    end

    return agility / agiPerCritAt60[class]
end

---Builds the display text table for the weakaura.
local newTextTable = function()
  ---@class TextTable: string[][]
  local t = {
    numLines = 0,
    colSeparator = " | ",
    ignoredLines = {},
    lineCells = {},
    isLineSeparator = {},
  }
  function t:AddLine(text, ignoreAlign)
      self.numLines = self.numLines + 1
      self[self.numLines] = {}
      self[self.numLines][1] = text
      self.ignoredLines[self.numLines] = ignoreAlign and true or false
      self.isLineSeparator[self.numLines] = false
      return self.numLines
    end
  ---@param line integer
  ---@param text string
  function t:AddCell(line, text)
    assert(line <= self.numLines and self[line], "Line does not exist")
    assert(type(self[line]) == "table", "Line is not a table")
    tinsert(self[line], text)
    return self
  end
  function t:AddSeparator()
    local idx = self:AddLine("===")
    self.ignoredLines[idx] = true
    self.isLineSeparator[idx] = true
    return self
  end
  ---@param justify ("left"|"right")?
  function t:PadCells(justify)
    ---@cast self TextTable
    if not justify then justify = "left" end
    -- find the max num of columns for all lines
    -- find the max width of each column
    -- add padding to each column to match the max width
    -- add padding to each line to match the max num of columns
    local maxCols = 0
    local colMaxWidths = {}
    for line = 1, self.numLines do
      if not self.ignoredLines[line] then
      maxCols = max(maxCols, #self[line])
        for col = 1, #self[line] do
          local colWidth = #self[line][col]
          colMaxWidths[col] = max(
            colMaxWidths[col] or 0, 
            colWidth
          )
        end
      end
    end
    for i = 1, self.numLines do
      if not self.ignoredLines[i] then
        for j = 1, maxCols do
          local cell = self[i][j] or ""
          local pad = colMaxWidths[j] - #cell
          if justify == "left" then
            self[i][j] = cell .. (" "):rep(pad)
          else
            self[i][j] = (" "):rep(pad) .. cell
          end
        end
      end
    end
    return self
  end
  function t:BuildTable()
    local lines = {}
    local maxLineLength = 0
    for i = 1, self.numLines do  
      -- each column is separated by a `self.colSeparator
      local lineText = table.concat(self[i], self.colSeparator)
      tinsert(lines, lineText)
      local length = #lineText
      if lineText:match("|c%w%w%w%w%w%w%w%w.*|r") then
        length = length - 10
      end
      maxLineLength = max(maxLineLength, length)
      print(("line %i | length: %i | isIgnored: %s")
        :format(i, length,  tostring(self.ignoredLines[i])));
    end
    -- adjust separtor lengths
    for i, isSeparator in ipairs(self.isLineSeparator) do
      if isSeparator then
        lines[i] = ("-"):rep(maxLineLength)
      end
    end
    -- each line is separated by a newline
    return table.concat(lines, "\n")
  end
  return t
end
aura_env.customText = function()
    if aura_env.state and aura_env.state.show
        and aura_env.tableInfo
    then
        local textTable = newTextTable()
        --- Player's weapon skill
        -- Weapon skill: %n | %n if exists
       local mhSkill, ohSkill = aura_env.getWeaponSkills()
        if mhSkill then
          local line = ("Weapon Skill(s): %i"):format(mhSkill)
          if aura_env.shouldUseOffhand() then
            line = line .. (" | %s"):format(NIGHT_FAE_BLUE_COLOR
            :WrapTextInColorCode(ohSkill))
          end
          textTable:AddLine(line, true)
          -- local lineIdx = textTable:AddLine("Weapon Skill(s)")
          -- textTable:AddCell(lineIdx, tostring(mhSkill))
          -- if aura_env.shouldUseOffhand() then
          --   textTable:AddCell(
          --     lineIdx, 
          --     NIGHT_FAE_BLUE_COLOR:WrapTextInColorCode(ohSkill)
          --   );
          -- end
        end
        -- Header
        -- calculation types and target info
        local tableType = aura_env.config.useYellowAttackTable
          and "Special Attacks"
          or "White Attacks";

        local simulateLevel = (
            aura_env.config.capTargetLevel
            and UnitExists("target")
            and UnitLevel("target") > UnitLevel("player") + aura_env.config.maxLevelGap
        ) or (
            aura_env.config.forceShow
            and not UnitExists("target")
        );
        local targetLevel = simulateLevel
          and (UnitLevel("player") + aura_env.config.maxLevelGap)
          or UnitLevel("target");
        local targetType = "NPC" -- deal with players later, requires different calculations


        local positionalInfo = "Infront";
        if aura_env.playerClass == "HUNTER" then
            positionalInfo = "Ranged";
            aura_env.possibleResults = {
                "Miss", "Block", "Crit", "Ordinary Hit"
            }
        elseif not aura_env.config.isTargetFacingPlayer then
            positionalInfo = "Behind"
            aura_env.possibleResults = {
                "Miss", "Dodge", "Glancing", "Crit", "Ordinary Hit"
            }
        end

        -- Insert "Glancing DR" after "Glancing" entry
        for i, v in ipairs(aura_env.possibleResults) do
            if v == "Glancing" then
                tinsert(aura_env.possibleResults, i + 1, "Glance DR")
                break
            end
        end
        -- Insert "Crit Cap" at the end of the table
        tinsert(aura_env.possibleResults, "Crit Cap")

        textTable:AddLine("Position: " .. positionalInfo, true);
        textTable:AddSeparator();
        textTable:AddLine(("%s on Lvl %i %s:")
        :format(tableType, targetLevel, targetType), true);
        textTable:AddSeparator();
        
        -- Actual attack table results
        for _, hitType in pairs(aura_env.possibleResults) do
            local chance = aura_env.tableInfo[hitType]
            local ohChance = aura_env.offHandTableInfo[hitType]
            -- local line = ("%s: %.01f%%"):format(hitType, chance) 
            local lineIdx = textTable:AddLine(hitType)
            if hitType == "Miss"
            and aura_env.config.useYellowAttackTable
            then
              chance = YELLOW_FONT_COLOR
              :WrapTextInColorCode(("%.01f%%"):format(chance));
            end
            textTable:AddCell(
              lineIdx, (
                type(chance) == "number" 
                and "%.01f%%" 
                or "%s"):format(chance));
            
            if aura_env.shouldUseOffhand() 
            and aura_env.config.showOffhand
            then
              ohChance = NIGHT_FAE_BLUE_COLOR
                :WrapTextInColorCode(("%.01f%%")
                :format(aura_env.offHandTableInfo[hitType]));
              -- line = ("%s | %s"):format(line, ohChance);
              textTable:AddCell(lineIdx, ohChance);
            end

            -- textTable:AddLine(line)
        end
        return textTable:PadCells():BuildTable()
    end
end

