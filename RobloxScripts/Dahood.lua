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

-- Create Tabs (Status is now created first)
local Tabs = {
    Status = Window:CreateTab({Title = "Status", Icon = "info"}),
    Main = Window:CreateTab({Title = "Main", Icon = "target"}),
    Teleports = Window:CreateTab({Title = "Teleports", Icon = "telescope"}),
    PVP = Window:CreateTab({Title = "PVP", Icon = "sword"}),
    Misc = Window:CreateTab({Title = "Misc", Icon = "book"}),
    Settings = Window:CreateTab({Title = "Settings", Icon = "settings"})
}

------------------------------------------------------------
-- STATUS TAB: DROPPED CASH DISPLAY
------------------------------------------------------------

-- Create a paragraph in the Status Tab to display the total dropped cash
local statusParagraph = Tabs.Status:CreateParagraph("DroppedCashParagraph", {
    Title = "Total Cash Dropped",
    Content = "Total Cash Dropped: 0"
})

-- Helper function: Format a number with thousands separators.
local function formatNumber(n)
    local formatted = string.format("%d", n)
    local k
    repeat
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    until k == 0
    return formatted
end

-- Helper function: Convert a cash string into a full number.
local function parseCashValue(text)
    if not text then return 0 end
    text = text:gsub("[$,]", "")
    local value = tonumber(text)
    if value then return value end
    local numStr = text:match("([%d%.]+)%s*[kK]")
    if numStr then
        return tonumber(numStr) * 1000
    end
    numStr = text:match("([%d%.]+)%s*[mM]")
    if numStr then
        return tonumber(numStr) * 1000000
    end
    numStr = text:match("([%d%.]+)")
    if numStr then
        return tonumber(numStr)
    end
    return 0
end

-- Helper function: Get the numeric value from a MoneyDrop object.
local function getMoneyDropValue(moneyDrop)
    if not moneyDrop then return 0 end
    local billboardGui = moneyDrop:FindFirstChild("BillboardGui")
    if billboardGui then
        local textLabel = billboardGui:FindFirstChild("TextLabel")
        if textLabel then
            local text = textLabel.Text
            local parsed = parseCashValue(text)
            return parsed
        else
            warn("TextLabel not found in " .. moneyDrop:GetFullName())
        end
    else
        warn("BillboardGui not found in " .. moneyDrop:GetFullName())
    end
    return 0
end

-- Function to sum the cash from every MoneyDrop in Workspace.Ignored.Drop.
local function updateDroppedCashTotal()
    local total = 0
    local ignored = game.Workspace:FindFirstChild("Ignored")
    if ignored then
        local dropFolder = ignored:FindFirstChild("Drop")
        if dropFolder then
            for _, child in ipairs(dropFolder:GetChildren()) do
                if child:FindFirstChild("BillboardGui") then
                    total = total + getMoneyDropValue(child)
                end
            end
        else
            warn("Drop folder not found in Workspace.Ignored!")
        end
    else
        warn("Ignored folder not found in Workspace!")
    end
    return total
end

-- Continuously update the Status paragraph every 0.4 seconds.
coroutine.wrap(function()
    while true do
        local totalCash = updateDroppedCashTotal()
        statusParagraph:SetValue("Total Cash Dropped: " .. formatNumber(totalCash))
        wait(0.4)
    end
end)()

------------------------------------------------------------
-- POSITION UPDATE SYSTEM (not used for ATM locking anymore)
------------------------------------------------------------
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

------------------------------------------------------------
-- Noclip Functions
------------------------------------------------------------
local Noclip = nil
local Clip = nil

local function noclip()
    Clip = false
    local function Nocl()
        if not Clip and game.Players.LocalPlayer.Character then
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
        if not Clip and game.Players.LocalPlayer.Character then
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

------------------------------------------------------------
-- Core Functions
------------------------------------------------------------
local function CancelTweens()
    for _, tween in pairs(State.ActiveTweens) do
        pcall(function() tween:Cancel() end)
    end
    State.ActiveTweens = {}
end

