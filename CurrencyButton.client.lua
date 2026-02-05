local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local currencyEvent = remotes:WaitForChild("CurrencyClick")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CurrencyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local amountLabel = Instance.new("TextLabel")
amountLabel.Size = UDim2.new(0, 260, 0, 38)
amountLabel.Position = UDim2.new(0.5, -130, 0, 16)
amountLabel.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
amountLabel.BackgroundTransparency = 0.15
amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
amountLabel.Font = Enum.Font.GothamBold
amountLabel.TextSize = 18
amountLabel.Text = "DollarBucks: 0"
amountLabel.Parent = screenGui

local amountCorner = Instance.new("UICorner")
amountCorner.CornerRadius = UDim.new(0, 10)
amountCorner.Parent = amountLabel

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 180, 0, 40)
button.Position = UDim2.new(0.5, -90, 0, 62)
button.Text = "Get DollarBucks"
button.BackgroundColor3 = Color3.fromRGB(36, 128, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = button

local function bindCurrency()
    local leaderstats = player:WaitForChild("leaderstats")
    local currency = leaderstats:WaitForChild("DollarBucks")

    local function refresh()
        amountLabel.Text = string.format("DollarBucks: %d", currency.Value)
    end

    refresh()
    currency:GetPropertyChangedSignal("Value"):Connect(refresh)
end

task.spawn(bindCurrency)

button.Activated:Connect(function()
    currencyEvent:FireServer()
end)
