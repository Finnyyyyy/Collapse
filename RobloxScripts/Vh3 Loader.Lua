---------------------------------------------------
-- Load MacLib and create the main GUI window  --
---------------------------------------------------
local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
local Window = MacLib:Window({
	Title = "Collapse | Vh3",
	Subtitle = "| Made by Finny <3",
	Size = UDim2.fromOffset(800, 500),
	DragStyle = 2,
	DisabledWindowControls = {},
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightShift,
	AcrylicBlur = false,
})

local globalSettings = {
	UIBlurToggle = Window:GlobalSetting({
		Name = "UI Blur",
		Default = Window:GetAcrylicBlurState(),
		Callback = function(bool)
			Window:SetAcrylicBlurState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
				Lifetime = 5
			})
		end,
	}),
	NotificationToggler = Window:GlobalSetting({
		Name = "Notifications",
		Default = Window:GetNotificationsState(),
		Callback = function(bool)
			Window:SetNotificationsState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " Notifications",
				Lifetime = 5
			})
		end,
	}),
	ShowUserInfo = Window:GlobalSetting({
		Name = "Show User Info",
		Default = Window:GetUserInfoState(),
		Callback = function(bool)
			Window:SetUserInfoState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Showing" or "Redacted") .. " User Info",
				Lifetime = 5
			})
		end,
	})
}

---------------------------------------------------
-- Create Tab Groups and Tabs                    --
---------------------------------------------------
local tabGroups = {
	Aim = Window:TabGroup(),
	World = Window:TabGroup(),
	Other = Window:TabGroup()
}
local tabs = {
	AimAssist = tabGroups.Aim:Tab({ Name = "Aim Assist", Image = "rbxassetid://99275039709063" }),
	Visuals = tabGroups.World:Tab({ Name = "Visuals", Image = "rbxassetid://104811813262009" }),
	Player = tabGroups.Other:Tab({ Name = "Player", Image = "rbxassetid://603107593" }),
	Settings = tabGroups.Other:Tab({ Name = "Settings", Image = "rbxassetid://110807522910450" })
}
tabs.Settings:InsertConfigSection("Left")

---------------------------------------------------
-- Game Services and Global Variables          --
---------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local currentTracerPosition = "Bottom"  -- default tracer origin
local Aiming = false
local currentTarget = nil

-- ESP table (for visuals only)
local ESP = {
    Enabled = true,
    Box = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Outlines = true,
        OutlineThickness = 0
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
        OutlineThickness = 0
    },
    HealthBar = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        Outlines = true,
        ShowNumber = true,
        NumberColor = Color3.fromRGB(255, 255, 255)
    }
}

---------------------------------------------------
-- Aim Settings and FOV Circle Setup             --
---------------------------------------------------
getgenv().aim_settings = {
    enabled = false,
    fov = 150,
    hitbox = "Head",  -- default target; options: "Head", "HumanoidRootPart", "Random", "Nearest"
    fovcircle = false,
    aimKey = Enum.KeyCode.E,
    method = "Camera",  -- "Camera" or "Mouse"
    fovThickness = 1,
    fovCircleColor = Color3.fromRGB(255,255,255),
    fovCircleFilled = false,
    fovCircleTransparency = 1
}
local currentAimKey = getgenv().aim_settings.aimKey

getgenv().boxESPFilled = getgenv().boxESPFilled or false

-- Create FOV Circle drawing
local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = getgenv().aim_settings.fovThickness
Circle.Color = getgenv().aim_settings.fovCircleColor
Circle.Transparency = getgenv().aim_settings.fovCircleTransparency
Circle.Filled = getgenv().aim_settings.fovCircleFilled
Circle.NumSides = 64

-- Global variable to hold the chosen random part (for "Random" mode)
local randomPart = nil

