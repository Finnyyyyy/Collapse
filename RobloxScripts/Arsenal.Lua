--[[
    AdvanceTech Arsenal | v1.7 (Fluent-Renewed GUI Version – Revised)
    Modified by AdvancedFalling Team

    Changes:
      • Theme set to "VSC Dark High Contrast"
      • Removed Infinite Ammo v1; only the Infinite Ammo toggle remains.
      • Hitbox expansion:
            - The team-check toggle is off by default (so hitboxes expand for everyone).
            - The extended hitboxes are set to be non-collidable (to avoid interfering with movement).
              (If you prefer collision enabled, change 'part.CanCollide = false' to true.)
      • Default jump height is set to 50.
      • A new Third Person toggle has been added in the Player tab.
--]]

-------------------------------
-- Load Fluent and Add‑Ons
-------------------------------
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-------------------------------
-- Create Window using Fluent
-------------------------------
local Window = Library:CreateWindow{
    Title = "Collapse | Arsenal | v1.1",
    SubTitle = "Made by Finny <3",
    TabWidth = 160,
    Size = UDim2.fromOffset(830,525),
    Resize = true,
    MinSize = Vector2.new(470,380),
    Acrylic = true,
    Theme = "VSC Dark High Contrast", -- Theme changed here
    MinimizeKey = Enum.KeyCode.RightControl
}

local Tabs = {
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "phosphor-users-bold"
    },
    ["Gun Mods"] = Window:CreateTab{
        Title = "Gun Mods",
        Icon = "phosphor-gun-bold"
    },
    Player = Window:CreateTab{
        Title = "Player",
        Icon = "phosphor-rocket-bold"
    },
    ["Color Skins"] = Window:CreateTab{
        Title = "Color Skins",
        Icon = "phosphor-paintbrush-bold"
    },
    Extra = Window:CreateTab{
        Title = "Extra",
        Icon = "phosphor-star-bold"
    },
    Visuals = Window:CreateTab{
        Title = "Visuals",
        Icon = "phosphor-eye-bold"
    },
    Settings = Window:CreateTab{
        Title = "Settings",
        Icon = "settings"
    },
    Credits = Window:CreateTab{
        Title = "Credits",
        Icon = "phosphor-info-bold"
    }
}

--------------------------------
-- COMMON FUNCTIONS & VARIABLES
--------------------------------



local Players = game:GetService("Players")
local player = Players.LocalPlayer

--------------------------------
-- FLY FUNCTIONS
--------------------------------
local flySettings = { fly = false, flyspeed = 50 }
local c, h, bv, bav, cam, flying
local buttons = { W = false, S = false, A = false, D = false, Moving = false }

local function startFly()
    if not player.Character or not player.Character:FindFirstChild("Head") or flying then return end
    c = player.Character
    h = c:FindFirstChildOfClass("Humanoid")
    h.PlatformStand = true
    cam = workspace:WaitForChild("Camera")
    bv = Instance.new("BodyVelocity", c.Head)
    bav = Instance.new("BodyAngularVelocity", c.Head)
    bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(10000,10000,10000)
    bv.P = 1000
    bav.AngularVelocity = Vector3.new(0,0,0)
    bav.MaxTorque = Vector3.new(10000,10000,10000)
    bav.P = 1000
    flying = true
    h.Died:Connect(function() flying = false end)
end

local function endFly()
    if not player.Character or not flying then return end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if bv then bv:Destroy() end
    if bav then bav:Destroy() end
    flying = false
end

local function setVec(vec)
    return vec * (flySettings.flyspeed / vec.Magnitude)
end

game:GetService("RunService").Heartbeat:Connect(function(step)
    if flying and c and c.PrimaryPart then
        local pos = c.PrimaryPart.Position
        local cf = cam.CFrame
        local ax, ay, az = cf:ToEulerAnglesXYZ()
        c:SetPrimaryPartCFrame(CFrame.new(pos.x, pos.y, pos.z) * CFrame.Angles(ax,ay,az))
        if buttons.Moving then
            local t = Vector3.new()
            if buttons.W then t = t + setVec(cf.LookVector) end
            if buttons.S then t = t - setVec(cf.LookVector) end
            if buttons.A then t = t - setVec(cf.RightVector) end
            if buttons.D then t = t + setVec(cf.RightVector) end
            c:TranslateBy(t * step)
        end
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input, GPE)
    if GPE then return end
    for key, _ in pairs(buttons) do
        if key ~= "Moving" and input.KeyCode == Enum.KeyCode[key] then
            buttons[key] = true
            buttons.Moving = true
        end
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input, GPE)
    if GPE then return end
    local moving = false
    for key, _ in pairs(buttons) do
        if key ~= "Moving" and input.KeyCode == Enum.KeyCode[key] then
            buttons[key] = false
        end
        if key ~= "Moving" and buttons[key] then moving = true end
    end
    buttons.Moving = moving
