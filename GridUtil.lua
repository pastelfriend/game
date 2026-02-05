local GridUtil = {}

function GridUtil.snapToGrid(position, gridSize)
    return Vector3.new(
        math.floor(position.X / gridSize + 0.5) * gridSize,
        math.floor(position.Y / gridSize + 0.5) * gridSize,
        math.floor(position.Z / gridSize + 0.5) * gridSize
    )
end

return GridUtil
