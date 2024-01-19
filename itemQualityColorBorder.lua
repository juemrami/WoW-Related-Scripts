local iLvlValidItemClass = {
    [Enum.ItemClass.Weapon] = true,
    [Enum.ItemClass.Armor] = true,
    [Enum.ItemClass.Tradegoods] = true,
}
if not aura_env.init then
    ---@param itemIDOrLink string|integer
    ---@return boolean? isJunk, boolean? isQuestItem, string? iLvl
    local getTextureStates = function(itemIDOrLink)
        if not itemIDOrLink then return end;
        local t = { GetItemInfo(itemIDOrLink) }
        ---@type integer?, string|integer?, integer?, integer?
        local quality, iLvl, sellPrice, itemClass = t[3], t[4], t[11], t[12];
        if not (quality and sellPrice and itemClass) then return end;
        local color = BAG_ITEM_QUALITY_COLORS[quality];
        if iLvl and color then
            -- make the color a little lighter
            color = DARKYELLOW_FONT_COLOR;
            iLvl = color:WrapTextInColorCode(tostring(iLvl));
        end
        local isQuestItem = itemClass == Enum.ItemClass.Questitem;
        local hasNoValue = sellPrice == 0;
        local isJunk = (quality < LE_ITEM_QUALITY_COMMON)
            and (not hasNoValue)
            and (not isQuestItem);
        iLvl = iLvlValidItemClass[itemClass] and tostring(iLvl) or nil;
        return isJunk, isQuestItem, iLvl;
    end;

    hooksecurefunc("SetItemButtonQuality",
        ---Initialize textures and borders for general items buttons.
        ---@param button ItemButtonTemplate
        ---@param quality integer?
        ---@param itemIDOrLink string|integer?
        function(button, quality, itemIDOrLink)
            -- initialize missing textures

            if not button.IconBorder then
                button.IconBorder = button:CreateTexture(nil, "OVERLAY", nil);
                button.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
                button.IconBorder:SetPoint("CENTER");
                button.IconBorder:SetSize(37, 37);
                button.IconBorder:Hide();
                button.IconOverlay = button:CreateTexture("$parentIconOverlay", "OVERLAY", nil);
            end;
            if not button.IconQuestTexture then
                button.IconQuestTexture = button:CreateTexture(nil, "OVERLAY", nil, 2);
                button.IconQuestTexture:SetPoint("TOP", 0, 0);
                button.IconQuestTexture:SetSize(37, 38);
                button.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER);
                button.IconQuestTexture:Hide();
            end;
            if not button.JunkIcon then
                button.JunkIcon = button
                    :CreateTexture(nil, "OVERLAY", nil, 3);
                button.JunkIcon:SetPoint("TOPLEFT", 1, 0);
                button.JunkIcon:SetAtlas("bags-junkcoin", true);
                button.JunkIcon:Hide();
            end
            if not button.ItemLevelText then
                button.ItemLevelText = button:CreateFontString("$parentItemLevelText", "OVERLAY");
                button.ItemLevelText:SetFont([[Fonts\ARIALN.TTF]], 13, "THICK")
                button.ItemLevelText:SetShadowColor(0, 0, 0, 1);
                button.ItemLevelText:SetShadowOffset(1, -1);
                button.ItemLevelText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2);
                button.ItemLevelText:SetText("");
                button.ItemLevelText:Hide();
            end

            if quality then
                local color = BAG_ITEM_QUALITY_COLORS[quality];
                if quality > LE_ITEM_QUALITY_COMMON and color then
                    if not button.IconBorder then ViragDevTool:AddData(button, "button") end
                    button.IconBorder:SetVertexColor(color.r, color.g, color.b);
                    button.IconBorder:Show();
                else
                    button.IconBorder:Hide();
                end;
            else
                button.IconBorder:Hide();
            end;
            local showItemLevel, itemLevel, isQuestItem, isJunkItem
            if itemIDOrLink then
                local parentContainer = button:GetParent();
                if not parentContainer then return end;

                local parentName = parentContainer:GetName();
                if parentName
                    and (parentName:sub(1, 14) == "ContainerFrame"
                        or parentName == "LootFrame"
                        or parentName == "MerchantFrame"
                        or parentName == "BankFrame"
                        or parentName == "TradeFrame"
                        or parentName == "MailFrame"
                        or parentName == "PaperDollItemsFrame"
                        or parentName == "QuestInfoRewardsFrame")
                then
                    isJunkItem, isQuestItem, itemLevel = getTextureStates(itemIDOrLink);
                    showItemLevel = not not itemLevel
                end;
            end
            button.IconQuestTexture:SetShown(isQuestItem);
            button.JunkIcon:SetShown(isJunkItem);
            button.ItemLevelText:SetText(itemLevel);
            button.ItemLevelText:SetShown(showItemLevel);
        end
    );
    -- the following frames use the ItemButtonTemplate but dont make calls to SetItemButtonQuality
    -- add textures to loot frame
    hooksecurefunc("LootFrame_Show", function(self)
        if self.numLootItems then
            for i = 1, self.numLootItems do
                local button = _G["LootButton" .. i];
                if not button then return end
                if button.slot then
                    local itemLink = GetLootSlotLink(button.slot);
                    SetItemButtonQuality(button, button.quality, itemLink);
                end
            end;
        end;
    end);

    -- add textures to paperdoll frame
    hooksecurefunc("PaperDollItemSlotButton_Update",
        function(self)
            if not self.IconBorder then return end
            local itemLink = GetInventoryItemLink("player", self:GetID());
            local quality = GetInventoryItemQuality("player", self:GetID());
            SetItemButtonQuality(self, quality, itemLink);
        end
    );

    --- Force update textures when player moves items around in bags
    hooksecurefunc("ContainerFrame_Update",
        function(self)
            if self.size then
                for i = 1, self.size do
                    ---@type ItemButtonTemplate?
                    local button = _G[self:GetName() .. "Item" .. i];
                    if button then
                        local itemLink = C_Container
                            .GetContainerItemLink(self:GetID(), button:GetID());
                        local quality = C_Item.GetItemQualityByID(itemLink);
                        SetItemButtonQuality(button, quality, itemLink);
                    end;
                end;
            end;
        end
    );

    aura_env.init = true;
end;

-- --- SoD fix
-- hooksecurefunc("ContainerFrame_EngravingTargetingModeChanged",
--     function(self, enabled)
--         DevTools_Dump(C_Engraving.GetCurrentRuneCast());
--         for c = 1, NUM_CONTAINER_FRAMES, 1 do
--             local frame = _G["ContainerFrame" .. c];
--             local name = frame:GetName();
--             if (frame:IsShown()) then
--                 for s = 1, frame.size, 1 do
--                     local itemButton = _G[name .. "Item" .. s];
--                     ---@cast itemButton ItemButtonTemplate
--                     if enabled and C_Engraving.GetCurrentRuneCast() then
--                         local engravable = C_Engraving.IsInventorySlotEngravableByCurrentRuneCast(frame:GetID(),
--                             itemButton:GetID());
--                         local itemLink = C_Container.GetContainerItemLink(frame:GetID(), itemButton:GetID());
--                         print(("%s | engravable? %s | willDesaturat? %s")
--                             :format(
--                                 itemLink or "Empty Slot",
--                                 tostring(engravable),
--                                 tostring(not engravable)
--                             )
--                         );
--                         SetItemButtonDesaturated(itemButton, not engravable);
--                     else
--                         SetItemButtonDesaturated(itemButton, false);
--                     end
--                 end
--             end
--         end
--     end
-- );
