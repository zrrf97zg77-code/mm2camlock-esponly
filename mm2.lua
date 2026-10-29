-- Player Camlock | For your own Roblox experience
-- Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Settings = {
    Enabled = false,
    WallCheck = true,
    ShowFOV = true,
    FOV = 150,
    XOffset = 0,
    YOffset = 0,
    Smoothness = 0.18,
}

local Target = nil
local ActiveSlider = nil
local Dragging = false
local DragStart, FrameStart

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local Gui = make("ScreenGui", {
    Name = "PlayerCamlock",
    ResetOnSpawn = false,
    DisplayOrder = 20,
}, PlayerGui)

local Panel = make("Frame", {
    Name = "Panel",
    Size = UDim2.fromOffset(224, 340),
    Position = UDim2.new(0, 24, 0.35, 0),
    BackgroundColor3 = Color3.fromRGB(17, 20, 29),
    BorderSizePixel = 0,
}, Gui)

make("UICorner", {CornerRadius = UDim.new(0, 9)}, Panel)
make("UIStroke", {
    Color = Color3.fromRGB(55, 112, 220),
    Thickness = 1.2,
}, Panel)

local TitleBar = make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 27),
    Position = UDim2.fromOffset(8, 4),
    BackgroundTransparency = 1,
    Text = "PLAYER CAMLOCK",
    TextColor3 = Color3.fromRGB(105, 165, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = true,
}, Panel)

local Status = make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 18),
    Position = UDim2.fromOffset(8, 30),
    BackgroundTransparency = 1,
    Text = "Status: OFF",
    TextColor3 = Color3.fromRGB(190, 195, 210),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Panel)

local function createButton(text, y, callback)
    local button = make("TextButton", {
        Size = UDim2.new(1, -16, 0, 25),
        Position = UDim2.fromOffset(8, y),
        BackgroundColor3 = Color3.fromRGB(31, 39, 55),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.fromRGB(235, 239, 250),
        TextSize = 11,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = true,
    }, Panel)

    make("UICorner", {CornerRadius = UDim.new(0, 5)}, button)
    button.Activated:Connect(callback)
    return button
end

local function updateStatus()
    Status.Text = Settings.Enabled and
        ("Status: ON" .. (Target and (" | " .. Target.Name) or " | Searching"))
        or "Status: OFF"
end

local LockButton = createButton("Camlock: OFF", 53, function()
    Settings.Enabled = not Settings.Enabled
    if not Settings.Enabled then
        Target = nil
    end
    LockButton.Text = "Camlock: " .. (Settings.Enabled and "ON" or "OFF")
    updateStatus()
end)

local WallButton = createButton("Wallcheck: ON", 82, function()
    Settings.WallCheck = not Settings.WallCheck
    WallButton.Text = "Wallcheck: " .. (Settings.WallCheck and "ON" or "OFF")
end)

local FOVButton = createButton("FOV Circle: ON", 111, function()
    Settings.ShowFOV = not Settings.ShowFOV
    FOVButton.Text = "FOV Circle: " .. (Settings.ShowFOV and "ON" or "OFF")
end)

make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 17),
    Position = UDim2.fromOffset(8, 141),
    BackgroundTransparency = 1,
    Text = "CAMERA SETTINGS",
    TextColor3 = Color3.fromRGB(105, 165, 255),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Panel)

local Sliders = {}

