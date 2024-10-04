--[[
    Complete Roblox Script with Fluent GUI
    Features:
    - Autofarm Toggle
    - Cash Aura Toggle
    - Box ESP Toggle (Disabled by default)
    - Health ESP Toggle (Disabled by default)
    - Name ESP Toggle (Disabled by default)
    - Tracers Toggle (Disabled by default)
    - Settings and Save Manager
    Author: Finny<3
--]]

-- Load Fluent and its Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create the Fluent Window
local Window = Fluent:CreateWindow({
    Title = "AstroClient-Baddies",
    SubTitle = "Made by Finny<3",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main" }),
    Visuals = Window:AddTab({ Title = "Visuals" }),
    Settings = Window:AddTab({ Title = "Settings" })
}

-- Initialize Toggle States
local autofarmEnabled = false
local cashAuraEnabled = false
local boxESPEnabled = false -- Disabled by default
local healthESPEnabled = false -- Disabled by default
local nameESPEnabled = false -- Disabled by default
local tracersEnabled = false -- Disabled by default
local skeletonESPEnabled = false -- New: Disabled by default

-- ESP Configuration Table
local Config = {
    -- Box Settings
    Box = true, -- Enable or disable the box around players
    BoxColor = Color3.fromRGB(255, 255, 255), -- Color of the box border (white)
    BoxThickness = 1, -- Thickness of the box border

    -- Box Outline Settings
    BoxOutline = true, -- Enable or disable the box outline
    BoxOutlineColor = Color3.fromRGB(255, 255, 255), -- Color of the box outline (white)
    BoxOutlineThickness = 1, -- Thickness of the box outline border

    -- Health Bar Settings
    HealthBar = true, -- Enable or disable the health bar
    HealthBarSide = "Left", -- Side of the box where the health bar appears ("Left", "Bottom", "Right")

    -- Name Display Settings
    Names = false, -- Disable the name display by default
    NamesColor = Color3.fromRGB(255, 255, 255), -- Color of the name text (white)
    NamesOutline = true, -- Enable or disable the outline around the name text
    NamesOutlineColor = Color3.fromRGB(0, 0, 0), -- Color of the name text outline (black)
    NamesFont = 2, -- Font style (0: SciFi, 1: System, 2: Parchment, 3: SourceSans)
    NamesSize = 13, -- Size of the name text

    -- Tracer Settings
    Tracers = false, -- Disable tracers by default
    TracerColor = Color3.fromRGB(255, 255, 255), -- Changed to white
    TracerThickness = 1.4, -- Thickness of the tracers
    TracerTransparency = 1, -- Transparency of the tracers (1: Fully Visible, 0: Invisible)

     -- Skeleton Settings (New)
     Skeleton = false,
     SkeletonColor = Color3.fromRGB(255, 255, 255),
     SkeletonThickness = 1
}

-- Add Toggles to Main Tab
local AutofarmToggle = Tabs.Main:AddToggle("AutofarmToggle", {
    Title = "Autofarm (Enable Punch before toggling)",
    Default = false
})

local CashAuraToggle = Tabs.Main:AddToggle("CashAuraToggle", {
    Title = "Cash Aura",
    Default = false, -- Disabled by default
    Callback = function(value)
        cashAuraEnabled = value
        getgenv().cashAura = cashAuraEnabled

        if cashAuraEnabled and not getgenv().cashAuraRunning then
            getgenv().cashAuraRunning = true
            -- Start Cash Aura in a separate thread to prevent blocking
            spawn(function()
                startCashAura()
                getgenv().cashAuraRunning = false
            end)
        elseif not cashAuraEnabled and getgenv().cashAuraRunning then
            -- Cash Aura will stop automatically as the loop checks getgenv().cashAura
            -- Optionally, you can add a notification or log
            print("Cash Aura has been disabled.")
        end
    end
})

-- Add Toggles to Visuals Tab
local BoxToggle = Tabs.Visuals:AddToggle("BoxESP", {
    Title = "Box ESP",
    Default = false, -- Disabled by default
    -- Callback removed; using OnChanged instead
})

local HealthToggle = Tabs.Visuals:AddToggle("HealthESP", {
    Title = "Health ESP",
    Default = false, -- Disabled by default
    -- Callback removed; using OnChanged instead
})

-- New Toggles: Name ESP and Tracers
local NameToggle = Tabs.Visuals:AddToggle("NameESP", {
    Title = "Name ESP",
    Default = false, -- Disabled by default
})

local TracerToggle = Tabs.Visuals:AddToggle("Tracers", {
    Title = "Tracers",
    Default = false, -- Disabled by default
})

-- New Skeleton Toggle
local SkeletonToggle = Tabs.Visuals:AddToggle("SkeletonESP", {
    Title = "Skeleton ESP",
    Default = false,
})

-- Table to Track ESP Elements per Player
local ESPElements = {}

-- Autofarm Functionality (As per User's Code)
local function startAutofarm()
    local plr = game.Players.LocalPlayer
    local cash = workspace:FindFirstChild("Cash")
    local dmg = workspace:FindFirstChild("Damageables")

    if not cash or not dmg then
        warn("Cash or Damageables folder not found in the workspace.")
        return
    end

    -- Prevent player from being idled
    for _, v in next, getconnections(plr.Idled) do
        v:Disable()
    end

    -- Function to pick up cash with teleportation
    local function getMoneyAutofarm()
        local cashPickedUp = false
        for _, m in pairs(cash:GetChildren()) do
            if m.Name == "Cash" and (m.Position - plr.Character.HumanoidRootPart.Position).Magnitude <= 300 then
                cashPickedUp = true
                plr.Character.HumanoidRootPart.CFrame = m.CFrame
                fireproximityprompt(m.ProximityPrompt, 6)
                task.wait(0.1) -- Increased delay for picking up cash
            end
            if not getgenv().farm then
                break
            end
        end
        return cashPickedUp
    end

    -- Main autofarm loop
    while getgenv().farm do
        pcall(function()
            --[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Noclip = nil
local Clip = nil

function noclip()
	Clip = false
	local function Nocl()
		if Clip == false and game.Players.LocalPlayer.Character ~= nil then
			for _,v in pairs(game.Workspace.Damageables:GetDescendants()) do
				if v:IsA('Model') and v.Name == 'ATM' then
					for _, part in pairs(v:GetDescendants()) do
						if part:IsA('BasePart') and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end
		end
		wait(0.21) -- basic optimization
	end
	Noclip = game:GetService('RunService').Stepped:Connect(Nocl)
end

function clip()
	if Noclip then Noclip:Disconnect() end
	Clip = true
end

noclip() -- to toggle noclip() and clip()

            for _, a in ipairs(dmg:GetChildren()) do
                if not getgenv().farm then break end
                if a:FindFirstChild("Damageable") and a.Damageable.Value > 0 and a.Name ~= "CashRegister" then
                    -- Teleport to 3 studs above the ATM
                    plr.Character.HumanoidRootPart.CFrame = a.Screen.CFrame * CFrame.new(0, 0, 0)
                    task.wait(1)

                    -- Break the ATM
                    repeat
                        if not getgenv().farm then break end
                        plr.Character.HumanoidRootPart.CFrame = a.Screen.CFrame * CFrame.new(0, 0, 0)
                        game:GetService("ReplicatedStorage"):WaitForChild("PUNCHEVENT"):FireServer(1)
                        task.wait(0.5)
                    until a.Damageable.Value <= 0

                    -- Ensure all cash is picked up before moving to the next ATM
                    local endTime = tick() + 2
                    local cashPickedUp
                    repeat
                        if not getgenv().farm then break end
                        cashPickedUp = getMoneyAutofarm()
                        task.wait(0.1) -- Increased delay for picking up cash
                    until tick() >= endTime and not cashPickedUp

                    -- Move to next ATM if no cash was picked up
                    if not cashPickedUp then
                        task.wait(0.5)
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- Cash Aura Functionality (As per User's Code)
local function startCashAura()
    local plr = game.Players.LocalPlayer
    local cash = workspace:FindFirstChild("Cash")

    if not cash then
        warn("Cash folder not found in the workspace.")
        return
    end

    -- Function to pick up cash without teleporting
    local function getMoneyAura()
        local cashPickedUp = false
        for _, m in pairs(cash:GetChildren()) do
            if m.Name == "Cash" and (m.Position - plr.Character.HumanoidRootPart.Position).Magnitude <= 300 then
                cashPickedUp = true
                fireproximityprompt(m.ProximityPrompt, 6)
                task.wait(0.1) -- Increased delay for picking up cash
            end
            if not getgenv().cashAura then
                break
            end
        end
        return cashPickedUp
    end

    -- Main cash aura loop
    while getgenv().cashAura do
        pcall(function()
            getMoneyAura()
            task.wait(1) -- Check every 1 second
        end)
        task.wait(1)
    end
end

-- Toggle Actions for Autofarm
AutofarmToggle:OnChanged(function(value)
    autofarmEnabled = value
    getgenv().farm = autofarmEnabled

    if autofarmEnabled then
        spawn(function()
            startAutofarm()
        end)
    end
end)

-- Toggle Actions for Cash Aura
-- Already handled in the CashAuraToggle's Callback above

-- Function to Create ESP for a Player
local function CreateEsp(Player)
    if ESPElements[Player] then return end -- Prevent duplicate ESPs

    -- Create Drawing objects for ESP elements
    local Box = Drawing.new("Square")
    local BoxOutline = Drawing.new("Square")
    local Name = Drawing.new("Text")
    local HealthBar = Drawing.new("Square")
    local Tracer = Drawing.new("Line") -- Tracer Drawing
    local SkeletonLines = {
        Head = Drawing.new("Line"),
        UpperTorso = Drawing.new("Line"),
        LowerTorso = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line")
    }

    -- Initial configuration for ESP elements
    Box.Filled = false -- Transparent inside
    Box.Color = Config.BoxColor
    Box.Thickness = Config.BoxThickness
    Box.ZIndex = 69
    Box.Visible = boxESPEnabled -- Initially visible based on toggle

    BoxOutline.Filled = false -- Transparent outline fill
    BoxOutline.Color = Config.BoxOutlineColor
    BoxOutline.Thickness = Config.BoxOutlineThickness
    BoxOutline.ZIndex = 68 -- Ensure it's behind the Box
    BoxOutline.Visible = Config.BoxOutline and boxESPEnabled -- Initially visible based on toggle

    Name.Visible = false
    Name.Center = true
    Name.Color = Config.NamesColor
    Name.Font = Config.NamesFont
    Name.Size = Config.NamesSize
    Name.Outline = Config.NamesOutline
    Name.OutlineColor = Config.NamesOutlineColor
    Name.ZIndex = 69

    HealthBar.Filled = true
    HealthBar.Color = Color3.fromRGB(0, 255, 0) -- Initial color (green)
    HealthBar.ZIndex = 70
    HealthBar.Visible = healthESPEnabled -- Initially visible based on toggle

    -- Tracer Configuration
    Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
    Tracer.To = Vector2.new(0, 0)
    Tracer.Color = Config.TracerColor
    Tracer.Thickness = Config.TracerThickness
    Tracer.Transparency = Config.TracerTransparency
    Tracer.Visible = tracersEnabled -- Initially visible based on toggle

        -- Configure Skeleton Lines
        for _, line in pairs(SkeletonLines) do
            line.Thickness = Config.SkeletonThickness
            line.Color = Config.SkeletonColor
            line.Visible = skeletonESPEnabled
        end

    -- Store ESP elements in the table
    ESPElements[Player] = {
        Box = Box,
        BoxOutline = BoxOutline,
        Name = Name,
        HealthBar = HealthBar,
        Tracer = Tracer, -- Store Tracer
        SkeletonLines = SkeletonLines,
        IsVisible = false
    }

    -- Connect to player updates
    local Updater = game:GetService("RunService").RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Head") and Player.Character.Humanoid.Health > 0 then
            local Humanoid = Player.Character.Humanoid
            local HRP = Player.Character.HumanoidRootPart
            local Camera = workspace.CurrentCamera

            -- Get the 2D position and visibility of the HumanoidRootPart
            local Target2dPosition, IsVisible = Camera:WorldToViewportPoint(HRP.Position)

            -- Calculate scale factor based on distance
            local distance = (Camera.CFrame.p - HRP.Position).Magnitude
            local scale_factor = 1 / (distance * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 100
            local width, height = math.floor(30 * scale_factor), math.floor(45 * scale_factor) -- Adjust box size

            -- Store visibility state
            ESPElements[Player].IsVisible = IsVisible

            -- Update Box ESP
            if boxESPEnabled then
                Box.Visible = IsVisible
                Box.Size = Vector2.new(width, height)
                Box.Position = Vector2.new(Target2dPosition.X - Box.Size.X / 2, Target2dPosition.Y - Box.Size.Y / 2)
            else
                Box.Visible = false
            end

            -- Update Box Outline
            if Config.BoxOutline and boxESPEnabled then
                BoxOutline.Visible = IsVisible
                BoxOutline.Size = Vector2.new(width, height)
                BoxOutline.Position = Vector2.new(Target2dPosition.X - BoxOutline.Size.X / 2, Target2dPosition.Y - BoxOutline.Size.Y / 2)
            else
                BoxOutline.Visible = false
            end

            -- Update Health Bar ESP
            if healthESPEnabled then
                HealthBar.Visible = IsVisible

                -- Set Health Bar Size and Position based on the side
                local barWidth = Config.BoxThickness -- Health bar width matches the box thickness
                local barHeight = height * (Humanoid.Health / Humanoid.MaxHealth) -- Full height of the ESP box

                if Config.HealthBarSide == "Left" then
                    HealthBar.Size = Vector2.new(barWidth, barHeight)
                    HealthBar.Position = Vector2.new(Target2dPosition.X - width / 2 - barWidth - 2, Target2dPosition.Y + height / 2 - barHeight - 1) -- Position adjusted slightly down
                elseif Config.HealthBarSide == "Bottom" then
                    HealthBar.Size = Vector2.new(width - 6, 2)
                    HealthBar.Position = Vector2.new(Target2dPosition.X - width / 2 + 3, Target2dPosition.Y + height / 2 + 5)
                end

                -- Set Health Bar Color (Red to Green)
                local healthPercent = Humanoid.Health / Humanoid.MaxHealth
                HealthBar.Color = Color3.fromRGB(255, 0, 0):lerp(Color3.fromRGB(0, 255, 0), healthPercent)
            else
                HealthBar.Visible = false
            end

            -- Update Name Display ESP
            if Config.Names then
                Name.Visible = IsVisible
                Name.Text = Player.Name .. " " .. math.floor(distance) .. "m"
                Name.Position = Vector2.new(Target2dPosition.X, Target2dPosition.Y - height * 0.5 - 15)
            else
                Name.Visible = false
            end

            -- Update Tracer ESP
            if Config.Tracers then
                Tracer.Visible = IsVisible
                Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                Tracer.To = Vector2.new(Target2dPosition.X, Target2dPosition.Y)
            else
                Tracer.Visible = false
            end
             -- Update Skeleton ESP
             if Config.Skeleton then
                local function worldToViewportPoint(position)
                    local screenPosition, onScreen = Camera:WorldToViewportPoint(position)
                    return Vector2.new(screenPosition.X, screenPosition.Y), onScreen
                end

                local function updateSkeletonLine(line, startPart, endPart)
                    if startPart and endPart then
                        local startPos, startVisible = worldToViewportPoint(startPart.Position)
                        local endPos, endVisible = worldToViewportPoint(endPart.Position)
                        line.From = startPos
                        line.To = endPos
                        line.Visible = startVisible and endVisible and IsVisible
                    else
                        line.Visible = false
                    end
                end

                local character = Player.Character
                updateSkeletonLine(SkeletonLines.Head, character:FindFirstChild("Head"), character:FindFirstChild("UpperTorso"))
                updateSkeletonLine(SkeletonLines.UpperTorso, character:FindFirstChild("UpperTorso"), character:FindFirstChild("LowerTorso"))
                updateSkeletonLine(SkeletonLines.LowerTorso, character:FindFirstChild("LowerTorso"), character:FindFirstChild("UpperTorso"))
                updateSkeletonLine(SkeletonLines.LeftUpperArm, character:FindFirstChild("LeftUpperArm"), character:FindFirstChild("LeftLowerArm"))
                updateSkeletonLine(SkeletonLines.LeftLowerArm, character:FindFirstChild("LeftLowerArm"), character:FindFirstChild("LeftHand"))
                updateSkeletonLine(SkeletonLines.RightUpperArm, character:FindFirstChild("RightUpperArm"), character:FindFirstChild("RightLowerArm"))
                updateSkeletonLine(SkeletonLines.RightLowerArm, character:FindFirstChild("RightLowerArm"), character:FindFirstChild("RightHand"))
                updateSkeletonLine(SkeletonLines.LeftUpperLeg, character:FindFirstChild("LeftUpperLeg"), character:FindFirstChild("LeftLowerLeg"))
                updateSkeletonLine(SkeletonLines.LeftLowerLeg, character:FindFirstChild("LeftLowerLeg"), character:FindFirstChild("LeftFoot"))
                updateSkeletonLine(SkeletonLines.RightUpperLeg, character:FindFirstChild("RightUpperLeg"), character:FindFirstChild("RightLowerLeg"))
                updateSkeletonLine(SkeletonLines.RightLowerLeg, character:FindFirstChild("RightLowerLeg"), character:FindFirstChild("RightFoot"))
            else
                for _, line in pairs(SkeletonLines) do
                    line.Visible = false
                end
            end

        else


            -- Hide ESP elements if player is not valid
            Box.Visible = false
            BoxOutline.Visible = false
            Name.Visible = false
            HealthBar.Visible = false
            Tracer.Visible = false -- Hide Tracer
            for _, line in pairs(SkeletonLines) do
                line.Visible = false
            end
        end
    end)


    -- Handle Player Removal
    Player.CharacterRemoving:Connect(function()
        Box:Remove()
        BoxOutline:Remove()
        Name:Remove()
        HealthBar:Remove()
        Tracer:Remove() -- Remove Tracer
        for _, line in pairs(SkeletonLines) do
            line:Remove()
        end
        Updater:Disconnect()
        ESPElements[Player] = nil
    end)
end

-- Function to Update ESP Visibility Based on Toggles
local function updateESPVisibility()
    for _, elements in pairs(ESPElements) do
        if elements.Box and elements.BoxOutline then
            elements.Box.Visible = boxESPEnabled and elements.IsVisible
            elements.BoxOutline.Visible = boxESPEnabled and Config.BoxOutline and elements.IsVisible
        end

        if elements.HealthBar then
            elements.HealthBar.Visible = healthESPEnabled and elements.IsVisible
        end

        if elements.Name then
            elements.Name.Visible = Config.Names and elements.IsVisible
        end

        if elements.Tracer then
            elements.Tracer.Visible = Config.Tracers and elements.IsVisible

            if elements.SkeletonLines then
                for _, line in pairs(elements.SkeletonLines) do
                    line.Visible = Config.Skeleton and elements.IsVisible
                end
            end
        end
    end
end

-- Connect OnChanged Events for BoxESP and HealthESP Toggles
BoxToggle:OnChanged(function(value)
    boxESPEnabled = value
    Config.Box = boxESPEnabled
    updateESPVisibility()
end)

HealthToggle:OnChanged(function(value)
    healthESPEnabled = value
    Config.HealthBar = healthESPEnabled
    updateESPVisibility()
end)

-- Connect OnChanged Event for NameESP Toggle
NameToggle:OnChanged(function(value)
    nameESPEnabled = value
    Config.Names = nameESPEnabled
    updateESPVisibility()
end)

-- Connect OnChanged Event for Tracers Toggle
TracerToggle:OnChanged(function(value)
    tracersEnabled = value
    Config.Tracers = tracersEnabled
    updateESPVisibility()
end)

SkeletonToggle:OnChanged(function(value)
    skeletonESPEnabled = value
    Config.Skeleton = skeletonESPEnabled
    updateESPVisibility()
end)

-- Function to Create ESP for All Current Players
local function initializeESP()
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            CreateEsp(player)
            player.CharacterAdded:Connect(function()
                CreateEsp(player)
            end)
        end
    end
end

-- Initialize ESP for Existing Players
initializeESP()

-- Connect to New Players Joining the Game
game:GetService("Players").PlayerAdded:Connect(function(player)
    if player ~= game.Players.LocalPlayer then
        CreateEsp(player)
        player.CharacterAdded:Connect(function()
            CreateEsp(player)
        end)
    end
end)

-- Clean Up ESP When Players Leave
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if ESPElements[player] then
        ESPElements[player].Box:Remove()
        ESPElements[player].BoxOutline:Remove()
        ESPElements[player].Name:Remove()
        ESPElements[player].HealthBar:Remove()
        ESPElements[player].Tracer:Remove() -- Remove Tracer
        for _, line in pairs(ESPElements[player].SkeletonLines) do
            line:Remove()
         end
        ESPElements[player] = nil
    end
end)

-- ESP Update Function (optional, can be used for additional updates)
local function updateESP()
    -- Currently handled within CreateEsp via RenderStepped
    -- This function can be expanded if needed
end

-- Ensure All GUI Elements are Updated and Saved
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings) -- Added settings section
SaveManager:BuildConfigSection(Tabs.Settings) -- Added config section
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
