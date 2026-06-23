local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local ItemPools = workspace:WaitForChild("Item_Pools")
local GiftsFolder = ItemPools:WaitForChild("Gift")
local GoldenFolder = ItemPools:WaitForChild("GoldenGift")
local EnemiesFolder = workspace:WaitForChild("Enemies")
local Beacon = workspace:WaitForChild("Beacon")
local AltarsFolder = workspace:FindFirstChild("Altars") 

local SPEED = 100
local HOVER_OFFSET = 2
local MAX_DISTANCE = 20000
local PREVIEW_COUNT = 10 

local isFarmOn = false 
local isAltarOn = false
local isIntermissionPause = false

-- === HELPER: NOTIFICATIONS ===
local function notif(text, title, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "System",
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- === 1. GUI CREATION ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmGUI"
ScreenGui.ResetOnSpawn = false
local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = Player:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Position = UDim2.new(0.5, -110, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Auto Farm" 
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local ToggleContainer = Instance.new("ScrollingFrame")
ToggleContainer.Size = UDim2.new(1, 0, 1, -40)
ToggleContainer.Position = UDim2.new(0, 0, 0, 40)
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.ScrollBarThickness = 4
ToggleContainer.BorderSizePixel = 0
ToggleContainer.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ToggleContainer
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 8)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- === 2. WORLD SETUP & BLOCKERS ===
local pathFolder = Instance.new("Folder", workspace)
pathFolder.Name = "PathVisualizer"

local BlockersFolder = Instance.new("Folder", workspace)
BlockersFolder.Name = "AutoFarmBlockers"

local PhysicalBlocker = Instance.new("Part")
PhysicalBlocker.Name = "BeaconPathfindingBlocker"
PhysicalBlocker.Size = Beacon.Size + Vector3.new(2, 2, 2)
PhysicalBlocker.Anchored = true
PhysicalBlocker.CanCollide = true 
PhysicalBlocker.Transparency = 0.5 
PhysicalBlocker.BrickColor = BrickColor.new("Bright red")
PhysicalBlocker.Material = Enum.Material.Neon
PhysicalBlocker.Parent = BlockersFolder

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {BlockersFolder}

local function updateBlockerVisibility()
    if isFarmOn or isAltarOn then
        BlockersFolder.Parent = workspace
    else
        BlockersFolder.Parent = nil
        pathFolder:ClearAllChildren()
    end
end

local function createToggle(name, layoutOrder, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 190, 0, 35)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.LayoutOrder = layoutOrder
    toggleFrame.Parent = ToggleContainer

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 14
    btn.Parent = toggleFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(60, 220, 100)
            btn.Text = name .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            btn.Text = name .. ": OFF"
        end
        callback(state)
        updateBlockerVisibility()
    end)
end

createToggle("Farm presents", 1, function(state) isFarmOn = state end)
createToggle("Auto Alters", 2, function(state) isAltarOn = state end)

-- === 3. DRAGGABLE GUI ===
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === 4. OPTIMIZED ENGINE ===
local cachedCharParts = {}
Player.CharacterAdded:Connect(function(char)
    cachedCharParts = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(cachedCharParts, part) end
    end
    char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then table.insert(cachedCharParts, part) end
    end)
end)

