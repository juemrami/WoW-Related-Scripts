-- PLAYER_TARGET_CHANGED, UNIT_STATS:player, PLAYER_EQUIPMENT_CHANGED, COMBAT_RATING_UPDATE, PLAYER_DAMAGE_DONE_MODS
aura_env.onEvent = function(event, ...)
    if UnitExists("target")
        and (event == "PLAYER_TARGET_CHANGED"
            or event == "UNIT_STATS"
            or event == "COMBAT_RATING_UPDATE"
            or (event == "PLAYER_DAMAGE_DONE_MODS" and ... == "player")
            or (event == "PLAYER_EQUIPMENT_CHANGED"
                and (... == INVSLOT_MAINHAND or ... == INVSLOT_OFFHAND))
            or event == "OPTIONS" or event == "STATUS")
    then
        aura_env.resetTable()
        aura_env.calculateTable()
        return true
    end
end
aura_env.resetTable = function()
    aura_env.missChance = 0
    aura_env.parryChance = 0
    aura_env.dodgeChance = 0
    aura_env.blockChance = 0
    aura_env.glancingChance = 0
    aura_env.glanceDR = 0
    aura_env.critChance = 0
    aura_env.critCap = 0
    aura_env.hitChance = 0
    aura_env.bonusWeaponSkill = 0
end
aura_env.calculateTable = function()
    -- Attack table calculations
    local playerLevel = UnitLevel("player")
    local targetLevel = UnitLevel("target")
    if targetLevel == -1 then
        targetLevel = playerLevel + 3
    end
    local mainWeaponSkill, offWeaponSkill
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "DRUID" then
        mainWeaponSkill = 5 * playerLevel
    else
        mainWeaponSkill, offWeaponSkill = aura_env.getWeaponSkills()
    end
    local targetDefense = targetLevel * 5                              -- 315 for level 63 mobs
    local defenseAttackSkillDiff = targetDefense - mainWeaponSkill
    local cappedWeaponSkill = min(mainWeaponSkill, playerLevel * 5)    -- 300 for lvl 60 players
    local extraWeaponSkill = max(0, mainWeaponSkill - playerLevel * 5) -- weapon skill from gear and racials
    local hit = GetHitModifier()

    local remainingPercent = 100

    -- Miss chance
    local missMod = defenseAttackSkillDiff > 10 and 0.2 or 0.1
    local dualWeildPenalty = IsDualWielding() and 19 or 0
    local baseMissChance = 5 + defenseAttackSkillDiff * missMod
    local yellowMissChance = baseMissChance
    baseMissChance = baseMissChance + dualWeildPenalty
    -- code in 1.12 explicitly adds a modifier that causes the first 1% of +hit gained from talents or gear to be ignored against monsters with more than 10 Defense Skill above the attacking player’s Weapon Skill.
    local hitPenalty = defenseAttackSkillDiff > 10 and 1 or 0
    local missChance = max(baseMissChance - (hit - hitPenalty), 0)
    aura_env.missChance = missChance
    remainingPercent = remainingPercent - missChance
    if remainingPercent <= 0 then
        aura_env.missChance = remainingPercent
        return
    end
    -- Dodge chance
    local dodgeChance = playerClass ~= "HUNTER"
        and max(5 + defenseAttackSkillDiff * 0.1, 0) or 0
    aura_env.dodgeChance = dodgeChance
    remainingPercent = remainingPercent - dodgeChance
    if remainingPercent <= 0 then
        aura_env.dodgeChance = remainingPercent
        return
    end
    -- Glancing blows
    -- extra weapon skill does not affect the chance of glancing blows
    local glancingChance = playerClass ~= "HUNTER"
        and (10 + max((targetDefense - cappedWeaponSkill) * 2, 0)) or 0;
    -- https://github.com/magey/classic-warrior/wiki/Attack-table#glancing-blows values from here
    local _glanceLowEnd = max(min(1.3 - (defenseAttackSkillDiff * 0.05), 0.91), 0.01)
    local _glanceHighEnd = max(min(1.2 - (defenseAttackSkillDiff * 0.03), 0.99), 0.2)
    local glanceDR = (_glanceLowEnd + _glanceHighEnd) / 2
    aura_env.glanceDR = (1 - glanceDR) * 100
    -- Block and Parrys
    local blockChance = 0
    local parryChance = 0
    if aura_env.config.isTargetFacingPlayer then
        if playerClass ~= "HUNTER" then
            -- Parry seems to be 14% vs +3 lvl targets, unaffected by weapon skill
            if (targetLevel - playerLevel > 2) then
                parryChance = 14
            else
                -- Unknown how it works vs lower lvl targets
                -- assume the behvaiour is the same as dodge and block
                parryChance = max(5 + defenseAttackSkillDiff * 0.1, 0)
            end
        end
        -- Mobs never have higher than 5% block chance.
        blockChance = min(5, max(5 + defenseAttackSkillDiff * 0.1, 0))
    end
    -- Order is Parry -> Glancing -> Block
    aura_env.parryChance = parryChance
    remainingPercent = remainingPercent - parryChance
    if remainingPercent <= 0 then
        aura_env.parryChance = -remainingPercent
        return
    end
    aura_env.glancingChance = glancingChance
    remainingPercent = remainingPercent - glancingChance
    if remainingPercent <= 0 then
        aura_env.glancingChance = -remainingPercent
        return
    end
    aura_env.blockChance = blockChance
    remainingPercent = remainingPercent - blockChance
    if remainingPercent <= 0 then
        aura_env.blockChance = -remainingPercent
        return
    end

    -- Crit chance
    -- GetCritChance() includes pvp 0.04 per extra skill point bonus
    local baseCrit = GetCritChance() - extraWeaponSkill * 0.04
    local cappedSkillDiff = cappedWeaponSkill - targetDefense
    local critMod = cappedSkillDiff < 0 and 0.2 or 0.04
    local critChance = baseCrit + cappedSkillDiff * critMod
    -- A flat (-1.8%) mod placed on your crit gained from auras when fighting +3 level mobs
    -- if aura crit > 0
    local auraCrit = (baseCrit - aura_env.getCritChanceFromAgility())
    local auraPentaly = (targetLevel - playerLevel > 3 and auraCrit > 0)
        and 1.8 or 0
    critChance = max(critChance - auraPentaly, 0)
    aura_env.critChance = critChance
    -- print(critChance, remainingPercent)
    remainingPercent = remainingPercent - critChance
    if remainingPercent <= 0 then
        aura_env.critChance = critChance + remainingPercent
    end
    -- Miss, parry, dodge, block, glancing blows take priority over crit, crit takes priority over hit.
    aura_env.hitChance = max(remainingPercent, 0)
    aura_env.critCap = aura_env.hitChance + aura_env.critChance
