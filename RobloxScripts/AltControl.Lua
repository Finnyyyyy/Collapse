-- Settings tables for Host and Accounts

local Host = {
    host = 5822052067  -- Host ID
}

local Accounts = {  -- Alt Account IDs
    [1] = 7947479943,   
    [2] = 123456789,
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

-- Bank position settings (for teleporting via command)
local bankPosition = Vector3.new(-373, 18.75, -346)

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

-- Function to tween the alt account to the bank
local function tweenToBank(character)
    local TweenService = game:GetService("TweenService")
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then 
        print("HumanoidRootPart not found!")
        return
    end
    
    local currentPos = hrp.Position
    local distance = (bankPosition - currentPos).Magnitude
    local speed = 50  -- studs per second
    local tweenTime = distance / speed
    
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(bankPosition)})
    
    tween:Play()
    tween.Completed:Connect(function(status)
        if status == Enum.PlaybackState.Completed then
            print("Reached Bank position!")
        end
    end)
    
    print("Tweening to Bank (Duration: " .. tweenTime .. " seconds).")
end

-- Function to handle host chat commands (only processed on alt accounts)
local function processHostCommand(msg)
    -- Check that the message starts with the defined prefix
    if msg:sub(1, #Settings.Prefix) ~= Settings.Prefix then
        return
    end

    -- Remove the prefix from the message
    local command = msg:sub(#Settings.Prefix + 1)
    
    -- Check for the specific command (case-sensitive as written)
    if command == "Tp Bank" then
        local character = player.Character or player.CharacterAdded:Wait()
        tweenToBank(character)
    end
end

-- Function to set up the host's chat listener (for alt accounts)
local function setupHostChatListener(hostPlayer)
    if hostPlayer then
        hostPlayer.Chatted:Connect(function(msg)
            -- Only process commands if the sender is the host
            if hostPlayer.UserId == Host.host then
                print("Host command received: " .. msg)
                processHostCommand(msg)
            end
        end)
        print("Chat listener set up for host.")
    end
end

-- Function to check the player's role and set up chat listener and FPS settings if needed
local function checkPlayerRole()
    local userId = player.UserId
    if userId == Host.host then
        print("You are the host!")
        applyFpsSettings(true)
        -- Host-specific command execution goes here.
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
            -- Try to get the host player instance.
            local hostPlayer = game.Players:GetPlayerByUserId(Host.host)
            if hostPlayer then
                setupHostChatListener(hostPlayer)
            else
                -- Wait for the host to join if they aren't present yet.
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
