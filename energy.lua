aura_env.previous_tick = GetTime()
aura_env.previous_energy = UnitPower("player")
aura_env.BASE_ENERGY_TICK = 20
aura_env.MAX_ENERGY = 100
aura_env.AR_ENERGY_TICK = 40
--UNIT_POWER_UPDATE, MAX_POWER_UPDATE, TRIGGER:1
aura_env.t = function(allstates, event, unit, power)
    local current_tick = GetTime()
    local current_energy = UnitPower("player")
    if event == "UNIT_POWER_UPDATE"
        and unit == "player" and power == "ENERGY"
    then
        local energy_gain = current_energy - aura_env.previous_energy

        local is_server_energy_tick = function()
            if current_tick == aura_env.previous_tick + 2 -- 2sec since last tick
            then
                return true
            end
            if (math.abs(energy_gain - aura_env.BASE_ENERGY_TICK) <= 2) -- ~20 energy tick
                or (math.abs(energy_gain - aura_env.AR_ENERGY_TICK) <= 2) -- ~40 energy tick
            then
                return true
            end
            if current_energy == aura_env.MAX_ENERGY          -- capping energy tick
                and energy_gain < aura_env.AR_ENERGY_TICK + 2 -- exclude thistle tea gains
            then
                return true
            end
            return false
        end
        if is_server_energy_tick() then
            aura_env.previous_tick = current_tick
            allstates[""] = {
                show = true,
                changed = true,
                progressType = "timed",
                expirationTime = current_tick + 2,
                duration = 2,
                autoHide = true,
            }
            if current_energy == aura_env.MAX_ENERGY then
                C_Timer.After(2, function() WeakAuras.ScanEvents("MAX_POWER_UPDATE") end)
            end
        end
    elseif event == "MAX_POWER_UPDATE" then
        allstates[""] = {
            show = true,
            changed = true,
            progressType = "timed",
            expirationTime = current_tick + 2,
            duration = 2,
            autoHide = true,
        }
        if current_energy == aura_env.MAX_ENERGY then
            C_Timer.After(2, function() WeakAuras.ScanEvents("MAX_POWER_UPDATE") end)
        end
    end
    aura_env.previous_energy = current_energy
    return true
end
