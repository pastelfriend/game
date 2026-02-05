local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local ClientState = require(ReplicatedStorage.Modules.ClientState)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local purchaseEvent = remotes:WaitForChild("PurchaseBlock")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local orderedBlockTypes = {}
for blockType, _ in pairs(Config.BlockTypes) do
    table.insert(orderedBlockTypes, blockType)
end
table.sort(orderedBlockTypes, function(a, b)
    local aConfig = Config.BlockTypes[a]
    local bConfig = Config.BlockTypes[b]
    if aConfig.Cost == bConfig.Cost then
        return a < b
    end
    return aConfig.Cost < bConfig.Cost
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 320)
frame.Position = UDim2.new(0, 10, 0, 80)
frame.BackgroundTransparency = 0.1
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
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Block Shop"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = frame

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -20, 1, -56)
list.Position = UDim2.new(0, 10, 0, 46)
list.BackgroundTransparency = 1
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function createShopCard(orderIndex, blockType, config)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 56)
    card.LayoutOrder = orderIndex
    card.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
    card.Parent = list

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 34, 0, 34)
    swatch.Position = UDim2.new(0, 10, 0.5, -17)
    swatch.BackgroundColor3 = config.Color
    swatch.Parent = card

    local swatchCorner = Instance.new("UICorner")
    swatchCorner.CornerRadius = UDim.new(0, 6)
    swatchCorner.Parent = swatch

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 84, 0, 20)
    nameLabel.Position = UDim2.new(0, 52, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = blockType
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local costLabel = Instance.new("TextLabel")
    costLabel.Size = UDim2.new(0, 110, 0, 16)
    costLabel.Position = UDim2.new(0, 52, 0, 30)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = string.format("%d DollarBucks", config.Cost)
    costLabel.TextColor3 = Color3.fromRGB(170, 210, 255)
    costLabel.Font = Enum.Font.Gotham
    costLabel.TextSize = 12
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.Parent = card

    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(0, 64, 0, 30)
    buyButton.Position = UDim2.new(1, -74, 0.5, -15)
    buyButton.Text = "Buy"
    buyButton.BackgroundColor3 = Color3.fromRGB(36, 128, 255)
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.Font = Enum.Font.GothamBold
    buyButton.TextSize = 13
    buyButton.Parent = card

    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 8)
    buyCorner.Parent = buyButton

    buyButton.Activated:Connect(function()
        purchaseEvent:FireServer(blockType, 1)
        ClientState.setBlockType(blockType)
    end)
end

for orderIndex, blockType in ipairs(orderedBlockTypes) do
    createShopCard(orderIndex, blockType, Config.BlockTypes[blockType])
end
