-- Settings tables for Host and Accounts

local Host = {
    host = 5822052067  -- Replace with your desired host player ID.
}

local Accounts = {
    [1] = 7947479943,   -- Replace/add account IDs as needed.
    -- [2] = 12345678,
    -- [3] = 87654321,
}

 -- local Settings = {
  --  Prefix = ? --others are "." "," "!" "/"
 --   Setfpsto = 60 --set fps on alt accounts(can be changed within script)
 --   CpuSaver = false
 --   CashCounter = false --Can be enabled/disabled within script, only host can run this.
 --   antiAfk = true
 --   ReactToCammands = true --when activated/things change within the scripts, the alt account will say a message in chat, saying its been enabled/disabled.
-- }

-- Wait for the LocalPlayer to be available
local player = game.Players.LocalPlayer
while not player do
    wait()
    player = game.Players.LocalPlayer
end

-- Function to set up the host's chat listener
local function setupHostChatListener(hostPlayer)
    if hostPlayer then
        hostPlayer.Chatted:Connect(function(msg)
            print("Host said: " .. msg)
        end)
        print("Chat listener set up for host.")
    end
end

-- Function to check the player's role and set up chat listener if needed
local function checkPlayerRole()
    local userId = player.UserId
    if userId == Host.host then
        print("You are the host!")
        -- Host-specific code can be added here.
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
            -- Try to get the host player instance
            local hostPlayer = game.Players:GetPlayerByUserId(Host.host)
            if hostPlayer then
                setupHostChatListener(hostPlayer)
            else
                -- Wait for the host to join if they aren't present yet
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

-- Run the role check and setup
checkPlayerRole()
