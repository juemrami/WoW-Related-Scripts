-- UPDATE_MOUSEOVER_UNIT, PLAYER_TARGET_CHANGED
aura_env.CHEPI_ID = 8361
aura_env.raidIconIndex = 3 -- diamond
aura_env.isChepiMarked = false
aura_env.onEvent = function(event, ...)
    if event == "UPDATE_MOUSEOVER_UNIT"
        or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_TARGET"
    then
        local findAndMarkChepi = function(unit)
            local npcId = aura_env.getUnitNpcID(unit)
            if npcId == aura_env.CHEPI_ID then
                aura_env.isChepiMarked = GetRaidTargetIndex(unit)
                if aura_env.isChepiMarked ~= aura_env.raidIconIndex 
                    and aura_env.canSetRaidMarkers()
                then
                    SetRaidTarget(unit, aura_env.raidIconIndex)
                    return true
                end
            end
        end
        local unit = (event == "UPDATE_MOUSEOVER_UNIT" and "mouseover")
            or ...
            or "none"

        -- first check the unit directly
        if findAndMarkChepi(unit) then
            return true
            -- then check unit's target
        elseif findAndMarkChepi(unit .. "target") then
            return true
        end
    end
end

aura_env.canSetRaidMarkers = function()
    return (CanGroupInvite and CanGroupInvite())
        or (C_PartyInfo.CanInvite and C_PartyInfo.CanInvite())
        or (not IsInGroup)
end
aura_env.getUnitNpcID = function(unit)
    local guid = UnitGUID(unit)
    if guid then
        local type, _, _, _, _, npcID = strsplit("-", guid)
        if type == "Creature" then
            return tonumber(npcID)
        end
    end
end


---@alias foo "fizz"|"buzz"?
---@alias bar ("fizz"|"buzz")?
---@alias baz "fizz"|"buzz"|nil