end)

--------------------------------
-- HITBOX FUNCTIONS
--------------------------------
local hitboxEnabled = false
-- Collision is always enabled; no toggle.
local hitbox_original_properties = {}
local hitboxSize = 21
local hitboxTransparency = 6
local defaultBodyParts = {"UpperTorso", "Head", "HumanoidRootPart"}

-- New flag for team-check; default is false (hitboxes expand for everyone)
local hitboxTeamCheckEnabled = false

local function savedPart(plr, part)
    if not hitbox_original_properties[plr] then
        hitbox_original_properties[plr] = {}
    end
    if not hitbox_original_properties[plr][part.Name] then
        hitbox_original_properties[plr][part.Name] = {
            CanCollide = part.CanCollide,
            Transparency = part.Transparency,
            Size = part.Size
        }
    end
end

local function restoredPart(plr)
    if hitbox_original_properties[plr] then
        for partName, props in pairs(hitbox_original_properties[plr]) do
            local part = plr.Character and plr.Character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.CanCollide = props.CanCollide
                part.Transparency = props.Transparency
                part.Size = props.Size
            end
        end
    end
end

local function findClosestPart(plr, partName)
    if not plr.Character then return nil end
    for _, part in ipairs(plr.Character:GetChildren()) do
        if part:IsA("BasePart") and part.Name:lower():find(partName:lower()) then
            return part
        end
    end
    return nil
end

local function extendHitbox(plr)
    for _, partName in ipairs(defaultBodyParts) do
        local part = plr.Character and (plr.Character:FindFirstChild(partName) or findClosestPart(plr, partName))
        if part and part:IsA("BasePart") then
            savedPart(plr, part)
            -- Set hitbox collision off to prevent interference:
            part.CanCollide = false  -- Change to true if you want collision enabled
            part.Transparency = hitboxTransparency / 10
            part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        end
    end
end

-- When team-check is enabled, only expand hitboxes for enemies.
local function isEnemy(plr)
    if hitboxTeamCheckEnabled then
        return plr.Team ~= player.Team
    else
        return true
    end
end

local function updateHitboxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if isEnemy(plr) then
                extendHitbox(plr)
            else
                restoredPart(plr)
            end
        end
    end
end

--------------------------------
-- AUTOFARM FUNCTIONS (Simplified)
--------------------------------
getgenv().AutoFarm = false
local runServiceConnection
local mouseDown = false
local camera = workspace.CurrentCamera

local function closestPlayer()
    local closestDistance = math.huge
    local closestPlr = nil
    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy ~= player and enemy.TeamColor ~= player.TeamColor and enemy.Character then
            local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = enemy.Character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid and humanoid.Health > 0 then
                local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    closestPlr = enemy
                end
            end
        end
    end
    return closestPlr
end

local function AutoFarm()
    game:GetService("ReplicatedStorage").wkspc.TimeScale.Value = 12
    runServiceConnection = game:GetService("RunService").Stepped:Connect(function()
        if getgenv().AutoFarm then
            local target = closestPlayer()
            if target and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local enemyHRP = target.Character.HumanoidRootPart
                local targetPos = enemyHRP.Position - enemyHRP.CFrame.LookVector * 2 + Vector3.new(0,2,0)
                player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
                if target.Character:FindFirstChild("Head") then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, target.Character.Head.Position)
                end
                if not mouseDown then
                    mouse1press()
                    mouseDown = true
                end
            else
                if mouseDown then
                    mouse1release()
                    mouseDown = false
                end
            end
        else
            if runServiceConnection then
                runServiceConnection:Disconnect()
                runServiceConnection = nil
            end
            if mouseDown then
                mouse1release()
                mouseDown = false
            end
        end
    end)
end

--------------------------------
-- TRIGGERBOT FUNCTIONS (Simplified)
--------------------------------
getgenv().triggerb = false
local triggerTeamCheck = "Team-Based"
local shotDelay = 0.2
local isAlive = true
local function checkHealth()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.HealthChanged:Connect(function(health)
            isAlive = health > 0
        end)
    end
end
player.CharacterAdded:Connect(checkHealth)
checkHealth()

game:GetService("RunService").RenderStepped:Connect(function()
    if getgenv().triggerb and isAlive then
        local mouse = player:GetMouse()
        local target = mouse.Target
        if target and target.Parent and target.Parent:FindFirstChild("Humanoid") and target.Parent.Name ~= player.Name then
            local targetPlr = Players:FindFirstChild(target.Parent.Name)
            if targetPlr and ((triggerTeamCheck == "FFA") or (triggerTeamCheck == "Everyone") or (triggerTeamCheck == "Team-Based" and targetPlr.Team ~= player.Team)) then
                mouse1press()
                wait(shotDelay)
                mouse1release()
            end
        end
    end
end)