end
aura_env.getWeaponSkills = function()
    local mhSkill
    local ohSkill
    local mhItemId = GetInventoryItemID("player", INVSLOT_MAINHAND)
    local ohItemId = GetInventoryItemID("player", INVSLOT_OFFHAND)
    local _, _, mhWeaponType = GetItemInfoInstant(mhItemId or "")
    local _, _, ohWeaponType = GetItemInfoInstant(ohItemId or "")
    for i = 1, GetNumSkillLines() do
        local name, _, _, baseSkill, _, extraSkill = GetSkillLineInfo(i)
        if mhWeaponType and not mhSkill and strfind(mhWeaponType, name) then
            mhSkill = baseSkill + extraSkill
        end
        if ohWeaponType and not ohSkill and strfind(ohWeaponType, name) then
            ohSkill = baseSkill + extraSkill
        end
        if mhSkill and ohSkill then
            break
        end
    end
    if mhWeaponType == ohWeaponType then
        return mhSkill
    else
        return mhSkill, ohSkill
    end
end
aura_env.getCritChanceFromAgility = function()
    local class = select(2, UnitClass("player"))
    local agility = UnitStat("player", 2)
    local scale = {
        ["HUNTER"] = 53,
        ["ROGUE"] = 29,
        ["WARRIOR"] = 20,
        ["SHAMAN"] = 20,
        ["DRUID"] = 20,
        ["PALADIN"] = 20,
    }
    return agility / scale[class]
end
aura_env.customText = function()
    if aura_env.states[2] and aura_env.states[2].show then
        local str
        if aura_env.config.isTargetFacingPlayer then
            str = (
                "Attack Table on Target:\n"
                .. (IsDualWielding() and "Miss (DW): %0.2f%%\n" or "Miss: %0.2f%%\n")
                .. "Dodge: %0.2f%%\n"
                .. "Parry: %0.2f%%\n"
                .. "Block: %0.2f%%\n"
                .. "Glancing: %0.2f%%\n"
                .. "Glance DR: %0.2f%%\n"
                .. "Crit: %0.2f%%\n"
                .. "Hit: %0.2f%%\n"
                .. "Crit Cap: %0.2f%%\n"
            ):format(
                aura_env.missChance,
                aura_env.dodgeChance,
                aura_env.parryChance,
                aura_env.blockChance,
                aura_env.glancingChance,
                aura_env.glanceDR,
                aura_env.critChance,
                aura_env.hitChance,
                aura_env.critCap
            )
        else
            str = (
                "Attack Table: (behind target)\n"
                .. (IsDualWielding() and "Miss (DW): %0.2f%%\n" or "Miss: %0.2f%%\n")
                .. "Dodge: %0.2f%%\n"
                .. "Glancing: %0.2f%%\n"
                .. "Glance DR: %0.2f%%\n"
                .. "Crit: %0.2f%%\n"
                .. "Hit: %0.2f%%\n"
                .. "Crit Cap: %0.2f%%\n"
            ):format(
                aura_env.missChance,
                aura_env.dodgeChance,
                aura_env.glancingChance,
                aura_env.glanceDR,
                aura_env.critChance,
                aura_env.hitChance,
                aura_env.critCap
            )
        end

        return str
    end
end
