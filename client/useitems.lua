-- ============================================================
-- NOVA Inventory - Item Use Effects
-- Lida com os efeitos de usar cada tipo de item
-- ============================================================

local ItemEffects = {}

-- ============================================================
-- HELPER: Chamar progress bar do HUD
-- ============================================================

local function ProgressBar(label, duration, opts)
    local ok, result = pcall(function()
        return exports['nova_hud']:ProgressBar(label, duration, opts)
    end)
    if not ok then
        Wait(duration)
        return true
    end
    return result
end

local function Notify(msg, type, dur)
    pcall(function()
        exports['nova_notify']:SendNotification(msg, type or 'info', dur or 3000)
    end)
end

-- ============================================================
-- COMIDA
-- ============================================================

ItemEffects['bread'] = function(itemData)
    local success = ProgressBar(InvL('eating_bread'), 4000, {
        animation = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
        canCancel = true,
    })
    if success then
        TriggerServerEvent('nova_inventory:applyEffect', 'hunger', 20)
        Notify(InvL('ate_bread'), 'success')
    end
end

ItemEffects['sandwich'] = function(itemData)
    local success = ProgressBar(InvL('eating_sandwich'), 5000, {
        animation = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
        canCancel = true,
    })
    if success then
        TriggerServerEvent('nova_inventory:applyEffect', 'hunger', 35)
        Notify(InvL('ate_sandwich'), 'success')
    end
end

ItemEffects['burger'] = function(itemData)
    local success = ProgressBar(InvL('eating_burger'), 5000, {
        animation = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
        canCancel = true,
    })
    if success then
        TriggerServerEvent('nova_inventory:applyEffect', 'hunger', 40)
        Notify(InvL('ate_burger'), 'success')
    end
end

-- ============================================================
-- BEBIDAS
-- ============================================================

ItemEffects['water'] = function(itemData)
    local success = ProgressBar(InvL('drinking_water'), 3000, {
        animation = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
        canCancel = true,
    })
    if success then
        TriggerServerEvent('nova_inventory:applyEffect', 'thirst', 30)
        Notify(InvL('drank_water'), 'success')
    end
end

ItemEffects['coffee'] = function(itemData)
    local success = ProgressBar(InvL('drinking_coffee'), 3500, {
        animation = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
        canCancel = true,
    })
    if success then
        TriggerServerEvent('nova_inventory:applyEffect', 'thirst', 20)
        TriggerServerEvent('nova_inventory:applyEffect', 'hunger', 10)
        Notify(InvL('drank_coffee'), 'success')
    end
end

ItemEffects['energy_drink'] = function(itemData)
    local success = ProgressBar(InvL('drinking_energy'), 3000, {
        animation = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
        canCancel = true,
    })
    if success then
        TriggerServerEvent('nova_inventory:applyEffect', 'thirst', 35)
        Notify(InvL('drank_energy'), 'success')
    end
end

-- ============================================================
-- MÉDICOS
-- ============================================================

ItemEffects['medikit'] = function(itemData)
    local success = ProgressBar(InvL('using_medikit'), 8000, {
        animation = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest', flag = 49 },
        canCancel = true,
    })
    if success then
        local ped = PlayerPedId()
        local maxHealth = GetEntityMaxHealth(ped)
        SetEntityHealth(ped, maxHealth)
        Notify(InvL('used_medikit'), 'success')
    end
end

ItemEffects['bandage'] = function(itemData)
    local success = ProgressBar(InvL('using_bandage'), 4000, {
        animation = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest', flag = 49 },
        canCancel = true,
    })
    if success then
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local maxHealth = GetEntityMaxHealth(ped)
        local newHealth = math.min(health + 50, maxHealth)
        SetEntityHealth(ped, newHealth)
        Notify(InvL('used_bandage'), 'success')
    end
end

-- ============================================================
-- PROTEÇÃO
-- ============================================================

ItemEffects['armor'] = function(itemData)
    local success = ProgressBar(InvL('using_armor'), 5000, {
        animation = { dict = 'clothingtie', clip = 'try_tie_negative_a', flag = 49 },
        canCancel = true,
    })
    if success then
        local ped = PlayerPedId()
        SetPedArmour(ped, 100)
        Notify(InvL('used_armor'), 'success')
    end
end

-- ============================================================
-- ARMAS
-- ============================================================

local weaponHashes = {
    ['weapon_pistol'] = 'WEAPON_PISTOL',
    ['weapon_combatpistol'] = 'WEAPON_COMBATPISTOL',
    ['weapon_heavypistol'] = 'WEAPON_HEAVYPISTOL',
    ['weapon_snspistol'] = 'WEAPON_SNSPISTOL',
    ['weapon_microsmg'] = 'WEAPON_MICROSMG',
    ['weapon_smg'] = 'WEAPON_SMG',
    ['weapon_pumpshotgun'] = 'WEAPON_PUMPSHOTGUN',
    ['weapon_sawnoffshotgun'] = 'WEAPON_SAWNOFFSHOTGUN',
    ['weapon_carbinerifle'] = 'WEAPON_CARBINERIFLE',
    ['weapon_assaultrifle'] = 'WEAPON_ASSAULTRIFLE',
    ['weapon_bat'] = 'WEAPON_BAT',
    ['weapon_knife'] = 'WEAPON_KNIFE',
    ['weapon_flashlight'] = 'WEAPON_FLASHLIGHT',
}

