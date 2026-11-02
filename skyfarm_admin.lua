
-- SKY FARM v1.0 | MODERADOR
-- Sem limite de tempo
-- Bloqueio contra sobrescrever farm ativa
-- Interface limitada a tela

local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ADMIN_NAME = "gabsgsgsbshs"
local ADMIN_UID = "cHmWn5xPQPPzxmjVOKClzFfBdiv2"

local DB = "https://sky-farm-b52b0-default-rtdb.firebaseio.com"
local API = "AIzaSyD8Qx6aJSJ-RUkuD1bHGVwFoxupAiL258M"
local SESSION_FILE = "skyfarm_admin_session.json"

local SPAWN = {
    x = 258.15,
    y = 654.15,
    z = 942.46
}

local requestFn = request or http_request or
    (syn and syn.request)

local old = playerGui:FindFirstChild("SkyFarmAdmin")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SkyFarmAdmin"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

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
    Size = UDim2.fromOffset(310, 370),
    Position = UDim2.new(.5, -155, .5, -185),
    BackgroundColor3 = Color3.fromRGB(22, 17, 36),
    BorderSizePixel = 0,
    Active = true
})
round(panel, 12)

make("UIStroke", panel, {
    Color = Color3.fromRGB(135, 76, 218),
    Thickness = 1.5
})

local title = make("TextLabel", panel, {
    Position = UDim2.fromOffset(12, 6),
    Size = UDim2.new(1, -55, 0, 38),
    BackgroundTransparency = 1,
    Text = "SKY FARM | MODERADOR v1.0",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = true
})

local status = make("TextLabel", panel, {
    Position = UDim2.fromOffset(12, 47),
    Size = UDim2.new(1, -24, 0, 52),
    BackgroundTransparency = 1,
    Text = "Verificando acesso...",
    TextColor3 = Color3.fromRGB(220, 210, 240),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextWrapped = true
})

local function button(text, y, color)
    local obj = make("TextButton", panel, {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 42),
        BackgroundColor3 = color or
            Color3.fromRGB(107, 55, 181),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13
    })
    round(obj, 8)
    return obj
end

local mini = make("TextButton", panel, {
    Position = UDim2.new(1, -39, 0, 9),
    Size = UDim2.fromOffset(29, 29),
    BackgroundColor3 = Color3.fromRGB(78, 44, 120),
    Text = "-",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 20
})
round(mini, 7)

local bubble = make("TextButton", gui, {
    Position = UDim2.fromOffset(12, 120),
    Size = UDim2.fromOffset(45, 45),
    BackgroundColor3 = Color3.fromRGB(112, 55, 188),
    Text = "SF",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    Visible = false,
    Active = true
})
round(bubble, 23)

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

if player.Name:lower() ~= ADMIN_NAME:lower() then
    panel.Size = UDim2.fromOffset(310, 150)
    status.Text = "Você não tem acesso a este script."
    status.TextColor3 = Color3.fromRGB(255, 100, 110)
    mini.Visible = false
    task.defer(function() keepVisible(panel) end)
    return
end

if not requestFn then
    status.Text = "Executor sem suporte HTTP."
    return
end

-- FIREBASE

local idToken
local refreshToken
local authenticated = false
local busy = false

local function http(method, url, body, extraHeaders)
    local headers = {
        ["Content-Type"] = "application/json"
    }

    for k, v in pairs(extraHeaders or {}) do
        headers[k] = v
    end

    local opts = {
        Url = url,
        Method = method,
        Headers = headers
    }

    if body ~= nil then opts.Body = body end

    local ok, response = pcall(requestFn, opts)

    if not ok or type(response) ~= "table" then
        return nil, nil, {}
    end

    local decoded
    pcall(function()
        decoded = Http:JSONDecode(response.Body or "")
    end)

    return tonumber(
        response.StatusCode or response.Status
    ), decoded, response.Headers or {}
end

local function saveSession()
    if not writefile or not refreshToken then return end

    pcall(function()
        writefile(
            SESSION_FILE,
            Http:JSONEncode({
                uid = ADMIN_UID,
                refreshToken = refreshToken
            })
        )
    end)
end

local function renew()
    if not refreshToken then return false end

    local code, data = http(
        "POST",
        "https://securetoken.googleapis.com/v1/token?key=" ..
            API,
        "grant_type=refresh_token&refresh_token=" ..
            Http:UrlEncode(refreshToken),
        {
            ["Content-Type"] =
                "application/x-www-form-urlencoded"
        }
    )

    if code ~= 200 or type(data) ~= "table" or
        data.user_id ~= ADMIN_UID or
        not data.id_token then
        return false
    end

    idToken = data.id_token
    refreshToken = data.refresh_token or refreshToken
    saveSession()
    return true
