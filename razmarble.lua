aura_env.bagOrder = {
    "Bigspirit",
    "Forashona",
    "Baldnfat",
    "Thoriun",
    "Oblagb",
    "Boglemage",
    "Dilphiv",
    "Griefedhc",
    "Santypaws",
};
aura_env.queuedCaster = aura_env.bagOrder[1];
aura_env.spellName = "Shadow Word: Pain"; -- "Fumble";
aura_env.destName = "Prowler" -- "Instructor Razuvious"
aura_env.marblesCooldown = 60;
aura_env.bagOfMarblesId = 1191;
-- wow classic doesnt include the spellID in the combat log
-- aura_env.spellID = 589; -- 5917

aura_env.updateCasterQueue = function()
    if not aura_env.bagOrder then return end
    local currentCaster = aura_env.queuedCaster
    for i = 1, #aura_env.bagOrder do
        if currentCaster == aura_env.bagOrder[i] then
            if aura_env.bagOrder[i + 1] then
                aura_env.queuedCaster = aura_env.bagOrder[i + 1];
            else
                aura_env.queuedCaster = aura_env.bagOrder[1];
            end
        end
    end
end
-- Events: UNIT_THREAT_LIST_UPDATE, 
-- CLEU:SPELL_AURA_APPLIED:SPELL_MISSED
aura_env.onEvent = function(states, event, ...)
    if not states[''] then
        print("no states")
        local name, _, icon = GetSpellInfo(aura_env.spellID);
        states[''] = {
            icon = icon,
            name = name,
            progressType = "timed",
            duration = 10,
            autoHide = false,
            expirationTime = GetTime(),
            sourceName = "None",
            nextCaster = aura_env.bagOrder[1],

        }
    end
    if event == "OPTIONS" then
        states[''].sourceName = aura_env.bagOrder[1]
        states[''].nextCaster = aura_env.bagOrder[2]
        states[''].changed = true
        states[''].show = true
        states[''].stacks = 1
        return true
    end
    local subEvent, _, casterGUID, casterName= select(2, ...)
    local destGUID, destName, _, _ , _,spellName = select(8, ...);
    if event == "UNIT_THREAT_LIST_UPDATE" then
        print(UnitName(...))
        local enemyUnit = ...
        if UnitHealth(enemyUnit)  > 0 
        -- and UnitName(enemyUnit) == aura_env.destName
        then
            states[''].show = true;
            states[''].changed = true;
        else
            states[''].show = false;
            states[''].changed = true;
        end
    elseif subEvent == "SPELL_AURA_APPLIED" then
        print(subEvent)
        if spellName == aura_env.spellName then
            if casterName == aura_env.queuedCaster then
                aura_env.updateCasterQueue()
            end
            -- if destName == aura_env.destName then
            if true then
                states[''].expirationTime = GetTime() + 10;
                states[''].sourceName = casterName;
                states[''].destName = destName;
                states[''].stacks = 1;
                states[''].show = true;
            end
            states[''].nextCaster = aura_env.queuedCaster
            states[''].changed = true;
            return true;
        end
    elseif subEvent == "SPELL_MISSED" then
        WeakAuras.ScanEvents("RAZ_MARBLE_CAST_MISSED")
        if spellName == aura_env.spellName then
            if casterName == aura_env.queuedCaster then
                aura_env.updateCasterQueue();
                states[''].nextCaster = aura_env.queuedCaster
                states[''].changed = true;
            end
            if casterGUID == UnitGUID("player") then
                -- notify WA users of new stack 
            end
        end
    end
    return true;
end


