aura_env.PICKPOCKET = GetSpellInfo(921)

--- From testing, there is at most a 150ms delay between the CLEU event 
--- and the UNIT_FLAG event that seems to fire when mob is pickpocketed and looted.
--- the UNIT_FLAG event wont fire if the mobs pockets are empty 
aura_env.MS_BUFFER_150 = 150/1000

---@param event string CLEU:SPELL_CAST_SUCCESS, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED
aura_env.onEvent = function(states, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED"
        and select(2,...) == "SPELL_CAST_SUCCESS"
    then
        local destGUID = select(8, ...)
        local spellName = select(13, ...)
        if spellName == aura_env.PICKPOCKET 
            and not states[destGUID] 
        then
            states[destGUID] = {
                show = true,
                changed = true,
                unit = aura_env.UnitTokenFromGUID(destGUID),
                progressType = "timed",
                duration = 5*60,
                expirationTime = GetTime() + 5*60,
                autoHide = false,
                icon = select(3, GetSpellInfo(921)),
            }
            return true
        end
    elseif event:sub(1, 10) == "NAME_PLATE" then
        local unit = ...
        local guid = UnitGUID(unit)
        local added = event:sub(11) == "ADDED"
        if guid and states[guid] then
            print("found")
            states[guid].unit = added and unit or nil
            states[guid].changed = true
            return true
        end
    end
end
aura_env.UnitTokenFromGUID = UnitTokenFromGUID or function(guid)
    for i = 1,40 do
        local unit = "nameplate" .. i
        if guid == UnitGUID(unit) then
            return unit
        end
    end
end
