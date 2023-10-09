InActiveBattlefield = C_PvP.IsActiveBattlefield or InActiveBattlefield
CanGroupInvite = C_PartyInfo.CanInvite or CanGroupInvite
InviteUnit = C_PartyInfo.InviteUnit or InviteUnit

if aura_env.config.keywords.keys then
    local keywords = {}
    for _, word in ipairs({ strsplit(",", aura_env.config.keywords.keys) }) do
        if word then
            word = aura_env.config.keywords.match_case and word or strlower(word)
            word = strtrim(word)
            tinsert(keywords, word)
        end
    end
    aura_env.keywords = keywords
end

aura_env.OnChatMsgWhisper = function(a, event, msg, source_name, ...)
    --no keyword or invite target.
    if not (msg or source_name) then return end

    -- keyword matching
    local is_keyword = false
    for _, keyword in ipairs(aura_env.keywords) do
        if msg == keyword then
            is_keyword = true
            break
        end
    end
    if not is_keyword then print("not keyword") return end
    print("should invite ", source_name)
    

    local canInvite = (
        CanGroupInvite()
        -- and not C_PartyInfo.IsPartyFull()
        and not InActiveBattlefield()
    )
    if canInvite then
        if source_name then
            source_name = strsplit("-", source_name)
            local source_guid = select(10, ...)
            if aura_env.config.whitelist.enabled then
                -- check if the player is in our guild
                if aura_env.config.whitelist.own_guild then
                    for i = 1, GetNumGuildMembers() do
                        local member_name = GetGuildRosterInfo(i)
                        if source_name == strsplit("-", member_name) then
                            InviteUnit(source_name)
                            return true
                        end
                    end
                end
                -- check if the player is in one of the allowed guilds
                -- currently no API to check a players guild by name.
            else
                InviteUnit(source_name)
                return true
            end
        end
    end
end
