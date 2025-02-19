local Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-- State Management
local State = {
    TravelMethod = "Teleport(Risky)",
    AttackMethod = "Heavy Attack", -- Default is Heavy Attack (using Combat tool)
    ATMRunning = false,
    CashAuraActive = false,
    CashDropActive = false,
    VisualizeActive = false,
    ActiveTweens = {},
    CurrentFarm = nil,
    ESPEnabled = false,
    NoclipEnabled = false,
    CurrentATMPosition = nil
}

local seatsFound = false

-- Create Window
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

-- Create Tabs
local Tabs = {
    Main = Window:CreateTab({Title = "Main", Icon = "target"}),
    Teleports = Window:CreateTab({Title = "Teleports", Icon = "telescope"}),
    Misc = Window:CreateTab({Title = "Misc", Icon = "book"}),
    Settings = Window:CreateTab({Title = "Settings", Icon = "settings"})
}

-- Position Update System (not used for ATM locking anymore)
local PositionUpdateConnection = nil

local function StartPositionUpdate(position)
    if PositionUpdateConnection then
        PositionUpdateConnection:Disconnect()
    end
    
    PositionUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and position then
            char.HumanoidRootPart.CFrame = position
        end
    end)
end

-- Noclip Functions
local Noclip = nil
local Clip = nil

local function noclip()
    Clip = false
    local function Nocl()
        if Clip == false and game.Players.LocalPlayer.Character then
            for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide and v.Name ~= "floatName" then
                    v.CanCollide = false
                end
            end
        end
        wait(0.21)
    end
    Noclip = game:GetService("RunService").Stepped:Connect(Nocl)
end

local function farmNoclip()
    Clip = false
    local function Nocl()
        if Clip == false and game.Players.LocalPlayer.Character then
            for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide and v.Name ~= "floatName" then
                    v.CanCollide = false
                end
            end
            for _, cashier in ipairs(game.Workspace.Cashiers:GetChildren()) do
                if cashier:FindFirstChild("Open") then
                    cashier.Open.CanCollide = false
                end
                if cashier:FindFirstChild("Hitbox") then
                    cashier.Hitbox.CanCollide = false
                end
            end
        end
        wait(0.21)
    end
    Noclip = game:GetService("RunService").Stepped:Connect(Nocl)
end

local function clip()
    if Noclip then Noclip:Disconnect() end
    Clip = true
    if game.Players.LocalPlayer.Character then
        for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end
    for _, cashier in ipairs(game.Workspace.Cashiers:GetChildren()) do
        if cashier:FindFirstChild("Open") then
            cashier.Open.CanCollide = true
        end
        if cashier:FindFirstChild("Hitbox") then
            cashier.Hitbox.CanCollide = true
        end
    end
end

-- Core Functions
local function CancelTweens()
    for _, tween in pairs(State.ActiveTweens) do
        pcall(function() tween:Cancel() end)
    end
    State.ActiveTweens = {}
end

local function getSpeed(distance)
    if distance > 150 then
        return 70
    elseif distance > 125 then
        return 60
    elseif distance > 100 then
        return 50
    elseif distance > 50 then
        return 35
    elseif distance > 25 then
        return 15
    elseif distance > 10 then
        return 8
    else
        return 6
    end
end

-- Modified MoveTo: When using Tween(slower), noclip is enabled during tweening
local function MoveTo(targetCFrame)
    local char = game.Players.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    CancelTweens()
    
    if State.TravelMethod == "Tween(slower)" then
        noclip()  -- enable noclip before starting tween
        local distance = (char.HumanoidRootPart.Position - targetCFrame.Position).Magnitude
        local speed = getSpeed(distance)
        local tween = game:GetService("TweenService"):Create(
            char.HumanoidRootPart,
            TweenInfo.new(distance / speed),
            {CFrame = targetCFrame}
        )
        table.insert(State.ActiveTweens, tween)
        tween:Play()
        tween.Completed:Connect(function()
            clip()  -- re-enable collisions after tween finishes
        end)
        return tween
    else
        char.HumanoidRootPart.CFrame = targetCFrame
        return nil
    end
end

-- Knife Purchase Functions with Waiting Loop
local function FindKnife()
    local shop = nil
    if game:FindFirstChild("Ugc") then
        local ugc = game.Ugc
        if ugc:FindFirstChild("Workspace") then
            local ws = ugc.Workspace
            if ws:FindFirstChild("Ignored") then
                local ignored = ws.Ignored
                if ignored:FindFirstChild("Shop") then
                    shop = ignored.Shop
                end
            end
        end
    end
    if shop then
        for _, item in ipairs(shop:GetChildren()) do
            if item.Name == "[Knife] - $164" then
                return item
            end
        end
    end
    return nil
end

local function WaitForKnife(timeout)
    timeout = timeout or 10
    local startTime = tick()
    while tick() - startTime < timeout do
        local knife = FindKnife()
        if knife then
            return knife
        end
        task.wait(0.5)
    end
    return nil
