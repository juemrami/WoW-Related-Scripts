aura_env.ids = {
    garrote = 703,
    exsanguinate = 200806,
    talents = {
        improved_garrote = 381632,
        -- nightstalker = 14062, -- Currently Broken
    },
    empowered_auras = {}
}
if IsPlayerSpell(aura_env.ids.talents.improved_garrote) then
    tinsert(aura_env.ids.empowered_auras, 392403) -- Improved Garrote (permanent buff)
    tinsert(aura_env.ids.empowered_auras, 392401) -- Improved Garrote (3s buff)
    tinsert(aura_env.ids.empowered_auras, 375939) -- Sepsis
end
-- if IsPlayerSpell(aura_env.ids.talents.nightstalker) then
--     tinsert(aura_env.ids.empowered_auras, 1784) -- Stealth
--     tinsert(aura_env.ids.empowered_auras, 115191) -- Stealth w/ Subterfuge
--     tinsert(aura_env.ids.empowered_auras, 115192) -- Subterfuge

-- end
aura_env.player = UnitGUID("player")
-- TRIGGER:1, CLEU:SPELL_AURA_APPLIED:SPELL_AURA_REFRESH:SPELL_AURA_REMOVED:SPELL_CAST_SUCCESS
aura_env.snapshot_track = function(allstates, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local sub_event = select(2, ...)
        local source = select(4, ...)
        local spell_id = select(12, ...)
        local target_guid = select(8, ...)

        if source ~= aura_env.player
            or (spell_id ~= aura_env.ids.garrote
                and spell_id ~= aura_env.ids.exsanguinate)
        then
            return false
        end

        local check_is_empowered = function()
            for _, aura_id in ipairs(aura_env.ids.empowered_auras) do
                local is_empowered_aura = C_UnitAuras.GetPlayerAuraBySpellID(aura_id) ~= nil
                if is_empowered_aura then
                    return true
                end
            end
        end
        local is_sepsis_aura = C_UnitAuras.GetPlayerAuraBySpellID(375939) ~= nil

        if sub_event == "SPELL_AURA_APPLIED" or sub_event == "SPELL_AURA_REFRESH" then
            allstates[target_guid] = {
                show = true,
                isEmpowered = check_is_empowered(),
                isSepsis = is_sepsis_aura,
                isExsang = false,
                changed = true,
            }
        elseif sub_event == "SPELL_AURA_REMOVED"
            and allstates[target_guid] then
            allstates[target_guid]["show"] = false
            allstates[target_guid]["changed"] = true
        elseif sub_event == "SPELL_CAST_SUCCESS"
            and spell_id == aura_env.ids.exsanguinate
            and allstates[target_guid] then
            allstates[target_guid]["isExsang"] = true
            allstates[target_guid]["changed"] = true
        end
    elseif event == "TRIGGER" then
        local trigger_states = select(2, ...)
        if trigger_states[""] == nil then return end
        local unit_guid = trigger_states[""].GUID
        allstates[""] = allstates[unit_guid]
        return true
    end
end

-- does snapshot with subterfuge
-- TRIGGER:1, CLEU:SPELL_AURA_APPLIED:SPELL_AURA_REFRESH:SPELL_AURA_REMOVED:SPELL_CAST_SUCCESS
aura_env.EXSANG_ID = 200806
aura_env.RUPTURE_ID = 1943
aura_env.RUPTURE_FINALITY_ID = 385951
aura_env.snapshot_fn = function(allstates, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local sub_event = select(2, ...)
        local source_guid = select(4, ...)
        local spell_id = select(12, ...)
        local target_guid = select(8, ...)

        if source_guid ~= UnitGUID("player") then return false end
        local finality_empowered = C_UnitAuras.GetPlayerAuraBySpellID(aura_env.RUPTURE_FINALITY_ID) ~= nil
        if sub_event == "SPELL_CAST_SUCCESS"
            and spell_id == aura_env.EXSANG_ID then
            allstates[target_guid]["isExsang"] = true
            allstates[target_guid]["changed"] = true
            allstates[target_guid]["show"] = true
        elseif (sub_event == "SPELL_AURA_APPLIED"
                or sub_event == "SPELL_AURA_REFRESH")
            and spell_id == aura_env.RUPTURE_ID then
            if finality_empowered then
                -- print ("Empowered Rupture cast on " .. target_guid)
            end
            allstates[target_guid] = {
                show = true,
                isFinality = finality_empowered,
                isExsang = false,
                changed = true,
            }
        elseif sub_event == "SPELL_AURA_REMOVED" and spell_id == aura_env.RUPTURE_ID then
            allstates[target_guid]["show"] = false
            allstates[target_guid]["changed"] = true
        end
    elseif event == "TRIGGER" then
        local trigger_states = select(2, ...)
        if not (trigger_states[""] and trigger_states[""].GUID) then
            return
        end
        local unit_guid = trigger_states[""].GUID
        allstates[""] = allstates[unit_guid]
        allstates[""].changed = true
        allstates[""].show = true
        return true
    end
end
