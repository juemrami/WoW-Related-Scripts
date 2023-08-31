if not aura_env.init then
    local parseChannelList = function(...)
        local num_of_args = select("#", ...)
        for i = 1, num_of_args, 3 do
            local channelNumber = select(i, ...)
            local channelName = select(i + 1, ...)
            if channelName == "HCElite1" then
                return channelNumber, channelName
            end
        end
    end
    hooksecurefunc("ChatEdit_ParseText",
        function(editBox, send, _)
            local text = editBox:GetText()
            local command = strmatch(text, "^(/[^%s]+)") or "";
            
            if command
            and (command == "/g"
            or command == "/guild")
            then
                local channelNum, channelName = parseChannelList(GetChannelList())
                --print(GetChannelList())
                if channelNum then
                    print(
                    "Re-routing from guild chat to ["..channelNum..". "..channelName.."] (final warning)" )
                    editBox:SetText("/"..channelNum)
                end
            end
    end)
    aura_env.init = true
end