--------------------------------
-- GUN MODS
--------------------------------
local originalValues = {FireRate = {}, ReloadTime = {}, EReloadTime = {}, Auto = {}, Spread = {}, Recoil = {}}

--------------------------------
-- FLUENT UI ELEMENTS
--------------------------------

--------------------------------
-- Main Tab (Hitbox, AutoFarm, Triggerbot)
--------------------------------
local MainTab = Tabs.Main

-- Hitbox Section
local hitboxToggle = MainTab:CreateToggle("Enable Hitbox", {Title = "[CLICK THIS FIRST] Enable Hitbox", Default = false, Description = "Continuously update hitboxes"})
hitboxToggle:OnChanged(function(state)
    hitboxEnabled = state
    if state then
        spawn(function()
            while hitboxEnabled do
                updateHitboxes()
                wait(0.1)
            end
        end)
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            restoredPart(plr)
        end
        hitbox_original_properties = {}
    end
    print("Hitbox enabled:", state)
end)

local hitboxSizeSlider = MainTab:CreateSlider("Hitbox Size", {
    Title = "Hitbox Size",
    Description = "Adjust the hitbox size",
    Default = hitboxSize,
    Min = 1,
    Max = 25,
    Rounding = 0
})
hitboxSizeSlider:OnChanged(function(val)
    hitboxSize = val
    if hitboxEnabled then updateHitboxes() end
    print("Hitbox Size set to:", val)
end)

local hitboxTransSlider = MainTab:CreateSlider("Hitbox Transparency", {
    Title = "Hitbox Transparency",
    Description = "Adjust transparency (1-10)",
    Default = hitboxTransparency,
    Min = 1,
    Max = 10,
    Rounding = 0
})
hitboxTransSlider:OnChanged(function(val)
    hitboxTransparency = val
    if hitboxEnabled then updateHitboxes() end
    print("Hitbox Transparency set to:", val)
end)

-- New Team Check Toggle (default off)
local teamCheckToggle = MainTab:CreateToggle("Enable Team Check (Hitbox)", {Title = "Team Check (Hitbox)", Default = false, Description = "When enabled, only enemy hitboxes expand"})
teamCheckToggle:OnChanged(function(state)
    hitboxTeamCheckEnabled = state
    if hitboxEnabled then updateHitboxes() end
    print("Team Check (Hitbox) set to:", state)
end)

-- AutoFarm Section
local autofarmToggle = MainTab:CreateToggle("AutoFarm", {Title = "AutoFarm", Default = false, Description = "Automatically move and shoot nearest enemy"})
autofarmToggle:OnChanged(function(state)
    getgenv().AutoFarm = state
    if state then
        wait(0.5)
        AutoFarm()
    else
        game:GetService("ReplicatedStorage").wkspc.CurrentCurse.Value = ""
        game:GetService("ReplicatedStorage").wkspc.TimeScale.Value = 1
        if runServiceConnection then runServiceConnection:Disconnect() end
        if mouseDown then mouse1release() end
    end
    print("AutoFarm set to:", state)
end)

-- Triggerbot Section
local triggerbotToggle = MainTab:CreateToggle("Enable Triggerbot", {Title = "Triggerbot", Default = false, Description = "Toggle triggerbot on/off"})
triggerbotToggle:OnChanged(function(state)
    getgenv().triggerb = state
    print("Triggerbot set to:", state)
end)

local triggerTeamDropdown = MainTab:CreateDropdown("Triggerbot Team Check", {
    Title = "Triggerbot Team Check Mode",
    Values = {"FFA", "Team-Based", "Everyone"},
    Multi = false,
    Default = "Team-Based"
})
triggerTeamDropdown:OnChanged(function(val)
    triggerTeamCheck = val
    print("Triggerbot Team Check set to:", val)
end)

local shotDelaySlider = MainTab:CreateSlider("Shot Delay", {
    Title = "Shot Delay",
    Description = "Delay between shots (in 0.1 increments)",
    Default = shotDelay * 10,
    Min = 1,
    Max = 10,
    Rounding = 0
})
shotDelaySlider:OnChanged(function(val)
    shotDelay = val / 10
    print("Shot Delay set to:", shotDelay)
end)

--------------------------------
-- Gun Mods Tab
--------------------------------
local GunTab = Tabs["Gun Mods"]

-- Only one Infinite Ammo toggle (v2 renamed)
local infiniteAmmoToggle = GunTab:CreateToggle("Infinite Ammo", {Title = "Infinite Ammo", Default = false, Description = "Toggle infinite ammo"})
infiniteAmmoToggle:OnChanged(function(state)
    if state then
        game:GetService("RunService").Stepped:Connect(function()
            pcall(function()
                local playerGui = player.PlayerGui
                playerGui.GUI.Client.Variables.ammocount.Value = 99
                playerGui.GUI.Client.Variables.ammocount2.Value = 99
            end)
        end)
    end
    print("Infinite Ammo set to:", state)
end)

