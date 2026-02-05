local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local TOOL_ORDER = {
    "Delete",
    "Place",
    "Move",
    "Paint",
    "Scale",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.spawn(function()
    for _ = 1, 30 do
        local success = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        if success then
            break
        end
        task.wait(0.1)
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HotbarGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 520, 0, 64)
bar.Position = UDim2.new(0.5, -260, 1, -78)
bar.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
bar.BackgroundTransparency = 0.08
bar.Parent = screenGui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 14)
barCorner.Parent = bar

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(80, 80, 110)
barStroke.Thickness = 1
barStroke.Parent = bar

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = bar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar

local buttonsByName = {}

local function getCharacterToolName()
    local character = player.Character
    if not character then
        return nil
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child.Name
        end
    end

    return nil
end

local function updateHighlights()
    local equipped = getCharacterToolName()
    for toolName, button in pairs(buttonsByName) do
        if equipped == toolName then
            button.BackgroundColor3 = Color3.fromRGB(58, 142, 255)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3 = Color3.fromRGB(44, 44, 58)
            button.TextColor3 = Color3.fromRGB(220, 220, 220)
        end
    end
end

local function findTool(toolName)
    local character = player.Character
    if character then
        local equipped = character:FindFirstChild(toolName)
        if equipped and equipped:IsA("Tool") then
            return equipped
        end
    end

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        local stored = backpack:FindFirstChild(toolName)
        if stored and stored:IsA("Tool") then
            return stored
        end
    end

    return nil
end

local function equipToolByName(toolName)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local equipped = getCharacterToolName()
    if equipped == toolName then
        humanoid:UnequipTools()
        updateHighlights()
        return
    end

    local tool = findTool(toolName)
    if tool then
        humanoid:EquipTool(tool)
        updateHighlights()
    end
end

local function bindCharacter(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            updateHighlights()
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            updateHighlights()
        end
    end)
    updateHighlights()
end

local function buildButtons()
    for _, child in ipairs(bar:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    table.clear(buttonsByName)

    for index, toolName in ipairs(TOOL_ORDER) do
        local button = Instance.new("TextButton")
        button.Name = toolName .. "Button"
        button.Size = UDim2.new(0, 94, 1, 0)
        button.LayoutOrder = index
        button.Text = toolName
        button.BackgroundColor3 = Color3.fromRGB(44, 44, 58)
        button.TextColor3 = Color3.fromRGB(220, 220, 220)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.Parent = bar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(78, 78, 102)
        stroke.Thickness = 1
        stroke.Parent = button

        button.Activated:Connect(function()
            equipToolByName(toolName)
        end)

        buttonsByName[toolName] = button
    end

    updateHighlights()
end

player.CharacterAdded:Connect(function(character)
    bindCharacter(character)
end)

if player.Character then
    bindCharacter(player.Character)
end

local backpack = player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(updateHighlights)
backpack.ChildRemoved:Connect(updateHighlights)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    local index = nil
    if input.KeyCode == Enum.KeyCode.One then
        index = 1
    elseif input.KeyCode == Enum.KeyCode.Two then
        index = 2
    elseif input.KeyCode == Enum.KeyCode.Three then
        index = 3
    elseif input.KeyCode == Enum.KeyCode.Four then
        index = 4
    elseif input.KeyCode == Enum.KeyCode.Five then
        index = 5
    end

    if not index then
        return
    end

    local toolName = TOOL_ORDER[index]
    if toolName then
        equipToolByName(toolName)
    end
end)

buildButtons()
