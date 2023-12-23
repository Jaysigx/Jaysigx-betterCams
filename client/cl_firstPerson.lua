local attachedCam = nil
local sensitivity = 10.0
local springiness = 0.25 -- Adjust the springiness factor
local parallaxFactor = 0.5
local isHudComponent16Active = false
local isHudComponent19Active = false
local prevMouseX, prevMouseY = 0.0, 0.0

local minXRotation = -60.0
local maxXRotation = 60.0 

local defaultFOV = 65.0
local highSpeedFOV = 90.0
local speedThreshold = 90.0 -- Speed threshold for changing FOV (in mph)

local isCarMoving = false
local isTransitioning = false
local transitionSpeed = 0.1 -- Adjust the transition speed

function LerpVector(start, target, alpha)
    return start + (target - start) * alpha
end

function LerpAngle(start, target, alpha)
    local startAngle = start
    local endAngle = target
    local normalizedAngle = endAngle - startAngle

    if normalizedAngle > 180 then
        normalizedAngle = normalizedAngle - 360
    elseif normalizedAngle < -180 then
        normalizedAngle = normalizedAngle + 360
    end

    return startAngle + normalizedAngle * alpha
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local isInVehicle = IsPedInAnyVehicle(playerPed, false)
        local isInFirstPerson = GetFollowPedCamViewMode() == 4
        
        isHudComponent16Active = IsHudComponentActive(16)
        isHudComponent19Active = IsHudComponentActive(19)
        local isAiming = IsPlayerFreeAiming(PlayerId())

        if isInVehicle and isInFirstPerson then
            if isAiming and attachedCam then
                -- Transition from aiming to not aiming
                RenderScriptCams(0, 0, attachedCam, 0, 0)
                DestroyCam(attachedCam, false)
                attachedCam = nil
                isTransitioning = true
            elseif not isAiming and not attachedCam then
                -- Transition from not aiming to aiming
                attachedCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
                isTransitioning = true
            end

            if attachedCam then
                local currentCamRot = GetCamRot(attachedCam, 2)

                local mouseX, mouseY = 0.0, 0.0

                if not isHudComponent16Active and not isHudComponent19Active then
                    mouseX = GetDisabledControlNormal(0, 1) * sensitivity
                    mouseY = GetDisabledControlNormal(0, 2) * sensitivity

                    prevMouseX, prevMouseY = mouseX, mouseY -- Store the previous mouse values
                else
                    mouseX, mouseY = 0.0, 0.0 -- Set mouse values to zero if HUD components are active
                end

                mouseX = prevMouseX + mouseX
                mouseY = prevMouseY + mouseY

                local headRotation = GetEntityBoneRotation(playerPed, GetEntityBoneIndexByName(playerPed, "SKEL_Head"))

                -- Blend head rotation and mouse input for the camera rotation
                local newCamRotX = math.max(math.min(currentCamRot.x - mouseY + headRotation.x * 0.5, maxXRotation), minXRotation)
                local newCamRotZ = currentCamRot.z - mouseX + headRotation.z * 0.5


                SetCamRot(attachedCam, newCamRotX, currentCamRot.y, newCamRotZ, 2)
                
                SetCamFov(attachedCam, 70.0)
                AttachCamToPedBone(attachedCam, playerPed, 31086, 0.05, 0.05, 0.01, true)

                local playerCoords = GetPedBoneCoords(playerPed, 31086)
                local currentCamCoords = GetCamCoord(attachedCam)
                local newCamCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)

                local interpX = LerpVector(currentCamCoords.x, newCamCoords.x, springiness)
                local interpY = LerpVector(currentCamCoords.y, newCamCoords.y, springiness)
                local interpZ = LerpVector(currentCamCoords.z, newCamCoords.z, springiness)

                local backgroundOffset = vector3(interpX, interpY, interpZ) - currentCamCoords
                local adjustedCoords = currentCamCoords + backgroundOffset

                if isTransitioning then
                    local playerCoords = GetPedBoneCoords(playerPed, 31086)
                    local currentCamCoords = GetCamCoord(attachedCam)
                    local newCamCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)

                    local adjustedCoords = LerpVector(currentCamCoords, newCamCoords, transitionSpeed)
                    SetCamCoord(attachedCam, adjustedCoords.x, adjustedCoords.y, adjustedCoords.z)

                    if adjustedCoords == currentCamCoords then
                        isTransitioning = false
                    end
                end

                SetCamCoord(attachedCam, adjustedCoords.x, adjustedCoords.y, adjustedCoords.z)

                local vehicle = GetVehiclePedIsIn(playerPed, false)

                if DoesEntityExist(vehicle) then
                    local speed = GetEntitySpeed(vehicle)
                    local speedMph = speed * 2.23694
                
                    local movingThreshold = 5
                    local highSpeedFOV = 90.0
                
                    local isCarMoving = speedMph > movingThreshold
                
                    if isCarMoving then
                        local fov = math.min(70.0 + (speedMph - movingThreshold) * 0.5, highSpeedFOV)
                        SetCamFov(attachedCam, fov)
                
                        local firstPersonCamRot = GetGameplayCamRot()
                        local vehicleHeading = GetEntityHeading(vehicle)
                
                        local lerpedRotZ = LerpAngle(firstPersonCamRot.z, vehicleHeading, 0.5) -- Adjust the springiness factor (0.3 in this case)
                
                        SetCamRot(attachedCam, firstPersonCamRot.x, firstPersonCamRot.y, lerpedRotZ, 2)
                    end
                end
                RenderScriptCams(1, 0, attachedCam, 0, 0)
                HideHudComponentThisFrame(14)
            end
        else
            if attachedCam then
                RenderScriptCams(0, 0, attachedCam, 0, 0)
                DestroyCam(attachedCam, false)
                attachedCam = nil
            end
        end
    end
end)
