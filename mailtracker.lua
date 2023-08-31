aura_env.MAIL_DELIVERY_TIME = 1 * 60 * 60
aura_env.escape_texture = function(path)
    return "|T" .. path .. ":12:12:0:0:64:64:4:60:4:60|t"
end
-- ready_icon = aura_env.escape_texture("Interface/RaidFrame/ReadyCheck-Ready"),12:12:0:0:64:64:4:60:4:60|t
if not aura_env.saved
    or not aura_env.saved.mail_data then
    print("setting saved")
    aura_env.saved = {
        mail_data = {
            incoming_for_character = {},
            outgoing_for_character = {}
        }
    }
end
if not aura_env.init then
    hooksecurefunc("SendMailFrame_SendMail", function(...)
        local name = SendMailNameEditBox:GetText()
        name = name ~= "" and name or nil
        print("sending mail to: ", name)
        WeakAuras.ScanEvents("MAIL_SEND_DATA", name)
    end)
    aura_env.init = true
    if aura_env.init then print("Hooked") end
end
aura_env.cleanup_states = function(allstates)
    local mail_data = aura_env.saved.mail_data
    for mail_type, _ in pairs(mail_data) do
        for character_key, _ in pairs(mail_data[mail_type]) do
            for i, mail_info in ipairs(mail_data[mail_type][character_key]) do
                -- ViragDevTool:AddData(mail_info, "mail info")
                local should_remove = true
                if mail_info and mail_info ~= {} then
                    should_remove = GetTime() > mail_info.expirationTime
                end
                print("removing: ", should_remove)
                if should_remove then
                    tremove(mail_data[mail_type][character_key], i)
                    local key = string.format(
                        "%s:%s:%.0f",
                        mail_info.sender,
                        mail_info.recipient,
                        mail_info.expirationTime
                    )
                    allstates[key] = {
                        changed = true,
                        show = false,
                    }
                    ViragDevTool:AddData(mail_data, "mail_data after clean")
                end
            end
        end
    end
end
aura_env.set_incoming_states = function(allstates)
    local recipient = UnitName("player")
    for _, mail_info in ipairs(aura_env.saved.mail_data.incoming_for_character[recipient] or {}) do
        local key = string.format(
            "%s:%s:%.0f",
            mail_info.sender,
            mail_info.recipient,
            mail_info.expirationTime
        )
        allstates[key] = {
            show = true,
            changed = true,
            duration = mail_info.duration,
            expirationTime = mail_info.expirationTime,
            progressType = "timed",
            sender = mail_info.sender,
            recipient = mail_info.recipient,
            icon = "Interface/Icons/INV_Letter_15",
            autoHide = false
        }
    end
end
aura_env.set_outgoing_states = function(allstates)
    local sender = UnitName("player")
    for _, mail_info in ipairs(aura_env.saved.mail_data.outgoing_for_character[sender] or {}) do
        local key = string.format(
            "%s:%s:%.0f",
            mail_info.sender,
            mail_info.recipient,
            mail_info.expirationTime
        )
        allstates[key] = {
            show = true,
            changed = true,
            duration = mail_info.duration,
            expirationTime = mail_info.expirationTime,
            progressType = "timed",
            sender = mail_info.sender,
            recipient = mail_info.recipient,
            icon = "Interface/Icons/INV_Letter_15",

            autoHide = false,
        }
    end
end
-- MAIL_SEND_DATA, MAIL_SHOW, MAIL_SEND_SUCCESS
aura_env.track_mail = function(allstates, event, ...)
    if aura_env.saved and aura_env.saved.mail_data then
        if event == "MAIL_SEND_DATA" then
            local recipient = ...
            aura_env.last_attempted_recipient = type(recipient) == "string" and recipient or nil
        elseif event == "MAIL_SEND_SUCCESS" then
            local recipient = aura_env.last_attempted_recipient
            local sender = UnitName("player")
            local send_time = GetTime()
            print("mail sent to ", recipient, " from ", sender, "@", send_time)
            if recipient and sender then
                local mail_data = aura_env.saved.mail_data
                local mail_info = {
                    sender = sender,
                    recipient = recipient,
                    duration = aura_env.MAIL_DELIVERY_TIME,
                    expirationTime = send_time + aura_env.MAIL_DELIVERY_TIME
                }
                mail_data.incoming_for_character[recipient] = mail_data.incoming_for_character[recipient] or {}
                mail_data.outgoing_for_character[sender] = mail_data.outgoing_for_character[sender] or {}
                tinsert(
                    mail_data.incoming_for_character[recipient],
                    mail_info

                )
                tinsert(
                    mail_data.outgoing_for_character[sender],
                    mail_info
                )
                C_Timer.After(
                    aura_env.MAIL_DELIVERY_TIME + 5,
                    function()
                        aura_env.cleanup_states(allstates)
                    end)
                ViragDevTool:AddData(mail_data, "mail_data")
            end
        end
        aura_env.cleanup_states(allstates)
        aura_env.set_incoming_states(allstates)
        aura_env.set_outgoing_states(allstates)
        ViragDevTool:AddData(allstates, "allstates")
    end
    return true
end
aura_env.custom_text = function(...)
    if aura_env.state
        and aura_env.state.recipient and aura_env.state.sender then
        local formatted_name = ""
        if aura_env.state.recipient == UnitName("Player") then
            formatted_name = ("From %s"):format(aura_env.state.sender)
        end
        formatted_name = ("To %s"):format(aura_env.state.recipient)
        -- print(aura_env.state.ready_icon)
        local ready_icon = aura_env.state.expirationTime < GetTime()
            and aura_env.escape_texture("Interface/RaidFrame/ReadyCheck-Ready")
            or ""
        return formatted_name, ready_icon
    end
    -- ViragDevTool:AddData({ ... }, "text args")
    -- ViragDevTool:AddData(aura_env.state, "state")
end
