fx_version 'cerulean'
game 'gta5'

name 'nova_inventory'
description 'NOVA Framework - Sistema de Inventário'
author 'NOVA Development'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'config.lua',
    'locales.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/useitems.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'nova_core',
}

exports {
    'AddItem',
    'RemoveItem',
    'HasItem',
    'GetItemCount',
    'GetPlayerInventory',
    'SetInventoryMaxWeight',
    'OpenInventory',
    'CloseInventory',
    'IsOpen',
}
