if not aura_env.saved then
    aura_env.saved = {
        -- initial values, programmatically changed.
        resists = 0,
        nonResists = 0,
    }
end
aura_env.sessionResists = 0
aura_env.trackedKicks = {
    ["Kick"] = true,
    ["Pummel"] = true,
    ["Earth Shock"] = true,
    ["Shield Bash"] = true,
    ["Counterspell"] = true,
    ["Spell Lock"] = true,
    ["Silence"] = true,
    ["Kick - Silenced"] = true,
}
-- events: CLEU:SPELL_CAST_START:SPELL_CAST_SUCCESS:SPELL_CAST_FAILED:SPELL_INTERRUPT
aura_env.onEvent = function(event, ...)
    local subEvent = select(2, ...)

    local sourceGUID = select(4, ...)
    local destGUID = select(8, ...)
    local spellName = select(13, ...)
    if subEvent == "SPELL_CAST_START" and sourceGUID == UnitGUID("player")
    then
        -- might not be necessary
        aura_env.lastCast = {
            name = spellName,
            start = GetTime()
        }
    elseif subEvent == "SPELL_CAST_SUCCESS"
        and aura_env.trackedKicks[spellName]
        and destGUID == UnitGUID("player")
    -- we've just been kicked
    then
        -- check if we are still casting
        local castName, _, castIcon, castStart, castEnd, castGUID = CastingInfo()
        if castName then
            -- kick resisted
            aura_env.saved.resists = aura_env.saved.resists + 1
            aura_env.sessionResists = aura_env.sessionResists + 1
            if aura_env.lastCast then
                --print("debug times match: ", aura_env.lastCast.start == castStart)
            end
            aura_env.resistedKick = spellName
            aura_env.currentCast = castName
            aura_env.currentCastIcon = castIcon
            return true
        else
            -- possibly interrupted
            -- could also just have not been casting
            -- check on SPELL_INTERRUPT event
        end
    elseif subEvent == "SPELL_CAST_SUCCESS"
        and sourceGUID == UnitGUID("player")
    then
        -- check if lastCast was successful to reset it
        if aura_env.lastCast and aura_env.lastCast.name == spellName then
            aura_env.lastCast = nil
        end
    elseif subEvent == "SPELL_INTERRUPT"
        and destGUID == UnitGUID("player")
    then
        local interruptedSpell = select(16, ...)
        if aura_env.lastCast and aura_env.lastCast.name == interruptedSpell then
            aura_env.saved.nonResists = aura_env.saved.nonResists + 1
        end
    end
end

-- alternative using castGUID
-- event: UNIT_SPELLCAST_START, UNIT_SPELLCAST_SUCCEEDED, CLEU:SPELL_CAST_SUCCESS
aura_env.onEvent = function(event, ...)
    if event == "UNIT_SPELLCAST_START"
        and ... == "player"
    then
        aura_env.lastCast = select(2, ...) -- castGUID
    elseif event == "UNIT_SPELLCAST_SUCCEEDED"
        and ... == "player"
    then
        local castGUID = select(2, ...)
        if aura_env.lastCast and aura_env.lastCast == castGUID then
            aura_env.lastCast = nil
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local subEvent = select(2, ...)
        local sourceGUID = select(4, ...)
        local destGUID = select(8, ...)
        local spellName = select(13, ...)
        -- check for kicks against player
        if subEvent == "SPELL_CAST_SUCCESS"
            and aura_env.trackedKicks[spellName]
            and destGUID == UnitGUID("player")
        then
            -- check for any casting info after successful enemy kicks
            local castName, _, castIcon, _, _, castGUID = CastingInfo()
            if castGUID then
                -- if cast info is found it means kick was resisted
                aura_env.saved.resists = aura_env.saved.resists + 1
                aura_env.sessionResists = aura_env.sessionResists + 1
                aura_env.resistedKick = spellName
                aura_env.currentCast = castName
                aura_env.currentCastIcon = castIcon
                -- activate aura
                return true
            end
        elseif subEvent == "SPELL_INTERRUPT"
            and destGUID == UnitGUID("player")
            and aura_env.lastCast
        then
            local interruptedSpell = select(16, ...)
            local lastCastID = select(6, strsplit("-", aura_env.lastCast))
            local lastCastName = GetSpellInfo(lastCastID)
            if lastCastName == interruptedSpell then
                aura_env.saved.nonResists = aura_env.saved.nonResists + 1
                aura_env.lastCast = nil
            end
        end
    end
end
-- not part of aura
CastingInfo = function() return UnitCastingInfo("player") end
WeakAuras.IsOptionsOpen()
