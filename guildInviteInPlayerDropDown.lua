-- events: PLAYER_ENTERING_WORLD
aura_env.onEvent = function(event)
    print(event)
    if event == "PLAYER_ENTERING_WORLD" or event == "STATUS" then
        aura_env.hookDropDrown()
    end
end
aura_env.hookDropDrown = function()
    if aura_env.init then return end
    local realm = GetNormalizedRealmName()
    Menu.ModifyMenu("MENU_UNIT_FRIEND", function(frame, description, context)
        if not IsInGuild() then return end
        description:CreateDivider();
        local normalizedName = context.name
        if context.server and (context.server ~= realm) then
            normalizedName = normalizedName.."-"..context.server
        end
        description:CreateButton("Guild Invite", function()
           C_GuildInfo.Invite(normalizedName)
        end)
        -- disabled. cant call AddFriend from inside a WA anymore
        -- description:CreateButton("Add Friend", function()
        --     C_FriendList.AddFriend(normalizedName)
        -- end)
    end)
    aura_env.init = true
end