for itemName, weaponHash in pairs(weaponHashes) do
    ItemEffects[itemName] = function(itemData)
        local ped = PlayerPedId()
        local hash = GetHashKey(weaponHash)
        if HasPedGotWeapon(ped, hash, false) then
            RemoveWeaponFromPed(ped, hash)
            Notify(InvL('weapon_stored'), 'info')
        else
            GiveWeaponToPed(ped, hash, 0, false, true)
            Notify(InvL('weapon_equipped', itemData.label or itemName), 'success')
        end
    end
end

-- ============================================================
-- MUNIÇÕES
-- ============================================================

local ammoWeapons = {
    ['ammo_pistol'] = { weapons = {'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_HEAVYPISTOL', 'WEAPON_SNSPISTOL'}, amount = 24 },
    ['ammo_smg'] = { weapons = {'WEAPON_MICROSMG', 'WEAPON_SMG'}, amount = 30 },
    ['ammo_shotgun'] = { weapons = {'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN'}, amount = 12 },
    ['ammo_rifle'] = { weapons = {'WEAPON_CARBINERIFLE', 'WEAPON_ASSAULTRIFLE'}, amount = 30 },
}

for itemName, ammoData in pairs(ammoWeapons) do
    ItemEffects[itemName] = function(itemData)
        local success = ProgressBar(InvL('loading_ammo'), 3000, {
            animation = { dict = 'weapons@pistol@', clip = 'reload_aim', flag = 49 },
            canCancel = true,
        })
        if success then
            local ped = PlayerPedId()
            local loaded = false
            for _, wHash in ipairs(ammoData.weapons) do
                local hash = GetHashKey(wHash)
                if HasPedGotWeapon(ped, hash, false) then
                    local current = GetAmmoInPedWeapon(ped, hash)
                    SetPedAmmo(ped, hash, current + ammoData.amount)
                    loaded = true
                end
            end
            if loaded then
                Notify(InvL('ammo_loaded', ammoData.amount), 'success')
            else
                Notify(InvL('no_compatible_weapon'), 'error')
                TriggerServerEvent('nova_inventory:refundItem', itemName)
            end
        else
            TriggerServerEvent('nova_inventory:refundItem', itemName)
        end
    end
end

-- ============================================================
-- VEÍCULOS
-- ============================================================

ItemEffects['repairkit'] = function(itemData)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = FindNearbyVehicle(GetEntityCoords(ped), 5.0)
    end

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        Notify(InvL('no_vehicle_nearby'), 'error')
        TriggerServerEvent('nova_inventory:refundItem', 'repairkit')
        return
    end

    local success = ProgressBar(InvL('repairing_vehicle'), 10000, {
        animation = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 1 },
        canCancel = true,
    })
    if success then
        SetVehicleFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        Notify(InvL('vehicle_repaired'), 'success')
    else
        TriggerServerEvent('nova_inventory:refundItem', 'repairkit')
    end
end

ItemEffects['jerrycan'] = function(itemData)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = FindNearbyVehicle(GetEntityCoords(ped), 5.0)
    end

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        Notify(InvL('no_vehicle_nearby'), 'error')
        TriggerServerEvent('nova_inventory:refundItem', 'jerrycan')
        return
    end

    local success = ProgressBar(InvL('refueling_vehicle'), 6000, {
        canCancel = true,
    })
    if success then
        SetVehicleFuelLevel(vehicle, GetVehicleFuelLevel(vehicle) + 40.0)
        Notify(InvL('vehicle_refueled'), 'success')
    else
        TriggerServerEvent('nova_inventory:refundItem', 'jerrycan')
    end
end

-- ============================================================
-- DOCUMENTOS (mostrar ao invés de consumir)
-- ============================================================

ItemEffects['id_card'] = function(itemData)
    Notify(InvL('showed_id'), 'info')
end

ItemEffects['driver_license'] = function(itemData)
    Notify(InvL('showed_license'), 'info')
end

ItemEffects['weapon_license'] = function(itemData)
    Notify(InvL('showed_weapon_license'), 'info')
end

-- ============================================================
-- LISTENER PRINCIPAL
-- ============================================================

RegisterNetEvent('nova_inventory:itemUsed')
AddEventHandler('nova_inventory:itemUsed', function(itemName, itemData)
    if ItemEffects[itemName] then
        CreateThread(function()
            ItemEffects[itemName](itemData)
        end)
    end
end)

-- Helper para encontrar veículo mais próximo
function FindNearbyVehicle(coords, maxDist)
    local vehicles = GetGamePool('CVehicle')
    local closest = 0
    local closestDist = maxDist + 1

    for _, veh in ipairs(vehicles) do
        local vCoords = GetEntityCoords(veh)
        local dist = #(coords - vCoords)
        if dist < closestDist then
            closest = veh
            closestDist = dist
        end
    end

    return closestDist <= maxDist and closest or 0
end