local fastReloadToggle = GunTab:CreateToggle("Fast Reload", {Title = "Fast Reload", Default = false, Description = "Toggle fast reload"})
fastReloadToggle:OnChanged(function(state)
    for _, v in pairs(game.ReplicatedStorage.Weapons:GetChildren()) do
        if v:FindFirstChild("ReloadTime") then
            if state then
                if not originalValues.ReloadTime[v] then
                    originalValues.ReloadTime[v] = v.ReloadTime.Value
                end
                v.ReloadTime.Value = 0.01
            else
                v.ReloadTime.Value = originalValues.ReloadTime[v] or 0.8
            end
        end
        if v:FindFirstChild("EReloadTime") then
            if state then
                if not originalValues.EReloadTime[v] then
                    originalValues.EReloadTime[v] = v.EReloadTime.Value
                end
                v.EReloadTime.Value = 0.01
            else
                v.EReloadTime.Value = originalValues.EReloadTime[v] or 0.8
            end
        end
    end
    print("Fast Reload set to:", state)
end)

local fastFireRateToggle = GunTab:CreateToggle("Fast Fire Rate", {Title = "Fast Fire Rate", Default = false, Description = "Toggle fast fire rate"})
fastFireRateToggle:OnChanged(function(state)
    for _, v in pairs(game.ReplicatedStorage.Weapons:GetDescendants()) do
        if v.Name == "FireRate" or v.Name == "BFireRate" then
            if state then
                if not originalValues.FireRate[v] then
                    originalValues.FireRate[v] = v.Value
                end
                v.Value = 0.02
            else
                v.Value = originalValues.FireRate[v] or 0.8
            end
        end
    end
    print("Fast Fire Rate set to:", state)
end)

local alwaysAutoToggle = GunTab:CreateToggle("Always Auto", {Title = "Always Auto", Default = false, Description = "Toggle always automatic fire"})
alwaysAutoToggle:OnChanged(function(state)
    for _, v in pairs(game.ReplicatedStorage.Weapons:GetDescendants()) do
        if v.Name == "Auto" or v.Name == "AutoFire" or v.Name == "Automatic" or v.Name == "AutoShoot" or v.Name == "AutoGun" then
            if state then
                if not originalValues.Auto[v] then
                    originalValues.Auto[v] = v.Value
                end
                v.Value = true
            else
                v.Value = originalValues.Auto[v] or false
            end
        end
    end
    print("Always Auto set to:", state)
end)

local noSpreadToggle = GunTab:CreateToggle("No Spread", {Title = "No Spread", Default = false, Description = "Toggle no spread"})
noSpreadToggle:OnChanged(function(state)
    for _, v in pairs(game:GetService("ReplicatedStorage").Weapons:GetDescendants()) do
        if v.Name == "MaxSpread" or v.Name == "Spread" or v.Name == "SpreadControl" then
            if state then
                if not originalValues.Spread[v] then
                    originalValues.Spread[v] = v.Value
                end
                v.Value = 0
            else
                v.Value = originalValues.Spread[v] or 1
            end
        end
    end
    print("No Spread set to:", state)
end)

local noRecoilToggle = GunTab:CreateToggle("No Recoil", {Title = "No Recoil", Default = false, Description = "Toggle no recoil"})
noRecoilToggle:OnChanged(function(state)
    for _, v in pairs(game:GetService("ReplicatedStorage").Weapons:GetDescendants()) do
        if v.Name == "RecoilControl" or v.Name == "Recoil" then
            if state then
                if not originalValues.Recoil[v] then
                    originalValues.Recoil[v] = v.Value
                end
                v.Value = 0
            else
                v.Value = originalValues.Recoil[v] or 1
            end
        end
    end
    print("No Recoil set to:", state)
end)

--------------------------------
-- Player Tab (Fly, Movement, Jump, Anti-Aim, Debris, Third Person)
--------------------------------
local PlayerTab = Tabs.Player

-- Fly Controls
local flyToggle = PlayerTab:CreateToggle("Fly", {Title = "Fly", Default = false, Description = "Toggle fly mode"})
flyToggle:OnChanged(function(state)
    if state then
        startFly()
    else
        endFly()
    end
    print("Fly set to:", state)
end)

local flySpeedSlider = PlayerTab:CreateSlider("Fly Speed", {
    Title = "Fly Speed",
    Description = "Adjust fly speed",
    Default = flySettings.flyspeed,
    Min = 1,
    Max = 500,
    Rounding = 0
})
flySpeedSlider:OnChanged(function(val)
    flySettings.flyspeed = val
    print("Fly Speed set to:", val)
end)

