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
    Prefix = "?",         -- Default command prefix ("?", can also be ".", ",", "!" or "/")
    AltFps = 60,          -- Max FPS for alt accounts
    HostFps = 60,         -- Max FPS for the host
    CpuSaver = false,     -- Reserved for future use
    CashCounter = false,  -- Reserved for future use (only host can run this)
    antiAfk = true,       -- Enable anti-AFK
    ReactToCammands = true,-- Reserved for future use: alt reacts to host commands in chat
}

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

-- Wait for the LocalPlayer to be available
local player = game.Players.LocalPlayer
while not player do
    wait()
    player = game.Players.LocalPlayer
end

-- Anti-AFK: if enabled, connect to the Idled event.
if Settings.antiAfk then
    player.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK triggered.")
    end)
end

-- Function to apply FPS settings
local function applyFpsSettings(isHost)
    if isHost then
        if Settings.HostFps then
            if setfpscap then
                setfpscap(Settings.HostFps)
                print("Host FPS set to " .. Settings.HostFps)
            else
                print("setfpscap function is not available.")
            end
        end
    else
        if Settings.AltFps then
            if setfpscap then
                setfpscap(Settings.AltFps)
                print("Alt FPS set to " .. Settings.AltFps)
            else
                print("setfpscap function is not available.")
            end
        end
    end
end

-- Function to spawn bank parts.
local function spawnBankParts()
    local Workspace = game:GetService("Workspace")
    local bankFolder = Workspace:FindFirstChild("BankParts")
    if not bankFolder then
        bankFolder = Instance.new("Folder")
        bankFolder.Name = "BankParts"
        bankFolder.Parent = Workspace
    else
        -- Clear out any old parts.
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
        part.Transparency = 0.1  -- Set the part to be barely visible
        part.Name = "BankPart_" .. i
        part.Parent = bankFolder
        spawnedParts[i] = part
        print("Spawned BankPart_" .. i .. " at " .. tostring(pos))
    end

    return spawnedParts
end

-- Function to get this account's index in the Accounts table.
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

-- Function to tween the alt account to its designated bank part.
local function tweenToBankPart(targetPos)
    local TweenService = game:GetService("TweenService")
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then 
        print("HumanoidRootPart not found!")
        return
    end

    local distance = (targetPos - hrp.Position).Magnitude
    local speed = 50  -- studs per second
    local tweenTime = distance / speed

    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    print("Tweening to position " .. tostring(targetPos) .. " (Duration: " .. tweenTime .. " seconds).")
    tween.Completed:Connect(function(status)
        if status == Enum.PlaybackState.Completed then
            print("Reached designated bank position!")
        end
    end)
end

-- Function to process host commands.
local function processHostCommand(msg)
    -- Check that the message starts with the defined prefix.
    if msg:sub(1, #Settings.Prefix) ~= Settings.Prefix then
        return
    end

    -- Remove the prefix.
    local command = msg:sub(#Settings.Prefix + 1)
    print("Command received (without prefix): '" .. command .. "'")
    
    if command == "setup Bank" then
        print("Processing 'setup Bank' command...")
        local spawnedParts = spawnBankParts()
        local accountIndex = getAccountIndex()
        if accountIndex and spawnedParts[accountIndex] then
            local targetPos = spawnedParts[accountIndex].Position + Vector3.new(0, 1.5, 0)
            tweenToBankPart(targetPos)
        else
            print("No matching bank part for account index " .. tostring(accountIndex) .. ".")
        end
    end
end

-- Function to set up the host's chat listener (for alt accounts).
local function setupHostChatListener(hostPlayer)
    if hostPlayer then
        hostPlayer.Chatted:Connect(function(msg)
            -- Only process commands if the sender is the host.
            if hostPlayer.UserId == Host.host then
                print("Host command received: " .. msg)
                processHostCommand(msg)
            end
        end)
        print("Chat listener set up for host.")
    end
end

-- Function to check the player's role and set up chat listener and FPS settings if needed.
local function checkPlayerRole()
    local userId = player.UserId
    if userId == Host.host then
        print("You are the host!")
        applyFpsSettings(true)
        -- Host can type commands directly.
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