end

local function login(email, password)
    local code, data = http(
        "POST",
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" ..
            API,
        Http:JSONEncode({
            email = email,
            password = password,
            returnSecureToken = true
        })
    )

    if code ~= 200 or type(data) ~= "table" or
        not data.idToken then
        return false
    end

    if data.localId ~= ADMIN_UID then
        return false
    end

    idToken = data.idToken
    refreshToken = data.refreshToken
    saveSession()
    return true
end

local function db(method, path, data, headers)
    if not idToken then return nil, nil, {} end

    local body = data ~= nil and
        Http:JSONEncode(data) or nil

    local function send()
        return http(
            method,
            DB .. path .. ".json?auth=" ..
                Http:UrlEncode(idToken),
            body,
            headers
        )
    end

    local code, result, responseHeaders = send()

    if (code == 401 or code == 403) and renew() then
        code, result, responseHeaders = send()
    end

    return code, result, responseHeaders
end

local function getETag(headers)
    for k, v in pairs(headers or {}) do
        if tostring(k):lower() == "etag" then
            return v
        end
    end
end

local function farmActive(command)
    return type(command) == "table"
        and command.active == true
        and command.action == "start"
end

-- LOGIN

local emailInput = make("TextBox", panel, {
    Position = UDim2.fromOffset(12, 110),
    Size = UDim2.new(1, -24, 0, 39),
    BackgroundColor3 = Color3.fromRGB(42, 34, 62),
    Text = "",
    PlaceholderText = "Email Firebase",
    TextColor3 = Color3.new(1, 1, 1),
    ClearTextOnFocus = false,
    TextSize = 13
})
round(emailInput, 7)

local passwordInput = make("TextBox", panel, {
    Position = UDim2.fromOffset(12, 158),
    Size = UDim2.new(1, -24, 0, 39),
    BackgroundColor3 = Color3.fromRGB(42, 34, 62),
    Text = "",
    PlaceholderText = "Senha Firebase",
    TextColor3 = Color3.new(1, 1, 1),
    ClearTextOnFocus = false,
    TextSize = 13
})
round(passwordInput, 7)

local loginButton = button("ENTRAR E SALVAR LOGIN", 208)

local startButton = button(
    "INICIAR FARM", 110,
    Color3.fromRGB(65, 145, 100)
)

local stopButton = button(
    "ENCERRAR FARM", 163,
    Color3.fromRGB(170, 65, 85)
)

local participantsButton = button(
    "VER PARTICIPANTES", 216
)

local output = make("TextLabel", panel, {
    Position = UDim2.fromOffset(12, 270),
    Size = UDim2.new(1, -24, 0, 85),
    BackgroundTransparency = 1,
    Text = "Farm sem limite de tempo\n" ..
        "Spawn: 258.15, 654.15, 942.46",
    TextColor3 = Color3.fromRGB(220, 210, 240),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextWrapped = true
})

local function showAdmin(enabled)
    authenticated = enabled

    emailInput.Visible = not enabled
    passwordInput.Visible = not enabled
    loginButton.Visible = not enabled

    startButton.Visible = enabled
    stopButton.Visible = enabled
    participantsButton.Visible = enabled
    output.Visible = enabled

    if enabled then
        status.Text = "Moderador autenticado: " ..
            player.Name
    end
end

showAdmin(false)

loginButton.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true

    status.Text = "Autenticando..."

    local success = login(
        emailInput.Text,
        passwordInput.Text
    )

    passwordInput.Text = ""

    if success then
        showAdmin(true)
    else
        status.Text =
            "Login invalido ou conta nao autorizada."
    end

    busy = false
end)

-- INICIAR FARM SEM SOBRESCREVER