local function getSpeed(distance)
    if distance > 150 then
        return 60
    elseif distance > 125 then
        return 55
    elseif distance > 100 then
        return 45
    elseif distance > 50 then
        return 30
    elseif distance > 25 then
        return 15
    elseif distance > 10 then
        return 8
    else
        return 6
    end
end

-- Modified MoveTo: When using Tween(slower), noclip is enabled during tweening.
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

------------------------------------------------------------
-- New Knife Purchase Function
------------------------------------------------------------
local function BuyKnife()
    local player = game.Players.LocalPlayer
    local existingKnife = player.Backpack:FindFirstChild("[Knife]") or (player.Character and player.Character:FindFirstChild("[Knife]"))
    if existingKnife then
        print("Knife already exists. Using the existing knife.")
        existingKnife.Parent = player.Character
        return true
    end

    local knifeShopItem = game.Workspace.Ignored.Shop["[Knife] - $164"]
    if knifeShopItem and knifeShopItem:FindFirstChild("ClickDetector") then
        print("Knife not in inventory, attempting to purchase...")
        fireclickdetector(knifeShopItem.ClickDetector, 4)
        local knifeTool
        for i = 2, 11 do
            knifeTool = player.Backpack:FindFirstChild("[Knife]") or (player.Character and player.Character:FindFirstChild("[Knife]"))
                      or player.Backpack:FindFirstChild("[Knife] - $164") or (player.Character and player.Character:FindFirstChild("[Knife] - $164"))
            if knifeTool then break end
            task.wait(0.5)
        end
        if knifeTool then
            if knifeTool.Name == "[Knife] - $164" then
                knifeTool.Name = "[Knife]"
            end
            knifeTool.Parent = player.Character
            return true
        else
            print("Knife not acquired after purchase attempt!")
            Library:Notify({Title = "Error", Content = "Knife not found in inventory after purchase!", Duration = 3})
            return false
        end
    else
        print("Knife or ClickDetector not found in shop!")
        Library:Notify({Title = "Error", Content = "Knife not found in Shop!", Duration = 3})
        return false
    end
end

------------------------------------------------------------
-- NEW: Rifle Purchase Function
------------------------------------------------------------
local function BuyRifle()
    local player = game.Players.LocalPlayer
    local existingRifle = player.Backpack:FindFirstChild("[Rifle]") or (player.Character and player.Character:FindFirstChild("[Rifle]"))
    if existingRifle then
        print("Rifle already exists. Using the existing rifle.")
        existingRifle.Parent = player.Character
        return true
    end

    local rifleShopItem = game.Workspace.Ignored.Shop["[Rifle] - $1694"]
    if rifleShopItem and rifleShopItem:FindFirstChild("ClickDetector") then
        print("Rifle not in inventory, attempting to purchase...")
        fireclickdetector(rifleShopItem.ClickDetector, 4)
        local rifleTool = nil
        for i = 2, 11 do
            rifleTool = player.Backpack:FindFirstChild("[Rifle]") or (player.Character and player.Character:FindFirstChild("[Rifle]"))
                        or player.Backpack:FindFirstChild("[Rifle] - $1694") or (player.Character and player.Character:FindFirstChild("[Rifle] - $1694"))
            if rifleTool then break end
            task.wait(0.5)
        end
        if rifleTool then
            if rifleTool.Name == "[Rifle] - $1694" then
                rifleTool.Name = "[Rifle]"
            end
            rifleTool.Parent = player.Character
            return true
        else
            print("Rifle not acquired after purchase attempt!")
            Library:Notify({Title = "Error", Content = "Rifle not found in inventory after purchase!", Duration = 3})
            return false
        end
    else
        print("Rifle or ClickDetector not found in shop!")
        Library:Notify({Title = "Error", Content = "Rifle not found in Shop!", Duration = 3})
        return false
    end
end

