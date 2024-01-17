local stances = {
    -- Battle Stance
    -- [GetSpellInfo(2457)] = 2,
    [2457] = 1,
    -- Defensive Stance
    -- [GetSpellInfo(71)] = 1,
    [71] = 2,
    -- Berserker Stance
    -- [GetSpellInfo(2458)] = 3,
    [2458] = 3,

}
local border = TEXTURE_ITEM_QUEST_BORDER
--- events: CLEU:SPELL_AURA_APPLIED:SPELL_AURA_REMOVED
aura_env.onEvent = function(states, event, ...)
    for id, _ in pairs(stances) do
        states[id] = {
            active = WA_GetUnitBuff("player", id, "HELPFUL PLAYER") ~= nil,
            icon = GetSpellTexture(id),
            stance = stances[id],
            show = true,
            changed = true,
        }
    end
    -- -- only on player GUID
    -- local subEvent, _, sourceGUID = select(2, ...)
    -- if sourceGUID ~= WeakAuras.myGUID then return end
    -- ---@type string, string
    -- local spellId, spellName = select(12, ...)
    -- if not stances[spellId] then return end

    
    -- if subEvent == "SPELL_AURA_APPLIED" then 
    --     states[spellName] = {
    --         active = true,
    --         icon = GetSpellTexture(spellId),
    --         stance = stances[spellId],
    --     }
    -- end
end
aura_env.onShow = function()
    if not aura_env.region.selectedTex then
        aura_env.region.selectedTex = aura_env.region:CreateTexture(nil, "OVERLAY", nil, 2)
        aura_env.region.selectedTex:SetTexture(border)
        aura_env.region.selectedTex:SetBlendMode("ADD")
        aura_env.region.selectedTex:SetAllPoints()
        aura_env.region.selectedTex:SetSize(aura_env.region:GetSize())
    end
end
aura_env.onUpdate = function()
    if aura_env.region.selectedTex then
        aura_env.region.selectedTex
            :SetShown(aura_env.state and aura_env.state.active)
    end
end
---@type WA.CustomConditions
local conditions = {
    active = {
        type ="bool",
        display = "Stance Active",
    }
}