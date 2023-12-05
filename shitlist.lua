if not aura_env.blacklist then 
    aura_env.blacklist = {}
    for _, name in ipairs(strsplit(aura_env.config.blacklist or "", ",")) do
        name = strtrim(name)
        if name ~= "" then
            aura_env.blacklist[name] = true
        end
    end
end
aura_env.onEvent = function(states, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then 
        local blacklistUsersInGroup = {}
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if aura_env.blacklist[name] then
                tAppend(blacklistUsersInGroup, name)
            end
        end
        if #blacklistUsersInGroup > 0 then
            local msg = "Shitters in group: " .. tConcat(blacklistUsersInGroup, ", ")
            print(msg)
        end
    end
end
