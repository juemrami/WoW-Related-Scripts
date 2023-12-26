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
local playerClass = select(2, UnitClass("player"))
local usesMana = UnitPowerType("player", 1) == Enum.PowerType.Mana
local usesRage = UnitPowerType("player", 2) == Enum.PowerType.Rage
local usesStones = playerClass == "ROGUE"
    or playerClass == "WARRIOR"
local usesOils = playerClass == "MAGE"
    or playerClass == "WARLOCK"
    or playerClass == "PRIEST"
if playerClass == "DRUID" or playerClass == "PALADIN" then
    local strength = UnitStat("player", 1) or 0
    local agility = UnitStat("player", 2) or 0
    local intellect = UnitStat("player", 4) or 0
    if max(strength, agility) >= intellect then
        usesOils = false
        if playerClass == "PALADIN" then
            usesStones = true
        end
    else
        usesStones = false
        usesOils = true
    end
end
local isRogue = playerClass == "ROGUE"
--- [itemID] = amount | {condition} and {amountIfTrue} or {amountIfFalse}
aura_env.evool = {
    consumes = {
        -- First-Aid
        [6450] = 20,                      -- Silk Bandage
        -- Cooking
        [3728] = 0,                       -- Tasty Lion Steak
        [5527] = 5,                       -- Goblin Deviled Clams
        -- Weapon Enchants
        [211845] = usesStones and 3 or 0, -- Blackfathom Sharpening Stone
        [211848] = usesOils and 3 or 0,   -- Blackfathom Mana Oil
        -- Engineering
        [6714] = 10,                      -- EZ-Thro Dynamite
        [4378] = 0,                       -- Heavy Dynamite
        -- Alchemy
        --- util pot
        [3386] = 0,                    -- Elixir of Poison Resistance
        --- potion cd
        [5634] = 5,                    -- Free Action Potion
        [6048] = 3,                    -- Shadow Protection Potion
        [929] = 10,                    -- Healing Potion
        [3385] = usesMana and 10 or 0, -- Lesser Mana Potion
        [3827] = 0,                    -- Mana Potion
        [5631] = usesRage and 10 or 0, -- Rage Potion
        [2459] = 0,                    -- Swiftness Potion
        --- elixirs
        [3388] = 1,                    -- Strong Troll's Blood
        [3390] = 3,                    -- Lesser Agility
        [3391] = 3,                    -- Ogre's Strength
        [3389] = 1,                    -- Defense Elixir
        [2458] = 3,                    -- Minor Fort Elixir
        -- Misc
        [211816] = 1,                  -- Warsong Battle Drum
        -- Rogue
        [6947] = isRogue and 10 or 0,  -- Instant Poison I
        [7676] = isRogue and 10 or 0,  -- Thistle Tea
    }
}
