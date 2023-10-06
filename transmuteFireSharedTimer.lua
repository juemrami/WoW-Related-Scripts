aura_env.spell_id = 25146
aura_env.name = GetSpellInfo(aura_env.spell_id)
aura_env.icon = select(3, GetSpellInfo(aura_env.spell_id))
aura_env.cd = GetSpellBaseCooldown(aura_env.spell_id) / 1000
if not aura_env.saved then
    aura_env.saved = {
        next_expiration = 0,
    }
end
-- CLEU:SPELL_CAST_SUCCESS, PLAYER_ENTERING_WORLD
aura_env.trig_fn = function(allstates, event, ...)
    if event == "PLAYER_ENTERING_WORLD"
        or event == "OPTIONS" then
        local time_casted, cd = GetSpellCooldown(aura_env.spell_id)
        if cd > 0 then
            aura_env.saved.next_expiration = time_casted + aura_env.cd
            allstates[""] = {
                show = true,
                changed = true,
                progressType = "timed",
                expirationTime = aura_env.saved.next_expiration,
                duration = aura_env.cd,
                icon = aura_env.icon,
                name = aura_env.name,
                autoHide = false,
            }
            return true
        end

        local sub_event = select(2, ...)
        if sub_event == "SPELL_CAST_SUCCESS" then
            local source_guid = select(4, ...)
            local spell_name = select(13, ...)
            if UnitGUID("player") == source_guid then
                if spell_name == aura_env.name then
                    aura_env.saved.next_expiration = GetTime() + aura_env.cd
                    allstates[""] = {
                        show = true,
                        changed = true,
                        progressType = "timed",
                        expirationTime = aura_env.saved.next_expiration,
                        duration = aura_env.cd,
                        icon = aura_env.icon,
                        name = aura_env.name,
                        autoHide = false,
                    }
                end
                return true
            end
        end
    end
end
