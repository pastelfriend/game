local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local GridUtil = require(ReplicatedStorage.Modules.GridUtil)

local services = script.Parent
local PlayerDataService = require(services.PlayerDataService)
local InventoryService = require(services.InventoryService)

local BuildingService = {}

local function snapNumberToStep(value, step)
    return math.floor((value / step) + 0.5) * step
end

local function snapVectorToStep(vector, step)
    return Vector3.new(
        snapNumberToStep(vector.X, step),
        snapNumberToStep(vector.Y, step),
        snapNumberToStep(vector.Z, step)
    )
end

local function getPlayerFolder(player)
    local container = Workspace:FindFirstChild("PlayerBlocks")
    if not container then
        container = Instance.new("Folder")
        container.Name = "PlayerBlocks"
        container.Parent = Workspace
    end

    local folder = container:FindFirstChild(tostring(player.UserId))
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = tostring(player.UserId)
        folder.Parent = container
    end

    return folder
end

local function playerOwnsBlock(player, part)
    return part and part:GetAttribute("OwnerUserId") == player.UserId
end

function BuildingService.placeBlock(player, blockType, position, rotation, target, normal)
    local config = Config.BlockTypes[blockType]
    if not config then
        return false, "Invalid block type"
    end

    local inventory = InventoryService.getInventory(player)
    if not inventory or inventory[blockType] <= 0 then
        return false, "Not enough inventory"
    end

    local snappedPosition = GridUtil.snapToGrid(position, Config.GridSize)
    if target and target:IsA("BasePart") and typeof(normal) == "Vector3" then
        if player.Character and target:IsDescendantOf(player.Character) then
            return false, "Cannot place on character"
        end

        if target:GetAttribute("OwnerUserId") ~= nil then
            snappedPosition = GridUtil.snapToGrid(target.Position + Vector3.new(
                normal.X ~= 0 and normal.X * ((target.Size.X + config.Size.X) * 0.5) or 0,
                normal.Y ~= 0 and normal.Y * ((target.Size.Y + config.Size.Y) * 0.5) or 0,
                normal.Z ~= 0 and normal.Z * ((target.Size.Z + config.Size.Z) * 0.5) or 0
            ), Config.GridSize)
        else
            local offset = Vector3.new(
                normal.X ~= 0 and normal.X * (config.Size.X * 0.5) or 0,
                normal.Y ~= 0 and normal.Y * (config.Size.Y * 0.5) or 0,
                normal.Z ~= 0 and normal.Z * (config.Size.Z * 0.5) or 0
            )
            snappedPosition = GridUtil.snapToGrid(position + offset, Config.GridSize)
        end
    end

    local block = Instance.new("Part")
    block.Name = blockType
    block.Size = config.Size
    block.Color = config.Color
    block.Material = config.Material or Enum.Material.Plastic
    block.Anchored = true
    block.CFrame = CFrame.new(snappedPosition) * CFrame.Angles(0, rotation or 0, 0)
    block:SetAttribute("OwnerUserId", player.UserId)
    block.Parent = getPlayerFolder(player)

    InventoryService.consumeItem(player, blockType, 1)

    return true, block
end

function BuildingService.moveBlock(player, block, position, rotation)
    if not playerOwnsBlock(player, block) then
        return false, "Not owner"
    end

    local snappedPosition = GridUtil.snapToGrid(position, Config.GridSize)
    block.CFrame = CFrame.new(snappedPosition) * CFrame.Angles(0, rotation or 0, 0)

    return true
end

function BuildingService.cloneBlock(player, block, payWithCurrency)
    if not playerOwnsBlock(player, block) then
        return false, "Not owner"
    end

    local blockType = block.Name
    local config = Config.BlockTypes[blockType]
    if not config then
        return false, "Invalid block type"
    end

    if payWithCurrency then
        local currency = PlayerDataService.getCurrencyValue(player)
        if not currency or currency.Value < config.Cost then
            return false, "Not enough currency"
        end
        currency.Value = currency.Value - config.Cost
    else
        local inventory = InventoryService.getInventory(player)
        if not inventory or inventory[blockType] <= 0 then
            return false, "Not enough inventory"
        end
        InventoryService.consumeItem(player, blockType, 1)
    end

    local clone = block:Clone()
    clone:SetAttribute("OwnerUserId", player.UserId)
    clone.Parent = getPlayerFolder(player)

    return true, clone
end

function BuildingService.paintBlock(player, block, color)
    if not playerOwnsBlock(player, block) then
        return false, "Not owner"
    end

    if typeof(color) ~= "Color3" then
        return false, "Invalid color"
    end

    block.Color = color

    return true
end

function BuildingService.scaleBlock(player, block, size, position, increment)
    if not playerOwnsBlock(player, block) then
        return false, "Not owner"
    end

    if typeof(size) ~= "Vector3" or typeof(position) ~= "Vector3" then
        return false, "Invalid scale data"
    end

    if size.X < 0.5 or size.Y < 0.5 or size.Z < 0.5 then
        return false, "Invalid size"
    end

    local snapIncrement = tonumber(increment)
    if not snapIncrement or snapIncrement <= 0 then
        snapIncrement = Config.ScaleIncrements[1]
    end

    local snappedSize = GridUtil.snapToGrid(size, snapIncrement)
    local positionStep = math.max(0.05, math.min(Config.GridSize, snapIncrement) * 0.5)
    local snappedPosition = snapVectorToStep(position, positionStep)

    block.Size = Vector3.new(
        math.max(0.5, snappedSize.X),
        math.max(0.5, snappedSize.Y),
        math.max(0.5, snappedSize.Z)
    )
    block.CFrame = CFrame.new(snappedPosition)

    return true
end

function BuildingService.deleteBlock(player, block)
    if not playerOwnsBlock(player, block) then
        return false, "Not owner"
    end

    local blockType = block.Name
    if Config.BlockTypes[blockType] then
        InventoryService.addItem(player, blockType, 1)
    end

    block:Destroy()
    return true
end

Players.PlayerAdded:Connect(function(player)
    getPlayerFolder(player)
end)

Players.PlayerRemoving:Connect(function(player)
    local container = Workspace:FindFirstChild("PlayerBlocks")
    if container then
        local folder = container:FindFirstChild(tostring(player.UserId))
        if folder then
            folder:Destroy()
        end
    end
end)

return BuildingService
