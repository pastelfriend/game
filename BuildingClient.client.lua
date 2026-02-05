local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local GridUtil = require(ReplicatedStorage.Modules.GridUtil)
local ClientState = require(ReplicatedStorage.Modules.ClientState)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local placeEvent = remotes:WaitForChild("PlaceBlock")
local moveEvent = remotes:WaitForChild("MoveBlock")
local paintEvent = remotes:WaitForChild("PaintBlock")
local scaleEvent = remotes:WaitForChild("ScaleBlock")
local deleteEvent = remotes:WaitForChild("DeleteBlock")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

local ghostPart = Instance.new("Part")
ghostPart.Name = "GhostPreview"
ghostPart.Transparency = 1
ghostPart.Anchored = true
ghostPart.CanCollide = false
ghostPart.CanQuery = false
ghostPart.Material = Enum.Material.Neon
ghostPart.Parent = workspace

local ghostOutline = Instance.new("SelectionBox")
ghostOutline.Name = "GhostOutline"
ghostOutline.LineThickness = 0.06
ghostOutline.Color3 = Color3.fromRGB(255, 255, 255)
ghostOutline.SurfaceColor3 = Color3.fromRGB(120, 240, 255)
ghostOutline.SurfaceTransparency = 0.8
ghostOutline.Adornee = ghostPart
ghostOutline.Parent = ghostPart

local hoverOutline = Instance.new("SelectionBox")
hoverOutline.Name = "HoverOutline"
hoverOutline.LineThickness = 0.05
hoverOutline.Color3 = Color3.fromRGB(255, 235, 120)
hoverOutline.SurfaceTransparency = 1
hoverOutline.Visible = false
hoverOutline.Parent = workspace

local HOVER_COLORS = {
    Delete = Color3.fromRGB(255, 80, 80),
    Paint = Color3.fromRGB(255, 255, 255),
    Move = Color3.fromRGB(0, 170, 255),
}

local selectedBlock = nil
local moveHandles = Instance.new("Handles")
moveHandles.Visible = false
moveHandles.Style = Enum.HandlesStyle.Movement
moveHandles.Parent = playerGui

local scaleHandles = Instance.new("Handles")
scaleHandles.Visible = false
scaleHandles.Style = Enum.HandlesStyle.Resize
scaleHandles.Parent = playerGui

local dragStartCFrame = nil
local dragAxis = nil
local dragStartPosition = nil
local dragLastPosition = nil

local scaleDragAxis = nil
local scaleDragStartSize = nil
local scaleDragStartPosition = nil

local function updateToolFromEquipped()
    local character = player.Character
    if not character then
        ClientState.setTool("None")
        return
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local toolType = child:GetAttribute("ToolType")
            if typeof(toolType) == "string" and toolType ~= "" then
                ClientState.setTool(toolType)
                return
            end
        end
    end

    ClientState.setTool("None")
end

local function bindToolState(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            updateToolFromEquipped()
        end
    end)

    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            updateToolFromEquipped()
        end
    end)

    updateToolFromEquipped()
end

player.CharacterAdded:Connect(function(character)
    bindToolState(character)
end)

if player.Character then
    bindToolState(player.Character)
else
    ClientState.setTool("None")
end

local function axisToVector(normalId)
    if normalId == Enum.NormalId.Right then
        return Vector3.new(1, 0, 0)
    elseif normalId == Enum.NormalId.Left then
        return Vector3.new(-1, 0, 0)
    elseif normalId == Enum.NormalId.Top then
        return Vector3.new(0, 1, 0)
    elseif normalId == Enum.NormalId.Bottom then
        return Vector3.new(0, -1, 0)
    elseif normalId == Enum.NormalId.Front then
        return Vector3.new(0, 0, -1)
    elseif normalId == Enum.NormalId.Back then
        return Vector3.new(0, 0, 1)
    end
    return Vector3.new(0, 1, 0)
end

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

local function getRaycastFilter()
    local filter = {ghostPart}
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer.Character then
            table.insert(filter, otherPlayer.Character)
        end
    end
    return filter
end

local function getRaycastResult()
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = getRaycastFilter()
    return Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
end

local function setGhostVisible(isVisible)
    ghostPart.Transparency = isVisible and 0.35 or 1
    ghostOutline.Visible = isVisible
