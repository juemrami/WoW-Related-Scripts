local f = function(event, sentence)
    if not sentence then return end
    local exp_pattern = "dies, you gain (%d+) experience."
    local bonus_pattern = "(%d+) exp Rested"
    local total_exp = strmatch(sentence, exp_pattern)
    if total_exp then
        total_exp = tonumber(total_exp)
        local bonus = strmatch(sentence, bonus_pattern)
        bonus = bonus and tonumber(bonus) or 0
        local raw = total_exp - bonus
        
        print("XP gained from killing monster: ", total_exp)
        print(string.format("Raw: %d, Bonus: %d", raw, bonus))
    end
end

