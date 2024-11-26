local isDead = false
local deathCoords = nil
local deathTime = 60 -- Time in seconds before respawn is available
local deathTimer = 0

-- Function to format time remaining
local function FormatTimeRemaining(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

-- Function to draw death screen text
local function DrawDeathText()
    -- Set text properties
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    
    -- Draw text based on timer state
    if deathTimer > 0 then
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName('You are dead\nRespawn available in: ' .. FormatTimeRemaining(deathTimer))
        EndTextCommandDisplayText(0.5, 0.4)
    else
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName('Press ~r~[E]~w~ to respawn')
        EndTextCommandDisplayText(0.5, 0.4)
    end
end

-- Function to handle player death
local function HandleDeath()
    local ped = PlayerPedId()
    isDead = true
    deathCoords = GetEntityCoords(ped)
    deathTimer = deathTime
    
    -- Death timer and draw text thread
    CreateThread(function()
        while isDead do
            -- Draw death text
            DrawDeathText()
            
            -- Update timer
            if deathTimer > 0 then
                Wait(1000)
                deathTimer = deathTimer - 1
            else
                -- Check for respawn input after timer is complete
                if IsControlJustPressed(0, 38) then -- E key
                    ShowRespawnMenu()
                end
                Wait(0)
            end
        end
    end)
    
    -- Disable controls while dead
    CreateThread(function()
        while isDead do
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 31, true) -- S
            DisableControlAction(0, 30, true) -- D
            DisableControlAction(0, 45, true) -- Reload
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 37, true) -- Select Weapon
            DisableControlAction(0, 23, true) -- Also 'enter'
            DisableControlAction(0, 288, true) -- Disable phone
            DisableControlAction(0, 289, true) -- Inventory
            DisableControlAction(0, 170, true) -- Animations
            DisableControlAction(0, 167, true) -- Job
            DisableControlAction(0, 0, true) -- Disable changing view
            DisableControlAction(0, 26, true) -- Disable looking behind
            DisableControlAction(0, 73, true) -- Disable clearing animation
            DisableControlAction(2, 199, true) -- Disable pause menu
            DisableControlAction(0, 59, true) -- Disable steering in vehicle
            DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
            DisableControlAction(0, 72, true) -- Disable reversing in vehicle
            Wait(0)
        end
    end)
end

-- Function to show respawn menu
local function ShowRespawnMenu()
    if not isDead or deathTimer > 0 then return end
    
    -- Hide any existing menus
    lib.hideContext()
    
    -- Start fade out
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    
    -- Reset ped state
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(deathCoords.x, deathCoords.y, deathCoords.z, 0.0, true, false)
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
    
    -- Trigger spawn selector
    TriggerEvent('srp-spawn:showSpawnSelector')
    
    -- Reset death state
    isDead = false
    deathCoords = nil
    deathTimer = 0
end

-- Death check thread
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        
        if IsEntityDead(ped) and not isDead then
            HandleDeath()
            TriggerEvent('srp-core:onPlayerDeath')
        end
        
        Wait(500)
    end
end)

-- Export functions
exports('IsPlayerDead', function()
    return isDead
end)

exports('GetDeathCoords', function()
    return deathCoords
end)

exports('GetDeathTimer', function()
    return deathTimer
end)

exports('RespawnPlayer', function()
    if isDead and deathTimer <= 0 then
        ShowRespawnMenu()
        return true
    end
    return false
end)

-- Event handlers
RegisterNetEvent('srp-core:revivePlayer')
AddEventHandler('srp-core:revivePlayer', function()
    if isDead then
        -- Reset death state
        isDead = false
        deathCoords = nil
        deathTimer = 0
        
        -- Revive player
        local ped = PlayerPedId()
        NetworkResurrectLocalPlayer(deathCoords.x, deathCoords.y, deathCoords.z, 0.0, true, false)
        SetEntityHealth(ped, 200)
        ClearPedBloodDamage(ped)
    end
end)

-- Add command for testing/admin use
RegisterCommand('revive', function()
    TriggerEvent('srp-core:revivePlayer')
end) 