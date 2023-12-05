aura_env.FIRE_SCHOOL_ID = tInvert(SCHOOL_STRINGS)[STRING_SCHOOL_FIRE]
aura_env.COMBUSTION = "Combustion"
aura_env.IMP_SCORCH = "Improved Scorch"

---@type table<string, number> key is spellName, value is icon
aura_env.fireSpells = {
    -- comment out to not create clone
    ["Flamestrike"] = 135826,
    ["Fire Blast"] = 135807,
    ["Pyroblast"] = 135808,
    ["Fireball"] = 135812,
    ["Scorch"] = 135827,
    -- ["Frostfire Bolt"] = 236217,
    -- ["Dragon's Breath"] = 134153,
    -- ["Living Bomb"] = 236220,
    -- ["Blast Wave"] = 135903,
}

aura_env.combustionStacks = select(3, AuraUtil.FindAuraByName(aura_env.COMBUSTION, "player", "HELPFUL")) or 0

aura_env.isValidUnit = function(unit)
    return UnitExists(unit) and not UnitIsFriend("player", unit) and not UnitIsDead(unit)
end
---@type {[string]: boolean} key is GUID
aura_env.improvedScorchTargets = {}
if aura_env.isValidUnit("target") then
    aura_env.improvedScorchTargets[UnitGUID("target")]
    = select(3, AuraUtil.FindAuraByName(aura_env.IMP_SCORCH, "target", "HARMFUL")) or false
end

aura_env.unitAuraUpdate = false

---@type {[string]: {tab: number, id: number, percentCritPerRank: number, affectedSpells: string[], getBonusCrit: fun(self): number}}}
aura_env.talentData = {
    ["Incineration"] = {
        tab = 2,
        id = 15,
        percentCritPerRank = 2,
        affectedSpells = {
            "Fire Blast",
            "Scorch",
        },
        getBonusCrit = function(self)
            local _, _, _, _, ranks = GetTalentInfo(self.tab, self.id)
            return (ranks or 0) * self.percentCritPerRank
        end,
    },
    ["World in Flames"] = {
        tab = 2,
        id = 9,
        percentCritPerRank = 2,
        affectedSpells = {
            "Flamestrike",
            "Pyroblast",
            "Blast Wave",
            "Dragon's Breath",
            "Living Bomb",
        },
        getBonusCrit = function(self)
            local _, _, _, _, ranks = GetTalentInfo(self.tab, self.id)
            return (ranks or 0) * self.percentCritPerRank
        end,
    },
    ["Improved Scorch"] = {
        tab = 2,
        id = 3,
        percentCritPerRank = 2,
        affectedSpells = {
            "Scorch",
            "Fireball",
            "Frostfire Bolt",
        },
        getBonusCrit = function(self)
            local _, _, _, _, ranks = GetTalentInfo(self.tab, self.id)
            return (ranks or 0) * self.percentCritPerRank
        end,
    }
}

aura_env.lastCheck = 0
aura_env.throttle = 1

