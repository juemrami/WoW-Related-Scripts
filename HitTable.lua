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
            -- print("useFakeTarget?", useFakeTarget)
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
aura_env.makeTable = function(useRaidTarget)
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
    aura_env.tableInfo["Miss"] = missChance

    -- A ranged attack cannot result in a dodge, parry, or glancing blow
    if aura_env.playerClass ~= "HUNTER" then
        -- Dodge chance
        local dodgeChance = max(5 + defenseAttackSkillDiff * 0.1, 0) or 0
        aura_env.tableInfo["Dodge"] = dodgeChance

        -- Parry
        -- Seems to be 14% vs +3 lvl targets, unaffected by weapon skill
        -- Unknown how it works vs lower lvl targets
        -- assume the behavior is the same as dodge and block
        local parryChance = aura_env.config.isTargetFacingPlayer
            and ((targetLevel - playerLevel > 2 and 14)
                or max(5 + defenseAttackSkillDiff * 0.1, 0)
            )
            or 0
        aura_env.tableInfo["Parry"] = parryChance

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
        aura_env.tableInfo["Glancing"] = glancingChance
        aura_env.tableInfo["Glance DR"] = glanceDR
    end
    -- Block
    -- Mobs never have higher than 5% block chance.
    local blockChance = aura_env.config.isTargetFacingPlayer
        and min(5, max(5 + defenseAttackSkillDiff * 0.1, 0))
        or 0
    aura_env.tableInfo["Block"] = blockChance
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
    aura_env.tableInfo["Crit"] = critChance

    -- Generate the Table
    local remainingChance = 100
    for _, attackResult
    -- Entry order: Miss, dodge, parry, glancing blows, blocks, crit, normal hit
    in ipairs(aura_env.possibleResults)
    do
        if aura_env.tableInfo[attackResult] then
            if remainingChance == 0 then
                aura_env.tableInfo[attackResult] = 0
            end
            remainingChance = remainingChance - aura_env.tableInfo[attackResult]
            if remainingChance < 0 then
                -- when the table is overflown
                -- correct the entry to not include overflown amount
                aura_env.tableInfo[attackResult] =
                    aura_env.tableInfo[attackResult] + remainingChance
                remainingChance = 0
            end
        end
    end
    -- actual hit chance is whatever is left from the 100% after all other entries
    aura_env.tableInfo["Ordinary Hit"] = remainingChance
    
    -- "Crit Cap" is the same as effective crit.
    -- It is the amount of space for Crit on the table after Block.
    -- If the space for calculated Crit is insufficient then,
    -- it is capped at whatever space is left to fill the table.
    -- If there is no space for crit, your crit is capped at 0%, ineffective.
    aura_env.tableInfo["Crit Cap"] =
        remainingChance + aura_env.tableInfo["Crit"]
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
------------------------------------------------------------------------
---Returns the crit chance gained from agility for the player's class.
---Level 60 values from https://vanilla-wow-archive.fandom.com/wiki/Attributes
---@return number
aura_env.getCritChanceFromAgility = function()
    local class = select(2, UnitClass("player"))
    local agility = UnitStat("player", 2)
    local level = UnitLevel("player")
    local agiPerCrit = {
        ["HUNTER"] = 53,
        ["ROGUE"] = 29,
        ["WARRIOR"] = 20,
        ["SHAMAN"] = 20,
        ["DRUID"] = 20,
        ["PALADIN"] = 20,
    }
    if not agiPerCrit[class] then
        return 0
    end
    if level == 25 then
        -- Unconfirmed. For SoD.
        -- Based on in-game comparing for rogue at lvl 25/40 vs 60
        -- 0.095 @ 25. approximately
        -- 0.055 @ 40
        local currentCritPerAgi = 0.055
        local maxCritPerAgi = 1 / agiPerCrit["ROGUE"] -- @ 60; 0.034%
        local levelMod = maxCritPerAgi / currentCritPerAgi
        for class, scale in pairs(agiPerCrit) do
            agiPerCrit[class] = scale * levelMod
        end
    end
    return agility / agiPerCrit[class]
end

---Builds the display text table for the weakaura.
aura_env.customText = function()
    if aura_env.state and aura_env.state.show
        and aura_env.tableInfo
    then
        local tableStr
        -- Weapon skill: %n | %n if exists
        local mhSkill, ohSkill = aura_env.getWeaponSkills()
        if mhSkill then
            tableStr = ("Weapon Skill(s): %i %s"):format(
                mhSkill, 
                ((ohSkill and ohSkill ~= mhSkill) 
                    and (("| %i\n"):format(ohSkill)) 
                    or "\n"))    
        end
        -- Header and Row Names
        local simulateLevel = (
            aura_env.config.capTargetLevel
            and UnitExists("target")
            and UnitLevel("target") > UnitLevel("player") + aura_env.config.maxLevelGap
        ) or (
            aura_env.config.forceShow
            and not UnitExists("target")
        )
        -- print("simulateLevel?", simulateLevel)
        tableStr = tableStr .. (aura_env.config.useYellowAttackTable
            and "Special Attack Table on "
            .. (simulateLevel
                and "+" .. aura_env.config.maxLevelGap .. " "
                or "") .. "Target:"
            or "Attack Table on "
            .. (simulateLevel
                and "+" .. aura_env.config.maxLevelGap .. " "
                or "") .. "Target:")

        if aura_env.playerClass == "HUNTER" then
            tableStr = tableStr .. " (Ranged)"
            aura_env.possibleResults = {
                "Miss", "Block", "Crit", "Ordinary Hit"
            }
        elseif not aura_env.config.isTargetFacingPlayer then
            tableStr = tableStr .. " (Behind)"
            aura_env.possibleResults = {
                "Miss", "Dodge", "Glancing", "Crit", "Ordinary Hit"
            }
        end
        -- Row data
        for _, hitType in pairs(aura_env.possibleResults) do
            local chance = aura_env.tableInfo[hitType]
            local line = ("\n%s: %.01f%%"):format(hitType, chance)
            if hitType == "Miss"
                and aura_env.config.useYellowAttackTable
            then
                chance = YELLOW_FONT_COLOR:WrapTextInColorCode(
                    ("%.01f%%"):format(chance)
                )
                line = ("\n%s: %s"):format(hitType, chance)
            end
            if hitType == "Glancing" then
                local key = "Glance DR"
                line = line .. (("\n%s: %0.1f%%"):format(
                    key,
                    aura_env.tableInfo[key]))
            end
            tableStr = tableStr .. line
        end
        -- add crit cap at bottom of table
        local key = "Crit Cap"
        tableStr = tableStr .. (("\n%s: %0.1f%%"):format(
            key,
            aura_env.tableInfo[key]))
        return tableStr
    end
end

