aura_env.MAIL_DELIVERY_TIME = 1 * 60 * 60
aura_env.debug = true
if not aura_env.saved
    or not aura_env.saved.mail_data then
    print("Creating Mail Tracker database.")
    aura_env.saved = {
        mail_data = {
            incoming_for_character = {},
            outgoing_for_character = {}
        }
    }
end
-- Hook onto Send Mail input box to get the recipient name.
if not aura_env.init then
    hooksecurefunc("SendMailFrame_SendMail", function(...)
        local name = SendMailNameEditBox:GetText()
        name = name ~= "" and name or nil
        WeakAuras.ScanEvents("MAIL_RECIPIENT_UPDATE", name)
    end)
    C_ChatInfo.RegisterAddonMessagePrefix("MAIL_TRACKER")
    if aura_env.init then print("Mail Tracker: Hooked and scanning for mail events.") end
    aura_env.init = true
end
aura_env.show_initial = false
-- MAIL_RECIPIENT_UPDATE, MAIL_SHOW, MAIL_SEND_SUCCESS, MAIL_DELIVERED, CHAT_MSG_ADDON
aura_env.on_event = function(allstates, event, ...)
    if aura_env.saved and aura_env.saved.mail_data then
        local should_update_states = false
        if not aura_env.show_initial then 
            should_update_states = true 
        end
        if event == "MAIL_SHOW" then
            aura_env.last_attempted_recipient = nil
            aura_env.clean_saved_data()
            should_update_states = true
        elseif event == "MAIL_RECIPIENT_UPDATE" then
            local recipient = ...
            aura_env.last_attempted_recipient = type(recipient) == "string" and recipient or nil
        elseif event == "MAIL_SEND_SUCCESS" then
            local recipient = aura_env.last_attempted_recipient
            local sender = UnitName("player")
            local send_time = GetTime()
            if aura_env.debug then
                print("New mail sent. recipient: ", recipient, " sender: ", sender, " send_time: ",
                    send_time)
            end
            if recipient and sender then
                local mail_data = aura_env.saved.mail_data
                local mail_info = {
                    sender = sender,
                    recipient = recipient,
                    duration = aura_env.MAIL_DELIVERY_TIME,
                    expirationTime = send_time + aura_env.MAIL_DELIVERY_TIME,
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
                aura_env.send_addon_message(recipient, mail_info.expirationTime)
                -- send an event after the 60m delivery time.
                C_Timer.After(
                    mail_info.duration,
                    function()
                        WeakAuras.ScanEvents("MAIL_DELIVERED", recipient, mail_info.expirationTime)
                    end)
                ViragDevTool:AddData(mail_data, "mail_data after recent send")
                should_update_states = true
            end
        elseif event == "MAIL_DELIVERED" then
            if ... and aura_env.config.hide_delay > 0 then
                C_Timer.After(
                    aura_env.config.hide_delay,
                    function()
                        WeakAuras.ScanEvents("MAIL_DELIVERED")
                    end)
            else
                should_update_states = true
            end
            aura_env.clean_saved_data()
        elseif event == "CHAT_MSG_ADDON"
            and ... == "MAIL_TRACKER" then
            local message, _, msg_sender, msg_target = select(2, ...)
            msg_sender = strsplit("-", msg_sender or "")
            msg_target = strsplit("-", msg_target or "")
            if aura_env.debug then print("received addon message from ", msg_sender, " to ", msg_target, ": ", message) end
            if msg_target == UnitName("player") then
                local mail_sender, expirationTime = strsplit(":", message)
                expirationTime = tonumber(expirationTime)
                local mail_data = aura_env.saved.mail_data
                local mail_info = {
                    sender = mail_sender,
                    recipient = msg_target,
                    duration = aura_env.MAIL_DELIVERY_TIME,
                    expirationTime = expirationTime
                }
                mail_data.incoming_for_character[msg_target] = mail_data.incoming_for_character[msg_target] or {}
                mail_data.outgoing_for_character[mail_sender] = mail_data.outgoing_for_character[mail_sender] or {}
                tinsert(
                    mail_data.incoming_for_character[msg_target],
                    mail_info

                )
                tinsert(
                    mail_data.outgoing_for_character[mail_sender],
                    mail_info
                )
                should_update_states = true
            end
        end
        if should_update_states or event =="OPTIONS" then
            aura_env.set_states(allstates)
            ViragDevTool:AddData(allstates, "allstates")
            aura_env.show_initial = true
            return true
        end
    end
end
-- sets both incoming and outgoing states from the local mail data.
aura_env.set_states = function(allstates)
    local target = UnitName("player")
    ViragDevTool:AddData(allstates, "allstates before update")
    -- reset allstates to not show
    for _, state in pairs(allstates) do
        state.show = false
        state.changed = true
    end
    -- add incoming and outgoing mail states
    for _, mail_info in ipairs(aura_env.saved.mail_data.incoming_for_character[target] or {}) do
        local key, state = aura_env.create_key_and_state(mail_info)
        allstates[key] = state
    end
    for _, mail_info in ipairs(aura_env.saved.mail_data.outgoing_for_character[target] or {}) do
        local key, state = aura_env.create_key_and_state(mail_info)
        if state.expirationTime <= GetTime() then
            state.show = false
        end
        -- print("setting state for key: ", key, " state: ", state)
        allstates[key] = state
    end

    -- ViragDevTool:AddData(aura_env.saved.mail_data.outgoing_for_character[target], "outgoing")
    -- ViragDevTool:AddData(allstates, "states")
    ViragDevTool:AddData(aura_env.saved.mail_data, "mail_data for states")
    -- return allstates
end
aura_env.create_key_and_state = function(mail_info)
    local function escapeIcon(icon)
        if icon and icon ~= "" then
            return "|T" .. icon .. ":12:12:0:0:64:64:4:60:4:60|t"
        end
    end
    local key = string.format(
        "%s:%s:%.0f",
        mail_info.sender,
        mail_info.recipient,
        mail_info.expirationTime
    )
    local state = {
        show = true,
        changed = true,
        duration = mail_info.duration,
        expirationTime = mail_info.expirationTime,
        progressType = "timed",
        sender = mail_info.sender,
        recipient = mail_info.recipient,
        mailIcon = escapeIcon("Interface/Icons/INV_Letter_15"),
        autoHide = false
    }
    local is_delivered = GetTime() >= mail_info.expirationTime
    if is_delivered then
        print("adding icon to delivered mail")
        state.icon = escapeIcon("Interface/RaidFrame/ReadyCheck-Ready")
    end
    return key, state
end
-- for sending mail related events to other users of the WA.
aura_env.send_addon_message = function(recipient, expirationTime)
    if aura_env.debug then print("sending addon message") end
    C_ChatInfo.SendAddonMessage(
        "MAIL_TRACKER",
        ("%s:%.2f"):format(
            UnitName("player"),
            expirationTime
        ),
        "WHISPER",
        recipient
    )
end
-- cleans up any expired mail data (incoming or outgoing).
aura_env.clean_saved_data = function()
    local mail_data = aura_env.saved.mail_data
    for mail_type, _ in pairs(mail_data) do
        if aura_env.debug then
            print("cleaning up mail type: ", mail_type)
        end
        for character_key, _ in pairs(mail_data[mail_type]) do
            for i, mail_info in ipairs(mail_data[mail_type][character_key]) do
                -- ViragDevTool:AddData(mail_info, "mail info")
                local should_remove = true
                if mail_info and mail_info ~= {} then
                    should_remove = GetTime() > mail_info.expirationTime
                end
                if should_remove then
                    if aura_env.debug then
                        print(("removing mail info %s -> %s, expired: %.0f seconds ago"):format(mail_info.sender,
                            mail_info.recipient,
                            GetTime() - mail_info.expirationTime))
                    end
                    tremove(mail_data[mail_type][character_key], i)
                    ViragDevTool:AddData(mail_data, "mail_data after clean")
                end
            end
        end
    end
end
aura_env.custom_text = function(...)
    if aura_env.state
        and aura_env.state.recipient and aura_env.state.sender then
        local formatted_name = ""
        if aura_env.state.recipient == UnitName("player") then
            formatted_name = ("From %s"):format(aura_env.state.sender)
        else
            formatted_name = ("To %s"):format(aura_env.state.recipient)
        end
        return formatted_name, aura_env.state.icon
    end
end
