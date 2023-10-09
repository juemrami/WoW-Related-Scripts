-- events: PLAYER_ENTERING_WORLD
aura_env.onEvent = function(event)
    print(event)
    if event == "PLAYER_ENTERING_WORLD" or event == "STATUS" then
        aura_env.hookDropDrown()
    end
end
aura_env.hookDropDrown = function()
    if aura_env.init then return end
    DropDownList1:HookScript("OnShow", function(self)
        if self.dropdown:GetName() == "FriendsDropDown"
            and self.dropdown.name
        then
            UIDropDownMenu_AddButton({
                text = "Guild Invite",
                func = function() GuildInvite(self.dropdown.name) end,
                notCheckable = true,
                tooltipTitle = "Guild Invite",
                tooltipText = "Invite this player to your guild",
                -- tooltipOnButton = true,
            }, 1)
            UIDropDownMenu_AddButton({
                text = "Add Friend",
                func = function()
                    C_FriendList.AddFriend(self.dropdown.name)
                end,
                notCheckable = true,
                tooltipTitle = "Add Friend",
                tooltipText = "Add Player to Friends list",
                -- tooltipOnButton = true,
            }, 1)
        end
    end)
    aura_env.init = true
end
