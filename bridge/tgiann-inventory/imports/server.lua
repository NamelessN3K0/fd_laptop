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
    if not item.metadata?.id then
        item.metadata.id = utils.uuid()
        tgiann_inventory:SetItemData(src, item, slot, item.metadata)
    end

    if not registeredStashes[item.metadata.id] then
        registeredStashes[id] = true
    end

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

exports('useLaptop', function(event, _, inventory, slot, _)
    if event == 'usingItem' then
        CreateThread(function()
            local item = tgiann_inventory:GetItemBySlot(inventory.id, slot)
            if not item then return false end
            if not item.metadata?.id then 
                item.metadata.id = utils.uuid()
                tgiann_inventory:SetItemData(src, item, slot, item.metadata)
            end

            if not registeredStashes[item.metadata.id] then
                tgiann_inventory:CreateCustomStashWithItem(('fd_laptop_%s'):format(item.metadata.id), {})
                registeredStashes[item.metadata.id] = true
            end

            local items getStashItemsFromDB(('fd_laptop_%s'):format(item.metadata.id))

            local devices = {}

            for _, item in pairs(items) do
                if item.metadata?.deviceId then
                    devices[#devices + 1] = {
                        slot = item.slot,
                        metadata = item.metadata
                    }
                end
            end

            TriggerEvent('fd_laptop:server:useLaptop', inventory.id, item.metadata?.id, devices)
        end)

        return false
    end
end)
