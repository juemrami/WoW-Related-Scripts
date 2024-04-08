aura_env.getGuildMemberInfo = function(member_name)
    C_GuildInfo.GuildRoster()
    local numGuildMembers = GetNumGuildMembers()
    for i = 1, numGuildMembers do
        local fullname, _, _, level, locale_class, zone, _, _, _, _, class = GetGuildRosterInfo(i)
        if strfind(strlower(fullname), strlower(member_name)) then
            local class_color_mixin = RAID_CLASS_COLORS[class]
            return { member_name, level, locale_class, zone, class_color_mixin }
        end
    end
    return nil
end
aura_env.parseChatMessage = function(event, ...)
    -- example: "[Mylilpwny] has died at level 5 while in Fargodeep Mine, slain by: Venture Co. Supervisor."
    if event == "CHAT_MSG_GUILD_DEATHS" then
        local msg = ...
        -- local chatLineID = select(11, ...)
        if strfind(msg, "died") then
            -- player name is first word in msg
            local name = strmatch(msg, "%[(.-)%]")
            local location = strmatch(msg, "in (.-),")
            local level = strmatch(msg, "level (%d+)")
            local cause = strmatch(msg, "by: (.-)%.")
            print("name: ", name, " location: ", location, " cause: ", cause)
            local player = aura_env.getGuildMemberInfo(name)
            local messageFormat = "Our brave brother, %s the %s, has died at level %d in %s"
            if player then
                local name, level, class, zone, class_color_mixin = unpack(player)
                name = class_color_mixin:WrapTextInColorCode(name)
                class = class_color_mixin:WrapTextInColorCode(class)
                if location then zone = location end
                local msg = messageFormat:format(name, class, level, zone)
                if cause then msg = msg .. ". Slain by: " .. cause end
                aura_env.displayMessage = msg
                return true
            end
        end
    end
end
local test ="[Mylilpwny] has died at level 5 while in Fargodeep Mine, slain by: Venture Co. Supervisor."
WeakAuras.ScanEvents("CHAT_MSG_GUILD_DEATHS", test)
-- new method with hardcore warning

local playSound = aura_env.playSound;
--- CHAT_MSG_GUILD_DEATHS event was removed in 1.15.2, now uses HARDCORE_DEATHS from th C_DeathAlert namespace
if not aura_env.init then
    print("Initializing")
    local getGuildMemberInfo = function(memberName)
        C_GuildInfo.GuildRoster()
        local numGuildMembers = GetNumGuildMembers()
        for i = 1, numGuildMembers do
            local fullname, _, _, level, class, zone, _, _, _, _, _class = GetGuildRosterInfo(i)
            if strfind(strlower(fullname), strlower(memberName)) then
                local classColor = RAID_CLASS_COLORS[_class]
                return { memberName, level, class, zone, classColor }
            end
        end
        return nil
    end
    -- using SetScript to overwrite the default behavior for the raid warning on death.
    -- as opposed to adding an additional raid warning message for the same death event.
    RaidWarningFrame:SetScript("OnEvent", function(self, event, message)
        if event == "HARDCORE_DEATHS" then
            local name = strmatch(message, "%[(.-)%]")
            local msgLocation = strmatch(message, "in (.-),")
            -- need to make sure the period is the last character in the string to get the full cause, incase of abbreviations.
            local cause = strmatch(message, "by: (.-)%.$")
            local messageFormat = "Our comrade, %s the %s, has died at level %d in %s"
            local player = getGuildMemberInfo(name)
            if player then
                local name, level, class, zone, class_color_mixin = unpack(player)
                name = class_color_mixin:WrapTextInColorCode(name)
                class = class_color_mixin:WrapTextInColorCode(class)
                if msgLocation then zone = msgLocation end
                local formattedMsg = messageFormat:format(name, class, level, zone)
                if cause then formattedMsg = formattedMsg .. ". Slain by: " .. cause end
                RaidNotice_AddMessage(self, formattedMsg)
                PlaySound(SOUNDKIT.RAID_WARNING) 
            end
        else
            -- Default behavior for the RaidWarningFrame OnEvent script
            RaidWarningFrame_OnEvent(self, event, message)
        end
    end)
end
aura_env.init = true
