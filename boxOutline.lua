if not aura_env.saved then
    aura_env.saved = {
        -- default init, will be programmatically overwritten
        textureScale = 1,
    }
end
aura_env.oldZoom = GetCameraZoom()
aura_env.updateFPS = 15
aura_env.frameCount = 0
aura_env.onUpdate = function()
    if aura_env.frameCount % aura_env.updateFPS == 0 then
        aura_env.frameCount = 0
        local currentZoom = GetCameraZoom()
        if currentZoom < 10 then
            local alpha = aura_env.region:GetAlpha()
            if alpha ~= 0 then
                aura_env.savedAlpha = alpha
                aura_env.region:SetAlpha(0)
            end
        elseif currentZoom ~= aura_env.oldZoom then
            if aura_env.region:GetAlpha() == 0 then
                aura_env.region:SetAlpha(aura_env.savedAlpha)
            end
            local cameraDiffScale = currentZoom / aura_env.oldZoom
            aura_env.oldZoom = currentZoom
            aura_env.updateRegionSize(cameraDiffScale)
        end
    end
    aura_env.frameCount = aura_env.frameCount + 1
end
aura_env.updateRegionSize = function(scale)
    local width, height = aura_env.region:GetSize()
    local currentSize = aura_env.region:GetScale()
    -- we actually want the inverse scale to shrink when zoomed out and grow when zoomed in
    -- aura_env.region:SetRegionWidth(width * (1/scale))
    -- aura_env.region:SetRegionHeight(height * (1/scale))
    -- print("Olds texture dims: " .. width .. " x " .. height .. " -> " .. width * scale .. " x " .. height * scale)
    aura_env.region:SetScale(currentSize * (1/scale))
    print("Old scale: ", currentSize, ". New scale: ", currentSize * (1/scale))
end
-- events: PLAYER_ENTERING_WORLD, OPTIONS
aura_env.onEvent = function(event, ...)
    print(event, aura_env.state)
    if event == "OPTIONS" then
        -- when options are changed, update the preferred dimension for the given camera zoom
        aura_env.saved.setupZoom = GetCameraZoom() > 10 
            and GetCameraZoom()
    end
    if event == "PLAYER_ENTERING_WORLD"
        and aura_env.saved.setupZoom then
        -- check camera zoom
        if GetCameraZoom() ~= aura_env.saved.setupZoom then
            -- if zoom is not the same as the setup zoom, update size
            aura_env.updateRegionSize(
                GetCameraZoom() / aura_env.saved.setupZoom
            )
        end
    end
end
aura_env.initialized = true