end

local function getPlacementPosition(hitPosition, normal, blockSize, target)
    if target and target:IsA("BasePart") and target:GetAttribute("OwnerUserId") ~= nil then
        local centerOffset = Vector3.new(
            normal.X ~= 0 and normal.X * ((target.Size.X + blockSize.X) * 0.5) or 0,
            normal.Y ~= 0 and normal.Y * ((target.Size.Y + blockSize.Y) * 0.5) or 0,
            normal.Z ~= 0 and normal.Z * ((target.Size.Z + blockSize.Z) * 0.5) or 0
        )
        return GridUtil.snapToGrid(target.Position + centerOffset, Config.GridSize)
    end

    local offset = Vector3.new(
        normal.X ~= 0 and normal.X * (blockSize.X * 0.5) or 0,
        normal.Y ~= 0 and normal.Y * (blockSize.Y * 0.5) or 0,
        normal.Z ~= 0 and normal.Z * (blockSize.Z * 0.5) or 0
    )
    return GridUtil.snapToGrid(hitPosition + offset, Config.GridSize)
end

local function updateGhost()
    local toolActive = ClientState.Tool ~= "None" and ClientState.Tool ~= "Place"
    hoverOutline.Visible = false
    hoverOutline.Adornee = nil

    local hoverResult = getRaycastResult()
    if toolActive and hoverResult and hoverResult.Instance and hoverResult.Instance:IsA("BasePart") then
        local hoverColor = HOVER_COLORS[ClientState.Tool] or Color3.fromRGB(255, 235, 120)
        if ClientState.Tool == "Paint" then
            hoverColor = ClientState.PaintColor
        end
        hoverOutline.Color3 = hoverColor
        hoverOutline.Adornee = hoverResult.Instance
        hoverOutline.Visible = true
    end

    if ClientState.Tool ~= "Place" then
        setGhostVisible(false)
        return
    end

    local blockType = ClientState.BlockType
    local config = Config.BlockTypes[blockType]
    if not config then
        setGhostVisible(false)
        return
    end

    local result = getRaycastResult()
    if not result then
        setGhostVisible(false)
        return
    end

    local target = result.Instance
    local normal = result.Normal
    local position = getPlacementPosition(result.Position, normal, config.Size, target)

    if target and target:IsDescendantOf(player.Character) then
        setGhostVisible(false)
        return
    end

    setGhostVisible(true)
    ghostPart.Size = config.Size
    ghostPart.Color = config.Color
    ghostPart.CFrame = CFrame.new(position)
end

RunService.RenderStepped:Connect(updateGhost)

local function getOwnedBlock()
    local target = mouse.Target
    if not target then
        return nil
    end

    if target:GetAttribute("OwnerUserId") ~= player.UserId then
        return nil
    end

    return target
end

local function clearSelectionState()
    selectedBlock = nil

    moveHandles.Visible = false
    moveHandles.Adornee = nil
    dragStartCFrame = nil
    dragStartPosition = nil
    dragLastPosition = nil
    dragAxis = nil

    scaleHandles.Visible = false
    scaleHandles.Adornee = nil
    scaleDragAxis = nil
    scaleDragStartSize = nil
    scaleDragStartPosition = nil
end

local function ensureSelectedOwnedBlock()
    local ownedBlock = getOwnedBlock()
    if not ownedBlock then
        return
    end

    selectedBlock = ownedBlock
end

local function showHandlesForCurrentTool()
    moveHandles.Visible = ClientState.Tool == "Move" and selectedBlock ~= nil
    moveHandles.Adornee = moveHandles.Visible and selectedBlock or nil

    scaleHandles.Visible = ClientState.Tool == "Scale" and selectedBlock ~= nil
    scaleHandles.Adornee = scaleHandles.Visible and selectedBlock or nil
end

