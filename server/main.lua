local Nova = nil
local inventories = {} -- [source] = { slots = {}, maxWeight = N }
local groundItems = {} -- [id] = { items, coords, time }
local groundId = 0

CreateThread(function()
    while not exports['nova_core']:IsFrameworkReady() do Wait(100) end
    Nova = exports['nova_core']:GetObject()
end)

-- ============================================================
-- HELPERS
-- ============================================================

local function getItems()
    local ok, items = pcall(function() return exports['nova_core']:GetItems() end)
    return ok and items or {}
end

local function getItemData(name)
    local items = getItems()
    return items[name]
end

local function calcWeight(inv)
    local w = 0
    for _, slot in pairs(inv) do
        if slot and slot.name then
            local data = getItemData(slot.name)
            w = w + (data and data.weight or 0) * (slot.amount or 1)
        end
    end
    return w
end

local function serializeInventory(source)
    if not inventories[source] then return '[]' end
    return json.encode(inventories[source].slots)
end

-- ============================================================
-- CARREGAR / SALVAR
-- ============================================================

local function loadInventory(source)
    local player = exports['nova_core']:GetPlayer(source)
    if not player then return end

    local rawInv = player.inventory or {}
    local slots = {}

    if rawInv and type(rawInv) == 'table' then
        for i, item in pairs(rawInv) do
            local slotIdx = tonumber(i) or #slots + 1
            if item and item.name then
                slots[slotIdx] = {
                    name = item.name,
                    label = item.label or item.name,
                    amount = item.amount or item.count or 1,
                    weight = item.weight or 0,
                    metadata = item.metadata or {},
                    type = item.type or 'item',
                }
            end
        end
    end

    inventories[source] = {
        slots = slots,
        maxWeight = InvConfig.MaxWeight,
    }
end

local function saveInventory(source)
    if not inventories[source] then return end
    pcall(function()
        exports['nova_core']:SetPlayerInventory(source, inventories[source].slots)
    end)
end

-- ============================================================
-- EXPORTS (usados pelo core)
-- ============================================================

local function AddItem(source, itemName, amount, slot, metadata)
    if not inventories[source] then loadInventory(source) end
    if not inventories[source] then return false end

    local itemData = getItemData(itemName)
    if not itemData then return false end

    amount = amount or 1
    if amount <= 0 then return false end

    local inv = inventories[source]
    local addWeight = (itemData.weight or 0) * amount
    local currentWeight = calcWeight(inv.slots)

    if currentWeight + addWeight > inv.maxWeight then return false end

    -- Tentar stackar em slot existente
    if not (itemData.unique) then
        for i, s in pairs(inv.slots) do
            if s and s.name == itemName then
                inv.slots[i].amount = (s.amount or 0) + amount
                saveInventory(source)
                updateClient(source)
                return true
            end
        end
    end

    -- Encontrar slot vazio
    local targetSlot = slot
    if not targetSlot then
        for i = 1, InvConfig.MaxSlots do
            if not inv.slots[i] or not inv.slots[i].name then
                targetSlot = i
                break
            end
        end
    end

    if not targetSlot then return false end

    inv.slots[targetSlot] = {
        name = itemName,
        label = itemData.label or itemName,
        amount = amount,
        weight = itemData.weight or 0,
        metadata = metadata or {},
        type = itemData.type or 'item',
    }

    saveInventory(source)
    updateClient(source)
    return true
end

local function RemoveItem(source, itemName, amount)
    if not inventories[source] then loadInventory(source) end
    if not inventories[source] then return false end

    amount = amount or 1
    local inv = inventories[source]

    for i, s in pairs(inv.slots) do
        if s and s.name == itemName then
            if s.amount >= amount then
                inv.slots[i].amount = s.amount - amount
                if inv.slots[i].amount <= 0 then
                    inv.slots[i] = nil
                end
                saveInventory(source)
                updateClient(source)
                return true
            end
        end
    end
    return false
end

local function HasItem(source, itemName, amount)
    amount = amount or 1
    return GetItemCount(source, itemName) >= amount
end

function GetItemCount(source, itemName)
    if not inventories[source] then loadInventory(source) end
    if not inventories[source] then return 0 end

    local total = 0
    for _, s in pairs(inventories[source].slots) do
        if s and s.name == itemName then
            total = total + (s.amount or 0)
        end
    end
    return total
end

local function GetPlayerInventory(source)
    if not inventories[source] then loadInventory(source) end
    if not inventories[source] then return {} end
    return inventories[source].slots
end

local function SetInventoryMaxWeight(source, weight)
    if not inventories[source] then loadInventory(source) end
    if inventories[source] then
        inventories[source].maxWeight = weight
    end
end

-- Registar exports
exports('AddItem', AddItem)
exports('RemoveItem', RemoveItem)
exports('HasItem', HasItem)
exports('GetItemCount', GetItemCount)
exports('GetPlayerInventory', GetPlayerInventory)
exports('SetInventoryMaxWeight', SetInventoryMaxWeight)

-- ============================================================
-- SINCRONIZAÇÃO COM CLIENTE
-- ============================================================

-- Força chaves string para que SendNUIMessage serialize como JSON object (não array)
local function slotsToObject(t)
    local o = {}
    for k, v in pairs(t) do
        o[tostring(k)] = v
    end
    return o
end

function updateClient(source)
    if not inventories[source] then return end
    local allItems = getItems()
    TriggerClientEvent('nova_inventory:update', source, {
        slots = slotsToObject(inventories[source].slots),
        maxWeight = inventories[source].maxWeight,
        currentWeight = calcWeight(inventories[source].slots),
        items = allItems,
    })
