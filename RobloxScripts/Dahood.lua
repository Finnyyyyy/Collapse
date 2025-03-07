local Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()


------------------------------------------------------------
-- STATE MANAGEMENT
------------------------------------------------------------
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

------------------------------------------------------------
-- CREATE WINDOW AND TABS (Selling appears above PVP; Selling tab icon is "banknote")
------------------------------------------------------------
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

local Tabs = {
    Status = Window:CreateTab({Title = "Status", Icon = "info"}),
    Main = Window:CreateTab({Title = "Main", Icon = "target"}),
    Teleports = Window:CreateTab({Title = "Teleports", Icon = "telescope"}),
    Selling = Window:CreateTab({Title = "Selling", Icon = "banknote"}),
    PVP = Window:CreateTab({Title = "PVP", Icon = "sword"}),
    Misc = Window:CreateTab({Title = "Misc", Icon = "book"}),
    Settings = Window:CreateTab({Title = "Settings", Icon = "settings"})
}

------------------------------------------------------------
-- STATUS TAB: RE-ORDERED STATUS INFORMATION
------------------------------------------------------------
local startTime = tick()
local timeParagraph = Tabs.Status:CreateParagraph("TimeInServerParagraph", {
    Title = "Time in Server",
    Content = "Time: 00:00:00"
})

local statusParagraph = Tabs.Status:CreateParagraph("DroppedCashParagraph", {
    Title = "Total Cash Dropped",
    Content = "Total Cash Dropped: 0"
})

local totalCashCollected = 0
local totalCashCollectedParagraph = Tabs.Status:CreateParagraph("TotalCashCollectedParagraph", {
    Title = "Total Cash Collected",
    Content = "Total Cash Collected: 0"
})

local tweenStatusParagraph = Tabs.Status:CreateParagraph("TweenStatusParagraph", {
    Title = "Tween Status",
    Content = "Tween Status: Idle"
})

local function formatNumber(n)
    local formatted = string.format("%d", n)
    local k
    repeat
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    until k == 0
    return formatted
end

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

-- Update Total Cash Dropped continuously
coroutine.wrap(function()
    while true do
        local totalCash = updateDroppedCashTotal()
        statusParagraph:SetValue("Total Cash Dropped: " .. formatNumber(totalCash))
        wait(0.4)
    end
end)()

-- Update Time in Server continuously
coroutine.wrap(function()
    while true do
        local elapsed = tick() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        local timeString = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        timeParagraph:SetValue("Time in Server: " .. timeString)
        wait(1)
    end
end)()

-- Update Tween Status continuously
coroutine.wrap(function()
    while true do
        local tweenActive = false
        for _, tween in pairs(State.ActiveTweens) do
            if tween.PlaybackState == Enum.PlaybackState.Playing then
                tweenActive = true
                break
            end
        end
        if tweenActive then
            tweenStatusParagraph:SetValue("Tween Status: Active")
        else
            tweenStatusParagraph:SetValue("Tween Status: Idle")
        end
        wait(0.5)
    end
end)()

-- Update Total Cash Collected continuously
coroutine.wrap(function()
    while true do
        totalCashCollectedParagraph:SetValue("Total Cash Collected: " .. formatNumber(totalCashCollected))
        wait(0.4)
    end
end)()

-- Listen for money being picked up (child removed from drop folder)
local dropFolder = game.Workspace:FindFirstChild("Ignored") and game.Workspace.Ignored:FindFirstChild("Drop")
if dropFolder then
    dropFolder.ChildRemoved:Connect(function(child)
        if child:FindFirstChild("BillboardGui") then
            local value = getMoneyDropValue(child)
            totalCashCollected = totalCashCollected + value
        end
    end)
end

------------------------------------------------------------
-- POSITION UPDATE SYSTEM
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
-- CORE FUNCTIONS
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

