local itemConfig = require 'config.server.item'
local config = require 'config.laptop'
if not itemConfig.item then return end

local utils = require 'utils.server'
local tgiann_inventory = exports["tgiann-inventory"]

---@type table<string, true>
local registeredStashes = {}

RegisterNetEvent('fd_laptop:server:openLaptopStorage', function(slot)
    local src = source

    local item = tgiann_inventory:GetItemBySlot(src, slot)
    if not item then return end
    if not item.info?.id then return false end
    if not registeredStashes[item.metadata.id] then return false end

    tgiann_inventory:OpenInventory(src, "stash", ('fd_laptop_%s'):format(item.metadata.id), {
        maxweight = itemConfig.weight,
        slots =  itemConfig.slots,
    })
end)

local function getStashItemsFromDB(inventoryId)
    local result = MySQL.Sync.fetchScalar('SELECT items FROM tgiann_inventory_stashitems WHERE stash = ?', {inventoryId})
    if result then
        return json.decode(result)
    else
        return {}
    end
end

RegisterServerEvent('fd_laptop:clientUseLaptop')
AddEventHandler('fd_laptop:clientUseLaptop', function(data)
    local src = source
    exports['fd_laptop']:useLaptop(src)
end)

exports('useLaptop', function(src)
    local item = tgiann_inventory:GetItemByName(src, "laptop")
    if not item then 
        return false 
    end
    if not item.info?.id then
        local newMetadata = {
            id = utils.uuid()
        }
        tgiann_inventory:UpdateItemMetadata(src, "laptop", item.slot, newMetadata)
        item = tgiann_inventory:GetItemByName(src, "laptop")
    end

    if not registeredStashes[item.info.id] then
        tgiann_inventory:CreateCustomStashWithItem(('fd_laptop_%s'):format(item.info.id), {})
        registeredStashes[item.info.id] = true
    end

    local items getStashItemsFromDB(('fd_laptop_%s'):format(item.info.id))

    local devices = {}

    if items then
        for _, item in pairs(items) do
            if item.info?.deviceId then
                devices[#devices + 1] = {
                    slot = item.slot,
                    metadata = item.info
                }
            end
        end
    end

    TriggerEvent('fd_laptop:server:useLaptop', src, item.info?.id, devices)
    return
end)
