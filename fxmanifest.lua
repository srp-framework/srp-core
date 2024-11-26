fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'srp-core'
description 'Core resource for SRP Framework'
author 'aaron-pw'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'srp-characters',
    'srp-spawn'
}

exports {
    'IsPlayerDead',
    'GetDeathCoords',
    'RespawnPlayer'
}
