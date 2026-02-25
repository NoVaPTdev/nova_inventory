local isOpen = false
local groundItems = {}

exports('OpenInventory', function()
    if isOpen then return end
    isOpen = true
    TriggerServerEvent('nova_inventory:requestOpen')
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    -- Esconder HUD
    pcall(function() TriggerEvent('nova_hud:toggle', false) end)
end)

exports('CloseInventory', function()
    CloseInv()
end)

exports('IsOpen', function()
    return isOpen
end)

function CloseInv()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    pcall(function() TriggerEvent('nova_hud:toggle', true) end)
end

-- Abrir com Tab (control 37 está disabled pelo core, usar IsDisabledControlJustReleased)
CreateThread(function()
    while true do
        if IsDisabledControlJustReleased(0, 37) then -- Tab
            local loaded = false
            pcall(function()
                loaded = exports['nova_core']:IsPlayerLoaded()
            end)
            if loaded then
                if isOpen then
                    CloseInv()
                else
                    exports['nova_inventory']:OpenInventory()
                end
            end
        end
        Wait(0)
    end
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseInv()
    cb({ ok = true })
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('nova_inventory:moveItem', data.fromSlot, data.toSlot)
    cb({ ok = true })
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('nova_inventory:useItem', data.slot)
    cb({ ok = true })
end)

RegisterNUICallback('dropItem', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('nova_inventory:dropItem', data.slot, data.amount or 1, {
        x = coords.x, y = coords.y, z = coords.z
    })
    cb({ ok = true })
end)

RegisterNUICallback('pickupItem', function(data, cb)
    TriggerServerEvent('nova_inventory:pickupItem', data.id)
    cb({ ok = true })
end)

-- Atualizar inventário do servidor
RegisterNetEvent('nova_inventory:update')
AddEventHandler('nova_inventory:update', function(data)
    SendNUIMessage({
        action = 'updateInventory',
        slots = data.slots,
        maxWeight = data.maxWeight,
        currentWeight = data.currentWeight,
    })
end)

-- Ground items
RegisterNetEvent('nova_inventory:groundUpdate')
AddEventHandler('nova_inventory:groundUpdate', function(items)
    groundItems = items or {}
end)

RegisterNetEvent('nova_inventory:itemUsed')
AddEventHandler('nova_inventory:itemUsed', function(itemName, itemData)
    TriggerEvent('nova_inventory:client:itemUsed', itemName, itemData)
    -- Fechar inventário se shouldClose
    local ok, items = pcall(function() return exports['nova_core']:GetItems() end)
    if ok and items and items[itemName] and items[itemName].shouldClose then
        CloseInv()
    end
end)

-- Hotbar use (1-5)
CreateThread(function()
    local hotbarKeys = { 157, 158, 160, 164, 165 } -- 1,2,3,4,5
    while true do
        if not isOpen then
            for i = 1, 5 do
                if IsControlJustReleased(0, hotbarKeys[i]) then
                    TriggerServerEvent('nova_inventory:useItem', i)
                end
            end
        end
        Wait(0)
    end
end)

-- Pickup prompt para ground items
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        for id, item in pairs(groundItems) do
            if item and item.coords then
                local dist = #(pCoords - vector3(item.coords.x, item.coords.y, item.coords.z))
                if dist < InvConfig.PickupDistance + 2 then
                    sleep = 0
                    if dist < InvConfig.PickupDistance then
                        DrawText3D(item.coords.x, item.coords.y, item.coords.z + 0.3,
                            '[E] ' .. (item.label or item.name) .. ' x' .. item.amount)
                        if IsControlJustReleased(0, 38) then -- E
                            TriggerServerEvent('nova_inventory:pickupItem', id)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.3, 0.3)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
