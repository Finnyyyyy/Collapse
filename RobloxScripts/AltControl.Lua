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
    Prefix = ".",         -- Default command prefix (can be "?", ".", ",", "!" or "/")
    AltFps = 60,          -- Max FPS for alt accounts
    HostFps = 60,         -- Max FPS for the host
    CpuSaver = false,     -- Reserved for future use
    CashCounter = false,  -- Reserved for future use (only host can run this)
    antiAfk = true,       -- Enable anti-AFK
    ReactToCammands = true,-- Reserved for future use: alt reacts to host commands in chat
}

-- Allowed prefix characters
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

-- Helper: Toggle noclip (disable collisions) for all BaseParts in the character.
local function setCharacterNoclip(character, state)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- Spawn bank parts (very faint, 1x1x1)
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
        part.Transparency = 0.95  -- Very faint
        part.Name = "BankPart_" .. i
        part.Parent = bankFolder
        spawnedParts[i] = part
        print("Spawned BankPart_" .. i .. " at " .. tostring(pos))
    end

    return spawnedParts
end

-- Spawn club parts (very faint, 1x1x1)
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
        part.Transparency = 0.95  -- Very faint
        part.Name = "ClubPart_" .. i
        part.Parent = clubFolder
        spawnedParts[i] = part
        print("Spawned ClubPart_" .. i .. " at " .. tostring(pos))
    end

    return spawnedParts
end

-- Get this account's index in the Accounts table.
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

-- Tween the alt account to a target position with anti-fling.
local function tweenToPosition(targetPos)
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then 
        print("HumanoidRootPart not found!")
        return
    end

    -- Enable noclip while tweening.
    setCharacterNoclip(character, true)

    local distance = (targetPos - hrp.Position).Magnitude
    local speed = 50  -- studs per second
    local tweenTime = distance / speed

    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    print("Tweening to position " .. tostring(targetPos) .. " (Duration: " .. tweenTime .. " seconds).")

    -- Anti-fling: Reset velocities only if farther than 3 studs.
    local antiFlingConn
    antiFlingConn = RunService.Heartbeat:Connect(function()
        if hrp and (hrp.Position - targetPos).Magnitude > 3 then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        else
            if antiFlingConn then
                antiFlingConn:Disconnect()
            end
        end
    end)

    tween.Completed:Connect(function(status)
        if status == Enum.PlaybackState.Completed then
            print("Reached designated position!")
            setCharacterNoclip(character, false)
            if antiFlingConn then
                antiFlingConn:Disconnect()
            end
        end
    end)
end

-- Check if a character is an allowed prefix.
local function isAllowedPrefix(ch)
    for _, prefix in ipairs(allowedPrefixes) do
        if ch == prefix then
            return true
        end
    end
    return false
end

-- Process host commands (now case insensitive).
local function processHostCommand(msg)
    local firstChar = msg:sub(1, 1)
    if not isAllowedPrefix(firstChar) then
        return
    end

    -- Convert command text to lower case for matching.
    local command = msg:sub(2):lower()
    print("Command received (processed to lower-case): '" .. command .. "'")
    
    if command == "setup bank" then
        print("Processing 'setup Bank' command...")
        local spawnedParts = spawnBankParts()
        local accountIndex = getAccountIndex()
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            tweenToPosition(targetPos)
        else
            print("No matching bank part for account index " .. tostring(accountIndex) .. ".")
        end
    elseif command == "setup club" then
        print("Processing 'setup Club' command...")
        local spawnedParts = spawnClubParts()
        local accountIndex = getAccountIndex()
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            tweenToPosition(targetPos)
        else
            print("No matching club part for account index " .. tostring(accountIndex) .. ".")
        end
    end
end

-- Set up the host's chat listener (for alt accounts).
local function setupHostChatListener(hostPlayer)
    if hostPlayer then
        hostPlayer.Chatted:Connect(function(msg)
            if hostPlayer.UserId == Host.host then
                print("Host command received: " .. msg)
                processHostCommand(msg)
            end
        end)
        print("Chat listener set up for host.")
    end
end

-- Check player's role and set up chat listener and FPS settings.
local function checkPlayerRole()
    local userId = player.UserId
    if userId == Host.host then
        print("You are the host!")
        applyFpsSettings(true)
    else
        local isAccount = false
        for _, accountId in pairs(Accounts) do
            if userId == accountId then
                isAccount = true
                break
            end
        end

        if isAccount then
            print("You are an account and will follow the host!")
            applyFpsSettings(false)
            local hostPlayer = game.Players:GetPlayerByUserId(Host.host)
            if hostPlayer then
                setupHostChatListener(hostPlayer)
            else
                game.Players.PlayerAdded:Connect(function(p)
                    if p.UserId == Host.host then
                        setupHostChatListener(p)
                    end
                end)
            end
        else
            print("Your ID does not match with the Host or any Accounts.")
        end
    end
end

-- Run the role check and setup.
checkPlayerRole()