-- events: PLAYER_DAMAGE_DONE_MODS, COMBAT RATING UPDATE, CLEU:SPELL_AURA_APPLIED:SPELL_AURA_APPLIED_DOSE:SPELL_AURA_REMOVED, PLAYER_TARGET_CHANGED
aura_env.onEvent = function(states, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local changed = aura_env.auraHandler(...)
        if changed then 
            aura_env.lastCheck = 0
        else 
            return false 
        end
    elseif event == "PLAYER_DAMAGE_DONE_MODS" and ... ~= "player" then 
        return false
    elseif event == "PLAYER_TARGET_CHANGED" 
        and not aura_env.isValidUnit("target")
    then
        return false
    end
    local currentTime = GetTimePreciseSec()
    if currentTime > aura_env.lastCheck + aura_env.throttle then
        -- print("last update: ", aura_env.lastCheck, "time: ", currentTime, "throttle: ", aura_env.throttle, "diff: ", currentTime - aura_env.lastCheck)
        print("updating ", event )
        local baseFireCrit = GetSpellCritChance(aura_env.FIRE_SCHOOL_ID)
        -- Combustion gives an additional 10% for each stack of the buff, start with 1 stack.
        local combustionCrit = aura_env.combustionStacks * 10
        -- print("combustion crit: " .. combustionCrit)

        -- if target is afflicted by imp scorch base fire crit is +5%
        local impScorchDebuffCrit = 0
        if aura_env.isValidUnit("target") then
            local targetGUID = UnitGUID("target")
            impScorchDebuffCrit = aura_env.improvedScorchTargets[targetGUID]
                and 5 or 0
        end
        -- print("imp scorch crit: " .. impScorchDebuffCrit)
        local fireSpellCrit = baseFireCrit + combustionCrit + impScorchDebuffCrit;
        -- print("fire spell crit: " .. fireSpellCrit)
        local anyStateChanged = false
        for spellName, icon in pairs(aura_env.fireSpells) do
            local state = states[spellName]
            if not state then
                state = {
                    show = true,
                    name = spellName,
                    icon = icon,
                }
            end
            local bonusSpecificSpellCrit = 0
            -- check each talent to see if it affects this spell
            for talentName, talentInfo in pairs(aura_env.talentData) do
                if tContains(talentInfo.affectedSpells, spellName) then
                    -- add the bonus crit from the talent if affected
                    bonusSpecificSpellCrit = bonusSpecificSpellCrit + talentInfo:getBonusCrit()
                    -- print(spellName .. " affected by talent " .. talentName .. " | bonus crit: " .. bonusSpecificSpellCrit)
                else
                    -- print("talent ".. talentName .. " does not affect spell ".. spellName)
                end
            end

            local spellCrit = fireSpellCrit + bonusSpecificSpellCrit
            -- print("total spell crit: " .. spellCrit)
            if state.spellCrit ~= spellCrit then
                state.changed = true
                anyStateChanged = true
            end
            -- print("state changed: " .. tostring(anyStateChanged))
            state.spellCrit = spellCrit
            states[spellName] = state
        end

        aura_env.lastCheck = currentTime
        return anyStateChanged
    end
end

---Handles watching for players combustion and improved scorch stacks. Also sets the `aura_env.combustionStacks` and `aura_env.improvedScorchTargets` variable
---@param ... any CLEU args
---@return boolean true if related event was handled
aura_env.auraHandler = function(...)
    local sourceGUID, _, _, _, destGUID, destFlags = select(4, ...)
    local spellId, spellName = select(12, ...)
    -- local destGUID = select(8, ...)
    if sourceGUID == WeakAuras.myGUID then
        local subEvent = select(2, ...)
        if spellName == aura_env.COMBUSTION then
            if subEvent == "SPELL_AURA_APPLIED" then
                aura_env.combustionStacks = 1
                return true
            elseif subEvent == "SPELL_AURA_APPLIED_DOSE" then
                aura_env.combustionStacks = select(16, ...) or (aura_env.combustionStacks + 1)
                return true
            elseif subEvent == "SPELL_AURA_REMOVED" then
                aura_env.combustionStacks = 0
                return true
            end
            -- print("combustion stacks: " .. aura_env.combustionStacks)
        end
        if spellName == aura_env.IMP_SCORCH and destGUID then
            if subEvent == "SPELL_AURA_APPLIED" then
                aura_env.improvedScorchTargets[destGUID] = true
                return true
            elseif subEvent == "SPELL_AURA_REMOVED" then
                aura_env.improvedScorchTargets[destGUID] = nil
                return true
            end
        end
    end
    return false
end

-- aura_env.fireTalentTab = 2
-- aura_env.talentIds = {
--     15, -- Incineration 2% on FireBlast and Scorch per rank
--     9,  -- World in Flames 2% on Flamestrike, Pyro, Blast Wave, DB, Living Bomb per rank
--     3,  -- Imp Scorch, 2% Scorch, Fireball, FFB per rank
--     11, -- Critical Mass 2% on base fire crit per rank (should be accounted for in the base crit)
--     20, -- Pyromaniac 1% on **base crit** per rank (should be accounted for in the base crit)
-- }
