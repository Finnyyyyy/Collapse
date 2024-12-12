local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local MousePos = UserInputService:GetMouseLocation()
local RunService = game:GetService("RunService")

-- Current Tracer Position
local currentTracerPosition = "Bottom"

-- ESP Table
local ESP = {
 Enabled = true,
 TeamCheck = false,
 Box = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255),
     Thickness = 1,
     Outlines = true,
     OutlineThickness = 1
 },
 Tool = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255)
 },
 Distance = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255)
 },
 Tracers = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255),
     Thickness = 1,
     Outlines = true,
     OutlineThickness = 1
 },
 HealthBar = {
     Enabled = false,
     Color = Color3.fromRGB(0, 255, 0),
     Outlines = true
 }
}

-- Silent Aim Settings
getgenv().silentaim_settings = {
 enabled = false,
 fov = 150,
 hitbox = "Head",
 fovcircle = false,
 teamCheck = false,
 fovPosition = "Mouse"  -- Added new setting
}

-- Create Circle for FOV
local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = 1
Circle.Color = Color3.fromRGB(255, 255, 255)
Circle.Transparency = 0.5
Circle.Filled = false

-- Silent Aim Implementation
local SilentAimTarget = nil

local function GetDirection(origin, destination)
    return (destination - origin).Unit * 1000
end

local function WorldToScreen(position)
    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(position)
    return {Position = Vector2.new(screenPos.X, screenPos.Y), OnScreen = onScreen}
end

local function IsTeammate(player)
    -- Check for "Teammate" text label
    return player.Character and player.Character:FindFirstChild("Teammate") ~= nil
end

