--// EMOTE MENU - Emote.lua
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local emotes = {
    {"Hello", 3576686446},
    {"Stadium",3360686498},
    {"Tilt",   3360692915},
    {"Shrug",  3576968026},
    {"Salute", 3360689775},
    {"Point",  3576823880},
}

local gui = Instance.new("ScreenGui")
gui.Name = "DanzzEmote"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(280,350)
main.Position = UDim2.new(.5,-140,.5,-175)
main.BackgroundColor3 = Color3.fromRGB(25,25,30)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner",main).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-50,0,45)
title.BackgroundTransparency = 1
title.Text = "🎭  EMOTE MENU"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = main

local mini = Instance.new("TextButton")
mini.Size = UDim2.fromOffset(35,32)
mini.Position = UDim2.new(1,-43,0,7)
mini.Text = "−"
mini.TextSize = 20
mini.TextColor3 = Color3.new(1,1,1)
mini.BackgroundColor3 = Color3.fromRGB(50,50,58)
mini.Parent = main
Instance.new("UICorner",mini).CornerRadius = UDim.new(0,8)

local search = Instance.new("TextBox")
search.Size = UDim2.new(1,-20,0,38)
search.Position = UDim2.fromOffset(10,52)
search.PlaceholderText = "🔎 Search..."
search.Text = ""
search.TextColor3 = Color3.new(1,1,1)
search.BackgroundColor3 = Color3.fromRGB(42,42,50)
search.Parent = main
Instance.new("UICorner",search).CornerRadius = UDim.new(0,9)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1,-20,1,-105)
list.Position = UDim2.fromOffset(10,100)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,6)
layout.Parent = list

local current

local function play(id)
    if current then
        current:Stop()
        current:Destroy()
        current = nil
    end

    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..id

    current = animator:LoadAnimation(anim)
    current.Priority = Enum.AnimationPriority.Action
    current:Play()
end

local function refresh()
    for _,v in ipairs(list:GetChildren()) do
        if v:IsA("TextButton") then
            v:Destroy()
        end
    end

    local q = string.lower(search.Text)

    for _,e in ipairs(emotes) do
        if q == "" or string.find(string.lower(e[1]),q,1,true) then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1,-4,0,42)
            b.Text = "  🎭  "..e[1]
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.TextColor3 = Color3.new(1,1,1)
            b.Font = Enum.Font.GothamMedium
            b.TextSize = 14
            b.BackgroundColor3 = Color3.fromRGB(42,42,50)
            b.Parent = list
            Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)

            b.MouseButton1Click:Connect(function()
                play(e[2])
            end)
        end
    end

    list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8)
end

search:GetPropertyChangedSignal("Text"):Connect(refresh)
refresh()

local minimized = false

mini.MouseButton1Click:Connect(function()
    minimized = not minimized

    search.Visible = not minimized
    list.Visible = not minimized

    if minimized then
        main.Size = UDim2.fromOffset(280,55)
        mini.Text = "+"
    else
        main.Size = UDim2.fromOffset(280,350)
        mini.Text = "−"
    end
end)