---------------------------------------------------
-- Helper Function for Random Aim Target         --
---------------------------------------------------
local function GetRandomPartFromCharacter(character)
    local partsList = {"Head", "HumanoidRootPart", "Right Leg", "Left Leg", "Right Arm", "Left Arm"}
    local available = {}
    for _, partName in ipairs(partsList) do
        local part = character:FindFirstChild(partName)
        if part then
            table.insert(available, part)
        end
    end
    if #available > 0 then
        return available[math.random(1, #available)]
    else
        return character:FindFirstChild("Head")
    end
end

---------------------------------------------------
-- Helper Function for Nearest Aim Target        --
---------------------------------------------------
local function GetNearestPartFromCharacter(character, mousePos)
    local partsList = {"Head", "HumanoidRootPart", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
    local bestPart = nil
    local bestDistance = math.huge
    for _, partName in ipairs(partsList) do
        local part = character:FindFirstChild(partName)
        if part then
            local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < bestDistance then
                    bestDistance = dist
                    bestPart = part
                end
            end
        end
    end
    return bestPart or character:FindFirstChild("Head")
end

---------------------------------------------------
-- Aiming Functionality                          --
---------------------------------------------------
local function AimLock()
    local mousePos = UserInputService:GetMouseLocation()
    local candidateTarget = nil
    local targetPart = nil
    local bestDistance = math.huge

    if getgenv().aim_settings.hitbox == "Nearest" then
        local partsList = {"Head", "HumanoidRootPart", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                for _, partName in ipairs(partsList) do
                    local part = v.Character:FindFirstChild(partName)
                    if part then
                        local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                            if distance <= getgenv().aim_settings.fov and distance < bestDistance then
                                bestDistance = distance
                                candidateTarget = v
                                targetPart = part
                            end
                        end
                    end
                end
            end
        end
    else
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                local candidatePart = nil
                if getgenv().aim_settings.hitbox == "Random" then
                    candidatePart = v.Character:FindFirstChild("HumanoidRootPart")
                else
                    candidatePart = v.Character:FindFirstChild(getgenv().aim_settings.hitbox)
                end
                if candidatePart then
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(candidatePart.Position)
                    if onScreen then
                        local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if distance <= getgenv().aim_settings.fov and distance < bestDistance then
                            bestDistance = distance
                            candidateTarget = v
                        end
                    end
                end
            end
        end

        if candidateTarget then
            if getgenv().aim_settings.hitbox == "Random" then
                if not randomPart then
                    randomPart = GetRandomPartFromCharacter(candidateTarget.Character)
                end
                targetPart = randomPart
            else
                targetPart = candidateTarget.Character:FindFirstChild(getgenv().aim_settings.hitbox)
            end
        end
    end

    currentTarget = candidateTarget
    if currentTarget and currentTarget.Character and targetPart then
        local pos = CurrentCamera.CFrame.Position
        CurrentCamera.CFrame = CFrame.new(pos, targetPart.Position)
    end
end

RunService.RenderStepped:Connect(function()
    if getgenv().aim_settings.enabled and Aiming then
        AimLock()
    end
    Circle.Position = UserInputService:GetMouseLocation()
    Circle.Radius = getgenv().aim_settings.fov
    Circle.Visible = getgenv().aim_settings.fovcircle
    Circle.Thickness = getgenv().aim_settings.fovThickness
    Circle.Color = getgenv().aim_settings.fovCircleColor
    Circle.Transparency = getgenv().aim_settings.fovCircleTransparency
    Circle.Filled = getgenv().aim_settings.fovCircleFilled
end)

---------------------------------------------------
-- Standard ESP Rendering (Box, Tracers, etc.)    --
---------------------------------------------------
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
        local HealthText = Drawing.new("Text")
        -- NEW: Name ESP drawing for displaying the player's username.
        local NameESPText = Drawing.new("Text")
        NameESPText.Size = 12
        NameESPText.Center = true
        NameESPText.Outline = true
        NameESPText.Font = 2
        NameESPText.Color = Color3.fromRGB(255,255,255)
        NameESPText.Text = Player.Name
        local Connection
        local Corners  -- for "Corners" box ESP

        Box.Filled = false
        HealthBarOutline.Filled = false
        HealthBarOutline.Color = Color3.new(0, 0, 0)
        HealthBar.Filled = true
        HealthBar.ZIndex = 5

        HealthText.Size = 10
        HealthText.Center = true
        HealthText.Outline = true
        HealthText.Font = 2
        HealthText.Color = ESP.HealthBar.NumberColor

        ToolText.Size = 13
        ToolText.Center = true
        ToolText.Outline = true
        ToolText.Font = 2
        ToolText.Color = ESP.Tool.Color

        DistanceText.Size = 11
        DistanceText.Center = true
        DistanceText.Outline = true
        DistanceText.Font = 2
        DistanceText.Color = ESP.Distance.Color

        local function HideESP()
            if Corners then
                for i, line in ipairs(Corners) do
                    line.Visible = false
                end
            end
            BoxOutline.Visible = false
            Box.Visible = false
            TracerOutline.Visible = false
            Tracer.Visible = false
            HealthBarOutline.Visible = false
            HealthBar.Visible = false
            ToolText.Visible = false
            DistanceText.Visible = false
            HealthText.Visible = false
            NameESPText.Visible = false
        end

        local function DestroyESP()
            if Corners then
                for i, line in ipairs(Corners) do
                    line:Remove()
                end
            end
            BoxOutline:Remove()
            Box:Remove()
            TracerOutline:Remove()
            Tracer:Remove()
            HealthBarOutline:Remove()
            HealthBar:Remove()
            ToolText:Remove()
            DistanceText:Remove()
            HealthText:Remove()
            NameESPText:Remove()
            if Connection then Connection:Disconnect() end
        end

        Connection = RunService.RenderStepped:Connect(function()
            if not ESP.Enabled then return HideESP() end
            if not Player or not Player.Parent then return DestroyESP() end
            if not (Player.Character and Player.Character:FindFirstChild("Head") and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0) then
                return HideESP()
            end

            local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart")
            if not HumanoidRootPart then return HideESP() end

            local ScreenPosition, OnScreen = CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position)
            if not OnScreen then return HideESP() end

            local FrustumHeight = math.tan(math.rad(CurrentCamera.FieldOfView * 0.5)) * 2 * ScreenPosition.Z
            local Size = CurrentCamera.ViewportSize.Y / FrustumHeight * Vector2.new(5,6)
            local Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Size / 2

            -- BOX ESP rendering
            if ESP.Box.Enabled then
                if getgenv().boxESPType == "Corners" then
                    if not Corners then
                        Corners = {
                            Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"),
                            Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line")
                        }
                    end
                    local cl = 15
                    local x = Position.X
                    local y = Position.Y
                    local w = Size.X
                    local h = Size.Y
                    Corners[1].From = Vector2.new(x, y)
                    Corners[1].To = Vector2.new(x + cl, y)
                    Corners[2].From = Vector2.new(x, y)
                    Corners[2].To = Vector2.new(x, y + cl)
                    Corners[3].From = Vector2.new(x + w - cl, y)
                    Corners[3].To = Vector2.new(x + w, y)
                    Corners[4].From = Vector2.new(x + w, y)
                    Corners[4].To = Vector2.new(x + w, y + cl)
                    Corners[5].From = Vector2.new(x, y + h)
                    Corners[5].To = Vector2.new(x + cl, y + h)
                    Corners[6].From = Vector2.new(x, y + h - cl)
                    Corners[6].To = Vector2.new(x, y + h)
                    Corners[7].From = Vector2.new(x + w - cl, y + h)
                    Corners[7].To = Vector2.new(x + w, y + h)
                    Corners[8].From = Vector2.new(x + w, y + h - cl)
                    Corners[8].To = Vector2.new(x + w, y + h)
                    for i, line in ipairs(Corners) do
                        line.Color = ESP.Box.Color
                        line.Thickness = ESP.Box.Thickness
                        line.Transparency = 0
                        line.Visible = true
                    end
                    Box.Visible = false
                    BoxOutline.Visible = false
                else
                    BoxOutline.Color = ESP.Box.Color
                    Box.Color = ESP.Box.Color
                    BoxOutline.Visible = ESP.Box.Outlines
                    BoxOutline.Thickness = ESP.Box.Thickness + ESP.Box.OutlineThickness
                    BoxOutline.Position = Position
                    BoxOutline.Size = Size

                    Box.Visible = true
                    Box.Position = Position
                    Box.Size = Size
                    Box.Thickness = ESP.Box.Thickness
                    if getgenv().boxESPFilled then
                        Box.Filled = true
                        Box.FillTransparency = 0.8
                    else
                        Box.Filled = false
                    end
                    if Corners then
                        for i, line in ipairs(Corners) do
                            line.Visible = false
                        end
                    end
                end
            else
                Box.Visible = false
                BoxOutline.Visible = false
                if Corners then
                    for i, line in ipairs(Corners) do
                        line.Visible = false
                    end
                end
            end

            -- TOOL ESP
            if ESP.Tool.Enabled then
                ToolText.Visible = true
                ToolText.Text = (Player.Character and Player.Character:FindFirstChildOfClass("Tool") and Player.Character:FindFirstChildOfClass("Tool").Name) or "None"
                ToolText.Position = Vector2.new(Position.X + (Size.X / 2), Position.Y + Size.Y + 2)
                ToolText.Color = ESP.Tool.Color
            else
                ToolText.Visible = false
            end

            -- DISTANCE ESP
            if ESP.Distance.Enabled then
                DistanceText.Visible = true
                local dist = 0
                if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    dist = math.floor((Player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                end
                DistanceText.Text = tostring(dist) .. " studs"
                DistanceText.Position = Vector2.new(Position.X + (Size.X / 2), Position.Y - 15)
                DistanceText.Color = ESP.Distance.Color
            else
                DistanceText.Visible = false
            end

            -- TRACERS
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

                TracerOutline.Color = ESP.Tracers.Color
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

            -- HEALTHBAR ESP
            if ESP.HealthBar.Enabled then
                local health = Player.Character.Humanoid.Health
                local maxHealth = Player.Character.Humanoid.MaxHealth
                local healthPercent = health / maxHealth

                HealthBarOutline.Visible = ESP.HealthBar.Outlines
                HealthBarOutline.Position = Vector2.new(Position.X - 6, Position.Y + Size.Y)
                HealthBarOutline.Size = Vector2.new(3, -Size.Y * healthPercent)
                HealthBarOutline.Thickness = 1

                HealthBar.Visible = true
                HealthBar.Position = HealthBarOutline.Position
                HealthBar.Size = HealthBarOutline.Size
                HealthBar.Color = ESP.HealthBar.Color

                HealthText.Visible = ESP.HealthBar.ShowNumber
                HealthText.Text = tostring(math.floor(health))
                HealthText.Position = Vector2.new(Position.X - 4.5, Position.Y + Size.Y - (Size.Y * healthPercent) - 15)
            else
                HealthBarOutline.Visible = false
                HealthBar.Visible = false
                HealthText.Visible = false
            end

            -- NAME ESP: Display the player's username above the Box ESP.
            NameESPText.Visible = true
            NameESPText.Text = Player.Name
            NameESPText.Position = Vector2.new(Position.X + (Size.X / 2), Position.Y - 20)
        end)
    end

    for i, v in pairs(Players:GetPlayers()) do 
        if v ~= LocalPlayer then AddESP(v) end
    end
    Players.PlayerAdded:Connect(function(v)
        AddESP(v)
    end)
end

---------------------------------------------------
-- Chams Functions (Highlight-based ESP)         --
---------------------------------------------------
local chamsStorage = nil
local chamsConnections = {}

local function EnableChams()
    local CoreGui = game:GetService("CoreGui")
    chamsStorage = Instance.new("Folder")
    chamsStorage.Parent = CoreGui
    chamsStorage.Name = "Highlight_Storage"

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer then
            local highlight = Instance.new("Highlight")
            highlight.Name = plr.Name
            -- Adjusted team check: Look for the ExpressionID at Workspace/[PlayerName]/Face/ExpressionID
            if getgenv().chamsTeamCheckEnabled then
                local playerModel = workspace:FindFirstChild(plr.Name)
                if playerModel then
                    local face = playerModel:FindFirstChild("Face")
                    if face then
                        local expr = face:FindFirstChild("ExpressionID")
                        if expr then
                            if expr.Value == 0 then
                                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                            elseif expr.Value == 3 then
                                highlight.FillColor = Color3.fromRGB(128, 0, 128)
                            elseif expr.Value == 5 then
                                highlight.FillColor = Color3.fromRGB(173, 216, 230)
                            else
                                highlight.FillColor = Color3.fromRGB(255, 255, 255)
                            end
                            expr.Changed:Connect(function(newVal)
                                if newVal == 0 then
                                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                                elseif newVal == 3 then
                                    highlight.FillColor = Color3.fromRGB(128, 0, 128)
                                elseif newVal == 5 then
                                    highlight.FillColor = Color3.fromRGB(173, 216, 230)
                                else
                                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                                end
                            end)
                        else
                            highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        end
                    else
                        highlight.FillColor = Color3.fromRGB(255, 255, 255)
                    end
                else
                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                end
            else
                highlight.FillColor = Color3.fromRGB(255, 255, 255)
            end
            highlight.DepthMode = "AlwaysOnTop"
            highlight.FillTransparency = (getgenv().chamsFillEnabled and 0.8 or 1)
            highlight.OutlineColor = Color3.fromRGB(255,255,255)
            highlight.OutlineTransparency = 0
            highlight.Parent = chamsStorage

            if plr.Character then
                highlight.Adornee = plr.Character
            end

            chamsConnections[plr] = plr.CharacterAdded:Connect(function(char)
                highlight.Adornee = char
            end)
        end
    end

    Players.PlayerAdded:Connect(function(plr)
        if plr ~= Players.LocalPlayer then
            local highlight = Instance.new("Highlight")
            highlight.Name = plr.Name
            if getgenv().chamsTeamCheckEnabled then
                local playerModel = workspace:FindFirstChild(plr.Name)
                if playerModel then
                    local face = playerModel:FindFirstChild("Face")
                    if face then
                        local expr = face:FindFirstChild("ExpressionID")
                        if expr then
                            if expr.Value == 0 then
                                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                            elseif expr.Value == 3 then
                                highlight.FillColor = Color3.fromRGB(128, 0, 128)
                            elseif expr.Value == 5 then
                                highlight.FillColor = Color3.fromRGB(173, 216, 230)
                            else
                                highlight.FillColor = Color3.fromRGB(255, 255, 255)
                            end
                            expr.Changed:Connect(function(newVal)
                                if newVal == 0 then
                                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                                elseif newVal == 3 then
                                    highlight.FillColor = Color3.fromRGB(128, 0, 128)
                                elseif newVal == 5 then
                                    highlight.FillColor = Color3.fromRGB(173, 216, 230)
                                else
                                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                                end
                            end)
                        else
                            highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        end
                    else
                        highlight.FillColor = Color3.fromRGB(255, 255, 255)
                    end
                else
                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                end
            else
                highlight.FillColor = Color3.fromRGB(255, 255, 255)
            end
            highlight.DepthMode = "AlwaysOnTop"
            highlight.FillTransparency = (getgenv().chamsFillEnabled and 0.8 or 1)
            highlight.OutlineColor = Color3.fromRGB(255,255,255)
            highlight.OutlineTransparency = 0
            highlight.Parent = chamsStorage

            if plr.Character then
                highlight.Adornee = plr.Character
            end

            chamsConnections[plr] = plr.CharacterAdded:Connect(function(char)
                highlight.Adornee = char
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if chamsStorage and chamsStorage:FindFirstChild(plr.Name) then
            chamsStorage[plr.Name]:Destroy()
        end
        if chamsConnections[plr] then
            chamsConnections[plr]:Disconnect()
            chamsConnections[plr] = nil
        end
    end)
end

local function DisableChams()
    if chamsStorage then
        chamsStorage:Destroy()
        chamsStorage = nil
    end
    for plr, conn in pairs(chamsConnections) do
        conn:Disconnect()
    end
    chamsConnections = {}
end

---------------------------------------------------
-- Skeleton ESP Library and Functions            --
---------------------------------------------------
local SkeletonLibrary = {}
do
    local WAIT = task.wait
    local TBINSERT = table.insert
    local V2 = Vector2.new
    local ROUND = math.round

    local RS = RunService
    local Camera = workspace.CurrentCamera
    local To2D = Camera.WorldToViewportPoint
    local LocalPlayer = Players.LocalPlayer

    function SkeletonLibrary:NewLine(info)
        local l = Drawing.new("Line")
        l.Visible = info.Visible or true
        l.Color = info.Color or Color3.fromRGB(0,255,0)
        l.Transparency = info.Transparency or 1
        l.Thickness = info.Thickness or 1
        return l
    end

    function SkeletonLibrary:Smoothen(v)
        return V2(ROUND(v.X), ROUND(v.Y))
    end

    local Skeleton = {
        Removed = false;
        Player = nil;
        Visible = false;
        Lines = {};
        Color = Color3.fromRGB(0,255,0);
        Alpha = 1;
        Thickness = 1;
        DoSubsteps = true;
    }
    Skeleton.__index = Skeleton;

    function Skeleton:UpdateStructure()
        if not self.Player.Character then return end
        self:RemoveLines()
        for _, part in next, self.Player.Character:GetChildren() do		
            if not part:IsA("BasePart") then continue end
            for _, link in next, part:GetChildren() do			
                if not link:IsA("Motor6D") then continue end
                TBINSERT(self.Lines, {
                    SkeletonLibrary:NewLine({
                        Visible = self.Visible;
                        Color = self.Color;
                        Transparency = self.Alpha;
                        Thickness = self.Thickness,
                    }),
                    SkeletonLibrary:NewLine({
                        Visible = self.Visible;
                        Color = self.Color;
                        Transparency = self.Alpha;
                        Thickness = self.Thickness,
                    }),
                    part.Name,
                    link.Name
                })
            end
        end
    end

    function Skeleton:SetVisible(State)
        for _, l in pairs(self.Lines) do
            l[1].Visible = State
            l[2].Visible = State
        end
    end

    function Skeleton:SetColor(Color)
        self.Color = Color
        for _, l in pairs(self.Lines) do
            l[1].Color = Color
            l[2].Color = Color
        end
    end

    function Skeleton:SetAlpha(Alpha)
        self.Alpha = Alpha
        for _, l in pairs(self.Lines) do
            l[1].Transparency = Alpha
            l[2].Transparency = Alpha
        end
    end

    function Skeleton:SetThickness(Thickness)
        self.Thickness = Thickness
        for _, l in pairs(self.Lines) do
            l[1].Thickness = Thickness
            l[2].Thickness = Thickness
        end
    end

    function Skeleton:SetDoSubsteps(State)
        self.DoSubsteps = State
    end

    function Skeleton:Update()
        if self.Removed then return end
        local Character = self.Player.Character
        if not Character then
            self:SetVisible(false)
            if not self.Player.Parent then
                self:Remove()
            end
            return
        end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            self:SetVisible(false)
            return
        end
        self:SetColor(self.Color)
        self:SetAlpha(self.Alpha)
        self:SetThickness(self.Thickness)
        local update = false
        for _, l in pairs(self.Lines) do
            local part = Character:FindFirstChild(l[3])
            if not part then
                l[1].Visible = false
                l[2].Visible = false
                update = true
                continue
            end
            local link = part:FindFirstChild(l[4])
            if not (link and link.Part0 and link.Part1) then
                l[1].Visible = false
                l[2].Visible = false
                update = true
                continue
            end
            local part0 = link.Part0
            local part1 = link.Part1
            if self.DoSubsteps and link.C0 and link.C1 then
                local c0 = link.C0
                local c1 = link.C1
                local part0p, v1 = To2D(Camera, part0.CFrame.p)
                local part0cp, v2 = To2D(Camera, (part0.CFrame * c0).p)
                if v1 and v2 then
                    l[1].From = Vector2.new(part0p.x, part0p.y)
                    l[1].To = Vector2.new(part0cp.x, part0cp.y)
                    l[1].Visible = true
                else 
                    l[1].Visible = false
                end
                local part1p, v3 = To2D(Camera, part1.CFrame.p)
                local part1cp, v4 = To2D(Camera, (part1.CFrame * c1).p)
                if v3 and v4 then
                    l[2].From = Vector2.new(part1p.x, part1p.y)
                    l[2].To = Vector2.new(part1cp.x, part1cp.y)
                    l[2].Visible = true
                else 
                    l[2].Visible = false
                end
            else					
                local part0p, v1 = To2D(Camera, part0.CFrame.p)
                local part1p, v2 = To2D(Camera, part1.CFrame.p)
                if v1 and v2 then
                    l[1].From = Vector2.new(part0p.x, part0p.y)
                    l[1].To = Vector2.new(part1p.x, part1p.y)
                    l[1].Visible = true
                else 
                    l[1].Visible = false
                end
                l[2].Visible = false
            end
        end
        if update or #self.Lines == 0 then
            self:UpdateStructure()
        end
    end

    function Skeleton:Toggle()
        self.Visible = not self.Visible
        if self.Visible then 
            self:RemoveLines()
            self:UpdateStructure()
            self._connection = RS.Heartbeat:Connect(function()
                if not getgenv().skeletonESPEnabled then
                    self:SetVisible(false)
                    if self._connection then self._connection:Disconnect() end
                    return
                end
                self:Update()
            end)
        else
            self:SetVisible(false)
            self:RemoveLines()
            if self._connection then
                self._connection:Disconnect()
                self._connection = nil
            end
        end
    end

    function Skeleton:RemoveLines()
        for _, l in pairs(self.Lines) do
            l[1]:Remove()
            l[2]:Remove()
        end
        self.Lines = {}
    end

    function Skeleton:Remove()
        self.Removed = true
        self:RemoveLines()
    end

    function SkeletonLibrary:NewSkeleton(Player, Visible, Color, Alpha, Thickness, DoSubsteps)
        if not Player then error("Missing Player argument (#1)") end
        local s = setmetatable({}, Skeleton)
        s.Player = Player
        s.Bind = Player.UserId
        if DoSubsteps ~= nil then s.DoSubsteps = DoSubsteps end
        if Color then s:SetColor(Color) end
        if Alpha then s:SetAlpha(Alpha) end
        if Thickness then s:SetThickness(Thickness) end
        if Visible then s:Toggle() end
        return s
    end
end

local skeletonESPEnabled = false
local Skeletons = {}

local function EnableSkeletonESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local sk = SkeletonLibrary:NewSkeleton(plr, true, getgenv().skeletonESPColor or Color3.fromRGB(255,255,255), 1, 1, true)
            Skeletons[plr] = sk
        end
    end
    Players.PlayerAdded:Connect(function(plr)
        if plr ~= LocalPlayer then
            local sk = SkeletonLibrary:NewSkeleton(plr, true, getgenv().skeletonESPColor or Color3.fromRGB(255,255,255), 1, 1, true)
            Skeletons[plr] = sk
        end
    end)
end

local function DisableSkeletonESP()
    for plr, sk in pairs(Skeletons) do
        if sk and sk.Remove then
            sk:Remove()
        end
    end
    Skeletons = {}
end

---------------------------------------------------
-- Input Event Listeners                         --
---------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if (input.KeyCode and input.KeyCode == currentAimKey) or (input.UserInputType and input.UserInputType == currentAimKey) then
		Aiming = true
		if getgenv().aim_settings.hitbox == "Random" then
		    randomPart = nil
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if (input.KeyCode and input.KeyCode == currentAimKey) or (input.UserInputType and input.UserInputType == currentAimKey) then
		Aiming = false
		currentTarget = nil
		randomPart = nil
	end
end)

---------------------------------------------------
-- GUI: Aim Assist Tab                           --
---------------------------------------------------
local aimBasic = tabs.AimAssist:Section({ Side = "Left" })
aimBasic:Toggle({
	Name = "Aim Assist",
	Default = false,
	Callback = function(Value)
		getgenv().aim_settings.enabled = Value
		if not Value then
			Aiming = false
			currentTarget = nil
		end
	end,
}, "AimAssistToggle")

aimBasic:Keybind({
	Name = "Aim Key",
	Default = currentAimKey,
	Callback = function(binded)
		getgenv().aim_settings.aimKey = binded
		currentAimKey = binded
	end,
	onBinded = function(bind)
		getgenv().aim_settings.aimKey = bind
		currentAimKey = bind
	end,
	onBindHeld = function() return Aiming, currentAimKey end,
}, "AimKey")

aimBasic:Toggle({
	Name = "FOV Circle",
	Default = false,
	Callback = function(Value)
		getgenv().aim_settings.fovcircle = Value
	end,
}, "FOVCircleToggle")

aimBasic:Slider({
	Name = "FOV Size",
	Default = getgenv().aim_settings.fov,
	Minimum = 1,
	Maximum = 800,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().aim_settings.fov = Value
		Window:Notify({ Title = "FOV Size", Description = "FOV size set to: " .. tostring(Value), Lifetime = 5 })
	end,
}, "FOVSizeSlider")

aimBasic:Dropdown({
	Name = "Aim Target",
	Multi = false,
	Required = true,
	Search = true,
	Default = "Head",
	Options = {"Head", "HumanoidRootPart", "Random", "Nearest"},
	Callback = function(Value)
		getgenv().aim_settings.hitbox = Value
		Window:Notify({ Title = "Aim Target", Description = "Target set to: " .. tostring(Value), Lifetime = 5 })
	end,
}, "AimTargetDropdown")

local aimFOV = tabs.AimAssist:Section({ Side = "Right" })
aimFOV:Dropdown({
	Name = "Aim Assist Method",
	Multi = false,
	Required = true,
	Search = true,
	Default = "Camera",
	Options = {"Camera", "Mouse"},
	Callback = function(Value)
		getgenv().aim_settings.method = Value
	end,
}, "AimMethodDropdown")

aimFOV:Slider({
	Name = "FOV Thickness",
	Default = getgenv().aim_settings.fovThickness,
	Minimum = 1,
	Maximum = 5,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().aim_settings.fovThickness = Value
	end,
}, "FOVThicknessSlider")

aimFOV:Colorpicker({
	Name = "FOV Circle Color",
	Default = getgenv().aim_settings.fovCircleColor,
	Alpha = 0,
	Callback = function(color, alpha)
		getgenv().aim_settings.fovCircleColor = color
	end,
}, "FOVCircleColorPicker")

aimFOV:Toggle({
	Name = "FOV Circle Filled",
	Default = getgenv().aim_settings.fovCircleFilled,
	Callback = function(Value)
		getgenv().aim_settings.fovCircleFilled = Value
	end,
}, "FOVCircleFilledToggle")

aimFOV:Slider({
	Name = "Fov Transparency",
	Default = getgenv().aim_settings.fovCircleTransparency,
	Minimum = 0.1,
	Maximum = 1,
	DisplayMethod = "Value",
	Precision = 2,
	Callback = function(Value)
		getgenv().aim_settings.fovCircleTransparency = Value
	end,
}, "FOVCircleTransparencySlider")

---------------------------------------------------
-- GUI: Visuals Tab                              --
---------------------------------------------------
local visualsLeft = tabs.Visuals:Section({ Side = "Left" })
local visualsRight = tabs.Visuals:Section({ Side = "Right" })
-- Main ESP toggles
visualsLeft:Toggle({
	Name = "Box ESP",
	Default = false,
	Callback = function(Value)
		ESP.Box.Enabled = Value
		Window:Notify({ Title = "Box ESP", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
	end,
}, "BoxESPToggle")
visualsLeft:Toggle({
	Name = "Tracers",
	Default = false,
	Callback = function(Value)
		ESP.Tracers.Enabled = Value
		Window:Notify({ Title = "Tracers", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
	end,
}, "TracersToggle")
visualsLeft:Toggle({
	Name = "Skeleton ESP",
	Default = false,
	Callback = function(Value)
         getgenv().skeletonESPEnabled = Value
         if Value then
              EnableSkeletonESP()
         else
              DisableSkeletonESP()
         end
         Window:Notify({ Title = "Skeleton ESP", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
	end,
}, "SkeletonESPToggle")
visualsLeft:Toggle({
	Name = "Healthbar",
	Default = false,
	Callback = function(Value)
		ESP.HealthBar.Enabled = Value
		ESP.HealthBar.ShowNumber = Value
		Window:Notify({ Title = "Healthbar", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
	end,
}, "HealthbarToggle")
visualsLeft:Toggle({
	Name = "Tool ESP",
	Default = false,
	Callback = function(Value)
		ESP.Tool.Enabled = Value
		Window:Notify({ Title = "Tool ESP", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
	end,
}, "ToolESPToggle")
visualsLeft:Toggle({
	Name = "Distance ESP",
	Default = false,
	Callback = function(Value)
		ESP.Distance.Enabled = Value
		Window:Notify({ Title = "Distance ESP", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
	end,
}, "DistanceESPToggle")
visualsLeft:Toggle({
    Name = "Chams",
    Default = false,
    Callback = function(Value)
         getgenv().chamsEnabled = Value
         if Value then
              EnableChams()
         else
              DisableChams()
         end
         Window:Notify({ Title = "Chams", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
    end,
}, "ChamsToggle")
-- ESP Customization Options
local espCustom = tabs.Visuals:Section({ Side = "Left", Title = "ESP Customization", VerticalOrder = true })
espCustom:Dropdown({
    Name = "Tracer Origin",
    Multi = false,
    Required = true,
    Search = true,
    Default = "Bottom",
    Options = {"Bottom", "Middle", "Top", "Mouse"},
    Callback = function(Value)
        currentTracerPosition = Value
    end,
}, "TracerOriginDropdown")
espCustom:Slider({
    Name = "Tracer Thickness",
    Default = ESP.Tracers.Thickness,
    Minimum = 1,
    Maximum = 5,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        ESP.Tracers.Thickness = Value
    end,
}, "TracerThicknessSlider")
espCustom:Dropdown({
    Name = "Box ESP Type",
    Multi = false,
    Required = true,
    Search = true,
    Default = "2D",
    Options = {"2D", "3D", "Corners"},
    Callback = function(Value)
        getgenv().boxESPType = Value
    end,
}, "BoxESPTypeDropdown")
espCustom:Toggle({
    Name = "Box ESP Filled",
    Default = false,
    Callback = function(Value)
        getgenv().boxESPFilled = Value
    end,
}, "BoxESPFilledToggle")
espCustom:Toggle({
    Name = "Chams Fill",
    Default = false,
    Callback = function(Value)
         getgenv().chamsFillEnabled = Value
         if chamsStorage then
             for _, highlight in pairs(chamsStorage:GetChildren()) do
                 if highlight:IsA("Highlight") then
                     highlight.FillTransparency = (Value and 0.8 or 1)
                 end
             end
         end
    end,
}, "ChamsFillToggle")

-- Visuals Right Color Pickers (except Chams Color picker is removed)
visualsRight:Colorpicker({
    Name = "Box ESP Color",
    Default = ESP.Box.Color,
    Alpha = 0,
    Callback = function(color, alpha)
        ESP.Box.Color = color
    end,
}, "BoxESPColor")
visualsRight:Colorpicker({
    Name = "Tracers Color",
    Default = ESP.Tracers.Color,
    Alpha = 0,
    Callback = function(color, alpha)
        ESP.Tracers.Color = color
    end,
}, "TracersColor")
visualsRight:Colorpicker({
    Name = "Skeleton ESP Color",
    Default = getgenv().skeletonESPColor or Color3.fromRGB(255,255,255),
    Alpha = 0,
    Callback = function(color, alpha)
         getgenv().skeletonESPColor = color
         for plr, sk in pairs(Skeletons) do
             if sk then sk:SetColor(color) end
         end
    end,
}, "SkeletonESPColor")
visualsRight:Colorpicker({
    Name = "HealthBar ESP Color",
    Default = ESP.HealthBar.Color,
    Alpha = 0,
    Callback = function(color, alpha)
        ESP.HealthBar.Color = color
    end,
}, "HealthBarESPColor")
visualsRight:Colorpicker({
    Name = "Tool ESP Color",
    Default = ESP.Tool.Color,
    Alpha = 0,
    Callback = function(color, alpha)
        ESP.Tool.Color = color
    end,
}, "ToolESPColor")
visualsRight:Colorpicker({
    Name = "Distance ESP Color",
    Default = ESP.Distance.Color,
    Alpha = 0,
    Callback = function(color, alpha)
        ESP.Distance.Color = color
    end,
}, "DistanceESPColor")
-- Chams Team Check toggle remains
visualsRight:Toggle({
    Name = "Chams Team Check",
    Default = false,
    Callback = function(Value)
         getgenv().chamsTeamCheckEnabled = Value
         if chamsStorage then
             for _, highlight in pairs(chamsStorage:GetChildren()) do
                 if highlight:IsA("Highlight") then
                     local plr = Players:FindFirstChild(highlight.Name)
                     if getgenv().chamsTeamCheckEnabled then
                         local playerModel = workspace:FindFirstChild(plr.Name)
                         if playerModel then
                             local face = playerModel:FindFirstChild("Face")
                             if face then
                                 local expr = face:FindFirstChild("ExpressionID")
                                 if expr then
                                     if expr.Value == 0 then
                                         highlight.FillColor = Color3.fromRGB(0, 255, 0)
                                     elseif expr.Value == 3 then
                                         highlight.FillColor = Color3.fromRGB(128, 0, 128)
                                     elseif expr.Value == 5 then
                                         highlight.FillColor = Color3.fromRGB(173, 216, 230)
                                     else
                                         highlight.FillColor = Color3.fromRGB(255, 255, 255)
                                     end
                                     expr.Changed:Connect(function(newVal)
                                         if newVal == 0 then
                                             highlight.FillColor = Color3.fromRGB(0, 255, 0)
                                         elseif newVal == 3 then
                                             highlight.FillColor = Color3.fromRGB(128, 0, 128)
                                         elseif newVal == 5 then
                                             highlight.FillColor = Color3.fromRGB(173, 216, 230)
                                         else
                                             highlight.FillColor = Color3.fromRGB(255, 255, 255)
                                         end
                                     end)
                                 else
                                     highlight.FillColor = Color3.fromRGB(255, 255, 255)
                                 end
                             else
                                 highlight.FillColor = Color3.fromRGB(255, 255, 255)
                             end
                         else
                             highlight.FillColor = Color3.fromRGB(255, 255, 255)
                         end
                     else
                         highlight.FillColor = Color3.fromRGB(255, 255, 255)
                     end
                 end
             end
         end
         Window:Notify({ Title = "Chams Team Check", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
    end,
}, "ChamsTeamCheckToggle")

---------------------------------------------------
-- GUI: Player Tab (Other)                        --
---------------------------------------------------
local playerSection = tabs.Player:Section({ Side = "Left" })

local defaultWalkSpeed = 16
local defaultJumpPower = 50

playerSection:Toggle({
    Name = "Speed",
    Default = false,
    Callback = function(Value)
        getgenv().speedEnabled = Value
        Window:Notify({ Title = "Speed", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
    end,
}, "SpeedToggle")

playerSection:Slider({
    Name = "Speed Value",
    Default = 16,
    Minimum = 16,
    Maximum = 500,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().speedValue = Value
        Window:Notify({ Title = "Speed Value", Description = "Speed set to: " .. tostring(Value), Lifetime = 5 })
    end,
}, "SpeedSlider")

local jumpSection = tabs.Player:Section({ Side = "Left", Title = "Jump" })
jumpSection:Toggle({
    Name = "Jump Height",
    Default = false,
    Callback = function(Value)
        getgenv().jumpEnabled = Value
        Window:Notify({ Title = "Jump Height", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
    end,
}, "JumpToggle")

jumpSection:Slider({
    Name = "Jump Height Value",
    Default = 50,
    Minimum = 50,
    Maximum = 250,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().jumpValue = Value
        Window:Notify({ Title = "Jump Height", Description = "Jump Height set to: " .. tostring(Value), Lifetime = 5 })
    end,
}, "JumpSlider")

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if getgenv().speedEnabled then
                humanoid.WalkSpeed = getgenv().speedValue or defaultWalkSpeed
            else
                humanoid.WalkSpeed = defaultWalkSpeed
            end
            if getgenv().jumpEnabled then
                humanoid.JumpPower = getgenv().jumpValue or defaultJumpPower
            else
                humanoid.JumpPower = defaultJumpPower
            end
        end
    end
end)

---------------------------------------------------
-- Finalize GUI                                  --
---------------------------------------------------
tabs.AimAssist:Select()

Window:Notify({
	Title = "Collapse:Vampire Hunters 3",
	Description = "Script loaded successfully! - Made by Finny <3",
	Lifetime = 5
})
