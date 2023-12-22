-- Vehicle damage shake effect
local lastDamage = 0.0
local vehicle = nil

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()

        if IsPedInAnyVehicle(playerPed) then
            local curVehicle = GetVehiclePedIsIn(playerPed, false)

            if curVehicle ~= vehicle then
                vehicle = curVehicle
                lastDamage = GetVehicleBodyHealth(vehicle)
            else
                local curHealth = GetVehicleBodyHealth(vehicle)
                local damage = lastDamage - curHealth

                if damage > 5 then
                    local shakeRate = math.min(damage / 200.0, 1.0) -- Scale the shake rate
                    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", shakeRate)
                end

                lastDamage = curHealth
            end
        else
            vehicle = nil
        end
    end
end)

-- Player movement shake effect
local isPlayerMoving = false
local originalFov = GetGameplayCamFov()

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local isInVehicle = IsPedInAnyVehicle(ped, false)
        local speed = GetEntitySpeed(ped) * 3.6 -- Convert speed to km/h
        
        if not isInVehicle and speed >= 1.0 and GetFollowPedCamViewMode() ~= 4 then
            if not isPlayerMoving then
                ShakeGameplayCam("ROAD_VIBRATION_SHAKE", 0.5)
                isPlayerMoving = true
                SetCamFov(GameplayCam, originalFov + 10.0) -- Adjust the FOV for a zoom effect
            end
        else
            if isPlayerMoving then
                StopGameplayCamShaking(false)
                isPlayerMoving = false
                SetCamFov(GameplayCam, originalFov) -- Reset FOV to its original value
            end
        end
    end
end)

-- Vehicle driving shake effect
local isDriving = false

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert speed to km/h

            if DoesEntityExist(vehicle) then
                if speed >= 5 and not isDriving then
                    isDriving = true
                    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.3)
                    Citizen.Wait(500)
                    StopGameplayCamShaking(0)
                elseif speed >= 250 and isDriving then
                    isDriving = false
                    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.75)
                    Citizen.Wait(1000)
                    StopGameplayCamShaking(0)
                elseif speed < 1.0 and IsVehicleInBurnout(vehicle) then
                    isDriving = false
                    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.75)
                    Citizen.Wait(1000)
                    StopGameplayCamShaking(0)
                elseif speed == 0 then
                    isDriving = false
                end
            end
        end
    end
end)

