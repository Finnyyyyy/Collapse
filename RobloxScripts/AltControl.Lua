------------------------------------------------
-- Settings and Account Tables
------------------------------------------------
local Host = {
    host = 5822052067  -- Host ID
}

local Accounts = {  -- Alt Account IDs
    [1] = 7947479943,
    [2] = 5822053302,
    [3] = 123456789,
    [4] = 123456789,
    [5] = 123456789,
    [6] = 123456789,
    [7] = 123456789,
    [8] = 123456789,
    [9] = 123456789,
    [10] = 123456789,
}

local Settings = {
    Prefix = "?",         -- Command prefix
    AltFps = 60,          -- Max FPS for alt accounts
    HostFps = 60,         -- Max FPS for host
    CpuSaver = false,
    CashCounter = false,  -- Only host can run this
    antiAfk = true,
    ReactToCammands = true,  -- When true, alts send chat messages in response
}

-- Global state
local State = {
    CashDropActive = false,
    CashDropTarget = nil,
    AirlockActive = false,
    AirlockBaseY = nil,
}

local allowedPrefixes = {"?", ".", ",", "!", "/"}

------------------------------------------------
-- Fallback Position Arrays (for setup fallback)
------------------------------------------------
local bankPositions = {
    Vector3.new(-384.5, 28.75, -318.5),
    Vector3.new(-368.5, 28.75, -318.5),
    Vector3.new(-384.5, 28.75, -308.5),
    Vector3.new(-368.5, 28.75, -308.5),
    Vector3.new(-384.5, 28.75, -298.5),
    Vector3.new(-368.5, 28.75, -298.5),
    Vector3.new(-384.5, 28.75, -288.5),
    Vector3.new(-368.5, 28.75, -288.5),
    Vector3.new(-384.5, 28.75, -278.5),
    Vector3.new(-368.5, 28.75, -278.5),
    Vector3.new(-384.5, 28.75, -268.5),
    Vector3.new(-368.5, 28.75, -268.5),
    Vector3.new(-384.5, 28.75, -258.5),
    Vector3.new(-368.5, 28.75, -258.5),
    Vector3.new(-384.5, 28.75, -248.5),
    Vector3.new(-368.5, 28.75, -248.5),
    Vector3.new(-384.5, 28.75, -238.5),
    Vector3.new(-368.5, 28.75, -238.5)
}

local clubPositions = {
    Vector3.new(-284.5, -2.46, -400.5),
    Vector3.new(-274.5, -2.46, -400.5),
    Vector3.new(-264.5, -2.46, -400.5),
    Vector3.new(-254.5, -2.46, -400.5),
    Vector3.new(-244.5, -2.46, -400.5),
    Vector3.new(-284.5, -2.46, -390.5),
    Vector3.new(-274.5, -2.46, -390.5),
    Vector3.new(-264.5, -2.46, -390.5),
    Vector3.new(-254.5, -2.46, -390.5),
    Vector3.new(-244.5, -2.46, -390.5),
    Vector3.new(-284.5, -2.46, -380.5),
    Vector3.new(-274.5, -2.46, -380.5),
    Vector3.new(-264.5, -2.46, -380.5),
    Vector3.new(-254.5, -2.46, -380.5),
    Vector3.new(-244.5, -2.46, -380.5),
    Vector3.new(-284.5, -2.46, -370.5),
    Vector3.new(-274.5, -2.46, -370.5),
    Vector3.new(-264.5, -2.46, -370.5),
    Vector3.new(-254.5, -2.46, -370.5),
    Vector3.new(-244.5, -2.46, -370.5),
    Vector3.new(-284.5, -2.46, -360.5),
    Vector3.new(-274.5, -2.46, -360.5),
    Vector3.new(-264.5, -2.46, -360.5),
    Vector3.new(-254.5, -2.46, -360.5),
    Vector3.new(-244.5, -2.46, -360.5)
}

