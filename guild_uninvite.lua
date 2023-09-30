-- GuildUninvite() is protected. so We need to get around this by;
-- hooking onto a proctected frame (like ChatFrame and posthooking onEvent)
-- creating a protected frame (using SecureActionButtonTemplate and making a button to call GuildUninvite() on click like deleing an time).  this would likely require globals
-- or using a hooksecurefunc. (need to find a function that is called when a guildmemeber dies)



--  ill go with making the frame using the static popup

-- onInit
if not aura_env.init then
    local button = CreateFrame("Button", "GuildRemoveRecentlyDead",aura_env.region, "SecureActionButtonTemplate")
    button:SetAttribute("type", "macro")
    StaticPopupDialogs["GUILD_UNINVITE"] = {
        text = "Are you sure you want to remove %s from the guild?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(self)
            print(self.data.name)
            securecallfunction(RunMacroText("/gremove " .. self.data.name))
            button:SetAttribute("macrotext", "/gremove " .. self.data.name)     
            button:Click()
        end,
        timeout = 0,
        whileDead = false,
        hideOnEscape = true,
        showAlert = true
    }

    hooksecurefunc("ChatFrame_MessageEventHandler", function(self, event, message)
        if event == "CHAT_MSG_GUILD_DEATHS" then
            local member = strmatch(message, "%[(.-)%] has died")
            _G["LAST_DEAD_GUILD_MEMBER"] = member
        end
        if event == "CHAT_MSG_SYSTEM" then
            local name = strmatch(message, "(.-) has gone offline.")
            if name and
                _G["LAST_DEAD_GUILD_MEMBER"] == name then
                _G["LAST_DEAD_GUILD_MEMBER"] = nil
                -- RunMacroText("/gremove " .. name)
                return
            end
        end
    end)

    aura_env.init = true
end
--Events: GUILD_MEMBER_DIED, CHAT_MSG_SYSTEM
aura_env.onEvent = function(event, ...)
    if event == "GUILD_MEMBER_DIED" then
        local member = ...
        aura_env.lastDeadMember = member
    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        local name = strmatch(message, "(.-) has gone offline.")
        if name
            and aura_env.lastDeadMember == name then
            aura_env.lastDeadMember = nil
            return StaticPopup_Show("GUILD_UNINVITE", name, nil, {name = name})
        end
    end
end


-- ChatFrame1:HookScript("OnEvent", function(self, event, message)
--     if event == "CHAT_MSG_GUILD_DEATHS" then
--         local member = strmatch(message, "%[(.-)%] has died")
--         _G["LAST_DEAD_GUILD_MEMBER"] = member
--     end
--     if event == "CHAT_MSG_SYSTEM" then
--         local name = strmatch(message, "(.-) has gone offline.")
--         if name and
--         _G["LAST_DEAD_GUILD_MEMBER"] == name then
--             _G["LAST_DEAD_GUILD_MEMBER"] = nil
--             GuildUninvite(member)
--             return
--         end
--     end
-- end,2)
