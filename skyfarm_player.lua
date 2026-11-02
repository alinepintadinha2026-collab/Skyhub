
-- SKY FARM v1.0 | JOGADOR
-- Sem limite de tempo
-- Interface limitada a tela

local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local requestFn = request or http_request or
    (syn and syn.request)

assert(requestFn, "Executor sem suporte HTTP")

local DB = "https://sky-farm-b52b0-default-rtdb.firebaseio.com"
local API = "AIzaSyD8Qx6aJSJ-RUkuD1bHGVwFoxupAiL258M"
local SPAWN = Vector3.new(258.15, 654.15, 942.46)

local env = getgenv and getgenv() or _G

if env.SkyFarmPlayer and env.SkyFarmPlayer.stop then
    env.SkyFarmPlayer.stop()
end

local running = true
local enabled = false
local token, refreshToken, uid
local target = nil
local lastSuccess = 0
local lastTeleport = 0

local function requestJSON(method, url, data)
    local opts = {
        Url = url,
        Method = method,
        Headers = {
            ["Content-Type"] = "application/json"
        }
    }

    if data ~= nil then
        opts.Body = Http:JSONEncode(data)
    end

    local ok, response = pcall(requestFn, opts)

    if not ok or type(response) ~= "table" then
        return nil, nil
    end

    local decoded
    pcall(function()
        decoded = Http:JSONDecode(response.Body or "")
    end)

    return tonumber(
        response.StatusCode or response.Status
    ), decoded
end

local function login()
    local code, data = requestJSON(
        "POST",
        "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" ..
            API,
        {returnSecureToken = true}
    )

    if code == 200 and data and data.idToken then
        token = data.idToken
        refreshToken = data.refreshToken
        uid = data.localId
        return true
    end

    return false
end

local function refresh()
    if not refreshToken then return login() end

    local ok, response = pcall(requestFn, {
        Url = "https://securetoken.googleapis.com/v1/token?key=" ..
            API,
        Method = "POST",
        Headers = {
            ["Content-Type"] =
                "application/x-www-form-urlencoded"
        },
        Body = "grant_type=refresh_token&refresh_token=" ..
            Http:UrlEncode(refreshToken)
    })

    if ok and response then
        local data

        pcall(function()
            data = Http:JSONDecode(response.Body or "")
        end)

        if data and data.id_token then
            token = data.id_token
            refreshToken = data.refresh_token or refreshToken
            return true
        end
    end

    return login()
end

local function db(method, path, data)
    if not token then return nil, nil end

    local function send()
        return requestJSON(
            method,
            DB .. path .. ".json?auth=" ..
                Http:UrlEncode(token),
            data
        )
    end

    local code, result = send()

    if code == 401 and refresh() then
        code, result = send()
    end

    return code, result
end

-- INTERFACE

local oldGui = player:WaitForChild("PlayerGui"):
    FindFirstChild("SkyFarmPlayer")

if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SkyFarmPlayer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player.PlayerGui

local function make(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", obj, {
        CornerRadius = UDim.new(0, radius)
    })
end

local panel = make("Frame", gui, {
    Size = UDim2.fromOffset(280, 180),
    Position = UDim2.new(.5, -140, .5, -90),
    BackgroundColor3 = Color3.fromRGB(25, 19, 39),
    BorderSizePixel = 0,
    Active = true
})
round(panel, 12)

local title = make("TextLabel", panel, {
    Position = UDim2.fromOffset(10, 4),
    Size = UDim2.new(1, -48, 0, 34),
    BackgroundTransparency = 1,
    Text = "SKY FARM | JOGADOR",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = true
})

local status = make("TextLabel", panel, {
    Position = UDim2.fromOffset(10, 42),
    Size = UDim2.new(1, -20, 0, 34),
    BackgroundTransparency = 1,
    Text = "Conectando...",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    TextWrapped = true
})

local toggle = make("TextButton", panel, {
    Position = UDim2.fromOffset(10, 82),
    Size = UDim2.new(1, -20, 0, 40),
    BackgroundColor3 = Color3.fromRGB(98, 51, 174),
    BorderSizePixel = 0,
    Text = "ATIVAR FARM",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold
})
round(toggle, 8)

make("TextLabel", panel, {
    Position = UDim2.fromOffset(10, 131),
    Size = UDim2.new(1, -20, 0, 34),
    BackgroundTransparency = 1,
    Text = "Retorno automatico apos renascer",
    TextColor3 = Color3.fromRGB(200, 195, 215),
    TextSize = 11
})

local mini = make("TextButton", panel, {
    Position = UDim2.new(1, -34, 0, 7),
    Size = UDim2.fromOffset(27, 27),
    BackgroundColor3 = Color3.fromRGB(80, 45, 125),
    TextColor3 = Color3.new(1, 1, 1),
    Text = "-"
})
round(mini, 6)

