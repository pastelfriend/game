local Players = game:GetService("Players")

local PlayerDataService = {}

local currencyFolderName = "leaderstats"
local currencyName = "DollarBucks"

function PlayerDataService.createLeaderstats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = currencyFolderName
    leaderstats.Parent = player

    local currency = Instance.new("IntValue")
    currency.Name = currencyName
    currency.Value = 100
    currency.Parent = leaderstats

    return currency
end

function PlayerDataService.getCurrencyValue(player)
    local leaderstats = player:FindFirstChild(currencyFolderName)
    if not leaderstats then
        return nil
    end

    return leaderstats:FindFirstChild(currencyName)
end

Players.PlayerAdded:Connect(function(player)
    PlayerDataService.createLeaderstats(player)
end)

return PlayerDataService
