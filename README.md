# Modular Building + Economy Starter

This repo contains a clean, server-authoritative starter architecture for a modular building system with a full economy/inventory loop.

## Recommended Folder Structure

```
ReplicatedStorage
  Modules
    Config.lua
    GridUtil.lua
    ClientState.lua
  Remotes
    PlaceBlock
    MoveBlock
    DeleteBlock
    PaintBlock
    ScaleBlock
    PurchaseBlock
    CurrencyClick
    InventoryUpdate
ServerScriptService
  Main.server.lua
  Services
    PlayerDataService.lua
    InventoryService.lua
    BuildingService.lua
StarterPlayer
  StarterPlayerScripts
    BuildingClient.client.lua
    HotbarUI.client.lua
StarterGui
  ShopGui
    ShopClient.client.lua
  InventoryGui
    InventoryClient.client.lua
  CurrencyGui
    CurrencyButton.client.lua
StarterPack
  Delete
  Place
  Move
  Paint
  Scale
ServerScriptService
  ToolSetup.server.lua
```

### Script Naming + Type (Important)

Roblox does **not** use file extensions in the Explorer. The `.lua` suffix here is just for this repo. In Studio, create:

- **ModuleScripts** named exactly: `Config`, `GridUtil`, `ClientState`
- **Server Script** named exactly: `Main` (it now auto-creates remotes)
- **ModuleScripts** in `ServerScriptService/Services` named exactly: `PlayerDataService`, `InventoryService`, `BuildingService`
- **LocalScripts** named exactly: `BuildingClient`, `HotbarUI`, `ShopClient`, `InventoryClient`, `CurrencyButton`
- **Server Script** named exactly: `ToolSetup`

If the object type is wrong (e.g., Script instead of LocalScript) the UI will not appear.

### Quick Troubleshooting

If you only see the **Get Currency** button:

1. Double-check that `ReplicatedStorage/Modules/Config`, `GridUtil`, and `ClientState` are **ModuleScripts** (not Scripts).
2. Double-check that `ShopClient` and `InventoryClient` are **LocalScripts** (not Scripts).
3. Make sure all three ModuleScripts are present, because those LocalScripts `require` them on startup.
4. Make sure you have the `Main` + `ToolSetup` scripts so remotes and hotbar tools appear.

## Inventory Data Structure

Server maintains inventory per player:

```lua
inventory = {
    Plastic = 0,
    Wood = 0,
    Metal = 0,
}
```

## Key Notes

- **Server-authoritative placement** and validation for currency, inventory, and ownership.
- **Client-side ghost preview** for grid snapping and placement.
- **Block ownership** stored via `OwnerUserId` attribute.
- **Per-player block folders** in `Workspace.PlayerBlocks/{UserId}`.
- **RemoteEvents** used for all gameplay actions.

Use the scripts as drop-in contents for a blank place. All UI is generated at runtime by the LocalScripts in `StarterGui`.