-- Travel Method: Moves while preserving current rotation.
local function MoveTo(targetCFrame)
    local char = game.Players.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    CancelTweens()
    
    local currentOrientation = hrp.CFrame - hrp.CFrame.Position
    local newTarget = currentOrientation + targetCFrame.Position

    if State.TravelMethod == "Tween(slower)" then
        noclip()
        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = getSpeed(distance)
        local tween = game:GetService("TweenService"):Create(
            hrp,
            TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
            {CFrame = newTarget}
        )
        table.insert(State.ActiveTweens, tween)
        tween:Play()
        tween.Completed:Connect(function()
            clip()
            for i, t in ipairs(State.ActiveTweens) do
                if t == tween then
                    table.remove(State.ActiveTweens, i)
                    break
                end
            end
        end)
        return tween
    else
        hrp.CFrame = newTarget
        return nil
    end
end

-- TP2 Teleport Function for Main Tab
local PlayersService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local function TP2(P1)
    local Player = PlayersService.LocalPlayer
    if not Player.Character then return end
    local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local newTarget = (hrp.CFrame - hrp.CFrame.Position) + P1.Position
    local Distance = (P1.Position - hrp.Position).Magnitude
    local Speed = 150
    
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear),
        {CFrame = newTarget}
    )
    table.insert(State.ActiveTweens, tween)
    tween:Play()
    tween.Completed:Connect(function()
         for i, t in ipairs(State.ActiveTweens) do
              if t == tween then
                   table.remove(State.ActiveTweens, i)
                   break
              end
         end
    end)
    
    if _G.Stop_Tween == true then
        tween:Cancel()
    end
    
    _G.Clip = true
    wait(Distance / Speed)
    _G.Clip = false
end

------------------------------------------------------------
-- NEW: KNIFE PURCHASE FUNCTION
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
-- NEW: RIFLE PURCHASE FUNCTION
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
-- UPDATED ATM AUTOFARM (integrated with Attack Method selection)
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
            task.wait(1)
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
                    task.wait(1)
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

        if State.ATMRunning and tick() - lastPunchTime > 5 then
            local allCashiers = game.Workspace.Cashiers:GetChildren()
            if #allCashiers > 0 and allCashiers[1]:FindFirstChild("Open") then
                local firstATMPosition = allCashiers[1].Open.CFrame * CFrame.new(-1.4, 0, 3)
                local tween = MoveTo(firstATMPosition)
                if tween then tween.Completed:Wait() end
                task.wait(0.5)
                lastPunchTime = tick()
            end
        end

        task.wait(0.5)
    end

    if PositionUpdateConnection then
        PositionUpdateConnection:Disconnect()
    end
end

------------------------------------------------------------
-- CASH AURA
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
        task.wait(0.425)
    end
end

------------------------------------------------------------
-- CASH DROP
------------------------------------------------------------
local function CashDrop()
    while State.CashDropActive do
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "15000")
        task.wait(5)
    end
end

------------------------------------------------------------
-- CASH ESP (CHAMS + VALUE DISPLAY)
------------------------------------------------------------
local cashESPConnection = nil

local function applyCashESPToMoneyDrop(inst)
    if inst.Name == "MoneyDrop" then
         if not inst:FindFirstChild("CashESPHighlight") then
              local highlight = Instance.new("Highlight")
              highlight.Name = "CashESPHighlight"
              highlight.FillColor = Color3.fromRGB(0,255,0)
              highlight.OutlineColor = Color3.fromRGB(0,200,0)
              highlight.FillTransparency = 0.5
              highlight.OutlineTransparency = 0
              highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
              highlight.Adornee = inst
              highlight.Parent = inst
         end
         if not inst:FindFirstChild("CashESPBillboard") then
              local billboard = Instance.new("BillboardGui")
              billboard.Name = "CashESPBillboard"
              billboard.Adornee = inst
              billboard.AlwaysOnTop = true
              billboard.Size = UDim2.new(0, 128, 0, 50)
              billboard.StudsOffset = Vector3.new(0, 2, 0)
              billboard.Parent = inst
              
              local textLabel = Instance.new("TextLabel")
              textLabel.Name = "CashESPText"
              textLabel.BackgroundTransparency = 1
              textLabel.TextColor3 = Color3.fromRGB(255,255,255)
              textLabel.TextScaled = false
              textLabel.TextSize = 12       
              textLabel.Size = UDim2.new(1,0,1,0)
              textLabel.Text = "Value: " .. formatNumber(getMoneyDropValue(inst))
              textLabel.Parent = billboard
              
              coroutine.wrap(function()
                  while inst.Parent do
                      if textLabel and textLabel.Parent then
                          textLabel.Text = "Value: " .. formatNumber(getMoneyDropValue(inst))
                      end
                      wait(0.5)
                  end
              end)()
         end
    end
