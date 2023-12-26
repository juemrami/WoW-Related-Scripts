aura_env.BASE_ENERGY_TICK = 20
aura_env.AR_ENERGY_TICK = aura_env.BASE_ENERGY_TICK * 2
aura_env.MAX_ENERGY = UnitPowerMax("player") or 100
aura_env.previous_energy = UnitPower("player")
---Last seen energy tick as a system time in seconds. `GetTime()`
aura_env.last_system_tick = nil ---@type number?
---Last seen energy server tick timestamp. `GetServerTime()`
aura_env.last_server_tick = nil ---@type number?

aura_env.is_using_fake_tick = false
--UNIT_POWER_UPDATE, MAX_POWER_UPDATE, TRIGGER:1
aura_env.onEvent = function(allstates, event, unit, power)
    local current_tick = GetTime()
    local current_energy = UnitPower("player")
    local print = aura_env.debug or print
    if event == "UNIT_POWER_UPDATE"
        and unit == "player" and power == "ENERGY"
    then
        local energy_gain = current_energy - aura_env.previous_energy
        local is_server_energy_tick = function()
            -- Ticks must come in ~2 sec intervals
            local is_possible_tick = function()
                local buffer_length = 0.25 -- seconds
                local diff = abs(current_tick - (aura_env.last_system_tick + 2))
                local show = (diff <= buffer_length)
                    -- except for the first tick (before we start tracking)
                    or not (allstates[""] and allstates[""].show)
                    -- and ticks comming out of using fake ticks
                    or aura_env.is_using_fake_tick
                    if allstates[""] and allstates[""].show and not aura_env.is_using_fake_tick then
                        print(("energy gained within %.3f sec of next expected tick")
                            :format(diff))
                    else
                        print("tracking first possible server tick")
                    end
                return show
            end
            if is_possible_tick() then
                -- Ticks must match expected energy gain
                if -- ~20 energy gained (plus/minus 1)
                    abs(energy_gain - aura_env.BASE_ENERGY_TICK) <= 1
                    -- ~40 energy gained with AR (plus/minus 2)
                    or (aura_env.is_adrenaline_rush_active()
                        and abs(energy_gain - aura_env.AR_ENERGY_TICK) <= 2)
                then
                    return true
                end
                -- When accounting for capping energy ticks
                if current_energy == aura_env.MAX_ENERGY
                    -- make sure to exclude gains over 40 (ie thistle tea)
                    and energy_gain < aura_env.AR_ENERGY_TICK + 2
                then
                    return true
                end
            end
            return false
        end
        -- print("energy changed. verifying tick")
        if energy_gain > 0 then
            print("energy gain: ", energy_gain, "| current: ", current_energy, "| previous: ", aura_env.previous_energy)
        end
        if energy_gain > 0 and is_server_energy_tick() then
            print("server tick detected.")
            aura_env.last_system_tick = current_tick
            allstates[""] = {
                show = true,
                changed = true,
                progressType = "timed",
                expirationTime = current_tick + 2,
                duration = 2,
                autoHide = true,
            }
            if current_energy == aura_env.MAX_ENERGY then
                print("max energy reached. starting fake tick events")
                aura_env.is_using_fake_tick = true
                C_Timer.After(2, function() WeakAuras.ScanEvents("MAX_POWER_UPDATE") end)
            else
                aura_env.is_using_fake_tick = false
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

---Returns the system time in seconds for the next expected energy tick.
---This signals both the start of the next tick, and the end of current tick.
---@return number? 
aura_env.get_next_tick = function()
-- first check for lastServerTickTimestamp
-- if available we will calculate the next tick based on server time over system time. this should be more accurate and eliminate drift.

-- if not available, we will calculate the next tick based on system time.
-- if not lastSystemTick then return nil 
-- meaning were not sure when the next tick is coming,
-- otherwise return system tick + 2
end

aura_env.onHide = function()
-- lastSeenTick = nil
end

aura_env.debug = function (...)
    if aura_env.config.debug then
        print(...)
    end
end

aura_env.is_adrenaline_rush_active = function()
    local spell_id = 13750 -- Adrenaline Rush
    local localized_name = GetSpellInfo(spell_id)
    return AuraUtil.FindAuraByName(
        localized_name, "player", "HELPFUL"
    ) ~= nil
end
--- notes
--- supposedly, the tick is actually coming in every 2.03 seconds while your energy is in a regeneration state..
--- and the energy gained is calculated by energy per second (10) times seconds since last tick (2.03) = 20.3 energy per tick.
--- the the 4th tick will come at 2.03 * 4 = 8.12s = 81.2 energy gained.
--- this is where the extra 1 energy comes from.
--- this continues until you reach 100 energy (capping tick). at which point you stop regenerating energy AFTER the following tick.
--- None if this is confirmed tho. just what ive read.


--- 2.03 * 5 = 10.15s = 101.5 energy gained.
--- 2.03 * 6 = 12.18s = 121.8 energy gained.
--- 2.03 * 7 = 14.21s = 142.1 energy gained. -- here youll notice the extra 1 energy.
--- 2.03 * 8 = 16.24s = 162.4 energy gained.
--- 2.03 * 9 = 18.27s = 182.7 energy gained.
--- 2.03 * 10 = 20.3s = 203 energy gained. -- same here (assuming you havent capped energy since first tick)