end

local function BuyKnife()
    local knife = WaitForKnife(10)
    if knife and knife:FindFirstChild("ClickDetector") then
        fireclickdetector(knife.ClickDetector)
        task.wait(1)
        return true
    else
        Library:Notify({Title = "Error", Content = "Knife not found in Shop!", Duration = 3})
        return false
    end
end

-- Updated ATM Autofarm (integrated with Attack Method selection)
local function RunATMAutofarm()
    -- If using Knife attack method, tween to knife shop and purchase knife.
    if State.AttackMethod == "Knife" then
        local knifeCFrame = CFrame.new(-277.65, 18.849, -236)
        local tween = MoveTo(knifeCFrame)
        if tween then tween.Completed:Wait() end
        task.wait(1)
        
        if not BuyKnife() then
            State.ATMRunning = false
            clip()
            return
        end
    end

    local lastPunchTime = tick()  -- timer to detect inactivity
    while State.ATMRunning do
        local char = game.Players.LocalPlayer.Character
        if not char then
            task.wait(1)
            continue
        end

        local toolName = (State.AttackMethod == "Knife") and "[Knife] - $164" or "Combat"
        local tool = char:FindFirstChild(toolName) or game.Players.LocalPlayer.Backpack:FindFirstChild(toolName)
        if not tool then
            Library:Notify({Title = "Error", Content = toolName.." tool missing!", Duration = 3})
            State.ATMRunning = false
            clip()
            break
        end
        tool.Parent = char

        local cashiers = game.Workspace.Cashiers:GetChildren()
        if #cashiers == 0 then
            task.wait(1)
            continue
        end

        -- Process each ATM (cashier)
        for _, cashier in ipairs(cashiers) do
            if not State.ATMRunning then break end
            if not cashier:FindFirstChild("Open") then
                continue
            end

            farmNoclip()
            local targetPosition = cashier.Open.CFrame * CFrame.new(0, 0, 2)
            local tween = MoveTo(targetPosition)
            if tween then tween.Completed:Wait() end

            clip()
            task.wait(0.5)

            -- Lock position at current ATM using a coroutine
            local lockRunning = true
            local lockCoroutine = coroutine.create(function()
                while lockRunning do
                    local char = game.Players.LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = targetPosition
                    end
                    task.wait(3)
                end
            end)
            coroutine.resume(lockCoroutine)

            -- Attack loop at current ATM
            for i = 1, 11 do
                if not State.ATMRunning then break end
                tool:Activate()
                lastPunchTime = tick()  -- update timer on each attack
                task.wait(0.5)
            end

            lockRunning = false  -- stop locking position
            task.wait(3.2)
        end

        -- If no attack occurred for over 3 seconds, return to the first ATM.
        if State.ATMRunning and tick() - lastPunchTime > 3 then
            local allCashiers = game.Workspace.Cashiers:GetChildren()
            if #allCashiers > 0 and allCashiers[1]:FindFirstChild("Open") then
                local firstATMPosition = allCashiers[1].Open.CFrame * CFrame.new(0, 0, 2)
                local tween = MoveTo(firstATMPosition)
                if tween then tween.Completed:Wait() end
                task.wait(0.5)
                lastPunchTime = tick()
            end
        end

        task.wait(0.1)
    end

    if PositionUpdateConnection then
        PositionUpdateConnection:Disconnect()
    end
end

-- Cash Aura
local function CashAura()
    while State.CashAuraActive do
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, money in ipairs(game.Workspace.Ignored.Drop:GetChildren()) do
                if money.Name == "MoneyDrop" and money:FindFirstChild("ClickDetector") then
                    if (money.Position - char.HumanoidRootPart.Position).Magnitude <= 20 then
                        fireclickdetector(money.ClickDetector)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end

-- Cash Drop
local function CashDrop()
    while State.CashDropActive do
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "10000")
        task.wait(5)
    end
end

-- Cash ESP
local function ToggleESP(state)
    if state then
        local highlight = Instance.new("Highlight")
        highlight.Name = "MoneyESP"
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
        highlight.FillTransparency = 0.5
        highlight.Parent = game.ReplicatedStorage

        local function applyESP(inst)
            if inst.Name == "MoneyDrop" then
                local clone = highlight:Clone()
                clone.Adornee = inst
                clone.Parent = inst
            end
        end

        for _, money in ipairs(game.Workspace.Ignored.Drop:GetChildren()) do
            applyESP(money)
        end

        game.Workspace.Ignored.Drop.ChildAdded:Connect(applyESP)
    else
        for _, money in ipairs(game.Workspace.Ignored.Drop:GetChildren()) do
            if money:FindFirstChild("MoneyESP") then
                money.MoneyESP:Destroy()
            end
        end
        if game.ReplicatedStorage:FindFirstChild("MoneyESP") then
            game.ReplicatedStorage.MoneyESP:Destroy()
        end
    end
end

