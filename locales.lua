-- NOVA Inventory - Locales (PT/EN)
local _lang = nil

local Strings = {
    pt = {
        -- Uso de itens
        eating_bread = 'A comer pão...',
        ate_bread = 'Comeste um pão. (+20 Fome)',
        eating_sandwich = 'A comer sandes...',
        ate_sandwich = 'Comeste uma sandes. (+35 Fome)',
        eating_burger = 'A comer hambúrguer...',
        ate_burger = 'Comeste um hambúrguer. (+40 Fome)',
        drinking_water = 'A beber água...',
        drank_water = 'Bebeste água. (+30 Sede)',
        drinking_coffee = 'A beber café...',
        drank_coffee = 'Bebeste um café. (+20 Sede, +10 Fome)',
        drinking_energy = 'A beber energética...',
        drank_energy = 'Bebeste uma energética. (+35 Sede)',
        using_medikit = 'A usar kit médico...',
        used_medikit = 'Usaste um kit médico. (Vida restaurada)',
        using_bandage = 'A aplicar ligadura...',
        used_bandage = 'Aplicaste uma ligadura. (+50 Vida)',
        using_armor = 'A vestir colete...',
        used_armor = 'Vestiste um colete. (Armadura 100%%)',
        loading_ammo = 'A carregar munição...',
        ammo_loaded = 'Munição carregada. (+%s)',
        no_compatible_weapon = 'Não tens uma arma compatível equipada.',
        repairing_vehicle = 'A reparar veículo...',
        vehicle_repaired = 'Veículo reparado!',
        no_vehicle_nearby = 'Não há veículo por perto.',
        refueling_vehicle = 'A abastecer veículo...',
        vehicle_refueled = 'Veículo abastecido! (+40%% Combustível)',
        weapon_stored = 'Guardaste a arma.',
        weapon_equipped = 'Equipaste: %s',
        showed_id = 'Mostraste o teu Cartão de Cidadão.',
        showed_license = 'Mostraste a tua Carta de Condução.',
        showed_weapon_license = 'Mostraste a tua Licença de Arma.',
        item_not_useable = 'Este item não pode ser usado.',
        -- NUI strings
        nui_inventory = 'Inventário',
        nui_weight = 'Peso',
        nui_use = 'Usar',
        nui_drop = 'Largar',
    },
    en = {
        eating_bread = 'Eating bread...',
        ate_bread = 'You ate some bread. (+20 Hunger)',
        eating_sandwich = 'Eating sandwich...',
        ate_sandwich = 'You ate a sandwich. (+35 Hunger)',
        eating_burger = 'Eating burger...',
        ate_burger = 'You ate a burger. (+40 Hunger)',
        drinking_water = 'Drinking water...',
        drank_water = 'You drank water. (+30 Thirst)',
        drinking_coffee = 'Drinking coffee...',
        drank_coffee = 'You drank coffee. (+20 Thirst, +10 Hunger)',
        drinking_energy = 'Drinking energy drink...',
        drank_energy = 'You drank an energy drink. (+35 Thirst)',
        using_medikit = 'Using medikit...',
        used_medikit = 'You used a medikit. (Health restored)',
        using_bandage = 'Applying bandage...',
        used_bandage = 'You applied a bandage. (+50 Health)',
        using_armor = 'Putting on armor...',
        used_armor = 'You put on armor. (Armor 100%%)',
        loading_ammo = 'Loading ammo...',
        ammo_loaded = 'Ammo loaded. (+%s)',
        no_compatible_weapon = 'You don\'t have a compatible weapon equipped.',
        repairing_vehicle = 'Repairing vehicle...',
        vehicle_repaired = 'Vehicle repaired!',
        no_vehicle_nearby = 'No vehicle nearby.',
        refueling_vehicle = 'Refueling vehicle...',
        vehicle_refueled = 'Vehicle refueled! (+40%% Fuel)',
        weapon_stored = 'Weapon stored.',
        weapon_equipped = 'Equipped: %s',
        showed_id = 'You showed your ID Card.',
        showed_license = 'You showed your Driver\'s License.',
        showed_weapon_license = 'You showed your Weapon License.',
        item_not_useable = 'This item cannot be used.',
        nui_inventory = 'Inventory',
        nui_weight = 'Weight',
        nui_use = 'Use',
        nui_drop = 'Drop',
    },
}

local function GetLang()
    if _lang then return _lang end
    _lang = 'pt'
    pcall(function()
        local cfg = exports['nova_core']:GetConfig()
        if cfg and cfg.Locale then _lang = cfg.Locale end
    end)
    return _lang
end

function InvL(key, ...)
    local lang = GetLang()
    local str = (Strings[lang] and Strings[lang][key]) or Strings['pt'][key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

function InvGetAllStrings()
    local lang = GetLang()
    return Strings[lang] or Strings['pt']
end
