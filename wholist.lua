if not aura_env.init then
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
        end
    end)
end
aura_env.init = true
