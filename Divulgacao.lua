-- SKYHUB | DARKHOLD COMMUNITY
-- BETA 1.0

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local discord = "https://discord.gg/WHrRsDUHQ"

local gui = Instance.new("ScreenGui")
gui.Name = "SkyhubCommunity"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(310, 260)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18, 10, 15)
main.Parent = gui

Instance.new("UICorner", main).CornerRadius =
    UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(160, 35, 50)
stroke.Thickness = 2
stroke.Parent = main

local function label(text, y, h, size, color)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, h)
    t.Position = UDim2.new(0, 10, 0, y)
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = color
    t.Font = Enum.Font.GothamBold
    t.TextSize = size
    t.TextWrapped = true
    t.Parent = main
    return t
end

label("✦ SKYHUB ✦", 18, 38, 28,
    Color3.fromRGB(235, 55, 70))

label("DARKHOLD EDITION", 55, 20, 12,
    Color3.fromRGB(180, 110, 115))

label("DESBLOQUEIE O PODER", 91, 30, 17,
    Color3.fromRGB(255, 230, 230))

label(
    "Entre no Discord oficial para obter o script completo e acompanhar atualizações!",
    126, 55, 13,
    Color3.fromRGB(205, 185, 190)
)

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -36, 0, 42)
button.Position = UDim2.new(0, 18, 0, 195)
button.BackgroundColor3 = Color3.fromRGB(130, 25, 40)
button.Text = "COPIAR LINK DO DISCORD"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 13
button.Font = Enum.Font.GothamBold
button.Parent = main

Instance.new("UICorner", button).CornerRadius =
    UDim.new(0, 8)

button.MouseButton1Click:Connect(function()
    if typeof(setclipboard) == "function" then
        setclipboard(discord)
        button.Text = "LINK COPIADO!"
    else
        button.Text = "discord.gg/WHrRsDUHQ"
    end
end)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -33, 0, 5)
close.BackgroundTransparency = 1
close.Text = "×"
close.TextColor3 = Color3.fromRGB(255, 100, 110)
close.TextSize = 24
close.Parent = main

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

main.Size = UDim2.fromOffset(0, 0)

TweenService:Create(
    main,
    TweenInfo.new(0.45, Enum.EasingStyle.Back),
    {Size = UDim2.fromOffset(310, 260)}
):Play()
