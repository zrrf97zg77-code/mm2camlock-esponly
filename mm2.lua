--// MM2 Mobile AimBot + FOV Sliders + ESP + Toggle + NPC Support
--// Works on players AND NPCs (MM2 Aim Trainer)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    ESP = true,
    Camlock = false,
    AimSmoothness = 0.25,
    FOVRadius = 120,
    ShowFOVCircle = true,
    MaxDistance = 500,
}

local COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff  = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0),
    Hero     = Color3.fromRGB(255, 170, 0),
    Accent   = Color3.fromRGB(145, 92, 255),
    Surface  = Color3.fromRGB(30, 30, 40),
}

local activeHighlights = {}

--// [ ROLE DETECTION ] --

local function GetRole(plr)
    local char = plr.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("StringValue") and (v.Name:lower():find("role") or v.Name:lower():find("team")) then
                return v.Value
            end
        end
    end
    for _, v in ipairs(plr:GetChildren()) do
        if v:IsA("StringValue") and (v.Name:lower():find("role") or v.Name:lower():find("team")) then
            return v.Value
        end
    end
    return "Innocent"
end

local function GetRoleFromModel(model)
    local plr = Players:GetPlayerFromCharacter(model)
    if plr then
        return GetRole(plr)
    end
    for _, v in ipairs(model:GetChildren()) do
        if v:IsA("StringValue") and (v.Name:lower():find("role") or v.Name:lower():find("team")) then
            return v.Value
        end
    end
    return "Murderer" -- default for NPCs
end

--// [ ESP ] --

local function UpdateESP(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if not char or not char:FindFirstChild("Humanoid") then return end

    local role = GetRole(plr)
    local color = COLORS[role] or COLORS.Innocent

    if activeHighlights[plr] then
        activeHighlights[plr]:Destroy()
    end

    local hl = Instance.new("Highlight")
    hl.Name = "MM2_ESP"
    hl.Adornee = char
    hl.FillColor = color
    hl.FillTransparency = 0.5
    hl.OutlineColor = color
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    activeHighlights[plr] = hl
end

--// [ TARGETING (Players + NPCs) ] --

local function IsValidModel(model)
    if not model or not model:IsA("Model") then return false end
    if model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    return true
end

local function GetTarget()
    local myRole = GetRole(LocalPlayer)
    if myRole == "Innocent" then return nil end

    local best, bestScore = nil, -math.huge
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    local candidates = {}
    local seen = {}

    -- Players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            table.insert(candidates, plr.Character)
            seen[plr.Character] = true
        end
    end

    -- Workspace NPCs (deep scan)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not seen[obj] and obj ~= LocalPlayer.Character then
            if not Players:GetPlayerFromCharacter(obj) and obj:FindFirstChildOfClass("Humanoid") then
                table.insert(candidates, obj)
                seen[obj] = true
            end
        end
    end

    for _, model in ipairs(candidates) do
        if IsValidModel(model) then
            local hrp = model.HumanoidRootPart
            local role = GetRoleFromModel(model)

            -- Role filter
            if myRole == "Sheriff" and role ~= "Murderer" then continue end
            if myRole == "Murderer" then
                local isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
                if role == "Murderer" and isPlayer then continue end
            end

            local dist = (hrp.Position - cam.CFrame.Position).Magnitude
            if dist > CONFIG.MaxDistance then continue end

            local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if not onScreen then continue end

            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if screenDist > CONFIG.FOVRadius then continue end

            local score = 0
            if myRole == "Sheriff" then
                score = 10000 - screenDist
            elseif myRole == "Murderer" then
                if role == "Sheriff" then
                    score = 10000 - screenDist
                else
                    score = 5000 - screenDist
                end
            end

            if score > bestScore then
                bestScore = score
                best = model
            end
        end
    end
    return best
end

--// [ GUI ] --

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Mobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- FOV Circle
local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.fromOffset(CONFIG.FOVRadius * 2, CONFIG.FOVRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = CONFIG.ShowFOVCircle
FOVCircle.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = COLORS.Accent
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.3
FOVStroke.Parent = FOVCircle

-- Main Panel
local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(260, 480)
Panel.Position = UDim2.new(0, 20, 0.25, 0)
Panel.BackgroundColor3 = Color3.fromRGB(15, 15, 21)
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
Panel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(42, 42, 55)
PanelStroke.Parent = Panel

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundTransparency = 1
Header.Parent = Panel

local HeaderAccent = Instance.new("Frame")
HeaderAccent.Size = UDim2.fromOffset(4, 22)
HeaderAccent.Position = UDim2.fromOffset(10, 11)
HeaderAccent.BackgroundColor3 = COLORS.Accent
HeaderAccent.BorderSizePixel = 0
HeaderAccent.Parent = Header

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 3)
HeaderCorner.Parent = HeaderAccent

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -50, 1, 0)
HeaderTitle.Position = UDim2.fromOffset(24, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "MM2 MOBILE"
HeaderTitle.TextColor3 = Color3.fromRGB(245, 245, 250)
HeaderTitle.TextSize = 15
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.fromOffset(30, 30)
MinimizeBtn.Position = UDim2.new(1, -38, 0, 7)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeBtn

-- Button Helper
local function MakeButton(y, text, defaultOn, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 44)
    Btn.Position = UDim2.fromOffset(10, y)
    Btn.BackgroundColor3 = defaultOn and COLORS.Accent or Color3.fromRGB(40, 40, 50)
    Btn.Text = text .. ": " .. (defaultOn and "ON" or "OFF")
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.AutoButtonColor = false
    Btn.Parent = Panel

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 8)
    C.Parent = Btn

    local state = defaultOn
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.Text = text .. ": " .. (state and "ON" or "OFF")
        Btn.BackgroundColor3 = state and COLORS.Accent or Color3.fromRGB(40, 40, 50)
        callback(state)
    end)
    return Btn
