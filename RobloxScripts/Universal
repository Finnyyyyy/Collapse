-- Load MacLib from the demo (new GUI)
local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

-- Create the main window using MacLib (GUI size set to 800x500) with keybind set to RightShift
local Window = MacLib:Window({
	Title = "Collapse | Vh3",
	Subtitle = "| Made by Finny <3",
	Size = UDim2.fromOffset(800, 500),
	DragStyle = 2,
	DisabledWindowControls = {},
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightShift, -- changed keybind to RightShift
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

-- Create Tab Groups
local tabGroups = {
	Aim = Window:TabGroup(),
	World = Window:TabGroup(),
	Other = Window:TabGroup()
}

-- Create Tabs in the desired order: Aim Assist, Visuals, Player, then Settings.
local tabs = {
	AimAssist = tabGroups.Aim:Tab({ Name = "Aim Assist", Image = "rbxassetid://99275039709063" }),
	Visuals = tabGroups.World:Tab({ Name = "Visuals", Image = "rbxassetid://104811813262009" }),
	Player = tabGroups.Other:Tab({ Name = "Player", Image = "rbxassetid://603107593" }), -- using an eye-like icon
	Settings = tabGroups.Other:Tab({ Name = "Settings", Image = "rbxassetid://110807522910450" })
}

tabs.Settings:InsertConfigSection("Left")

--------------------------------------------
-- Existing Game Services and Variables  --
--------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Current Tracer Position and Aim Variables
local currentTracerPosition = "Bottom"  -- default tracer position
local Aiming = false
local currentTarget = nil

-- ESP Table (for visuals only)
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

--------------------------------------------------
-- Global ESP Distance Check Settings (for ESP) --
--------------------------------------------------
if getgenv().distanceCheckEnabled == nil then
    getgenv().distanceCheckEnabled = false
end
if getgenv().distanceCheckValue == nil then
    getgenv().distanceCheckValue = 500
end

--------------------------------------------------
-- Aim Settings and FOV Circle Setup              --
--------------------------------------------------
getgenv().aim_settings = {
    enabled = false,
    fov = 150,
    hitbox = "Head",  -- default target is head
    fovcircle = false,
    aimKey = Enum.KeyCode.E,
    
    -- FOV circle customizations:
    method = "Camera",           -- "Camera" (default) or "Mouse"
    fovThickness = 1,            -- thickness of the FOV circle
    fovCircleColor = Color3.fromRGB(255,255,255),
    fovCircleFilled = false,     -- whether the circle is filled
    fovCircleTransparency = 1,   -- transparency (0.1 to 1)
    
    -- Smoothing and Prediction settings:
    enableSmoothness = false,    -- when enabled, makes lock-on less snappy
    smoothnessX = 1,             -- affects interpolation factor
    smoothnessY = 1,             -- affects interpolation factor
    enablePredictions = false,   -- offsets the target position
    predictionOffsetX = 0,       -- x offset in studs
    predictionOffsetY = 0        -- y offset in studs
}
local currentAimKey = getgenv().aim_settings.aimKey

-- Create a FOV Circle drawing
local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = getgenv().aim_settings.fovThickness
Circle.Color = getgenv().aim_settings.fovCircleColor
Circle.Transparency = getgenv().aim_settings.fovCircleTransparency
Circle.Filled = getgenv().aim_settings.fovCircleFilled
Circle.NumSides = 64

---------------------------
-- Aiming Functionality  --
---------------------------
local function AimLock()
    local mousePos = UserInputService:GetMouseLocation()
    
    local targetPart = nil
    if currentTarget and currentTarget.Character then
        targetPart = currentTarget.Character:FindFirstChild(getgenv().aim_settings.hitbox)
    end
    
    if targetPart then
        local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position)
        local screenPosition = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (mousePos - screenPosition).Magnitude
        
        if onScreen and distance <= getgenv().aim_settings.fov then
            local pos = CurrentCamera.CFrame.Position
            local targetPos = targetPart.Position
            if getgenv().aim_settings.enablePredictions then
                targetPos = targetPos + Vector3.new(getgenv().aim_settings.predictionOffsetX, getgenv().aim_settings.predictionOffsetY, 0)
            end
            local desiredLook = (targetPos - pos).Unit
            if getgenv().aim_settings.enableSmoothness then
                local smoothFactor = 1 / ((getgenv().aim_settings.smoothnessX + getgenv().aim_settings.smoothnessY) / 2)
                local currentLook = CurrentCamera.CFrame.LookVector
                local newLook = currentLook:Lerp(desiredLook, smoothFactor)
                CurrentCamera.CFrame = CFrame.new(pos, pos + newLook)
            else
                CurrentCamera.CFrame = CFrame.new(pos, pos + desiredLook)
            end
            return
        end
    end

    currentTarget = nil
    local lastMagnitude = math.huge
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local part = v.Character:FindFirstChild(getgenv().aim_settings.hitbox)
            if part then
                local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(part.Position)
                local screenPosition = Vector2.new(screenPos.X, screenPos.Y)
                local dist = (mousePos - screenPosition).Magnitude
                if onScreen and dist <= getgenv().aim_settings.fov then
                    if dist < lastMagnitude then
                        lastMagnitude = dist
                        currentTarget = v
                    end
                end
            end
        end
    end
    
    if currentTarget and currentTarget.Character then
        local part = currentTarget.Character:FindFirstChild(getgenv().aim_settings.hitbox)
        if part then
            local pos = CurrentCamera.CFrame.Position
            local targetPos = part.Position
            if getgenv().aim_settings.enablePredictions then
                targetPos = targetPos + Vector3.new(getgenv().aim_settings.predictionOffsetX, getgenv().aim_settings.predictionOffsetY, 0)
            end
            local desiredLook = (targetPos - pos).Unit
            if getgenv().aim_settings.enableSmoothness then
                local smoothFactor = 1 / ((getgenv().aim_settings.smoothnessX + getgenv().aim_settings.smoothnessY) / 2)
                local currentLook = CurrentCamera.CFrame.LookVector
                local newLook = currentLook:Lerp(desiredLook, smoothFactor)
                CurrentCamera.CFrame = CFrame.new(pos, pos + newLook)
            else
                CurrentCamera.CFrame = CFrame.new(pos, pos + desiredLook)
            end
        end
    end
end

------------------
-- ESP Functions --
------------------
-- (This Functions table is used solely by the ESP)
local Functions = {}
do 
    function Functions:IsAlive(Player)
        return Player and Player.Character and Player.Character:FindFirstChild("Head") and 
               Player.Character:FindFirstChild("Humanoid") and 
               Player.Character.Humanoid.Health > 0
    end
    
    function Functions:GetEquippedTool(Player)
        if Player and Player.Character then
            local Tool = Player.Character:FindFirstChildOfClass("Tool")
            if Tool then return Tool.Name end
        end
        return "None"
    end
    
    function Functions:GetDistance(Player)
        if Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and 
           LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return math.floor((Player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
        end
        return 0
    end
end

--------------------
-- ESP Rendering  --
--------------------
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
        local Connection

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
            BoxOutline.Visible = false
            Box.Visible = false
            TracerOutline.Visible = false
            Tracer.Visible = false
            HealthBarOutline.Visible = false
            HealthBar.Visible = false
            ToolText.Visible = false
            DistanceText.Visible = false
            HealthText.Visible = false
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
            HealthText:Remove()
            if Connection then Connection:Disconnect() end
        end

        Connection = RunService.RenderStepped:Connect(function()
            if not ESP.Enabled then return HideESP() end
            if not Player or not Player.Parent then return DestroyESP() end
            if not Functions:IsAlive(Player) then return HideESP() end

            local HumanoidRootPart = Player.Character.HumanoidRootPart
            if not HumanoidRootPart then return HideESP() end

            -- For ESP only: if distance check is enabled and the player is beyond the limit, hide drawings.
            if getgenv().distanceCheckEnabled and Functions:GetDistance(Player) > getgenv().distanceCheckValue then
                BoxOutline.Visible = false
                Box.Visible = false
                TracerOutline.Visible = false
                Tracer.Visible = false
                HealthBarOutline.Visible = false
                HealthBar.Visible = false
                ToolText.Visible = false
                DistanceText.Visible = false
                HealthText.Visible = false
                return
            end

            local ScreenPosition, OnScreen = CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position)
            if not OnScreen then return HideESP() end

            local FrustumHeight = math.tan(math.rad(CurrentCamera.FieldOfView * 0.5)) * 2 * ScreenPosition.Z
            local Size = CurrentCamera.ViewportSize.Y / FrustumHeight * Vector2.new(5,6)
            local Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Size / 2

            if ESP.Box.Enabled then
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
        end)
    end

    for i, v in pairs(Players:GetPlayers()) do 
        if v ~= LocalPlayer then AddESP(v) end
    end

    Players.PlayerAdded:Connect(function(v)
        AddESP(v)
    end)
end

---------------------------
-- FOV Circle & Aim Loop  --
---------------------------
RunService.RenderStepped:Connect(function()
    if getgenv().aim_settings.enabled and Aiming then
        AimLock()
    end
    
    Circle.Position = UserInputService:GetMouseLocation()
    Circle.Radius = getgenv().aim_settings.fov
    Circle.Thickness = getgenv().aim_settings.fovThickness
    Circle.Color = getgenv().aim_settings.fovCircleColor
    Circle.Transparency = getgenv().aim_settings.fovCircleTransparency
    Circle.Filled = getgenv().aim_settings.fovCircleFilled
    Circle.Visible = getgenv().aim_settings.fovcircle
end)

--------------------------
-- Input Event Listeners --
--------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if (input.KeyCode and input.KeyCode == currentAimKey) or (input.UserInputType and input.UserInputType == currentAimKey) then
		Aiming = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if (input.KeyCode and input.KeyCode == currentAimKey) or (input.UserInputType and input.UserInputType == currentAimKey) then
		Aiming = false
		currentTarget = nil
	end
end)

--------------------------
-- GUI: Aim Assist Tab --
--------------------------
-- Left Column: Basic Controls then Smooth & Prediction settings
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
	Options = {"Head", "HumanoidRootPart"},
	Callback = function(Value)
		getgenv().aim_settings.hitbox = Value
		Window:Notify({ Title = "Aim Target", Description = "Target set to: " .. tostring(Value), Lifetime = 5 })
	end,
}, "AimTargetDropdown")