------------------------------------------------------------
-- Updated ATM Autofarm (integrated with Attack Method selection)
------------------------------------------------------------
local function RunATMAutofarm()
    if State.AttackMethod == "Knife" then
        local knifeCFrame = CFrame.new(-277.65, 23.849, -236)
        local tween = MoveTo(knifeCFrame)
        if tween then tween.Completed:Wait() end
        task.wait(0.5)
        
        if not BuyKnife() then
            State.ATMRunning = false
            clip()
            return
        end
    end

    local lastPunchTime = tick()
    while State.ATMRunning do
        local char = game.Players.LocalPlayer.Character
        if not char then
            task.wait(3)
            continue
        end

        local toolName = (State.AttackMethod == "Knife") and "[Knife]" or "Combat"
        local tool = char:FindFirstChild(toolName) or game.Players.LocalPlayer.Backpack:FindFirstChild(toolName)
        if not tool then
            Library:Notify({Title = "Error", Content = toolName.." tool missing!", Duration = 3})
            State.ATMRunning = false
            clip()
            break
        end
        tool.Parent = char

        -- In non-Knife mode, check that the Combat tool is equipped.
        if State.AttackMethod ~= "Knife" then
            if not (tool and tool.Parent == char) then
                local combatTool = char:FindFirstChild("Combat") or game.Players.LocalPlayer.Backpack:FindFirstChild("Combat")
                if combatTool then
                    combatTool.Parent = char
                    tool = combatTool
                else
                    Library:Notify({Title = "Error", Content = "Combat tool missing!", Duration = 3})
                    State.ATMRunning = false
                    clip()
                    break
                end
            end
        end

        local cashiers = game.Workspace.Cashiers:GetChildren()
        if #cashiers == 0 then
            task.wait(2.5)
            continue
        end

        for _, cashier in ipairs(cashiers) do
            if not State.ATMRunning then break end
            if not cashier:FindFirstChild("Open") then
                continue
            end

            farmNoclip()
            local targetPosition = cashier.Open.CFrame * CFrame.new(-1.4, 0, 3)
            local tween = MoveTo(targetPosition)
            if tween then tween.Completed:Wait() end

            clip()
            task.wait(0.5)

            local lockRunning = true
            local lockCoroutine = coroutine.create(function()
                while lockRunning do
                    local char = game.Players.LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = targetPosition
                    end
                    task.wait(0.5)
                end
            end)
            coroutine.resume(lockCoroutine)

            local numAttacks = (State.AttackMethod == "Knife") and 5 or 10
            local attackWait = (State.AttackMethod == "Knife") and 1 or 0.5
            for i = 1, numAttacks do
                if not State.ATMRunning then break end
                if State.AttackMethod ~= "Knife" then
                    if not (tool and tool.Parent == char) then
                        local combatTool = char:FindFirstChild("Combat") or game.Players.LocalPlayer.Backpack:FindFirstChild("Combat")
                        if combatTool then
                            combatTool.Parent = char
                            tool = combatTool
                        else
                            Library:Notify({Title = "Error", Content = "Combat tool missing!", Duration = 3})
                            State.ATMRunning = false
                            clip()
                            break
                        end
                    end
                end
                tool:Activate()
                lastPunchTime = tick()
                task.wait(attackWait)
            end

            lockRunning = false
            task.wait(3.4)
        end

        if State.ATMRunning and tick() - lastPunchTime > 3 then
            local allCashiers = game.Workspace.Cashiers:GetChildren()
            if #allCashiers > 0 and allCashiers[1]:FindFirstChild("Open") then
                local firstATMPosition = allCashiers[1].Open.CFrame * CFrame.new(0, 0, 3.5)
                local tween = MoveTo(firstATMPosition)
                if tween then tween.Completed:Wait() end
                task.wait(0.5)
                lastPunchTime = tick()
            end
        end

        task.wait(0.3)
    end

    if PositionUpdateConnection then
        PositionUpdateConnection:Disconnect()
    end
end

------------------------------------------------------------
-- Cash Aura
------------------------------------------------------------
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
        task.wait(0.35)
    end
end

------------------------------------------------------------
-- Cash Drop
------------------------------------------------------------
local function CashDrop()
    while State.CashDropActive do
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "10000")
        task.wait(5)
    end
