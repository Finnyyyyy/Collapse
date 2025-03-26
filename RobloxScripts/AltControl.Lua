-- Settings tables for Host and Accounts
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
    Prefix = "?",         -- Default command prefix
    AltFps = 60,          -- Max FPS for alt accounts
    HostFps = 60,         -- Max FPS for the host
    CpuSaver = false,     -- Reserved for future use
    CashCounter = false,  -- Reserved for future use (only host can run this)
    antiAfk = true,       -- Enable anti-AFK
    ReactToCommands = true,  -- Controls if accounts send chat messages
}

-- Global state for commands like CashDrop
local State = {
    CashDropActive = false
}

-- Allowed prefix characters
local allowedPrefixes = {"?", ".", ",", "!", "/"}

------------------------------------------------
-- Utility: Parse shorthand cash amount (e.g., "500k", "2.5m")
------------------------------------------------
local function parseCashString(str)
    local numberPart = tonumber(str:match("(%d+%.?%d*)"))
    if not numberPart then return 0 end
    local lowerStr = str:lower()
    if lowerStr:find("k") then
        return numberPart * 1000
    elseif lowerStr:find("m") then
        return numberPart * 1000000
    else
        return numberPart
    end
end

------------------------------------------------
-- MoneyDrop Total Calculation
-- Uses the exact path: game.Workspace.Ignored.Drop
-- Sums the values of all children named "MoneyDrop"
------------------------------------------------
local function getMoneyDropValue(moneyDrop)
    if not moneyDrop then return 0 end
    local billboardGui = moneyDrop:FindFirstChild("BillboardGui")
    if billboardGui then
        local textLabel = billboardGui:FindFirstChild("TextLabel")
        if textLabel then
            local text = textLabel.Text
            local parsed = parseCashString(text)
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
                if child.Name == "MoneyDrop" then
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

------------------------------------------------
-- Part Position Tables
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
-- Anti-AFK
------------------------------------------------
if Settings.antiAfk then
    player.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK triggered.")
    end)
end

------------------------------------------------
-- Apply FPS settings
------------------------------------------------
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
-- Chat Message Helper
------------------------------------------------
local function sendChatMessage(message)
    local ChatService = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
    if ChatService and ChatService:FindFirstChild("SayMessageRequest") then
        ChatService.SayMessageRequest:FireServer(message, "All")
        print("Chat message sent: " .. message)
    else
        print("Unable to send chat message: Chat service not found.")
    end
end

------------------------------------------------
-- Helper: Toggle noclip for character parts
------------------------------------------------
local function setCharacterNoclip(character, state)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

------------------------------------------------
-- Spawn Part Functions
------------------------------------------------
local function spawnBankParts()
    local Workspace = game:GetService("Workspace")
    local bankFolder = Workspace:FindFirstChild("BankParts")
    if not bankFolder then
        bankFolder = Instance.new("Folder")
        bankFolder.Name = "BankParts"
        bankFolder.Parent = Workspace
    else
        for _, part in pairs(bankFolder:GetChildren()) do
            part:Destroy()
        end
    end
    local spawnedParts = {}
    for i, pos in ipairs(bankPositions) do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1, 1, 1)
        part.Position = pos
        part.Anchored = true
        part.Transparency = 0.85
        part.Name = "BankPart_" .. i
        part.Parent = bankFolder
        spawnedParts[i] = part
        print("Spawned BankPart_" .. i .. " at " .. tostring(pos))
    end
    return spawnedParts
end

local function spawnClubParts()
    local Workspace = game:GetService("Workspace")
    local clubFolder = Workspace:FindFirstChild("ClubParts")
    if not clubFolder then
        clubFolder = Instance.new("Folder")
        clubFolder.Name = "ClubParts"
        clubFolder.Parent = Workspace
    else
        for _, part in pairs(clubFolder:GetChildren()) do
            part:Destroy()
        end
    end
    local spawnedParts = {}
    for i, pos in ipairs(clubPositions) do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1, 1, 1)
        part.Position = pos
        part.Anchored = true
        part.Transparency = 0.85
        part.Name = "ClubPart_" .. i
        part.Parent = clubFolder
        spawnedParts[i] = part
        print("Spawned ClubPart_" .. i .. " at " .. tostring(pos))
    end
    return spawnedParts
end

local function spawnUFOParts()
    local Workspace = game:GetService("Workspace")
    local ufoFolder = Workspace:FindFirstChild("UFOParts")
    if not ufoFolder then
        ufoFolder = Instance.new("Folder")
        ufoFolder.Name = "UFOParts"
        ufoFolder.Parent = Workspace
    else
        for _, part in pairs(ufoFolder:GetChildren()) do
            part:Destroy()
        end
    end
    local spawnedParts = {}
    for i, pos in ipairs(ufoPositions) do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1, 1, 1)
        part.Position = pos
        part.Anchored = true
        part.Transparency = 0.85
        part.Name = "UFOPart_" .. i
        part.Parent = ufoFolder
        spawnedParts[i] = part
        print("Spawned UFOPart_" .. i .. " at " .. tostring(pos))
    end
    return spawnedParts