local function createSlider(name, y, minValue, maxValue, initial, callback)
    local holder = make("Frame", {
        Size = UDim2.new(1, -16, 0, 35),
        Position = UDim2.fromOffset(8, y),
        BackgroundTransparency = 1,
    }, Panel)

    local label = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 15),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(220, 225, 240),
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = name,
    }, holder)

    local track = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 7),
        Position = UDim2.fromOffset(0, 22),
        BackgroundColor3 = Color3.fromRGB(48, 55, 72),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, holder)

    make("UICorner", {CornerRadius = UDim.new(1, 0)}, track)

    local fill = make("Frame", {
        Size = UDim2.new((initial - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(75, 137, 255),
        BorderSizePixel = 0,
    }, track)

    make("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

    local function setFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local alpha = math.clamp(
            (x - track.AbsolutePosition.X) / width, 0, 1
        )
        local value = minValue + alpha * (maxValue - minValue)
        value = math.floor(value * 100 + 0.5) / 100
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        label.Text = name .. ": " .. tostring(value)
        callback(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            ActiveSlider = setFromX
            setFromX(input.Position.X)
        end
    end)

    table.insert(Sliders, {
        Update = setFromX,
        Track = track,
    })

    label.Text = name .. ": " .. tostring(initial)
end

createSlider("FOV Radius", 160, 40, 400, Settings.FOV, function(v)
    Settings.FOV = v
end)

createSlider("X Offset", 198, -200, 200, Settings.XOffset, function(v)
    Settings.XOffset = v
end)

createSlider("Y Offset", 236, -200, 200, Settings.YOffset, function(v)
    Settings.YOffset = v
end)

createSlider("Smoothing", 274, 0.03, 1, Settings.Smoothness, function(v)
    Settings.Smoothness = v
end)

local HideButton = createButton("Hide Menu", 311, function()
    Panel.Visible = false
    ActiveSlider = nil
    ReopenButton.Visible = true
end)

ReopenButton = make("TextButton", {
    Name = "Reopen",
    Size = UDim2.fromOffset(100, 32),
    Position = UDim2.new(0, 20, 0, 100),
    BackgroundColor3 = Color3.fromRGB(25, 32, 48),
    BorderSizePixel = 0,
    Text = "Open Camlock",
    TextColor3 = Color3.fromRGB(105, 165, 255),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    Visible = false,
}, Gui)

make("UICorner", {CornerRadius = UDim.new(0, 7)}, ReopenButton)

ReopenButton.Activated:Connect(function()
    Panel.Visible = true
    ReopenButton.Visible = false
end)

-- Drag the menu using its title.
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        FrameStart = Panel.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if Dragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - DragStart
            Panel.Position = UDim2.new(
                FrameStart.X.Scale,
                FrameStart.X.Offset + delta.X,
                FrameStart.Y.Scale,
                FrameStart.Y.Offset + delta.Y
            )
        end
    end

    if ActiveSlider and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        ActiveSlider(input.Position.X)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
        ActiveSlider = nil
    end
end)

-- FOV circle
local Circle = make("Frame", {
    Name = "FOVCircle",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, Gui)

make("UICorner", {CornerRadius = UDim.new(1, 0)}, Circle)

make("UIStroke", {
    Color = Color3.fromRGB(85, 150, 255),
    Thickness = 1.5,
    Transparency = 0.1,
}, Circle)

local function getCharacterParts(player)
    local character = player.Character
    if not character then
        return nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")

    if not humanoid or humanoid.Health <= 0 or not head then
        return nil, nil
    end

    return character, head
end

local function canSeeTarget(camera, character, head)
    if not Settings.WallCheck then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true

    local origin = camera.CFrame.Position
    local direction = head.Position - origin
    local result = workspace:Raycast(origin, direction, params)

    return result == nil or result.Instance:IsDescendantOf(character)
end

local function getScreenPoint(camera, head)
    local point, onScreen = camera:WorldToViewportPoint(head.Position)
    if not onScreen or point.Z <= 0 then
        return nil
    end
    return Vector2.new(point.X, point.Y)
end

local function targetIsValid(camera, player)
    if not player or player == LocalPlayer then
        return false
    end

    local character, head = getCharacterParts(player)
    if not character then
        return false
    end

    local point = getScreenPoint(camera, head)
    if not point then
        return false
    end

    local center = camera.ViewportSize / 2
    if (point - center).Magnitude > Settings.FOV then
        return false
    end

    return canSeeTarget(camera, character, head)
end

local function findTarget(camera)
    local center = camera.ViewportSize / 2
    local bestPlayer = nil
    local bestDistance = Settings.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character, head = getCharacterParts(player)

            if character and head then
                local point = getScreenPoint(camera, head)

                if point and canSeeTarget(camera, character, head) then
                    local distance = (point - center).Magnitude

                    if distance <= bestDistance then
                        bestDistance = distance
                        bestPlayer = player
                    end
                end
            end
        end
    end

    return bestPlayer
end

-- Run after Roblox's default camera update.
RunService:BindToRenderStep(
    "PlayerCamlockUpdate",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        Circle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
        Circle.Visible = Settings.ShowFOV

        if not Settings.Enabled then
            Target = nil
            updateStatus()
            return
        end

        if not targetIsValid(camera, Target) then
            Target = findTarget(camera)
        end

        updateStatus()

        if not Target then
            return
        end

        local character, head = getCharacterParts(Target)
        if not character or not head then
            Target = nil
            return
        end

        local point = getScreenPoint(camera, head)
        if not point then
            Target = nil
            return
        end

        -- Offsets independently adjust the screen-space aim point.
        local aimX = math.clamp(
            point.X + Settings.XOffset, 0, camera.ViewportSize.X
        )
        local aimY = math.clamp(
            point.Y + Settings.YOffset, 0, camera.ViewportSize.Y
        )

        local ray = camera:ViewportPointToRay(aimX, aimY)
        local desired = CFrame.lookAt(
            camera.CFrame.Position,
            camera.CFrame.Position + ray.Direction
        )

        camera.CFrame = camera.CFrame:Lerp(
            desired,
            math.clamp(Settings.Smoothness, 0.01, 1)
        )
    end
)

Players.PlayerRemoving:Connect(function(player)
    if Target == player then
        Target = nil
    end
end)
