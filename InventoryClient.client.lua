local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local ClientState = require(ReplicatedStorage.Modules.ClientState)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryUpdateEvent = remotes:WaitForChild("InventoryUpdate")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 260)
frame.Position = UDim2.new(1, -270, 0, 80)
frame.BackgroundTransparency = 0.2
frame.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(70, 70, 90)
frameStroke.Thickness = 1
frameStroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Inventory"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = frame

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, -20, 1, -40)
grid.Position = UDim2.new(0, 10, 0, 35)
grid.BackgroundTransparency = 1
grid.Parent = frame

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0, 64, 0, 64)
layout.CellPadding = UDim2.new(0, 6, 0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Parent = grid

local selectedBlockType = ClientState.BlockType
local tiles = {}
local inventoryAmounts = {}
local knownBlockTypes = {}
local orderedBlockTypes = {}

for blockType, _ in pairs(Config.BlockTypes) do
    inventoryAmounts[blockType] = 0
    knownBlockTypes[blockType] = false
    table.insert(orderedBlockTypes, blockType)
end

table.sort(orderedBlockTypes)

local function updateTileVisual(blockType)
    local tile = tiles[blockType]
    if not tile then
        return
    end

    local amount = inventoryAmounts[blockType] or 0
    local known = knownBlockTypes[blockType] == true

    tile.Visible = known
    if not known then
        return
    end

    local countLabel = tile:FindFirstChild("CountLabel")
    local preview = tile:FindFirstChild("Preview")

    if countLabel then
        countLabel.Text = tostring(amount)
    end

    if preview and preview:IsA("Frame") then
        preview.BackgroundTransparency = amount > 0 and 0 or 0.35
    end

    local isSelected = blockType == selectedBlockType
    if isSelected then
        tile.BackgroundColor3 = Color3.fromRGB(80, 130, 80)
    else
        tile.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    end

    tile.AutoButtonColor = amount > 0
end

local function selectBlockType(blockType)
    if knownBlockTypes[blockType] ~= true then
        return
    end

    if (inventoryAmounts[blockType] or 0) <= 0 then
        return
    end

    selectedBlockType = blockType
    ClientState.setBlockType(blockType)

    for name, _ in pairs(tiles) do
        updateTileVisual(name)
    end
end

for orderIndex, blockType in ipairs(orderedBlockTypes) do
    local config = Config.BlockTypes[blockType]
    local tile = Instance.new("TextButton")
    tile.Name = blockType .. "Tile"
    tile.Size = UDim2.new(0, 64, 0, 64)
    tile.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    tile.Text = ""
    tile.Visible = false
    tile.Parent = grid
    tile.LayoutOrder = orderIndex

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = tile

    local preview = Instance.new("Frame")
    preview.Name = "Preview"
    preview.Size = UDim2.new(1, -12, 1, -12)
    preview.Position = UDim2.new(0, 6, 0, 6)
    preview.BackgroundColor3 = config.Color
    preview.BorderSizePixel = 0
    preview.Parent = tile

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 4)
    previewCorner.Parent = preview

    local materialLabel = Instance.new("TextLabel")
    materialLabel.Size = UDim2.new(1, 0, 1, 0)
    materialLabel.BackgroundTransparency = 1
    materialLabel.Text = blockType
    materialLabel.TextScaled = true
    materialLabel.Font = Enum.Font.GothamBold
    materialLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
    materialLabel.TextStrokeTransparency = 0.5
    materialLabel.Parent = preview

    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.AnchorPoint = Vector2.new(1, 1)
    countLabel.Position = UDim2.new(1, -4, 1, -2)
    countLabel.Size = UDim2.new(0, 28, 0, 20)
    countLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    countLabel.BackgroundTransparency = 0.2
    countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countLabel.TextScaled = true
    countLabel.Font = Enum.Font.GothamBold
    countLabel.Text = "0"
    countLabel.Parent = tile

    local countCorner = Instance.new("UICorner")
    countCorner.CornerRadius = UDim.new(0, 3)
    countCorner.Parent = countLabel

    tile.Activated:Connect(function()
        selectBlockType(blockType)
    end)

    tiles[blockType] = tile
end

inventoryUpdateEvent.OnClientEvent:Connect(function(inventory)
    for blockType, _ in pairs(Config.BlockTypes) do
        local amount = inventory[blockType] or 0
        inventoryAmounts[blockType] = amount
        if amount > 0 then
            knownBlockTypes[blockType] = true
        end
        updateTileVisual(blockType)
    end

    if selectedBlockType and knownBlockTypes[selectedBlockType] ~= true then
        selectedBlockType = nil
    end

    if not selectedBlockType or (inventoryAmounts[selectedBlockType] or 0) <= 0 then
        local chosen = nil
        for _, blockType in ipairs(orderedBlockTypes) do
            local amount = inventoryAmounts[blockType] or 0
            if knownBlockTypes[blockType] and amount > 0 then
                chosen = blockType
                break
            end
        end

        if chosen then
            selectBlockType(chosen)
        end
    end
end)

ClientState.BlockTypeChanged.Event:Connect(function(blockType)
    selectedBlockType = blockType
    for name, _ in pairs(tiles) do
        updateTileVisual(name)
    end
end)
