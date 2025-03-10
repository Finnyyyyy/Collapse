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

-- Create Tabs
local tabs = {
	AimAssist = tabGroups.Aim:Tab({ Name = "Aim Assist", Image = "rbxassetid://99275039709063" }),
	Visuals = tabGroups.World:Tab({ Name = "Visuals", Image = "rbxassetid://104811813262009" }),
	Settings = tabGroups.Other:Tab({ Name = "Settings", Image = "rbxassetid://110807522910450" })
}

tabs.Settings:InsertConfigSection("Left")

--------------------------------------------
-- Existing Game Services and Variables  --
--------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folder for Item ESP
local itemPointsFolder = workspace:WaitForChild("GameStuff"):WaitForChild("Map"):WaitForChild("Data"):WaitForChild("GamePoints"):WaitForChild("ItemPoints")

-- Current Tracer Position and Aim Variables
local currentTracerPosition = "Bottom"  -- default tracer position
local Aiming = false
local currentTarget = nil

-- ESP Table (for original ESPs)
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

-- Aim Settings (global) with extra customization defaults
getgenv().aim_settings = {
    enabled = false,
    fov = 150,
    hitbox = "Head",  -- default target is head
    fovcircle = false,
    aimKey = Enum.KeyCode.E,
    
    -- FOV circle customizations:
    method = "Camera",           -- Dropdown: "Camera" (default) or "Mouse"
    fovThickness = 1,            -- Slider 1 to 5 (thickness of the FOV circle)
    fovCircleColor = Color3.fromRGB(255,255,255),
    fovCircleFilled = false,     -- Whether the circle is filled
    fovCircleTransparency = 1,   -- Slider 0.1 to 1, applies to the entire circle
    
    -- Smoothing and Prediction settings:
    enableSmoothness = false,    -- When enabled, makes lock-on less snappy
    smoothnessX = 1,             -- Slider 1 to 10 (affects interpolation factor)
    smoothnessY = 1,             -- Slider 1 to 10 (we average these for simplicity)
    enablePredictions = false,   -- When enabled, offsets the target position
    predictionOffsetX = 0,       -- Slider -10 to 10 (in studs; x offset)
    predictionOffsetY = 0        -- Slider -10 to 10 (in studs; y offset)
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
            -- Apply prediction offset if enabled
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
-- Left Column: Basic Controls and then below it, Smooth & Prediction settings
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

-- Below Basic Controls: Smoothness & Prediction (in a separate section below on the left)
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

--[[ 
    ============================
    New ESPs Begin Here:
    ============================
--]]

-------------------------------------
-- Global variables for new ESPs --
-------------------------------------
getgenv().itemESPEnabled = false
getgenv().skeletonESPEnabled = false
getgenv().chamsEnabled = false
getgenv().armChamsEnabled = false

getgenv().skeletonESPColor = Color3.fromRGB(255,255,255)
getgenv().chamsColor = Color3.fromRGB(255,255,255)
getgenv().armChamsColor = Color3.fromRGB(255,255,255)

local itemESPConnection = nil
local itemESPObjects = {}

local skeletons = {}
local skeletonAddedConnection = nil

local chamConnections = {}
local chamsFolder = nil

local armChamsConnections = {}
local armChamsPlayerAddedConnection = nil

-----------------------
-- ITEM ESP Functions
-----------------------
local function updateItemESP()
    if not getgenv().itemESPEnabled then
        for _, data in pairs(itemESPObjects) do
            if data.box then data.box:Remove() end
            if data.text then data.text:Remove() end
        end
        itemESPObjects = {}
        return
    end

    for _, item in ipairs(itemPointsFolder:GetChildren()) do
        if item:IsA("BasePart") then
            if item:FindFirstChild("Used") then
                if itemESPObjects[item] then
                    itemESPObjects[item].box:Remove()
                    itemESPObjects[item].text:Remove()
                    itemESPObjects[item] = nil
                end
            else
                if not itemESPObjects[item] then
                    local box = Drawing.new("Square")
                    box.Color = Color3.new(1,1,1)
                    box.Thickness = 1
                    box.Transparency = 1
                    box.Filled = false
                    box.Visible = true

                    local text = Drawing.new("Text")
                    text.Color = Color3.new(1,1,1)
                    text.Size = 12
                    text.Center = true
                    text.Outline = true
                    text.Visible = true

                    itemESPObjects[item] = {box = box, text = text}
                end

                local pos, onScreen = CurrentCamera:WorldToViewportPoint(item.Position)
                if onScreen then
                    -- Compute bounding box from the part's corners
                    local cf = item.CFrame
                    local size = item.Size
                    local corners = {}
                    for dx = -0.5, 0.5, 1 do
                        for dy = -0.5, 0.5, 1 do
                            for dz = -0.5, 0.5, 1 do
                                local offset = Vector3.new(dx * size.X, dy * size.Y, dz * size.Z)
                                local worldCorner = cf:PointToWorldSpace(offset)
                                local cornerPos, visible = CurrentCamera:WorldToViewportPoint(worldCorner)
                                if visible then
                                    table.insert(corners, Vector2.new(cornerPos.X, cornerPos.Y))
                                end
                            end
                        end
                    end
                    if #corners > 0 then
                        local minX, minY = math.huge, math.huge
                        local maxX, maxY = -math.huge, -math.huge
                        for _, corner in ipairs(corners) do
                            if corner.X < minX then minX = corner.X end
                            if corner.Y < minY then minY = corner.Y end
                            if corner.X > maxX then maxX = corner.X end
                            if corner.Y > maxY then maxY = corner.Y end
                        end
                        itemESPObjects[item].box.Position = Vector2.new(minX, minY)
                        itemESPObjects[item].box.Size = Vector2.new(maxX - minX, maxY - minY)
                        itemESPObjects[item].box.Visible = true

                        local textPos = Vector2.new((minX + maxX)/2, minY - 15)
                        itemESPObjects[item].text.Position = textPos
                        itemESPObjects[item].text.Text = item.Name
                        itemESPObjects[item].text.Visible = true
                    else
                        itemESPObjects[item].box.Visible = false
                        itemESPObjects[item].text.Visible = false
                    end
                else
                    itemESPObjects[item].box.Visible = false
                    itemESPObjects[item].text.Visible = false
                end
            end
        end
    end

    -- Clean up items that no longer exist
    for item, data in pairs(itemESPObjects) do
        if not item.Parent then
            data.box:Remove()
            data.text:Remove()
            itemESPObjects[item] = nil
        end
    end
end

---------------------------
-- SKELETON ESP Functions --
---------------------------
-- Skeleton Library (modified to default to white)
local SkeletonLibrary = {}
SkeletonLibrary.__index = SkeletonLibrary

function SkeletonLibrary:NewLine(info)
	local l = Drawing.new("Line")
	l.Visible = info.Visible or true
	l.Color = info.Color or Color3.new(1,1,1)
	l.Transparency = info.Transparency or 1
	l.Thickness = info.Thickness or 1
	return l
end

function SkeletonLibrary:Smoothen(v)
	return Vector2.new(math.round(v.X), math.round(v.Y))
end

local Skeleton = {
	Removed = false,
	Player = nil,
	Visible = false,
	Lines = {},
	Color = Color3.new(1,1,1),
	Alpha = 1,
	Thickness = 1,
	DoSubsteps = true,
}
Skeleton.__index = Skeleton

function Skeleton:UpdateStructure()
	if not self.Player.Character then return end

	self:RemoveLines()

	for _, part in next, self.Player.Character:GetChildren() do		
		if not part:IsA("BasePart") then continue end

		for _, link in next, part:GetChildren() do			
			if not link:IsA("Motor6D") then continue end
			
			table.insert(self.Lines, {
				SkeletonLibrary:NewLine({Visible = self.Visible, Color = self.Color, Transparency = self.Alpha, Thickness = self.Thickness}),
				SkeletonLibrary:NewLine({Visible = self.Visible, Color = self.Color, Transparency = self.Alpha, Thickness = self.Thickness}),
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

			local part0p, v1 = CurrentCamera:WorldToViewportPoint(part0.CFrame.p)
			local part0cp, v2 = CurrentCamera:WorldToViewportPoint((part0.CFrame * c0).p)
			
			if v1 and v2 then
				l[1].From = Vector2.new(part0p.x, part0p.y)
				l[1].To = Vector2.new(part0cp.x, part0cp.y)
				l[1].Visible = true
			else 
				l[1].Visible = false
			end
			
			local part1p, v3 = CurrentCamera:WorldToViewportPoint(part1.CFrame.p)
			local part1cp, v4 = CurrentCamera:WorldToViewportPoint((part1.CFrame * c1).p)
		
			if v3 and v4 then
				l[2].From = Vector2.new(part1p.x, part1p.y)
				l[2].To = Vector2.new(part1cp.x, part1cp.y)
				l[2].Visible = true
			else 
				l[2].Visible = false
			end
		else					
			local part0p, v1 = CurrentCamera:WorldToViewportPoint(part0.CFrame.p)
			local part1p, v2 = CurrentCamera:WorldToViewportPoint(part1.CFrame.p)
			
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
		local c
		c = RunService.Heartbeat:Connect(function()
			if not self.Visible then
				self:SetVisible(false)
				c:Disconnect()
				return
			end
			self:Update()
		end)
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
	if DoSubsteps ~= nil then
		s.DoSubsteps = DoSubsteps
	end
	if Color then s:SetColor(Color) end
	if Alpha then s:SetAlpha(Alpha) end
	if Thickness then s:SetThickness(Thickness) end
	if Visible then s:Toggle() end
	return s
end

local function startSkeletonESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local sk = SkeletonLibrary:NewSkeleton(player, true, getgenv().skeletonESPColor, 1, 1, true)
			table.insert(skeletons, sk)
		end
	end
	skeletonAddedConnection = Players.PlayerAdded:Connect(function(player)
		if player ~= LocalPlayer then
			local sk = SkeletonLibrary:NewSkeleton(player, true, getgenv().skeletonESPColor, 1, 1, true)
			table.insert(skeletons, sk)
		end
	end)
end

local function stopSkeletonESP()
	if skeletonAddedConnection then skeletonAddedConnection:Disconnect() end
	for _, sk in ipairs(skeletons) do
		sk:Remove()
	end
	skeletons = {}
end

---------------------------
-- CHAMS (Highlight) ESP --
---------------------------
local function startChams()
	chamsFolder = Instance.new("Folder")
	chamsFolder.Parent = game:GetService("CoreGui")
	chamsFolder.Name = "Highlight_Storage"
	
	local function highlightPlayer(plr)
		if plr == LocalPlayer then return end
		local highlight = Instance.new("Highlight")
		highlight.Name = plr.Name
		highlight.FillColor = getgenv().chamsColor or Color3.new(1,1,1)
		highlight.DepthMode = "AlwaysOnTop"
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = getgenv().chamsColor or Color3.new(1,1,1)
		highlight.OutlineTransparency = 0
		highlight.Parent = chamsFolder
		
		if plr.Character then
			highlight.Adornee = plr.Character
		end
		
		local conn = plr.CharacterAdded:Connect(function(char)
			highlight.Adornee = char
		end)
		chamConnections[plr] = {conn = conn, highlight = highlight}
	end
	
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			highlightPlayer(plr)
		end
	end
	
	Players.PlayerAdded:Connect(function(plr)
		if plr ~= LocalPlayer then
			highlightPlayer(plr)
		end
	end)
	
	Players.PlayerRemoving:Connect(function(plr)
		if chamConnections[plr] then
			chamConnections[plr].highlight:Destroy()
			chamConnections[plr].conn:Disconnect()
			chamConnections[plr] = nil
		end
	end)
end

local function stopChams()
	if chamsFolder then
		chamsFolder:Destroy()
		chamsFolder = nil
	end
	for _, data in pairs(chamConnections) do
		data.conn:Disconnect()
		if data.highlight then data.highlight:Destroy() end
	end
	chamConnections = {}
end

----------------------------
-- ARM CHAMS Functions --
----------------------------
local function applyArmChams(character, chamsColor, transparency, reflectance)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local targetParts = {
		"LeftArm", "RightArm",
		"LeftHand", "RightHand",
		"LeftUpperArm", "LeftLowerArm",
		"RightUpperArm", "RightLowerArm"
	}
	for _, partName in pairs(targetParts) do
		local part = character:FindFirstChild(partName)
		if part and not part:GetAttribute("ArmChamsModified") then
			part.Material = Enum.Material.ForceField
			part.Color = chamsColor
			part.Transparency = transparency
			part.Reflectance = reflectance
			part:SetAttribute("ArmChamsModified", true)
			part:GetPropertyChangedSignal("Material"):Connect(function()
				if part.Material ~= Enum.Material.ForceField then
					part.Material = Enum.Material.ForceField
				end
			end)
		end
	end
end

local function startArmChams(chamsColor)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			if plr.Character then
				applyArmChams(plr.Character, chamsColor, 0.3, 0.15)
			end
			armChamsConnections[plr] = plr.CharacterAdded:Connect(function(character)
				applyArmChams(character, chamsColor, 0.3, 0.15)
			end)
		end
	end
	armChamsPlayerAddedConnection = Players.PlayerAdded:Connect(function(plr)
		if plr ~= LocalPlayer then
			armChamsConnections[plr] = plr.CharacterAdded:Connect(function(character)
				applyArmChams(character, chamsColor, 0.3, 0.15)
			end)
		end
	end)
end

local function stopArmChams()
	if armChamsPlayerAddedConnection then armChamsPlayerAddedConnection:Disconnect() end
	for plr, conn in pairs(armChamsConnections) do
		conn:Disconnect()
	end
	armChamsConnections = {}
	-- Note: Resetting materials is not handled here.
end

-------------------------------
-- New ESP Toggles (Visuals) --
-------------------------------
-- ITEM ESP Toggle
visualsLeft:Toggle({
	Name = "Item ESP",
	Default = false,
	Callback = function(Value)
		getgenv().itemESPEnabled = Value
		if Value then
			itemESPConnection = RunService.RenderStepped:Connect(updateItemESP)
			Window:Notify({ Title = "Item ESP", Description = "Enabled", Lifetime = 5 })
		else
			if itemESPConnection then
				itemESPConnection:Disconnect()
				itemESPConnection = nil
			end
			-- Cleanup drawings
			updateItemESP()
			Window:Notify({ Title = "Item ESP", Description = "Disabled", Lifetime = 5 })
		end
	end,
}, "ItemESPToggle")

-- Skeleton ESP Toggle
visualsLeft:Toggle({
	Name = "Skeleton ESP",
	Default = false,
	Callback = function(Value)
		getgenv().skeletonESPEnabled = Value
		if Value then
			startSkeletonESP()
			Window:Notify({ Title = "Skeleton ESP", Description = "Enabled", Lifetime = 5 })
		else
			stopSkeletonESP()
			Window:Notify({ Title = "Skeleton ESP", Description = "Disabled", Lifetime = 5 })
		end
	end,
}, "SkeletonESPToggle")

-- Chams Toggle
visualsLeft:Toggle({
	Name = "Chams",
	Default = false,
	Callback = function(Value)
		getgenv().chamsEnabled = Value
		if Value then
			startChams()
			Window:Notify({ Title = "Chams", Description = "Enabled", Lifetime = 5 })
		else
			stopChams()
			Window:Notify({ Title = "Chams", Description = "Disabled", Lifetime = 5 })
		end
	end,
}, "ChamsToggle")

-- Arm Chams Toggle
visualsLeft:Toggle({
	Name = "Arm Chams",
	Default = false,
	Callback = function(Value)
		getgenv().armChamsEnabled = Value
		if Value then
			startArmChams(getgenv().armChamsColor)
			Window:Notify({ Title = "Arm Chams", Description = "Enabled", Lifetime = 5 })
		else
			stopArmChams()
			Window:Notify({ Title = "Arm Chams", Description = "Disabled", Lifetime = 5 })
		end
	end,
}, "ArmChamsToggle")

-----------------------------------------
-- New ESP Colorpickers (Visuals Right)--
-----------------------------------------
-- Skeleton ESP Color
visualsRight:Colorpicker({
	Name = "Skeleton ESP Color",
	Default = getgenv().skeletonESPColor,
	Alpha = 0,
	Callback = function(color, alpha)
		getgenv().skeletonESPColor = color
		for _, sk in ipairs(skeletons) do
			sk:SetColor(color)
		end
	end,
}, "SkeletonESPColorPicker")

-- Chams Color
visualsRight:Colorpicker({
	Name = "Chams Color",
	Default = getgenv().chamsColor,
	Alpha = 0,
	Callback = function(color, alpha)
		getgenv().chamsColor = color
		-- Update all active highlights
		if chamsFolder then
			for _, highlight in ipairs(chamsFolder:GetChildren()) do
				highlight.FillColor = color
				highlight.OutlineColor = color
			end
		end
	end,
}, "ChamsColorPicker")

-- Arm Chams Color
visualsRight:Colorpicker({
	Name = "Arm Chams Color",
	Default = getgenv().armChamsColor,
	Alpha = 0,
	Callback = function(color, alpha)
		getgenv().armChamsColor = color
		-- Note: New characters will use the updated color; existing ones are not updated automatically.
	end,
}, "ArmChamsColorPicker")

---------------------
-- Finalize GUI  --
---------------------
tabs.AimAssist:Select()

Window:Notify({
	Title = "Collapse:Vampire Hunters 3",
	Description = "Script loaded successfully! - Made by Finny <3",
	Lifetime = 5
})
