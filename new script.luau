--
--    made by aucuse
--
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart")
local Humanoid = character:WaitForChild("Humanoid")

local flying = false
local tpEnabled = true
local espEnabled = true
local mobEspEnabled = false
local noclipEnabled = false
local noFogEnabled = false
local infJumpEnabled = false
local walkSpeedEnabled = false
local flySpeedEnabled = false
local noFallEnabled = false
local noStunEnabled = false
local hitboxExtenderEnabled = false
local backAttachEnabled = false
local spectatingTarget = nil

local speed = 16
local flySpeed = 50
local MAX_SPEED = 500
local maxEspDistance = 1000
local hitboxSize = 5

-- Custom Keybinds
local flightKey = Enum.KeyCode.T
local walkSpeedKey = Enum.KeyCode.G
local toggleGuiKey = Enum.KeyCode.RightShift
local hitboxKey = Enum.KeyCode.H
local backAttachKey = Enum.KeyCode.B

-- Detailed ESP Sub-options
local espName = true
local espHealthBar = true
local espHpNumber = true
local espDistance = true
local espEquipped = true
local espBox = true
local espHeadDot = true
local espCharms = true

-- World Lighting Presets
local currentLightingPreset = "Normal"

-- New Feature States
local selectedBackAttachTarget = nil
local selectedFlingTarget = nil
local flingPlayerEnabled = false
local savedWaypoints = {}

-- Configuration Save/Load System
local CONFIG_FILE_NAME = "AucuseHub_Config.json"

local function saveConfig()
    local configData = {
        flightKey = flightKey.Name,
        walkSpeedKey = walkSpeedKey.Name,
        toggleGuiKey = toggleGuiKey.Name,
        hitboxKey = hitboxKey.Name,
        backAttachKey = backAttachKey.Name,
        speed = speed,
        flySpeed = flySpeed,
        maxEspDistance = maxEspDistance,
        hitboxSize = hitboxSize,
        espName = espName,
        espHealthBar = espHealthBar,
        espHpNumber = espHpNumber,
        espDistance = espDistance,
        espEquipped = espEquipped,
        espBox = espBox,
        espHeadDot = espHeadDot,
        espCharms = espCharms,
        tpEnabled = tpEnabled,
        espEnabled = espEnabled,
        mobEspEnabled = mobEspEnabled,
        noclipEnabled = noclipEnabled,
        noFogEnabled = noFogEnabled,
        infJumpEnabled = infJumpEnabled,
        walkSpeedEnabled = walkSpeedEnabled,
        noFallEnabled = noFallEnabled,
        noStunEnabled = noStunEnabled,
        hitboxExtenderEnabled = hitboxExtenderEnabled,
        backAttachEnabled = backAttachEnabled
    }
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(configData))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE_NAME) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE_NAME))
            if data then
                if data.flightKey and Enum.KeyCode[data.flightKey] then flightKey = Enum.KeyCode[data.flightKey] end
                if data.walkSpeedKey and Enum.KeyCode[data.walkSpeedKey] then walkSpeedKey = Enum.KeyCode[data.walkSpeedKey] end
                if data.toggleGuiKey and Enum.KeyCode[data.toggleGuiKey] then toggleGuiKey = Enum.KeyCode[data.toggleGuiKey] end
                if data.hitboxKey and Enum.KeyCode[data.hitboxKey] then hitboxKey = Enum.KeyCode[data.hitboxKey] end
                if data.backAttachKey and Enum.KeyCode[data.backAttachKey] then backAttachKey = Enum.KeyCode[data.backAttachKey] end
                if data.speed then speed = data.speed end
                if data.flySpeed then flySpeed = data.flySpeed end
                if data.maxEspDistance then maxEspDistance = data.maxEspDistance end
                if data.hitboxSize then hitboxSize = data.hitboxSize end
                if data.espName ~= nil then espName = data.espName end
                if data.espHealthBar ~= nil then espHealthBar = data.espHealthBar end
                if data.espHpNumber ~= nil then espHpNumber = data.espHpNumber end
                if data.espDistance ~= nil then espDistance = data.espDistance end
                if data.espEquipped ~= nil then espEquipped = data.espEquipped end
                if data.espBox ~= nil then espBox = data.espBox end
                if data.espHeadDot ~= nil then espHeadDot = data.espHeadDot end
                if data.espCharms ~= nil then espCharms = data.espCharms end
                if data.tpEnabled ~= nil then tpEnabled = data.tpEnabled end
                if data.espEnabled ~= nil then espEnabled = data.espEnabled end
                if data.mobEspEnabled ~= nil then mobEspEnabled = data.mobEspEnabled end
                if data.noclipEnabled ~= nil then noclipEnabled = data.noclipEnabled end
                if data.noFogEnabled ~= nil then noFogEnabled = data.noFogEnabled end
                if data.infJumpEnabled ~= nil then infJumpEnabled = data.infJumpEnabled end
                if data.walkSpeedEnabled ~= nil then walkSpeedEnabled = data.walkSpeedEnabled end
                if data.noFallEnabled ~= nil then noFallEnabled = data.noFallEnabled end
                if data.noStunEnabled ~= nil then noStunEnabled = data.noStunEnabled end
                if data.hitboxExtenderEnabled ~= nil then hitboxExtenderEnabled = data.hitboxExtenderEnabled end
                if data.backAttachEnabled ~= nil then backAttachEnabled = data.backAttachEnabled end
            end
        end
    end)
end

loadConfig()

local espFolder = Instance.new("Folder", CoreGui)
espFolder.Name = "RainbowESPStorage"

local mobEspFolder = Instance.new("Folder", CoreGui)
mobEspFolder.Name = "RainbowMobESPStorage"

local function getNeonCreamyIcyThemeColor()
    local t = tick() * 2.5
    local mix = (math.sin(t) + 1) / 2
    local creamyLightBlue = Color3.fromRGB(150, 220, 255)
    local creamyWhite = Color3.fromRGB(245, 250, 255)
    return creamyLightBlue:Lerp(creamyWhite, mix)
end

local updateActiveStatusHeader

