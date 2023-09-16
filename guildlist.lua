-- what guild are we scanning
aura_env.scanGuild = aura_env.scanGuild or ""
local guild = select(1, GetGuildInfo("player"))
if guild == "HC Elite" then
    aura_env.scanGuild = "HC Elite II"
elseif guild == "HC Elite II" then
    aura_env.scanGuild = "HC Elite"
end
-- the current guild scan data (as Who objects)
-- {gender, raceStr, fullName, filename, classStr, level, fullGuildName, area}
aura_env.list = aura_env.list or {}

-- naughty global to track if we are in update (not overwrite) mode
HC_ELITE_UPDATE_MODE = false
-- naughty global to ensure we don't scan more than once per min
HC_ELITE_LAST_SCAN = 0 -- timestamp
-- naughty global to track class number when scanning
HC_ELITE_CLASS_NUMBER = 1
-- naughty global to track number of members in aura_env.list across auras
HC_ELITE_ALT_LIST_MEMBERS = 0

-- this script runs whenever Guild tab is opened
GuildFrame:HookScript("OnShow", function()
    -- don't run the /who inside instances (no raid lag please)
    local inInstance = select(1, IsInInstance())
    if inInstance == false then
        local newTime = GetTime()
        if newTime - HC_ELITE_LAST_SCAN > 60 then
            HC_ELITE_LAST_SCAN = newTime
            HC_ELITE_UPDATE_MODE = false


            -- stop Who tab auto opening
            FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
            C_FriendList.SetWhoToUi(true)

            -- only /who the other guild
            C_FriendList.SortWho("Class")
            local guild = select(1, GetGuildInfo("player"))
            if guild == "HC Elite" then
                print("sending who query 1")
                C_FriendList.SendWho('g-"HC Elite II"')
            elseif guild == "HC Elite II" then
                print("sending who query 1")
                C_FriendList.SendWho('g-"HC Elite"')
            end

            -- check if 50+ results were found, if so scan classes individually
            C_Timer.After(0.3, function()
                local N = C_FriendList.GetNumWhoResults()
                if N >= 50 then
                    HC_ELITE_UPDATE_MODE = true
                    HC_ELITE_CLASS_NUMBER = 1
                    -- every 4s scan a new class
                    for k, v in pairs(classList) do
                        C_Timer.After(HC_ELITE_CLASS_NUMBER * 4,
                            function()
                                print("pulse")
                                local classList = {
                                    "Warrior", "Priest", "Paladin", "Druid",
                                    "Hunter", "Mage", "Rogue", "Warlock", "Shaman" }
                                if HC_ELITE_UPDATE_MODE then
                                    -- don't open UI
                                    FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
                                    C_FriendList.SetWhoToUi(true)
                                    -- scan this class
                                    if guild == "HC Elite" then
                                        print("sending who query 2")
                                        C_FriendList.SendWho('g-"HC Elite II" c-"' ..
                                            classList[HC_ELITE_CLASS_NUMBER] .. '"')
                                    elseif guild == "HC Elite II" then
                                        print("sending who query 2")
                                        C_FriendList.SendWho('g-"HC Elite" c-"' ..
                                            classList[HC_ELITE_CLASS_NUMBER] .. '"')
                                    end
                                end
                            end)
                        -- reset UI settings
                        if HC_ELITE_UPDATE_MODE then
                            C_Timer.After(HC_ELITE_CLASS_NUMBER * 4 + 0.5, function()
                                C_FriendList.SetWhoToUi(false)
                                FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
                            end)
                        end
                        HC_ELITE_CLASS_NUMBER = HC_ELITE_CLASS_NUMBER + 1
                    end
                end
            end)


            -- reset Who tab functionality
            C_Timer.After(0.5, function()
                C_FriendList.SetWhoToUi(false)
                FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
            end)
        end
    end
end)

-- hex codes for WoW class colors
aura_env.rgb = {}
aura_env.rgb["Death Knight"] = "C41E3A"
aura_env.rgb["Demon Hunter"] = "A330C9"
aura_env.rgb["Druid"] = "FF7C0A"
aura_env.rgb["Evoker"] = "33937F"
aura_env.rgb["Hunter"] = "AAD372"
aura_env.rgb["Mage"] = "3FC7EB"
aura_env.rgb["Monk"] = "00FF98"
aura_env.rgb["Paladin"] = "F48CBA"
aura_env.rgb["Priest"] = "FFFFFF"
aura_env.rgb["Rogue"] = "FFF468"
aura_env.rgb["Shaman"] = "0070DD"
aura_env.rgb["Warlock"] = "8788EE"
aura_env.rgb["Warrior"] = "C69B6D"
-- function to colorize text based on class
aura_env.color = function(text, class)
    return "|cff" .. aura_env.rgb[class] .. text .. "|r"
end



aura_env.members = aura_env.members or 0

aura_env.position = aura_env.position or 1

-- code to move to the next/prev member in the list (loops around)
aura_env.next = function()
    aura_env.position = aura_env.position + 1
    if aura_env.position > aura_env.members then
        aura_env.position = 1
    end
end

aura_env.prev = function()
    aura_env.position = aura_env.position - 1
    if aura_env.position < 1 then
        aura_env.position = aura_env.members
    end
end


-- code to open chat whisper dialogue to player
aura_env.whisper = function(name)
    name = type(name) ~= "string" and "" or name
    local editBox = ACTIVE_CHAT_EDIT_BOX or DEFAULT_CHAT_FRAME.editBox or SELECTED_CHAT_FRAME.editBox
    if editBox then
        ChatEdit_ActivateChat(editBox)
        editBox:SetText("/w " .. name .. " ")
    end
end
