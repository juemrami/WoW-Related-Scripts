-- on init 
local a = function (self, unitId, unitFrame, envTable, modTable)
    if not unitFrame.currentTargetLabel then
        local size = 12
        local color = "white"
        unitFrame.currentTargetLabel = Plater:CreateLabel(unitFrame.healthBar, "", size, color) 
        unitFrame.currentTargetLabel:SetPoint ('top', 0, unitFrame.healthBar:GetHeight()+2)
    end
    
end
-- on update
local b = function (self, unitId, unitFrame, envTable, modTable)
    --insert code here
    local targetUnitName = UnitName(unitFrame.targetUnitID) or ""
    local classColor = "white"
    if targetUnitName then
        local _,className, _ = UnitClass(unitFrame.targetUnitID)
        if RAID_CLASS_COLORS[className] then
            classColor = "#"..RAID_CLASS_COLORS[className].colorStr
        end
    end
    --print(currentUnitTargetToken, text, size, color)
    if unitFrame.currentTargetLabel then
        unitFrame.currentTargetLabel.textcolor = classColor
        unitFrame.currentTargetLabel.text = targetUnitName
    end
    --ViragDevTool:AddData(unitFrame, "Unit Frame")
end