end

------------------------------------------------------------
-- Cash ESP
------------------------------------------------------------
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

------------------------------------------------------------
-- Map Destruction
------------------------------------------------------------
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

------------------------------------------------------------
-- UI ELEMENTS FOR MAIN TAB
------------------------------------------------------------
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
    Default = 2,
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

------------------------------------------------------------
-- TELEPORT BUTTONS
------------------------------------------------------------
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

------------------------------------------------------------
-- PVP TAB: PLAYER DROPDOWN & AUTOKILL OPTIONS
------------------------------------------------------------
local pvpDropdown = Tabs.PVP:CreateDropdown("PVPDropdown", {
    Title = "Select Player",
    Description = "Choose a player from the lobby",
    Values = {},
    Multi = false,
    Default = 1,
})

local selectedPlayerName = nil
local function updatePvpDropdown()
    local players = game:GetService("Players"):GetPlayers()
    local options = {}
    for _, player in ipairs(players) do
        table.insert(options, player.Name)
    end
    if #options > 40 then
        while #options > 40 do
            table.remove(options, 41)
        end
    end
    pvpDropdown:SetValues(options)
end

updatePvpDropdown()

game:GetService("Players").PlayerAdded:Connect(function(player)
    updatePvpDropdown()
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    updatePvpDropdown()
end)

pvpDropdown:OnChanged(function(Value)
    selectedPlayerName = Value
    print("Player dropdown changed:", Value)
end)

local TweenService = game:GetService("TweenService")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")

local function TP2(P1)
    local Player = PlayersService.LocalPlayer
    if not Player.Character then return end
    local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    local Distance = (P1.Position - HumanoidRootPart.Position).Magnitude
    local Speed = 150
    
    local Tween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(Distance/Speed, Enum.EasingStyle.Linear),
        {CFrame = P1}
    )
    
    Tween:Play()
    
    if _G.Stop_Tween == true then
        Tween:Cancel()
    end
    
    _G.Clip = true
    wait(Distance/Speed)
    _G.Clip = false
end

-- Declare orbit parameter variables (default values)
local orbitSizeValue = 20
local orbitSpeedValue = 20

-- Updated createCircleAndOrbit using slider values
local function createCircleAndOrbit(targetPlayer)
    if not targetPlayer.Character then return end
    local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local baseRadius = orbitSizeValue
    local maxRadius = orbitSizeValue
    local segments = orbitSizeValue  -- number of segments equals orbit size
    local rotationSpeed = orbitSpeedValue
    local expansionSpeed = 0
    local circleParts = {}
    local rotationAngle = 0
    local currentRadius = baseRadius

    for i = 1, segments do
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.5, 0.5, 0.5)
        part.Shape = Enum.PartType.Ball
        part.Material = Enum.Material.Neon
        part.Color = Color3.new(1, 1, 1)
        part.Anchored = true
        part.CanCollide = false
        part.Parent = game.Workspace
        table.insert(circleParts, part)
    end

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not targetPlayer or not targetPlayer.Character or not rootPart then
            connection:Disconnect()
            for _, part in ipairs(circleParts) do
                part:Destroy()
            end
            return
        end

        rotationAngle = rotationAngle + rotationSpeed * math.pi / 180
        currentRadius = math.min(currentRadius + expansionSpeed, maxRadius)

        for i, part in ipairs(circleParts) do
            local angle = ((math.pi * 2) * (i / segments)) + rotationAngle
            local offset = Vector3.new(math.cos(angle) * currentRadius, 0, math.sin(angle) * currentRadius)
            part.Position = rootPart.Position + offset
        end

        if PlayersService.LocalPlayer.Character and PlayersService.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local playerRootPart = PlayersService.LocalPlayer.Character.HumanoidRootPart
            local orbitPosition = rootPart.Position + Vector3.new(
                math.cos(rotationAngle) * currentRadius,
                0,
                math.sin(rotationAngle) * currentRadius
            )
            playerRootPart.CFrame = CFrame.new(orbitPosition, rootPart.Position)
        end
    end)

    return function()
        connection:Disconnect()
        for _, part in ipairs(circleParts) do
            part:Destroy()
        end
    end