local function HasCharacter(player)
    return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestPlayer()
    local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
    local mousePos = getgenv().silentaim_settings.fovPosition == "Mouse" and 
                     UserInputService:GetMouseLocation() or 
                     screenCenter
    
    local closestPlayer = nil
    local shortestDistance = getgenv().silentaim_settings.fov
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and HasCharacter(player) then
            -- Check for Silent Aim Team Check and Teammate Label
            if not (getgenv().silentaim_settings.teamCheck and (IsTeammate(player) or player.Team == LocalPlayer.Team)) then
                local targetPart = player.Character:FindFirstChild(getgenv().silentaim_settings.hitbox or "Head")
                if targetPart then
                    local screenPos = WorldToScreen(targetPart.Position)
                    if screenPos.OnScreen then
                        local distance = (mousePos - screenPos.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Update Silent Aim Target
RunService.RenderStepped:Connect(function()
    if getgenv().silentaim_settings.enabled then
        SilentAimTarget = GetClosestPlayer()
    else
        SilentAimTarget = nil
    end
 
    -- Updated FOV Circle Handling
    local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
    
    if getgenv().silentaim_settings.fovPosition == "Mouse" then
        Circle.Position = UserInputService:GetMouseLocation()
    else -- Centered
        Circle.Position = screenCenter
    end
    
    Circle.Radius = getgenv().silentaim_settings.fov
    Circle.Visible = getgenv().silentaim_settings.fovcircle
end)
 
-- Hook Raycast
local Old
Old = hookmetamethod(game, "__namecall", function(Self, ...)
    local Args = {...}
    local method = getnamecallmethod()
    
    if not checkcaller() and Self == Workspace and method == "Raycast" and getgenv().silentaim_settings.enabled and SilentAimTarget then
        local origin = Args[1]
        Args[2] = GetDirection(origin, SilentAimTarget.Character[getgenv().silentaim_settings.hitbox].Position)
        return Old(Self, unpack(Args))
    end
    
    return Old(Self, ...)
end)
 
-- ESP Functions
local Functions = {}
do 
function Functions:IsAlive(Player)
    if Player and Player.Character and Player.Character:FindFirstChild("Head") and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
        return true
    end
    return false
end
 
function Functions:GetTeam(Player)
    if not Player.Neutral then
        return game:GetService("Teams")[Player.Team.Name]
    end
    return "No Team"
end
 
function Functions:GetEquippedTool(Player)
    if Player and Player.Character then
        local Tool = Player.Character:FindFirstChildOfClass("Tool")
        if Tool then
            return Tool.Name
        end
    end
    return "None"
end
 
function Functions:GetDistance(Player)
    if Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return math.floor((Player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
    return 0
end
end
 
-- ESP Implementation
do
local function AddESP(Player)
    local BoxOutline = Drawing.new("Square")
    local Box = Drawing.new("Square")
    local TracerOutline = Drawing.new("Line")
    local Tracer = Drawing.new("Line")
    local HealthBarOutline = Drawing.new("Square")
    local HealthBar = Drawing.new("Square")
    local ToolText = Drawing.new("Text")
    local DistanceText = Drawing.new("Text")
    local Connection
 
    Box.Filled = false
    BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    TracerOutline.Color = Color3.fromRGB(0, 0, 0)
    HealthBarOutline.Filled = false
    HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    HealthBar.Filled = true
    HealthBar.ZIndex = 5
 
    ToolText.Size = 13
    ToolText.Center = true
    ToolText.Outline = true
    ToolText.Font = 2
    ToolText.Color = ESP.Tool.Color
 
    DistanceText.Size = 13
    DistanceText.Center = true
    DistanceText.Outline = true
    DistanceText.Font = 2
    DistanceText.Color = ESP.Distance.Color
 
    local function HideESP()
        BoxOutline.Visible = false
        Box.Visible = false
        TracerOutline.Visible = false
        Tracer.Visible = false
        HealthBarOutline.Visible = false
        HealthBar.Visible = false
        ToolText.Visible = false
        DistanceText.Visible = false
    end
 
    local function DestroyESP()
        BoxOutline:Remove()
        Box:Remove()
        TracerOutline:Remove()
        Tracer:Remove()
        HealthBarOutline:Remove()
        HealthBar:Remove()
        ToolText:Remove()
        DistanceText:Remove()
        Connection:Disconnect()
    end
 
    Connection = RunService.Heartbeat:Connect(function()
        if not ESP.Enabled then 
            return HideESP()
        end
 
        if not Player or not Player.Parent then
            return DestroyESP()
        end
 
        if not Functions:IsAlive(Player) then
            return HideESP()
        end
 
        -- Check for Teammate Label and Team Check
        if (ESP.TeamCheck and (IsTeammate(Player) or Player.Team == LocalPlayer.Team)) then
            return HideESP()
        end
 
        local HumanoidRootPart = Player.Character.HumanoidRootPart
        if not HumanoidRootPart then
            return HideESP()
        end
 
        local ScreenPosition, OnScreen = CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position)
        if not OnScreen then
            return HideESP()
        end
 
        local FrustumHeight = math.tan(math.rad(CurrentCamera.FieldOfView * 0.5)) * 2 * ScreenPosition.Z
        local Size = CurrentCamera.ViewportSize.Y / FrustumHeight * Vector2.new(5,6)
        local Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Size / 2
 
        if ESP.Box.Enabled then
            BoxOutline.Visible = ESP.Box.Outlines
            BoxOutline.Thickness = ESP.Box.Thickness + ESP.Box.OutlineThickness
            BoxOutline.Position = Position
            BoxOutline.Size = Size
 
            Box.Visible = true
            Box.Position = Position
            Box.Size = Size
            Box.Color = ESP.Box.Color
            Box.Thickness = ESP.Box.Thickness
        else
            Box.Visible = false
            BoxOutline.Visible = false
        end
 
        if ESP.Tool.Enabled then
            ToolText.Visible = true
            ToolText.Text = Functions:GetEquippedTool(Player)
            ToolText.Position = Vector2.new(Position.X + (Size.X / 2), Position.Y + Size.Y + 2)
            ToolText.Color = ESP.Tool.Color
        else
            ToolText.Visible = false
        end
 
        if ESP.Distance.Enabled then
            DistanceText.Visible = true
            DistanceText.Text = tostring(Functions:GetDistance(Player)) .. " studs"
            DistanceText.Position = Vector2.new(Position.X + (Size.X / 2), Position.Y - 15)
            DistanceText.Color = ESP.Distance.Color
        else
            DistanceText.Visible = false
        end

        if ESP.Tracers.Enabled then
            local tracerFrom
            if currentTracerPosition == "Bottom" then
                tracerFrom = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
            elseif currentTracerPosition == "Middle" then
                tracerFrom = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
            elseif currentTracerPosition == "Top" then
                tracerFrom = Vector2.new(CurrentCamera.ViewportSize.X / 2, 0)
            elseif currentTracerPosition == "Mouse" then
                tracerFrom = UserInputService:GetMouseLocation()
            end

            TracerOutline.Visible = ESP.Tracers.Outlines
            TracerOutline.Thickness = ESP.Tracers.Thickness + ESP.Tracers.OutlineThickness
            TracerOutline.From = tracerFrom
            TracerOutline.To = Vector2.new(ScreenPosition.X, Position.Y + Size.Y)

            Tracer.Visible = true
            Tracer.Color = ESP.Tracers.Color
            Tracer.Thickness = ESP.Tracers.Thickness
            Tracer.From = tracerFrom
            Tracer.To = Vector2.new(TracerOutline.To.X, TracerOutline.To.Y)
        else
            TracerOutline.Visible = false
            Tracer.Visible = false
        end

        if ESP.HealthBar.Enabled then
            HealthBarOutline.Visible = ESP.HealthBar.Outlines
            HealthBarOutline.Position = Vector2.new(Position.X - 6, Position.Y + Size.Y)
            HealthBarOutline.Size = Vector2.new(3, -Size.Y * Player.Character.Humanoid.Health / Player.Character.Humanoid.MaxHealth)
            HealthBarOutline.Thickness = 1

            HealthBar.Visible = true
            HealthBar.Position = HealthBarOutline.Position
            HealthBar.Size = HealthBarOutline.Size
            HealthBar.Color = ESP.HealthBar.Color
        else
            HealthBarOutline.Visible = false
            HealthBar.Visible = false
        end
    end)
end

for i,v in pairs(Players:GetChildren()) do 
    if v ~= LocalPlayer then
        AddESP(v)
    end
end

Players.PlayerAdded:Connect(function(v)
    AddESP(v)
end)
end

-- GUI Setup with Orion
local Window = OrionLib:MakeWindow({
    Name = "Collapse:Weaponry-Made by Finny<3",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "CollapseWeaponry"
})

local Tabs = {
    Main = Window:MakeTab({ 
        Name = "Main", 
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false 
    }),
    Visuals = Window:MakeTab({ 
        Name = "Visuals", 
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false 
    }),
    Settings = Window:MakeTab({ 
        Name = "Settings", 
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false 
    })
}

-- Silent Aim Toggle (First)
Tabs.Main:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Flag = "SilentAimEnabled",
    Callback = function(Value)
        getgenv().silentaim_settings.enabled = Value
    end
})