end

local function ToggleCashESP(state)
    local dropFolder = game.Workspace:FindFirstChild("Ignored") and game.Workspace.Ignored:FindFirstChild("Drop")
    if not dropFolder then return end

    if state then
        for _, money in ipairs(dropFolder:GetChildren()) do
            applyCashESPToMoneyDrop(money)
        end
        cashESPConnection = dropFolder.ChildAdded:Connect(function(child)
            applyCashESPToMoneyDrop(child)
        end)
    else
        if cashESPConnection then
            cashESPConnection:Disconnect()
            cashESPConnection = nil
        end
        for _, money in ipairs(dropFolder:GetChildren()) do
            if money:FindFirstChild("CashESPHighlight") then
                money.CashESPHighlight:Destroy()
            end
            if money:FindFirstChild("CashESPBillboard") then
                money.CashESPBillboard:Destroy()
            end
        end
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

Tabs.Main:CreateToggle("Cash_ESP", {
    Title = "Cash ESP",
    Default = false
}):OnChanged(function(state)
    ToggleCashESP(state)
end)

Tabs.Main:CreateButton({
    Title = "Collect all money",
    Description = "Tween/Teleport to all MoneyDrop objects using a fixed speed of 60 studs/sec. Cash Aura must be active.",
    Callback = function()
        Window:Dialog({
            Title = "KICK/DEATH RISKKK!!, proceed?",
            Content = "Collects all MoneyDrop objects available when the button is pressed. Cash Aura must be active.",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        print("Collecting cash...")
                        local dropFolder = game.Workspace:FindFirstChild("Ignored") and game.Workspace.Ignored:FindFirstChild("Drop")
                        if dropFolder then
                            local TweenService = game:GetService("TweenService")
                            noclip()
                            while #dropFolder:GetChildren() > 0 do
                                for _, drop in ipairs(dropFolder:GetChildren()) do
                                    if drop.Name == "MoneyDrop" and drop.Parent then
                                        local char = game.Players.LocalPlayer.Character
                                        if not char or not char:FindFirstChild("HumanoidRootPart") then
                                            continue
                                        end
                                        local hrp = char.HumanoidRootPart
                                        local targetPos = drop.CFrame * CFrame.new(0, 1, 0)
                                        local currentYaw = math.atan2(hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Z)
                                        local targetCFrame = CFrame.new(targetPos.Position) * CFrame.Angles(0, currentYaw, 0)
                                        local distance = (hrp.Position - targetPos.Position).Magnitude
                                        local duration = distance / 500
                                        local tween = TweenService:Create(
                                            hrp,
                                            TweenInfo.new(duration, Enum.EasingStyle.Linear),
                                            {CFrame = targetCFrame}
                                        )
                                        tween:Play()
                                        tween.Completed:Wait()
                                        task.wait(5)
                                    end
                                end
                                wait(5)
                            end
                            clip()
                        else
                            print("Drop folder not found!")
                        end
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        print("Cash collection cancelled.")
                    end
                }
            }
        })
    end
})

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

