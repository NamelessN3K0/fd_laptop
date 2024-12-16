local inventory = {}

function inventory.hasItem(itemName, metadata)
    local hasItem = exports["tgiann-inventory"]:HasItem(itemName, 1)
    return hasItem
end

return inventory