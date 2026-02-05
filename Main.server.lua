local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)

local services = script.Parent:WaitForChild("Services")

local PlayerDataService = require(services.PlayerDataService)
local InventoryService = require(services.InventoryService)
local BuildingService = require(services.BuildingService)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name)
    local remote = remotes:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end

    remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = remotes
    return remote
end

local placeEvent = ensureRemote("PlaceBlock")
local moveEvent = ensureRemote("MoveBlock")
local paintEvent = ensureRemote("PaintBlock")
local scaleEvent = ensureRemote("ScaleBlock")
local deleteEvent = ensureRemote("DeleteBlock")
local purchaseEvent = ensureRemote("PurchaseBlock")
local currencyEvent = ensureRemote("CurrencyClick")
local inventoryUpdateEvent = ensureRemote("InventoryUpdate")

local function sendInventory(player)
    local inventory = InventoryService.getInventory(player)
    if not inventory then
        return
    end

    inventoryUpdateEvent:FireClient(player, inventory)
end

Players.PlayerAdded:Connect(function(player)
    sendInventory(player)
end)

placeEvent.OnServerEvent:Connect(function(player, blockType, position, rotation, target, normal)
    if typeof(position) ~= "Vector3" then
        return
    end

    local success, result = BuildingService.placeBlock(player, blockType, position, rotation, target, normal)
    if success then
        sendInventory(player)
    end
end)

moveEvent.OnServerEvent:Connect(function(player, block, position, rotation)
    if typeof(position) ~= "Vector3" or not block then
        return
    end

    BuildingService.moveBlock(player, block, position, rotation)
end)

paintEvent.OnServerEvent:Connect(function(player, block, color)
    if not block then
        return
    end

    BuildingService.paintBlock(player, block, color)
end)

scaleEvent.OnServerEvent:Connect(function(player, block, size, position, increment)
    if not block or typeof(size) ~= "Vector3" or typeof(position) ~= "Vector3" then
        return
    end

    BuildingService.scaleBlock(player, block, size, position, increment)
end)

deleteEvent.OnServerEvent:Connect(function(player, block)
    if not block then
        return
    end

    local success = BuildingService.deleteBlock(player, block)
    if success then
        sendInventory(player)
    end
end)

purchaseEvent.OnServerEvent:Connect(function(player, blockType, amount)
    local config = Config.BlockTypes[blockType]
    if not config then
        return
    end

    local quantity = math.max(1, tonumber(amount) or 1)
    local cost = config.Cost * quantity

    local currency = PlayerDataService.getCurrencyValue(player)
    if not currency or currency.Value < cost then
        return
    end

    currency.Value = currency.Value - cost
    InventoryService.addItem(player, blockType, quantity)
    sendInventory(player)
end)

currencyEvent.OnServerEvent:Connect(function(player)
    local currency = PlayerDataService.getCurrencyValue(player)
    if currency then
        currency.Value = currency.Value + 25
    end
end)
