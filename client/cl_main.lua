local lastVehicleDamage = 0.0
local currentVehicle = nil

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local isInVehicle = IsPedInAnyVehicle(playerPed)
        
        if isInVehicle then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle ~= currentVehicle then
                currentVehicle = vehicle
                lastVehicleDamage = GetVehicleBodyHealth(vehicle)
            else
                local currentHealth = GetVehicleBodyHealth(vehicle)
                local damage = lastVehicleDamage - currentHealth

                if damage > 5 then
                    local shakeIntensity = math.min(damage / 200.0, 1.0)
                    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", shakeIntensity)
                end

                lastVehicleDamage = currentHealth
            end
        else
            currentVehicle = nil
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

local isDriving = false

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert speed to km/h

            if DoesEntityExist(vehicle) then
                if speed >= 250 then
                    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.75)
                    Citizen.Wait(1000)
                    StopGameplayCamShaking(0)
                elseif speed >= 5 and not isDriving then
                    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.3)
                    Citizen.Wait(500)
                    StopGameplayCamShaking(0)
                elseif speed < 1.0 and not IsVehicleInBurnout(vehicle) then
                    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.75)
                    Citizen.Wait(1000)
                    StopGameplayCamShaking(0)
                else
                    isDriving = false
                end
            end
        else
            isDriving = false
        end
    end
end)
