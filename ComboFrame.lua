---Atlases (availabile in classic client)
-- ComboPoints-PointBg
-- ComboPoints-ComboPoint
-- ComboPoints-FX-Circle
-- ComboPoints-FX-Star

--- for extra CPs (not implemented )
-- ComboPoints-ComboPointDash-Bg
-- ComboPoints-ComboPointDash
-- ComboPoints-FX-Dash

-- ComboPoints-AllPointsBG
------------------------------------------
-- Data driven layout tweaks for differing numbers of combo point frames.
-- Indexed by max "usable" combo points (see below)
local comboPointMaxToLayout = {
    [5] = {
        ["width"] = 20,
        ["height"] = 21,
        ["xOffs"] = 1,
    },
    [6] = {
        ["width"] = 18,
        ["height"] = 19,
        ["xOffs"] = -1,
    },
};
---@param maxPoints number max points that should be shown
---@param currentPoint ComboPointFrame
---@param prevPoint ComboPointFrame?
local function updateComboPointLayout(maxPoints, currentPoint, prevPoint)
    local layout = comboPointMaxToLayout[maxPoints];

    currentPoint:SetSize(layout.width, layout.height);
    currentPoint.PointOff:SetSize(layout.width, layout.height);
    currentPoint.Point:SetSize(layout.width, layout.height);

    if (prevPoint) then
        currentPoint:SetPoint("LEFT", prevPoint, "RIGHT", layout.xOffs, 0);
    end
end

