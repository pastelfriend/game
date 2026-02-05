local ClientState = {}

ClientState.Tool = "None"
ClientState.BlockType = "Plastic"
ClientState.ScaleIncrement = 1
ClientState.PaintColor = Color3.fromRGB(255, 255, 255)
ClientState.Axis = "Y"

ClientState.ToolChanged = Instance.new("BindableEvent")
ClientState.BlockTypeChanged = Instance.new("BindableEvent")
ClientState.ScaleChanged = Instance.new("BindableEvent")
ClientState.PaintChanged = Instance.new("BindableEvent")
ClientState.AxisChanged = Instance.new("BindableEvent")

function ClientState.setTool(toolName)
    ClientState.Tool = toolName
    ClientState.ToolChanged:Fire(toolName)
end

function ClientState.setBlockType(blockType)
    ClientState.BlockType = blockType
    ClientState.BlockTypeChanged:Fire(blockType)
end

function ClientState.setScaleIncrement(increment)
    ClientState.ScaleIncrement = increment
    ClientState.ScaleChanged:Fire(increment)
end

function ClientState.setPaintColor(color)
    ClientState.PaintColor = color
    ClientState.PaintChanged:Fire(color)
end

function ClientState.setAxis(axis)
    ClientState.Axis = axis
    ClientState.AxisChanged:Fire(axis)
end

return ClientState
