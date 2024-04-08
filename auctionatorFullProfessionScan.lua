local isUsingAuctionator = function()
    return C_AddOns.IsAddOnLoaded("Auctionator")
end;

if not isUsingAuctionator() then
    WeakAuras.prettyPrint(
        ([[Aura [%s] requires the "Auctionator" addon]]):format(aura_env.id)
    )
    return;
end
local SearchAllReagentButton
--- Helpers
local isAuctionHouseOpen = function()
    return AuctionFrame and AuctionFrame:IsShown()
end;
local isTradeSkillOpen = function()
    return TradeSkillFrame and TradeSkillFrame:IsShown()
end;
local isUsingLeatrix = function()
    return LeaPlusDB and LeaPlusDB.EnhanceProfessions
end;
---@type {name: string, infoMissing: boolean, recipeIndex: number, reagents: string[]}[] # {name, isMissing, craftID, reagents}
local currentProfessionCrafts = {}
local AuctionatorSearchCurrent = function (callerID)
    local searchTerms = {}
    local uniqueReagents = {}
    for _, craft in ipairs(currentProfessionCrafts) do
        assert(not craft.infoMissing, "All missing info should be resolved before calling AuctionatorSearch")
        table.insert(searchTerms, { searchString = craft.name, isExact = true })
        for _, reagent in pairs(craft.reagents) do
            if not uniqueReagents[reagent] then
                table.insert(searchTerms, { searchString = reagent, isExact = true })
                uniqueReagents[reagent] = true
            end
        end
    end
    print("Searching for ", #searchTerms, " terms")
    Auctionator.API.v1.MultiSearchAdvanced(callerID, searchTerms)
    SearchAllReagentButton:SetEnabled(true)
end
local auraID = aura_env.id
local currentTradeSkillStr = ""
local getApiCallerID = function()
    return currentTradeSkillStr .. " " .. AUCTIONATOR_L_REAGENT_SEARCH
end;
local ScanCraftReagents = function(recipeIndex, existing)
    local isComplete = true
    local numReagents = GetTradeSkillNumReagents(recipeIndex)
    local reagents = existing or {}
    if existing then
        assert(false, "Not implemented, pass `nil`")
        -- todo: fix double work refetching found reagent.
    else
        for idx = 1, numReagents do
            local reagentName = GetTradeSkillReagentInfo(recipeIndex, idx)
            if not reagentName then 
                isComplete = false
            end
            reagents[idx] = reagentName
        end
    end
    return isComplete, reagents
end
local function ScanMissingCrafts()
    local isRescanComplete = true
    for _, craft in ipairs(currentProfessionCrafts) do
        if craft.infoMissing then
            print("re-fetching for missing info for ", craft.name)
            local reagentsComplete, reagents = ScanCraftReagents(craft.recipeIndex)
            if reagentsComplete then
                -- todo: fix double work refetching possibly found reagents.
                craft.reagents = reagents
                craft.infoMissing = false
            else
                WeakAuras.prettyPrint(auraID..": Rescan reagents still incomplete.")
                DevTools_Dump({   
                    tradeSkill = currentTradeSkillStr, 
                    recipeName = craft.name,
                    reagents = reagents,
                })
                isRescanComplete = false
            end
        end
    end
    if isRescanComplete then print("Rescan complete") end
    return isRescanComplete
end
local ScanProfessionCrafts = function()
    local numCrafts = 0
    local anyInfoMissing = false
    for recipeIndex = 1, GetNumTradeSkills() do
        local craftName, type = GetTradeSkillInfo(recipeIndex)
        if type ~= "header" and craftName then
            local craftInfo = {
                name = craftName,
                missingInfo = true, 
                recipeIndex = recipeIndex,
                reagents = {}
            }
            numCrafts = numCrafts + 1
            local reagentsComplete, reagents = ScanCraftReagents(recipeIndex);
            if reagentsComplete then
                craftInfo.reagents = reagents
                craftInfo.missingInfo = false
            else
                anyInfoMissing = true
                craftInfo.missingInfo = true
                WeakAuras.prettyPrint(auraID..": Craft "..craftName.." marked for rescan. Missing reagents.")
                DevTools_Dump({   
                    tradeSkill = currentTradeSkillStr, 
                    recipeName = craftName,
                    reagents = reagents,
                })
            end
            tinsert(currentProfessionCrafts, craftInfo)
        end
    end
    if anyInfoMissing then
        print("Scanning incomplete, waiting on info")
    end
    if not anyInfoMissing and numCrafts > 0 then
        print("Scan Complete")
       return true
    end
end
local rescanOnUpdate = false
local function getButton()
    if not getglobal("SearchAllReagentButton") and TradeSkillFrame
    then
        local button = CreateFrame("Button", "SearchAllReagentButton", TradeSkillFrame,
            "UIPanelDynamicResizeButtonTemplate");
        if isUsingLeatrix() then
            button
                :SetPoint("TOPRIGHT", TradeSkillRankFrame, "BOTTOMRIGHT", 6, -2.5)
        else
            button:SetPoint("TOPRIGHT", TradeSkillSkill1, "TOPRIGHT", 0, 0)
        end
        button:SetText("Search All")
        button.fitTextWidthPadding = 15
        button:FitToText()
        button:SetHeight(TradeSkillSkill1:GetHeight())
        button:SetScript("OnClick", function()
            if isAuctionHouseOpen() then
                AuctionatorSearchCurrent(getApiCallerID())
            end
        end)
        button:SetShown(false)
        button:SetEnabled(true) -- default to disabled and enabled when all info has been scanned
        local fontFile, fontSize, fontFlags = button.Text:GetFont()
        button.Text:SetFont(fontFile, fontSize - 2.5, fontFlags)
        print("Search All Reagents button created")
        SearchAllReagentButton = button
    end
    return SearchAllReagentButton
end
aura_env.onEvent = function(event, ...)
    if event == "AUCTION_HOUSE_SHOW" and ... == nil then
        -- delay AUCTION_HOUSE_SHOW event by .25ms to account for bug where AuctionFrame is not yet shown, use Arg1 as a flag
        C_Timer.After(.25,
            function()
                WeakAuras.ScanEvents("AUCTION_HOUSE_SHOW", true)
            end
        )
        return;
    elseif event == "TRADE_SKILL_SHOW" then
        local professionName = GetTradeSkillLine()
        if professionName ~= currentTradeSkillStr then
            rescanOnUpdate = false -- reset incase any pending info from last open profession
            currentProfessionCrafts = {} -- reset data on new profession
            currentTradeSkillStr = professionName
        end
    elseif event == "TRADE_SKILL_UPDATE" then
        print(event, " | should rescan? ", rescanOnUpdate)
        if rescanOnUpdate then
                SearchAllReagentButton:SetEnabled(false)
                local allComplete = ScanMissingCrafts()
                if allComplete then 
                    getButton():SetEnabled(true)
                    rescanOnUpdate = false
                else
                    print("Rescan incomplete, waiting for next trade skill update event")
                end
            end
            return -- exit early, asssuming we already ran the rest of code
    end
    local button = getButton()
    if not button then return end
    print(event)  
    if isAuctionHouseOpen() and isTradeSkillOpen() then
        button:SetShown(isAuctionHouseOpen())
        -- populate if no data
        if not next(currentProfessionCrafts) then
            local isComplete = ScanProfessionCrafts()
            button:SetEnabled(isComplete)
            if not isComplete then 
                rescanOnUpdate = true 
            end
        end
    end
end
--- events: AUCTION_HOUSE_SHOW, TRADE_SKILL_SHOW, TRADE_SKILL_CLOSE, AUCTION_HOUSE_CLOSED, TRADE_SKILL_UPDATE
---@alias events "AUCTION_HOUSE_SHOW"|"TRADE_SKILL_SHOW"|"TRADE_SKILL_CLOSE"|"AUCTION_HOUSE_CLOSED"|"TRADE_SKILL_UPDATE"