if Player.Character then
    for _, part in ipairs(Player.Character:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(cachedCharParts, part) end
    end
end

RunService.Stepped:Connect(function()
    if (isFarmOn or isAltarOn) then
        for _, part in ipairs(cachedCharParts) do
            if part.CanCollide then part.CanCollide = false end
        end
    end
end)

local function clearExistingEnemies()
    for _, enemy in ipairs(EnemiesFolder:GetChildren()) do enemy:Destroy() end
end
EnemiesFolder.ChildAdded:Connect(function(child)
    if isFarmOn or isAltarOn then task.defer(function() child:Destroy() end) end
end)

task.spawn(function()
    while true do
        isIntermissionPause = workspace:FindFirstChild("Lobby") ~= nil
        task.wait(0.5)
    end
end)

local function getRoot()
    local char = Player.Character or Player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function getRootOffset(root)
    local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
    return (humanoid and humanoid.HipHeight or 2) + (root.Size.Y / 2) + HOVER_OFFSET
end

-- ==========================================
-- LOGIC & MATH 
-- ==========================================
local function getAltarPrompts()
    local prompts = {}
    local currentRooms = workspace:FindFirstChild("CurrentRooms") or AltarsFolder or workspace
    for _, p in ipairs(currentRooms:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Enabled then
            table.insert(prompts, p)
        end
    end
    return prompts
end

local function isValidGift(gift)
    return gift and gift.Parent and gift:IsA("BasePart") and gift.Transparency ~= 1 and gift:FindFirstChild("Collect", true)
end

local function getNearestGifts(origin, count)
    local found = {}
    for _, folder in ipairs({ GiftsFolder, GoldenFolder }) do
        for _, gift in ipairs(folder:GetChildren()) do
            if isValidGift(gift) then
                local dist = (origin - gift.Position).Magnitude
                if dist <= MAX_DISTANCE then table.insert(found, { gift = gift, dist = dist }) end
            end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)

    local result = {}
    for i = 1, math.min(count, #found) do table.insert(result, found[i].gift) end
    return result
end

local function isLineOfSightClear(startPos, endPos)
    local direction = endPos - startPos
    local result = workspace:Raycast(startPos, direction, rayParams)
    return result == nil
end

local function getActiveTripmines()
    local active = {}
    local tripmineFolder = ItemPools:FindFirstChild("Tripmine")
    if tripmineFolder then
        for _, mine in ipairs(tripmineFolder:GetChildren()) do
            local part = mine:IsA("BasePart") and mine or mine:FindFirstChildOfClass("BasePart")
            if part and part.Transparency ~= 1 then
                table.insert(active, mine)
            end
        end
    end
    return active
end

local function pathBlocked(pos, activeTripmines, activeEnemies)
    local root = getRoot()
    local startPos = root.Position
    
    local minX = math.min(startPos.X, pos.X) - 1
    local maxX = math.max(startPos.X, pos.X) + 1
    local minY = math.min(startPos.Y, pos.Y) - 2.5
    local maxY = math.max(startPos.Y, pos.Y) + 2.5
    local minZ = math.min(startPos.Z, pos.Z) - 1
    local maxZ = math.max(startPos.Z, pos.Z) + 1

    local function checkOverlap(obj)
        local mPos, mSize
        if obj:IsA("BasePart") then
            mPos = obj.Position
            mSize = obj.Size
        elseif obj:IsA("Model") then
            mPos = obj:GetPivot().Position
            local _, s = obj:GetBoundingBox()
            mSize = s
        end

        if mPos and mSize then
            local minMx = mPos.X - (mSize.X / 2)
            local maxMx = mPos.X + (mSize.X / 2)
            local minMy = mPos.Y - (mSize.Y / 2)
            local maxMy = mPos.Y + (mSize.Y / 2)
            local minMz = mPos.Z - (mSize.Z / 2)
            local maxMz = mPos.Z + (mSize.Z / 2)

            local overlapX = maxX >= minMx and minX <= maxMx
            local overlapY = maxY >= minMy and minY <= maxMy
            local overlapZ = maxZ >= minMz and minZ <= maxMz

            return overlapX and overlapY and overlapZ
        end
        return false
    end

    for _, mine in ipairs(activeTripmines) do
        if checkOverlap(mine) then return true end
    end
    for _, enemy in ipairs(activeEnemies) do
        if checkOverlap(enemy) then return true end
    end

    return false
end

local function computePath(startPos, finishPos)
    local path = PathfindingService:CreatePath({ AgentRadius = 3, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
    local ok = pcall(function() path:ComputeAsync(startPos, finishPos) end)

    if ok and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        waypoints[#waypoints] = PathWaypoint.new(finishPos, waypoints[#waypoints].Action)
        return waypoints
    end
    return nil 
end

-- UPDATED: Accommodates both Gifts and Altar Prompts smoothly
local function tweenToWaypoint(root, targetPos, yOffset, action, targetObj)
    local pos = targetPos + Vector3.new(0, yOffset, 0)

    if action == Enum.PathWaypointAction.Jump then
        local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Jump = true end
    end

    local activeTripmines = getActiveTripmines()
    local activeEnemies = EnemiesFolder:GetChildren()

    -- Pre-tween interception logic (strictly for gifts)
    local blocked = pathBlocked(pos, activeTripmines, activeEnemies)
    if blocked and targetObj and (targetObj.Name == "Gift" or targetObj.Name == "GoldenGift") then
        root.Position = pos
        task.wait(0.3)
        return true
    end

    local dist = (pos - root.Position).Magnitude
    if dist < 0.5 then return true end

    local info = TweenInfo.new(dist / SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(root, info, {Position = pos})
    
    local isBlockedMidway = false
    local monitorThread = task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if pathBlocked(pos, getActiveTripmines(), EnemiesFolder:GetChildren()) then
                tween:Cancel()
                isBlockedMidway = true
                break
            end
            task.wait(0.05)
        end
    end)

    tween:Play()
    tween.Completed:Wait()

    if isBlockedMidway then
        root.Position = pos
        task.wait(0.3)
        return true
    end

    if targetObj then
        if (targetObj.Name == "Gift" or targetObj.Name == "GoldenGift") and not isValidGift(targetObj) then return true end
        if targetObj:IsA("ProximityPrompt") and not targetObj.Enabled then return true end
    end
    
    if (not isFarmOn and not isAltarOn) or isIntermissionPause then return false end 

    return true
end

local function followPath(root, waypoints, targetObj)
    local yOffset = getRootOffset(root)

    for i = 2, #waypoints do
        if targetObj then
            if (targetObj.Name == "Gift" or targetObj.Name == "GoldenGift") and not isValidGift(targetObj) then return true end
            if targetObj:IsA("ProximityPrompt") and not targetObj.Enabled then return true end
        end
        
        if not tweenToWaypoint(root, waypoints[i].Position, yOffset, waypoints[i].Action, targetObj) then
            return false
        end
    end
    return true
end

local function teleportToBeacon(root)
    local pos = Beacon.Position + Vector3.new(0, 4, 0)
    root.CFrame = CFrame.new(pos)
end

-- === 5. MAIN LOOP ===
task.spawn(function()
    updateBlockerVisibility()
    
    while true do
        if (not isFarmOn and not isAltarOn) or isIntermissionPause then
            task.wait(0.2)
            continue
        end

        local root = getRoot()
        PhysicalBlocker.CFrame = Beacon.CFrame
        clearExistingEnemies() 

        -- FIXED: Altar Tweening Activation & Non-Teleport Return Setup
        if isAltarOn then
            local prompts = getAltarPrompts()
            if #prompts > 0 then
                local selectedPrompt = prompts[1]
                local pPart = selectedPrompt.Parent
                if pPart and pPart:IsA("BasePart") then
                    local targetPos = pPart.Position + pPart.CFrame.LookVector * -3
                    
                    local waypoints = nil
                    if isLineOfSightClear(root.Position, targetPos) then
                        waypoints = {
                            PathWaypoint.new(root.Position, Enum.PathWaypointAction.Walk),
                            PathWaypoint.new(targetPos, Enum.PathWaypointAction.Walk)
                        }
                    else
                        waypoints = computePath(root.Position, targetPos)
                    end

                    if not waypoints then
                        waypoints = {
                            PathWaypoint.new(root.Position, Enum.PathWaypointAction.Walk),
                            PathWaypoint.new(targetPos, Enum.PathWaypointAction.Walk)
                        }
                    end

                    -- Tweens seamlessly directly onto the Altar point
                    local success = followPath(root, waypoints, selectedPrompt)
                    if success and isAltarOn and selectedPrompt.Enabled then
                        if fireproximityprompt then
                            fireproximityprompt(selectedPrompt)
                            task.wait(selectedPrompt.HoldDuration)
                        end
                    end
                end
                -- Left without CFrame reversions so it falls immediately into present routines nearby
                continue 
            end
        end

        if isFarmOn then
            local gifts = getNearestGifts(root.Position, PREVIEW_COUNT)

            if #gifts == 0 then
                task.wait(1) 
                gifts = getNearestGifts(root.Position, PREVIEW_COUNT)
                
                if #gifts == 0 then
                    pathFolder:ClearAllChildren()
                    teleportToBeacon(root)
                    task.wait(1.5) 
                end
                continue
            end

            local gift = gifts[1]
            local waypoints = nil

            if root.AssemblyLinearVelocity.Y < -40 then
                waypoints = { PathWaypoint.new(root.Position, Enum.PathWaypointAction.Walk), PathWaypoint.new(gift.Position, Enum.PathWaypointAction.Walk) }
            else
                for _, possibleGift in ipairs(gifts) do
                    if isLineOfSightClear(root.Position, possibleGift.Position) then
                        waypoints = {
                            PathWaypoint.new(root.Position, Enum.PathWaypointAction.Walk),
                            PathWaypoint.new(possibleGift.Position, Enum.PathWaypointAction.Walk)
                        }
                        gift = possibleGift
                        break
                    else
                        waypoints = computePath(root.Position, possibleGift.Position)
                        if waypoints then
                            gift = possibleGift
                            break
                        end
                    end
                end
                
                if not waypoints and #gifts > 0 then
                    gift = gifts[1]
                    waypoints = {
                        PathWaypoint.new(root.Position, Enum.PathWaypointAction.Walk),
                        PathWaypoint.new(gift.Position, Enum.PathWaypointAction.Walk)
                    }
                end
            end

            if waypoints then
                followPath(root, waypoints, gift)
            else
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)
