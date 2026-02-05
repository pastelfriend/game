local Config = {}

Config.GridSize = 1
Config.ScaleIncrements = {0.5, 1, 2}

Config.BlockTypes = {
    Plastic = {
        Name = "Plastic",
        Cost = 10,
        Size = Vector3.new(2, 2, 2),
        Color = Color3.fromRGB(163, 162, 165),
        Material = Enum.Material.Plastic,
    },
    Wood = {
        Name = "Wood",
        Cost = 25,
        Size = Vector3.new(2, 2, 2),
        Color = Color3.fromRGB(193, 142, 111),
        Material = Enum.Material.Wood,
    },
    Metal = {
        Name = "Metal",
        Cost = 50,
        Size = Vector3.new(2, 2, 2),
        Color = Color3.fromRGB(127, 127, 127),
        Material = Enum.Material.DiamondPlate,
    },
}

return Config
