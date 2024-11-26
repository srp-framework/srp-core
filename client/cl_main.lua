local PlayerData = {}
local isSpawned = false
local firstSpawn = true
local isLoaded = false

-- Add this at the top of the file
CreateThread(function()
    print('^2SRP-Core: Client-side initialized successfully^7')
end)

-- Update the playerSpawned event handler
RegisterNetEvent('srp-core:playerSpawned')
AddEventHandler('srp-core:playerSpawned', function()
    if not isSpawned then
        isSpawned = true
        TriggerServerEvent('srp-core:playerSpawned')
    end
end)

-- Player data loaded from server
RegisterNetEvent('srp-core:playerLoaded')
AddEventHandler('srp-core:playerLoaded', function(data)
    PlayerData = data
    
    -- Display initial money values
    TriggerEvent('srp-core:updateMoney', PlayerData.cash, PlayerData.bank)
end)

-- Money updates
RegisterNetEvent('srp-core:updateMoney')
AddEventHandler('srp-core:updateMoney', function(cash, bank)
    PlayerData.cash = cash
    PlayerData.bank = bank
    
    -- You can add UI updates here
    lib.notify({
        title = 'Balance Update',
        description = string.format('Cash: $%d | Bank: $%d', cash, bank),
        type = 'inform'
    })
end)

-- Export player data for other resources
exports('GetPlayerData', function()
    return PlayerData
end)

-- Add this event handler:
RegisterNetEvent('srp-core:characterCreated')
AddEventHandler('srp-core:characterCreated', function()
    -- Trigger player spawn after character creation
    TriggerServerEvent('srp-core:playerSpawned')
end)

-- Add this near the top of the file after local variables
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    print('^2SRP-Core: Client-side initialized successfully^7')
    
    -- Small delay to ensure everything is loaded
    Wait(1000)
    
    -- If player is already spawned when resource starts
    if NetworkIsPlayerActive(PlayerId()) then
        -- Reset player state
        local ped = PlayerPedId()
        SetEntityVisible(ped, false, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        DisplayRadar(false)
        DisplayHud(false)
        
        -- Request character list
        TriggerServerEvent('srp-core:requestCharacters')
    end
end)

-- Add this event to handle resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    -- Cleanup when resource stops
    if DoesCamExist(previewCam) then
        DestroyCam(previewCam, true)
        RenderScriptCams(false, false, 0, true, true)
    end
    
    -- Reset player state
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    
    -- Restore UI elements
    DisplayHud(true)
    DisplayRadar(true)
end)

-- Initial spawn handler
AddEventHandler('playerSpawned', function()
    print('^3[DEBUG] playerSpawned event triggered^7')
    if firstSpawn then
        firstSpawn = false
        isLoaded = false
        
        -- Hide player and UI
        local ped = PlayerPedId()
        SetEntityVisible(ped, false, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        DisplayRadar(false)
        DisplayHud(false)
        
        -- Small delay to ensure everything is loaded
        Wait(1000)
        
        print('^3[DEBUG] Requesting characters from server^7')
        TriggerServerEvent('srp-core:playerFirstSpawn')
    end
end)

-- Add this new event handler
RegisterNetEvent('srp-core:initializeCharacterSelection')
AddEventHandler('srp-core:initializeCharacterSelection', function()
    -- Trigger player spawn after character creation
    TriggerServerEvent('srp-core:playerSpawned')
end)

-- Teleport to coordinates
RegisterNetEvent('srp-core:teleportToCoords')
AddEventHandler('srp-core:teleportToCoords', function(x, y, z)
    print('^3[DEBUG] Received teleport coordinates:', x, y, z)
    
    local ped = PlayerPedId()
    local entity = ped
    
    -- If player is in a vehicle
    if IsPedInAnyVehicle(ped, false) then
        entity = GetVehiclePedIsIn(ped, false)
    end
    
    -- Start fade out
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    
    -- Teleport
    SetEntityCoords(entity, x + 0.0, y + 0.0, z + 0.0, false, false, false, false)
    
    -- Wait for collision to load
    while not HasCollisionLoadedAroundEntity(entity) do
        Wait(0)
    end
    
    -- Fade back in
    DoScreenFadeIn(500)
    
    print('^3[DEBUG] Teleport completed')
    lib.notify({
        title = 'Teleported',
        description = string.format('Teleported to %0.2f, %0.2f, %0.2f', x, y, z),
        type = 'success'
    })
end)

-- Teleport to waypoint
RegisterNetEvent('srp-core:teleportToWaypoint')
AddEventHandler('srp-core:teleportToWaypoint', function()
    print('^3[DEBUG] Waypoint teleport triggered')
    
    local waypoint = GetFirstBlipInfoId(8) -- 8 is the waypoint blip ID
    
    if not DoesBlipExist(waypoint) then
        lib.notify({
            title = 'Error',
            description = 'No waypoint set on the map',
            type = 'error'
        })
        return
    end
    
    local coords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()
    local entity = ped
    
    -- If player is in a vehicle
    if IsPedInAnyVehicle(ped, false) then
        entity = GetVehiclePedIsIn(ped, false)
    end
    
    -- Start fade out
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    
    -- Find ground z coordinate
    local found, groundZ = false, 0.0
    for height = 1000.0, -500.0, -25.0 do
        local testCoords = vector3(coords.x, coords.y, height)
        found, groundZ = GetGroundZFor_3dCoord(testCoords.x, testCoords.y, testCoords.z, true)
        
        if found then 
            print('^3[DEBUG] Found ground at height:', groundZ)
            break 
        end
        Wait(0)
    end
    
    if not found then
        groundZ = coords.z
    end
    
    -- Teleport
    SetEntityCoords(entity, coords.x, coords.y, groundZ + 0.0, false, false, false, false)
    
    -- Wait for collision to load
    while not HasCollisionLoadedAroundEntity(entity) do
        Wait(0)
    end
    
    -- Fade back in
    DoScreenFadeIn(500)
    
    print('^3[DEBUG] Waypoint teleport completed')
    lib.notify({
        title = 'Teleported',
        description = 'Teleported to waypoint',
        type = 'success'
    })
end)

-- On player spawn, request character list
AddEventHandler('playerSpawned', function()
    -- Only trigger this the first time the player spawns
    if not LocalPlayer.state.initialSpawn then
        LocalPlayer.state.initialSpawn = true
        TriggerServerEvent('srp-characters:requestCharacters')
    end
end)
