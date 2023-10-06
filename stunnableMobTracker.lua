aura_env.presetMobIDs = {
    -- paste output ids below
    15338, 15327, 15392, 15391, 13021,
}
if not aura_env.saved then
    aura_env.saved = {
        isMobStunnable = {}
    }
end
for _, npcID in ipairs(aura_env.presetMobIDs) do
    aura_env.saved.isMobStunnable[tostring(npcID)] = false
end
aura_env.trackedStuns = {
    ["Kidney Shot"] = true,
    ["Cheap Shot"] = true,
    ["Hammer of Justice"] = true,
    ["Bash"] = true,
    ["Impact"] = true,
    ["Blackout"] = true,
    ["Charge Stun"] = true,
}
-- events: PLAYER_TARGET_CHANGED, CLEU:SPELL_MISSED:SPELL_AURA_APPLIED, PLAYER_ENTERING_WORLD
aura_env.onEvent = function(allstates, event, ...)
    if event == "PLAYER_ENTERING_WORLD"
        and aura_env.config.displaySavedOnLoad
    then
        local idList = ""
        for npcID, stunnable in pairs(aura_env.saved.isMobStunnable) do
            if not stunnable then
                idList = idList .. npcID .. ", "
            end
        end
        if idList ~= "" then
            print("Unstunnable NPC IDs: " .. idList)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local subEvent = select(2, ...)
        local targetGUID = select(8, ...)
        local spellName = select(13, ...)
        if subEvent == "SPELL_AURA_APPLIED"
            and aura_env.trackedStuns[spellName]
        then
            local npcID = select(6, strsplit("-", targetGUID))
            if npcID then
                aura_env.saved.isMobStunnable[npcID] = true
            end
        elseif subEvent == "SPELL_MISSED" and select(15, ...) == "IMMUNE"
            and aura_env.trackedStuns[spellName]
        then
            local npcID = select(6, strsplit("-", targetGUID))
            if npcID
                and not aura_env.saved.isMobStunnable[npcID]
            then
                aura_env.saved.isMobStunnable[npcID] = false
            end
        end
    end
    if UnitExists("target") and not UnitIsPlayer("target") then
        local targetGUID = UnitGUID("target")
        local npcID = select(6, strsplit("-", targetGUID))
        if npcID then
            local stunnable = aura_env.saved.isMobStunnable[npcID]
            local stunnableStatus = stunnable == nil
                and "Unknown"
                or (stunnable and "Stunnable" or "Not Stunnable")
            local show = false
            if aura_env.config.showOn == 1 then
                -- Show On: Always
                show = true
            elseif aura_env.config.showOn == 2 then
                -- Show On: Not Stunnable
                show = stunnable == false
            elseif aura_env.config.showOn == 3 then
                -- Show On: Stunnable
                show = stunnable
            elseif aura_env.config.showOm == 4 then
                -- Show On: Not Unknown
                show = stunnable ~= nil
            end
            allstates[""] = {
                show = show,
                changed = true,
                stunnable = stunnable,
                stunnableStatus = stunnableStatus,
                autoHide = false
            }
            return true
        end
    else
    allstates[""] = {
        show = false,
        changed = true,
    }
    end
    return true
end
-- NOT PART OF CUSTOM CODE--
-- If checked will output the current list of IDs, for NPCs known to not be stunnable, whenever the player loads into the world. The output ids should be copy pasted into the "presetMobIDs" table in the custom code section of the "Actions" tab.
-- "Always" will make it so that aura is always visible. "Not Stunnable" will show the aura when target is . "Stunnable" will show the aura when the target is known to be stunnable.
stunnableStatus = {
    display = "Stunnable Status",
    type = "select",
    values = {
        ["Stunnable"] = "Stunnable",
        ["Not Stunnable"] = "Not Stunnable",
        ["Unknown"] = "Unknown",
    }
}