-- Below Basic Controls: Smoothness & Prediction
local aimSmooth = tabs.AimAssist:Section({ Side = "Left", VerticalOrder = true })
aimSmooth:Toggle({
	Name = "Enable Smoothness",
	Default = false,
	Callback = function(Value)
		getgenv().aim_settings.enableSmoothness = Value
	end,
}, "SmoothnessToggle")

aimSmooth:Slider({
	Name = "Smoothness X",
	Default = getgenv().aim_settings.smoothnessX,
	Minimum = 1,
	Maximum = 10,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().aim_settings.smoothnessX = Value
	end,
}, "SmoothnessXSlider")

aimSmooth:Slider({
	Name = "Smoothness Y",
	Default = getgenv().aim_settings.smoothnessY,
	Minimum = 1,
	Maximum = 10,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().aim_settings.smoothnessY = Value
	end,
}, "SmoothnessYSlider")

aimSmooth:Toggle({
	Name = "Enable Predictions",
	Default = false,
	Callback = function(Value)
		getgenv().aim_settings.enablePredictions = Value
	end,
}, "PredictionsToggle")

aimSmooth:Slider({
	Name = "Prediction Offset X",
	Default = getgenv().aim_settings.predictionOffsetX,
	Minimum = -10,
	Maximum = 10,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().aim_settings.predictionOffsetX = Value
	end,
}, "PredictionOffsetXSlider")

