
SLASH_HELLO_TEST1 = '/hw'
local function helloWorld()
    message("hello world, from ".. UnitName("player"))
    print(GetSpellInfo(359040))
end
SlashCmdList['HELLO_TEST'] = helloWorld;


--init the keyId 
local dbCharacterKey = UnitName("player").."-"..GetRealmName();

--Ripped from https://wowpedia.fandom.com/wiki/Saving_variables_between_game_sessions

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "myLocaldb" then
        -- Our saved variables, if they exist, have been loaded at this point.
        if THEOTAR_TEA_COUNT == nil then
            -- This is the first time this addon is loaded; set SVs to default values
            THEOTAR_TEA_COUNT = {}
        end

        if THEOTAR_TEA_COUNT[dbCharacterKey] == nil then
            -- We have no data for this character, so add its key to table and init values
            THEOTAR_TEA_COUNT[dbCharacterKey] = {
                Total=0, Agility=0, Crit=0, Vers=0, Haste=0
            }
            print("Now Tracking Theotar Tea Data for "..dbCharacterKey)
        else 
            -- We do have data for this character
            print("Tea counts for ".. dbCharacterKey)

            for teaType, count in pairs(THEOTAR_TEA_COUNT[dbCharacterKey]) do
                print(teaType..':'..count)
            end
        
        end

    elseif event == "PLAYER_LOGOUT" then
            -- not sure if we have to overwrite old pointers or if they get auto-updated on logout
    end
end)

