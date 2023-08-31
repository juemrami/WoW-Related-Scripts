-- if unit and guid and aura_env.config.explosiveModule and (npcID or name or spellID) and (not (aura_env.should_whitelist_npc[npcID] or aura_env.should_whitelist_npc[name] or (aura_env.should_whitelist_spell_id[spellID] and (not aura_env.config.enableAnyCast) or aura_env.config.enableAnyCast and spellID))) then
-- 	aura_env.visible(unit, false)
-- end
-- if event== OPTIONS then
-- 	aura_env.config.npcs = 120651
-- 	aura_env.should_whitelist_npc = {}
-- 	aura_env.should_whitelist_spell_id = {}
-- 	for k, v in pairs({
-- 		strsplit(",", aura_env.config.npcs)
-- 	}) do
-- 		aura_env.should_whitelist_npc[v] = true
-- 	end
-- 	for k, v in pairs({
-- 		strsplit(",", aura_env.config.spellIDs)
-- 	}) do
-- 		local spell_id = tonumber(v)
-- 		if spell_id then
-- 			aura_env.should_whitelist_spell_id[spell_id] = true
-- 		end
-- 	end
-- end
aura_env = {}
aura_env.npcs = {}
aura_env.explosive_id = 120651
aura_env.spellIDs = {}
aura_env.modifiers = {
    [1] = "LALT",
    [2] = "LCTRL",
    [3] = "LSHIFT",
    [4] = "RALT",
    [5] = "RCTRL",
    [6] = "RSHIFT"
}
aura_env.visible = function(unit, bool)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if plate and unit then
        if IsAddOnLoaded("Plater") then
            if bool then
                plate.unitFramePlater:Show()
            else
                plate.unitFramePlater:Hide()
            end
        elseif IsAddOnLoaded("ElvUI") and ElvUI[1] and ElvUI[1].NamePlates and ElvUI[1].NamePlates.Initialized then
            if bool then
                plate.unitFrame:Show()
            else
                plate.unitFrame:Hide()
            end
        elseif IsAddOnLoaded("NeatPlates") then
            if bool then
                plate.carrier:Show()
            else
                plate.carrier:Hide()
            end
        elseif IsAddOnLoaded("TidyPlates_ThreatPlates") then
            if bool then
                plate.TPFrame:Show()
            else
                plate.TPFrame:Hide()
            end
        elseif IsAddOnLoaded("Kui_Nameplates") then
            if bool then
                plate.kui:Show()
            else
                plate.kui:Hide()
            end
        elseif bool then
            plate.UnitFrame:Show()
        else
            plate.UnitFrame:Hide()
        end
    end
end
aura_env.filter_nameplates = function(plate)
    local unit = plate.namePlateUnitToken
    local guid = UnitGUID(unit)
    local name = UnitName(unit)
    local npcID = select(6, strsplit("-", guid))
    local spellID = select(9, UnitCastingInfo(unit))
    local health = UnitHealth(unit)
    return unit, guid, name, npcID, spellID, health
end

local a = function(event, ...)
    if event == "MODIFIER_STATE_CHANGED" then
        local state = select(2, ...)
        local modifier = select(1, ...)
        if state == 1 and modifier == aura_env.modifiers[aura_env.config.specifiedModifier] then
            for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
                local unit = plate.namePlateUnitToken
                local guid = UnitGUID(unit)
                local npcID = select(6, strsplit("-", guid))
                if npcID then npcID = tonumber(npcID) end
                -- local spellID = select(9, UnitCastingInfo(unit))
                local health = UnitHealth(unit)
                if aura_env.config.healthModule and health then
                    -- if explosiveModule is active, omit explsoives from the health module filtering
                    if aura_env.config.explosiveModule and npcID == aura_env.explosive_id then
                    elseif health <= aura_env.config.healthThreshold then
                        aura_env.visible(unit, false)
                    end
                elseif aura_env.config.explosiveModule and npcID then
                    print(npcID, aura_env.explosive_id, "equal?", npcID == aura_env.explosive_id)
                    if npcID ~= aura_env.explosive_id then
                        aura_env.visible(unit, false)
                    end
                end
            end
        else
            for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
                aura_env.visible(plate.namePlateUnitToken, true)
            end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unit = select(1, ...)
        if unit and IsModifierKeyDown() then
            local plate = C_NamePlate.GetNamePlateForUnit(unit)
            local guid = UnitGUID(unit)
            local npcID = select(6, strsplit("-", guid))
            local health = UnitHealth(unit)
            if npcID then npcID = tonumber(npcID) end
            if aura_env.config.healthModule and health then
                if aura_env.config.explosiveModule and npcID == aura_env.explosive_id then return false end
                if health <= aura_env.config.healthThreshold then
                    aura_env.visible(plate.namePlateUnitToken, false)
                end
            elseif aura_env.config.explosiveModule and npcID ~= aura_env.explosive_id then
                aura_env.visible(plate.namePlateUnitToken, false)
            end
        end
    end
end


a()
