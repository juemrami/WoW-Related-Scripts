-- "%s has reached level 60!" is the sentence. need to parse the name and match it for a guild members

-- CHAT_MSG_SYSTEM
aura_env.f = function(event, message, ...)
    if event ~= "CHAT_MSG_SYSTEM" then return end
    local name = strmatch(message, "(.+) has reached level 60!")
    if name then
        -- C_FriendList.SendWho("x-"..name.." 60") -- not usable without a #hwevent
        for i = 1, GetNumGuildMembers() do
            local fullName, _, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
            fullName = strsplit("-", fullName)
            if strlower(fullName) ==  strlower(name) then
                local colorMixin = RAID_CLASS_COLORS[class]
                local formattedName = colorMixin:WrapTextInColorCode(name)
                aura_env.playerName = formattedName
                print("Guild member,"..formattedName..", has reached level 60!")
                return true
            end
        end
    end
end