local function createPlayerESP(targetPlayer)
    if targetPlayer == player then return end

    local function setupESP(targetChar)
        if not targetChar then return end
        local head = targetChar:WaitForChild("Head", 5)
        local hum = targetChar:WaitForChild("Humanoid", 5)
        local rootPart = targetChar:WaitForChild("HumanoidRootPart", 5)
        if not head or not hum or not rootPart then return end

        if espFolder:FindFirstChild(targetPlayer.Name) then
            espFolder[targetPlayer.Name]:Destroy()
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = targetPlayer.Name
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 160, 0, 85)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = espFolder

        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0, 16)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextStrokeTransparency = 0.3

        local distanceLabel = Instance.new("TextLabel", billboard)
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Position = UDim2.new(0, 0, 0, 16)
        distanceLabel.Size = UDim2.new(1, 0, 0, 14)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.TextSize = 10
        distanceLabel.TextColor3 = Color3.fromRGB(210, 230, 255)
        distanceLabel.TextStrokeTransparency = 0.4

        local itemLabel = Instance.new("TextLabel", billboard)
        itemLabel.Name = "ItemLabel"
        itemLabel.Position = UDim2.new(0, 0, 0, 30)
        itemLabel.Size = UDim2.new(1, 0, 0, 14)
        itemLabel.BackgroundTransparency = 1
        itemLabel.Font = Enum.Font.GothamMedium
        itemLabel.TextSize = 10
        itemLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
        itemLabel.TextStrokeTransparency = 0.4

        local hpNumberLabel = Instance.new("TextLabel", billboard)
        hpNumberLabel.Name = "HpNumberLabel"
        hpNumberLabel.Position = UDim2.new(0, 0, 0, 44)
        hpNumberLabel.Size = UDim2.new(1, 0, 0, 14)
        hpNumberLabel.BackgroundTransparency = 1
        hpNumberLabel.Font = Enum.Font.GothamBold
        hpNumberLabel.TextSize = 10
        hpNumberLabel.TextColor3 = Color3.fromRGB(245, 250, 255)
        hpNumberLabel.TextStrokeTransparency = 0.4
        hpNumberLabel.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)

        local healthBg = Instance.new("Frame", billboard)
        healthBg.Name = "HealthBg"
        healthBg.Position = UDim2.new(0.1, 0, 0, 60)
        healthBg.Size = UDim2.new(0.8, 0, 0, 4)
        healthBg.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
        healthBg.BorderSizePixel = 0
        Instance.new("UICorner", healthBg).CornerRadius = UDim.new(0, 2)

        local healthFill = Instance.new("Frame", healthBg)
        healthFill.Name = "HealthFill"
        healthFill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(150, 220, 255)
        healthFill.BorderSizePixel = 0
        Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 2)

        local headDot = Instance.new("Frame", billboard)
        headDot.Name = "HeadDot"
        headDot.AnchorPoint = Vector2.new(0.5, 0.5)
        headDot.Position = UDim2.new(0.5, 0, 0.88, 0)
        headDot.Size = UDim2.new(0, 6, 0, 6)
        headDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        headDot.BorderSizePixel = 0
        Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)
        local headDotStroke = Instance.new("UIStroke", headDot)
        headDotStroke.Thickness = 1
        headDotStroke.Color = Color3.fromRGB(10, 20, 35)

        local boxFrame = Instance.new("Frame", billboard)
        boxFrame.Name = "BoxFrame"
        boxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        boxFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        boxFrame.Size = UDim2.new(0, 44, 0, 75)
        boxFrame.BackgroundTransparency = 1
        boxFrame.BorderSizePixel = 0
        local boxStroke = Instance.new("UIStroke", boxFrame)
        boxStroke.Name = "BoxStroke"
        boxStroke.Thickness = 1.5

        local healthConnection
        healthConnection = hum.HealthChanged:Connect(function(newHealth)
            if hum.MaxHealth > 0 then
                healthFill.Size = UDim2.new(math.clamp(newHealth / hum.MaxHealth, 0, 1), 0, 1, 0)
                hpNumberLabel.Text = math.floor(newHealth) .. "/" .. math.floor(hum.MaxHealth)
            end
        end)

        billboard.Destroying:Connect(function()
            if healthConnection then healthConnection:Disconnect() end
        end)
    end

    if targetPlayer.Character then setupESP(targetPlayer.Character) end
    targetPlayer.CharacterAdded:Connect(setupESP)
end

for _, p in ipairs(Players:GetPlayers()) do createPlayerESP(p) end
Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(function(p)
    if espFolder:FindFirstChild(p.Name) then espFolder[p.Name]:Destroy() end
end)

local function setupMobESP(model)
    if not model:IsA("Model") then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChild("PrimaryPart")
    
    if not hum or not rootPart then return end
    
    local isPlayerModel = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then isPlayerModel = true break end
    end
    if isPlayerModel then return end

    local uniqueId = model:GetDebugId()
    if mobEspFolder:FindFirstChild(uniqueId) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = uniqueId
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 130, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = mobEspFolder

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "[MOB] " .. model.Name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextColor3 = Color3.fromRGB(255, 120, 120)

    local healthBg = Instance.new("Frame", billboard)
    healthBg.Position = UDim2.new(0.1, 0, 0.5, 0)
    healthBg.Size = UDim2.new(0.8, 0, 0, 4)
    healthBg.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
    healthBg.BorderSizePixel = 0
    Instance.new("UICorner", healthBg).CornerRadius = UDim.new(0, 2)

    local healthFill = Instance.new("Frame", healthBg)
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(150, 220, 255)
    healthFill.BorderSizePixel = 0
    Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 2)

    local healthConnection
    healthConnection = hum.HealthChanged:Connect(function(newHealth)
        if hum.MaxHealth > 0 then
            healthFill.Size = UDim2.new(math.clamp(newHealth / hum.MaxHealth, 0, 1), 0, 1, 0)
        end
    end)

    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if healthConnection then healthConnection:Disconnect() end
            billboard:Destroy()
        end
    end)
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then setupMobESP(obj) end
end
Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
        task.wait(0.5)
        setupMobESP(obj)
    end
end)

local neonStrokes = {}
local titleLabelUI = nil
local activeStatusLabelUI = nil

local function registerNeonStroke(stroke)
    table.insert(neonStrokes, stroke)
end

RunService.RenderStepped:Connect(function()
    local themeColor = getNeonCreamyIcyThemeColor()
    
    for i = #neonStrokes, 1, -1 do
        local stroke = neonStrokes[i]
        if stroke and stroke.Parent then stroke.Color = themeColor else table.remove(neonStrokes, i) end
    end

    if titleLabelUI then titleLabelUI.TextColor3 = themeColor end
    if activeStatusLabelUI then activeStatusLabelUI.TextColor3 = themeColor end

    for _, gui in ipairs(espFolder:GetChildren()) do
        if gui:IsA("BillboardGui") then
            local targetName = gui.Name
            local targetPlayerObj = Players:FindFirstChild(targetName)
            if targetPlayerObj and targetPlayerObj.Character and HRP then
                local tHRP = targetPlayerObj.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local dist = math.floor((tHRP.Position - HRP.Position).Magnitude)
                    if espEnabled and dist <= maxEspDistance then
                        gui.Enabled = true
                        local distLbl = gui:FindFirstChild("DistanceLabel")
                        if distLbl then
                            distLbl.Visible = espDistance
                            distLbl.Text = dist .. " studs"
                        end

                        local nameLbl = gui:FindFirstChild("NameLabel")
                        if nameLbl then
                            nameLbl.Visible = espName
                            nameLbl.Text = targetPlayerObj.Name
                            nameLbl.TextColor3 = themeColor
                        end

                        local healthBg = gui:FindFirstChild("HealthBg")
                        if healthBg then healthBg.Visible = espHealthBar end

                        local hpNumLbl = gui:FindFirstChild("HpNumberLabel")
                        if hpNumLbl then
                            hpNumLbl.Visible = espHpNumber
                            hpNumLbl.TextColor3 = themeColor
                        end

                        local headDot = gui:FindFirstChild("HeadDot")
                        if headDot then headDot.Visible = espHeadDot end

                        local boxFrame = gui:FindFirstChild("BoxFrame")
                        if boxFrame then
                            boxFrame.Visible = espBox
                            local boxStroke = boxFrame:FindFirstChild("BoxStroke")
                            if boxStroke then boxStroke.Color = themeColor end
                        end

                        local itemLbl = gui:FindFirstChild("ItemLabel")
                        if itemLbl then
                            itemLbl.Visible = espEquipped
                            itemLbl.TextColor3 = themeColor
                            local equippedTool = nil
                            for _, item in ipairs(targetPlayerObj.Character:GetChildren()) do
                                if item:IsA("Tool") then
                                    equippedTool = item
                                    break
                                end
                            end
                            if equippedTool then
                                itemLbl.Text = "[" .. equippedTool.Name .. "]"
                            else
                                itemLbl.Text = "[None]"
                            end
                        end
                    else
                        gui.Enabled = false
                    end
                else
                    gui.Enabled = false
                end
            else
                gui.Enabled = false
            end
        end
    end

    -- ESP Charms (Highlight Effect)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local hl = char:FindFirstChild("AucuseCharmHighlight")
            if espEnabled and espCharms then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "AucuseCharmHighlight"
                    hl.Adornee = char
                    hl.Parent = char
                end
                hl.FillColor = themeColor
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.OutlineTransparency = 0.2
                hl.Enabled = true
            else
                if hl then hl.Enabled = false end
            end
        end
    end

    for _, gui in ipairs(mobEspFolder:GetChildren()) do
        if gui:IsA("BillboardGui") then gui.Enabled = mobEspEnabled end
    end

    if spectatingTarget and spectatingTarget.Character then
        local targetHRP = spectatingTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            camera.CameraType = Enum.CameraType.Scriptable
            local targetPos = targetHRP.Position + Vector3.new(0, 3, 0)
            local camPos = targetPos - (targetHRP.CFrame.LookVector * 12) + Vector3.new(0, 6, 0)
            camera.CFrame = CFrame.new(camPos, targetPos)
        end
    end
end)

