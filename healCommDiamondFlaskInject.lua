if not aura_env.init then
    if LibStub then
        ---@class LibHealComm-4.0
        local HealComm = LibStub:GetLibrary("LibHealComm-4.0")
        -- DevTools_Dump(HealComm)
        if HealComm and UnitClass("player") == "Warrior" then
            local DiamondFlask = GetSpellInfo(363880)
            local interval, duration = 5, 60
            local ticks = duration / interval
            -- Diamond Flask HoT benefits from spell power at 1:5 vs the the Normal 1:15
            HealComm.hotData[DiamondFlask] = {
                coeff = duration / 5, 
                interval = interval, 
                levels = {50}, 
                ticks = ticks,
                averages = {108}
            }
            function HealComm:GetHealTargets(bitType, guid, spellID)
                return HealComm.compressGUID[UnitGUID("player")]
            end

            function HealComm:CalculateHotHealing(guid, spellID)
                local hotData = HealComm.hotData
                local spellName, spellRank = GetSpellInfo(spellID), 1
                local totalBaseHeal = hotData[spellName].averages[spellRank]
                local bonusHealing = GetSpellBonusHealing()
                local ticks = hotData[spellName].ticks
                local coeff = hotData[spellName].coeff
                local interval = hotData[spellName].interval
                local estTotalHeal = playerHealModifier * (
                        totalBaseHeal + (bonusHealing * coeff )
                    )
                local estTickHeal = estTotalHeal / ticks

                return HealComm.HOT_HEALS, estTickHeal, ticks, interval
            end
            HealComm:OnInitialize()
            print("Diamond Flask added to LibHealComm-4.0")
            aura_env.init = true
        end
    end
end


-- /dump LibStub.libs["LibHealComm-4.0"].CalculateHotHealing
-- /dump LibStub.libs["LibHealComm-4.0"].hotData["Diamond Flask"].averages[
-- Similarly, a DoT or HoT needs to last at least 15 seconds to get the full additional spell power