mouse.Button1Down:Connect(function()
    local result = getRaycastResult()
    if not result then
        return
    end

    local position = result.Position

    if ClientState.Tool == "Place" then
        local target = result.Instance
        local normal = result.Normal

        if target and target:IsDescendantOf(player.Character) then
            return
        end

        placeEvent:FireServer(ClientState.BlockType, position, 0, target, normal)
        return
    end

    if ClientState.Tool == "Move" then
        ensureSelectedOwnedBlock()
        showHandlesForCurrentTool()
        return
    end

    if ClientState.Tool == "Paint" then
        local target = getOwnedBlock()
        if target then
            paintEvent:FireServer(target, ClientState.PaintColor)
        end
        return
    end

    if ClientState.Tool == "Delete" then
        local target = getOwnedBlock()
        if target then
            deleteEvent:FireServer(target)
        end
        return
    end

    if ClientState.Tool == "Scale" then
        ensureSelectedOwnedBlock()
        showHandlesForCurrentTool()
    end
end)

moveHandles.MouseButton1Down:Connect(function(normalId)
    if not selectedBlock then
        return
    end

    dragStartCFrame = selectedBlock.CFrame
    dragStartPosition = selectedBlock.Position
    dragLastPosition = selectedBlock.Position
    dragAxis = axisToVector(normalId)
end)

moveHandles.MouseDrag:Connect(function(_, distance)
    if not selectedBlock or not dragStartPosition or not dragAxis then
        return
    end

    local snappedDistance = math.floor((distance / Config.GridSize) + 0.5) * Config.GridSize
    local delta = dragAxis * snappedDistance
    local position = GridUtil.snapToGrid(dragStartPosition + delta, Config.GridSize)
    dragLastPosition = position

    selectedBlock.CFrame = CFrame.new(position)
    moveEvent:FireServer(selectedBlock, position, 0)
end)

moveHandles.MouseButton1Up:Connect(function()
    dragStartCFrame = nil
    dragStartPosition = nil
    dragLastPosition = nil
    dragAxis = nil
end)

scaleHandles.MouseButton1Down:Connect(function(normalId)
    if not selectedBlock then
        return
    end

    scaleDragAxis = axisToVector(normalId)
    scaleDragStartSize = selectedBlock.Size
    scaleDragStartPosition = selectedBlock.Position
end)

scaleHandles.MouseDrag:Connect(function(_, distance)
    if not selectedBlock or not scaleDragAxis or not scaleDragStartSize or not scaleDragStartPosition then
        return
    end

    local increment = math.max(0.05, tonumber(ClientState.ScaleIncrement) or Config.GridSize)
    local snappedDistance = math.floor((distance / increment) + 0.5) * increment
    local proposedSize = scaleDragStartSize + Vector3.new(
        scaleDragAxis.X ~= 0 and snappedDistance or 0,
        scaleDragAxis.Y ~= 0 and snappedDistance or 0,
        scaleDragAxis.Z ~= 0 and snappedDistance or 0
    )

    if proposedSize.X < 0.5 or proposedSize.Y < 0.5 or proposedSize.Z < 0.5 then
        return
    end

    local function snapDimension(value)
        return math.max(0.5, math.floor((value / increment) + 0.5) * increment)
    end

    local snappedSize = Vector3.new(
        snapDimension(proposedSize.X),
        snapDimension(proposedSize.Y),
        snapDimension(proposedSize.Z)
    )

    local axisSizeDelta = Vector3.new(
        scaleDragAxis.X ~= 0 and (snappedSize.X - scaleDragStartSize.X) or 0,
        scaleDragAxis.Y ~= 0 and (snappedSize.Y - scaleDragStartSize.Y) or 0,
        scaleDragAxis.Z ~= 0 and (snappedSize.Z - scaleDragStartSize.Z) or 0
    )
    local centerOffset = Vector3.new(
        axisSizeDelta.X * scaleDragAxis.X * 0.5,
        axisSizeDelta.Y * scaleDragAxis.Y * 0.5,
        axisSizeDelta.Z * scaleDragAxis.Z * 0.5
    )
    local positionStep = math.max(0.05, math.min(Config.GridSize, increment) * 0.5)
    local newPosition = snapVectorToStep(scaleDragStartPosition + centerOffset, positionStep)

    selectedBlock.Size = snappedSize
    selectedBlock.CFrame = CFrame.new(newPosition)
    scaleEvent:FireServer(selectedBlock, snappedSize, newPosition, increment)
end)

scaleHandles.MouseButton1Up:Connect(function()
    scaleDragAxis = nil
    scaleDragStartSize = nil
    scaleDragStartPosition = nil
end)

