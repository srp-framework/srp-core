local Permissions = {}

-- Helper function to check if string ends with pattern
local function endsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

-- Helper function to check if string starts with pattern
local function startsWith(str, start)
    return str:sub(1, #start) == start
end

-- Load player permissions
local function LoadPlayerPermissions(license)
    -- First check if user is in any group's users list
    for groupName, groupData in pairs(Config.Permissions.Groups) do
        if groupData.users then
            for _, identifier in ipairs(groupData.users) do
                if identifier == license then
                    -- User is in config, ensure they're in database with correct group
                    local result = MySQL.single.await('SELECT `group` FROM permissions WHERE license = ?', {license})
                    if result then
                        -- Update existing database entry if group doesn't match
                        if result.group ~= groupName then
                            MySQL.update('UPDATE permissions SET `group` = ? WHERE license = ?', {
                                groupName,
                                license
                            })
                        end
                    else
                        -- Create new database entry for config user
                        MySQL.insert('INSERT INTO permissions (license, `group`, permissions) VALUES (?, ?, ?)', {
                            license,
                            groupName,
                            '[]'
                        })
                    end
                    
                    return {
                        group = groupName,
                        permissions = {}
                    }
                end
            end
        end
    end

    -- Check database for existing permissions
    local result = MySQL.single.await('SELECT `group`, permissions FROM permissions WHERE license = ?', {license})
    if result then
        return {
            group = result.group,
            permissions = json.decode(result.permissions)
        }
    end
    
    -- Create default user permissions if none exist
    MySQL.insert('INSERT INTO permissions (license, `group`, permissions) VALUES (?, ?, ?)', {
        license,
        'user',
        '[]'
    })
    
    return {
        group = 'user',
        permissions = {}
    }
end

-- Check if player has permission
local function HasPermission(license, permission)
    if not Permissions[license] then
        Permissions[license] = LoadPlayerPermissions(license)
    end
    
    local playerGroup = Permissions[license].group
    local currentGroup = Config.Permissions.Groups[playerGroup]
    
    -- Check direct permissions
    if Permissions[license].permissions then
        for _, perm in ipairs(Permissions[license].permissions) do
            if perm == permission or perm == '*' then
                return true
            end
        end
    end
    
    -- Check group permissions
    while currentGroup do
        for _, perm in ipairs(currentGroup.permissions) do
            if perm == permission or perm == '*' or 
               (endsWith(perm, '.*') and startsWith(permission, perm:sub(1, -3))) then
                return true
            end
        end
        
        -- Check inherited permissions
        if currentGroup.inherits then
            currentGroup = Config.Permissions.Groups[currentGroup.inherits]
        else
            break
        end
    end
    
    return false
end

-- Set player group
local function SetPlayerGroup(license, group)
    if not Config.Permissions.Groups[group] then return false end
    
    MySQL.update('UPDATE permissions SET `group` = ? WHERE license = ?', {
        group,
        license
    })
    
    if not Permissions[license] then
        Permissions[license] = LoadPlayerPermissions(license)
    end
    Permissions[license].group = group
    
    return true
end

-- Add permission to player
local function AddPlayerPermission(license, permission)
    if not Permissions[license] then
        Permissions[license] = LoadPlayerPermissions(license)
    end
    
    local perms = Permissions[license].permissions
    table.insert(perms, permission)
    
    MySQL.update('UPDATE permissions SET permissions = ? WHERE license = ?', {
        json.encode(perms),
        license
    })
    
    return true
end

-- Export functions
exports('HasPermission', HasPermission)
exports('SetPlayerGroup', SetPlayerGroup)
exports('AddPlayerPermission', AddPlayerPermission)

-- Command to set player group
RegisterCommand('setgroup', function(source, args)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not HasPermission(license, 'admin.setgroup') then
        return lib.notify(source, {
            title = 'Error',
            description = 'You do not have permission to use this command',
            type = 'error'
        })
    end
    
    if #args < 2 then
        return lib.notify(source, {
            title = 'Error',
            description = 'Usage: /setgroup <id> <group>',
            type = 'error'
        })
    end
    
    local targetId = tonumber(args[1])
    local group = args[2]
    
    local targetLicense = GetPlayerIdentifierByType(targetId, 'license')
    if not targetLicense then return end
    
    if SetPlayerGroup(targetLicense, group) then
        lib.notify(source, {
            title = 'Success',
            description = 'Player group updated',
            type = 'success'
        })
    end
end)

-- Example command using permissions
RegisterCommand('kick', function(source, args)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not HasPermission(license, 'admin.kick') and not HasPermission(license, 'mod.kick') then
        return lib.notify(source, {
            title = 'Error',
            description = 'You do not have permission to use this command',
            type = 'error'
        })
    end
    
    -- Rest of kick command logic
end)

-- Add this near the top of the file
CreateThread(function()
    -- Initialize permissions for config users
    for groupName, groupData in pairs(Config.Permissions.Groups) do
        if groupData.users then
            for _, identifier in ipairs(groupData.users) do
                LoadPlayerPermissions(identifier)
            end
        end
    end
    print('^2SRP-Core: Permissions system initialized^7')
end)

-- Add debug print to check if HasPermission function exists
print('^3[DEBUG] HasPermission function exists:', HasPermission ~= nil)

-- Teleport to coordinates command
RegisterCommand('tp', function(source, args)
    -- Debug prints
    print('^3[DEBUG] /tp command triggered by:', GetPlayerName(source))
    print('^3[DEBUG] Arguments:', json.encode(args))
    
    -- Check if player has permission
    if not HasPermission(source, 'admin.teleport') then
        print('^3[DEBUG] Player lacks permission:', GetPlayerName(source))
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You do not have permission to use this command',
            type = 'error'
        })
        return
    end
    
    -- Check if coordinates were provided
    if #args < 3 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Usage: /tp [x] [y] [z]',
            type = 'error'
        })
        return
    end
    
    -- Convert args to numbers and validate
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])
    
    if not x or not y or not z then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Invalid coordinates provided',
            type = 'error'
        })
        return
    end
    
    print('^3[DEBUG] Teleporting player to:', x, y, z)
    TriggerClientEvent('srp-core:teleportToCoords', source, x, y, z)
end, false) -- Set this to false to allow from console

-- Teleport to waypoint command
RegisterCommand('tpm', function(source)
    -- Debug print
    print('^3[DEBUG] /tpm command triggered by:', GetPlayerName(source))
    
    -- Check if player has permission
    if not HasPermission(source, 'admin.teleport') then
        print('^3[DEBUG] Player lacks permission:', GetPlayerName(source))
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You do not have permission to use this command',
            type = 'error'
        })
        return
    end
    
    print('^3[DEBUG] Triggering waypoint teleport for:', GetPlayerName(source))
    TriggerClientEvent('srp-core:teleportToWaypoint', source)
end, false) -- Set this to false to allow from console 