aimSmooth:Slider({
	Name = "Prediction Offset Y",
	Default = getgenv().aim_settings.predictionOffsetY,
	Minimum = -10,
	Maximum = 10,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().aim_settings.predictionOffsetY = Value
	end,
}, "PredictionOffsetYSlider")

-- Right Column: FOV Circle Customizations
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

----------------------------
-- GUI: Visuals Tab --
----------------------------
local visualsLeft = tabs.Visuals:Section({ Side = "Left" })
local visualsRight = tabs.Visuals:Section({ Side = "Right" })

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

visualsLeft:Dropdown({
	Name = "Tracer Position",
	Multi = false,
	Required = true,
	Search = true,
	Default = "Bottom",
	Options = {"Bottom", "Middle", "Top", "Mouse"},
	Callback = function(Value)
		currentTracerPosition = Value
	end,
}, "TracerPositionDropdown")

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

-- Checks Section (for ESP only – distance filtering)
local visualsChecks = tabs.Visuals:Section({ Side = "Left", Title = "Checks" })
visualsChecks:Toggle({
    Name = "Distance Check",
    Default = false,
    Callback = function(Value)
        getgenv().distanceCheckEnabled = Value
        Window:Notify({ Title = "Distance Check", Description = (Value and "Enabled" or "Disabled"), Lifetime = 5 })
    end,
}, "VisualsDistanceCheckToggle")
visualsChecks:Slider({
    Name = "Distance Limit",
    Default = 500,
    Minimum = 100,
    Maximum = 500,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().distanceCheckValue = Value
        Window:Notify({ Title = "Distance Limit", Description = "Distance limit set to: " .. tostring(Value), Lifetime = 5 })
    end,
}, "VisualsDistanceLimitSlider")

visualsRight:Colorpicker({
	Name = "Box ESP Color",
	Default = ESP.Box.Color,
	Alpha = 0,
	Callback = function(color, alpha)
		ESP.Box.Color = color
	end,
}, "BoxESPColor")

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

visualsRight:Colorpicker({
	Name = "Tracers Color",
	Default = ESP.Tracers.Color,
	Alpha = 0,
	Callback = function(color, alpha)
		ESP.Tracers.Color = color
	end,
}, "TracersColor")

visualsRight:Colorpicker({
	Name = "HealthBar ESP Color",
	Default = ESP.HealthBar.Color,
	Alpha = 0,
	Callback = function(color, alpha)
		ESP.HealthBar.Color = color
	end,
}, "HealthBarESPColor")

----------------------------
-- GUI: Player Tab (Other)  --
----------------------------
local playerSection = tabs.Player:Section({ Side = "Left" })

-- Default values
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
    Maximum = 500, -- increased max speed to 500
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
    Maximum = 250, -- increased max jump height to 250
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().jumpValue = Value
        Window:Notify({ Title = "Jump Height", Description = "Jump Height set to: " .. tostring(Value), Lifetime = 5 })
    end,
}, "JumpSlider")

-- Continuously update player speed and jump height if toggled
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

---------------------
-- Finalize GUI  --
---------------------
tabs.AimAssist:Select()

Window:Notify({
	Title = "Collapse:Vampire Hunters 3",
	Description = "Script loaded successfully! - Made by Finny <3",
	Lifetime = 5
})