end

-- Slider Helper
local function MakeSlider(y, text, min, max, default, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -20, 0, 60)
    Holder.Position = UDim2.fromOffset(10, y)
    Holder.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
    Holder.BorderSizePixel = 0
    Holder.Parent = Panel

    local HC = Instance.new("UICorner")
    HC.CornerRadius = UDim.new(0, 8)
    HC.Parent = Holder

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -12, 0, 22)
    Label.Position = UDim2.fromOffset(6, 2)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(230, 230, 240)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -20, 0, 10)
    BarBg.Position = UDim2.new(0, 10, 0, 34)
    BarBg.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    BarBg.BorderSizePixel = 0
    BarBg.Parent = Holder

    local BBC = Instance.new("UICorner")
    BBC.CornerRadius = UDim.new(1, 0)
    BBC.Parent = BarBg

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    Fill.BackgroundColor3 = COLORS.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = BarBg

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(1, 0)
    FC.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Size = UDim2.fromOffset(20, 20)
    Knob.Position = UDim2.new((default - min)/(max - min), 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = BarBg

    local KC = Instance.new("UICorner")
    KC.CornerRadius = UDim.new(1, 0)
    KC.Parent = Knob

    local value = default
    local dragging = false

    local function Update(input)
        local rel = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        Label.Text = text .. ": " .. value
        callback(value)
    end

    BarBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Update(input)
        end
    end)

    BarBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            Update(input)
        end
    end)

    return Holder
end

local ESPBtn = MakeButton(50, "ESP", CONFIG.ESP, function(s) CONFIG.ESP = s end)
local AimBtn = MakeButton(100, "AIMBOT", CONFIG.Camlock, function(s) CONFIG.Camlock = s end)
local FOVBtn = MakeButton(150, "FOV CIRCLE", CONFIG.ShowFOVCircle, function(s)
    CONFIG.ShowFOVCircle = s
    FOVCircle.Visible = s
end)

MakeSlider(204, "FOV Radius", 30, 400, CONFIG.FOVRadius, function(v)
    CONFIG.FOVRadius = v
end)

MakeSlider(270, "Aim Smoothness", 1, 100, math.floor(CONFIG.AimSmoothness * 100), function(v)
    CONFIG.AimSmoothness = v / 100
end)

