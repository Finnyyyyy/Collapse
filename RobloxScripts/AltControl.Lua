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
    AirlockActive = false,  -- whether airlock is active
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
        else
            print("setfpscap function is not available.")
        end
    else
        if Settings.AltFps and setfpscap then
            setfpscap(Settings.AltFps)
            print("Alt FPS set to " .. Settings.AltFps)
        else
            print("setfpscap function is not available.")
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
    if type(text) ~= "string" then return 0 end
    text = text:match("^%s*(.-)%s*$") or ""
    if text == "" then return 0 end
    text = text:gsub("[$,]", "")
    local num = tonumber(text)
    if num then
        return num
    end
    local lowered = text:lower()
    if lowered:find("k") then
        local numericPart = lowered:gsub("k", "")
        local val = tonumber(numericPart)
        return val and (val * 1e3) or 0
    elseif lowered:find("m") then
        local numericPart = lowered:gsub("m", "")
        local val = tonumber(numericPart)
        return val and (val * 1e6) or 0
    end
    return 0
end

------------------------------------------------
-- Cash Counter (Host Only)
------------------------------------------------
local function updateDroppedCashTotal()
    local total = 0
    if workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop") then
        for _, drop in ipairs(workspace.Ignored.Drop:GetChildren()) do
            if drop.Name == "MoneyDrop" then
                total = total + parseCashValue(
                    drop:FindFirstChild("BillboardGui") and
                    drop.BillboardGui:FindFirstChild("TextLabel") and
                    drop.BillboardGui.TextLabel.Text or "0"
                )
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
    local duration = customDuration or (distance / 50)  -- default: speed = 50 studs/sec; for airlock we may supply customDuration
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
end

------------------------------------------------
-- Command Functions: Setup, Drop, Airlock, and Unairlock
------------------------------------------------
-- Setup commands: Tween to the position of an existing part (or fallback default).
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
    local part = nil
    if workspace:FindFirstChild(folderName) then
        part = workspace[folderName]:FindFirstChild(partName)
    end
    local basePos = part and part.Position or fallbackPos
    local targetPos = basePos + Vector3.new(0, 1.5, 0)
    sendChatMessage("Tweening to " .. destName)
    executeTween(targetPos)
    sendChatMessage("Reached destination: " .. destName)
    print("Setup command completed for " .. destName .. " at " .. tostring(targetPos))
end

-- Drop commands remain unchanged.
local function lockedToPosition(targetPos)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    while State.CashDropActive do
        hrp.CFrame = CFrame.new(targetPos)
        wait(0.1)
    end
    print("Player " .. player.Name .. " unlocked from locked position " .. tostring(targetPos))
end

local function CashDrop()
    while State.CashDropActive do
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "15000")
        task.wait(5)
        if State.CashDropTarget then
            local currentCash = updateDroppedCashTotal()
            if currentCash >= State.CashDropTarget then
                State.CashDropActive = false
                sendChatMessage("Drop target reached. Total dropped: " .. formatShort(currentCash))
                break
            end
        end
    end
end

-- Airlock command:
-- When ?airlock <offset> is issued, tween upward by that offset (using speed = 100 studs/sec)
-- Once reached, anchor the HumanoidRootPart to lock the position.
local function startAirlock(offset)
    offset = tonumber(offset) or parseCashValue(offset)
    if not offset then
        print("Invalid airlock offset")
        return
    end
    offset = math.min(offset, 20)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    local currentPos = hrp.Position
    local targetPos = Vector3.new(currentPos.X, currentPos.Y + offset, currentPos.Z)
    sendChatMessage("Airlock tweening to Y " .. targetPos.Y)
    -- Tween using speed 100 studs/sec (duration = offset/100)
    executeTween(targetPos, offset/100)
    sendChatMessage("Airlock engaged at Y " .. targetPos.Y)
    hrp.Anchored = true  -- Lock position without continuous teleporting
    State.AirlockActive = true
    State.AirlockTarget = targetPos
end

-- Unairlock: Remove the anchor from the HRP so movement resumes.
local function stopAirlock()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end
    State.AirlockActive = false
    State.AirlockTarget = nil
    sendChatMessage("Airlock disengaged.")
end

------------------------------------------------
-- Process Host Commands
------------------------------------------------
local function processHostCommand(msg)
    if not msg or #msg < 2 then return end
    local firstChar = msg:sub(1,1)
    if not table.find(allowedPrefixes, firstChar) then return end
    local command = msg:sub(2):lower()
    print("Received host command: '" .. command .. "'")
    
    if command == "setup bank" then
        processSetupCommand("bank")
    elseif command == "setup club" then
        processSetupCommand("club")
    elseif command == "setup ufo" then
        processSetupCommand("ufo")
    elseif command:sub(1,4) == "drop" then
        local arg = command:match("^drop%s+(%S+)$")
        if arg then
            local dropTarget = parseCashValue(arg)
            State.CashDropTarget = dropTarget
            sendChatMessage("Drop started. Value: " .. arg)
        else
            State.CashDropTarget = nil
            sendChatMessage("Drop started.")
        end
        State.CashDropActive = true
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        local lockedPos = hrp.Position
        spawn(function() lockedToPosition(lockedPos) end)
        spawn(function() CashDrop() end)
    elseif command == "stop" then
        State.CashDropActive = false
        sendChatMessage("Drop stopped.")
    elseif command:sub(1,7) == "airlock" then
        local offset = command:match("^airlock%s+(%S+)$")
        if offset then
            startAirlock(offset)
        else
            print("Airlock command requires an offset value.")
        end
    elseif command == "unairlock" then
        stopAirlock()
    end
end

------------------------------------------------
-- Chat Listener (Alts Only)
------------------------------------------------
if player.UserId ~= Host.host then
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
    local success, hostName = pcall(game.Players.GetNameFromUserIdAsync, game.Players, Host.host)
    if success and hostName then
        ChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
            if messageData and messageData.FromSpeaker and messageData.Message then
                if messageData.FromSpeaker:lower() == hostName:lower() then
                    print("Alt (" .. player.Name .. ") received host command: " .. messageData.Message)
                    processHostCommand(messageData.Message)
                end
            end
        end)
        print("Chat listener set up for alt " .. player.Name)
    else
        print("Failed to get host name for chat listening.")
    end
end

------------------------------------------------
-- End of Chat Listener
------------------------------------------------
local function checkPlayerRole()
    if player.UserId == Host.host then
        print("You are the host!")
        applyFpsSettings(true)
    else
        print("You are an account and will follow the host!")
        applyFpsSettings(false)
    end
end

checkPlayerRole()
