-- UPDATE_MOUSEOVER_UNIT, PLAYER_TARGET_CHANGED
aura_env.CHEPI_ID = 8361
aura_env.raidIconIndex = 3 -- diamond
aura_env.chepiFound = false
aura_env.onEvent = function(event, ...)
    if event == "UPDATE_MOUSEOVER_UNIT"
        or event == "PLAYER_TARGET_CHANGED"
    then
        local unit = event:find("MOUSEOVER") and "mouseover" or "target"
        local unitName = UnitName(unit)
        if unitName == "Chepi" and not aura_env.chepiFound then
            aura_env.chepiFound = true
            if not GetRaidTargetIndex(unitTarget) == aura_env.raidIconIndex then
                SetRaidTarget(unitTarget, aura_env.raidIconIndex)
            end
            return true
        end
        -- check unit's target
        local unitTargetName = UnitName(unit .. "target")
        if unitTargetName == "Chepi" and not aura_env.chepiFound then
            aura_env.chepiFound = true
            SetRaidTarget(unit .. "target", aura_env.raidIconIndex)
            return true
        end
    elseif event == "UNIT_TARGET" then
        local unitTarget = ... .. "target"
        local unitTargetName = UnitName(unitTarget)
        if unitTargetName == "Chepi" and not aura_env.chepiFound then
            aura_env.chepiFound = true
            if not GetRaidTargetIndex(unitTarget) == aura_env.raidIconIndex then
                SetRaidTarget(unitTarget, aura_env.raidIconIndex)
            end
            return true
        end
    end
end
