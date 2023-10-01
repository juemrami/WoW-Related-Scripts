-- PLAYER_TARGET_CHANGED, UNIT_STATS:player, PLAYER_EQUIPMENT_CHANGED, COMBAT_RATING_UPDATE, PLAYER_DAMAGE_DONE_MODS

aura_env.resetTable = function()
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
aura_env.resetTable()
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
        aura_env.makeTable()
        return true
    end
end
aura_env.makeTable = function()
    -- Attack table calculations
    local playerLevel = UnitLevel("player")
    local playerClass = select(2, UnitClass("player"))
    local targetLevel = UnitLevel("target")
    if targetLevel == -1 then
        -- ?? level target
        targetLevel = playerLevel + 3
    end
    local mainWeaponSkill, offWeaponSkill = aura_env.getWeaponSkills()
    local targetDefenseSkill = targetLevel * 5                           -- 315 for level 63 mobs
    local defenseAttackSkillDiff = targetDefenseSkill - mainWeaponSkill
    local cappedWeaponSkill = min(mainWeaponSkill, playerLevel * 5)      -- 300 for lvl 60 players
    local extraWeaponSkill = max(0, mainWeaponSkill - cappedWeaponSkill) -- bonus weapon skill
    local hit = GetHitModifier()

    -- Miss chance
    local missMod = defenseAttackSkillDiff > 10 and 0.2 or 0.1
    local dualWeildPenalty = IsDualWielding() and 19 or 0
    local baseMissChance = 5 + defenseAttackSkillDiff * missMod
    local yellowMissChance = baseMissChance
    baseMissChance = baseMissChance + dualWeildPenalty
    -- code in 1.12 explicitly adds a modifier that causes the first 1% of +hit gained from talents or gear to be ignored against monsters with more than 10 Defense Skill above the attacking player’s Weapon Skill.
    local hitPenalty = defenseAttackSkillDiff > 10 and 1 or 0
    local missChance = max(baseMissChance - (hit - hitPenalty), 0)
    aura_env.tableInfo["Miss"] = missChance
    if playerClass ~= "HUNTER" then
        -- Dodge chance
        local dodgeChance = max(5 + defenseAttackSkillDiff * 0.1, 0) or 0
        aura_env.tableInfo["Dodge"] = dodgeChance

        -- Parry
        -- Seems to be 14% vs +3 lvl targets, unaffected by weapon skill
        -- Unknown how it works vs lower lvl targets
        -- assume the behvaiour is the same as dodge and block
        local parryChance = aura_env.config.isTargetFacingPlayer
            and ((targetLevel - playerLevel > 2)
                and 14 or max(5 + defenseAttackSkillDiff * 0.1, 0))
            or 0
        aura_env.tableInfo["Parry"] = parryChance

        -- Glancing blows
        -- extra weapon skill does not affect the chance of glancing blows
        local glancingChance = (10 + max((targetDefenseSkill - cappedWeaponSkill) * 2, 0))
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
    -- GetCritChance() includes pvp 0.04 per extra skill point bonus
    local baseCrit = GetCritChance() - extraWeaponSkill * 0.04
    local cappedSkillDiff = cappedWeaponSkill - targetDefenseSkill
    local critMod = cappedSkillDiff < 0 and 0.2 or 0.04
    local critChance = baseCrit + cappedSkillDiff * critMod
    -- A flat (-1.8%) mod placed on your crit gained from auras when fighting +3 level mobs
    -- if aura crit > 0
    local auraCrit = (baseCrit - aura_env.getCritChanceFromAgility())
    local auraPentaly = (targetLevel - playerLevel > 3 and auraCrit > 0)
        and 1.8 or 0
    critChance = max(critChance - auraPentaly, 0)
    aura_env.tableInfo["Crit"] = critChance
    -- Miss, dodge, parry, glancing blows, blocks take priority over crit, crit takes priority over hit.

    -- aura_env.hitChance = max(remainingPercent, 0)
    local remainingChance = 100
    for _, attackType
    in ipairs({ "Miss", "Dodge", "Parry", "Block", "Glancing", "Crit" })
    do
        if aura_env.tableInfo[attackType] then
            if remainingChance == 0 then
                aura_env.tableInfo[attackType] = 0
            end
            remainingChance = remainingChance - aura_env.tableInfo[attackType]
            if remainingChance < 0 then
                aura_env.tableInfo[attackType] = -remainingChance
                remainingChance = 0
            end
        end
    end
    aura_env.tableInfo["Ordinary Hit"] = remainingChance
    aura_env.tableInfo["Crit Cap"] = remainingChance + aura_env.tableInfo["Crit"]
end
aura_env.getWeaponSkills = function()
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "DRUID" then
        return 5 * UnitLevel("player")
    end
    local mhSkill
    local ohSkill
    local mhItemId = GetInventoryItemID("player", INVSLOT_MAINHAND)
    local ohItemId = GetInventoryItemID("player", INVSLOT_OFFHAND)
    local _, _, mhWeaponType = GetItemInfoInstant(mhItemId or "")
    local _, _, ohWeaponType = GetItemInfoInstant(ohItemId or "")
    -- "subType" for weapons can be "One-Handed Axes" or "One-Handed Maces"
    -- but the skill in the skillLines are labeled as just "Axes" or "Maces"
    local oneHandedWeaps = { ["Axes"] = true, ["Swords"] = true, ["Maces"] = true }

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, baseSkill, _, extraSkill = GetSkillLineInfo(i)
        if not isHeader then
            if oneHandedWeaps[skillName] then
                skillName = "One-Handed " .. skillName
            end
            -- print(mhWeaponType, skillName)
            if mhWeaponType and not mhSkill and mhWeaponType == skillName then
                mhSkill = baseSkill + extraSkill
            end
            if ohWeaponType and not ohSkill and ohWeaponType == skillName then
                ohSkill = baseSkill + extraSkill
            end
            if mhSkill and ohSkill then
                break
            end
        end
    end
    return mhSkill, ohSkill
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
    -- print(aura_env.tableInfo)
    -- print(#aura_env.tableInfo)
    if aura_env.states[2] and aura_env.states[2].show 
    and aura_env.tableInfo then
        local str
        for label, value in pairs(aura_env.tableInfo) do
            str = (str and str .. "\n" or "") .. label .. ": " .. value .. "%"
            -- print(str)
        end
        return str
    end
end
