-- Sniper Control GUI Script - Compact Design
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Create main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SniperControl"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Create toggle button (eye icon)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 40, 0, 40)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 0, 90)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "👁"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 18
ToggleButton.Visible = true
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(180, 80, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Transparency = 0.3
ToggleStroke.Parent = ToggleButton

-- Main frame with gradient and transparency
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Corner radius
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Gradient effect
local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 0, 60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 0, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 0, 45))
})
UIGradient.Rotation = 45
UIGradient.Parent = MainFrame

-- Border stroke
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(100, 0, 150)
MainStroke.Thickness = 2
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitleBar.BackgroundTransparency = 0.3
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = MainFrame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 12)
TitleBarCorner.Parent = TitleBar

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "USERNAME SNIPER"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = TitleBar

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -25, 0, 4)
CloseButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
CloseButton.BackgroundTransparency = 0.2
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "×"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.ZIndex = 3
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Content frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -36)
ContentFrame.Position = UDim2.new(0, 10, 0, 36)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Username input container
local InputContainer = Instance.new("Frame")
InputContainer.Size = UDim2.new(1, 0, 0, 50)
InputContainer.Position = UDim2.new(0, 0, 0, 0)
InputContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
InputContainer.BackgroundTransparency = 0.3
InputContainer.BorderSizePixel = 0
InputContainer.Parent = ContentFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputContainer

-- Input container stroke
local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(80, 0, 120)
InputStroke.Thickness = 1
InputStroke.Transparency = 0.5
InputStroke.Parent = InputContainer

-- Input label
local InputLabel = Instance.new("TextLabel")
InputLabel.Size = UDim2.new(1, -10, 0, 16)
InputLabel.Position = UDim2.new(0, 5, 0, 5)
InputLabel.BackgroundTransparency = 1
InputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InputLabel.Text = "Username (case-insensitive):"
InputLabel.Font = Enum.Font.Gotham
InputLabel.TextSize = 10
InputLabel.TextXAlignment = Enum.TextXAlignment.Left
InputLabel.Parent = InputContainer

-- Username text box (smaller single-line)
local UsernameTextBox = Instance.new("TextBox")
UsernameTextBox.Size = UDim2.new(1, -10, 0, 22)
UsernameTextBox.Position = UDim2.new(0, 5, 0, 24)
UsernameTextBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
UsernameTextBox.BackgroundTransparency = 0.2
UsernameTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
UsernameTextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
UsernameTextBox.PlaceholderText = "Enter username..."
UsernameTextBox.Text = ""
UsernameTextBox.Font = Enum.Font.Gotham
UsernameTextBox.TextSize = 12
UsernameTextBox.MultiLine = false
UsernameTextBox.ClearTextOnFocus = false
UsernameTextBox.Parent = InputContainer

local TextBoxCorner = Instance.new("UICorner")
TextBoxCorner.CornerRadius = UDim.new(0, 6)
TextBoxCorner.Parent = UsernameTextBox

-- Text box stroke
local TextBoxStroke = Instance.new("UIStroke")
TextBoxStroke.Color = Color3.fromRGB(60, 0, 90)
TextBoxStroke.Thickness = 1
TextBoxStroke.Transparency = 0.3
TextBoxStroke.Parent = UsernameTextBox

-- Status indicator
local StatusContainer = Instance.new("Frame")
StatusContainer.Size = UDim2.new(1, 0, 0, 20)
StatusContainer.Position = UDim2.new(0, 0, 0, 60)
StatusContainer.BackgroundTransparency = 1
StatusContainer.Parent = ContentFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.5, 0, 1, 0)
StatusLabel.Position = UDim2.new(0, 0, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Text = "Status:"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusContainer

local StatusValue = Instance.new("TextLabel")
StatusValue.Size = UDim2.new(0.5, 0, 1, 0)
StatusValue.Position = UDim2.new(0.5, 0, 0, 0)
StatusValue.BackgroundTransparency = 1
StatusValue.TextColor3 = Color3.fromRGB(255, 80, 80)
StatusValue.Text = "INACTIVE"
StatusValue.Font = Enum.Font.GothamBold
StatusValue.TextSize = 11
StatusValue.TextXAlignment = Enum.TextXAlignment.Right
StatusValue.Parent = StatusContainer

-- Main button container
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, 0, 0, 32)
ButtonContainer.Position = UDim2.new(0, 0, 0, 90)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = ContentFrame

-- Action button
local ActionButton = Instance.new("TextButton")
ActionButton.Size = UDim2.new(1, 0, 1, 0)
ActionButton.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
ActionButton.BackgroundTransparency = 0.1
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.Text = "DICE EM"
ActionButton.Font = Enum.Font.GothamBold
ActionButton.TextSize = 12
ActionButton.Parent = ButtonContainer

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = ActionButton

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Color = Color3.fromRGB(180, 80, 255)
ButtonStroke.Thickness = 1
ButtonStroke.Transparency = 0.5
ButtonStroke.Parent = ActionButton

-- File paths
local sniperFolder = "sniper"
local configFile = sniperFolder .. "/config.json"

