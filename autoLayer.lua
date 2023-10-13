aura_env.keywords = {
    "lf layer", "wtb layer", "layer me",
    "layer pls", "layer plz", "any layer",
    "inv to layer", "lf not layer", "lf non layer",
    "layer inv"
}
aura_env.negations = { "not", "off", "except", "but", "non" }
aura_env.isUsingNWB = IsAddOnLoaded("NovaWorldBuffs")
aura_env.blacklist = {
    -- [playerName] = {lastInvite = 0, lastInviteLayer = 0}
}
if not aura_env.isUsingNWB then
    WeakAuras.prettyPrint("Aura '" .. aura_env.id .. "' requires the 'NovaWorldBuffs' addon for layer detection.")
end
if not aura_env.saved then aura_env.saved = {} end
-- events: CHAT_MSG_GUILD, CHAT_MSG_CHANNEL, GROUP_ROSTER_UPDATE
aura_env.onEvent = function(event, ...)
    if event == "CHAT_MSG_GUILD"
        or (event == "CHAT_MSG_CHANNEL" and select(9, ...) == "HCElite")
        and aura_env.isUsingNWB
        and aura_env.canInvite()
    then
        -- ex: "LF layer any but 7,6,8"
        local message, sender = ...
        -- force ignore case for now
        message = strlower(message)

        local messageHasKeyword = table.foreach(
            aura_env.keywords,
            function(_, keyword)
                return strfind(message, keyword)
            end
        )
        local messageHasLayerExclusions = table.foreach(
            aura_env.negations,
            function(_, negation)
                return strfind(message, negation)
            end
        )
        if messageHasKeyword then
            local currentLayer = aura_env.getCurrentLayer() or "Unknown"
            if not aura_env.config.inviteOnUnknown
                and currentLayer == "Unknown"
            then
                aura_env.debug("Not inviting, current layer is unknown.")
                return
            end

            -- find the "not" layers in the message (if any)
            local excludedLayers = {}
            local specificLayerRequested
            if messageHasLayerExclusions then
                local possibleLayers = gmatch(message, "%d+")
                for layer in possibleLayers do
                    local layerNum = tonumber(layer)
                    if layerNum then
                        table.insert(excludedLayers, layerNum)
                    end
                end
            else -- check for *specific* layer requests
                local possibleLayers = gmatch(message, "%d+")
                for layer in possibleLayers do
                    local layerNum = tonumber(layer)
                    if layerNum and layerNum == currentLayer then
                        specificLayerRequested = currentLayer
                        break
                    end
                    aura_env.debug("Not inviting, layer " .. currentLayer .. " not requested.")
                    return
                end
            end

            aura_env.debug(sender .. " is asking for a layer to "
                .. (specificLayerRequested and currentLayer or "any")
                .. (#excludedLayers > 0
                    and " except " .. table.concat(excludedLayers, ',')
                    or ""
                ) .. '.'
            )
            -- if currently in an excluded layer, don't respond
            if #excludedLayers > 0 then
                -- if we have layer exclusions, check if we known our layer
                -- if layer is unknown check the inviteOnUnknown option.
                -- if true continue, if false return.
                -- if layer is known, check if it's in the excluded layers.
                -- if it is, return, if not continue.
                if currentLayer == "Unknown"
                    and not aura_env.config.inviteOnUnknown then
                    aura_env.debug("Not inviting, current layer is unknown.")
                    return
                elseif tContains(excludedLayers, currentLayer) then
                    aura_env.debug(
                        "Currently in an unwanted layer, not responding."
                    )
                    return
                end
            end

            aura_env.debug("Should Invite " .. sender .. " to " .. "Layer " .. currentLayer)
            -- notify player of layer being invited to
            SendChatMessage(
                "Inviting you to Layer " .. currentLayer .. ".",
                "WHISPER",
                nil,
                sender
            )
            if aura_env.config.blacklistDuration == 0 or
                not aura_env.isPlayerBlacklisted(sender) then
                -- invite the player
                InviteUnit(sender)
                aura_env.lastPlayerInvited = sender
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- check if the last player invited accepted the invite
        if aura_env.lastPlayerInvited then
            local playerJoinedGroup = false
            for unit in WA_IterateGroupMembers(false, true) do
                local name, realm = UnitFullName(unit)
                realm = realm ~= "" and realm or GetNormalizedRealmName()
                local fullName = name .. '-' .. realm
                if fullName == aura_env.lastPlayerInvited then
                    print(aura_env.lastPlayerInvited .. " joined the group.")
                    playerJoinedGroup = true
                    break
                end
            end
            -- add them to blacklist if they did
            if playerJoinedGroup then
                aura_env.debug("Adding " .. aura_env.lastPlayerInvited .. " to blacklist.")
                aura_env.blacklist[aura_env.lastPlayerInvited] = {
                    lastInvite = GetTime(),
                    lastInviteLayer = aura_env.getCurrentLayer() or "Unknown"
                }
                aura_env.lastPlayerInvited = nil
            end
        end
    end
end
aura_env.canInvite = function()
    return CanGroupInvite()
        and not C_PartyInfo.IsPartyFull()
        and not InActiveBattlefield()
        and not IsInInstance()
end
-- aura_env.config.blacklistDuration
-- Set the amount of time in seconds that a player will be blacklisted for after being invited to a layer. Used to prevent spamming invites to players who are already in your layer. Set to 0 to disable.
aura_env.isPlayerBlacklisted = function(playerName)
    local blacklistInfo = aura_env.blacklist[playerName]
    if blacklistInfo then
        local isSameLayer = blacklistInfo.lastInviteLayer == (aura_env.getCurrentLayer() or "Unknown")
        local isWithinBlacklistDuration = GetTime() - blacklistInfo.lastInvite < aura_env.config.blacklistDuration
        if not isSameLayer or not isWithinBlacklistDuration then
            aura_env.debug("Removing " .. playerName .. " from blacklist. Conditions met.")
            aura_env.blacklist[playerName] = nil
            return false
        end
    end
    return true
end
aura_env.debug = function(...)
    if aura_env.config.debug then
        print(...)
    end
end
aura_env.getCurrentLayer = function()
    -- NWB uses 0 for unknown layer
    if NWB_CurrentLayer and NWB_CurrentLayer > 0
    then
        aura_env.saved.lastKnownLayer = NWB_CurrentLayer
        return NWB_CurrentLayer
    end
    return aura_env.config.useLastKnown
        and aura_env.saved.lastKnownLayer
        or nil
end
aura_env.getCurrentLayer()
-- Instead of using "Unknown" for a layer, allows the aura to use the last known layer associated with the account (layers are preserved across characters).
