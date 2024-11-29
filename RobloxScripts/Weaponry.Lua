local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Variables 
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
 teamCheck = false
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
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local shortestDistance = getgenv().silentaim_settings.fov  -- Use existing FOV setting
    
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
 
    -- FOV Circle Handling
    local MousePos = UserInputService:GetMouseLocation()
    Circle.Position = MousePos
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

 -- GUI Setup
local Window = Fluent:CreateWindow({
    Title = "Collapse-Weaponry",
    SubTitle = "Made by Finny<3",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftAlt
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Main", Icon = "" }),
        Visuals = Window:AddTab({ Title = "Visuals", Icon = "" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
        }
        
        local Options = Fluent.Options
        
        -- Silent Aim Toggle (First)
        local SilentAimToggle = Tabs.Main:AddToggle("SilentAimEnabled", {
        Title = "Silent Aim",
        Default = false
        })
        
        SilentAimToggle:OnChanged(function()
        getgenv().silentaim_settings.enabled = Options.SilentAimEnabled.Value
        end)
        
        -- Silent Aim Team Check Toggle
        local SilentAimTeamCheckToggle = Tabs.Main:AddToggle("SilentAimTeamCheck", {
        Title = "Silent Aim Team Check",
        Default = false
        })
        
        SilentAimTeamCheckToggle:OnChanged(function()
        getgenv().silentaim_settings.teamCheck = Options.SilentAimTeamCheck.Value
        end)
        
        -- FOV Circle Toggle (Second)
        local FovCircleToggle = Tabs.Main:AddToggle("FovCircle", {
        Title = "FOV Circle",
        Default = false
        })
        
        FovCircleToggle:OnChanged(function()
        getgenv().silentaim_settings.fovcircle = Options.FovCircle.Value
        end)
        
        -- FOV Slider (Third)
        local FovSlider = Tabs.Main:AddSlider("FovSlider", {
        Title = "FOV Size",
        Description = "Adjust the FOV circle size",
        Default = 150,
        Min = 1,
        Max = 800,
        Rounding = 0
        })
        
        FovSlider:OnChanged(function(Value)
        getgenv().silentaim_settings.fov = Value
        end)
        
        -- Silent Aim Target Dropdown
        local SilentAimTargetDropdown = Tabs.Main:AddDropdown("SilentAimTarget", {
         Title = "Silent Aim Target",
         Description = "Select the target hitbox for Silent Aim",
         Values = {"Head", "HumanoidRootPart"},
         Multi = false,
         Default = "Head",
        })
        
        SilentAimTargetDropdown:OnChanged(function(Value)
         getgenv().silentaim_settings.hitbox = Value
        end)
        
        -- Speed Slider
        local SpeedSlider = Tabs.Main:AddSlider("SpeedSlider", {
         Title = "Player Speed",
         Description = "Adjust your walking speed",
         Default = 16,
         Min = 16,
         Max = 25,
         Rounding = 1
        })
        
        SpeedSlider:OnChanged(function(Value)
         if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
           game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
         end
        end)
        
        -- Jump Height Slider
        local JumpHeightSlider = Tabs.Main:AddSlider("JumpHeightSlider", {
         Title = "Jump Height",
         Description = "Adjust your jump power",
         Default = 50,
         Min = 50,
         Max = 150,
         Rounding = 1
        })
        
        JumpHeightSlider:OnChanged(function(Value)
         if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
           game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
         end
        end)
        
        -- ESP Toggles
        local BoxESPToggle = Tabs.Visuals:AddToggle("BoxESP", {
        Title = "Box ESP",
        Default = false
        })
        
        BoxESPToggle:OnChanged(function()
        ESP.Box.Enabled = Options.BoxESP.Value
        end)
        
        local TracersToggle = Tabs.Visuals:AddToggle("Tracers", {
        Title = "Tracers",
        Default = false
        })
        
        TracersToggle:OnChanged(function()
         ESP.Tracers.Enabled = Options.Tracers.Value
        end)
        
        -- Tracer Position Dropdown
        local TracerPositionDropdown = Tabs.Visuals:AddDropdown("TracerPosition", {
         Title = "Tracer Position",
         Description = "Select the starting position for tracers",
         Values = {"Bottom", "Middle", "Top", "Mouse"},
         Multi = false,
         Default = "Bottom",
        })
        
        TracerPositionDropdown:OnChanged(function(Value)
         currentTracerPosition = Value
        end)
        
        local HealthbarToggle = Tabs.Visuals:AddToggle("Healthbar", {
        Title = "Healthbar",
        Default = false
        })
        
        HealthbarToggle:OnChanged(function()
         ESP.HealthBar.Enabled = Options.Healthbar.Value
        end)
        
        local ToolESPToggle = Tabs.Visuals:AddToggle("ToolESP", {
         Title = "Tool ESP",
         Default = false
        })
        
        ToolESPToggle:OnChanged(function()
         ESP.Tool.Enabled = Options.ToolESP.Value
        end)
        
        local DistanceESPToggle = Tabs.Visuals:AddToggle("DistanceESP", {
         Title = "Distance ESP",
         Default = false
        })
        
        DistanceESPToggle:OnChanged(function()
         ESP.Distance.Enabled = Options.DistanceESP.Value
        end)
        
        -- ESP Team Check Toggle
        local ESPTeamCheckToggle = Tabs.Visuals:AddToggle("ESPTeamCheck", {
         Title = "ESP Team Check",
         Default = false
        })
        
        ESPTeamCheckToggle:OnChanged(function()
         ESP.TeamCheck = Options.ESPTeamCheck.Value
        end)
        
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        InterfaceManager:SetFolder("CollapseWeaponry")
        SaveManager:SetFolder("CollapseWeaponry/configs")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
        
        Window:SelectTab(1)
        
        Fluent:Notify({
        Title = "Collapse-Weaponry",
        Content = "Script loaded successfully!",
        Duration = 6
        })
        
        SaveManager:LoadAutoloadConfig()
