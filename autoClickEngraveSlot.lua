aura_env.hook = function(event, arg1)
    if arg1 == "Blizzard_EngravingUI"
        or (event ~= "OPTIONS"
            and C_AddOns.IsAddOnLoaded("Blizzard_EngravingUI"))
    then
        -- following is run once per session (ie every reload of game ui)
        if not aura_env.init then
            --- For auto clicking the inventory slot on right click.
            hooksecurefunc("EngravingFrameSpell_OnClick",
                function(self, button)
                    if button == "RightButton" then
                        local rune = C_Engraving.GetCurrentRuneCast()
                        if not InCombatLockdown()
                            and not UnitIsDeadOrGhost("player")
                            and not UnitCastingInfo("player")
                            and not IsPlayerMoving()
                            and not C_Engraving.IsRuneEquipped(rune.skillLineAbilityID)
                        then
                            PickupInventoryItem(rune.equipmentSlot)
                            ClearCursor()

                            -- accepts the replace enchant popup
                            StaticPopup1Button1:Click()

                            -- re-use blizzards mouseover texture,
                            -- as the "current rune being cast" texture
                            self.selectedTex:Show()
                        end
                    end
                end
            )
            --- For showing the currently equipped rune texture
            aura_env.updateEquippedTextures = function()
                local buttons = EngravingFrame.scrollFrame.buttons;
                -- foreach button in the EngravingFrame scrollFrame
                for _, button in pairs(buttons) do
                    ---@cast button Button

                    -- Create the "equipped" texture if it doesn't exist
                    -- Texture info ripped from Blizzard_EngravingUI.xml
                    if not button.equippedTex then
                        button.equippedTex = button:CreateTexture(nil, "OVERLAY", nil, 1)
                        button.equippedTex:SetTexture(
                            "Interface\\ClassTrainerFrame\\TrainerTextures"
                        )
                        button.equippedTex:SetBlendMode("ADD")
                        button.equippedTex:SetSize(160, RUNE_BUTTON_HEIGHT)
                        button.equippedTex:SetPoint("CENTER")
                        button.equippedTex:SetTexCoord(
                            0.00195313,
                            0.57421875,
                            0.75390625,
                            0.84570313
                        )
                    end

                    -- default to hiding the textures
                    button.selectedTex:Hide()
                    button.equippedTex:Hide()
                    
                    -- enable texture if equipped
                    if button.skillLineAbilityID
                        and C_Engraving.IsRuneEquipped(
                            button.skillLineAbilityID
                        )
                    then
                        button.equippedTex:Show()
                    end
                end
            end
            hooksecurefunc("EngravingFrame_UpdateRuneList",
                aura_env.updateEquippedTextures
            )            
            aura_env.init = true
            aura_env.debug("Securely attached to Blizzard's EngravingUI!")
        end
        if aura_env.updateEquippedTextures then
            if event == "RUNE_UPDATED" then
                aura_env.updateEquippedTextures()
            elseif event == "ENGRAVING_TARGETING_MODE_CHANGED"
                and arg1 == false
            then
                aura_env.updateEquippedTextures()
            end
        end
    end
    if event == "OPTIONS" then
        local autoPushSpell = aura_env.config.autoPushSpell and "1" or "0"
        if autoPushSpell ~= C_CVar.GetCVar("AutoPushSpellToActionBar") then
            C_CVar.SetCVar("AutoPushSpellToActionBar", autoPushSpell)
            aura_env.debug("\"AutoPushSpellToActionBar\" - ", autoPushSpell == "1" and "Enabled" or "Disabled")   
        end
    end
end
aura_env.debug = function(...)
    if aura_env.config.debug then
        local auraID = DIM_GREEN_FONT_COLOR:WrapTextInColorCode(aura_env.id..": ")
        WeakAuras.prettyPrint(auraID.."\n", ...)
    end
end
