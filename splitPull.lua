local addReaction = function()
    local _, unit = GameTooltip:GetUnit()
    if not UnitIsPlayer(unit) 
    and not UnitIsPlayer("target") 
    and not UnitIsUnit(unit,"target") 
    and not UnitIsFriend("player", unit)
    and not UnitIsFriend("player", "target")
    then 
        local reaction = UnitReaction(unit, "target")
        local colors = {
            [2] = HOSTILE_STATUS_COLOR,
            [4] = NEUTRAL_STATUS_COLOR,
            [5] = FRIENDLY_STATUS_COLOR
        }
        local strings = {
            [2] = "Hostile",
            [4] = "Neutral",
            [5] = "Friendly"
        }
        if colors[reaction] then
            GameTooltip:AddLine("Reaction to Target:  " .. colors[reaction]:WrapTextInColorCode(strings[reaction]))
        end
    end
end
GameTooltip:HookScript("OnTooltipSetUnit", addReaction)
