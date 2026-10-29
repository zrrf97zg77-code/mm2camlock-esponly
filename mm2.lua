
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AimGUI"
gui.ResetOnSpawn = false

local S = {
    Aim = false, Wall = true, ShowFOV = true,
    FOV = 120, X = 0, Y = 0, Smooth = 0.18
}

local purple = Color3.fromRGB(130, 100, 255)
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromOffset(270, 370)
panel.Position = UDim2.new(.5, -135, .5, -185)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "AIMLOCK SETTINGS"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextSize = 16

local circle = Instance.new("Frame", gui)
circle.AnchorPoint = Vector2.new(.5, .5)
circle.Position = UDim2.fromScale(.5, .5)
circle.Size = UDim2.fromOffset(S.FOV * 2, S.FOV * 2)
circle.BackgroundTransparency = 1
local cc = Instance.new("UICorner", circle)
cc.CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", circle)
stroke.Color = purple
stroke.Thickness = 2

local function toggle(text, y, key)
    local b = Instance.new("TextButton", panel)
    b.Position = UDim2.fromOffset(10, y)
    b.Size = UDim2.new(1, -20, 0, 32)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

    local function refresh()
        b.Text = text .. ": " .. (S[key] and "ON" or "OFF")
    end

    refresh()
    b.Activated:Connect(function()
        S[key] = not S[key]
        refresh()
        if key == "ShowFOV" then
            circle.Visible = S.ShowFOV
        end
    end)
end

toggle("Aimlock", 45, "Aim")
toggle("Wallcheck", 82, "Wall")
toggle("FOV Circle", 119, "ShowFOV")

local sliders = {}

local function slider(text, y, key, min, max, step, format)
    local t = Instance.new("TextLabel", panel)
    t.Position = UDim2.fromOffset(12, y)
    t.Size = UDim2.new(1, -24, 0, 20)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.new(1, 1, 1)
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("TextButton", panel)
    track.Position = UDim2.fromOffset(12, y + 24)
    track.Size = UDim2.new(1, -24, 0, 8)
    track.Text = ""
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 75)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = purple
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function update(x)
        local a = math.clamp(
            (x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1
        )
        local v = min + a * (max - min)
        v = min + math.floor((v - min) / step + .5) * step
        S[key] = v
        a = (v - min) / (max - min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        t.Text = text .. ": " .. format(v)
        if key == "FOV" then
            circle.Size = UDim2.fromOffset(v * 2, v * 2)
        end
    end

    update(track.AbsolutePosition.X +
        track.AbsoluteSize.X * ((S[key] - min) / (max - min)))

    track.Activated:Connect(function()
        update(UIS:GetMouseLocation().X)
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliders[track] = update
            update(input.Position.X)
        end
    end)
end

slider("FOV Radius", 160, "FOV", 40, 300, 5, tostring)
slider("X Offset", 215, "X", -200, 200, 1, tostring)
slider("Y Offset", 270, "Y", -200, 200, 1, tostring)
slider("Smoothness", 325, "Smooth", 0, 1, .01,
    function(v) return string.format("%.2f", v) end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        for _, update in pairs(sliders) do
            update(input.Position.X)
        end
    end
end)

local hide = Instance.new("TextButton", panel)
hide.Position = UDim2.new(1, -35, 0, 5)
hide.Size = UDim2.fromOffset(28, 28)
hide.Text = "X"
hide.TextColor3 = Color3.new(1, 1, 1)
hide.BackgroundColor3 = Color3.fromRGB(80, 60, 90)

local show = Instance.new("TextButton", gui)
show.Position = UDim2.fromOffset(10, 100)
show.Size = UDim2.fromOffset(90, 35)
show.Text = "SHOW GUI"
show.Visible = false

hide.Activated:Connect(function()
    panel.Visible = false
    show.Visible = true
end)

show.Activated:Connect(function()
    panel.Visible = true
    show.Visible = false
end)

-- TARGETING LOGIC

local target = nil

local function getParts(plr)
    local char = plr.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not hum or hum.Health <= 0 or not head or not root then
        return
    end

    return char, hum, head, root
end

local function visible(camera, char, head)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character, gui}

    local direction = head.Position - camera.CFrame.Position
    local result = workspace:Raycast(
        camera.CFrame.Position, direction, params
    )

    return not result or result.Instance:IsDescendantOf(char)
end

local function findTarget(camera)
    local best, bestDistance = nil, math.huge
    local center = camera.ViewportSize / 2

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local char, hum, head, root = getParts(plr)

            if char then
                local sameTeam = player.Team ~= nil
                    and plr.Team == player.Team

                if not sameTeam then
                    local distance =
                        (root.Position - camera.CFrame.Position).Magnitude

                    local point, onScreen =
                        camera:WorldToViewportPoint(head.Position)

                    local screenDistance = (
                        Vector2.new(point.X, point.Y) - center
                    ).Magnitude

                    if onScreen and point.Z > 0
                        and distance <= 250
                        and screenDistance <= S.FOV
                        and screenDistance < bestDistance then

                        if not S.Wall or visible(camera, char, head) then
                            best = plr
                            bestDistance = screenDistance
                        end
                    end
                end
            end
        end
    end

    return best
end

RunService:BindToRenderStep(
    "AimGUI_Update",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        local camera = workspace.CurrentCamera
        if not camera then return end

        circle.Position = UDim2.fromOffset(
            camera.ViewportSize.X / 2,
            camera.ViewportSize.Y / 2
        )

        if not S.Aim then
            target = nil
            return
        end

        if not target then
            target = findTarget(camera)
        end

        if not target then return end

        local char, hum, head, root = getParts(target)
        if not char then
            target = nil
            return
        end

        local point, onScreen =
            camera:WorldToViewportPoint(head.Position)

        local center = camera.ViewportSize / 2
        local screenDistance = (
            Vector2.new(point.X, point.Y) - center
        ).Magnitude

        if not onScreen or point.Z <= 0
            or screenDistance > S.FOV
            or (S.Wall and not visible(camera, char, head)) then
            target = nil
            return
        end

        local ray = camera:ViewportPointToRay(
            point.X + S.X,
            point.Y + S.Y
        )

        local desired = CFrame.lookAt(
            camera.CFrame.Position,
            camera.CFrame.Position + ray.Direction
        )

        if S.Smooth > 0 then
            camera.CFrame = camera.CFrame:Lerp(desired, S.Smooth)
        end
    end
)
