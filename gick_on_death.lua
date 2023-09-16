--Events: GUILD_MEMBER_DIED, CHAT_MSG_SYSTEM
aura_env.triggerFunction = function(event, ...) 
    if event == "GUILD_MEMBER_DIED" then
        local member = ...
        aura_env.lastDeadMember = member
    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        -- Bigsxy has gone offline.
        local name = strmatch(message, "(.-) has gone offline.")
        if name and aura_env.lastDeadMember == name then
            GuildUninvite(name)
            aura_env.lastDeadMember = nil
            return true
        end
    end
end
