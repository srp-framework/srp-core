-- Initialize Players table
Players = {}

-- Resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Print ASCII art
    print([[^5
      ______     ______     ______   
     /\  ___\   /\  == \   /\  == \  
     \ \___  \  \ \  __<   \ \  _-/ 
      \/\_____\  \ \_\ \_\  \ \_\   
       \/_____/   \/_/ /_/   \/_/      
                          
    ^2Framework by aaronpw^7
    ]])
    
    -- Create permissions table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS permissions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            license VARCHAR(50) UNIQUE,
            `group` VARCHAR(50) DEFAULT 'user'
        )
    ]], {}, function(result)
        if result then
            print('^2SRP-Core: Server-side initialized successfully^7')
        else
            print('^1SRP-Core: Failed to initialize database^7')
        end
    end)
end)

-- Player connecting
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local license = GetPlayerIdentifierByType(source, 'license')
    
    -- Debug print
    print('[DEBUG] Player connecting:', name)
    
    if not license then
        setKickReason('Unable to find license identifier.')
        CancelEvent()
        return
    end
    
    -- Initialize player data with default group
    Players[source] = {
        name = name,
        license = license,
        group = Config.Permissions.DefaultGroup
    }
    
    -- Load player permissions
    MySQL.single('SELECT `group` FROM permissions WHERE license = ?', {license}, function(result)
        if result then
            Players[source].group = result.group
            print('^3[DEBUG] Loaded permissions for ' .. name .. ': ' .. result.group .. '^7')
        else
            -- Insert default group if no permissions exist
            MySQL.insert('INSERT INTO permissions (license, `group`) VALUES (?, ?)', {
                license,
                Config.Permissions.DefaultGroup
            })
            print('^3[DEBUG] Created default permissions for ' .. name .. '^7')
        end
    end)
end)

-- Player dropped
AddEventHandler('playerDropped', function(reason)
    local source = source
    if Players[source] then
        print('^3[DEBUG] Player dropped: ' .. Players[source].name .. ' (' .. reason .. ')^7')
        Players[source] = nil
    end
end)

-- Export the Players table
exports('GetPlayers', function()
    return Players
end)

-- Export to check if player has permission
exports('HasPermission', function(source, permission)
    if not Players[source] then return false end
    
    local group = Players[source].group
    if not Config.Permissions.Groups[group] then return false end
    
    -- Check if permission exists in group
    if Config.Permissions.Groups[group].permissions then
        for _, perm in ipairs(Config.Permissions.Groups[group].permissions) do
            if perm == permission then
                return true
            end
        end
    end
    
    -- Check inherited permissions
    local currentGroup = Config.Permissions.Groups[group]
    while currentGroup and currentGroup.inherits do
        currentGroup = Config.Permissions.Groups[currentGroup.inherits]
        if not currentGroup or not currentGroup.permissions then break end
        
        for _, perm in ipairs(currentGroup.permissions) do
            if perm == permission then
                return true
            end
        end
    end
    
    return false
end)
