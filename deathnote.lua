aura_env.getGuildMemberInfo = function(member_name) 
    C_GuildInfo.GuildRoster()
    local numGuildMembers = GetNumGuildMembers()
    for i = 1, numGuildMembers do
        local fullname, _, _, level, locale_class, zone, _,_,_,_,class = GetGuildRosterInfo(i)
        if strfind(fullname, member_name) then
            local class_color_mixin = RAID_CLASS_COLORS[class]
            return {member_name, level, locale_class, zone, class_color_mixin}
        end
    end
    return nil
end
aura_env.parseChatMessage = function(event, ...)
    -- example: "Mylilpwny has died!"
    if event == "CHAT_MSG_SYSTEM" then
        local msg = ...
        -- local chatLineID = select(11, ...)
        if strfind(msg, "died") or strfind(msg,"offline") then
            -- player name is first word in msg
            local name = select(1, strsplit(" ", msg))
            local player = aura_env.getGuildMemberInfo(name)
            local messageFormat = "Our brave brother, %s the %s, has died at level %d in %s"
            if player then
                local name, level, class, zone, class_color_mixin = unpack(player)
                name = class_color_mixin:WrapTextInColorCode(name)
                class = class_color_mixin:WrapTextInColorCode(class)
                
                local msg = messageFormat:format(name, class, level, zone)
                aura_env.displayMessage = msg
                return true
            end

        end
        
    end
end
