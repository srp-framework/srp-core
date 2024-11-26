Config = {}

-- Permissions Configuration
Config.Permissions = {
    Groups = {
        ['admin'] = {
            label = 'Administrator',
            inherits = 'moderator',
            permissions = {
                'admin.teleport',
                'admin.noclip',
                'admin.heal',
                'admin.revive',
                'admin.kick',
                'admin.ban',
                'admin.bring',
                'admin.goto'
            }
        },
        ['moderator'] = {
            label = 'Moderator',
            inherits = 'user',
            permissions = {
                'mod.teleport',
                'mod.noclip',
                'mod.heal',
                'mod.revive'
            }
        },
        ['user'] = {
            label = 'User',
            permissions = {}
        }
    },
    
    -- Default group for new players
    DefaultGroup = 'user'
}

-- Debug Mode
Config.Debug = false

-- Other core-specific configurations can go here
Config.SaveInterval = 5 * 60 * 1000 -- Save player data every 5 minutes