RunService.Stepped:Connect(function()
    if (noclipEnabled or flying) and character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    -- Hitbox Extender logic
    if hitboxExtenderEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    tRoot.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    tRoot.Transparency = 0.6
                    tRoot.BrickColor = BrickColor.new("Cyan")
                    tRoot.CanCollide = false
                end
            end
        end
    end

    -- Back Attach target logic
    if backAttachEnabled and selectedBackAttachTarget and selectedBackAttachTarget.Character and HRP then
        local targetHRP = selectedBackAttachTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            HRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3.5)
        end
    end

    -- Fling Player target logic
    if flingPlayerEnabled and selectedFlingTarget and selectedFlingTarget.Character and HRP then
        local targetHRP = selectedFlingTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            HRP.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)
            HRP.CFrame = targetHRP.CFrame
        end
    end
end)

local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character then
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP and HRP then HRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3) end
    end
end

local function addNeonStroke(instance, thickness)
    local stroke = Instance.new("UIStroke", instance)
    stroke.Thickness = thickness or 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    registerNeonStroke(stroke)
    return stroke
end

local function triggerButtonSparkles(button)
    local absolutePos = button.AbsolutePosition
    local absoluteSize = button.AbsoluteSize
    local center = absolutePos + (absoluteSize / 2)

    local screenGui = button:FindFirstAncestorWhichIsA("ScreenGui")
    if not screenGui then return end

    local sparkleHolder = Instance.new("Folder", screenGui)
    sparkleHolder.Name = "SparkleEffect"

    for i = 1, 10 do
        local angle = math.rad(math.random(0, 360))
        local distance = math.random(10, 45)
        local targetPos = center + Vector2.new(math.cos(angle) * distance, math.sin(angle) * distance)

        local dot = Instance.new("Frame", sparkleHolder)
        dot.Size = UDim2.new(0, math.random(4, 7), 0, math.random(4, 7))
        dot.Position = UDim2.new(0, center.X, 0, center.Y)
        dot.BackgroundColor3 = Color3.fromRGB(220, 245, 255)
        dot.BackgroundTransparency = 0
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local stroke = Instance.new("UIStroke", dot)
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 1.2

        TweenService:Create(dot, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, targetPos.X, 0, targetPos.Y),
            Size = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1
        }):Play()

        TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play()
    end

    task.delay(0.55, function()
        sparkleHolder:Destroy()
    end)
end

-- Add visual polish and smooth hover animations to any button
local function applyVisualHover(btn)
    local origSize = btn.Size
    local hoverSize = UDim2.new(origSize.X.Scale, origSize.X.Offset + 4, origSize.Y.Scale, origSize.Y.Offset + 2)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = hoverSize}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = origSize}):Play()
    end)
end

local function toggleFlight()
    flying = not flying
    if flying then
        Humanoid.PlatformStand = true
        if HRP then
            local bv = Instance.new("BodyVelocity", HRP)
            bv.Name = "FlyVelocity"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)

            local bg = Instance.new("BodyGyro", HRP)
            bg.Name = "FlyGyro"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.CFrame = HRP.CFrame

            pcall(function()
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            end)

            task.spawn(function()
                while flying and character and HRP and Humanoid and Humanoid.Health > 0 do
                    local cam = Workspace.CurrentCamera
                    local moveDir = Vector3.new()
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                    bv.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * flySpeed or Vector3.new(0, 0.05, 0)
                    bg.CFrame = cam.CFrame
                    RunService.RenderStepped:Wait()
                end
            end)
        end
    else
        Humanoid.PlatformStand = false
        pcall(function()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        end)
        if HRP then
            if HRP:FindFirstChild("FlyVelocity") then HRP.FlyVelocity:Destroy() end
            if HRP:FindFirstChild("FlyGyro") then HRP.FlyGyro:Destroy() end
        end
    end
end