end

----------------------------------------------------------------
-- New Dropdown for Autokill Method in PVP Tab
----------------------------------------------------------------
local autokillMethodDropdown = Tabs.PVP:CreateDropdown("AutokillMethodDropdown", {
    Title = "Autokill Method",
    Description = "Select autokill method",
    Values = {"Orbit", "Crazy"},
    Multi = false,
    Default = 1,
})

local selectedAutokillMethod = "Orbit"
autokillMethodDropdown:OnChanged(function(val)
    selectedAutokillMethod = val
    print("Autokill method changed:", val)
end)

----------------------------------------------------------------
-- New Sliders for Orbit Parameters (placed above Autokill toggle)
----------------------------------------------------------------
local orbitSizeSlider = Tabs.PVP:CreateSlider("OrbitSizeSlider", {
    Title = "Orbit Size",
    Description = "Determines orbit base & max radius and number of segments.",
    Default = 20,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        orbitSizeValue = Value
        print("Orbit size changed:", Value)
    end,
})
orbitSizeSlider:OnChanged(function(Value)
    orbitSizeValue = Value
    print("Orbit size changed:", Value)
end)

local orbitSpeedSlider = Tabs.PVP:CreateSlider("OrbitSpeedSlider", {
    Title = "Orbit Speed",
    Description = "Determines rotation speed. Higher = more laggier and risk of getting kicked, recommended between 0-40.",
    Default = 20,
    Min = 0,
    Max = 75,
    Rounding = 1,
    Callback = function(Value)
        orbitSpeedValue = Value
        print("Orbit speed changed:", Value)
    end,
})
orbitSpeedSlider:OnChanged(function(Value)
    orbitSpeedValue = Value
    print("Orbit speed changed:", Value)
end)

----------------------------------------------------------------
-- New Toggle for Autokill with integrated noclip for autokill and Rifle purchase
----------------------------------------------------------------
local currentOrbitCleanup = nil
Tabs.PVP:CreateToggle("AutokillToggle", {
    Title = "Autokill",
    Default = false,
}):OnChanged(function(state)
    if state then
        local rifleShopItem = game.Workspace.Ignored.Shop["[Rifle] - $1694"]
        if rifleShopItem then
            local rifleCFrame = CFrame.new(-259.658, 54.363, -213.512)
            local tween = MoveTo(rifleCFrame)
            if tween then tween.Completed:Wait() end
            task.wait(1)
            if not BuyRifle() then
                clip()
                return
            end
        else
            print("Rifle shop item not found!")
            Library:Notify({Title = "Error", Content = "Rifle shop item not found!", Duration = 3})
            clip()
            return
        end

        noclip()
        if selectedAutokillMethod == "Orbit" then
            if selectedPlayerName then
                local targetPlayer = PlayersService:FindFirstChild(selectedPlayerName)
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    TP2(targetPlayer.Character.HumanoidRootPart.CFrame)
                    currentOrbitCleanup = createCircleAndOrbit(targetPlayer)
                else
                    print("Selected target is invalid for orbit.")
                end
            else
                print("No player selected for autokill orbit.")
            end
        elseif selectedAutokillMethod == "Crazy" then
            print("Crazy autokill method not implemented yet.")
        end
    else
        if currentOrbitCleanup then
            currentOrbitCleanup()
            currentOrbitCleanup = nil
        end
        clip()
    end
end)

------------------------------------------------------------
-- MISC TAB
------------------------------------------------------------
Tabs.Misc:CreateButton({
    Title = "Destroy Map",
    Callback = DestroyMap
})

------------------------------------------------------------
-- SETTINGS TAB (Interface & Config Sections)
------------------------------------------------------------
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

------------------------------------------------------------
-- Anti-Idle
------------------------------------------------------------
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

------------------------------------------------------------
-- Seat Removal
------------------------------------------------------------
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