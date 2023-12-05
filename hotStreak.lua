-- events: CLEU:SPELL_DAMAGE:SPELL_AURA_REMOVED:SPELL_AURA_APPLIED
aura_env.trackedSpells = {
    ["Fireball"] = 135812,
    ["Fire Blast"] = 135807,
    ["Scorch"] = 135827,
    ["Living Bomb"] = 236220,
    ["Frostfire Bolt"] = 236217,
    -- ["Hot Streak"] = 236218
}
aura_env.streakCount = 0
aura_env.hotStreakTriggered = false
aura_env.hotStreakActive = false
aura_env.onEvent = function(states, event, ...)
    local sourceGUID = select(4, ...)
    local spellName = select(13, ...)
    local oldStreak = aura_env.streakCount
    if sourceGUID == WeakAuras.myGUID then
        local subEvent = select(2, ...)
        if subEvent == "SPELL_DAMAGE" and aura_env.trackedSpells[spellName] then
            local isCrit = select(21, ...)
            if isCrit and not aura_env.hotStreakActive then
                -- Allow 3 charges. 1 heating up. 2 hot streak. 3 banked
                if oldStreak < 3 then
                    aura_env.streakCount = oldStreak + 1
                end
            elseif not isCrit then
                if aura_env.hotStreakActive then
                    aura_env.streakCount = 2
                else
                    aura_env.streakCount = 0
                end
            end
        end
        if spellName == "Hot Streak" then
            if subEvent == "SPELL_AURA_APPLIED" 
                or subEvent == "SPELL_AURA_REFRESH" 
            then
                aura_env.hotStreakTriggered = true
                if aura_env.streakCount < 2 then
                    -- hack, this should never be the case
                    -- if were updating the count properly with crit events.
                    print("Hot Streak applied with streakCount < 2")
                    aura_env.streakCount = 2
                end
                aura_env.hotStreakActive = true
            elseif subEvent == "SPELL_AURA_REMOVED" then
                aura_env.streakCount = max(oldStreak - 2, 0)
                aura_env.hotStreakActive = false
            end
        end
    end
    if aura_env.streakCount ~= oldStreak 
        or aura_env.hotStreakTriggered
    then
        states[""] = {
            show = (aura_env.streakCount > 0) or InCombatLockdown(),
            changed = true,
            stacks = aura_env.streakCount,
            streakCount = aura_env.streakCount
        }
        if aura_env.hotStreakActive then
            states[""].progressType = "timed"
            states[""].duration = 10
            states[""].expirationTime = GetTime() + 10
            aura_env.hotStreakTriggered = false              
        end
        return true
    end
    if event == "OPTIONS" then
        local streak = random(1, 3)
        states[""] = {
            show = true,
            changed = true,
            streakCount = streak
        }
        if streak >= 2 then
            states[""].progressType = "timed"
            states[""].duration = 10
            states[""].expirationTime = GetTime() + 10
        end
    end
end
