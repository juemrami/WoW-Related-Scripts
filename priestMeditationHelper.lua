aura_env.kneelPattern = "kneels"
aura_env.emoteReplyWindow = 10 -- seconds  
aura_env.scanUnitsEvent = {
    ["NAME_PLATE_UNIT_ADDED"] = true,
    ["NAME_PLATE_UNIT_REMOVED"] = true,
    ["GROUP_ROSTER_UPDATE"] = true,
    ["PLAYER_TARGET_CHANGED"] = true,
    ["UPDATE_MOUSEOVER_UNIT"] = true,
}
-- events: NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED, GROUP_ROSTER_UPDATE, PLAYER_TARGET_CHANGED, UPDATE_MOUSEOVER_UNIT, CHAT_MSG_TEXT_EMOTE, PLAYER_STOPPED_MOVING
aura_env.onEvent = function(states, event, ...)
    if event == "CHAT_MSG_TEXT_EMOTE" then
        ---@type string, string
        local msg, sender = ...
        ---@type string
        local senderGUID = select(12, ...)
        if senderGUID == WeakAuras.myGUID then
            for _, state in pairs(states) do
                if state.show and state.unit and state.replied then
                    state.changed = true
                    state.show = aura_env.config.kneelBack and true or false
                end
            end
            return true
        end
        if msg:find(aura_env.kneelPattern) then
            local unit = aura_env.getUnitTokenFromGUID(senderGUID)
            if unit then
                print("unit found for sender, sending using unit")
                states[senderGUID] = {
                    show = true,
                    changed = true,
                    name = sender,
                    replied = DoEmote("PRAY", unit),
                    unit = unit,
                    progressType = "timed",
                    duration = aura_env.emoteReplyWindow,
                    expirationTime = GetTime() + aura_env.emoteReplyWindow,
                    autoHide = true,
                }
                return true
            end
        end
    elseif aura_env.scanUnitsEvent[event] then
        for senderGUID, state in pairs(states) do
            if not state.unit then
                local unit = aura_env.getUnitTokenFromGUID(senderGUID)
                if unit then
                    state.replied = DoEmote("PRAY", unit)
                    state.unit = unit
                    state.changed = true
                end
            end
            return true
        end
    elseif event == "PLAYER_STOPPED_MOVING" and aura_env.config.kneelBack then
        for _, state in pairs(states) do
            if state.replied then
                state.replied = DoEmote("KNEEL")
                state.changed = true
                state.show = false
            end
        end
        return true
    end
end
aura_env.getUnitTokenFromGUID = function(guid)
    for _, unit in ipairs({ "target", "mouseover", "softfriend" })do
        if UnitGUID(unit) == guid then
            return unit
        end
        if UnitGUID(unit .. "target") == guid then
            return unit
        end
    end
    if C_CVar.GetCVarBool("nameplateShowFriends") then
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitGUID(unit) == guid then
                return unit
            end
            if UnitGUID(unit .. "target") == guid then
                return unit
            end
        end
    end
    if IsInGroup() then
        for unit in WA_IterateGroupMembers() do
            if UnitGUID(unit) == guid then
                return unit
            end
            if UnitGUID(unit .. "target") == guid then
                return unit
            end
        end
    end
end
