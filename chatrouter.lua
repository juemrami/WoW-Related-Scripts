-- Events: PLAYER_ENTERING_WORLD, GUILD_ROSTER_UPDATE
-- GUILD_ROSTER_UPDATE is hack since PLAYER_ENTERING_WORLD fires before guild info is available on login
aura_env.initialize = function(event,...)
    if not aura_env.init and 
    (event == "PLAYER_ENTERING_WORLD" or 
    event == "GUILD_ROSTER_UPDATE") then
        local playerGuild = GetGuildInfo("player")
        if playerGuild and strmatch(playerGuild, "HC Elite") then
            hooksecurefunc("ChatEdit_HandleChatType",
                function(editBox, msg, command, send)
                    if command == '/G' then
                        local channelNum, channelName = GetChannelName("HCElite")
                        if channelNum > 0 then
                            print(
                                "Re-routing from guild chat to "..
                                "["..channelNum..". "..channelName.."]"..
                                "(final warning)"
                            )
                            editBox:SetAttribute("channelTarget", channelNum);
                            editBox:SetAttribute("chatType", "CHANNEL");
                            editBox:SetText(msg);
                            ChatEdit_UpdateHeader(editBox);
                            return true;
                        end
                    end
                end
            )
            aura_env.init = true
        end
    end
    return aura_env.init
end