local ufoPositions = {
    Vector3.new(29.5, 147.5, -667.5),
    Vector3.new(39.5, 147.5, -667.5),
    Vector3.new(49.5, 147.5, -667.5),
    Vector3.new(59.5, 147.5, -667.5),
    Vector3.new(29.5, 147.5, -677.5),
    Vector3.new(39.5, 147.5, -677.5),
    Vector3.new(49.5, 147.5, -677.5),
    Vector3.new(59.5, 147.5, -677.5),
    Vector3.new(29.5, 147.5, -687.5),
    Vector3.new(39.5, 147.5, -687.5),
    Vector3.new(49.5, 147.5, -687.5),
    Vector3.new(59.5, 147.5, -687.5),
    Vector3.new(29.5, 147.5, -697.5),
    Vector3.new(39.5, 147.5, -697.5),
    Vector3.new(49.5, 147.5, -697.5),
    Vector3.new(59.5, 147.5, -697.5)
}

------------------------------------------------
-- Wait for the LocalPlayer
------------------------------------------------
local player = game.Players.LocalPlayer
while not player do
    wait()
    player = game.Players.LocalPlayer
end

------------------------------------------------
-- Anti-AFK and FPS Settings
------------------------------------------------
if Settings.antiAfk then
    player.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK triggered.")
    end)
end

local function applyFpsSettings(isHost)
    if isHost then
        if Settings.HostFps and setfpscap then
            setfpscap(Settings.HostFps)
            print("Host FPS set to " .. Settings.HostFps)
        end
    else
        if Settings.AltFps and setfpscap then
            setfpscap(Settings.AltFps)
            print("Alt FPS set to " .. Settings.AltFps)
        end
    end
end

------------------------------------------------
-- Helper: Send Chat Message
------------------------------------------------
local function sendChatMessage(message)
    if Settings.ReactToCammands then
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

------------------------------------------------
-- Utility Functions
------------------------------------------------
local function getAccountIndex()
    if not player or not player.UserId then return 1 end
    for i, accountId in ipairs(Accounts) do
        if player.UserId == accountId then
            return i
        end
    end
    return 1
end

local function formatShort(n)
    if n >= 1e6 then
        return string.format("%.1fm", n/1e6)
    elseif n >= 1e3 then
        return string.format("%.1fk", n/1e3)
    else
        return tostring(n)
    end
end

local function parseCashValue(text)
    text = tostring(text):gsub("[$,]", ""):lower()
    local num = tonumber(text:match("%d+%.?%d*"))
    if not num then return 0 end
    
    if text:find("k") then
        return num * 1e3
    elseif text:find("m") then
        return num * 1e6
    end
    return num
end

------------------------------------------------
-- Cash Counter (Host Only)
------------------------------------------------
local function updateDroppedCashTotal()
    local total = 0
    if workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop") then
        for _, drop in ipairs(workspace.Ignored.Drop:GetChildren()) do
            if drop.Name == "MoneyDrop" then
                total += parseCashValue(drop.BillboardGui.TextLabel.Text)
            end
        end
    end
    return total
end

if player.UserId == Host.host then
    task.spawn(function()
        while true do
            local cash = updateDroppedCashTotal()
            print("Current ground cash:", formatShort(cash))
            task.wait(1.5)
        end
    end)
end

------------------------------------------------
-- Tweening Helper Function
------------------------------------------------
local function executeTween(targetPos, customDuration)
    local character = player.Character or player.CharacterAdded:Wait()
    local TweenService = game:GetService("TweenService")
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    local distance = (hrp.Position - targetPos).Magnitude
    local duration = customDuration or (distance / 150)  -- Default 150 studs/s
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
end

------------------------------------------------
-- Command Functions
------------------------------------------------
local function processSetupCommand(setupType)
    local idx = getAccountIndex()
    local folderName, partName, destName, fallbackPos = nil, nil, nil, nil
    
    if setupType == "bank" then
        folderName = "BankParts"
        partName = "BankPart_" .. idx
        destName = "Bank"
        fallbackPos = bankPositions[idx] or bankPositions[1]
    elseif setupType == "club" then
        folderName = "ClubParts"
        partName = "ClubPart_" .. idx
        destName = "Club"
        fallbackPos = clubPositions[idx] or clubPositions[1]
    elseif setupType == "ufo" then
        folderName = "UFOParts"
        partName = "UFOPart_" .. idx
        destName = "UFO"
        fallbackPos = ufoPositions[idx] or ufoPositions[1]
    end
    
    local part = workspace:FindFirstChild(folderName) and workspace[folderName]:FindFirstChild(partName)
    local basePos = part and part.Position or fallbackPos
    local targetPos = basePos + Vector3.new(0, 1.5, 0)
    
    sendChatMessage("Moving to " .. destName)
    executeTween(targetPos)
    sendChatMessage("Arrived at " .. destName)