-- Map Destruction
local function DestroyMap()
    local function destroyFolder(folder)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                child:Destroy()
            end
        end
    end

    destroyFolder(game.Workspace:FindFirstChild("MAP"))
    destroyFolder(game.Workspace:FindFirstChild("Lights"))
    
    local ignored = game.Workspace:FindFirstChild("Ignored")
    if ignored then
        destroyFolder(ignored:FindFirstChild("HouseOwn"))
        destroyFolder(ignored:FindFirstChild("HouseItemSale"))
    end

    -- Create platforms
    local parts = {
        {CFrame = CFrame.new(-935.5, 18, -660.25), Size = Vector3.new(167, 1, 31.5)},
        {CFrame = CFrame.new(-558, 18.5, 269.625), Size = Vector3.new(15, 1, 17.25)},
        {CFrame = CFrame.new(-611.875, 18, 272.25), Size = Vector3.new(22.75, 1, 19)},
        {CFrame = CFrame.new(586.25, 48, -470.5), Size = Vector3.new(39.5, 1, 19.5)},
        {CFrame = CFrame.new(583.5, 45.125, -275.375), Size = Vector3.new(19.5, 1, 18.75)},
        {CFrame = CFrame.new(-401.5, 18.005, -590.625), Size = Vector3.new(20.5, 1, 20.75)},
        {CFrame = CFrame.new(517.625, 44.5, -302), Size = Vector3.new(20.25, 1, 20.5)},
    }

    for _, data in pairs(parts) do
        local part = Instance.new("Part")
        part.Anchored = true
        part.CFrame = data.CFrame
        part.Size = data.Size
        part.Color = Color3.fromRGB(255, 0, 0)
        part.Transparency = 0.5
        part.Parent = workspace
    end
end

-- UI Elements
Tabs.Main:CreateDropdown("TravelMethod", {
    Title = "Travel Method",
    Values = {"Teleport(Risky)", "Tween(slower)"},
    Multi = false,
    Default = 2,
}):OnChanged(function(value)
    State.TravelMethod = value
end)

Tabs.Main:CreateDropdown("AttackMethod", {
    Title = "Attack Method",
    Values = {"Light Attack", "Heavy Attack", "Knife"},
    Multi = false,
    Default = 2, -- Default is Heavy Attack
}):OnChanged(function(value)
    State.AttackMethod = value
end)

Tabs.Main:CreateToggle("ATM_Autofarm", {
    Title = "ATM Autofarm", 
    Default = false
}):OnChanged(function(state)
    State.ATMRunning = state
    if state then
        coroutine.wrap(RunATMAutofarm)()
    else
        if PositionUpdateConnection then
            PositionUpdateConnection:Disconnect()
        end
    end
end)

Tabs.Main:CreateToggle("Cash_Aura", {
    Title = "Cash Aura", 
    Default = false
}):OnChanged(function(state)
    State.CashAuraActive = state
    if state then
        coroutine.wrap(CashAura)()
    end
end)

Tabs.Main:CreateToggle("Cash_Drop", {
    Title = "Cash Drop", 
    Default = false
}):OnChanged(function(state)
    State.CashDropActive = state
    if state then
        coroutine.wrap(CashDrop)()
    end
end)

Tabs.Main:CreateToggle("Cash_ESP", {
    Title = "Cash ESP", 
    Default = false
}):OnChanged(function(state)
    State.ESPEnabled = state
    ToggleESP(state)
end)

Tabs.Main:CreateToggle("Noclip", {
    Title = "Noclip",
    Default = false
}):OnChanged(function(state)
    State.NoclipEnabled = state
    if state then
        noclip()
    else
        clip()
    end
end)

-- Teleport Buttons
local teleportLocations = {
    {Title = "Bank", Position = Vector3.new(-373, 18.75, -346)},
    {Title = "Hood Fitness", Position = Vector3.new(-76, 19.45, -594.25)},
    {Title = "Club", Position = Vector3.new(-262.5, -1.208, -376)},
    {Title = "School", Position = Vector3.new(-652.5, 18.75, 197.5)},
    {Title = "Uphill Gunz", Position = Vector3.new(-562.75, 5.66, -736.25)},
    {Title = "Hospital", Position = Vector3.new(80, 19.255, -484.75)},
    {Title = "Ufo", Position = Vector3.new(49.75, 159.75, -686.25)}
}

for _, loc in ipairs(teleportLocations) do
    Tabs.Teleports:CreateButton({
        Title = loc.Title,
        Callback = function()
            MoveTo(CFrame.new(loc.Position))
        end
    })
end

-- Misc Tab
Tabs.Misc:CreateButton({
    Title = "Destroy Map",
    Callback = DestroyMap
})

-- Initialize Systems
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Anti-Idle
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- Seat Removal
for _, seat in ipairs(game:GetDescendants()) do
    if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
        seat:Destroy()
        seatsFound = true
    end
end

if not seatsFound then
    warn("No seats found in the game!")
end

Library:Notify({
    Title = "Script Loaded",
    Content = "Script loaded successfully.",
    Duration = 5
})