startButton.MouseButton1Click:Connect(function()
    if not authenticated or busy then return end
    busy = true

    status.Text = "Verificando farm existente..."

    local message = "Nao foi possivel iniciar."

    for attempt = 1, 3 do
        local code, current, headers = db(
            "GET",
            "/farm/commands",
            nil,
            {["X-Firebase-ETag"] = "true"}
        )

        if code ~= 200 then
            message = "Erro Firebase: " .. tostring(code)
            break
        end

        if farmActive(current) then
            message = "UMA FARM JA ESTA ATIVA!"
            break
        end

        local etag = getETag(headers)

        if not etag then
            message =
                "Sem ETag. Inicio bloqueado por seguranca."
            break
        end

        local command = {
            action = "start",
            active = true,
            sessionId = Http:GenerateGUID(false),
            moderator = player.Name,
            moderatorUserId = player.UserId,
            moderatorUid = ADMIN_UID,
            placeId = game.PlaceId,
            jobId = game.JobId,
            destination = SPAWN,
            issuedAt = {
                [".sv"] = "timestamp"
            }
        }

        local writeCode = db(
            "PUT",
            "/farm/commands",
            command,
            {["if-match"] = etag}
        )

        if writeCode == 200 then
            message = "Farm iniciada com sucesso!"
            output.Text =
                "Farm ativa\nResponsavel: " ..
                player.Name ..
                "\nSem limite de tempo"
            break
        elseif writeCode == 412 then
            message = "Outra farm foi iniciada."
        else
            message =
                "Erro ao iniciar. HTTP: " ..
                tostring(writeCode)
            break
        end
    end

    status.Text = message
    busy = false
end)

-- ENCERRAR FARM MANUALMENTE

stopButton.MouseButton1Click:Connect(function()
    if not authenticated or busy then return end
    busy = true

    status.Text = "Verificando farm..."

    local code, current, headers = db(
        "GET",
        "/farm/commands",
        nil,
        {["X-Firebase-ETag"] = "true"}
    )

    if code ~= 200 then
        status.Text = "Erro ao consultar farm."
        busy = false
        return
    end

    if not farmActive(current) then
        status.Text = "Nenhuma farm ativa."
        busy = false
        return
    end

    local etag = getETag(headers)

    if not etag then
        status.Text = "Nao foi possivel validar a farm."
        busy = false
        return
    end

    local stopped = {
        action = "stop",
        active = false,
        sessionId = current.sessionId,
        moderator = current.moderator,
        stoppedBy = player.Name,
        issuedAt = current.issuedAt,
        stoppedAt = {
            [".sv"] = "timestamp"
        }
    }

    local writeCode = db(
        "PUT",
        "/farm/commands",
        stopped,
        {["if-match"] = etag}
    )

    if writeCode == 200 then
        status.Text = "Farm encerrada!"
        output.Text = "Nenhuma farm ativa."
    elseif writeCode == 412 then
        status.Text =
            "A farm mudou. Tente novamente."
    else
        status.Text =
            "Erro ao encerrar. HTTP: " ..
            tostring(writeCode)
    end

    busy = false
end)

-- PARTICIPANTES

participantsButton.MouseButton1Click:Connect(function()
    if not authenticated or busy then return end
    busy = true

    status.Text = "Consultando participantes..."

    local code, data = db(
        "GET", "/farm/participants"
    )

    if code ~= 200 then
        status.Text =
            "Erro na consulta: " .. tostring(code)
        busy = false
        return
    end

    local names = {}
    local now = DateTime.now().UnixTimestampMillis

    if type(data) == "table" then
        for _, p in pairs(data) do
            if type(p) == "table"
                and p.active == true
                and p.jobId == game.JobId
                and tonumber(p.placeId) == game.PlaceId
                and now - (tonumber(p.lastSeen) or 0)
                    < 180000 then

                table.insert(
                    names,
                    tostring(p.name or "Jogador")
                )
            end
        end
    end

    table.sort(names)

    output.Text =
        "Participantes ativos: " .. #names ..
        "\n" ..
        (#names > 0 and
            table.concat(names, ", ") or
            "Nenhum participante")

    status.Text = "Consulta concluida."
    busy = false
end)

-- LOGIN AUTOMATICO

task.spawn(function()
    if not (readfile and isfile) then
        status.Text = "Faca login para continuar."
        return
    end

    local ok, saved = pcall(function()
        if not isfile(SESSION_FILE) then
            return nil
        end

        return Http:JSONDecode(
            readfile(SESSION_FILE)
        )
    end)

    if ok and type(saved) == "table"
        and saved.uid == ADMIN_UID
        and saved.refreshToken then

        refreshToken = saved.refreshToken
        status.Text = "Recuperando sessao..."

        if renew() then
            showAdmin(true)
            return
        end
    end

    status.Text = "Faca login para continuar."
end)

task.spawn(function()
    while gui.Parent do
        task.wait(45 * 60)

        if authenticated and refreshToken then
            if not renew() then
                idToken = nil
                showAdmin(false)
                status.Text =
                    "Sessao expirada. Entre novamente."
            end
        end
    end
end)

print("SKY FARM v1.0 | Moderador carregado")