end

local function lockedToPosition(targetPos)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    while State.CashDropActive do
        hrp.CFrame = CFrame.new(targetPos)
        task.wait()
    end
end

local function CashDrop()
    while State.CashDropActive do
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "15000")
        task.wait(5)
        if State.CashDropTarget then
            local currentCash = updateDroppedCashTotal()
            if currentCash >= State.CashDropTarget then
                State.CashDropActive = false
                sendChatMessage("Target reached: " .. formatShort(currentCash))
            end
        end
    end
end

local function startAirlock(offset)
    -- Clean previous state
    if State.AirlockActive then
        State.AirlockActive = false
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = false
        end
    end

    offset = tonumber(offset) or parseCashValue(offset)
    if not offset then return end
    offset = math.clamp(offset, -20, 20)

    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    
    -- Store base Y if first activation
    if not State.AirlockBaseY then
        State.AirlockBaseY = hrp.Position.Y
    end

    local targetPos = Vector3.new(
        hrp.Position.X,
        State.AirlockBaseY + offset,
        hrp.Position.Z
    )

    State.AirlockActive = true
    sendChatMessage("Airlock started")
    
    -- Tween at 75 studs/s
    executeTween(targetPos, math.abs(offset)/75)
    
    if State.AirlockActive then
        hrp.Anchored = true
    end
end

local function stopAirlock()
    State.AirlockActive = false
    State.AirlockBaseY = nil
    
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = false
    end
    sendChatMessage("Airlock disabled")
end

------------------------------------------------
-- Command Processor
------------------------------------------------
local function processHostCommand(msg)
    if not msg or #msg < 2 then return end
    local prefix = msg:sub(1,1)
    if not table.find(allowedPrefixes, prefix) then return end
    
    local command = msg:sub(2):lower()
    
    if command == "setup bank" then
        processSetupCommand("bank")
    elseif command == "setup club" then
        processSetupCommand("club")
    elseif command == "setup ufo" then
        processSetupCommand("ufo")
    elseif command:sub(1,4) == "drop" then
        local arg = command:match("drop%s+(.+)$")
        State.CashDropTarget = arg and parseCashValue(arg)
        State.CashDropActive = true
        spawn(function()
            lockedToPosition((player.Character or player.CharacterAdded:Wait()).HumanoidRootPart.Position)
        end)
        spawn(CashDrop)
        sendChatMessage("Drop started" .. (State.CashDropTarget and (" Target: " .. formatShort(State.CashDropTarget)) or ""))
    elseif command == "stop" then
        State.CashDropActive = false
        sendChatMessage("Drop stopped")
    elseif command:sub(1,7) == "airlock" then
        local offset = command:match("airlock%s+([%-%d%.]+)$")
        if offset then startAirlock(offset) end
    elseif command == "unairlock" then
        stopAirlock()
    end
end

------------------------------------------------
-- Chat Listener Setup
------------------------------------------------
if player.UserId ~= Host.host then
    local ChatEvents = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents")
    local hostName = game.Players:GetNameFromUserIdAsync(Host.host)
    
    ChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
        if messageData.FromSpeaker == hostName then
            processHostCommand(messageData.Message)
        end
    end)
end

------------------------------------------------
-- Initialization
------------------------------------------------
local function checkPlayerRole()
    if player.UserId == Host.host then
        print("Host initialized")
        applyFpsSettings(true)
    else
        print("Alt account initialized")
        applyFpsSettings(false)
    end
end

checkPlayerRole()
