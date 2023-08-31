aura_env.main_poisons = {
    [315584] = "Instant Poison",
    [2823] = "Deadly Poison",
    [381664] = "Amplifying Poison",
}
aura_env.off_poisons = {
    [381637] = "Atrophic Poison",
    [5761] = "Numbing Poison",
    [3408] = "Crippling Poison",
    [8679] = "Wound Poison",

}
aura_env.tFind = function(table, item)
    local index = 1;
    while table[index] do
        if (item == table[index]) then
            return index;
        end
        index = index + 1;
    end
    return nil;
end
aura_env.max_poisons = function()
    -- Dragon Tempered Blades
    return IsSpellKnown(381801) and 2 or 1
end

aura_env.get_preferred = function()
    local mh
    -- Amp > Deadly > Instant Default
    -- check for deadly
    local deadly_known = IsSpellKnown(2823)
    local amp_known = IsSpellKnown(381637)
    local atroph_known = IsSpellKnown(381637)
    if aura_env.max_poisons() == 2 then
        if amp_known then
            mh = { 381664, 2823 } -- amp + deadly
        else
            mh = { 2823, 315584 }
        end -- deadly + instant

        if atroph_known then
            oh = { 381637, 5761 } -- atroph + numbing
        else
            oh = { 5761, 3408 }
        end -- numbing + crippling
    else
        if amp_known then
            mh = { 381664 } -- amp
        elseif deadly_known then
            mh = { 2823 }   -- deadly
        else
            mh = { 315584 }
        end -- instant

        if atroph_known then
            oh = { 381637 } -- atroph
        else
            oh = { 5761 }
        end -- numbing
    end
    return mh, oh
end

aura_env.scan_poisons = function()
    local main = {}
    for poison_id, poison_name in pairs(aura_env.main_poisons) do
        local applied_poison = C_UnitAuras.GetPlayerAuraBySpellID(poison_id)
        if applied_poison then
            tinsert(main, applied_poison)
        end
    end

    local off = {}
    for poison_id, poison_name in pairs(aura_env.off_poisons) do
        local applied_poison = C_UnitAuras.GetPlayerAuraBySpellID(poison_id)
        if applied_poison then
            tinsert(off, applied_poison)
        end
    end
    return main, off
end

aura_env.trigger = function(allstates, event, ...)
    if event == "UNIT_AURA" then
        local applied_mh, applied_oh = aura_env.scan_poisons()
        allstates[""] = {
            changed = true,
        }
        local pref_main, pref_off = aura_env.get_preferred()
        if #applied_mh < aura_env.max_poisons() then
            for i, poison_data in ipairs(applied_mh) do
                local idx = aura_env.tFind(pref_main, poison_data.spellID)
                if idx then

                end
            end
        end
    return true
    end
end
