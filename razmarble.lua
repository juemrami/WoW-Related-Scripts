aura_env.bagOrder = {
    "Forashona",
    "Baldnfat",
    "Thoriun",
    "Oblagb",
    "Boglemage",
    "Dilphiv",
    "Griefedhc",
    "Santypaws",
};
aura_env.spellID = 589;
aura_env.destName = "Prowler"
aura_env.nextCaster = aura_env.bagOrder[1];
aura_env.spellName = "Fumble";


aura_env.updateNextCaster = function(currentCaster)
    if not aura_env.bagOrder then return end
    
    for i = 1, #aura_env.bagOrder do
        if currentCaster == aura_env.bagOrder[i] then
            if aura_env.bagOrder[i + 1] then
                aura_env.nextCaster = aura_env.bagOrder[i + 1];
            else
                aura_env.nextCaster = aura_env.bagOrder[1];
            end
        end
    end
end
aura_env.fn = function(allstates, event, ...)
    if not allstates[''] then
        local name, _, icon = GetSpellInfo(aura_env.spellID);
        allstates[''] = {
            sourceName = "",
            destName = "",
            icon = icon,
            name = name,
            progressType = "timed",
            duration = 10,
            changed = true,
            show = false,
            stacks = 0,
        }
    end
    if event == "OPTIONS" then
        allstates[''].sourceName = aura_env.bagOrder[1]
        allstates[''].nextCaster = aura_env.bagOrder[2]
        allstates[''].changed = true
        allstates[''].show = true
        allstates[''].stacks = 1
        return true
    end
    local subEvent = select(2, ...)
    local casterName = select(5, ...);
    local spellName = select(13, ...);
    local destName = select(9, ...);
    local spellID = select(10, ...);
    if subEvent == "SPELL_AURA_APPLIED" then
        print(event)
        if (spellID == aura_env.spellID) then
            print(spellID)
            if casterName == aura_env.nextCaster then
                aura_env.updateNextCaster(casterName)
            end
            if destName == aura_env.destName then
                allstates[''].expirationTime = GetTime() + 10;
                allstates[''].sourceName = casterName;
                allstates[''].destName = destName;
                allstates[''].stacks = 1;
                allstates[''].show = true;
            end
            allstates[''].nextCaster = aura_env.nextCaster
            allstates[''].changed = true;
            return true;
        end
    elseif subEvent == "SPELL_MISSED" then
        local isExpired = allstates[''].expirationTime 
        and allstates[''].expirationTime < GetTime()
        allstates['misses'] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = 2,
            sourceName = casterName,
            autoHide = true,
            expirationTime = GetTime() + 2,
        }
        if spellID == aura_env.spellID then
            if casterName == aura_env.nextCaster then
                aura_env.updateNextCaster(casterName);
                allstates[''].nextCaster = aura_env.nextCaster
                allstates[''].changed = true;
            end
            if isExpired then
                allstates[''].stacks = 0;
                allstates[''].show = false;
                allstates[''].changed = true;
            end
        end
    end
    return true;
end