local function TP2(P1)
    local Player = game:GetService("Players").LocalPlayer
    if not Player.Character then return end
    local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local newTarget = (hrp.CFrame - hrp.CFrame.Position) + P1.Position
    local Distance = (P1.Position - hrp.Position).Magnitude
    local Speed = 150
    
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear),
        {CFrame = newTarget}
    )
    table.insert(State.ActiveTweens, tween)
    tween:Play()
    tween.Completed:Connect(function()
         for i, t in ipairs(State.ActiveTweens) do
              if t == tween then
                   table.remove(State.ActiveTweens, i)
                   break
              end
         end
    end)
    
    if _G.Stop_Tween == true then
        tween:Cancel()
    end
    
    _G.Clip = true
    wait(Distance / Speed)
    _G.Clip = false
end

-- Declare orbit parameter variables
local orbitSizeValue = 20
local orbitSpeedValue = 20

local function createCircleAndOrbit(targetPlayer)
    if not targetPlayer.Character then return end
    local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local baseRadius = orbitSizeValue
    local maxRadius = orbitSizeValue
    local segments = orbitSizeValue
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
    connection = game:GetService("RunService").RenderStepped:Connect(function()
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

        if game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local playerRootPart = game:GetService("Players").LocalPlayer.Character.HumanoidRootPart
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
-- NEW Dropdown for Autokill Method in PVP Tab
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
-- New Sliders for Orbit Parameters (above Autokill toggle)
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

------------------------------------------------------------
-- NEW: AUTOKILL TOGGLE (KILL ALL)
------------------------------------------------------------
local currentOrbitCleanup = nil
Tabs.PVP:CreateToggle("AutokillToggle", {
    Title = "Autokill",
    Default = false,
}):OnChanged(function(state)
    if state then
        -- Enable noclip specifically for autokill
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
        -- Disable autokill-specific noclip by re-enabling collisions
        clip()
    end
end)


------------------------------------------------------------
-- NEW: SILENT AIM & FOV OPTIONS (PVP TAB)
------------------------------------------------------------
local silentAimToggle = Tabs.PVP:CreateToggle("SilentAimToggle", {
    Title = "Silent Aim",
    Default = false
})
local silentAimDistanceSlider = Tabs.PVP:CreateSlider("SilentAimDistanceSlider", {
    Title = "Distance",
    Description = "Max world distance for silent aim (5-500)",
    Default = 100,
    Min = 5,
    Max = 500,
    Rounding = 1,
})
local fovToggle = Tabs.PVP:CreateToggle("FOVToggle", {
    Title = "FOV",
    Default = false
})
local fovSizeSlider = Tabs.PVP:CreateSlider("FOVSizeSlider", {
    Title = "FOV Size",
    Description = "Radius of the FOV circle (10-750)",
    Default = 100,
    Min = 10,
    Max = 750,
    Rounding = 1,
})
local fovPlacementDropdown = Tabs.PVP:CreateDropdown("FOVPlacementDropdown", {
    Title = "FOV Placement",
    Values = {"Fixed", "Mouse"},
    Multi = false,
    Default = 1,
})

getgenv().silentaim_settings = getgenv().silentaim_settings or {}
getgenv().silentaim_settings.enabled = false
getgenv().silentaim_settings.distance = 100           -- world distance threshold
getgenv().silentaim_settings.fov = 100                -- silent aim boundary circle radius when FOV toggle is off
getgenv().silentaim_settings.fovtoggle = false
getgenv().silentaim_settings.fovsize = 100            -- radius for FOV circle when toggle is on
getgenv().silentaim_settings.fovPlacement = "Fixed"   -- "Fixed" or "Mouse"
getgenv().silentaim_settings.hitbox = "Head"          -- target hitbox

silentAimToggle:OnChanged(function(state)
    getgenv().silentaim_settings.enabled = state
end)

silentAimDistanceSlider:OnChanged(function(value)
    getgenv().silentaim_settings.distance = value
end)

fovToggle:OnChanged(function(state)
    getgenv().silentaim_settings.fovtoggle = state
end)

fovSizeSlider:OnChanged(function(value)
    getgenv().silentaim_settings.fovsize = value
end)

fovPlacementDropdown:OnChanged(function(value)
    getgenv().silentaim_settings.fovPlacement = value
end)

-- Create Drawing objects for the two circles
local UserInputService = game:GetService("UserInputService")
local CurrentCamera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Silent Aim circle: fixed at center, fully transparent
local silentAimCircle = Drawing.new("Circle")
silentAimCircle.Visible = false
silentAimCircle.Thickness = 1
silentAimCircle.Color = Color3.fromRGB(255, 255, 255)
silentAimCircle.Transparency = 1
silentAimCircle.Filled = false
silentAimCircle.Radius = getgenv().silentaim_settings.fov

-- FOV circle: visible when FOV toggle is on
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 0.5
fovCircle.Filled = false
fovCircle.Radius = getgenv().silentaim_settings.fovsize

local function WorldToScreen(position)
    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(position)
    return {Position = Vector2.new(screenPos.X, screenPos.Y), OnScreen = onScreen}
end

-- Get the closest player within the FOV and distance threshold
local SilentAimTarget = nil
local function GetClosestPlayer()
    local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X/2, CurrentCamera.ViewportSize.Y/2)
    local closestPlayer = nil
    local shortestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if getgenv().silentaim_settings.teamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            local targetPart = player.Character:FindFirstChild(getgenv().silentaim_settings.hitbox)
            if targetPart then
                local screenPos = WorldToScreen(targetPart.Position)
                if screenPos.OnScreen then
                    local dist = (screenPos.Position - screenCenter).Magnitude
                    local radius = getgenv().silentaim_settings.fovtoggle and getgenv().silentaim_settings.fovsize or getgenv().silentaim_settings.fov
                    if dist <= radius and (targetPart.Position - CurrentCamera.CFrame.Position).Magnitude <= getgenv().silentaim_settings.distance then
                        if dist < shortestDist then
                            shortestDist = dist
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Update circles and target every RenderStepped
game:GetService("RunService").RenderStepped:Connect(function()
    if getgenv().silentaim_settings.fovtoggle then
        if getgenv().silentaim_settings.fovPlacement == "Mouse" then
            fovCircle.Position = UserInputService:GetMouseLocation()
        else
            fovCircle.Position = Vector2.new(CurrentCamera.ViewportSize.X/2, CurrentCamera.ViewportSize.Y/2)
        end
        fovCircle.Radius = getgenv().silentaim_settings.fovsize
        fovCircle.Visible = true
        silentAimCircle.Visible = false
    else
        fovCircle.Visible = false
        silentAimCircle.Position = Vector2.new(CurrentCamera.ViewportSize.X/2, CurrentCamera.ViewportSize.Y/2)
        silentAimCircle.Radius = getgenv().silentaim_settings.fov
        silentAimCircle.Visible = getgenv().silentaim_settings.enabled
    end
    if getgenv().silentaim_settings.enabled then
        SilentAimTarget = GetClosestPlayer()
    else
        SilentAimTarget = nil
    end
end)

