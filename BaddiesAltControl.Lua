local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = _G.Config
local hostId = config.host
local prefix = config.options.prefix
local feedback = config.options.Feedback

local commands = {
    airlock = function(player, distance)
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local newPosition = hrp.Position + Vector3.new(0, tonumber(distance) or 5, 0)
            hrp.CFrame = CFrame.new(newPosition)
            hrp.Anchored = true
            if feedback then
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Airlock enabled", "All")
            end
        end
    end,
    -- Add more commands here
}

local function isAlt(player)
    for _, altId in ipairs(config.Alts) do
        if player.UserId == altId then
            return true
        end
    end
    return false
end

local function executeCommand(command, ...)
    if commands[command] then
        commands[command](Players.LocalPlayer, ...)
    end
end

local function onChatted(message)
    if message:sub(1, #prefix) == prefix then
        local splitMessage = message:sub(#prefix + 1):split(" ")
        local command = splitMessage[1]
        local args = {table.unpack(splitMessage, 2)}
        executeCommand(command, table.unpack(args))
    end
end

if isAlt(Players.LocalPlayer) then
    setfpscap(config.fps)
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageObj)
        local speaker = Players:FindFirstChild(messageObj.FromSpeaker)
        if speaker and speaker.UserId == hostId then
            onChatted(messageObj.Message)
        end
    end)
else
    Players.LocalPlayer:Kick("ID not matched")
end
