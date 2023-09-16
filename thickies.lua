q = function(modTable)
    local anchor = {
        side = abs(modTable.config.anchor) or 2,
        --1 = topleft 2 = left 3 = bottomleft 4 = bottom 5 = bottom right 6 = right 7 = topright 8 = top
        x = abs(modTable.config.xoffset) or 0, --x offset
        y = abs(modTable.config.yoffset) or 0, --y offset
    }

    local playersOnly = modTable.config.playersOnly

    function modTable.CreateCCCircle(unitFrame)
        if not unitFrame.CCCircle then
            unitFrame.CCCircle = CreateFrame("frame", unitFrame:GetName() .. "CCCircle", unitFrame)
            unitFrame.CCCircle:SetSize(40, 40)
            unitFrame.CCCircle:SetFrameLevel(unitFrame.healthBar:GetFrameLevel() + 25)

            unitFrame.CCCircle.ClassIcon = unitFrame.CCCircle:CreateTexture(nil, "ARTWORK", nil, 1)
            unitFrame.CCCircle.ClassIcon:SetScale(0.3)
            unitFrame.CCCircle.ClassIcon:SetSize(128, 128)
            local class = select(2, UnitClass(unitFrame.namePlateUnitToken))
            unitFrame.CCCircle.ClassIcon:SetAtlas(GetClassAtlas(class))
            unitFrame.CCCircle.ClassIcon:Show()

            unitFrame.CCCircle.CCIcon = unitFrame.CCCircle:CreateTexture(nil, "ARTWORK", nil, 2)
            unitFrame.CCCircle.CCIcon:Hide()
            unitFrame.CCCircle.CCIcon:SetScale(0.3)
            unitFrame.CCCircle.CCIcon:SetSize(128, 128)

            unitFrame.CCCircle.ClassOverlay = unitFrame.CCCircle:CreateTexture(nil, "OVERLAY", nil, 1)
            unitFrame.CCCircle.ClassOverlay:SetAtlas("Portrait-Frame-Nameplate", true)
            unitFrame.CCCircle.ClassOverlay:Show()

            unitFrame.CCCircle.CCText = unitFrame.CCCircle:CreateFontString(nil, "OVERLAY", "CommentatorFontSmall", 1)
            unitFrame.CCCircle.CCText:SetJustifyH("CENTER")
            unitFrame.CCCircle.CCText:SetSize(30, 1)
            unitFrame.CCCircle.CCText:SetFixedColor(1, 1, 1, 1)

            unitFrame.CCCircle.Mask = unitFrame.CCCircle:CreateMaskTexture(nil, "OVERLAY", nil, 1)
            unitFrame.CCCircle.Mask:Show()
            unitFrame.CCCircle.Mask:SetAtlas("CircleMaskScalable", true)
            unitFrame.CCCircle.Mask:SetScale(0.65)
            unitFrame.CCCircle.ClassIcon:AddMaskTexture(unitFrame.CCCircle.Mask)
            unitFrame.CCCircle.CCIcon:AddMaskTexture(unitFrame.CCCircle.Mask)

            unitFrame.CCCircle.CCCooldown = CreateFrame("Cooldown", nil, unitFrame.CCCircle)
            unitFrame.CCCircle.CCCooldown:SetSwipeTexture("Interface\\PVPFrame\\PVP-Separation-Circle-Cooldown-overlay")
            unitFrame.CCCircle.CCCooldown:SetSwipeColor(0, 0, 0, 0.8)
            unitFrame.CCCircle.CCCooldown:SetSize(50, 50)

            unitFrame.CCCircle.ClassIcon:ClearAllPoints()
            PixelUtil.SetPoint(unitFrame.CCCircle.ClassIcon, "CENTER", unitFrame.CCCircle, "CENTER", 0, 0)

            unitFrame.CCCircle.CCIcon:ClearAllPoints()
            PixelUtil.SetPoint(unitFrame.CCCircle.CCIcon, "CENTER", unitFrame.CCCircle, "CENTER", 0, 0)

            unitFrame.CCCircle.ClassOverlay:ClearAllPoints()
            PixelUtil.SetPoint(unitFrame.CCCircle.ClassOverlay, "CENTER", unitFrame.CCCircle, "CENTER", 0, 0)

            unitFrame.CCCircle.CCText:ClearAllPoints()
            PixelUtil.SetPoint(unitFrame.CCCircle.CCText, "CENTER", unitFrame.CCCircle, "CENTER", 0, 30)

            unitFrame.CCCircle.CCCooldown:ClearAllPoints()
            PixelUtil.SetPoint(unitFrame.CCCircle.CCCooldown, "CENTER", unitFrame.CCCircle, "CENTER", 0, 0)

            unitFrame.CCCircle.Mask:ClearAllPoints()
            PixelUtil.SetPoint(unitFrame.CCCircle.Mask, "CENTER", unitFrame.CCCircle, "CENTER", 0, 0)

            --Plater.SetAnchor(unitFrame.CCCircle.ClassIcon, anchor, unitFrame.healthBar)
            unitFrame.CCCircle.Mask:SetAllPoints(unitFrame.CCCircle.ClassIcon)


            modTable.updateCCCircle(unitFrame)
        end
    end

    function modTable.UpdateCrowdControlAuras(unitFrame)
        local CCCircle = unitFrame.CCCircle
        local spellID, expirationTime, duration
        for _, auraIcon in ipairs(unitFrame.ExtraIconFrame.IconPool) do
            if auraIcon:IsShown() then
                if DetailsFramework.CrowdControlSpells[auraIcon.spellId] then
                    local thisExpi = auraIcon.startTime + auraIcon.duration
                    if not expirationTime or expirationTime < thisExpi then
                        spellID = auraIcon.spellId
                        expirationTime = thisExpi
                        duration = auraIcon.duration
                    end
                    if modTable.config.hideIcons then
                        auraIcon:SetSize(1, 1)
                        auraIcon:SetAlpha(0)
                        --auraIcon:Hide()
                    end
                else
                    auraIcon:SetAlpha(1)
                end
            else
                auraIcon:SetAlpha(1)
                --break
            end
        end

        local hasCC = spellID and expirationTime
        if hasCC then
            CCCircle.CCCooldown:SetCooldown(expirationTime - duration, duration)

            if spellID ~= nil then
                local icon = select(3, GetSpellInfo(spellID))
                if icon then
                    CCCircle.CCIcon:SetTexture(icon)
                end
            end
        end
        CCCircle.CCIcon:SetShown(hasCC)

        CCCircle.ccExpirationTime = expirationTime
        CCCircle.ccSpellID = spellID

        local timeRemaining = CCCircle.ccExpirationTime and math.max(CCCircle.ccExpirationTime - GetTime(), 0) or 0
        if timeRemaining > 0 then
            if modTable.config.showTimer then
                CCCircle.CCText:SetFormattedText("%.1f", timeRemaining)
                CCCircle.CCText:Show()
            else
                CCCircle.CCText:Hide()
            end
        else
            CCCircle.CCText:Hide()
            CCCircle.CCCooldown:Clear()
        end
    end

    function modTable.updateCCCircle(unitFrame, added)
        anchor.side = IsActiveBattlefieldArena() and 8 or (abs(modTable.config.anchor) or 2)
        if playersOnly and not (unitFrame.ActorType == "friendlyplayer" or unitFrame.ActorType == "enemyplayer") then
            unitFrame.CCCircle:Hide()
            return
        end

        if added then
            local class = select(2, UnitClass(unitFrame.namePlateUnitToken))
            unitFrame.CCCircle.ClassIcon:SetAtlas(GetClassAtlas(class))
        end

        Plater.SetAnchor(unitFrame.CCCircle, anchor, unitFrame.healthBar)
        unitFrame.CCCircle:SetScale(modTable.config.scale)

        if not unitFrame.CCCircle:IsShown() then
            unitFrame.CCCircle:Show()
        end

        modTable.UpdateCrowdControlAuras(unitFrame)
    end

    if not Plater.db.profile.debuff_show_cc then
        Plater.db.profile.debuff_show_cc = true
        Plater.RefreshAuraDBUpvalues()
    end