-- New hook method: override workspace.Raycast using hookfunction (or direct assignment)
local oldRaycast
if hookfunction then
    oldRaycast = hookfunction(workspace.Raycast, newcclosure(function(origin, direction, params, ignoreList)
        if getgenv().silentaim_settings.enabled and SilentAimTarget and SilentAimTarget.Character then
            local targetPart = SilentAimTarget.Character:FindFirstChild(getgenv().silentaim_settings.hitbox)
            if targetPart then
                local newDirection = (targetPart.Position - origin).Unit * 1000
                direction = newDirection
            end
        end
        return oldRaycast(origin, direction, params, ignoreList)
    end))
else
    oldRaycast = workspace.Raycast
    workspace.Raycast = newcclosure(function(origin, direction, params, ignoreList)
        if getgenv().silentaim_settings.enabled and SilentAimTarget and SilentAimTarget.Character then
            local targetPart = SilentAimTarget.Character:FindFirstChild(getgenv().silentaim_settings.hitbox)
            if targetPart then
                local newDirection = (targetPart.Position - origin).Unit * 1000
                direction = newDirection
            end
        end
        return oldRaycast(origin, direction, params, ignoreList)
    end)
end

------------------------------------------------------------
-- SELLING TAB FUNCTIONS (NEW)
------------------------------------------------------------
local sellingDropdown = Tabs.Selling:CreateDropdown("PlayerPositionDropdown", {
    Title = "Player Position",
    Values = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
    Multi = false,
    Default = 1,
})
local selectedSellingPosition = "1"
sellingDropdown:OnChanged(function(value)
    selectedSellingPosition = value
    print("Selling dropdown changed:", value)
end)