-- Custom WalkSpeed Controls
local isWalkSpeedEnabled = false
local selectedWalkMethod = "Velocity"
local walkSettings = { WalkSpeed = 16 }
PlayerTab:CreateToggle("Custom WalkSpeed", {Title = "Custom WalkSpeed", Default = false, Description = "Toggle custom walk speed"}):OnChanged(function(state)
    isWalkSpeedEnabled = state
    print("Custom WalkSpeed set to:", state)
end)
PlayerTab:CreateDropdown("Walk Method", {
    Title = "Walk Method",
    Values = {"Velocity", "Vector", "CFrame"},
    Multi = false,
    Default = "Velocity"
}):OnChanged(function(val)
    selectedWalkMethod = val
    print("Walk Method set to:", val)
end)
PlayerTab:CreateSlider("Walkspeed Power", {
    Title = "Walkspeed Power",
    Description = "Adjust walkspeed power",
    Default = walkSettings.WalkSpeed,
    Min = 16,
    Max = 500,
    Rounding = 0
}):OnChanged(function(val)
    walkSettings.WalkSpeed = val
    print("WalkSpeed Power set to:", val)
end)

game:GetService("RunService").Stepped:Connect(function(deltaTime)
    if isWalkSpeedEnabled then
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart then
                local moveDir = humanoid.MoveDirection
                local speed = walkSettings.WalkSpeed
                if selectedWalkMethod == "Velocity" then
                    if moveDir.Magnitude > 0 then
                        rootPart.Velocity = Vector3.new(moveDir.X * speed, rootPart.Velocity.Y, moveDir.Z * speed)
                    else
                        rootPart.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0)
                    end
                elseif selectedWalkMethod == "Vector" then
                    local scaleFactor = 0.0001
                    rootPart.CFrame = rootPart.CFrame + (moveDir * speed * deltaTime * scaleFactor)
                elseif selectedWalkMethod == "CFrame" then
                    local scaleFactor = 0.0001
                    rootPart.CFrame = rootPart.CFrame + (moveDir * speed * deltaTime * scaleFactor)
                else
                    humanoid.WalkSpeed = speed
                end
            end
        end
    end
end)

-- Custom JumpPower Controls
local isJumpPowerEnabled = false
local jumpMethod = "Velocity"
local currentJumpPower = 50  -- Default set to 50
local jumpConn
PlayerTab:CreateToggle("Custom JumpPower", {Title = "Custom JumpPower", Default = false, Description = "Toggle custom jump power"}):OnChanged(function(state)
    isJumpPowerEnabled = state
    print("Custom JumpPower set to:", state)
end)
PlayerTab:CreateDropdown("Jump Method", {
    Title = "Jump Method",
    Values = {"Velocity", "Vector", "CFrame"},
    Multi = false,
    Default = "Velocity"
}):OnChanged(function(val)
    jumpMethod = val
    print("Jump Method set to:", val)
end)
PlayerTab:CreateSlider("Change JumpPower", {
    Title = "JumpPower",
    Description = "Adjust jump power",
    Default = currentJumpPower,
    Min = 30,
    Max = 500,
    Rounding = 0
}):OnChanged(function(val)
    currentJumpPower = val
    local character = player.Character
    if character then
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.UseJumpPower = true
        if jumpConn then jumpConn:Disconnect() end
        jumpConn = humanoid.Jumping:Connect(function(isActive)
            if isJumpPowerEnabled and isActive and character:FindFirstChild("HumanoidRootPart") then
                if jumpMethod == "Velocity" then
                    character.HumanoidRootPart.Velocity = Vector3.new(character.HumanoidRootPart.Velocity.X, val, character.HumanoidRootPart.Velocity.Z)
                elseif jumpMethod == "Vector" then
                    character.HumanoidRootPart.Velocity = Vector3.new(0, val, 0)
                elseif jumpMethod == "CFrame" then
                    character:SetPrimaryPartCFrame(character:GetPrimaryPartCFrame() + Vector3.new(0, val, 0))
                end
            end
        end)
    end
    print("JumpPower set to:", val)
end)

-- Anti-Aim Controls
local antiAimToggle = PlayerTab:CreateToggle("Anti-Aim v1", {Title = "Anti-Aim v1", Default = false, Description = "Toggle anti-aim"})
antiAimToggle:OnChanged(function(state)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if state and hrp then
        local spin = Instance.new("BodyAngularVelocity", hrp)
        spin.Name = "AntiAimSpin"
        spin.AngularVelocity = Vector3.new(0, 10, 0)
        spin.MaxTorque = Vector3.new(0, math.huge, 0)
        spin.P = 500000
        local gyro = Instance.new("BodyGyro", hrp)
        gyro.Name = "AntiAimGyro"
        gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        gyro.CFrame = hrp.CFrame
        gyro.P = 3000
    else
        if hrp then
            local spin = hrp:FindFirstChild("AntiAimSpin")
            if spin then spin:Destroy() end
            local gyro = hrp:FindFirstChild("AntiAimGyro")
            if gyro then gyro:Destroy() end
        end
    end
    print("Anti-Aim set to:", state)
end)
PlayerTab:CreateSlider("Spin Speed", {
    Title = "Spin Speed",
    Description = "Adjust anti-aim spin speed",
    Default = 10,
    Min = 10,
    Max = 100,
    Rounding = 0
}):OnChanged(function(val)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local spin = hrp:FindFirstChild("AntiAimSpin")
        if spin then
            spin.AngularVelocity = Vector3.new(0, val, 0)
        end
    end
    print("Spin Speed set to:", val)
end)

