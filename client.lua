local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local config = Config
local speedMultiplier = config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local showAltitude = false
local showSeatbelt = false
local nos = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0
local nitroActive = 0
local harness = 0
local hp = 100
local armed = 0
local parachute = -1
local oxygen = 100
local dev = false
local playerDead = false
local showMenu = false
local showCircleB = false
local showSquareB = false
local Menu = config.Menu
local CinematicHeight = 0.2
local w = 0

DisplayRadar(false)

local function CinematicShow(bool)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    if bool then
        DisplayRadar(false)
        for i = CinematicHeight, 0, -1.0 do
            Wait(10)
            w = i
        end
    else
      if IsPedInAnyVehicle(PlayerPedId()) then
        DisplayRadar(true)
      end
        for i = 0, CinematicHeight, 1.0 do
            Wait(10)
            w = i
        end
    end
end

local function loadSettings(settings)
    for k,v in pairs(settings) do
        if Menu.isCineamticModeChecked then
            Menu.isCineamticModeChecked = v
            CinematicShow(v)
            SendNUIMessage({ test = true, event = k, toggle = v})
        end
    end
    --QBCore.Functions.Notify(Lang:t("notify.hud_settings_loaded"), "success")
end

local function saveSettings()
    SetResourceKvp('hudSettings', json.encode(Menu))
end

local function hasHarness(items)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local _harness = false
    if items then
        for _, v in pairs(items) do
            if v.name == 'harness' then
                _harness = true
            end
        end
    end

    harness = _harness
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(2000)
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    PlayerData = {}
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(2000)
end)

CreateThread(function()
    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0

    if (aspectRatio > defaultAspectRatio) then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end

    RequestStreamedTextureDict("circlemap", false)
    while not HasStreamedTextureDictLoaded("circlemap") do
        Wait(150)
    end

    SetMinimapClipType(4)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
    SetMinimapComponentPosition("minimap", "L", "B", -0.0100 + minimapOffset, -0.030, 0.180, 0.258)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.03, 0.07, 0.1225, 0.17)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.00 + minimapOffset, 0.015, 0.252, 0.338)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)

    Wait(50)
    SetRadarBigmapEnabled(false, false)
end)

RegisterCommand('cinematic', function()
    TriggerEvent('pls-hud:client:cinematic')
end)

RegisterNetEvent('pls-hud:client:cinematic', function()
    Wait(50)
    if cine then
        CinematicShow(false)
        cine = false
        QBCore.Functions.Notify(Lang:t("notify.cinematic_off"), 'error')
    else
        CinematicShow(true)
        cine = true
        QBCore.Functions.Notify(Lang:t("notify.cinematic_on"), 'primary')
    end
end)

--RegisterNetEvent('hud:client:ToggleAirHud', function()
  --  showAltitude = not showAltitude
--end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst) -- Triggered in qb-core
    hunger = newHunger
    thirst = newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress) -- Add this event with adding stress elsewhere
    stress = newStress
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- Triggered in smallresources
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent('seatbelt:client:ToggleCruise', function() -- Triggered in smallresources
    cruiseOn = not cruiseOn
end)

RegisterNetEvent('hud:client:UpdateNitrous', function(_, nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent("qb-admin:client:ToggleDevmode", function()
    dev = not dev
end)

local function IsWhitelistedWeaponArmed(weapon)
    if weapon then
        for _, v in pairs(config.WhitelistedWeaponArmed) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

local prevPlayerStats = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }

local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    prevPlayerStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'hudtick',
            show = data[1],
            dynamicHealth = data[2],
            dynamicArmor = data[3],
            dynamicHunger = data[4],
            dynamicThirst = data[5],
            dynamicStress = data[6],
            dynamicOxygen = data[7],
            dynamicEngine = data[8],
            dynamicNitro = data[9],
            health = data[10],
            playerDead = data[11],
            armor = data[12],
            thirst = data[13],
            hunger = data[14],
            stress = data[15],
            voice = data[16],
            radio = data[17],
            talking = data[18],
            armed = data[19],
            oxygen = data[20],
            parachute = data[21],
            nos = data[22],
            cruise = data[23],
            nitroActive = data[24],
            harness = data[25],
            hp = data[26],
            speed = data[27],
            engine = data[28],
            cinematic = data[29],
            dev = data[30],
        })
    end
end

local prevVehicleStats = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }

local function updateVehicleHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevVehicleStats[k] ~= v then shouldUpdate = true break end
    end
    prevVehicleStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'car',
            show = data[1],
            isPaused = data[2],
            seatbelt = data[3],
            speed = data[4],
            fuel = data[5],
            altitude = data[6],
            showAltitude = data[7],
            showSeatbelt = data[8],
            showSquareB = data[9],
            showCircleB = data[10],
        })
    end