end

------------------------------------------------
-- Get Account Index
------------------------------------------------
local function getAccountIndex()
    for i, accountId in ipairs(Accounts) do
        if player.UserId == accountId then
            print("Account index for UserId " .. player.UserId .. " is " .. i)
            return i
        end
    end
    print("UserId " .. player.UserId .. " is not found in the Accounts table.")
    return nil
end

------------------------------------------------
-- Tweening Functions
------------------------------------------------
local function doTween(targetPos, duration)
    local TweenService = game:GetService("TweenService")
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then 
        print("HumanoidRootPart not found!")
        return
    end
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
end

local function maintainTween(targetPos)
    local startTime = tick()
    while tick() - startTime < 1.5 do
        doTween(targetPos, 0.5)
        wait(0.1)
    end
end

local function executeSetupCommand(targetPos)
    local character = player.Character or player.CharacterAdded:Wait()
    setCharacterNoclip(character, true)
    maintainTween(targetPos)
    setCharacterNoclip(character, false)
    print("Setup command completed for target " .. tostring(targetPos))
end

------------------------------------------------
-- Lock Player to Position
------------------------------------------------
local function lockedToPosition(targetPos)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    while State.CashDropActive do
        hrp.CFrame = CFrame.new(targetPos)
        wait(0.1)
    end
    print("Player " .. player.Name .. " unlocked from locked position " .. tostring(targetPos))
end

------------------------------------------------
-- Cash Drop Functions
------------------------------------------------
local function CashDrop()
    while State.CashDropActive do
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "15000")
        task.wait(5)
    end
end

local function CashDropWithTarget(targetAmount)
    while State.CashDropActive do
        local totalCash = updateDroppedCashTotal()
        if totalCash >= targetAmount then
            print("Target reached: " .. totalCash)
            if Settings.ReactToCommands then
                sendChatMessage("Cash drop finished: Target reached (" .. totalCash .. ")")
            end
            State.CashDropActive = false
            break
        end
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "15000")
        task.wait(5)
    end
end

------------------------------------------------
-- Process Host Commands
------------------------------------------------
local function processHostCommand(msg)
    if not msg or #msg < 2 then return end
    local firstChar = msg:sub(1, 1)
    if not table.find(allowedPrefixes, firstChar) then
        return
    end
    local command = msg:sub(2):lower()
    print("Received host command: '" .. command .. "'")
    
    if command == "setup bank" then
        print("Processing 'setup bank' command...")
        local spawnedParts = spawnBankParts()
        local accountIndex = getAccountIndex()
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            if Settings.ReactToCommands then
                sendChatMessage("Tweening to bank")
            end
            executeSetupCommand(targetPos)
            if Settings.ReactToCommands then
                sendChatMessage("Reached destination for bank")
            end
        else
            print("No matching bank part for account index " .. tostring(accountIndex) .. ".")
        end
    elseif command == "setup club" then
        print("Processing 'setup club' command...")
        local spawnedParts = spawnClubParts()
        local accountIndex = getAccountIndex()
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            if Settings.ReactToCommands then
                sendChatMessage("Tweening to club")
            end
            executeSetupCommand(targetPos)
            if Settings.ReactToCommands then
                sendChatMessage("Reached destination for club")
            end
        else
            print("No matching club part for account index " .. tostring(accountIndex) .. ".")
        end
    elseif command == "setup ufo" then
        print("Processing 'setup ufo' command...")
        local spawnedParts = spawnUFOParts()
        local accountIndex = getAccountIndex()
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            if Settings.ReactToCommands then
                sendChatMessage("Tweening to ufo")
            end
            executeSetupCommand(targetPos)
            if Settings.ReactToCommands then
                sendChatMessage("Reached destination for ufo")
            end
        else
            print("No matching UFO part for account index " .. tostring(accountIndex) .. ".")
        end
    elseif command:sub(1,4) == "drop" then
        print("Processing 'drop' command...")
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        local lockedPos = hrp.Position

        local args = {}
        for word in command:gmatch("%S+") do
            table.insert(args, word)
        end

        if #args > 1 then
            local targetValueStr = args[2]
            local targetAmount = parseCashString(targetValueStr)
            if Settings.ReactToCommands then
                sendChatMessage("Cash Drop Started: Target " .. targetValueStr)
            end
            State.CashDropActive = true
            spawn(function() lockedToPosition(lockedPos) end)
            spawn(function() CashDropWithTarget(targetAmount) end)
        else
            if Settings.ReactToCommands then
                sendChatMessage("Cash Drop Started")
            end
            State.CashDropActive = true
            spawn(function() lockedToPosition(lockedPos) end)
            spawn(function() CashDrop() end)
        end
    elseif command == "stop" then
        print("Processing 'stop' command...")
        State.CashDropActive = false
        if Settings.ReactToCommands then
            sendChatMessage("The cash drop has been stopped")
        end
    end
end

------------------------------------------------
-- Chat Listener for Alt Accounts
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
        print("Listening for commands sent by host. " .. player.Name)
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
