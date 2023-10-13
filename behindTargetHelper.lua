if not aura_env.saved then
    aura_env.saved = {
        backAttacks = {}
    }
end
aura_env.duration = 0.5
aura_env.spellRecentlyMissed = nil
-- events: CLEU:SPELL_CAST_FAILED:SPELL_CAST_SUCCESS, UI_ERROR_MESSAGE
aura_env.a = function(states, event, ...)
    if event == "UI_ERROR_MESSAGE"
        and select(2, ...) == SPELL_FAILED_NOT_BEHIND
        and  aura_env.spellRecentlyMissed
    then
        local _, _, icon = GetSpellInfo(aura_env.spellRecentlyMissed)
        states[''] = {
            show = true,
            changed = true,
            icon = icon,
            spellName = aura_env.spellRecentlyMissed,
            notBehindTarget = true,
            progressType = "timed",
            duration = aura_env.duration,
            expirationTime = GetTime() + aura_env.duration,
            autoHide = true,
        }
    end
    if event == "COMBAT_LOG_EVENT_UNFILTERED"
    and select(4, ...) == UnitGUID("player")
    then
        local subEvent = select(2, ...)
        local attackResult = strsub(subEvent, 12)
        local _, sourceName = select(4, ...)
        local spellName, _, errorText = select(13, ...)
        -- FAILED
        if (attackResult == "FAILED"
                and errorText == SPELL_FAILED_NOT_BEHIND)
        then
            aura_env.saved.backAttacks[spellName] = true
            aura_env.spellRecentlyMissed = spellName
            local _, _, icon = GetSpellInfo(spellName)
            states[''] = {
                show = true,
                changed = true,
                icon = icon,
                spellName = spellName,
                sourceName = sourceName,
                notBehindTarget = true,
                progressType = "timed",
                duration = aura_env.duration,
                expirationTime = GetTime() + aura_env.duration,
                autoHide = true,
            }
        end
        -- SUCCEESS
        if attackResult == "SUCCESS"
            and aura_env.saved.backAttacks[spellName]
            and aura_env.spellRecentlyMissed
        then
            local _, _, icon = GetSpellInfo(spellName)
            states[''] = {
                show = true,
                changed = true,
                icon = icon,
                spellName = spellName,
                notBehindTarget = false,
                progressType = "timed",
                duration = aura_env.duration*2,
                expirationTime = GetTime() + aura_env.duration*2,
                autoHide = true,
            }
        end
    end
    return true
end

-- do not include past this point
local customVars = {
    notBehindTarget = {
        type = "bool",
        display = "Casting while Not Behind Target"
    }
}