end



-- hide friendly healthbars
a = function(self, unitId, unitFrame, envTable, modTable)
    local arenaCheck = modTable.config.arenaOnly and IsActiveBattlefieldArena()
    if unitFrame.ActorType == "friendlyplayer" and IsActiveBattlefieldArena() then
        unitFrame.healthBar:SetSize(0, 0)
        unitFrame.healthBar.unitName:SetText("")
    end
end


c = function()
    ViragDevTool:AddData(aura_env.state, "aura state")
    if aura_env.state.destGUID then
        -- for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        --     if nameplate.namePlateUnitName == "Demonic Tyrant" then
        --         -- local ownerText = nameplate.ActorTitleSpecial:GetText()
        --         -- owner text example:
        --         -- "Bigsexy's Demonic Tyrant"
        --         -- or "Bigsexy-RealName's Demonic Tyrant "
        --         -- local name = strmatch(ownerText, "<(.-)'s")
        --         local name = strmatch(ownerText, "<(.-)'s")
        --         -- name = strsplit("-", name)
        --         -- print(name, aura_env.state.sourceName, name == aura_env.state.sourceName)

        --         if name == aura_env.state.sourceName then
        --             return nameplate

        --     end
        -- end
        local unit = UnitTokenFromGUID(aura_env.state.destGUID)
        C_NamePlate.GetNamePlateForUnit(unit)
    end
end

-- Cloning Version
-- events: CLEU:SPELL_SUMMON, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED
aura_env.custom = function(allstates, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local subEvent = select(2, ...)
        local sourceGUID, sourceName = select(4, ...)
        local destGUID, destName = select(8, ...)
        local spellID, spellName = select(12, ...)
        local duration = 15
        if spellID == 265187
            or spellName == "Summon Demonic Tyrant"
        then
            allstates[destGUID] = {
                show = true,
                changed = true,
                progressType = "timed",
                autoHide = true,
                duration = duration,
                expirationTime = GetTime() + duration,
                unitToken = UnitTokenFromGUID(destGUID),
                sourceGUID = sourceGUID,
                sourceName = sourceName,
                destGUID = destGUID,
                destName = destName,
                spellID = spellID,
                spellName = spellName,
            }
            return true
        end
    elseif event == "NAME_PLATE_UNIT_ADDED"
        or event == "NAME_PLATE_UNIT_REMOVED"
    then
        local unitToken = ...
        local guid = UnitGUID(unitToken)
        if allstates[guid] then
            allstates[guid].unitToken = unitToken
            allstates[guid].changed = true
            return true
        end
    end
end
