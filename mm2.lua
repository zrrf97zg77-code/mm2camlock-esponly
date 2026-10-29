
--// AIM ASSIST GUI — ROBLOX STUDIO
--// Put this LocalScript in StarterPlayer > StarterPlayerScripts.
--// For use in your own experience.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("AimAssistGUI")
if old then old:Destroy() end

local settings = {
    Enabled = false,
    ShowFOV = true,
    FOV = 120,
    X = 0,
    Y = 0,
    Smoothness = 0.20,
}

local gui = Instance.new("ScreenGui")
gui.Name = "AimAssistGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(220, 290)
panel.Position = UDim2.new(0, 16, 0.5, -145)
panel.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
panel.BorderSizePixel = 0
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(65, 115, 190)
outline.Transparency = 0.25
outline.Parent = panel

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 10)
pad.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 7)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = panel

local function corner(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = instance
end

local function label(text, order, height, bold)
    local l = Instance.new("TextLabel")
    l.LayoutOrder = order
    l.Size = UDim2.new(1, 0, 0, height)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(240, 242, 250)
    l.TextSize = bold and 14 or 11
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = panel
    return l
end

label("AIM ASSIST", 1, 23, true)

local function button(text, order, callback)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = Color3.fromRGB(43, 48, 62)
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.TextSize = 11
    b.Font = Enum.Font.GothamMedium
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = panel
    corner(b, 6)
    b.Activated:Connect(function()
        callback(b)
    end)
    return b
end

button("Aim Assist: OFF", 2, function(b)
    settings.Enabled = not settings.Enabled
    b.Text = settings.Enabled and "Aim Assist: ON" or "Aim Assist: OFF"
    b.BackgroundColor3 = settings.Enabled
        and Color3.fromRGB(38, 125, 82)
        or Color3.fromRGB(43, 48, 62)
end)

button("FOV Circle: ON", 3, function(b)
    settings.ShowFOV = not settings.ShowFOV
    b.Text = settings.ShowFOV and "FOV Circle: ON" or "FOV Circle: OFF"
end)

local activeSlider = nil
local sliderConnections = {}

local function makeSlider(title, order, min, max, initial, key, decimals)
    local holder = Instance.new("Frame")
    holder.LayoutOrder = order
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundTransparency = 1
    holder.Parent = panel

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, 0, 0, 17)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(220, 225, 238)
    valueLabel.TextSize = 10
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Parent = holder

    local track = Instance.new("Frame")
    track.Position = UDim2.fromOffset(0, 23)
    track.Size = UDim2.new(1, 0, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(52, 57, 72)
    track.BorderSizePixel = 0
    track.Active = true
    track.Parent = holder
    corner(track, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 145, 240)
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 4)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((initial - min) / (max - min), 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(12, 12)
    knob.BackgroundColor3 = Color3.fromRGB(245, 247, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 6)

    local function refresh(value)
        local alpha = math.clamp((value - min) / (max - min), 0, 1)
        settings[key] = value
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)

        local format = decimals == 0 and "%.0f" or "%." .. decimals .. "f"
        valueLabel.Text = title .. ": " .. string.format(format, value)
    end

    local function setFromX(x)
        if not gui.Enabled or not panel.Visible then return end
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local alpha = math.clamp(
            (x - track.AbsolutePosition.X) / width, 0, 1
        )
        refresh(min + (max - min) * alpha)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = track
            setFromX(input.Position.X)
        end
    end)

    sliderConnections[track] = setFromX
    refresh(initial)
end

makeSlider("FOV Radius", 4, 40, 300, settings.FOV, "FOV", 0)
makeSlider("Horizontal Offset (X)", 5, -100, 100, settings.X, "X", 0)
makeSlider("Vertical Offset (Y)", 6, -100, 100, settings.Y, "Y", 0)
makeSlider("Smoothness", 7, 0.05, 1, settings.Smoothness, "Smoothness", 2)

UIS.InputChanged:Connect(function(input)
    if not activeSlider then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local update = sliderConnections[activeSlider]
        if update then update(input.Position.X) end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        activeSlider = nil
    end
end)

local hide = button("Hide Panel", 8, function()
    panel.Visible = false
end)

local reopen = Instance.new("TextButton")
reopen.Size = UDim2.fromOffset(90, 30)
reopen.Position = UDim2.new(0, 16, 0.5, -15)
reopen.BackgroundColor3 = Color3.fromRGB(30, 35, 47)
reopen.TextColor3 = Color3.new(1, 1, 1)
reopen.Text = "OPEN AIM GUI"
reopen.TextSize = 11
reopen.Font = Enum.Font.GothamBold
reopen.Visible = false
reopen.Parent = gui
corner(reopen, 6)

hide.Activated:Connect(function()
    panel.Visible = false
    reopen.Visible = true
    activeSlider = nil
end)

reopen.Activated:Connect(function()
    panel.Visible = true
    reopen.Visible = false
end)

local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Size = UDim2.fromOffset(settings.FOV * 2, settings.FOV * 2)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Parent = gui
circle.ZIndex = 1
corner(circle, settings.FOV)

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = Color3.fromRGB(80, 145, 240)
circleStroke.Thickness = 1.5
circleStroke.Parent = circle

-- Selects the closest visible character inside the FOV.
-- X and Y are independent screen-space offsets.
local function findTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local center = camera.ViewportSize / 2
    local closest, closestDistance = nil, settings.FOV

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local character = other.Character
            local head = character and character:FindFirstChild("Head")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if head and humanoid and humanoid.Health > 0 then
                local point, onScreen = camera:WorldToViewportPoint(head.Position)

                if onScreen and point.Z > 0 then
                    local distance = (
                        Vector2.new(point.X, point.Y) - center
                    ).Magnitude

                    if distance <= closestDistance then
                        closest = other
                        closestDistance = distance
                    end
                end
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    circle.Position = UDim2.fromOffset(
        camera.ViewportSize.X / 2,
        camera.ViewportSize.Y / 2
    )
    circle.Size = UDim2.fromOffset(settings.FOV * 2, settings.FOV * 2)
    circle.Visible = settings.ShowFOV

    local target = settings.Enabled and findTarget() or nil
    circleStroke.Color = target
        and Color3.fromRGB(80, 220, 130)
        or Color3.fromRGB(80, 145, 240)

    -- This script intentionally does not force the camera onto other players.
    -- Use the selected target and offsets in your own game's approved aim
    -- mechanic or training range.
end)
