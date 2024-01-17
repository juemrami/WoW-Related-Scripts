if not aura_env.init then
    ---@param itemIDOrLink string|integer
    ---@return boolean? isJunk, boolean? isQuestItem
    local getTextureStates = function(itemIDOrLink)
        if not itemIDOrLink then return end;
        local t = { GetItemInfo(itemIDOrLink) }
        ---@type integer?, integer?, integer?
        local quality, sellPrice, itemClass = t[3], t[11], t[12];
        if not (quality and sellPrice and itemClass) then return end;

        local isQuestItem = itemClass == Enum.ItemClass.Questitem;
        local hasNoValue = sellPrice == 0;
        local isJunk = (quality < LE_ITEM_QUALITY_COMMON)
            and (not hasNoValue)
            and (not isQuestItem);
        return isJunk, isQuestItem;
    end;

    hooksecurefunc("SetItemButtonQuality",
        ---Initialize textures and borders for general items buttons.
        ---@param button ItemButtonTemplate
        ---@param quality? integer
        ---@param itemIDOrLink string|integer?
        function(button, quality, itemIDOrLink)
            if quality then
                local color = BAG_ITEM_QUALITY_COLORS[quality];
                if quality > LE_ITEM_QUALITY_COMMON and color then
                    button.IconBorder:SetVertexColor(color.r, color.g, color.b);
                    button.IconBorder:Show();
                else
                    button.IconBorder:Hide();
                end;
            else
                button.IconBorder:Hide();
            end;

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
                    if not button.IconQuestTexture then
                        button.IconQuestTexture = button:CreateTexture("IconQuestTexture", "OVERLAY", nil, 2);
                        button.IconQuestTexture:SetPoint("TOP", 0, 0);
                        button.IconQuestTexture:SetSize(37, 38);
                        button.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER);
                        button.IconQuestTexture:Hide();
                    end;
                    if not button.JunkIcon then
                        button.JunkIcon = button
                            :CreateTexture("JunkIcon", "OVERLAY", nil, 3);
                        button.JunkIcon:SetPoint("TOPLEFT", 1, 0);
                        button.JunkIcon:SetAtlas("bags-junkcoin", true);
                        button.JunkIcon:Hide();
                    end
                    local isJunk, isQuestItem = getTextureStates(itemIDOrLink);
                    button.IconQuestTexture:SetShown(isQuestItem);
                    button.JunkIcon:SetShown(isJunk);
                end;
            end
        end
    );

    -- add quality border to loot frame
    hooksecurefunc("LootFrame_Show", function(self)
        if self.numLootItems then
            for i = 1, self.numLootItems do
                local button = _G["LootButton" .. i];
                if not button then return end
                if button.JunkIcon then
                    button.JunkIcon:Hide();
                end;
                if button.IconQuestTexture then
                    button.IconQuestTexture:Hide();
                end;
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
            ---@cast self ItemButtonTemplate
            if not self.IconBorder then
                self.IconBorder = self:CreateTexture("IconBorder", "OVERLAY", nil);
                self.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
                self.IconBorder:SetPoint("CENTER");
                self.IconBorder:SetSize(37, 37);
                self.IconBorder:Hide();
                self.IconOverlay = self:CreateTexture("IconOverlay", "OVERLAY", nil);
            end;
            if self.JunkIcon then self.JunkIcon:Hide() end;
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
                    local button = _G[self:GetName() .. "Item" .. i];
                    ---@cast button ItemButtonTemplate
                    if button
                        and (button.JunkIcon
                            or button.IconQuestTexture)
                    then
                        local itemLink = C_Container
                            .GetContainerItemLink(self:GetID(), button:GetID());

                        local isJunk, isQuesItem = getTextureStates(itemLink);
                        if button.IconQuestTexture then
                            button.IconQuestTexture:SetShown(isQuesItem);
                        end;
                        if button.JunkIcon then
                            button.JunkIcon:SetShown(isJunk);
                        end;
                    end;
                end;
            end;
        end
    );
    --- SoD fix
    hooksecurefunc("ContainerFrame_EngravingTargetingModeChanged",
        function(self, enabled)
            DevTools_Dump(C_Engraving.GetCurrentRuneCast());
            for c = 1, NUM_CONTAINER_FRAMES, 1 do
                local frame = _G["ContainerFrame" .. c];
                local name = frame:GetName();
                if (frame:IsShown()) then
                    for s = 1, frame.size, 1 do
                        local itemButton = _G[name .. "Item" .. s];
                        ---@cast itemButton ItemButtonTemplate
                        if enabled and C_Engraving.GetCurrentRuneCast() then
                            local engravable = C_Engraving.IsInventorySlotEngravableByCurrentRuneCast(frame:GetID(),
                                itemButton:GetID());
                            local itemLink = C_Container.GetContainerItemLink(frame:GetID(), itemButton:GetID());
                            print(("%s | engravable? %s | willDesaturat? %s")
                                :format(
                                    itemLink or "Empty Slot",
                                    tostring(engravable),
                                    tostring(not engravable)
                                )
                            );
                            SetItemButtonDesaturated(itemButton, not engravable);
                        else
                            SetItemButtonDesaturated(itemButton, false);
                        end
                    end
                end
            end
        end
    );
    aura_env.init = true;
end;