local bubble = make("TextButton", gui, {
    Position = UDim2.fromOffset(12, 120),
    Size = UDim2.fromOffset(43, 43),
    BackgroundColor3 = Color3.fromRGB(98, 51, 174),
    TextColor3 = Color3.new(1, 1, 1),
    Text = "SF",
    Visible = false,
    Active = true
})
round(bubble, 22)

mini.MouseButton1Click:Connect(function()
    panel.Visible = false
    bubble.Visible = true
end)

bubble.MouseButton1Click:Connect(function()
    bubble.Visible = false
    panel.Visible = true
end)

-- ZONA SEGURA

local function safePosition(frame, x, y)
    local screen = gui.AbsoluteSize
    local size = frame.AbsoluteSize

    return UDim2.fromOffset(
        math.clamp(x, 0, math.max(0, screen.X - size.X)),
        math.clamp(y, 0, math.max(0, screen.Y - size.Y))
    )
end

local function keepVisible(frame)
    local pos = frame.AbsolutePosition -
        gui.AbsolutePosition

    frame.Position = safePosition(
        frame, pos.X, pos.Y
    )
end

local function drag(frame, handle)
    local moving = false
    local start, origin, tracked

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~=
                Enum.UserInputType.MouseButton1 then
            return
        end

        moving = true
        tracked = input
        start = input.Position
        origin = frame.AbsolutePosition -
            gui.AbsolutePosition

        input.Changed:Connect(function()
            if input.UserInputState ==
                Enum.UserInputState.End then
                moving = false
            end
        end)
    end)

    UIS.InputChanged:Connect(function(input)
        if not moving then return end

        if input ~= tracked and
            input.UserInputType ~=
                Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - start

        frame.Position = safePosition(
            frame,
            origin.X + delta.X,
            origin.Y + delta.Y
        )
    end)
end

drag(panel, title)
drag(bubble, bubble)

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(
    function()
        keepVisible(panel)
        keepVisible(bubble)
    end
)

task.defer(function()
    keepVisible(panel)
    keepVisible(bubble)
end)

-- PARTICIPANTES

local function presence()
    if not uid then return end

    if enabled then
        db("PUT", "/farm/participants/" .. uid, {
            active = true,
            name = player.Name,
            userId = player.UserId,
            jobId = game.JobId,
            placeId = game.PlaceId,
            lastSeen = {
                [".sv"] = "timestamp"
            },
            updatedAt = {
                [".sv"] = "timestamp"
            }
        })
    else
        db("DELETE", "/farm/participants/" .. uid)
    end
end

local function setEnabled(value)
    enabled = value
    target = nil

    toggle.Text = value and
        "DESATIVAR FARM" or "ATIVAR FARM"

    status.Text = value and
        "Aguardando moderador..." or
        "Farm desativada"

    task.spawn(presence)
end

toggle.MouseButton1Click:Connect(function()
    setEnabled(not enabled)
end)

-- CONSULTA DA FARM
-- Sem expiracao por tempo

local function check()
    if not enabled then return end

    local code, command = db(
        "GET", "/farm/commands"
    )

    if code ~= 200 then
        target = nil
        status.Text = "Conexao indisponivel"
        return
    end

    lastSuccess = os.clock()

    if type(command) ~= "table"
        or command.active ~= true
        or command.action ~= "start"
        or command.jobId ~= game.JobId
        or tonumber(command.placeId) ~= game.PlaceId
        or type(command.sessionId) ~= "string" then

        target = nil
        status.Text = "Aguardando moderador..."
        return
    end

    target = SPAWN
    status.Text = "Farm ativa | retorno automatico"
end

-- TELEPORTE CONTINUO

local function teleport()
    if not enabled or not target then return end

    if os.clock() - lastSuccess > 10 then
        return
    end

    if os.clock() - lastTeleport < 2 then
        return
    end

    local char = player.Character
    local hum = char and
        char:FindFirstChildOfClass("Humanoid")
    local root = char and
        char:FindFirstChild("HumanoidRootPart")

    if not hum or hum.Health <= 0 or not root then
        return
    end

    if (root.Position - target).Magnitude > 12 then
        lastTeleport = os.clock()

        char:PivotTo(
            CFrame.new(
                target + Vector3.new(0, 3, 0)
            )
        )
    end
end

local charConn = player.CharacterAdded:Connect(function()
    lastTeleport = 0
    task.wait(1)

    if running and enabled and target then
        teleport()
    end
end)

env.SkyFarmPlayer = {
    stop = function()
        running = false
        enabled = false
        target = nil

        pcall(presence)

        charConn:Disconnect()
        gui:Destroy()
    end
}

task.spawn(function()
    while running and not token do
        if login() then
            status.Text = "Pronto para ativar"
        else
            status.Text = "Tentando conectar..."
            task.wait(8)
        end
    end

    local heartbeat = 0

    while running do
        if enabled then
            check()

            if os.clock() - heartbeat >= 60 then
                heartbeat = os.clock()
                presence()
            end
        end

        task.wait(3)
    end
end)

task.spawn(function()
    while running do
        teleport()
        task.wait(.35)
    end
end)

print("SKY FARM v1.0 | Jogador carregado")
