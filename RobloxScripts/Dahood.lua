local Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-- Create the Fluent window
local Window = Library:CreateWindow({
    Title = "Collapse-Dahood",
    SubTitle = "Made by Finny<3",
    TabWidth = 160,
    Size = UDim2.fromOffset(1250, 800),
    Resize = true,
    MinSize = Vector2.new(500, 500),
    Acrylic = true,
    Theme = "VSC Dark High Contrast",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Create tabs
local Tabs = {
    Main = Window:CreateTab({Title = "Main", Icon = "target"}),
    Teleports = Window:CreateTab({Title = "Teleports", Icon = "pin"}),
    Misc = Window:CreateTab({Title = "Misc", Icon = "settings"}),
    Settings = Window:CreateTab({Title = "Settings", Icon = "settings"})
}

local Options = Library.Options

-- Ensure the game is loaded
while not game:IsLoaded() do wait() end
repeat wait() until game.Players.LocalPlayer.Character

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

-- Anti-idle
local GC = getconnections or get_signal_cons
if GC then
    for i, v in pairs(GC(Players.LocalPlayer.Idled)) do
        if v["Disable"] then v["Disable"](v)
        elseif v["Disconnect"] then v["Disconnect"](v)
        end
    end
else
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local isEnabled = false
local autofarmCoroutine = nil
local cashAuraEnabled = false

-- Function to collect money
local function getMoneyAroundMe()
    wait(0.7)
    for i, money in ipairs(game.Workspace.Ignored.Drop:GetChildren()) do
        if not cashAuraEnabled then return end
        if money.Name == "MoneyDrop" and (money.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude <= 20 then
            fireclickdetector(money.ClickDetector)
            wait(0.7)
        end
    end
end

-- Function to start the autofarm
local function startAutoFarm(toolName)
    local humanoid = game.Players.LocalPlayer.Character.Humanoid
    local tool = game.Players.LocalPlayer.Backpack:FindFirstChild(toolName)
    if not tool then
        warn(toolName .. " tool not found in backpack")
        return
    end
    humanoid:EquipTool(tool)

    while isEnabled do
        for i, v in ipairs(game.Workspace.Cashiers:GetChildren()) do
            if not isEnabled then return end
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.Open.CFrame * CFrame.new(0, 0, 2)

            wait(0.5)

            for i = 0, 10 do
                if not isEnabled then return end
                wait(0.5)
                tool:Activate()
            end
            getMoneyAroundMe()
        end
    end
end

-- Function to teleport and purchase the knife
local function teleportAndPurchaseKnife()
    local targetPosition = Vector3.new(-277.65, 18.849, -236)
    local player = game.Players.LocalPlayer
    while not player.Character do
        wait()
    end
    local character = player.Character or player.CharacterAdded:Wait()
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
    end
    wait(1)
    local knife = game.Workspace.Ignored.Shop:FindFirstChild("[Knife] - $159")
    if knife then
        local clickDetector = knife:FindFirstChild("ClickDetector")
        if clickDetector then
            clickDetector.MaxActivationDistance = 4.5
            fireclickdetector(clickDetector)
            print("Knife purchased")
            wait(1)
            local tool = player.Backpack:FindFirstChild("[Knife] - $159")
            if tool then
                player.Character.Humanoid:EquipTool(tool)
                print("Knife tool equipped after purchase")
            else
                warn("Knife tool not found in backpack")
            end
        else
            warn("ClickDetector not found on the knife object")
        end
    else
        warn("Knife object not found")
    end
end

-- Add elements to Main tab
local AtmAutofarmToggle = Tabs.Main:CreateToggle("AtmAutofarm", {
    Title = "ATM Autofarm", 
    Default = false
})

AtmAutofarmToggle:OnChanged(function(value)
    isEnabled = value
    if isEnabled then
        if not autofarmCoroutine then
            autofarmCoroutine = coroutine.create(function() startAutoFarm("Combat") end)
            coroutine.resume(autofarmCoroutine)
        end
    else
        if autofarmCoroutine then
            coroutine.yield(autofarmCoroutine)
            autofarmCoroutine = nil
        end
    end
end)

local KnifeAutofarmToggle = Tabs.Main:CreateToggle("KnifeAutofarm", {
    Title = "Knife Autofarm", 
    Default = false
})

KnifeAutofarmToggle:OnChanged(function(value)
    if value then
        teleportAndPurchaseKnife()
        wait(1)
        if not autofarmCoroutine then
            autofarmCoroutine = coroutine.create(function() startAutoFarm("[Knife] - $159") end)
            coroutine.resume(autofarmCoroutine)
        end
    else
        if autofarmCoroutine then
            coroutine.yield(autofarmCoroutine)
            autofarmCoroutine = nil
        end
    end
end)

local CashAuraToggle = Tabs.Main:CreateToggle("CashAura", {
    Title = "Cash Aura", 
    Default = false
})

CashAuraToggle:OnChanged(function(value)
    cashAuraEnabled = value
    if cashAuraEnabled then
        getMoneyAroundMe()
    end
end)

local CashDropToggle = Tabs.Main:CreateToggle("CashDrop", {
    Title = "Cash Drop", 
    Default = false
})

CashDropToggle:OnChanged(function(value)
    if value then
        while CashDropToggle.Value do
            dropMoney(10000)
            wait(5)
        end
    end
end)

function dropMoney(amount)
    game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "" .. amount)
end

Tabs.Main:CreateButton({
    Title = "Cash ESP",
    Callback = function()
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local HighlightMaterial = Instance.new("Color3Value")
        HighlightMaterial.Name = "HighlightMaterial"
        HighlightMaterial.Value = Color3.fromRGB(0, 255, 0) -- Neon green color
        HighlightMaterial.Parent = ReplicatedStorage

        local function applyESP(part)
            if not part or not part:IsA("BasePart") or part.Name ~= "MoneyDrop" then
                return
            end

            local highlight = Instance.new("BoxHandleAdornment")
            highlight.Size = part.Size * 1.1
            highlight.Color3 = HighlightMaterial.Value
            highlight.Transparency = 0.3
            highlight.AlwaysOnTop = true
            highlight.ZIndex = 1
            highlight.Adornee = part
            highlight.Parent = part
        end

        local function monitorDropsFolder()
            local dropsFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Drop")

            for _, part in ipairs(dropsFolder:GetChildren()) do
                applyESP(part)
            end

            dropsFolder.ChildAdded:Connect(function(part)
                applyESP(part)
            end)
        end

        monitorDropsFolder()

        Library:Notify({
            Title = "ESP Script",
            Content = "ESP script has successfully loaded. Made by Finny <3",
            Duration = 5,
        })

        print("ESP script loaded.")
    end
})

-- Teleports Tab
local teleportButtons = {
    {Title = "Bank", Position = Vector3.new(-373, 18.75, -346)},
    {Title = "Hood Fitness", Position = Vector3.new(-76, 19.45, -594.25)},
    {Title = "Club", Position = Vector3.new(-262.5, -1.208, -376)},
    {Title = "School", Position = Vector3.new(-652.5, 18.75, 197.5)},
    {Title = "BasketBall Court", Position = Vector3.new(-932, 19.6, -482.25)},
    {Title = "Uphill Gunz", Position = Vector3.new(-562.75, 5.66, -736.25)},
    {Title = "Hospital", Position = Vector3.new(80, 19.255, -484.75)},
    {Title = "Ufo", Position = Vector3.new(49.75, 159.75, -686.25)},
}

for _, btn in pairs(teleportButtons) do
    Tabs.Teleports:CreateButton({
        Title = btn.Title,
        Callback = function()
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(btn.Position)
            end
        end
    })
end

-- Misc Tab
Tabs.Misc:CreateButton({
    Title = "Destroy the map (recommended for autofarm)",
    Callback = function()
        local function destroyFolderContents(folder)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    child:Destroy()
                end
            else
                warn("Specified folder does not exist")
            end
        end

        local function addAnchoredPart(position, size, color, transparency)
            local part = Instance.new("Part")
            part.Position = position
            part.Size = size
            part.Anchored = true
            part.Color = color
            part.Transparency = transparency
            part.Parent = game.Workspace
        end

        local mapFolderPath = game.Workspace:FindFirstChild("MAP")
        local lightsFolderPath = game.Workspace:FindFirstChild("Lights")
        local ignoredFolderPath = game.Workspace:FindFirstChild("Ignored")

        if mapFolderPath then
            local mapSubFolder = mapFolderPath:FindFirstChild("Map")
            destroyFolderContents(mapSubFolder)
        else
            warn("Folder 'MAP' does not exist in Workspace")
        end

        if mapFolderPath then
            local mapLightsSubFolder = mapFolderPath:FindFirstChild("Lights")
            destroyFolderContents(mapLightsSubFolder)
        else
            warn("Folder 'MAP' does not exist in Workspace")
        end

        destroyFolderContents(lightsFolderPath)

        if ignoredFolderPath then
            local houseOwnFolder = ignoredFolderPath:FindFirstChild("HouseOwn")
            local houseItemSaleFolder = ignoredFolderPath:FindFirstChild("HouseItemSale")
            destroyFolderContents(houseOwnFolder)
            destroyFolderContents(houseItemSaleFolder)
        else
            warn("Folder 'Ignored' does not exist in Workspace")
        end

        local partsData = {
            {size = Vector3.new(167, 1, 31.5), position = Vector3.new(-935.5, 18, -660.25)},
            {size = Vector3.new(15, 1, 17.25), position = Vector3.new(-558, 18.5, 269.625)},
            {size = Vector3.new(22.75, 1, 19), position = Vector3.new(-611.875, 18, 272.25)},
            {size = Vector3.new(39.5, 1, 19.5), position = Vector3.new(586.25, 48, -470.5)},
            {size = Vector3.new(19.5, 1, 18.75), position = Vector3.new(583.5, 45.125, -275.375)},
            {size = Vector3.new(20.5, 1, 20.75), position = Vector3.new(-401.5, 18.005, -590.625)},
            {size = Vector3.new(20.25, 1, 20.5), position = Vector3.new(517.625, 44.5, -302)}
        }

        for _, data in ipairs(partsData) do
            addAnchoredPart(data.position, data.size, Color3.fromRGB(255, 0, 0), 0.5)
        end
    end
})

-- Initialize addons
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

Library:Notify({
    Title = "Collapse-Dahood",
    Content = "Script loaded successfully!",
    Duration = 5
})