-- Object Teleport (Debris Collection)
local debrisSelected = "Both"
local debrisToggle = PlayerTab:CreateToggle("Enable Collect Debris", {Title = "Collect Debris", Default = false, Description = "Teleport DeadHP/DeadAmmo to you"})
debrisToggle:OnChanged(function(state)
    _G.isCollecting = state
    if state then
        spawn(function()
            while _G.isCollecting do
                pcall(function()
                    local character = player.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        for _, v in pairs(workspace.Debris:GetChildren()) do
                            if (debrisSelected == "DeadHP" and v.Name == "DeadHP") or
                               (debrisSelected == "DeadAmmo" and v.Name == "DeadAmmo") or
                               (debrisSelected == "Both" and (v.Name == "DeadHP" or v.Name == "DeadAmmo")) then
                                v.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0.2, 0)
                            end
                        end
                    end
                end)
                wait(0.1)
            end
        end)
    end
    print("Collect Debris set to:", state)
end)
PlayerTab:CreateDropdown("Select Object", {
    Title = "Select Object",
    Values = {"DeadHP", "DeadAmmo", "Both"},
    Multi = false,
    Default = "Both"
}):OnChanged(function(val)
    debrisSelected = val
    print("Debris selection set to:", val)
end)

-- Third Person Toggle
local thirdPersonToggle = PlayerTab:CreateToggle("Third Person", {Title = "Third Person", Default = false, Description = "Toggle third-person view"})
thirdPersonToggle:OnChanged(function(state)
    if state then
        -- Adjust zoom distances and force the camera to follow your humanoid
        game:GetService("StarterPlayer").CameraMaxZoomDistance = 1000
        game:GetService("StarterPlayer").CameraMinZoomDistance = 0
        player.CameraMode = Enum.CameraMode.Classic
        if player.Character then
            workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
        end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        print("Third person enabled")
    else
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        print("Third person disabled, first person locked")
    end
end)

--------------------------------
-- Color Skins Tab (Arm & Gun Chams)
--------------------------------
local SkinsTab = Tabs["Color Skins"]

-- Arm Skins
local armMaterialDropdown = SkinsTab:CreateDropdown("Arm Material", {
    Title = "Arm Material",
    Values = {"Plastic", "ForceField", "Wood", "Grass"},
    Multi = false,
    Default = "Plastic"
})
armMaterialDropdown:OnChanged(function(val)
    _G.armMaterial = val
    print("Arm Material set to:", val)
end)
local armColorPicker = SkinsTab:CreateColorpicker("Arm Color", {
    Title = "Arm Color",
    Default = Color3.fromRGB(50,50,50)
})
armColorPicker:OnChanged(function()
    _G.armColor = armColorPicker.Value
    print("Arm Color set to:", armColorPicker.Value)
end)
local armCharmsToggle = SkinsTab:CreateToggle("Arm Charms", {Title = "Arm Charms", Default = false})
armCharmsToggle:OnChanged(function(state)
    _G.armCharms = state
    if state then
        spawn(function()
            while _G.armCharms do
                wait(0.01)
                local cameraArms = workspace.CurrentCamera:WaitForChild("Arms")
                if cameraArms then
                    for _, part in pairs(cameraArms:GetDescendants()) do
                        if (part.Name == "Right Arm" or part.Name == "Left Arm") and part:IsA("BasePart") then
                            part.Material = Enum.Material[_G.armMaterial or "Plastic"]
                            part.Color = _G.armColor or Color3.fromRGB(50,50,50)
                        end
                    end
                end
            end
        end)
    end
    print("Arm Charms set to:", state)
end)