---@param parent? Frame # should be the ComboPointPlayerFrame
---@param index number # should be the index of the combo point
local createNewComboPoint = function(parent, index)
    ---@class ComboPointFrame : Frame
    ---@field PointAnim AnimationGroup
    ---@field AnimIn AnimationGroup
    ---@field AnimOut AnimationGroup
    local pointFrame = CreateFrame("Frame", "$parentComboPoint" .. index, parent)
    pointFrame.on = false
    pointFrame:SetSize(20, 21)

    local pointBg = pointFrame:CreateTexture("$parentPointBg", "BACKGROUND")
    pointBg:SetAtlas("ComboPoints-PointBg", false)
    pointBg:SetSize(20, 21)
    pointBg:SetPoint("CENTER")
    -- pointBg:SetPoint("CENTER", parent)
    pointFrame.PointOff = pointBg

    local actualPoint = pointFrame:CreateTexture("$parentPoint", "ARTWORK")
    actualPoint:SetAtlas("ComboPoints-ComboPoint", false)
    actualPoint:SetBlendMode("BLEND")
    actualPoint:SetAlpha(0)
    actualPoint:SetSize(20, 21)
    actualPoint:SetPoint("CENTER")
    pointFrame.Point = actualPoint

    local fxCircle = pointFrame:CreateTexture("$parentFXCircle", "ARTWORK")
    fxCircle:SetAtlas("ComboPoints-FX-Circle", true) -- uses atlas size
    fxCircle:SetBlendMode("BLEND")
    fxCircle:SetAlpha(0)
    -- fxCircle:SetSize(20, 21)
    fxCircle:SetPoint("CENTER")
    pointFrame.CircleBurst = fxCircle

    local fxStar = pointFrame:CreateTexture("$parentFXStar", "OVERLAY")
    fxStar:SetAtlas("ComboPoints-FX-Star", true) -- uses atlas size
    fxStar:SetBlendMode("ADD")
    fxStar:SetAlpha(0)
    fxStar:SetPoint("CENTER")
    pointFrame.Star = fxStar

    -- Animations
    local pointAnim = pointFrame:CreateAnimationGroup("$parentPointAnim")
    pointAnim:SetToFinalAlpha(true)
    local pointAlpha = pointAnim:CreateAnimation("Alpha")
    pointAlpha:SetDuration(0.25)
    pointAlpha:SetOrder(1)
    pointAlpha:SetFromAlpha(0)
    pointAlpha:SetToAlpha(1)
    pointAlpha:SetChildKey("Point")
    local pointScale = pointAnim:CreateAnimation("Scale")
    pointScale:SetSmoothing("OUT")
    pointScale:SetDuration(0.25)
    pointScale:SetOrder(1)
    pointScale:SetScaleFrom(0.8, 0.8)
    pointScale:SetScaleTo(1, 1)
    pointScale:SetChildKey("Point")
    pointAnim:SetParentKey("PointAnim")

    local animIn = pointFrame:CreateAnimationGroup("$parentAnimIn")
    animIn:SetToFinalAlpha(true)
    local starScale = animIn:CreateAnimation("Scale")
    starScale:SetSmoothing("OUT")
    starScale:SetDuration(0.5)
    starScale:SetOrder(1)
    starScale:SetScaleFrom(0.25, 0.25)
    starScale:SetScaleTo(0.9, 0.9)
    starScale:SetChildKey("Star")
    local starRot = animIn:CreateAnimation("Rotation")
    starRot:SetSmoothing("OUT")
    starRot:SetDuration(0.8)
    starRot:SetOrder(1)
    starRot:SetDegrees(-60)
    starRot:SetChildKey("Star")
    local starAlpha = animIn:CreateAnimation("Alpha")
    starAlpha:SetSmoothing("IN")
    starAlpha:SetDuration(0.4)
    starAlpha:SetOrder(1)
    starAlpha:SetFromAlpha(0.75)
    starAlpha:SetToAlpha(0)
    starAlpha:SetStartDelay(0.5)
    starAlpha:SetChildKey("Star")
    local circleAlpha = animIn:CreateAnimation("Alpha")
    circleAlpha:SetDuration(0.1)
    circleAlpha:SetOrder(1)
    circleAlpha:SetFromAlpha(0)
    circleAlpha:SetToAlpha(1)
    circleAlpha:SetChildKey("CircleBurst")
    local circleScale = animIn:CreateAnimation("Scale")
    circleScale:SetSmoothing("OUT")
    circleScale:SetDuration(0.25)
    circleScale:SetOrder(1)
    circleScale:SetScaleFrom(1.25, 1.25)
    circleScale:SetScaleTo(0.75, 0.75)
    circleScale:SetChildKey("CircleBurst")
    local circleAlpha2 = animIn:CreateAnimation("Alpha")
    circleAlpha2:SetSmoothing("IN")
    circleAlpha2:SetDuration(0.25)
    circleAlpha2:SetOrder(1)
    circleAlpha2:SetFromAlpha(1)
    circleAlpha2:SetToAlpha(0)
    circleAlpha2:SetStartDelay(0.25)
    circleAlpha2:SetChildKey("CircleBurst")
    animIn:SetParentKey("AnimIn")

    local animOut = pointFrame:CreateAnimationGroup("$parentAnimOut")
    animOut:SetToFinalAlpha(true)
    local circleAlpha = animOut:CreateAnimation("Alpha")
    circleAlpha:SetDuration(0.1)
    circleAlpha:SetOrder(1)
    circleAlpha:SetFromAlpha(0)
    circleAlpha:SetToAlpha(1)
    circleAlpha:SetChildKey("CircleBurst")
    local circleScale = animOut:CreateAnimation("Scale")
    circleScale:SetSmoothing("OUT")
    circleScale:SetDuration(0.4)
    circleScale:SetOrder(1)
    circleScale:SetScaleFrom(0.8, 0.8)
    circleScale:SetScaleTo(0.6, 0.6)
    circleScale:SetChildKey("CircleBurst")
    local circleAlpha2 = animOut:CreateAnimation("Alpha")
    circleAlpha2:SetSmoothing("IN")
    circleAlpha2:SetDuration(0.25)
    circleAlpha2:SetOrder(1)
    circleAlpha2:SetFromAlpha(1)
    circleAlpha2:SetToAlpha(0)
    circleAlpha2:SetStartDelay(0.25)
    circleAlpha2:SetChildKey("CircleBurst")
    animOut:SetParentKey("AnimOut")

    return pointFrame
end
local comboFrameID = "ComboPointPlayerFrame"
---@param parent? Frame
local createComboPointBar = function(parent)
    ---@class ComboPointBar : Frame
    local bar = CreateFrame("Frame", comboFrameID, parent or PlayerFrame)
    bar:SetSize(126, 18)
    if parent then
        bar:SetPoint("CENTER", 0, 0)
    else -- hook onto player frame like blizzard does
        bar:SetPoint("TOP", PlayerFrame, "BOTTOM", 50, 38)
        bar:SetFrameLevel(PlayerFrame:GetFrameLevel() + 2) -- copied from blizzard code
    end
    local barBg = bar:CreateTexture("$parentBackGround", "OVERLAY")
    barBg:SetAtlas("ComboPoints-AllPointsBG", true)
    barBg:SetPoint("TOPLEFT")
    bar.BackGround = barBg
    bar.ComboPoints = {} ---@type ComboPointFrame[]
    for i = 1, 6 do
        local pointFrame = createNewComboPoint(bar, i)
        if i == 1 then
            pointFrame:SetPoint("TOPLEFT", 11, -2)
        else
            pointFrame:SetPoint("LEFT", bar.ComboPoints[i - 1], "RIGHT", 1, 0)
        end
        pointFrame:SetParentKey("ComboPoint" .. i)
        pointFrame:SetShown(false)
        bar.ComboPoints[i] = pointFrame
    end
    return bar
