if not aura_env.init then
    if LibStub then
        ---@class LibHealComm-4.0
        local HealComm = LibStub("LibHealComm-4.0")
        if
            UnitClass("player") == "Warrior"
            and HealComm then
            local DiamondFlask = GetSpellInfo(363880)
            HealComm.hotData = HealComm.hotData or {}
            HealComm.hotData[DiamondFlask] = {
                interval = 5,
                levels = { 50 },
                ticks = 12,
                --12*9
                averages = { 108 }
            }
            function HealComm:GetHealTargets(bitType, guid, spellID)
                return HealComm.compressGUID[UnitGUID("player")]
            end

            function HealComm:CalculateHotHealing(guid, spellID)
                local spellName = GetSpellInfo(spellID)
                local baseTick = ceil(HealComm.hotData[spellName].averages[1]
                    / HealComm.hotData[spellName].ticks)
                local tickAmount = baseTick + (GetSpellBonusHealing() or 0)
                return
                    HealComm.HOT_HEALS,
                    tickAmount,
                    HealComm.hotData[spellName].ticks,
                    HealComm.hotData[spellName].interval
            end

            function HealComm:CalculateHealing(guid, spellID)
                local spellName = GetSpellInfo(spellID)
                local baseTick = ceil(HealComm.hotData[spellName].averages[1]
                    / HealComm.hotData[spellName].ticks)
                local tickAmount = baseTick + (GetSpellBonusHealing() or 0)
                return
                    HealComm.HOT_HEALS,
                    tickAmount,
                    HealComm.hotData[spellName].ticks,
                    HealComm.hotData[spellName].interval
            end
            HealComm:OnInitialize()
            print("Diamond Flask added to LibHealComm-4.0")
            aura_env.init = true
        end
    end
end


-- /dump LibStub.libs["LibHealComm-4.0"].CalculateHotHealing
-- /dump LibStub.libs["LibHealComm-4.0"].hotData["Diamond Flask"].averages[