end

-- ============================================================
-- EVENTOS
-- ============================================================

AddEventHandler('nova:server:onPlayerLoaded', function(source, player)
    loadInventory(source)
    Wait(500)
    updateClient(source)
end)

AddEventHandler('nova:server:onPlayerDropped', function(source)
    if inventories[source] then
        saveInventory(source)
        inventories[source] = nil
    end
end)

AddEventHandler('nova:server:onPlayerLogout', function(source)
    if inventories[source] then
        saveInventory(source)
        inventories[source] = nil
    end
end)

-- NUI Callbacks via eventos
RegisterNetEvent('nova_inventory:requestOpen')
AddEventHandler('nova_inventory:requestOpen', function()
    local src = source
    if not inventories[src] then loadInventory(src) end
    updateClient(src)
end)

RegisterNetEvent('nova_inventory:moveItem')
AddEventHandler('nova_inventory:moveItem', function(fromSlot, toSlot)
    local src = source
    if not inventories[src] then return end
    local inv = inventories[src].slots

    local fromItem = inv[fromSlot]
    local toItem = inv[toSlot]

    -- Se ambos existem e são o mesmo item, stackar
    if fromItem and toItem and fromItem.name == toItem.name and not getItemData(fromItem.name).unique then
        inv[toSlot].amount = (toItem.amount or 0) + (fromItem.amount or 0)
        inv[fromSlot] = nil
    else
        -- Swap
        inv[fromSlot] = toItem
        inv[toSlot] = fromItem
    end

    saveInventory(src)
    updateClient(src)
end)

RegisterNetEvent('nova_inventory:useItem')
AddEventHandler('nova_inventory:useItem', function(slot)
    local src = source
    if not inventories[src] then return end
    local item = inventories[src].slots[slot]
    if not item then return end

    local itemData = getItemData(item.name)
    if not itemData or not itemData.useable then
        TriggerClientEvent('nova_notify:show', src, InvL('item_not_useable'), 'error', 3000)
        return
    end

    -- Remover 1 unidade do item (exceto armas/documentos que são permanentes)
    local shouldConsume = true
    if itemData.type == 'weapon' or itemData.type == 'item' then
        if itemData.unique then
            shouldConsume = false
        end
    end

    -- Items que são consumíveis (comida, bebida, medkit, bandage, ammo, armor, jerrycan, repairkit)
    if shouldConsume then
        inventories[src].slots[slot].amount = (item.amount or 1) - 1
        if inventories[src].slots[slot].amount <= 0 then
            inventories[src].slots[slot] = nil
        end
        saveInventory(src)
        updateClient(src)
    end

    TriggerEvent('nova:server:onItemUse', src, item.name, item)
    TriggerClientEvent('nova_inventory:itemUsed', src, item.name, item)
end)

-- Devolver item se uso cancelado via progress bar
RegisterNetEvent('nova_inventory:refundItem')
AddEventHandler('nova_inventory:refundItem', function(itemName)
    local src = source
    if not itemName or itemName == '' then return end
    AddItem(src, itemName, 1)
end)

-- Aplicar efeitos de metadata no servidor (hunger, thirst, etc.)
RegisterNetEvent('nova_inventory:applyEffect')
AddEventHandler('nova_inventory:applyEffect', function(effectType, value)
    local src = source
    if not effectType or not value then return end
    if type(value) ~= 'number' or value <= 0 or value > 100 then return end

    pcall(function()
        local player = exports['nova_core']:GetPlayer(src)
        if player and player.metadata then
            local current = player.metadata[effectType] or 0
            local newVal = math.min(current + value, 100)
            exports['nova_core']:SetPlayerMetadata(src, effectType, newVal)
        end
    end)
end)

RegisterNetEvent('nova_inventory:dropItem')
AddEventHandler('nova_inventory:dropItem', function(slot, amount, coords)
    local src = source
    if not inventories[src] then return end
    local item = inventories[src].slots[slot]
    if not item then return end

    amount = math.min(amount or 1, item.amount)

    -- Remover do inventário
    inventories[src].slots[slot].amount = item.amount - amount
    if inventories[src].slots[slot].amount <= 0 then
        inventories[src].slots[slot] = nil
    end

    -- Criar ground item
    groundId = groundId + 1
    groundItems[groundId] = {
        id = groundId,
        name = item.name,
        label = item.label,
        amount = amount,
        coords = coords,
        time = os.time(),
    }

    TriggerClientEvent('nova_inventory:groundUpdate', -1, groundItems)
    saveInventory(src)
    updateClient(src)
end)

RegisterNetEvent('nova_inventory:pickupItem')
AddEventHandler('nova_inventory:pickupItem', function(groundItemId)
    local src = source
    local gItem = groundItems[groundItemId]
    if not gItem then return end

    local success = AddItem(src, gItem.name, gItem.amount)
    if success then
        groundItems[groundItemId] = nil
        TriggerClientEvent('nova_inventory:groundUpdate', -1, groundItems)
    end
end)

-- Limpar ground items expirados
CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        local changed = false
        for id, item in pairs(groundItems) do
            if now - item.time > InvConfig.GroundItemExpiry then
                groundItems[id] = nil
                changed = true
            end
        end
        if changed then
            TriggerClientEvent('nova_inventory:groundUpdate', -1, groundItems)
        end
    end
end)