end
aura_env.getComboPointBar = function()
    if not _G[comboFrameID] then
        local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
        assert(aura_env.region, "WA Region not found. Please report to the author.")
        local bar = createComboPointBar(aura_env.region) 
        local parentLevel = bar:GetParent():GetFrameLevel()
        -- Move frame back -2 level for the bg 
        -- and then raise the combo points back to parent.
        bar:SetFrameLevel(parentLevel - 2);
        for i = 1, maxComboPoints do
            updateComboPointLayout(
                maxComboPoints, 
                bar.ComboPoints[i], 
                bar.ComboPoints[i - 1]
            )
            bar.ComboPoints[i]:SetShown(true)
            bar.ComboPoints[i]:SetFrameLevel(parentLevel)
        end
        aura_env.bar = bar
    else
        aura_env.bar = _G[comboFrameID]
    end
    return aura_env.bar
end
aura_env.maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
--- events: PLAYER_ENTERING_WORLD, UNIT_POWER_UPDATE
aura_env.onEvent = function(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or not aura_env.bar then
        aura_env.bar = aura_env.getComboPointBar()
        aura_env.bar.BackGround:SetShown(not aura_env.config.hideBackground)
        -- in order to move it around with WA.
        -- aura_env.bar:SetParent(aura_env.region.texture)
        -- aura_env.bar:SetParentKey("texture")
    end
    if not aura_env.bar then 
        -- not sure when this might happen. 
        -- an error in creating the frames maybe
        return
    end
    if event == "UNIT_POWER_UPDATE" then
        local player, powerTypeStr = ...
        if player ~= "player" or powerTypeStr ~= "COMBO_POINTS" then
            return
        end
        aura_env.updateComboPoints()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" 
    and select(2,...) == "UNIT_DIED"
    and select(8,...) == UnitGUID("target") 
    then
        C_Timer.After(0.5, function() aura_env.updateComboPoints(0) end)
    elseif event == "OPTIONS" then
        if aura_env.config.hideBackground then
            aura_env.bar.BackGround:SetShown(false)
        else
            aura_env.bar.BackGround:SetShown(true)
        end
        WeakAuras.ScanEvents("COMBO_POINT_DEMO")
    elseif event == "COMBO_POINT_DEMO" then
        if WeakAuras.IsOptionsOpen() 
        and (not aura_env.lastDemoEvent
        or GetTime() - aura_env.lastDemoEvent >= 1)
        then
            aura_env.updateDemoState()
            C_Timer.After(1, 
                function()
                    WeakAuras.ScanEvents("COMBO_POINT_DEMO")
                    if aura_env then
                        aura_env.lastDemoEvent = GetTime()
                    end
                end
            )
        elseif not WeakAuras.IsOptionsOpen() then
            -- this should happen with the status event.
            -- here just to be safe with the cleanup
            aura_env.updateComboPoints()
        end
    elseif event == "STATUS" then
        aura_env.updateComboPoints()
    end
end
aura_env.updateComboPoints = function(forcePoints)
    local currentPoints = forcePoints 
        and forcePoints 
        or UnitPower("player", Enum.PowerType.ComboPoints)

    for i = 1, min(currentPoints, aura_env.maxPoints) do
        aura_env.animIn(aura_env.bar.ComboPoints[i])
    end
    for i = currentPoints + 1, aura_env.maxPoints do
        aura_env.animOut(aura_env.bar.ComboPoints[i])
    end
end
aura_env.updateDemoState = function()
    aura_env.demoPoints = aura_env.demoPoints or {5, 4, 3, 2, 1, 0}
    local points = aura_env.demoPoints[#aura_env.demoPoints]
    aura_env.updateComboPoints(points)
    tremove(aura_env.demoPoints)
    if #aura_env.demoPoints == 0 then
        aura_env.demoPoints = nil
    end
end

---@param point ComboPointFrame
aura_env.animIn = function(point)
    if (not point.on) then
        point.on = true;
        point.AnimIn:Play();

        if (point.PointAnim) then
            point.PointAnim:Play();
        end
    end
end
---@param point ComboPointFrame
aura_env.animOut = function(point)
    if (point.on) then
        point.on = false;

        if (point.PointAnim) then
            point.PointAnim:Play(true);
        end

        point.AnimIn:Stop();
        point.AnimOut:Play();
    end
end
