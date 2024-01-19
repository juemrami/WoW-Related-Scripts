---@param states table<string, WA.State>
---@param event any
---@param ... any
---events: CLEU:SPELL_AURA_APPLIED:SPELL_AURA_REMOVED_DOSE:SPELL_AURA_REMOVED
function aura_env.onEvent(states, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local AQUA_SHELL, _, icon = GetSpellInfo(406970)
        local GHAMOORA = 201722
        local spellName = select(13, ...)
        if spellName ~= AQUA_SHELL then return end
        local destGUID = select(8, ...)
        local npcID = tonumber(select(6, strsplit("-", destGUID)))
        if npcID ~= GHAMOORA then return end
        local subEvent = select(2, ...)
        if subEvent == "SPELL_AURA_APPLIED" then
            states[""] = {
                show = true,
                changed = true,
                progressType = "static",
                total = 100,
                stacks = 100,
                value = 0,
                icon = icon,
            }
            return true
        elseif event == "SPELL_AURA_REMOVED_DOSE"
            and states[""] and states[""].stacks
        then
            states[""].stacks = states[""].stacks - 1
            states[""].value = states[""].value + 1
            states[""].show = states[""].stacks >= 0
            states[""].changed = true
            return true
        elseif event == "SPELL_AURA_REMOVED" then
            states[""] = {
                show = false,
                changed = true,
            }
            return true
        end
    elseif event == "OPTIONS" then
        local _, _, icon = GetSpellInfo(406970)
        states[""] = {
            show = true,
            changed = true,
            progressType = "static",
            total = 100,
            stacks = 86,
            value = 0,
            icon = icon,
        }
    end
end
