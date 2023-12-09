local categories = C_Engraving.GetRuneCategories(true, true);
    for _, category in ipairs(categories) do
    local runes = C_Engraving.GetRunesForCategory(category, true);
    for _, rune in ipairs(runes) do
        local macroText = 
        "#showtooltip %s\n/run C_Engraving.CastRune(%d)\n/use %d\n/click StaticPopup1Button1\n\n"
        print(macroText:format(
            rune.name,
            rune.skillLineAbilityID,
            category
        ));
    end;
end;