local function createGUI()
    if CoreGui:FindFirstChild("AucuseCreamyIcyHub") then CoreGui.AucuseCreamyIcyHub:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AucuseCreamyIcyHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui

    local TooltipFrame = Instance.new("Frame", ScreenGui)
    TooltipFrame.Name = "GlobalTooltip"
    TooltipFrame.Size = UDim2.new(0, 180, 0, 32)
    TooltipFrame.BackgroundTransparency = 0.15
    TooltipFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    TooltipFrame.Visible = false
    TooltipFrame.ZIndex = 100
    Instance.new("UICorner", TooltipFrame).CornerRadius = UDim.new(0, 6)
    addNeonStroke(TooltipFrame, 1.2)

    local TooltipText = Instance.new("TextLabel", TooltipFrame)
    TooltipText.Size = UDim2.new(1, 0, 1, 0)
    TooltipText.BackgroundTransparency = 1
    TooltipText.Font = Enum.Font.GothamMedium
    TooltipText.TextSize = 10
    TooltipText.TextColor3 = Color3.fromRGB(220, 235, 255)
    TooltipText.TextWrapped = true

    local function attachTooltip(buttonObj, descriptionText)
        buttonObj.MouseEnter:Connect(function()
            TooltipText.Text = descriptionText
            TooltipFrame.Visible = true
        end)
        buttonObj.MouseMoved:Connect(function()
            local mouseLoc = UserInputService:GetMouseLocation()
            TooltipFrame.Position = UDim2.new(0, mouseLoc.X + 12, 0, mouseLoc.Y - 35)
        end)
        buttonObj.MouseLeave:Connect(function()
            TooltipFrame.Visible = false
        end)
    end

    local SnowContainer = Instance.new("Folder", ScreenGui)
    SnowContainer.Name = "SnowContainer"
    
    task.spawn(function()
        while ScreenGui.Parent do
            local flake = Instance.new("Frame", SnowContainer)
            flake.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))
            flake.Position = UDim2.new(math.random(), 0, -0.05, 0)
            flake.BackgroundColor3 = Color3.fromRGB(215, 230, 250)
            flake.BackgroundTransparency = math.random(30, 60) / 100
            flake.BorderSizePixel = 0
            Instance.new("UICorner", flake).CornerRadius = UDim.new(1, 0)

            local fallDuration = math.random(7, 13)
            local drift = math.random(-60, 60)
            
            TweenService:Create(flake, TweenInfo.new(fallDuration, Enum.EasingStyle.Linear), {
                Position = UDim2.new(flake.Position.X.Scale, drift, 1.05, 0),
                BackgroundTransparency = 1
            }):Play()

            task.delay(fallDuration, function()
                if flake then flake:Destroy() end
            end)
            task.wait(0.35)
        end
    end)

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0, 680, 0, 480)
    MainFrame.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true

    -- Opening visual animation
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 680, 0, 480)}):Play()

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
    addNeonStroke(MainFrame, 2.8)

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size = UDim2.new(1, 0, 0, 48)
    TopBar.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", TopBar)
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Position = UDim2.new(0, 18, 0, 0)
    TitleLabel.Size = UDim2.new(0, 250, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "❄️ aucuse's creamy icy hub"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabelUI = TitleLabel

    local Sidebar = Instance.new("ScrollingFrame", MainFrame)
    Sidebar.Position = UDim2.new(0, 14, 0, 54)
    Sidebar.Size = UDim2.new(0, 150, 1, -112)
    Sidebar.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    Sidebar.BorderSizePixel = 0
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.ScrollBarThickness = 2
    Sidebar.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
    addNeonStroke(Sidebar, 1.8)

    local ActiveStatusLabel = Instance.new("TextLabel", MainFrame)
    ActiveStatusLabel.Position = UDim2.new(0, 14, 1, -52)
    ActiveStatusLabel.Size = UDim2.new(0, 150, 0, 36)
    ActiveStatusLabel.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    ActiveStatusLabel.BackgroundTransparency = 0.2
    ActiveStatusLabel.Font = Enum.Font.GothamBold
    ActiveStatusLabel.TextSize = 10
    ActiveStatusLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
    Instance.new("UICorner", ActiveStatusLabel).CornerRadius = UDim.new(0, 8)
    addNeonStroke(ActiveStatusLabel, 1.5)
    activeStatusLabelUI = ActiveStatusLabel

    local function updateStatus()
        local count = 0
        if flying then count = count + 1 end
        if walkSpeedEnabled then count = count + 1 end
        if flySpeedEnabled then count = count + 1 end
        if tpEnabled then count = count + 1 end
        if espEnabled then count = count + 1 end
        if mobEspEnabled then count = count + 1 end
        if noclipEnabled then count = count + 1 end
        if noFogEnabled then count = count + 1 end
        if infJumpEnabled then count = count + 1 end
        if noFallEnabled then count = count + 1 end
        if noStunEnabled then count = count + 1 end
        if hitboxExtenderEnabled then count = count + 1 end
        if backAttachEnabled then count = count + 1 end
        if flingPlayerEnabled then count = count + 1 end
        if spectatingTarget then count = count + 1 end

        if count > 0 then
            ActiveStatusLabel.Text = count .. " ACTIVE FEATURES"
        else
            ActiveStatusLabel.Text = "0 ACTIVE FEATURES"
        end
    end
    updateActiveStatusHeader = updateStatus
    updateStatus()

    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local sideLayout = Instance.new("UIListLayout", Sidebar)
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Padding = UDim.new(0, 6)
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContainerHolder = Instance.new("Frame", MainFrame)
    ContainerHolder.Position = UDim2.new(0, 174, 0, 54)
    ContainerHolder.Size = UDim2.new(1, -188, 1, -66)
    ContainerHolder.BackgroundTransparency = 1

    local tabs = {}
    local function createTabContent(name)
        local sf = Instance.new("ScrollingFrame", ContainerHolder)
        sf.Name = name .. "Tab"
        sf.Size = UDim2.new(1, 0, 1, 0)
        sf.BackgroundTransparency = 1
        sf.Visible = false
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.ScrollBarThickness = 3
        sf.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)

        local layout = Instance.new("UIListLayout", sf)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabs[name] = sf
        return sf
    end

    local movementTab = createTabContent("Movement")
    local visualsTab = createTabContent("Visuals")
    local teleportTab = createTabContent("Teleport")
    local combatTab = createTabContent("Combat")
    local worldTab = createTabContent("World")
    local miscTab = createTabContent("Misc")

    local function switchTab(tabName)
        for name, sf in pairs(tabs) do
            sf.Visible = (name == tabName)
        end
    end
    switchTab("Movement")

    local function createTabButton(name, order)
        local btn = Instance.new("TextButton", Sidebar)
        btn.LayoutOrder = order
        btn.Size = UDim2.new(1, -12, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
        btn.TextColor3 = Color3.fromRGB(180, 205, 235)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Text = name
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        addNeonStroke(btn, 1.8)
        applyVisualHover(btn)

        attachTooltip(btn, "Switches panel view to " .. name .. " configurations.")

        btn.MouseButton1Click:Connect(function()
            triggerButtonSparkles(btn)
            switchTab(name)
        end)
    end

    createTabButton("Movement", 1)
    createTabButton("Visuals", 2)
    createTabButton("Teleport", 3)
    createTabButton("Combat", 4)
    createTabButton("World", 5)
    createTabButton("Misc", 6)
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 6 * 44)

    local function createToggleButton(parentTab, title, tooltipText, initialState, callback)
        local btn = Instance.new("TextButton", parentTab)
        btn.Size = UDim2.new(1, -10, 0, 48)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.TextWrapped = true
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        addNeonStroke(btn, 2.0)
        applyVisualHover(btn)

        attachTooltip(btn, tooltipText)

        local active = initialState
        local function updateVisuals()
            if active then
                btn.BackgroundColor3 = Color3.fromRGB(35, 55, 75)
                btn.TextColor3 = Color3.fromRGB(200, 240, 255)
                btn.Text = title .. ": ON"
            else
                btn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
                btn.TextColor3 = Color3.fromRGB(140, 160, 185)
                btn.Text = title .. ": OFF"
            end
        end
        updateVisuals()

        btn.MouseButton1Click:Connect(function()
            triggerButtonSparkles(btn)
            active = not active
            updateVisuals()
            callback(active)
            updateStatus()
            saveConfig()
        end)
        parentTab.CanvasSize = UDim2.new(0, 0, 0, parentTab.UIListLayout.AbsoluteContentSize.Y + 12)
        return btn
    end

    local function createSlider(parentTab, title, tooltipText, min, max, current, callback)
        local frame = Instance.new("Frame", parentTab)
        frame.Size = UDim2.new(1, -10, 0, 56)
        frame.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        addNeonStroke(frame, 2.0)

        attachTooltip(frame, tooltipText)

        local label = Instance.new("TextLabel", frame)
        label.Position = UDim2.new(0, 14, 0, 6)
        label.Size = UDim2.new(1, -28, 0, 20)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextColor3 = Color3.fromRGB(180, 205, 235)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = title .. ": " .. current

        local sliderBg = Instance.new("Frame", frame)
        sliderBg.Position = UDim2.new(0, 14, 0, 34)
        sliderBg.Size = UDim2.new(1, -28, 0, 12)
        sliderBg.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
        sliderBg.BorderSizePixel = 0
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 6)

        local sliderFill = Instance.new("Frame", sliderBg)
        sliderFill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(120, 190, 255)
        sliderFill.BorderSizePixel = 0
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 6)

        local draggingSlider = false
        local function updateValue(input)
            local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + ((max - min) * pos))
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = title .. ": " .. val
            callback(val)
            saveConfig()
        end

        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = true
                updateValue(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateValue(input)
            end
        end)

        parentTab.CanvasSize = UDim2.new(0, 0, 0, parentTab.UIListLayout.AbsoluteContentSize.Y + 12)
    end

    local function createKeybindButton(parentTab, title, tooltipText, currentKey, callback)
        local btn = Instance.new("TextButton", parentTab)
        btn.Size = UDim2.new(1, -10, 0, 48)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
        btn.TextColor3 = Color3.fromRGB(180, 205, 235)
        btn.BorderSizePixel = 0
        btn.Text = title .. ": [" .. currentKey.Name .. "]"
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        addNeonStroke(btn, 2.0)
        applyVisualHover(btn)

        attachTooltip(btn, tooltipText)

        local listening = false
        btn.MouseButton1Click:Connect(function()
            triggerButtonSparkles(btn)
            listening = true
            btn.Text = title .. ": [ PRESS ANY KEY ]"
            btn.TextColor3 = Color3.fromRGB(240, 180, 80)
        end)

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                callback(input.KeyCode)
                btn.Text = title .. ": [" .. input.KeyCode.Name .. "]"
                btn.TextColor3 = Color3.fromRGB(180, 205, 235)
                saveConfig()
            end
        end)

        parentTab.CanvasSize = UDim2.new(0, 0, 0, parentTab.UIListLayout.AbsoluteContentSize.Y + 12)
    end

    -- --- MOVEMENT TAB ---
    createToggleButton(movementTab, "FLY", "Enables free flight mode across the 3D map space.", flying, function(state)
        flying = state
        if not flying and character and HRP then
            Humanoid.PlatformStand = false
            if HRP:FindFirstChild("FlyVelocity") then HRP.FlyVelocity:Destroy() end
            if HRP:FindFirstChild("FlyGyro") then HRP.FlyGyro:Destroy() end
        elseif flying then
            toggleFlight()
            flying = true
        end
    end)

    createSlider(movementTab, "Fly Speed", "Adjusts movement velocity while flying.", 16, MAX_SPEED, flySpeed, function(val)
        flySpeed = val
    end)

    createKeybindButton(movementTab, "Fly Keybind", "Changes keyboard shortcut to trigger flight.", flightKey, function(newKey)
        flightKey = newKey
    end)

    createToggleButton(movementTab, "WALK SPEED", "Toggles custom character walk speed multiplier.", walkSpeedEnabled, function(state)
        walkSpeedEnabled = state
        if Humanoid then Humanoid.WalkSpeed = walkSpeedEnabled and speed or 16 end
    end)

    createSlider(movementTab, "Walk Speed", "Sets custom movement walking velocity.", 16, 200, speed, function(val)
        speed = val
        if walkSpeedEnabled and Humanoid then Humanoid.WalkSpeed = speed end
    end)

    createKeybindButton(movementTab, "WalkSpeed Keybind", "Changes keyboard shortcut to toggle walkspeed.", walkSpeedKey, function(newKey)
        walkSpeedKey = newKey
    end)

    createToggleButton(movementTab, "INF JUMP", "Allows continuous jumping infinitely mid-air.", infJumpEnabled, function(state)
        infJumpEnabled = state
    end)

    createToggleButton(movementTab, "NOCLIP", "Bypasses collision detection allowing you to walk through walls.", noclipEnabled, function(state)
        noclipEnabled = state
    end)

    createToggleButton(movementTab, "NO FALL DAMAGE", "Instantly resets health drops to protect against landing impacts.", noFallEnabled, function(state)
        noFallEnabled = state
    end)

    -- --- VISUALS TAB ---
    createToggleButton(visualsTab, "ESP", "Renders player outlines, health metrics, and markers through walls.", espEnabled, function(state)
        espEnabled = state
    end)

    createSlider(visualsTab, "ESP Max Distance", "Maximum render distance for player ESP overlays.", 100, 5000, maxEspDistance, function(val)
        maxEspDistance = val
    end)

    createToggleButton(visualsTab, "ESP Name", "Toggles player username display tags.", espName, function(state)
        espName = state
    end)

    createToggleButton(visualsTab, "ESP Health Bar", "Toggles health bar meters above players.", espHealthBar, function(state)
        espHealthBar = state
    end)

    createToggleButton(visualsTab, "ESP HP Number", "Toggles exact numerical health values.", espHpNumber, function(state)
        espHpNumber = state
    end)

    createToggleButton(visualsTab, "ESP Distance", "Toggles distance indicators in studs.", espDistance, function(state)
        espDistance = state
    end)

    createToggleButton(visualsTab, "ESP Equipped Item", "Toggles functional text showing what tool/weapon players are holding, matching the glowing theme.", espEquipped, function(state)
        espEquipped = state
    end)

    createToggleButton(visualsTab, "ESP Box", "Toggles 2D bounding boxes around players.", espBox, function(state)
        espBox = state
    end)

    createToggleButton(visualsTab, "ESP Head Dot", "Toggles precision tracking dots over player heads.", espHeadDot, function(state)
        espHeadDot = state
    end)

    createToggleButton(visualsTab, "ESP Charms", "Applies glowing matching color charms/chams highlight effects onto players.", espCharms, function(state)
        espCharms = state
    end)

    createToggleButton(visualsTab, "MOB ESP", "Highlights environmental NPCs and active monsters.", mobEspEnabled, function(state)
        mobEspEnabled = state
    end)

    createToggleButton(visualsTab, "NO FOG", "Clears environmental fog and lighting distance haze.", noFogEnabled, function(state)
        noFogEnabled = state
        if not noFogEnabled then Lighting.FogEnd = 100000 end
    end)

    -- --- TELEPORT TAB ---
    createToggleButton(teleportTab, "CLICK TP", "Enables instant teleporting by holding LeftShift and clicking anywhere.", tpEnabled, function(state)
        tpEnabled = state
    end)

    local TpPlayerBtn = Instance.new("TextButton", teleportTab)
    TpPlayerBtn.Size = UDim2.new(1, -10, 0, 48)
    TpPlayerBtn.Font = Enum.Font.GothamBold
    TpPlayerBtn.TextSize = 12
    TpPlayerBtn.Text = "TP TO PLAYER ▾"
    TpPlayerBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
    TpPlayerBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
    TpPlayerBtn.BorderSizePixel = 0
    Instance.new("UICorner", TpPlayerBtn).CornerRadius = UDim.new(0, 8)
    addNeonStroke(TpPlayerBtn, 2.0)
    applyVisualHover(TpPlayerBtn)
    attachTooltip(TpPlayerBtn, "Opens a selection menu to instantly teleport to any player.")

    local SpectateBtn = Instance.new("TextButton", teleportTab)
    SpectateBtn.Size = UDim2.new(1, -10, 0, 48)
    SpectateBtn.Font = Enum.Font.GothamBold
    SpectateBtn.TextSize = 12
    SpectateBtn.Text = "SPECTATE ▾"
    SpectateBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
    SpectateBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
    SpectateBtn.BorderSizePixel = 0
    Instance.new("UICorner", SpectateBtn).CornerRadius = UDim.new(0, 8)
    addNeonStroke(SpectateBtn, 2.0)
    applyVisualHover(SpectateBtn)
    attachTooltip(SpectateBtn, "Opens a menu to spectate and follow other players' cameras.")

    local DropdownFrame = Instance.new("ScrollingFrame", ScreenGui)
    DropdownFrame.Name = "PlayerDropdown"
    DropdownFrame.Size = UDim2.new(0, 200, 0, 140)
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.Visible = false
    DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    DropdownFrame.ScrollBarThickness = 3
    DropdownFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)
    Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 8)
    addNeonStroke(DropdownFrame, 1.8)
    local dropLayout = Instance.new("UIListLayout", DropdownFrame)
    dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dropLayout.Padding = UDim.new(0, 4)

    local SpectateDropdownFrame = Instance.new("ScrollingFrame", ScreenGui)
    SpectateDropdownFrame.Name = "SpectateDropdown"
    SpectateDropdownFrame.Size = UDim2.new(0, 200, 0, 140)
    SpectateDropdownFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    SpectateDropdownFrame.BorderSizePixel = 0
    SpectateDropdownFrame.Visible = false
    SpectateDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    SpectateDropdownFrame.ScrollBarThickness = 3
    SpectateDropdownFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)
    Instance.new("UICorner", SpectateDropdownFrame).CornerRadius = UDim.new(0, 8)
    addNeonStroke(SpectateDropdownFrame, 1.8)
    local specLayout = Instance.new("UIListLayout", SpectateDropdownFrame)
    specLayout.SortOrder = Enum.SortOrder.LayoutOrder
    specLayout.Padding = UDim.new(0, 4)

    local function refreshPlayerList()
        for _, child in ipairs(DropdownFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                count = count + 1
                local pBtn = Instance.new("TextButton", DropdownFrame)
                pBtn.Size = UDim2.new(1, -8, 0, 30)
                pBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
                pBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
                pBtn.Font = Enum.Font.GothamMedium
                pBtn.TextSize = 11
                pBtn.Text = p.Name
                pBtn.BorderSizePixel = 0
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
                addNeonStroke(pBtn, 1.5)

                pBtn.MouseButton1Click:Connect(function()
                    triggerButtonSparkles(pBtn)
                    teleportToPlayer(p)
                    DropdownFrame.Visible = false
                end)
            end
        end
        DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, count * 34)
    end

    local function refreshSpectateList()
        for _, child in ipairs(SpectateDropdownFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local count = 0

        if spectatingTarget then
            count = count + 1
            local stopBtn = Instance.new("TextButton", SpectateDropdownFrame)
            stopBtn.Size = UDim2.new(1, -8, 0, 30)
            stopBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
            stopBtn.TextColor3 = Color3.fromRGB(240, 150, 150)
            stopBtn.Font = Enum.Font.GothamBold
            stopBtn.TextSize = 11
            stopBtn.Text = "[ STOP SPECTATING ]"
            stopBtn.BorderSizePixel = 0
            Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)
            addNeonStroke(stopBtn, 1.5)

            stopBtn.MouseButton1Click:Connect(function()
                triggerButtonSparkles(stopBtn)
                spectatingTarget = nil
                camera.CameraType = Enum.CameraType.Custom
                camera.CameraSubject = Humanoid
                SpectateDropdownFrame.Visible = false
                SpectateBtn.Text = "SPECTATE ▾"
                updateStatus()
            end)
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                count = count + 1
                local pBtn = Instance.new("TextButton", SpectateDropdownFrame)
                pBtn.Size = UDim2.new(1, -8, 0, 30)
                pBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
                pBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
                pBtn.Font = Enum.Font.GothamMedium
                pBtn.TextSize = 11
                pBtn.Text = p.Name
                pBtn.BorderSizePixel = 0
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
                addNeonStroke(pBtn, 1.5)

                pBtn.MouseButton1Click:Connect(function()
                    triggerButtonSparkles(pBtn)
                    spectatingTarget = p
                    SpectateDropdownFrame.Visible = false
                    SpectateBtn.Text = "SPEC: " .. p.Name
                    updateStatus()
                end)
            end
        end
        SpectateDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, count * 34)
    end

    TpPlayerBtn.MouseButton1Click:Connect(function()
        triggerButtonSparkles(TpPlayerBtn)
        SpectateDropdownFrame.Visible = false
        DropdownFrame.Visible = not DropdownFrame.Visible
        if DropdownFrame.Visible then
            refreshPlayerList()
            local absPos = TpPlayerBtn.AbsolutePosition
            DropdownFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 48)
        end
    end)

    SpectateBtn.MouseButton1Click:Connect(function()
        triggerButtonSparkles(SpectateBtn)
        DropdownFrame.Visible = false
        SpectateDropdownFrame.Visible = not SpectateDropdownFrame.Visible
        if SpectateDropdownFrame.Visible then
            refreshSpectateList()
            local absPos = SpectateBtn.AbsolutePosition
            SpectateDropdownFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 48)
        end
    end)

    -- --- COMBAT TAB ---
    createToggleButton(combatTab, "NO STUN", "Prevents character staggering, freezing, and stun lock states.", noStunEnabled, function(state)
        noStunEnabled = state
    end)

    createToggleButton(combatTab, "HITBOX EXTENDER", "Expands enemy player target hitboxes for effortless accuracy.", hitboxExtenderEnabled, function(state)
        hitboxExtenderEnabled = state
        if not hitboxExtenderEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        tRoot.Size = Vector3.new(2, 2, 1)
                        tRoot.Transparency = 1
                    end
                end
            end
        end
    end)

    createSlider(combatTab, "Hitbox Size", "Adjusts the target scale size for extended hitboxes.", 2, 25, hitboxSize, function(val)
        hitboxSize = val
    end)

    createKeybindButton(combatTab, "Hitbox Keybind", "Changes keyboard shortcut to toggle hitbox extender.", hitboxKey, function(newKey)
        hitboxKey = newKey
    end)

    createToggleButton(combatTab, "BACK ATTACH", "Instantly attaches and locks your position directly behind the selected player target.", backAttachEnabled, function(state)
        backAttachEnabled = state
    end)

    local BackAttachTargetBtn = Instance.new("TextButton", combatTab)
    BackAttachTargetBtn.Size = UDim2.new(1, -10, 0, 48)
    BackAttachTargetBtn.Font = Enum.Font.GothamBold
    BackAttachTargetBtn.TextSize = 12
    BackAttachTargetBtn.Text = selectedBackAttachTarget and ("ATTACH TARGET: " .. selectedBackAttachTarget.Name) or "SELECT ATTACH TARGET ▾"
    BackAttachTargetBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
    BackAttachTargetBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
    BackAttachTargetBtn.BorderSizePixel = 0
    Instance.new("UICorner", BackAttachTargetBtn).CornerRadius = UDim.new(0, 8)
    addNeonStroke(BackAttachTargetBtn, 2.0)
    applyVisualHover(BackAttachTargetBtn)
    attachTooltip(BackAttachTargetBtn, "Selects a player target for the back attach function.")

    local BackAttachDropdown = Instance.new("ScrollingFrame", ScreenGui)
    BackAttachDropdown.Name = "BackAttachDropdown"
    BackAttachDropdown.Size = UDim2.new(0, 200, 0, 140)
    BackAttachDropdown.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    BackAttachDropdown.BorderSizePixel = 0
    BackAttachDropdown.Visible = false
    BackAttachDropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
    BackAttachDropdown.ScrollBarThickness = 3
    BackAttachDropdown.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)
    Instance.new("UICorner", BackAttachDropdown).CornerRadius = UDim.new(0, 8)
    addNeonStroke(BackAttachDropdown, 1.8)
    local baListLayout = Instance.new("UIListLayout", BackAttachDropdown)
    baListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    baListLayout.Padding = UDim.new(0, 4)

    local function refreshBackAttachList()
        for _, child in ipairs(BackAttachDropdown:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                count = count + 1
                local pBtn = Instance.new("TextButton", BackAttachDropdown)
                pBtn.Size = UDim2.new(1, -8, 0, 30)
                pBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
                pBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
                pBtn.Font = Enum.Font.GothamMedium
                pBtn.TextSize = 11
                pBtn.Text = p.Name
                pBtn.BorderSizePixel = 0
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
                addNeonStroke(pBtn, 1.5)

                pBtn.MouseButton1Click:Connect(function()
                    triggerButtonSparkles(pBtn)
                    selectedBackAttachTarget = p
                    BackAttachTargetBtn.Text = "ATTACH TARGET: " .. p.Name
                    BackAttachDropdown.Visible = false
                end)
            end
        end
        BackAttachDropdown.CanvasSize = UDim2.new(0, 0, 0, count * 34)
    end

    BackAttachTargetBtn.MouseButton1Click:Connect(function()
        triggerButtonSparkles(BackAttachTargetBtn)
        BackAttachDropdown.Visible = not BackAttachDropdown.Visible
        if BackAttachDropdown.Visible then
            refreshBackAttachList()
            local absPos = BackAttachTargetBtn.AbsolutePosition
            BackAttachDropdown.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 48)
        end
    end)

    createKeybindButton(combatTab, "Back Attach Keybind", "Changes keyboard shortcut to toggle back attach.", backAttachKey, function(newKey)
        backAttachKey = newKey
    end)

    createToggleButton(combatTab, "FLING PLAYER", "Enables high velocity physics spinning to fling a chosen player.", flingPlayerEnabled, function(state)
        flingPlayerEnabled = state
    end)

    local FlingTargetBtn = Instance.new("TextButton", combatTab)
    FlingTargetBtn.Size = UDim2.new(1, -10, 0, 48)
    FlingTargetBtn.Font = Enum.Font.GothamBold
    FlingTargetBtn.TextSize = 12
    FlingTargetBtn.Text = selectedFlingTarget and ("FLING TARGET: " .. selectedFlingTarget.Name) or "SELECT FLING TARGET ▾"
    FlingTargetBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
    FlingTargetBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
    FlingTargetBtn.BorderSizePixel = 0
    Instance.new("UICorner", FlingTargetBtn).CornerRadius = UDim.new(0, 8)
    addNeonStroke(FlingTargetBtn, 2.0)
    applyVisualHover(FlingTargetBtn)
    attachTooltip(FlingTargetBtn, "Selects a specific player target to fling.")

    local FlingDropdown = Instance.new("ScrollingFrame", ScreenGui)
    FlingDropdown.Name = "FlingDropdown"
    FlingDropdown.Size = UDim2.new(0, 200, 0, 140)
    FlingDropdown.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    FlingDropdown.BorderSizePixel = 0
    FlingDropdown.Visible = false
    FlingDropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
    FlingDropdown.ScrollBarThickness = 3
    FlingDropdown.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)
    Instance.new("UICorner", FlingDropdown).CornerRadius = UDim.new(0, 8)
    addNeonStroke(FlingDropdown, 1.8)
    local fListLayout = Instance.new("UIListLayout", FlingDropdown)
    fListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    fListLayout.Padding = UDim.new(0, 4)

    local function refreshFlingList()
        for _, child in ipairs(FlingDropdown:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                count = count + 1
                local pBtn = Instance.new("TextButton", FlingDropdown)
                pBtn.Size = UDim2.new(1, -8, 0, 30)
                pBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
                pBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
                pBtn.Font = Enum.Font.GothamMedium
                pBtn.TextSize = 11
                pBtn.Text = p.Name
                pBtn.BorderSizePixel = 0
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
                addNeonStroke(pBtn, 1.5)

                pBtn.MouseButton1Click:Connect(function()
                    triggerButtonSparkles(pBtn)
                    selectedFlingTarget = p
                    FlingTargetBtn.Text = "FLING TARGET: " .. p.Name
                    FlingDropdown.Visible = false
                end)
            end
        end
        FlingDropdown.CanvasSize = UDim2.new(0, 0, 0, count * 34)
    end

    FlingTargetBtn.MouseButton1Click:Connect(function()
        triggerButtonSparkles(FlingTargetBtn)
        FlingDropdown.Visible = not FlingDropdown.Visible
        if FlingDropdown.Visible then
            refreshFlingList()
            local absPos = FlingTargetBtn.AbsolutePosition
            FlingDropdown.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 48)
        end
    end)

    -- --- WORLD TAB ---
    local function applyLightingPreset(preset)
        currentLightingPreset = preset
        if preset == "Midnight" then
            Lighting.ClockTime = 0
            Lighting.Brightness = 0.5
            Lighting.OutdoorAmbient = Color3.fromRGB(20, 30, 50)
        elseif preset == "Cyberpunk Neon" then
            Lighting.ClockTime = 22
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(50, 20, 70)
        elseif preset == "Sunny Clear" then
            Lighting.ClockTime = 14
            Lighting.Brightness = 2.5
            Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
        elseif preset == "Normal" then
            Lighting.ClockTime = 12
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end
    end

    local lightingPresetBtn = Instance.new("TextButton", worldTab)
    lightingPresetBtn.Size = UDim2.new(1, -10, 0, 48)
    lightingPresetBtn.Font = Enum.Font.GothamBold
    lightingPresetBtn.TextSize = 12
    lightingPresetBtn.Text = "LIGHTING: " .. currentLightingPreset .. " ▾"
    lightingPresetBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
    lightingPresetBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
    lightingPresetBtn.BorderSizePixel = 0
    Instance.new("UICorner", lightingPresetBtn).CornerRadius = UDim.new(0, 8)
    addNeonStroke(lightingPresetBtn, 2.0)
    applyVisualHover(lightingPresetBtn)
    attachTooltip(lightingPresetBtn, "Cycles or opens world atmosphere presets.")

    local LightingDropdown = Instance.new("ScrollingFrame", ScreenGui)
    LightingDropdown.Name = "LightingDropdown"
    LightingDropdown.Size = UDim2.new(0, 200, 0, 120)
    LightingDropdown.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    LightingDropdown.BorderSizePixel = 0
    LightingDropdown.Visible = false
    LightingDropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
    LightingDropdown.ScrollBarThickness = 3
    LightingDropdown.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)
    Instance.new("UICorner", LightingDropdown).CornerRadius = UDim.new(0, 8)
    addNeonStroke(LightingDropdown, 1.8)
    local lLayout = Instance.new("UIListLayout", LightingDropdown)
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lLayout.Padding = UDim.new(0, 4)

    local presets = {"Normal", "Midnight", "Cyberpunk Neon", "Sunny Clear"}
    for idx, name in ipairs(presets) do
        local pBtn = Instance.new("TextButton", LightingDropdown)
        pBtn.Size = UDim2.new(1, -8, 0, 30)
        pBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
        pBtn.TextColor3 = Color3.fromRGB(180, 205, 235)
        pBtn.Font = Enum.Font.GothamMedium
        pBtn.TextSize = 11
        pBtn.Text = name
        pBtn.BorderSizePixel = 0
        Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
        addNeonStroke(pBtn, 1.5)

        pBtn.MouseButton1Click:Connect(function()
            triggerButtonSparkles(pBtn)
            applyLightingPreset(name)
            lightingPresetBtn.Text = "LIGHTING: " .. name .. " ▾"
            LightingDropdown.Visible = false
        end)
    end
    LightingDropdown.CanvasSize = UDim2.new(0, 0, 0, #presets * 34)

    lightingPresetBtn.MouseButton1Click:Connect(function()
        triggerButtonSparkles(lightingPresetBtn)
        LightingDropdown.Visible = not LightingDropdown.Visible
        if LightingDropdown.Visible then
            local absPos = lightingPresetBtn.AbsolutePosition
            LightingDropdown.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 48)
        end
    end)

    -- Brightness and FOV Sliders
    createSlider(worldTab, "Brightness", "Adjusts world lighting brightness intensity.", 0, 10, Lighting.Brightness, function(val)
        Lighting.Brightness = val
    end)

    createSlider(worldTab, "FOV", "Adjusts camera field of view scale.", 50, 120, math.floor(camera.FieldOfView), function(val)
        camera.FieldOfView = val
    end)

    -- Waypoint Management UI Container
    local waypointInputContainer = Instance.new("Frame", worldTab)
    waypointInputContainer.Size = UDim2.new(1, -10, 0, 52)
    waypointInputContainer.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
    waypointInputContainer.BorderSizePixel = 0
    Instance.new("UICorner", waypointInputContainer).CornerRadius = UDim.new(0, 8)
    addNeonStroke(waypointInputContainer, 2.0)

    local WaypointNameBox = Instance.new("TextBox", waypointInputContainer)
    WaypointNameBox.Position = UDim2.new(0, 10, 0, 8)
    WaypointNameBox.Size = UDim2.new(0.55, -12, 0, 36)
    WaypointNameBox.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
    WaypointNameBox.TextColor3 = Color3.fromRGB(220, 235, 255)
    WaypointNameBox.Font = Enum.Font.GothamMedium
    WaypointNameBox.TextSize = 11
    WaypointNameBox.PlaceholderText = "Enter Waypoint Name..."
    WaypointNameBox.Text = ""
    WaypointNameBox.BorderSizePixel = 0
    Instance.new("UICorner", WaypointNameBox).CornerRadius = UDim.new(0, 6)

    local SetWaypointBtn = Instance.new("TextButton", waypointInputContainer)
    SetWaypointBtn.Position = UDim2.new(0.57, 0, 0, 8)
    SetWaypointBtn.Size = UDim2.new(0.43, -10, 0, 36)
    SetWaypointBtn.BackgroundColor3 = Color3.fromRGB(35, 55, 75)
    SetWaypointBtn.TextColor3 = Color3.fromRGB(200, 240, 255)
    SetWaypointBtn.Font = Enum.Font.GothamBold
    SetWaypointBtn.TextSize = 11
    SetWaypointBtn.Text = "+ SET WAYPOINT"
    SetWaypointBtn.BorderSizePixel = 0
    Instance.new("UICorner", SetWaypointBtn).CornerRadius = UDim.new(0, 6)
    applyVisualHover(SetWaypointBtn)

    local WaypointScrollContainer = Instance.new("ScrollingFrame", worldTab)
    WaypointScrollContainer.Name = "WaypointScrollContainer"
    WaypointScrollContainer.Size = UDim2.new(1, -10, 0, 150)
    WaypointScrollContainer.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    WaypointScrollContainer.BorderSizePixel = 0
    WaypointScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    WaypointScrollContainer.ScrollBarThickness = 3
    WaypointScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 170, 220)
    Instance.new("UICorner", WaypointScrollContainer).CornerRadius = UDim.new(0, 8)
    addNeonStroke(WaypointScrollContainer, 1.8)

    local wpListLayout = Instance.new("UIListLayout", WaypointScrollContainer)
    wpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    wpListLayout.Padding = UDim.new(0, 4)
    wpListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function refreshWaypointList()
        for _, child in ipairs(WaypointScrollContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for index, wpData in ipairs(savedWaypoints) do
            local wpRow = Instance.new("Frame", WaypointScrollContainer)
            wpRow.Size = UDim2.new(1, -8, 0, 32)
            wpRow.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
            wpRow.BorderSizePixel = 0
            Instance.new("UICorner", wpRow).CornerRadius = UDim.new(0, 6)

            local lbl = Instance.new("TextLabel", wpRow)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.Size = UDim2.new(0.55, -8, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextColor3 = Color3.fromRGB(180, 205, 235)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = wpData.Name

            local tpWpBtn = Instance.new("TextButton", wpRow)
            tpWpBtn.Position = UDim2.new(0.57, 0, 0, 4)
            tpWpBtn.Size = UDim2.new(0.24, 0, 1, -8)
            tpWpBtn.BackgroundColor3 = Color3.fromRGB(35, 55, 75)
            tpWpBtn.TextColor3 = Color3.fromRGB(200, 240, 255)
            tpWpBtn.Font = Enum.Font.GothamBold
            tpWpBtn.TextSize = 10
            tpWpBtn.Text = "TP"
            tpWpBtn.BorderSizePixel = 0
            Instance.new("UICorner", tpWpBtn).CornerRadius = UDim.new(0, 4)

            tpWpBtn.MouseButton1Click:Connect(function()
                triggerButtonSparkles(tpWpBtn)
                if HRP then HRP.CFrame = wpData.CFrame end
            end)

            local delWpBtn = Instance.new("TextButton", wpRow)
            delWpBtn.Position = UDim2.new(0.83, 0, 0, 4)
            delWpBtn.Size = UDim2.new(0.15, 0, 1, -8)
            delWpBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
            delWpBtn.TextColor3 = Color3.fromRGB(240, 150, 150)
            delWpBtn.Font = Enum.Font.GothamBold
            delWpBtn.TextSize = 10
            delWpBtn.Text = "X"
            delWpBtn.BorderSizePixel = 0
            Instance.new("UICorner", delWpBtn).CornerRadius = UDim.new(0, 4)

            delWpBtn.MouseButton1Click:Connect(function()
                triggerButtonSparkles(delWpBtn)
                table.remove(savedWaypoints, index)
                refreshWaypointList()
            end)
        end
        WaypointScrollContainer.CanvasSize = UDim2.new(0, 0, 0, #savedWaypoints * 36)
    end

    SetWaypointBtn.MouseButton1Click:Connect(function()
        triggerButtonSparkles(SetWaypointBtn)
        if HRP then
            local nameVal = WaypointNameBox.Text
            if nameVal == "" then nameVal = "Waypoint " .. (#savedWaypoints + 1) end
            table.insert(savedWaypoints, {Name = nameVal, CFrame = HRP.CFrame})
            WaypointNameBox.Text = ""
            refreshWaypointList()
        end
    end)

    -- --- MISC TAB ---
    createKeybindButton(miscTab, "Toggle GUI Key", "Changes keyboard shortcut to open/close the GUI menu.", toggleGuiKey, function(newKey)
        toggleGuiKey = newKey
    end)

    local RejoinBtn = Instance.new("TextButton", miscTab)
    RejoinBtn.Size = UDim2.new(1, -10, 0, 48)
    RejoinBtn.Font = Enum.Font.GothamBold
    RejoinBtn.TextSize = 12
    RejoinBtn.Text = "REJOIN SERVER"
    RejoinBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
    RejoinBtn.TextColor3 = Color3.fromRGB(240, 150, 150)
    RejoinBtn.BorderSizePixel = 0
    Instance.new("UICorner", RejoinBtn).CornerRadius = UDim.new(0, 8)
    addNeonStroke(RejoinBtn, 2.0)
    applyVisualHover(RejoinBtn)
    attachTooltip(RejoinBtn, "Instantly reconnects and rejoins the current server session.")

    RejoinBtn.MouseButton1Click:Connect(function()
        triggerButtonSparkles(RejoinBtn)
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
    end)

    for _, tab in pairs(tabs) do
        tab.CanvasSize = UDim2.new(0, 0, 0, tab.UIListLayout.AbsoluteContentSize.Y + 12)
    end
end

createGUI()

player.CharacterAdded:Connect(function(char)
    character = char
    HRP = character:WaitForChild("HumanoidRootPart")
    Humanoid = character:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = walkSpeedEnabled and speed or 16
    if flying then flying = false end
    if spectatingTarget then
        spectatingTarget = nil
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = Humanoid
    end
    createGUI()
end)

-- No Stun hook handler
Humanoid.StateChanged:Connect(function(_, newState)
    if noStunEnabled then
        if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.PlatformStanding then
            if not flying then
                Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                Humanoid.PlatformStand = false
            end
        end
    end
end)

-- No Fall Damage hook handler
Humanoid.StateChanged:Connect(function(_, newState)
    if noFallEnabled and newState == Enum.HumanoidStateType.Land then
        pcall(function()
            if Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
        end)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == flightKey then
        toggleFlight()
    end

    if input.KeyCode == walkSpeedKey then
        walkSpeedEnabled = not walkSpeedEnabled
        if Humanoid then Humanoid.WalkSpeed = walkSpeedEnabled and speed or 16 end
        if updateActiveStatusHeader then updateActiveStatusHeader() end
        saveConfig()
    end

    if input.KeyCode == hitboxKey then
        hitboxExtenderEnabled = not hitboxExtenderEnabled
        if not hitboxExtenderEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        tRoot.Size = Vector3.new(2, 2, 1)
                        tRoot.Transparency = 1
                    end
                end
            end
        end
        if updateActiveStatusHeader then updateActiveStatusHeader() end
        saveConfig()
    end

    if input.KeyCode == backAttachKey then
        backAttachEnabled = not backAttachEnabled
        if updateActiveStatusHeader then updateActiveStatusHeader() end
        saveConfig()
    end

    if input.KeyCode == toggleGuiKey then
        local gui = CoreGui:FindFirstChild("AucuseCreamyIcyHub")
        if gui then
            gui.Enabled = not gui.Enabled
        end
    end

    if infJumpEnabled and input.KeyCode == Enum.KeyCode.Space then
        if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end

    if tpEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            if mouse.Hit and HRP then HRP.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
        end
    end
end)