end

local lastFuelUpdate = 0
local lastFuelCheck = {}

local function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        lastFuelCheck = math.floor(exports['LegacyFuel']:GetFuel(vehicle))
    end
    return lastFuelCheck
end

-- HUD Update loop

CreateThread(function()
    local wasInVehicle = false
    while true do
        Wait(50)
        if LocalPlayer.state.isLoggedIn then
            local show = true
            local player = PlayerPedId()
            local playerId = PlayerId()
            local weapon = GetSelectedPedWeapon(player)
            -- Player hud
            if not IsWhitelistedWeaponArmed(weapon) then
                if weapon ~= `WEAPON_UNARMED` then
                    armed = true
                else
                    armed = false
                end
            end
            playerDead = IsEntityDead(player) or PlayerData.metadata["inlaststand"] or PlayerData.metadata["isdead"] or false
            parachute = GetPedParachuteState(player)
            -- Stamina
            if not IsEntityInWater(player) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
            end
            -- Oxygen
            if IsEntityInWater(player) then
                oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
            end
            -- Player hud
            local talking = NetworkIsPlayerTalking(playerId)
            local voice = 0
            if LocalPlayer.state['proximity'] then
                voice = LocalPlayer.state['proximity'].distance
            end
            if IsPauseMenuActive() then
                show = false
            end
            local vehicle = GetVehiclePedIsIn(player)
            if not (IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle)) then
            updatePlayerHud({
                show,
                Menu.isDynamicHealthChecked,
                Menu.isDynamicArmorChecked,
                Menu.isDynamicHungerChecked,
                Menu.isDynamicThirstChecked,
                Menu.isDynamicStressChecked,
                Menu.isDynamicOxygenChecked,
                Menu.isDynamicEngineChecked,
                Menu.isDynamicNitroChecked,
                GetEntityHealth(player) - 100,
                playerDead,
                GetPedArmour(player),
                thirst,
                hunger,
                stress,
                voice,
                LocalPlayer.state['radioChannel'],
                talking,
                armed,
                oxygen,
                parachute,
                -1,
                cruiseOn,
                nitroActive,
                harness,
                hp,
                math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                -1,
                Menu.isCineamticModeChecked,
                dev,
            })
            end
            -- Vehicle hud
            if IsPedInAnyHeli(player) or IsPedInAnyPlane(player) then
                showAltitude = true
                showSeatbelt = false
            end
            if IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle) then
                if not wasInVehicle then
                    DisplayRadar(true)
                end
                wasInVehicle = true
                updatePlayerHud({
                    show,
                    Menu.isDynamicHealthChecked,
                    Menu.isDynamicArmorChecked,
                    Menu.isDynamicHungerChecked,
                    Menu.isDynamicThirstChecked,
                    Menu.isDynamicStressChecked,
                    Menu.isDynamicOxygenChecked,
                    Menu.isDynamicEngineChecked,
                    Menu.isDynamicNitroChecked,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state['radioChannel'],
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    nos,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    (GetVehicleEngineHealth(vehicle) / 10),
                    Menu.isCineamticModeChecked,
                    dev,
                })
                updateVehicleHud({
                    show,
                    IsPauseMenuActive(),
                    seatbeltOn,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    getFuelLevel(vehicle),
                    math.ceil(GetEntityCoords(player).z * 0.5),
                    showAltitude,
                    showSeatbelt,
                    showSquareB,
                    showCircleB,
                })
                showAltitude = false
                showSeatbelt = true
            else
                if wasInVehicle then
                    wasInVehicle = false
                    SendNUIMessage({
                        action = 'car',
                        show = false,
                        seatbelt = false,
                        cruise = false,
                    })
                    seatbeltOn = false
                    cruiseOn = false
                    harness = false
                end
                DisplayRadar(0)
            end
        else
            SendNUIMessage({
                action = 'hudtick',
                show = false
            })
        end
    end
end)

-- Low fuel
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) and not IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(ped, false))) then
                if exports['LegacyFuel']:GetFuel(GetVehiclePedIsIn(ped, false)) <= 20 then -- At 20% Fuel Left
                    if Menu.isLowFuelChecked then
                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "pager", 0.10)
                        QBCore.Functions.Notify(Lang:t("notify.low_fuel"), "error")
                        Wait(60000) -- repeats every 1 min until empty
                    end
                end
            end
        end
        Wait(10000)
    end
end)

-- Harness Check

