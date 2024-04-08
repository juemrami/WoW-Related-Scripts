local incursionData = {
    -- {startItem, questId, shareItem}
	{ item = 219999, id = 81768, shareItem = 220053 },
	{ item = 220000, id = 81769, shareItem = 220054 },
	{ item = 220001, id = 81770, shareItem = 220055 },
	{ item = 220002, id = 81771, shareItem = 220056 },
	{ item = 220003, id = 81772, shareItem = 220057 },
	{ item = 220004, id = 81773, shareItem = 220058 },
	{ item = 220005, id = 81774, shareItem = 220059 },
	{ item = 220006, id = 81775, shareItem = 220060 },
	{ item = 220007, id = 81776, shareItem = 220061 },
	{ item = 220008, id = 81777, shareItem = 220062 },
	{ item = 220009, id = 81778, shareItem = 220063 },
	{ item = 220010, id = 81779, shareItem = 220064 },
	{ item = 220011, id = 81780, shareItem = 220065 },
	{ item = 220012, id = 81781, shareItem = 220066 },
	{ item = 220013, id = 81782, shareItem = 220067 },
	{ item = 220014, id = 81783, shareItem = 220068 },
	{ item = 220015, id = 81784, shareItem = 220069 },
	{ item = 220016, id = 81785, shareItem = 220070 },
}
-- theres 18 quest in total (@build 54092)
-- quests 1 - 3 are Kill quests. Not worth keeping imo
-- quests 10 - 12 are profession quests Herb\Mining\Skinning
local ignoredMissions = {
    1, 2, 3, 10, 11, 12
}

---  helpers
local getItemContainerSlot = function(itemID)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemID(bag, slot)
            if item == itemID then
                return bag, slot
            end
        end
    end
end
local abandonQuest = function(questID)
    if not C_QuestLog.IsOnQuest(questID) then return end
    local idx = GetQuestLogIndexByID(questID)
    SelectQuestLogEntry(idx)
    SetAbandonQuest()
    AbandonQuest()
    print("Quest Abandoned: ", C_QuestLog.GetQuestInfo(questID))
end
---@return boolean? await
local deleteItem = function(itemID)
    if CursorHasItem() then return end -- only 1 item deleted at time
    local bag, slot = getItemContainerSlot(itemID)
    if not (bag and slot) then return end -- item not found
    C_Container.PickupContainerItem(bag, slot)
    DeleteCursorItem()
    print("Item Deleted: ", GetItemInfo(itemID))
    -- weakaura workaround
    return true
end
local buttonFrameID = "IncursionCleanUpButton"
local getButton = function()
    if not getglobal(buttonFrameID) then
        local button = CreateFrame("Button", buttonFrameID, QuestLogFrame, "UIPanelButtonTemplate")
        button:SetText("Cleanup Incursions")
        button:SetSize(130, 20)
        button:SetPoint("BOTTOMRIGHT", QuestLogTitleText, "TOPRIGHT", 6, 2)
        local awaitDelete
        button:SetScript("OnClick", function()
            for _, missionNumber in ipairs(ignoredMissions) do
                local quest = incursionData[missionNumber]
                abandonQuest(quest.id)
                awaitDelete = deleteItem(quest.item)
                if not awaitDelete then 
                    awaitDelete = deleteItem(quest.shareItem)
                end
            end

        end)
    end
    return getglobal(buttonFrameID)
end
getButton()
