if not aura_env.init then
    for i = 1, NUM_CONTAINER_FRAMES do
        _G["ContainerFrame" .. i]:HookScript("OnUpdate", function(self)
            --print("update")
            local id = self:GetID()
            local container = self:GetName()
            if id > 4 then return end -- 0 is backpack, 1-4 are bags
            for slot_idx = 1, self.size, 1 do
                local bag_item_button = _G[container .. "Item" .. slot_idx]
                -- local itemLink = GetContainerItemLink(id, ag_item_button:GetID())
                bag_item_button.IconBorder:SetShown(false)
                bag_item_button.JunkIcon:SetShown(false)
                if not bag_item_button.IconQuestTexture then
                    --print("creating quest texture")
                    bag_item_button.IconQuestTexture = bag_item_button:CreateTexture("IconQuestTexture","OVERLAY", nil, 2);
                    bag_item_button.IconQuestTexture:SetPoint("TOP", 0, 0);
                    bag_item_button.IconQuestTexture:SetSize(37, 38); -- in blizz code
                    bag_item_button.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER);
                end
                bag_item_button.IconQuestTexture:SetShown(false)

                local _, _, _, quality, _, _,itemLink, _, noValue, itemID = GetContainerItemInfo(id, bag_item_button:GetID());
                if quality and itemID then
                    -- check classID. key for quest items is 12
                    local isQuestItem = select(6, GetItemInfoInstant(itemID)) == 12;
                    bag_item_button.IconQuestTexture:SetShown(isQuestItem);
                    if quality > 1 then
                        local quality_color = BAG_ITEM_QUALITY_COLORS[quality]
                        bag_item_button.IconBorder:SetVertexColor(quality_color.r, quality_color.g, quality_color.b)
                        bag_item_button.IconBorder:SetShown(true)
                    end
                    bag_item_button.JunkIcon:SetShown(quality == LE_ITEM_QUALITY_POOR and not noValue and not isQuestItem)
                end
            end
        end)
    end
end
aura_env.init = true
