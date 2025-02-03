aura_env.keywords = { -- case insensitive. be specific to avoid false positives
    "lf layer", "wtb layer", "layer me",
    "layer pls", "layer plz", "any layer",
    "inv to layer", "lf not layer", "lf non layer",
    "layer inv", "inv layer", "layer invite", "layer off"
}
aura_env.negations = { "not", "off", "except", "but", "non" }
local IS_NWB_LOADED = IsAddOnLoaded("NovaWorldBuffs")
if not IS_NWB_LOADED then
    WeakAuras.prettyPrint("Aura '" .. aura_env.id .. "' requires the 'NovaWorldBuffs' addon for layer detection.")
    aura_env.onEvent = function() end;
    return;
end
local CURRENT_REALM = GetNormalizedRealmName()
local ERR_ALREADY_IN_GROUP = ERR_ALREADY_IN_GROUP_S:gsub("%%s", "(%%S+)")
local ERR_DECLINE_GROUP = ERR_DECLINE_GROUP_S:gsub("%%s", "(%%S+)")
local getNormalizedName = function(fullName)
    if not fullName then return nil; end
    local name, realm = strsplit("-", fullName); -- if same realm, ignore realm
    return (not realm or realm ~= CURRENT_REALM) and fullName or name
end
local shouldTrySendInvite = function()
    return CanGroupInvite() -- has invite perms
        and not C_PartyInfo.IsPartyFull() -- party not full
        and not InActiveBattlefield() -- not in a BG
        and not IsInInstance() -- not in an instance