-- Gun Skins
local gunMaterialDropdown = SkinsTab:CreateDropdown("Gun Material", {
    Title = "Gun Material",
    Values = {"Plastic", "ForceField", "Wood", "Grass"},
    Multi = false,
    Default = "Plastic"
})
gunMaterialDropdown:OnChanged(function(val)
    _G.gunMaterial = val
    print("Gun Material set to:", val)
end)
local gunColorPicker = SkinsTab:CreateColorpicker("Gun Color", {
    Title = "Gun Color",
    Default = Color3.fromRGB(50,50,50)
})
gunColorPicker:OnChanged(function()
    _G.gunColor = gunColorPicker.Value
    print("Gun Color set to:", gunColorPicker.Value)
end)
local gunCharmsToggle = SkinsTab:CreateToggle("Gun Charms", {Title = "Gun Charms", Default = false})
gunCharmsToggle:OnChanged(function(state)
    _G.gunCharms = state
    if state then
        spawn(function()
            while _G.gunCharms do
                wait(0.01)
                local arms = workspace.CurrentCamera:WaitForChild("Arms")
                if arms then
                    for _, part in pairs(arms:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            part.Material = Enum.Material[_G.gunMaterial or "Plastic"]
                            part.Color = _G.gunColor or Color3.fromRGB(50,50,50)
                        end
                    end
                end
            end
        end)
    end
    print("Gun Charms set to:", state)
end)

-- Rainbow Gun examples
local rainbowGunToggle1 = SkinsTab:CreateToggle("Rainbow Gun v1", {Title = "Rainbow Gun v1", Default = false})
rainbowGunToggle1:OnChanged(function(state)
    _G.rainbowGun1 = state
    print("Rainbow Gun v1 set to:", state)
end)
game:GetService("RunService").RenderStepped:Connect(function() 
    if workspace.CurrentCamera:FindFirstChild('Arms') and _G.rainbowGun1 then 
        local c = tick() % 1
        for _, part in pairs(workspace.CurrentCamera.Arms:GetDescendants()) do 
            if part:IsA('MeshPart') then 
                part.Color = Color3.fromHSV(c, 1, 1)
            end 
        end 
    end 
end)
local rainbowGunToggle2 = SkinsTab:CreateToggle("Rainbow Gun v2 [Crazy Fast Animation]", {Title = "Rainbow Gun v2", Default = false})
rainbowGunToggle2:OnChanged(function(state)
    _G.rainbowGun2 = state
    print("Rainbow Gun v2 set to:", state)
end)
local rainbowHue = 0
local hueIncrement = 0.1
game:GetService("RunService").RenderStepped:Connect(function()
    if workspace.CurrentCamera:FindFirstChild('Arms') and _G.rainbowGun2 then
        rainbowHue = rainbowHue + hueIncrement
        if rainbowHue >= 1 then rainbowHue = rainbowHue % 1 end
        for _, part in pairs(workspace.CurrentCamera.Arms:GetDescendants()) do
            if part:IsA('MeshPart') then
                part.Color = Color3.fromHSV(rainbowHue, 1, 1)
            end
        end
    end
end)

--------------------------------
-- Extra Tab
--------------------------------
local ExtraTab = Tabs.Extra

local particlesToggle = ExtraTab:CreateToggle("Mess up your screen lol", {Title = "Particles", Default = false, Description = "Enable/disable particles on your character"})
particlesToggle:OnChanged(function(state)
    if state then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") then
                v.Parent = player.Character and player.Character:FindFirstChild("Particle Area") or v.Parent
            end
        end
    else
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") then
                v.Parent = workspace
            end
        end
    end
    print("Particles set to:", state)
end)

local maxLevelToggle = ExtraTab:CreateToggle("Max Level???", {Title = "Max Level", Default = false, Description = "Set your score and kills to astronomical values"})
maxLevelToggle:OnChanged(function(state)
    local stats = player.CareerStatsCache
    if state and stats then
        stats.Score.Value = 1e18
        stats.Kills.Value = 1e14
    end
    print("Max Level set to:", state)
end)

local changeNameToggle = ExtraTab:CreateToggle("Change Name", {Title = "Change Name", Default = false, Description = "Change your name in various GUIs"})
changeNameToggle:OnChanged(function(state)
    _G.hidename = state
    if state then
        spawn(function()
            while _G.hidename do
                pcall(function()
                    local gui = player.PlayerGui
                    if gui and gui.Menew_Main and gui.GUI_Scorecard then
                        gui.Menew_Main.Container.PlrName.Text = "AdvanceChan UwU"
                        gui.Menew_Main.Container.PlrName2.Text = "AdvanceChan UwU"
                        gui.GUI_Scorecard.Scorecard.PlayerCard.Username.Text = "AdvanceFalling Team"
                    end
                end)
                wait(0.2)
            end
        end)
    end
    print("Change Name set to:", state)
end)

local chadToggle = ExtraTab:CreateToggle("IsChad", {Title = "IsChad", Default = false})
chadToggle:OnChanged(function(state)
    if state then
        if not player:FindFirstChild("IsChad") then
            local iv = Instance.new("IntValue", player)
            iv.Name = "IsChad"
        end
    else
        if player:FindFirstChild("IsChad") then
            player.IsChad:Destroy()
        end
    end
    print("IsChad set to:", state)
end)

local vipToggle = ExtraTab:CreateToggle("VIP", {Title = "VIP", Default = false})
vipToggle:OnChanged(function(state)
    if state then
        if not player:FindFirstChild("VIP") then
            local iv = Instance.new("IntValue", player)
            iv.Name = "VIP"
        end
    else
        if player:FindFirstChild("VIP") then
            player.VIP:Destroy()
        end
    end
    print("VIP set to:", state)
end)

--------------------------------
-- Visuals Tab (ESP)
--------------------------------
local VisualsTab = Tabs.Visuals
local espLib = loadstring(game:HttpGet("https://rawscript.vercel.app/api/raw/esp_1"))()

local espToggle = VisualsTab:CreateToggle("Enable ESP", {Title = "Enable ESP", Default = false})
espToggle:OnChanged(function(state)
    espLib:Toggle(state)
    espLib.Players = state
    print("ESP set to:", state)
end)
local tracersToggle = VisualsTab:CreateToggle("Tracers ESP", {Title = "Tracers", Default = false})
tracersToggle:OnChanged(function(state)
    espLib.Tracers = state
    print("ESP Tracers set to:", state)
end)
local namesToggle = VisualsTab:CreateToggle("Name ESP", {Title = "Names", Default = false})
namesToggle:OnChanged(function(state)
    espLib.Names = state
    print("ESP Names set to:", state)
end)
local boxesToggle = VisualsTab:CreateToggle("Boxes ESP", {Title = "Boxes", Default = false})
boxesToggle:OnChanged(function(state)
    espLib.Boxes = state
    print("ESP Boxes set to:", state)
end)
local teamColorToggle = VisualsTab:CreateToggle("Team Coordinate", {Title = "Team Color", Default = false})
teamColorToggle:OnChanged(function(state)
    espLib.TeamColor = state
    print("ESP Team Color set to:", state)
end)
local teammatesToggle = VisualsTab:CreateToggle("Teammates", {Title = "Show Teammates", Default = false})
teammatesToggle:OnChanged(function(state)
    espLib.TeamMates = state
    print("ESP Teammates set to:", state)
end)
local espColorPicker = VisualsTab:CreateColorpicker("ESP Color", {Title = "ESP Color", Default = Color3.fromRGB(255,255,255)})
espColorPicker:OnChanged(function()
    espLib.Color = espColorPicker.Value
    print("ESP Color set to:", espColorPicker.Value)
end)

--------------------------------
-- Settings Tab (Performance, Server Hop, etc.)
--------------------------------
local SettingsTab = Tabs.Settings

local antiLagToggle = SettingsTab:CreateToggle("Anti Lag", {Title = "Anti Lag", Default = false, Description = "Optimize materials and decals"})
antiLagToggle:OnChanged(function(state)
    if state then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") then
                obj.Material = Enum.Material.SmoothPlastic
            end
        end
    else
        -- Restoration logic can be added if desired.
    end
    print("Anti Lag set to:", state)
end)
local fpsBoostToggle = SettingsTab:CreateToggle("FPS Boost", {Title = "FPS Boost", Default = false})
fpsBoostToggle:OnChanged(function(state)
    if state then
        local terrain = workspace.Terrain
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = "Level01"
    else
        settings().Rendering.QualityLevel = "Automatic"
    end
    print("FPS Boost set to:", state)
end)
local fullBrightToggle = SettingsTab:CreateToggle("Full Bright", {Title = "Full Bright", Default = false})
fullBrightToggle:OnChanged(function(state)
    local L = game:GetService("Lighting")
    if state then
        L.Ambient = Color3.new(1,1,1)
        L.ColorShift_Bottom = Color3.new(1,1,1)
        L.ColorShift_Top = Color3.new(1,1,1)
    else
        L.Ambient = Color3.new(0.5,0.5,0.5)
        L.ColorShift_Bottom = Color3.new(0,0,0)
        L.ColorShift_Top = Color3.new(0,0,0)
    end
    print("Full Bright set to:", state)
end)
local serverHopButton = SettingsTab:CreateButton{
    Title = "Server Hop",
    Description = "Hop to another server",
    Callback = function()
        -- Insert your full server hop logic here.
        print("Server Hop triggered")
    end
}
local rejoinButton = SettingsTab:CreateButton{
    Title = "Rejoin Server",
    Description = "Rejoin current server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
    end
}
local closeUIKeybind = SettingsTab:CreateKeybind("Close UI", {
    Title = "Close UI Keybind",
    Default = "LeftControl",
    Mode = "Toggle",
    Callback = function(val)
        Library:ToggleUI()
        print("UI toggled, key state:", val)
    end
})
closeUIKeybind:OnChanged(function(val)
    print("Close UI Keybind changed:", val)
end)

--------------------------------
-- Hand Over to SaveManager & InterfaceManager
--------------------------------
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Library:Notify{
    Title = "Arsenal - Collapse",
    Content = "The script has been loaded.",
    Duration = 8
}
SaveManager:LoadAutoloadConfig()