-- Animation variables
local hoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local buttonHoverTween = nil
local pulseConnection = nil

-- Function to ensure folder exists
local function ensureFolder()
    if not isfolder(sniperFolder) then
        makefolder(sniperFolder)
    end
end

-- Function to load configuration
local function loadConfig()
    ensureFolder()
    
    if isfile(configFile) then
        local success, result = pcall(function()
            return readfile(configFile)
        end)
        
        if success and result then
            local config = HttpService:JSONDecode(result)
            return config
        end
    end
    
    -- Default configuration
    return {
        SniperCheck = false,
        Usernames = {}
    }
end

-- Function to save configuration
local function saveConfig(config)
    ensureFolder()
    
    local success, result = pcall(function()
        writefile(configFile, HttpService:JSONEncode(config))
        return true
    end)
    
    return success
end

-- Function to update UI state
local function updateUI()
    local config = loadConfig()
    
    if config.SniperCheck then
        ActionButton.Text = "STOP"
        ActionButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StatusValue.Text = "ACTIVE"
        StatusValue.TextColor3 = Color3.fromRGB(80, 255, 80)
        
        -- Start pulse animation
        if pulseConnection then
            pulseConnection:Disconnect()
        end
        
        pulseConnection = RunService.Heartbeat:Connect(function()
            local alpha = (math.sin(tick() * 5) + 1) / 2
            ActionButton.BackgroundTransparency = 0.1 + (alpha * 0.1)
        end)
    else
        ActionButton.Text = "DICE EM"
        ActionButton.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
        StatusValue.Text = "INACTIVE"
        StatusValue.TextColor3 = Color3.fromRGB(255, 80, 80)
        
        -- Stop pulse animation
        if pulseConnection then
            pulseConnection:Disconnect()
            pulseConnection = nil
        end
        ActionButton.BackgroundTransparency = 0.1
    end
end

-- Function to process username (make it case insensitive)
local function processUsername(text)
    local processed = text:gsub("%s+", ""):lower()
    return processed ~= "" and processed or nil
end

-- Function to start sniper
local function startSniper()
    print("[SNIPER] Sniper setup Finished")
    
    local config = loadConfig()
    
    if config.SniperCheck then
        print("[SNIPER] Sniper is Running")
        print("[SNIPER] Checking username: " .. (config.Usernames[1] or "None"))
        
        -- Your actual sniper logic would go here
        spawn(function()
            while config.SniperCheck do
                local currentConfig = loadConfig()
                if not currentConfig.SniperCheck then
                    break
                end
                
                -- Sniper checking logic here
                wait(1)
            end
        end)
    end
end

-- Function to stop sniper
local function stopSniper()
    print("[SNIPER] Sniper stopped")
end

-- Button hover effects
ActionButton.MouseEnter:Connect(function()
    if buttonHoverTween then
        buttonHoverTween:Cancel()
    end
    buttonHoverTween = TweenService:Create(ActionButton, hoverTweenInfo, {
        BackgroundTransparency = 0.05
    })
    buttonHoverTween:Play()
end)

ActionButton.MouseLeave:Connect(function()
    if buttonHoverTween then
        buttonHoverTween:Cancel()
    end
    buttonHoverTween = TweenService:Create(ActionButton, hoverTweenInfo, {
        BackgroundTransparency = 0.1
    })
    buttonHoverTween:Play()
end)

-- Toggle button hover effects
ToggleButton.MouseEnter:Connect(function()
    ToggleButton.BackgroundTransparency = 0.1
end)

ToggleButton.MouseLeave:Connect(function()
    ToggleButton.BackgroundTransparency = 0.2
end)

-- Close button hover effects
CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
end)

-- Action button click event
ActionButton.MouseButton1Click:Connect(function()
    local config = loadConfig()
    
    -- Process and save username
    local username = processUsername(UsernameTextBox.Text)
    config.Usernames = username and {username} or {}
    
    -- Toggle sniper state
    config.SniperCheck = not config.SniperCheck
    
    if saveConfig(config) then
        updateUI()
        
        if config.SniperCheck then
            startSniper()
        else
            stopSniper()
        end
        
        print("[SNIPER] Configuration saved: " .. (config.SniperCheck and "ACTIVE" or "INACTIVE"))
        print("[SNIPER] Username: " .. (username or "None"))
    else
        warn("[SNIPER] Failed to save configuration!")
    end
end)

-- Toggle button click event (show/hide GUI)
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Close button click event
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Make toggle button draggable
ToggleButton.Active = true
ToggleButton.Draggable = true

-- Load existing configuration and update UI
local config = loadConfig()
if config.Usernames and #config.Usernames > 0 then
    UsernameTextBox.Text = config.Usernames[1]
end

updateUI()

-- If sniper was already running when script starts, start it
if config.SniperCheck then
    startSniper()
end

print("[SNIPER] GUI loaded successfully!")
print("[SNIPER] Config folder Created: " .. sniperFolder)
print("[SNIPER] Config file Created: " .. configFile)
print("[SNIPER] Click the eye icon to open/close the GUI")