end
aura_env.blacklist = { --[[playerName] = {lastInvite = 0, lastInviteLayer = 0}]] };
aura_env.pendingInvites = { --[[playerName] = true]] };
if not aura_env.saved then aura_env.saved = {
    lastKnownLayer = { --[[realmName]: layerNumber]]},
} end;
-- events: CHAT_MSG_GUILD, CHAT_MSG_CHANNEL, GROUP_ROSTER_UPDATE, CHAT_MSG_SYSTEM
aura_env.onEvent = function(event, ...)
    if event == "CHAT_MSG_GUILD"
        or (aura_env.allowedChannels
            and event == "CHAT_MSG_CHANNEL"
            and aura_env.allowedChannels[strlower(select(9, ...) or "")])
        and select(12, ...) ~= WeakAuras.myGUID
        and shouldTrySendInvite()
    then
        -- ex: "LF layer any but 7,6,8"
        local message, sender = ...;
        -- bugfix: anniversary realms dont like when you add realm to player name when using the InviteUnit function
        sender = getNormalizedName(sender)
        if not sender then return end
        if aura_env.pendingInvites[sender] then
            aura_env.debug("Ignoring message from " .. sender .. ". Already pending invite.")
            return;
        end
        message = strlower(message) -- force ignore case for now
        local messageHasKeyword = table.foreach(aura_env.keywords,
            function(_, keyword) return strfind(message, keyword) end
        )
        local messageHasLayerExclusions = table.foreach(aura_env.negations,
            function(_, negation) return strfind(message, negation) end
        )
        if messageHasKeyword then
            local currentLayer = aura_env.getCurrentLayer()
            local requestedLayers, excludedLayers = {}, {};
            -- Im assuming a request would never ask for both layer exclusions AND specific layers
            if messageHasLayerExclusions then -- check for layer exclusions
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
                    if layerNum then
                        table.insert(requestedLayers, layerNum)
                    end
                end
            end
            aura_env.debug(sender .. " is asking for a layer to "
                .. (#requestedLayers > 0 and table.concat(requestedLayers, ',') or "any")
                .. (#excludedLayers > 0 and " except " .. table.concat(excludedLayers, ',') or "")
            );
            if aura_env.isCurrentLayerOk(requestedLayers, excludedLayers)
            and (aura_env.config.blacklistDuration == 0 or not aura_env.isPlayerBlacklisted(sender))
            then
                aura_env.debug("Should Invite " .. sender .. " to " .. "Layer " .. currentLayer)
                -- notify player of layer being invited to
                SendChatMessage("Sending invite to Layer " .. currentLayer .. ".",
                    "WHISPER", nil, sender
                );
                -- invite the player
                InviteUnit(sender)
                aura_env.pendingInvites[sender] = true;
            end
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        if not next(aura_env.pendingInvites) then return end;
        local message = ... ---@type string
        local player = getNormalizedName(strmatch(message, ERR_ALREADY_IN_GROUP))
        if player and aura_env.pendingInvites[player] then -- player is already in a group
            aura_env.pendingInvites[player] = nil
            SendChatMessage("Invite failed. You are in a group.", "WHISPER", nil, player);
            return;
        end
        player = getNormalizedName(strmatch(message, ERR_DECLINE_GROUP))
        if player and aura_env.pendingInvites[player] then -- player declined the invite
            aura_env.pendingInvites[player] = nil
            return;
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if not next(aura_env.pendingInvites) then return end;
        -- check if recently invited players accepted the invite
        local recentInvitesAccepted = {};
        for unit in WA_IterateGroupMembers(false, true) do
            local name, realm = UnitNameUnmodified(unit)
            local player = name .. (realm  and ('-' .. realm) or "")
            if aura_env.pendingInvites[player] then
                recentInvitesAccepted[player] = true
                aura_env.pendingInvites[player] = nil
                if not next(aura_env.pendingInvites) then break end;
            end
        end
        for player, _ in pairs(recentInvitesAccepted) do -- add them to blacklist if they did
            aura_env.debug(("Adding %s to blacklist for %i seconds.")
                :format(player, aura_env.config.blacklistDuration)
            );
            aura_env.blacklist[player] = {
                lastInvite = GetTime(),
                lastInviteLayer = aura_env.getCurrentLayer(),
            };
        end
    end
end

---@param requestedLayers number[]
---@param excludedLayers number[]
aura_env.isCurrentLayerOk = function(requestedLayers, excludedLayers)
    local currentLayer = aura_env.getCurrentLayer() or "Unknown"
    if not aura_env.config.inviteOnUnknown and currentLayer == "Unknown"
    then
        aura_env.debug("Not responding, our current layer is unknown.")
        return
    end
    if #excludedLayers > 0 then
        if tContains(excludedLayers, currentLayer) then
            aura_env.debug("Currently in an unwanted layer, not responding.")
            return false
        end
        -- its okay to invite people when layer is unknown and they have specified exclusions-
        -- because it doesn't burn a layer cooldown inviting to same layer.
        -- Also, they can just try again. Plus it lets NWB share layer info with us :)
    end
    if #requestedLayers > 0 then
        -- however if they specify layers, we should only respond if we know our layer-
        -- irregardless of the inviteOnUnknown setting.
        -- This, prevents burning someone's layer cd on a layer not being requested
        if currentLayer == "Unknown" then
            aura_env.debug("Not responding, our current layer is unknown.")
            return false
        elseif not tContains(requestedLayers, currentLayer) then
            aura_env.debug("Not in a specified layer, not responding.")
            return false
        end
    end
    -- (we are NOT in an excluded layer OR we are in a requested layer)
    -- OR (nothing was specified so anything goes)
    return true

end
aura_env.setupAllowedChannels = function()
    if not aura_env.config.allowedChannels or aura_env.config.allowedChannels == "" then
        aura_env.allowedChannels = false -- better than nil
        return;
    end;
    aura_env.allowedChannels = {}
    local channels = {strsplit(" ", aura_env.config.allowedChannels)}
    for _, channel in ipairs(channels) do
        channel = strtrim(channel)
        if strlen(channel) > 0 then aura_env.allowedChannels[strlower(channel)] = true end
    end
    if not next(aura_env.allowedChannels) then aura_env.allowedChannels = false end
end
aura_env.isPlayerBlacklisted = function(playerName)
    local blacklistInfo = aura_env.blacklist[playerName]
    if not blacklistInfo then return false end
    local isSameLayer = blacklistInfo.lastInviteLayer == aura_env.getCurrentLayer()
    local isWithinBlacklistDuration = GetTime() - blacklistInfo.lastInvite < aura_env.config.blacklistDuration
    if not isSameLayer or not isWithinBlacklistDuration then
        aura_env.debug("Removing " .. playerName .. " from blacklist. Conditions met.")
        aura_env.blacklist[playerName] = nil
        return false
    end
    return true
end
aura_env.debug = function(...) if aura_env.config.debug then print(...) end; end;
aura_env.getCurrentLayer = function()
    -- NWB uses 0 for unknown layer
    if NWB_CurrentLayer and NWB_CurrentLayer > 0 then
        aura_env.saved.lastKnownLayer[CURRENT_REALM] = NWB_CurrentLayer
        return NWB_CurrentLayer
    else
        return aura_env.config.useLastKnown
            and aura_env.saved.lastKnownLayer[CURRENT_REALM] or "Unknown";
    end
end
aura_env.getCurrentLayer()
aura_env.setupAllowedChannels()

-- aura_env.config.useLastKnown
-- When the current layer is unknown this, use the last known layer associated with the current realm if any (layers are preserved across characters on the same realm). Useful because NWB tends to forget the current layer after a reload. !!Last known server can be wrong right after login.

-- aura_env.config.blacklistDuration
-- Set the amount of time in seconds that a player will be blacklisted for after being successfully invited to a layer.

-- aura_env.config.inviteOnUnknown
-- Allows inviting players even when NWB is unsure of the current layer.