ClientState.ToolChanged.Event:Connect(function(toolName)
    if toolName ~= "Move" and toolName ~= "Scale" then
        clearSelectionState()
    else
        showHandlesForCurrentTool()
    end

    if toolName == "None" then
        hoverOutline.Visible = false
        hoverOutline.Adornee = nil
    end
end)


-- Consolidated from ToolSettings.client.lua
do
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ToolSettingsGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local scaleFrame = Instance.new("Frame")
    scaleFrame.Size = UDim2.new(0, 220, 0, 90)
    scaleFrame.Position = UDim2.new(0, 10, 0, 410)
    scaleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    scaleFrame.BackgroundTransparency = 0.2
    scaleFrame.Visible = false
    scaleFrame.Parent = screenGui

    local scaleTitle = Instance.new("TextLabel")
    scaleTitle.Size = UDim2.new(1, 0, 0, 24)
    scaleTitle.BackgroundTransparency = 1
    scaleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    scaleTitle.Text = "Scale Settings"
    scaleTitle.Parent = scaleFrame

    local scaleLayout = Instance.new("UIListLayout")
    scaleLayout.Padding = UDim.new(0, 6)
    scaleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scaleLayout.Parent = scaleFrame

    local function makeButton(parent, text, onClick)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 24)
        button.Position = UDim2.new(0, 10, 0, 0)
        button.Text = text
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Parent = parent
        button.Activated:Connect(onClick)
        return button
    end

    local incrementLabel = Instance.new("TextLabel")
    incrementLabel.Size = UDim2.new(1, -20, 0, 24)
    incrementLabel.Position = UDim2.new(0, 10, 0, 0)
    incrementLabel.Text = "Scale Increment"
    incrementLabel.BackgroundTransparency = 1
    incrementLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    incrementLabel.Parent = scaleFrame

    local incrementBox = Instance.new("TextBox")
    incrementBox.Size = UDim2.new(1, -20, 0, 24)
    incrementBox.Position = UDim2.new(0, 10, 0, 0)
    incrementBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    incrementBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    incrementBox.PlaceholderText = "ex: 0.25"
    incrementBox.Text = tostring(ClientState.ScaleIncrement)
    incrementBox.ClearTextOnFocus = false
    incrementBox.Parent = scaleFrame

    incrementBox.FocusLost:Connect(function()
        local value = tonumber(incrementBox.Text)
        if value and value > 0 then
            ClientState.setScaleIncrement(value)
            incrementBox.Text = tostring(value)
        else
            incrementBox.Text = tostring(ClientState.ScaleIncrement)
        end
    end)

    local paintFrame = Instance.new("Frame")
    paintFrame.Size = UDim2.new(0, 260, 0, 260)
    paintFrame.Position = UDim2.new(0, 10, 0, 410)
    paintFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    paintFrame.BackgroundTransparency = 0.2
    paintFrame.Visible = false
    paintFrame.Parent = screenGui

    local paintTitle = Instance.new("TextLabel")
    paintTitle.Size = UDim2.new(1, 0, 0, 24)
    paintTitle.BackgroundTransparency = 1
    paintTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    paintTitle.Text = "Color Wheel"
    paintTitle.Parent = paintFrame

    local palette = Instance.new("Frame")
    palette.Size = UDim2.new(1, -20, 1, -50)
    palette.Position = UDim2.new(0, 10, 0, 34)
    palette.BackgroundTransparency = 1
    palette.Parent = paintFrame

    local paletteLayout = Instance.new("UIGridLayout")
    paletteLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    paletteLayout.CellSize = UDim2.new(0, 28, 0, 28)
    paletteLayout.Parent = palette

    for i = 0, 47 do
        local hue = (i % 12) / 12
        local value = 1 - math.floor(i / 12) * 0.15
        local color = Color3.fromHSV(hue, 1, value)

        local swatch = Instance.new("TextButton")
        swatch.Text = ""
        swatch.BackgroundColor3 = color
        swatch.Parent = palette

        swatch.Activated:Connect(function()
            ClientState.setPaintColor(color)
        end)
    end

    ClientState.ToolChanged.Event:Connect(function(toolName)
        scaleFrame.Visible = toolName == "Scale"
        paintFrame.Visible = toolName == "Paint"
    end)

end
