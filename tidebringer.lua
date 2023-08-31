-- function(allstates, event, ...)
--     if event == "COMBAT_LOG_EVENT_UNFILTERED" then
--         -- https://wowpedia.fandom.com/wiki/COMBAT_LOG_EVENT#Payload
--         local sub_event = select(2,...)
--         local source = select(4,...)
--         local spell_id = select(12,...)
--         local target_guid = select(8,...)

--         if source ~= aura_env.player
--         or (spell_id ~= aura_env.ids.garrote and spell_id ~= aura_env.ids.exsanguinate) then
--             return false
--         end

--         local is_empowered_aura = false
--         for _, aura_id in ipairs(aura_env.ids.empowered_auras) do
--             is_empowered_aura = C_UnitAuras.GetPlayerAuraBySpellID(aura_id) ~= nil
--             if is_empowered_aura then break
--             end
--         end

--         if sub_event == "SPELL_AURA_APPLIED" or sub_event == "SPELL_AURA_REFRESH" then
--             allstates[target_guid] = {
--                 show = true,
--                 isEmpowered = is_empowered_aura,
--                 isExsang = false,
--                 changed = true,
--             }
--         elseif sub_event == "SPELL_AURA_REMOVED" then
--             allstates[target_guid].show = false
--         elseif sub_event == "SPELL_CAST_SUCCESS" and spell_id == aura_env.ids.exsanguinate then
--             allstates[target_guid]["isExsang"] = true
--             allstates[target_guid]["changed"] = true
--         end
--     elseif event == "TRIGGER" then
--         local trigger_states = select(2,...)
--         if trigger_states == nil then return end
--         if trigger_states[""] == nil then return end
--         local unit_guid = trigger_states[""].GUID
--         allstates[""] = allstates[unit_guid]
--         ViragDevTool:AddData(trigger_states, "trigger_states")
--         return true
--     end
-- end
--CLEU:SPELL_AURA_APPLIED:SPELL_AURA_REMOVED:SPELL_AURA_APPLIED_DOSE:SPELL_AURA_REMOVED_DOSE
B = function(allstates, event, ...)
    if event == "TIDEBRINGER_RETRIGGER" then
        if aura_env.stacks == 2 then
            C_Timer.After(8, function() WeakAuras.ScanEvents("TIDEBRINGER_RETRIGGER", true) end)
        end
    end
    local spell_id = select(12, ...)
    local source = select(4, ...)
    local sub_event = select(2, ...)
    local retrigger = select(1, ...)

    if (spell_id == 236502 and source == UnitGUID("player"))
        or retrigger == true
    then
        if sub_event == "SPELL_AURA_APPLIED_DOSE" or "SPELL_AURA_APPLIED" then
            local buff = C_UnitAuras.GetPlayerAuraBySpellID(236502)
            aura_env.stacks = buff and buff.applications or 0
            C_Timer.After(8, function() WeakAuras.ScanEvents("TIDEBRINGER_RETRIGGER", true) end)
        end

        allstates[""] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = 8,
            expirationTime = GetTime() + 8,
            autoHide = true,
            name = "Tidebringer",
            icon = 136042,
            stacks = aura_env.stacks
        }
        return true
    end
end

-- TIDEBRINGER_RETRIGGER, SPELL_AURA_APPLIED_DOSE, SPELL_AURA_APPLIED
C = function(allstates, event, ...)
    local tidebringer_id = 236502
    local tidebringer_icon = 136042
    local sub_event = select(2, ...)
    if sub_event == "SPELL_AURA_APPLIED_DOSE" or "SPELL_AURA_APPLIED" then
        local source = select(4, ...)
        local spell_id = select(12, ...)
        aura_env.stacks = select(16, ...) or 1
        if source ~= aura_env.player then return false end
        if spell_id ~= tidebringer_id then return false end
    end
    print("stacks: ", stacks)
    allstates[""] = {
        show = true,
        changed = true,
        progressType = "timed",
        duration = 8,
        expirationTime = GetTime() + 8,
        autoHide = true,
        name = "Tidebringer",
        icon = tidebringer_icon,
        stacks = aura_env.stacks
    }
    if stacks == 2 then
        C_Timer.After(8, function() WeakAuras.ScanEvents("TIDEBRINGER_RETRIGGER", _, nil) end)
    end
    return true
end
a = function(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        aura_env.npcEngaged = {}
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            local unit = plate.namePlateUnitToken
            local guid = UnitGUID(unit)
            local npcID = select(6, strsplit("-", guid))
            if npcID then npcID = tonumber(npcID) end
            -- local spellID = select(9, UnitCastingInfo(unit))
            if guid then
                aura_env.npcEngaged[guid] = true
                local count, _, _ = MDT:GetEnemyForces(npcId)
                if count then
                    aura_env.currentPullPercentage = aura_env.currentPullPercentage + count
                    aura_env.npcEngaged[guid] = true
                end
            end
        end
    end
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unit = select(1, ...)
        if unit and UnitAffectingCombat(unit) then
            local guid = UnitGUID(unit)
            local npcId = select(6, strsplit("-", guid))
            if npcId then npcId = tonumber(npcId) end
            
            local count, _, _ = MDT:GetEnemyForces(npcId)
            
            if count and not aura_env.npcEngaged then
                aura_env.currentPullPercentage = aura_env.currentPullPercentage + count
                aura_env.npcEngaged[guid] = true
            end
        end
    end
    if event == "PLAYER_REGEN_ENABLED" then
        aura_env.npcEngaged = {}
    end
end