local sellingPositions = {
    [1] = Vector3.new(-368.5, 27.75, -316.5),
    [2] = Vector3.new(-386.5, 27.75, -316.5),
    [3] = Vector3.new(-368.5, 27.75, -308.5),
    [4] = Vector3.new(-386.5, 27.75, -308.5),
    [5] = Vector3.new(-368.5, 27.75, -300.5),
    [6] = Vector3.new(-386.5, 27.75, -300.5),
    [7] = Vector3.new(-368.5, 27.75, -292.5),
    [8] = Vector3.new(-386.5, 27.75, -292.5),
    [9] = Vector3.new(-368.5, 27.75, -284.5),
    [10] = Vector3.new(-386.5, 27.75, -284.5),
}

local sellingParts = {}
local partsSpawned = false

local lockActive = false
local lockConnection = nil
local lockedPosition = nil

Tabs.Selling:CreateButton({
    Title = "Setup Position",
    Callback = function()
        local selectedIndex = tonumber(selectedSellingPosition) or 1

        if not partsSpawned then
            for i = 1, 10 do
                local pos = sellingPositions[i]
                local part = Instance.new("Part")
                part.Size = Vector3.new(1, 1, 1)
                part.Anchored = true
                part.Transparency = 0.9
                part.CFrame = CFrame.new(pos)
                part.Parent = game.Workspace
                sellingParts[i] = part
            end
            partsSpawned = true
        end

        local targetPart = sellingParts[selectedIndex]
        local player = game.Players.LocalPlayer
        if targetPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local targetCFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
            local distance = (hrp.Position - targetCFrame.Position).Magnitude
            local tween = TweenService:Create(hrp, TweenInfo.new(distance / 75, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
            table.insert(State.ActiveTweens, tween)
            tween:Play()
            tween.Completed:Connect(function()
                for i, t in ipairs(State.ActiveTweens) do
                    if t == tween then
                        table.remove(State.ActiveTweens, i)
                        break
                    end
                end
            end)
            tween.Completed:Wait()
            if lockActive then
                lockedPosition = player.Character.HumanoidRootPart.CFrame
            end
        else
            Library:Notify({Title = "Error", Content = "Player or target part not found!", Duration = 3})
        end
    end
})

Tabs.Selling:CreateToggle("Lock_Position", {
    Title = "Lock Position",
    Default = false
}):OnChanged(function(state)
    local player = game.Players.LocalPlayer
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if state then
        if hrp then
            lockedPosition = hrp.CFrame
            originalAnchored = hrp.Anchored
            hrp.Anchored = true
            lockActive = true
            lockConnection = coroutine.create(function()
                while lockActive do
                    wait(3)
                    if not lockActive then break end
                    local offset = Vector3.new(0, 0, -0.8)
                    local tween1 = TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = lockedPosition * CFrame.new(offset)})
                    tween1:Play()
                    tween1.Completed:Wait()
                    local tween2 = TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = lockedPosition})
                    tween2:Play()
                    tween2.Completed:Wait()
                end
            end)
            coroutine.resume(lockConnection)
        end
    else
        lockActive = false
        if hrp then
            hrp.Anchored = originalAnchored or false
        end
        lockConnection = nil
    end
end)

Tabs.Selling:CreateToggle("Cash_Drop", {
    Title = "Cash Drop", 
    Default = false
}):OnChanged(function(state)
    State.CashDropActive = state
    if state then
        coroutine.wrap(CashDrop)()
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
-- ANTI-IDLE
------------------------------------------------------------
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

------------------------------------------------------------
-- SEAT REMOVAL
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