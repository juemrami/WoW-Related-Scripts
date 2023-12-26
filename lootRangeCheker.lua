-- events: PLAYER_REGEN_DISABLED, GROUP_ROSTER_UPDATE, ENCOUNTER_START, CLEU, PLAYER_STARTED_MOVING, PLAYER_STOPPED_MOVING
---@type table<yards, itemId[]>
aura_env.rangeItems = {
    -- 100 yards
    [100] = {
        4144, 5418, 8773, 8795, 
        8900, 8760, 15769, 17162, 
        23719, 23721, 23722, 23715, 23718
    }
}
aura_env.onEvent = function(states, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local sourceGUID, _,_,_, destGUID = select(4, ...)
        if sourceGUID ~= WeakAuras.myGUID 
        or destGUID == WeakAuras.myGUID then
            return
        end
    end
    local changed = false
    for _, state in pairs(states) do
       state.changed = true
       state.show = false
    end
    for unit in WA_IterateGroupMembers() do
        if unit ~= "player" then
            local inRange = aura_env.unitInRange(unit, 100)
            if not states[unit] or states[unit].inRange ~= inRange then
                local class = select(2, UnitClass(unit))
                local name = UnitName(unit)
                states[unit] = {
                    inRange = inRange,
                    changed = true,
                    show = true,
                    unit = unit,
                    name = name,
                    formatName = name and RAID_CLASS_COLORS[class]:WrapTextInColorCode(name),
                    rangeStr = inRange and "in range" or "out of range"
                    
                }
                changed = true
            end
        end
    end
    return changed
end
aura_env.unitInRange = function(unit, range)
    local inRange = false
    for i = 1, #aura_env.rangeItems[range] do
        local itemId = aura_env.rangeItems[range][i]
        if IsItemInRange(itemId, unit) then
            inRange = true
            break
        end
    end
    return inRange
end

---@alias yards number
---@alias itemId number