CreateThread(function()
    while true do
        Wait(1000)

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            hasHarness(PlayerData.items)
        end
    end
end)

-- Stress Gain

CreateThread(function() -- Speeding
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                local vehClass = GetVehicleClass(veh)
                local speed = GetEntitySpeed(veh) * speedMultiplier

                if vehClass ~= 13 and vehClass ~= 14 and vehClass ~= 15 and vehClass ~= 16 and vehClass ~= 21 then
                    local stressSpeed
                    if vehClass == 8 then
                        stressSpeed = config.MinimumSpeed
                    else
                        stressSpeed = seatbeltOn and config.MinimumSpeed or config.MinimumSpeedUnbuckled
                    end
                    if speed >= stressSpeed then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            end
        end
        Wait(10000)
    end
end)

local function IsWhitelistedWeaponStress(weapon)
    if weapon then
        for _, v in pairs(config.WhitelistedWeaponStress) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

CreateThread(function() -- Shooting
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                if IsPedShooting(ped) and not IsWhitelistedWeaponStress(weapon) then
                    if math.random() < config.StressChance then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            else
                Wait(1000)
            end
        end
        Wait(8)
    end
end)

-- Stress Screen Effects

local function GetBlurIntensity(stresslevel)
    for _, v in pairs(config.Intensity['blur']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for _, v in pairs(config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local effectInterval = GetEffectInterval(stress)
        if stress >= 100 then
            local BlurIntensity = GetBlurIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = FallRepeat * 1750
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)

            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(1000)
            for _ = 1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
        elseif stress >= config.MinimumStress then
            local BlurIntensity = GetBlurIntensity(stress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end
        Wait(effectInterval)
    end
end)

-- Minimap update
CreateThread(function()
    while true do
        SetRadarBigmapEnabled(false, false)
        SetRadarZoom(1000)
        Wait(500)
    end
end)

local function BlackBars()
    DrawRect(0.0, 0.0, 2.0, w, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, w, 0, 0, 0, 255)
end

CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do
            Wait(1)
        end
    end
    while true do
        if w > 0 then
            BlackBars()
            DisplayRadar(0)
            SendNUIMessage({
                action = 'hudtick',
                show = false,
            })
            SendNUIMessage({
                action = 'car',
                show = false,
            })
        end
        Wait(0)
    end
end)

-- Compass
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num + 0.5 * mult)
end

local prevBaseplateStats = { nil, nil, nil, nil, nil, nil, nil}

local function updateBaseplateHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevBaseplateStats[k] ~= v then shouldUpdate = true break end
    end
    prevBaseplateStats = data
    if shouldUpdate then
        SendNUIMessage ({
            action = 'baseplate',
            show = data[1],
            street1 = data[2],
            street2 = data[3],
            showCompass = data[4],
            showStreets = data[5],
            showPointer = data[6],
            showDegrees = data[7],
        })
    end
end

local lastCrossroadUpdate = 0
local lastCrossroadCheck = {}

local function getCrossroads(player)
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 1500 then
        local pos = GetEntityCoords(player)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        lastCrossroadCheck = { GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2) }
    end
    return lastCrossroadCheck
end

-- Compass Update loop

CreateThread(function()
	local lastHeading = 1
    local heading
	while true do
        if Menu.isChangeCompassFPSChecked then
            Wait(50)
        else
            Wait(0)
        end
        local show = true
        local player = PlayerPedId()
        local camRot = GetGameplayCamRot(0)
        if Menu.isCompassFollowChecked then
            heading = tostring(round(360.0 - ((camRot.z + 360.0) % 360.0)))
        else
            heading = tostring(round(360.0 - GetEntityHeading(player)))
        end
		if heading == '360' then heading = '0' end
            if heading ~= lastHeading then
			    if IsPedInAnyVehicle(player) then
                    local crossroads = getCrossroads(player)
                    SendNUIMessage ({
                        action = 'update',
                        value = heading
                    })
                    updateBaseplateHud({
                        show,
                        crossroads[1],
                        crossroads[2],
                        Menu.isCompassShowChecked,
                        Menu.isShowStreetsChecked,
                        Menu.isPointerShowChecked,
                        Menu.isDegreesShowChecked,
                    })
			    else
                    if Menu.isOutCompassChecked then
                        SendNUIMessage ({
                            action = 'update',
                            value = heading
                        })
                        SendNUIMessage ({
                            action = 'baseplate',
                            show = true,
                            showCompass = true,
                        })
                    else
                        SendNUIMessage ({
                            action = 'baseplate',
                            show = false,
                        })
                    end
			    end
	        end
		    lastHeading = heading
	    end
end)
