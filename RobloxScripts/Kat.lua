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
}

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
       local Connection

       Box.Filled = false
       BoxOutline.Color = Color3.fromRGB(0, 0, 0)
       TracerOutline.Color = Color3.fromRGB(0, 0, 0)
       HealthBarOutline.Filled = false
       HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
       HealthBar.Filled = true
       HealthBar.ZIndex = 5

       local function HideESP()
           BoxOutline.Visible = false
           Box.Visible = false
           TracerOutline.Visible = false
           Tracer.Visible = false
           HealthBarOutline.Visible = false
           HealthBar.Visible = false
       end

       local function DestroyESP()
           BoxOutline:Remove()
           Box:Remove()
           TracerOutline:Remove()
           Tracer:Remove()
           HealthBarOutline:Remove()
           HealthBar:Remove()
           Connection:Disconnect()
       end

       Connection = RunService.Heartbeat:Connect(function()
           if not ESP.Enabled then 
               return HideESP()
           end

           if not Player then
               return DestroyESP()
           end

           if not Functions:IsAlive(Player) then
               return HideESP()
           end

           if ESP.TeamCheck and Functions:GetTeam(Player) == Functions:GetTeam(LocalPlayer) then
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

           if ESP.Tracers.Enabled then
               TracerOutline.Visible = ESP.Tracers.Outlines
               TracerOutline.Thickness = ESP.Tracers.Thickness + ESP.Tracers.OutlineThickness
               TracerOutline.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
               TracerOutline.To = Vector2.new(ScreenPosition.X, Position.Y + Size.Y)

               Tracer.Visible = true
               Tracer.Color = ESP.Tracers.Color
               Tracer.Thickness = ESP.Tracers.Thickness
               Tracer.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
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

-- Silent Aim Implementation
local Target
local Circle = Drawing.new("Circle")

Circle.Visible = false
Circle.Thickness = 1
Circle.Transparency = 0
Circle.Color = Color3.fromRGB(255, 255, 255)
Circle.Filled = false

local function getMousePosition()
   return UserInputService:GetMouseLocation()
end

local function GetClosest(Fov)
   local Target, Closest = nil, Fov or math.huge
   local MousePos = getMousePosition()
   for i,v in pairs(Players:GetPlayers()) do
       if (v.Character and v ~= LocalPlayer and 
           v.Character:FindFirstChild(getgenv().silentaim_settings.hitbox)) then
           local Position, OnScreen = 
               CurrentCamera:WorldToScreenPoint(v.Character[getgenv().silentaim_settings.hitbox].Position)
           local Distance = (Vector2.new(Position.X, Position.Y) - MousePos).Magnitude
           if (Distance < Closest and OnScreen) then
               Closest = Distance
               Target = v
           end
       end
   end
   return Target
end

-- GUI Setup
local Window = Fluent:CreateWindow({
   Title = "Collapse-Kat",
   SubTitle = "Made by Finny<3",
   TabWidth = 160,
   Size = UDim2.fromOffset(580, 460),
   Acrylic = true,
   Theme = "Dark",
   MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
   Main = Window:AddTab({ Title = "Main", Icon = "" }),
   Visuals = Window:AddTab({ Title = "Visuals", Icon = "" }),
   Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Silent Aim Toggle
local SilentAimToggle = Tabs.Main:AddToggle("SilentAimEnabled", {
   Title = "Silent Aim",
   Default = false
})

SilentAimToggle:OnChanged(function()
   getgenv().silentaim_settings.enabled = Options.SilentAimEnabled.Value
end)

-- FOV Circle Toggle
local FovCircleToggle = Tabs.Main:AddToggle("FovCircle", {
   Title = "FOV Circle",
   Default = false
})

FovCircleToggle:OnChanged(function()
   getgenv().silentaim_settings.fovcircle = Options.FovCircle.Value
   Circle.Visible = Options.FovCircle.Value
   Circle.Transparency = Options.FovCircle.Value and 1 or 0
end)

-- FOV Slider
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
   Circle.Radius = Value
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

local HealthbarToggle = Tabs.Visuals:AddToggle("Healthbar", {
   Title = "Healthbar",
   Default = false
})

HealthbarToggle:OnChanged(function()
   ESP.HealthBar.Enabled = Options.Healthbar.Value
end)

-- Silent Aim Update Loop
RunService.RenderStepped:Connect(function()
   local MousePos = getMousePosition()
   Circle.Position = MousePos
   Circle.Radius = getgenv().silentaim_settings.fov
   Circle.Visible = getgenv().silentaim_settings.fovcircle

   if getgenv().silentaim_settings.enabled then
       Target = GetClosest(getgenv().silentaim_settings.fov)
   end
end)

-- Silent Aim Hook
local Old
Old = hookmetamethod(game, "__namecall", function(Self, ...)
   local Args = {...}
   if (not checkcaller() and getnamecallmethod() == "FindPartOnRayWithIgnoreList" and getgenv().silentaim_settings.enabled) then
       if (table.find(Args[2], workspace.WorldIgnore.Ignore) and Target and Target.Character) then
           local Origin = Args[1].Origin
           Args[1] = Ray.new(Origin,
               Target.Character[getgenv().silentaim_settings.hitbox].Position - Origin)
       end
   end
   return Old(Self, unpack(Args))
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("CollapseKat")
SaveManager:SetFolder("CollapseKat/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
   Title = "Collapse-Kat",
   Content = "Script loaded successfully!",
   Duration = 6
})

SaveManager:LoadAutoloadConfig()
