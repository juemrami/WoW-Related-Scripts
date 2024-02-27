local CanGroupInvite = C_PartyInfo.CanInvite or CanGroupInvite
local InviteUnit = C_PartyInfo.InviteUnit or InviteUnit

if aura_env.config.whitelist then
    local whitelist = {}
    for _, word in ipairs({ strsplit(",", aura_env.config.whitelist) }) do
        word = strtrim(word)
        if word and word ~= "" then
            word = strlower(word)
            whitelist[word] = true
        end
    end
    whitelist[""] = false -- to prevent cache miss on empty string
    aura_env.whitelist = whitelist
end
aura_env.playerName = strlower(UnitName("player"))
aura_env.onEvent = function(event, ...)
    local msg = ... or ""
    if not msg:find("online") then return end
    local targetName = strsplit(" ", StripHyperlinks(msg) or "")
    targetName = targetName:lower()
    targetName = strsplit('-', targetName)
    if aura_env.whitelist[targetName] 
    and CanGroupInvite()
    and targetName ~= aura_env.playerName
    then
        InviteUnit(targetName)
    end
end


-- aura_env._onEvent = function  (event, ...)
--     if event == "CHAT_MSG_SYSTEM" then
--         local msg = ... or ""
--         -- msg = strlower(msg)
--         -- ERR_FRIEND_ONLINE_SS == "|Hplayer:%s|h[%s]|h has come online."
--         -- need to change it to create a capture group for the player name and then check if the player is in the whitelist
--         -- local ERR_FRIEND_ONLINE_SS  = "|Hplayer:(.-)|h%[(.-)%]|h has come online."
--         local FRIEND_ONLINE_PATTERN = ERR_FRIEND_ONLINE_SS
--             :gsub("|.+|h%s", "%%[(.+)%%] ")
--         -- full name with server
--         print("message: ", msg)
--         print("pattern: ", FRIEND_ONLINE_PATTERN)
--         print("match: ", msg:match(FRIEND_ONLINE_PATTERN))
--         local target = msg:match(FRIEND_ONLINE_PATTERN)
--         print(target)
--         print("test parse:", msg:match("%[(.+)%]%shas come") )
--         target = strlower(target or "")
--         print(target)
--         -- name (without server)
--         local name = strsplit("-", target)
--         if name ~= "" then 
--             print("friend online is ", target)
--         end
--         if aura_env.whitelist[name]
--         and target ~= aura_env.playerName
--         and CanGroupInvite()
--         then
--             InviteUnit(target)
--             return true
--         end
--     end
-- end