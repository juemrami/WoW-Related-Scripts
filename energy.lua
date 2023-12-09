aura_env.BASE_ENERGY_TICK = 20
aura_env.AR_ENERGY_TICK = aura_env.BASE_ENERGY_TICK * 2
aura_env.MAX_ENERGY = UnitPowerMax("player") or 100
aura_env.previous_energy = UnitPower("player")
aura_env.previous_tick = GetTime()

--UNIT_POWER_UPDATE, MAX_POWER_UPDATE, TRIGGER:1
aura_env.onEvent = function(allstates, event, unit, power)
    local current_tick = GetTime()
    local current_energy = UnitPower("player")
    if event == "UNIT_POWER_UPDATE"
        and unit == "player" and power == "ENERGY"
    then
        local energy_gain = current_energy - aura_env.previous_energy

        local is_server_energy_tick = (function()
            -- 2sec since last tick
            if current_tick == aura_env.previous_tick + 2 then
                return true
            end
            -- ~20 energy gained (plus/minus 1)
            if (math.abs(energy_gain - aura_env.BASE_ENERGY_TICK) <= 1) 
            -- ~40 energy gained (plus/minus 2)
            or (math.abs(energy_gain - aura_env.AR_ENERGY_TICK) <= 2) 
            then
                return true
            end
            -- capping energy tick
            if current_energy == aura_env.MAX_ENERGY 
                and energy_gain < aura_env.AR_ENERGY_TICK + 2 -- exclude thistle tea gains
            then
                return true
            end
            return false
        end)() -- self invoked
        if is_server_energy_tick then
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

--- notes
--- supposedly, the tick is actually comming in every 2.03 seconds while your energy is in a regeneration state..
--- and the enegy gained is calculated by energy per second (10) times seconds since last tick (2.03) = 20.3 energy per tick.
--- the the 4th tick will come at 2.03 * 4 = 8.12s = 81.2 energy gained.
--- this is where the extra 1 energy comes from.
--- this continues untill you reach 100 energy. at which point you stop regenerating energy.



--- 2.03 * 5 = 10.15s = 101.5 energy gained.
--- 2.03 * 6 = 12.18s = 121.8 energy gained.
--- 2.03 * 7 = 14.21s = 142.1 energy gained. -- here youll notice the extra 1 energy.
--- 2.03 * 8 = 16.24s = 162.4 energy gained.
--- 2.03 * 9 = 18.27s = 182.7 energy gained.
--- 2.03 * 10 = 20.3s = 203 energy gained. -- same here. 