-- Silent Aim Team Check Toggle
Tabs.Main:AddToggle({
    Name = "Silent Aim Team Check",
    Default = false,
    Flag = "SilentAimTeamCheck",
    Callback = function(Value)
        getgenv().silentaim_settings.teamCheck = Value
    end
})

-- FOV Circle Toggle (Second)
Tabs.Main:AddToggle({
    Name = "FOV Circle",
    Default = false,
    Flag = "FovCircle",
    Callback = function(Value)
        getgenv().silentaim_settings.fovcircle = Value
    end
})

-- FOV Position Dropdown (New)
Tabs.Main:AddDropdown({
    Name = "FOV Position",
    Default = "Mouse",
    Options = {"Mouse", "Centered"},
    Flag = "FovPosition",
    Callback = function(Value)
        getgenv().silentaim_settings.fovPosition = Value
    end
})

-- FOV Slider (Third)
Tabs.Main:AddSlider({
    Name = "FOV Size",
    Min = 1,
    Max = 800,
    Default = 100,
    Flag = "FovSlider",
    Callback = function(Value)
        getgenv().silentaim_settings.fov = Value
    end
})

-- Silent Aim Target Dropdown
Tabs.Main:AddDropdown({
    Name = "Silent Aim Target",
    Default = "Head",
    Options = {"Head", "HumanoidRootPart"},
    Flag = "SilentAimTarget",
    Callback = function(Value)
        getgenv().silentaim_settings.hitbox = Value
    end
})

-- Speed Slider
Tabs.Main:AddSlider({
    Name = "Player Speed",
    Min = 16,
    Max = 150,
    Default = 16,
    Callback = function(Value)
        local Character = game.Players.LocalPlayer.Character
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = Value
        end
    end
})

-- Jump Height Slider
Tabs.Main:AddSlider({
    Name = "Jump Height",
    Min = 50,
    Max = 150,
    Default = 50,
    Callback = function(Value)
        local Character = game.Players.LocalPlayer.Character
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.JumpPower = Value
        end
    end
})

-- ESP Toggles
Tabs.Visuals:AddToggle({
    Name = "Box ESP",
    Default = false,
    Flag = "BoxESP",
    Callback = function(Value)
        ESP.Box.Enabled = Value
    end
})

Tabs.Visuals:AddToggle({
    Name = "Tracers",
    Default = false,
    Flag = "Tracers",
    Callback = function(Value)
        ESP.Tracers.Enabled = Value
    end
})

Tabs.Visuals:AddDropdown({
    Name = "Tracer Position",
    Default = "Bottom",
    Options = {"Bottom", "Middle", "Top", "Mouse"},
    Flag = "TracerPosition",
    Callback = function(Value)
        currentTracerPosition = Value
    end
})

Tabs.Visuals:AddToggle({
    Name = "Healthbar",
    Default = false,
    Flag = "Healthbar",
    Callback = function(Value)
        ESP.HealthBar.Enabled = Value
    end
})

Tabs.Visuals:AddToggle({
    Name = "Tool ESP",
    Default = false,
    Flag = "ToolESP",
    Callback = function(Value)
        ESP.Tool.Enabled = Value
    end
})

Tabs.Visuals:AddToggle({
    Name = "Distance ESP",
    Default = false,
    Flag = "DistanceESP",
    Callback = function(Value)
        ESP.Distance.Enabled = Value
    end
})

Tabs.Visuals:AddToggle({
    Name = "ESP Team Check",
    Default = false,
    Flag = "ESPTeamCheck",
    Callback = function(Value)
        ESP.TeamCheck = Value
    end
})

-- Initialize Orion Library
OrionLib:Init()

-- Notification
OrionLib:MakeNotification({
    Name = "Collapse-Weaponry",
    Content = "Script loaded successfully!-Made by finny<3",
    Image = "rbxassetid://4483345998",
    Time = 5
})