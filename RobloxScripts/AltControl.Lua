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
    Prefix = "?",         -- Default command prefix (example)
    AltFps = 60,          -- Max FPS for alt accounts
    HostFps = 60,         -- Max FPS for the host
    CpuSaver = false,     -- Reserved for future use
    CashCounter = false,  -- Reserved for future use (only host can run this)
    antiAfk = true,       -- Enable anti-AFK
    ReactToCammands = true, -- When true, alts react with chat messages
}

-- Global state for commands like CashDrop
local State = {
    CashDropActive = false,
    CashDropTarget = nil, -- target cash amount (if any) for the drop command
}

-- Allowed prefix characters (restored to the original list)
local allowedPrefixes = {"?", ".", ",", "!", "/"}

-- Bank part positions (ordered list)
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

-- Club part positions (ordered list)
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

-- UFO part positions (ordered list)
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

-- Wait for the LocalPlayer
local player = game.Players.LocalPlayer
while not player do
    wait()
    player = game.Players.LocalPlayer
end

-- Anti-AFK
if Settings.antiAfk then
    player.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK triggered.")
    end)
end

-- Apply FPS settings
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
-- Helper function to send chat messages (if ReactToCammands is true)
local function sendChatMessage(message)
    if Settings.ReactToCammands then
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

------------------------------------------------
-- Cash Counter Core Script (Simplified)
------------------------------------------------

-- Short-form formatter (e.g., 7100 becomes "7.1k", 1500000 becomes "1.5m")
local function formatShort(n)
    if n >= 1e6 then
        return string.format("%.1fm", n/1e6)
    elseif n >= 1e3 then
        return string.format("%.1fk", n/1e3)
    else
        return tostring(n)
    end
end

-- Convert cash text ($1.5k, 3m, etc.) to numerical value safely.
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

-- Get value from a MoneyDrop object
local function getMoneyDropValue(moneyDrop)
    return parseCashValue(
        moneyDrop:FindFirstChild("BillboardGui")
        and moneyDrop.BillboardGui:FindFirstChild("TextLabel")
        and moneyDrop.BillboardGui.TextLabel.Text or "0"
    )
end

-- Main cash calculation logic: sums up values from all MoneyDrop parts
local function updateDroppedCashTotal()
    local total = 0
    if workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop") then
        for _, drop in ipairs(workspace.Ignored.Drop:GetChildren()) do
            if drop.Name == "MoneyDrop" then
                total = total + getMoneyDropValue(drop)
            end
        end
    end
    return total
end

-- Live updates (runs every 1.5 seconds) only for the host.
if player.UserId == Host.host then
    task.spawn(function()
        while true do
            local cash = updateDroppedCashTotal()
            print("Current ground cash:", formatShort(cash))
            task.wait(1.5)
        end
    end)
end

-- Track collected cash (when money disappears)
if workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop") then
    workspace.Ignored.Drop.ChildRemoved:Connect(function(child)
        if child.Name == "MoneyDrop" then
            local collected = getMoneyDropValue(child)
            if player.UserId == Host.host then
                print("Collected:", formatShort(collected))
            end
        end
    end)
end

------------------------------------------------
-- Spawn Functions for parts
------------------------------------------------

-- Spawn bank parts (1x1x1, increased visibility with lower transparency)
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

-- Spawn club parts (1x1x1, increased visibility with lower transparency)
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

-- Spawn UFO parts (1x1x1, increased visibility with lower transparency)
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
-- Helper functions for character tweening and noclip
------------------------------------------------

-- Helper: Toggle noclip (disable collisions) for all BaseParts in the character.
local function setCharacterNoclip(character, state)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- Performs a single tween over the given duration (in seconds) to targetPos.
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
    tween.Completed:Wait()  -- Wait until the tween finishes
end

-- Repeatedly tween to targetPos every 0.5 seconds for a total of 1.5 seconds.
local function maintainTween(targetPos)
    local startTime = tick()
    while tick() - startTime < 1.5 do
        doTween(targetPos, 0.5)
        wait(0.1)
    end
end

-- Executes the setup command: enables noclip, repeatedly tweens, then disables noclip.
-- Now accepts a destinationName for chat feedback.
local function executeSetupCommand(targetPos, destinationName)
    local character = player.Character or player.CharacterAdded:Wait()
    sendChatMessage("Tweening to " .. destinationName)
    setCharacterNoclip(character, true)
    maintainTween(targetPos)
    setCharacterNoclip(character, false)
    sendChatMessage("Reached destination: " .. destinationName)
    print("Setup command completed for target " .. tostring(targetPos))
end

------------------------------------------------
-- New function to "lock" the player to a position --
------------------------------------------------
local function lockedToPosition(targetPos)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    -- Continuously force the HRP's CFrame to the target position while cash drop is active.
    while State.CashDropActive do
        hrp.CFrame = CFrame.new(targetPos)
        wait(0.1)
    end
    print("Player " .. player.Name .. " unlocked from locked position " .. tostring(targetPos))
end

------------------------------------------------
-- New CashDrop function to drop money repeatedly.
------------------------------------------------
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

------------------------------------------------
-- Process host commands (case insensitive).
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
        local accountIndex = nil
        for i, accountId in ipairs(Accounts) do
            if player.UserId == accountId then
                accountIndex = i
                print("Account index for UserId " .. player.UserId .. " is " .. i)
                break
            end
        end
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            executeSetupCommand(targetPos, "Bank")
        else
            print("No matching bank part for account index " .. tostring(accountIndex) .. ".")
        end

    elseif command == "setup club" then
        print("Processing 'setup club' command...")
        local spawnedParts = spawnClubParts()
        local accountIndex = nil
        for i, accountId in ipairs(Accounts) do
            if player.UserId == accountId then
                accountIndex = i
                print("Account index for UserId " .. player.UserId .. " is " .. i)
                break
            end
        end
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            executeSetupCommand(targetPos, "Club")
        else
            print("No matching club part for account index " .. tostring(accountIndex) .. ".")
        end

    elseif command == "setup ufo" then
        print("Processing 'setup ufo' command...")
        local spawnedParts = spawnUFOParts()
        local accountIndex = nil
        for i, accountId in ipairs(Accounts) do
            if player.UserId == accountId then
                accountIndex = i
                print("Account index for UserId " .. player.UserId .. " is " .. i)
                break
            end
        end
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            executeSetupCommand(targetPos, "UFO")
        else
            print("No matching UFO part for account index " .. tostring(accountIndex) .. ".")
        end

    elseif command:sub(1,4) == "drop" then
        print("Processing 'drop' command...")
        -- Use pattern to extract the argument after "drop"
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
        spawn(function()
            lockedToPosition(lockedPos)
        end)
        spawn(function()
            CashDrop()
        end)

    elseif command == "stop" then
        print("Processing 'stop' command...")
        State.CashDropActive = false
        sendChatMessage("Drop stopped.")
    end
end

------------------------------------------------
-- New chat listener using DefaultChatSystemChatEvents --
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
-- End of chat listener
------------------------------------------------

-- For the host account, just apply FPS settings.
local function checkPlayerRole()
    if player.UserId == Host.host then
        print("You are the host!")
        applyFpsSettings(true)
    else
        print("You are an account and will follow the host!")
        applyFpsSettings(false)
    end
end

-- Run the role check and setup.
checkPlayerRole()
