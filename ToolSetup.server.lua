local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")

local TOOL_DEFS = {
    { Name = "Delete", ToolType = "Delete", Order = 1 },
    { Name = "Place", ToolType = "Place", Order = 2 },
    { Name = "Move", ToolType = "Move", Order = 3 },
    { Name = "Paint", ToolType = "Paint", Order = 4 },
    { Name = "Scale", ToolType = "Scale", Order = 5 },
}

local function buildTool(toolDef)
    local tool = Instance.new("Tool")
    tool.Name = toolDef.Name
    tool.ToolTip = toolDef.Name
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool:SetAttribute("ToolType", toolDef.ToolType)
    tool.Parent = StarterPack
    return tool
end

local function styleTool(tool, toolDef)
    tool.Name = toolDef.Name
    tool.ToolTip = toolDef.Name
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool:SetAttribute("ToolType", toolDef.ToolType)
end

local function ensureToolTemplate(toolDef)
    local existing = StarterPack:FindFirstChild(toolDef.Name)
    if existing and existing:IsA("Tool") then
        styleTool(existing, toolDef)
        return
    end

    buildTool(toolDef)
end

local function cleanupOldToolNames(container)
    local oldNames = {
        PlaceTool = true,
        MoveTool = true,
        DeleteTool = true,
        PaintTool = true,
        ScaleTool = true,
    }

    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Tool") and oldNames[child.Name] then
            child:Destroy()
        end
    end
end

local function ensureAllToolTemplates()
    cleanupOldToolNames(StarterPack)

    for _, toolDef in ipairs(TOOL_DEFS) do
        ensureToolTemplate(toolDef)
    end
end

local function clearExistingTools(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Tool") then
            child:Destroy()
        end
    end
end

local function giveOrderedTools(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return
    end

    local starterGear = player:FindFirstChild("StarterGear")

    clearExistingTools(backpack)
    if starterGear then
        clearExistingTools(starterGear)
    end

    for _, toolDef in ipairs(TOOL_DEFS) do
        local source = StarterPack:FindFirstChild(toolDef.Name)
        if source and source:IsA("Tool") then
            source:Clone().Parent = backpack
            if starterGear then
                source:Clone().Parent = starterGear
            end
        end
    end
end

ensureAllToolTemplates()

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        giveOrderedTools(player)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    giveOrderedTools(player)
    player.CharacterAdded:Connect(function()
        giveOrderedTools(player)
    end)
end