MakeSlider(336, "Max Distance", 50, 1000, CONFIG.MaxDistance, function(v)
    CONFIG.MaxDistance = v
end)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 30)
Status.Position = UDim2.fromOffset(10, 405)
Status.BackgroundTransparency = 1
Status.Text = "ESP: ON | Target: None"
Status.TextColor3 = Color3.fromRGB(150, 150, 170)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Panel

--// [ FLOATING TOGGLE BUTTON ] --

local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "GUIToggle"
FloatBtn.Size = UDim2.fromOffset(54, 54)
FloatBtn.Position = UDim2.new(0, 20, 0.5, -27)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
FloatBtn.Text = "≡"
FloatBtn.TextColor3 = COLORS.Accent
FloatBtn.TextSize = 26
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.AutoButtonColor = false
FloatBtn.Visible = false
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 16)
FloatCorner.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = COLORS.Accent
FloatStroke.Thickness = 1.5
FloatStroke.Transparency = 0.3
FloatStroke.Parent = FloatBtn

local floatDragging = false
local floatDragStart, floatStartPos
local floatMoved = false

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        floatDragging = true
        floatMoved = false
        floatDragStart = input.Position
        floatStartPos = FloatBtn.Position
    end
end)

FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        floatDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if floatDragging and (input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - floatDragStart
        if delta.Magnitude > 8 then floatMoved = true end
        FloatBtn.Position = UDim2.new(
            floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X,
            floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y
        )
    end
end)

--// [ PANEL DRAGGING ] --

local dragging = false
local dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if input.Position.X > MinimizeBtn.AbsolutePosition.X then return end
        dragging = true
        dragStart = input.Position
        startPos = Panel.Position
    end
end)

Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        Panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

--// [ OPEN / MINIMIZE ANIMATION (FIXED) ] --

local isOpen = true
local savedX = 20

local function MinimizePanel()
    if not isOpen then return end
    isOpen = false
    savedX = Panel.Position.X.Offset

    local targetX = -Panel.AbsoluteSize.X - 20

    TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = UDim2.new(0, targetX, Panel.Position.Y.Scale, Panel.Position.Y.Offset)
    }):Play()

    task.delay(0.25, function()
        Panel.Visible = false
        FloatBtn.Visible = true
        FloatBtn.Size = UDim2.fromOffset(30, 30)
        TweenService:Create(FloatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(54, 54)
        }):Play()
    end)
end

local function OpenPanel()
    if isOpen then return end
    isOpen = true
    FloatBtn.Visible = false
    Panel.Visible = true

    local yScale = Panel.Position.Y.Scale
    local yOffset = Panel.Position.Y.Offset

    Panel.Position = UDim2.new(0, savedX - 300, yScale, yOffset)

    TweenService:Create(Panel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, savedX, yScale, yOffset)
    }):Play()
end

MinimizeBtn.MouseButton1Click:Connect(MinimizePanel)

FloatBtn.MouseButton1Click:Connect(function()
    if floatMoved then return end
    OpenPanel()
end)

--// [ MAIN LOOP ] --

RunService.RenderStepped:Connect(function()
    FOVCircle.Size = UDim2.fromOffset(CONFIG.FOVRadius * 2, CONFIG.FOVRadius * 2)

    if CONFIG.ESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            UpdateESP(plr)
        end
    end

    local myRole = GetRole(LocalPlayer)
    local target = GetTarget()

    if target then
        local isNPC = Players:GetPlayerFromCharacter(target) == nil
        local tag = isNPC and "[NPC]" or "[PLAYER]"
        Status.Text = myRole .. " -> " .. target.Name .. " " .. tag
    else
        Status.Text = myRole .. " | Target: None"
    end

    if CONFIG.Camlock and target then
        local hrp = target:FindFirstChild("HumanoidRootPart")
        if hrp then
            local camera = workspace.CurrentCamera
            local targetCFrame = CFrame.new(camera.CFrame.Position, hrp.Position + Vector3.new(0, 1, 0))
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, CONFIG.AimSmoothness)
        end
    end
end)

--// [ HOOKS ] --

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        UpdateESP(plr)
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if activeHighlights[plr] then
        activeHighlights[plr]:Destroy()
        activeHighlights[plr] = nil
    end
end)

print("[MM2] Mobile AimBot + FOV + ESP + NPC Support Loaded")
