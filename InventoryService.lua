local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)

local InventoryService = {}

local inventories = {}

local function getStarterInventory()
    local inventory = {}
    for blockType, _ in pairs(Config.BlockTypes) do
        inventory[blockType] = 0
    end
    return inventory
end

function InventoryService.getInventory(player)
    return inventories[player.UserId]
end

function InventoryService.addItem(player, blockType, amount)
    local inventory = inventories[player.UserId]
    if not inventory or inventory[blockType] == nil then
        return false
    end

    inventory[blockType] = inventory[blockType] + amount
    return true
end

function InventoryService.consumeItem(player, blockType, amount)
    local inventory = inventories[player.UserId]
    if not inventory or inventory[blockType] == nil then
        return false
    end

    if inventory[blockType] < amount then
        return false
    end

    inventory[blockType] = inventory[blockType] - amount
    return true
end

Players.PlayerAdded:Connect(function(player)
    inventories[player.UserId] = getStarterInventory()
end)

Players.PlayerRemoving:Connect(function(player)
    inventories[player.UserId] = nil
end)

return InventoryService
