
-- Roblox Studio: Targeting GUI
-- Place in StarterPlayer > StarterPlayerScripts as a LocalScript.
-- Designed for testing in your own experience.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local enabled = false
local showFOV = true
local fovRadius = 120
local smoothness = 0.2
local selectedTarget = nil

local gui = Instance.new("ScreenGui")
gui.Name = "TargetingGUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(240, 255)
panel.Position = UDim2.new(0, 20, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
panel.BorderSizePixel = 0
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = panel

local function makeButton(text, order, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 30)
    button.LayoutOrder = order
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.Parent = panel
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
    button.Activated:Connect(function()
        callback(button)
    end)
    return button
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.LayoutOrder = 0
title.BackgroundTransparency = 1
title.Text = "TARGETING TEST"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = panel

local aimButton
aimButton = makeButton("Targeting: OFF", 1, function(button)
    enabled = not enabled
    selectedTarget = nil
    button.Text = enabled and "Targeting: ON" or "Targeting: OFF"
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(45, 115, 75)
        or Color3.fromRGB(55, 55, 65)
end)

local fovButton
fovButton = makeButton("FOV Circle: ON", 2, function(button)
    showFOV = not showFOV
    button.Text = showFOV and "FOV Circle: ON" or "FOV Circle: OFF"
end)

local function makeSlider(labelText, order, minValue, maxValue, initialValue, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 42)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order
    holder.Parent = panel

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local track = Instance.new("TextButton")
    track.Position = UDim2.fromOffset(0, 23)
    track.Size = UDim2.new(1, 0, 0, 12)
    track.Text = ""
    track.AutoButtonColor = false
    track.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
    track.Parent = holder
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(90, 155, 230)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local value = initialValue
    local dragging = false

    local function update(x)
        if not gui.Enabled then return end

        local left = track.AbsolutePosition.X
        local width = track.AbsoluteSize.X
        local alpha = math.clamp((x - left) / width, 0, 1)

        value = minValue + (maxValue - minValue) * alpha
        fill.Size = UDim2.new(alpha, 0, 1, 0)

        local display = math.floor(value * 100) / 100
        label.Text = labelText .. ": " .. tostring(display)
        callback(value)
    end

    local function start(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end

    track.InputBegan:Connect(start)

    UIS.InputChanged:Connect(function(input)
        if dragging and gui.Enabled then
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                update(input.Position.X)
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local initialAlpha = (initialValue - minValue) / (maxValue - minValue)
    fill.Size = UDim2.new(initialAlpha, 0, 1, 0)
    label.Text = labelText .. ": " .. tostring(initialValue)

    return function()
        return value
    end
end

local getFOV = makeSlider("FOV Radius", 3, 40, 300, fovRadius, function(value)
    fovRadius = value
end)

local getSmooth = makeSlider("Camera Smoothness", 4, 0.05, 1, smoothness, function(value)
    smoothness = value
end)

local hideButton = makeButton("Hide GUI", 5, function()
    panel.Visible = false
end)

local reopen = Instance.new("TextButton")
reopen.Size = UDim2.fromOffset(85, 30)
reopen.Position = UDim2.new(0, 20, 0.35, 0)
reopen.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
reopen.TextColor3 = Color3.new(1, 1, 1)
reopen.Text = "Open GUI"
reopen.TextSize = 12
reopen.Font = Enum.Font.Gotham
reopen.Visible = false
reopen.Parent = gui
Instance.new("UICorner", reopen).CornerRadius = UDim.new(0, 6)

hideButton.Activated:Connect(function()
    panel.Visible = false
    reopen.Visible = true
end)

reopen.Activated:Connect(function()
    panel.Visible = true
    reopen.Visible = false
end)

local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 0
circle.Parent = gui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 155, 230)
stroke.Thickness = 1.5
stroke.Parent = circle

local function getClosestPlayer()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local center = camera.ViewportSize / 2
    local bestPlayer = nil
    local bestDistance = fovRadius

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local character = other.Character
            local head = character and character:FindFirstChild("Head")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if head and humanoid and humanoid.Health > 0 then
                local point, visible = camera:WorldToViewportPoint(head.Position)
                if visible and point.Z > 0 then
                    local distance = (
                        Vector2.new(point.X, point.Y) - center
                    ).Magnitude

                    if distance < bestDistance then
                        bestDistance = distance
                        bestPlayer = other
                    end
                end
            end
        end
    end

    return bestPlayer
end

RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    circle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
    circle.Position = UDim2.fromScale(0.5, 0.5)
    circle.Visible = showFOV

    -- This GUI selects and highlights a target for testing.
    -- It does not force the camera to aim at other players.
    selectedTarget = enabled and getClosestPlayer() or nil
    stroke.Color = selectedTarget
        and Color3.fromRGB(80, 220, 120)
        or Color3.fromRGB(90, 155, 230)
end)
