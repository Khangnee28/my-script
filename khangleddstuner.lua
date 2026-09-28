-- ============================================================
-- KHANGLE DDS HUB v25 — SYNCED HSV RAINBOW
-- ============================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local camera = workspace.CurrentCamera

local function checkFarmOK() return workspace:FindFirstChild("Computers") ~= nil end

pcall(function()
    Lighting.GlobalShadows = true
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
    if not Lighting:FindFirstChild("KhangLeBloom") then
        local b = Instance.new("BloomEffect", Lighting)
        b.Name = "KhangLeBloom"; b.Intensity = 0.4; b.Threshold = 0.8
    end
end)

local parent = nil
pcall(function() parent = gethui and gethui() or CoreGui end)
if not parent then parent = LocalPlayer:WaitForChild("PlayerGui") end
if parent:FindFirstChild("KhangLeCustomTuner") then parent.KhangLeCustomTuner:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KhangLeCustomTuner"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = parent

local function makeHeaderDraggable(header, frame)
    header.Active = true
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ============ THEME ============
local HUB_BG    = Color3.fromRGB(10, 14, 22)
local HUB_SIDE  = Color3.fromRGB(14, 20, 32)
local CARD_BG   = Color3.fromRGB(18, 26, 40)
local themeColor = Color3.fromRGB(0, 229, 160)
local ACCENT2   = Color3.fromRGB(56, 189, 248)
local TXT_DIM   = Color3.fromRGB(150, 165, 185)

-- ============ HSV RAINBOW (SMOOTH, INFINITE) ============
-- Dung HSV de co vo han mau, muot hon. Cung 1 ham dung cho menu + floats.
local function rainbowAt(t)
    return Color3.fromHSV((t * 0.06) % 1, 1, 1)
end

-- ============ LED STATE (DEFAULT RAINBOW ON, SYNC) ============
local menuRainbow = true
local menuFixedColor = Color3.fromRGB(0, 229, 160)
local floatRainbow = true
local floatFixedColor = Color3.fromRGB(0, 229, 160)
local floatRGB = {}

local function addRGBStroke(btn)
    local s = Instance.new("UIStroke", btn)
    s.Name = "RGB"; s.Thickness = 2.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0; s.Color = rainbowAt(0)
    table.insert(floatRGB, s)
    return s
end

-- ============ FORWARD DECL ============
local ControlPanel, freecamMenuFrame, hideFloatBtn
local HubFrame, hubClose, hubHeader, hubStroke, statPanel
local farmSwitch, farmNote
local bodyOpenBtn, fcOpenBtn
local ToggleFloatMenuBtn
local lblStat1, lblStat2, lblTime, lblWork
local showAutoTFloat = false
local farmOffice = false
local ofAnswers, ofPrints = 0, 0
local activeMode, farmStart = nil, 0
local antiAfk, optFPS = true, false

local ridegoSwitch
local ridegoStatusFrame
local ridegoTimeLbl, ridegoTripsLbl, ridegoEarnLbl
local ridegoStatusCarLbl, ridegoStatusLbl
local ridegoPickLbl
local ridegoCarBtn, ridegoCarListPanel, ridegoCarScroll, ridegoCarListWrap
local ridegoCarOpen = false
local ridegoSelectedCar = ""
local ridegoCarList = {}

_G._officeStop = nil
_G._ridegoStop = nil
_G._ridegoEnabled = false

-- ============ NUT NOI ============
local function makeFloatBtn(icon, color, yPos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 48, 0, 48); b.Position = UDim2.new(0, 25, yPos, 0)
    b.BackgroundColor3 = Color3.fromRGB(15, 15, 15); b.TextColor3 = color
    b.Text = icon; b.TextSize = 22; b.Font = Enum.Font.GothamBold
    b.Draggable = true; b.ZIndex = 10; b.Parent = ScreenGui
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local ToggleBtn = makeFloatBtn("👑", themeColor, 0.4)
local AutoTFloatingBtn = makeFloatBtn("🕹️", Color3.fromRGB(255, 100, 0), 0.53); AutoTFloatingBtn.Visible = false
local BodyManagerFloatingBtn = makeFloatBtn("🚗", Color3.fromRGB(0, 230, 180), 0.66); BodyManagerFloatingBtn.Visible = false
local FreecamFloatingBtn = makeFloatBtn("📷", Color3.fromRGB(255, 255, 255), 0.79); FreecamFloatingBtn.Visible = false

-- ============ LED MASTER LOOP (SYNCED) ============
-- 1 loop duy nhat, cung t, cung mau cho menu + tat ca nut noi + status borders
-- -> khong con lech pha, khong loan mat
task.spawn(function()
    local t = 0
    while true do
        task.wait(0.03)
        t = t + 0.15
        local cMenu, cFloat
        if menuRainbow then cMenu = rainbowAt(t) else cMenu = menuFixedColor end
        if floatRainbow then cFloat = rainbowAt(t) else cFloat = floatFixedColor end

        -- Menu chinh
        if hubStroke and hubStroke.Parent then
            hubStroke.Color = cMenu
            if hubHeader then hubHeader.TextColor3 = cMenu end
            if ToggleBtn then ToggleBtn.TextColor3 = cMenu end
        end

        -- Nut noi
        for _, s in ipairs(floatRGB) do
            if s and s.Parent then
                s.Color = cFloat
                s.Transparency = 0
            end
        end
    end
end)

-- ============ STATUS OFFICE ============
do
    statPanel = Instance.new("Frame")
    statPanel.Size = UDim2.new(0, 250, 0, 148)
    statPanel.Position = UDim2.new(0, 76, 0.5, 20)
    statPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
    statPanel.BackgroundTransparency = 0.15
    statPanel.BorderSizePixel = 0
    statPanel.Active = true; statPanel.Draggable = true
    statPanel.Visible = false; statPanel.ZIndex = 9
    statPanel.Parent = ScreenGui
    Instance.new("UICorner", statPanel).CornerRadius = UDim.new(0, 10)
    local so = Instance.new("UIStroke", statPanel)
    so.Name = "RainbowBorder"; so.Thickness = 2
    so.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; so.Color = rainbowAt(0)
    task.spawn(function()
        local t = 0
        while true do task.wait(0.03); t = t + 0.15
            if so and so.Parent then so.Color = rainbowAt(t) end
        end
    end)
    local t1 = Instance.new("TextLabel", statPanel)
    t1.Size = UDim2.new(1, -20, 0, 24); t1.Position = UDim2.new(0, 10, 0, 4)
    t1.BackgroundTransparency = 1; t1.Text = "🌾 Office Status"
    t1.TextColor3 = Color3.fromRGB(255, 140, 40); t1.TextSize = 13
    t1.Font = Enum.Font.GothamBold; t1.TextXAlignment = Enum.TextXAlignment.Left; t1.ZIndex = 10
    local function sl(y)
        local l = Instance.new("TextLabel", statPanel)
        l.Size = UDim2.new(1, -20, 0, 18); l.Position = UDim2.new(0, 10, 0, y)
        l.BackgroundTransparency = 1; l.Text = ""
        l.TextColor3 = Color3.fromRGB(200, 220, 240); l.TextSize = 11
        l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd; l.ZIndex = 10
        return l
    end
    lblStat1 = sl(32); lblStat2 = sl(50); lblTime = sl(68); lblWork = sl(92)
    lblWork.TextColor3 = Color3.fromRGB(255, 200, 80)
end

local function setStatus(t) if lblWork then lblWork.Text = "📍 " .. t end end
local function fmtTime(s)
    s = math.floor(s)
    local h = math.floor(s / 3600); local m = math.floor((s % 3600) / 60); local sec = s % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, sec) end
    return string.format("%02d:%02d", m, sec)
end
local function refreshStatPanel()
    if activeMode == "office" then
        lblStat1.Text = "🧮 Lượt giải: " .. ofAnswers
        lblStat2.Text = "🖨️ Lượt in: " .. ofPrints
    end
end
task.spawn(function()
    while true do task.wait(1)
        if activeMode == "office" and farmStart > 0 then
            lblTime.Text = "⏱ Thời gian: " .. fmtTime(os.clock() - farmStart)
        end
    end
end)

-- ============ FPS/PING ============
local perfOn, perfLocked = false, false
local perfFrame = Instance.new("Frame")
perfFrame.Size = UDim2.new(0, 160, 0, 40); perfFrame.Position = UDim2.new(1, -170, 0, 96)
perfFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12); perfFrame.BackgroundTransparency = 0.35
perfFrame.BorderSizePixel = 0; perfFrame.Visible = false; perfFrame.ZIndex = 50
perfFrame.Active = true; perfFrame.Draggable = true; perfFrame.Parent = ScreenGui
Instance.new("UICorner", perfFrame).CornerRadius = UDim.new(0, 8)
local perfLabel = Instance.new("TextLabel", perfFrame)
perfLabel.Size = UDim2.new(1, -12, 1, -8); perfLabel.Position = UDim2.new(0, 6, 0, 4)
perfLabel.BackgroundTransparency = 1; perfLabel.Text = "FPS: -- | Ping: --"
perfLabel.TextColor3 = Color3.fromRGB(140, 255, 140); perfLabel.TextSize = 11
perfLabel.Font = Enum.Font.GothamBold; perfLabel.TextXAlignment = Enum.TextXAlignment.Left; perfLabel.ZIndex = 51
local function getPing()
    local p = 0
    pcall(function() p = StatsService:GetNetworkPing() end)
    if (not p) or p <= 0 then pcall(function() p = player:GetNetworkPing() end) end
    if p and p > 0 and p < 1 then p = p * 1000 end
    return math.floor(p or 0)
end
local fpsFrames = 0
RunService.RenderStepped:Connect(function() fpsFrames = fpsFrames + 1 end)
task.spawn(function()
    while true do task.wait(1)
        local fps = fpsFrames; fpsFrames = 0
        if perfOn then perfLabel.Text = string.format("FPS: %d | Ping: %dms", fps, getPing()) end
    end
end)

-- ============ NAME ============
local hideNameOn, customName = false, ""
local function getChar() return LocalPlayer.Character end
local function hideNameTags()
    local c = getChar(); if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then pcall(function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end) end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BillboardGui") then pcall(function() d.Enabled = false end) end
    end
end
local function showNameTags()
    local c = getChar(); if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then pcall(function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end) end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BillboardGui") then pcall(function() d.Enabled = true end) end
    end
end
local function applyCustomName()
    local c = getChar(); if not c then return end
    pcall(function() LocalPlayer.DisplayName = customName end)
    local myName = LocalPlayer.Name
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BillboardGui") then
            for _, t in ipairs(d:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text:find(myName, 1, true) then t.Text = customName end
            end
        end
    end
end
local function watchChar(c)
    if not c then return end
    c.DescendantAdded:Connect(function(d)
        if d:IsA("BillboardGui") then
            if hideNameOn then pcall(function() d.Enabled = false end) end
            if customName ~= "" then task.wait(0.2); applyCustomName() end
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function(c)
    watchChar(c); task.wait(0.5)
    if hideNameOn then hideNameTags() end
    if customName ~= "" then applyCustomName() end
end)
if LocalPlayer.Character then watchChar(LocalPlayer.Character) end
task.spawn(function()
    while true do task.wait(1)
        if hideNameOn then hideNameTags() end
    end
end)

-- ============================================================
-- KHOI 1: HUB UI
-- ============================================================
do
    HubFrame = Instance.new("Frame")
    HubFrame.Size = UDim2.new(0, 480, 0, 350)
    HubFrame.Position = UDim2.new(0.5, -240, 0.5, -175)
    HubFrame.BackgroundColor3 = HUB_SIDE
    HubFrame.BorderSizePixel = 0; HubFrame.Active = true; HubFrame.Visible = false
    HubFrame.ClipsDescendants = false; HubFrame.ZIndex = 8; HubFrame.Parent = ScreenGui
    Instance.new("UICorner", HubFrame).CornerRadius = UDim.new(0, 12)
    hubStroke = Instance.new("UIStroke", HubFrame)
    hubStroke.Color = rainbowAt(0); hubStroke.Thickness = 1.5; hubStroke.Transparency = 0.25

    hubHeader = Instance.new("TextLabel", HubFrame)
    hubHeader.Size = UDim2.new(1, -40, 0, 34); hubHeader.Position = UDim2.new(0, 12, 0, 0)
    hubHeader.BackgroundTransparency = 1; hubHeader.Text = "👑 KHANGLE DDS HUB"
    hubHeader.TextColor3 = rainbowAt(0); hubHeader.TextSize = 13
    hubHeader.Font = Enum.Font.GothamBold; hubHeader.TextXAlignment = Enum.TextXAlignment.Left
    hubHeader.ZIndex = 18
    makeHeaderDraggable(hubHeader, HubFrame)

    hubClose = Instance.new("TextButton", HubFrame)
    hubClose.Size = UDim2.new(0, 26, 0, 26); hubClose.Position = UDim2.new(1, -30, 0, 4)
    hubClose.BackgroundTransparency = 1; hubClose.TextColor3 = TXT_DIM
    hubClose.Text = "✕"; hubClose.TextSize = 14; hubClose.Font = Enum.Font.GothamBold; hubClose.ZIndex = 19

    local sidebar = Instance.new("Frame", HubFrame)
    sidebar.Size = UDim2.new(0, 96, 1, -34); sidebar.Position = UDim2.new(0, 0, 0, 34)
    sidebar.BackgroundTransparency = 1; sidebar.BorderSizePixel = 0; sidebar.ZIndex = 14

    local content = Instance.new("Frame", HubFrame)
    content.Size = UDim2.new(1, -104, 1, -42); content.Position = UDim2.new(0, 100, 0, 34)
    content.BackgroundColor3 = HUB_BG; content.BorderSizePixel = 0; content.ClipsDescendants = false
    content.ZIndex = 10
    Instance.new("UICorner", content).CornerRadius = UDim.new(0, 12)

    local pages, navBtns = {}, {}
    local currentPageName = nil
    local function addPage(name)
        if pages[name] then return pages[name] end
        local pg = Instance.new("Frame", content)
        pg.Size = UDim2.new(1, 0, 1, 0); pg.BackgroundTransparency = 1
        pg.ClipsDescendants = false; pg.Visible = false; pg.ZIndex = 11
        pages[name] = pg
        return pg
    end
    local function selectPage(name)
        currentPageName = name
        for n, pg in pairs(pages) do pg.Visible = (n == name) end
        for n, b in pairs(navBtns) do
            if n == name then
                b.BackgroundColor3 = Color3.fromRGB(24, 36, 54); b.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                b.BackgroundColor3 = Color3.fromRGB(18, 26, 40); b.TextColor3 = TXT_DIM
            end
        end
    end
    local navIndex = 0
    local function addNav(name, icon)
        local b = Instance.new("TextButton", sidebar)
        b.Size = UDim2.new(1, -12, 0, 40); b.Position = UDim2.new(0, 6, 0, 6 + navIndex * 44)
        b.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
        b.Text = icon .. " " .. name; b.TextColor3 = TXT_DIM; b.TextSize = 11
        b.Font = Enum.Font.GothamBold; b.ZIndex = 15
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        navIndex = navIndex + 1; navBtns[name] = b
        b.MouseButton1Click:Connect(function() selectPage(name) end)
        addPage(name); return b
    end

    addNav("TUNER", "🎛️"); addNav("CHUNG", "🧰")
    addNav("FARMING", "💼")  -- FIX: icon 🌾 -> 💼
    addNav("SETTINGS", "⚙️")

    local tunerPage = pages["TUNER"]
    local chungPage = pages["CHUNG"]
    local farmingPage = pages["FARMING"]
    local settingsPage = pages["SETTINGS"]

    -- ============ COLOR APPLY ============
    local function applyMenuColor(c)
        menuRainbow = false
        menuFixedColor = c
        if hubStroke then hubStroke.Color = c end
        if hubHeader then hubHeader.TextColor3 = c end
        if ToggleBtn then ToggleBtn.TextColor3 = c end
    end
    local function applyMenuRainbow() menuRainbow = true end
    local function applyFloatColor(c)
        floatRainbow = false
        floatFixedColor = c
        for _, s in ipairs(floatRGB) do
            if s and s.Parent then s.Color = c; s.Transparency = 0 end
        end
    end
    local function applyFloatRainbow() floatRainbow = true end

    -- ============== TUNER ==============
    local function createInput(name, dv, posY, pg)
        local lbl = Instance.new("TextLabel", pg)
        lbl.Size = UDim2.new(0.9, 0, 0, 14); lbl.Position = UDim2.new(0.05, 0, 0, posY)
        lbl.BackgroundTransparency = 1; lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(210, 210, 210); lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 12
        local box = Instance.new("TextBox", pg)
        box.Size = UDim2.new(0.9, 0, 0, 24); box.Position = UDim2.new(0.05, 0, 0, posY + 14)
        box.BackgroundColor3 = Color3.fromRGB(22, 22, 28); box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.Text = tostring(dv); box.TextSize = 11; box.Font = Enum.Font.GothamBold
        box.BorderSizePixel = 0; box.ZIndex = 12
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local st = Instance.new("UIStroke", box); st.Color = Color3.fromRGB(60, 60, 75); st.Thickness = 1
        return box
    end
    local hpBox = createInput("💪 Hệ số Mã lực (Mặc định: 5.0)", "5.0", 6, tunerPage)
    local rpmBox = createInput("🔥 Cộng thêm Tua máy - RPM (Mặc định: 3500)", "3500", 48, tunerPage)
    local gearRatioBox = createInput("⚙️ Tỷ số truyền số - Ratio Gear (Mặc định: 0.9)", "0.9", 90, tunerPage)
    local finalDriveBox = createInput("⛓️ Tỷ số truyền cuối - Final Drive (Mặc định: 0.9)", "0.9", 132, tunerPage)
    local Status = Instance.new("TextLabel", tunerPage)
    Status.Size = UDim2.new(0.9, 0, 0, 18); Status.Position = UDim2.new(0.05, 0, 0, 174)
    Status.BackgroundTransparency = 1; Status.Text = "Trạng thái: Sẵn sàng."
    Status.TextColor3 = Color3.fromRGB(255, 200, 0); Status.TextSize = 10
    Status.Font = Enum.Font.GothamBold; Status.TextXAlignment = Enum.TextXAlignment.Center; Status.ZIndex = 12
    local InjectBtn = Instance.new("TextButton", tunerPage)
    InjectBtn.Size = UDim2.new(0.9, 0, 0, 28); InjectBtn.Position = UDim2.new(0.05, 0, 0, 194)
    InjectBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100); InjectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    InjectBtn.Text = "⚡ ÁP DỤNG TUNER"; InjectBtn.TextSize = 11
    InjectBtn.Font = Enum.Font.GothamBold; InjectBtn.ZIndex = 12
    Instance.new("UICorner", InjectBtn).CornerRadius = UDim.new(0, 7)
    ToggleFloatMenuBtn = Instance.new("TextButton", tunerPage)
    ToggleFloatMenuBtn.Size = UDim2.new(0.9, 0, 0, 28); ToggleFloatMenuBtn.Position = UDim2.new(0.05, 0, 0, 226)
    ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); ToggleFloatMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleFloatMenuBtn.Text = "🕹️ NÚT NỔI AUTO T: ĐANG TẮT"; ToggleFloatMenuBtn.TextSize = 11
    ToggleFloatMenuBtn.Font = Enum.Font.GothamBold; ToggleFloatMenuBtn.ZIndex = 12
    Instance.new("UICorner", ToggleFloatMenuBtn).CornerRadius = UDim.new(0, 7)

    local statusThread, tunedModels = nil, setmetatable({}, { __mode = "k" })
    local function setStatusTmp(msg, color, delay)
        if not Status or not Status.Parent then return end
        if statusThread then task.cancel(statusThread); statusThread = nil end
        Status.Text = msg; Status.TextColor3 = color
        statusThread = task.delay(delay or 3, function()
            if Status and Status.Parent then
                Status.Text = "Trạng thái: Sẵn sàng."; Status.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
        end)
    end
    InjectBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        local isInVehicle = seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat"))
        if not isInVehicle then setStatusTmp("❌ Hãy ngồi lên xe rồi bấm áp dụng nhé!", Color3.fromRGB(255, 50, 50)); return end
        local vehicleModel = seat.Parent
        if vehicleModel and tunedModels[vehicleModel] then
            setStatusTmp("⚠ Xe này đã tune rồi — respawn xe để apply", Color3.fromRGB(255, 180, 60), 4); return
        end
        local hpMult = tonumber(hpBox.Text) or 5.0
        local rpmAdd = tonumber(rpmBox.Text) or 3500
        local gearMult = tonumber(gearRatioBox.Text) or 0.8
        local finalMult = tonumber(finalDriveBox.Text) or 0.8
        local count = 0
        local charParts = {}
        if char then
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then charParts[p] = true end end
            local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then charParts[hrp] = true end
        end
        local function isCharOwned(t)
            local ok1, res1 = pcall(function()
                for _, v in pairs(t) do if typeof(v) == "Instance" and charParts[v] then return true end end
                return false
            end)
            return ok1 and res1
        end
        local function unfreeze(t) pcall(function() setreadonly(t, false) end) end
        local SPEED_KEYS = { topspeed=true, maxspeed=true, speedlimit=true, maxvelocity=true, topspeedkmh=true, maxthrottle=true, limiter=true }
        local POWER_KEYS = { horsepower=true, torque=true, maxpower=true }
        local RPM_KEYS = { redline=true, maxrpm=true, rpm=true }
        local GEAR_KEYS = { gearratio=true, finaldrive=true }
        local GEAR_TBL = { gearratios=true, gears=true }
        local DRAG_KEYS = { drag=true, dragcoefficient=true, airresistance=true }
        local seen = {}
        local function tuneTable(t, depth)
            if depth > 6 or seen[t] then return end
            if isCharOwned(t) then return end
            seen[t] = true; unfreeze(t)
            for k, v in pairs(t) do
                if type(k) == "string" then
                    local lk = k:lower()
                    if SPEED_KEYS[lk] and type(v) == "number" and v > 0 then
                        if pcall(function() t[k] = v * 1.6 end) then count = count + 1 end
                    elseif POWER_KEYS[lk] and type(v) == "number" then
                        if pcall(function() t[k] = v * hpMult end) then count = count + 1 end
                    elseif RPM_KEYS[lk] and type(v) == "number" and v >= 1000 then
                        if pcall(function() t[k] = v + rpmAdd end) then count = count + 1 end
                    elseif GEAR_KEYS[lk] and type(v) == "number" and v > 0 then
                        if pcall(function() t[k] = v * gearMult end) then count = count + 1 end
                    elseif GEAR_TBL[lk] and type(v) == "table" then
                        unfreeze(v)
                        for i, g in pairs(v) do
                            if type(g) == "number" then if pcall(function() v[i] = g * gearMult end) then count = count + 1 end end
                        end
                    elseif DRAG_KEYS[lk] and type(v) == "number" and v > 0 then
                        if pcall(function() t[k] = v * 0.7 end) then count = count + 1 end
                    elseif type(v) == "table" then tuneTable(v, depth + 1) end
                elseif type(v) == "table" then tuneTable(v, depth + 1) end
            end
        end
        if typeof(getgc) == "function" then
            pcall(function()
                for _, obj in pairs(getgc(true)) do
                    if typeof(obj) == "table" then pcall(function() tuneTable(obj, 1) end) end
                end
            end)
        end
        if vehicleModel then
            for _, obj in pairs(vehicleModel:GetDescendants()) do
                pcall(function()
                    for an, av in pairs(obj:GetAttributes()) do
                        if type(av) == "number" then
                            local ln = an:lower()
                            if ln:find("topspeed") or ln:find("maxspeed") or ln:find("speedlimit") or ln:find("maxvelocity") then
                                obj:SetAttribute(an, av * 1.6); count = count + 1
                            elseif ln:find("horsepower") or ln:find("power") or ln:find("torque") then
                                obj:SetAttribute(an, av * hpMult); count = count + 1
                            elseif ln:find("drag") then obj:SetAttribute(an, av * 0.7); count = count + 1 end
                        end
                    end
                end)
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    pcall(function()
                        local name = obj.Name:lower()
                        if name:find("topspeed") or name:find("maxspeed") or name:find("speedlimit") then
                            obj.Value = obj.Value * 1.6; count = count + 1
                        elseif name:find("horsepower") or name:find("power") or name:find("torque") then
                            obj.Value = obj.Value * hpMult; count = count + 1
                        elseif name:find("rpm") or name:find("redline") then
                            if obj.Value >= 1000 then obj.Value = obj.Value + rpmAdd; count = count + 1 end
                        elseif name:find("gear") or name:find("ratio") then
                            obj.Value = obj.Value * gearMult; count = count + 1
                        elseif name:find("drive") then obj.Value = obj.Value * finalMult; count = count + 1
                        elseif name:find("drag") then obj.Value = obj.Value * 0.7; count = count + 1 end
                    end)
                end
            end
        end
        if count == 0 then setStatusTmp("⚠ Không tìm thấy gì để tune", Color3.fromRGB(255, 180, 60), 4); return end
        if vehicleModel then tunedModels[vehicleModel] = true end
        setStatusTmp("✔ Đã tune (xuống xe lên lại)", Color3.fromRGB(0, 255, 120), 4)
    end)

    -- ============== CHUNG ==============
    local scroll = Instance.new("ScrollingFrame", chungPage)
    scroll.Size = UDim2.new(1, 0, 1, 0); scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 260); scroll.ScrollBarThickness = 4; scroll.ZIndex = 12
    local chungPad = Instance.new("UIPadding", scroll)
    chungPad.PaddingTop = UDim.new(0, 6); chungPad.PaddingBottom = UDim.new(0, 6)

    local function makeCard(par, y, title, desc, col)
        local card = Instance.new("Frame", par)
        card.Size = UDim2.new(1, -8, 0, 110); card.Position = UDim2.new(0, 4, 0, y)
        card.BackgroundColor3 = CARD_BG; card.BorderSizePixel = 0; card.ZIndex = 12
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
        local cs = Instance.new("UIStroke", card); cs.Color = col; cs.Thickness = 1; cs.Transparency = 0.4
        local t = Instance.new("TextLabel", card)
        t.Size = UDim2.new(1, -24, 0, 20); t.Position = UDim2.new(0, 12, 0, 8)
        t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = col; t.TextSize = 12
        t.Font = Enum.Font.GothamBold; t.TextXAlignment = Enum.TextXAlignment.Left; t.ZIndex = 13
        local d = Instance.new("TextLabel", card)
        d.Size = UDim2.new(1, -24, 0, 34); d.Position = UDim2.new(0, 12, 0, 30)
        d.BackgroundTransparency = 1; d.Text = desc; d.TextColor3 = TXT_DIM; d.TextSize = 10
        d.Font = Enum.Font.GothamMedium; d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextWrapped = true; d.ZIndex = 13
        return card
    end
    local cardBody = makeCard(scroll, 0, "🚗 THÁO DÀN ÁO — quản lý part xe", "BẬT = hiện nút nổi 🚗 để dùng.\nTẮT = ẩn nút nổi, đóng bảng.", Color3.fromRGB(0, 230, 180))
    bodyOpenBtn = Instance.new("TextButton", cardBody)
    bodyOpenBtn.Size = UDim2.new(0.9, 0, 0, 28); bodyOpenBtn.Position = UDim2.new(0.05, 0, 0, 70)
    bodyOpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); bodyOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bodyOpenBtn.Text = "🚗 DÀN ÁO: ĐANG TẮT"; bodyOpenBtn.TextSize = 10
    bodyOpenBtn.Font = Enum.Font.GothamBold; bodyOpenBtn.ZIndex = 13
    Instance.new("UICorner", bodyOpenBtn).CornerRadius = UDim.new(0, 6)
    local cardFc = makeCard(scroll, 120, "📷 FREECAM CINEMATIC — quay phim", "BẬT = hiện nút nổi 📷 để dùng.\nTẮT = ẩn nút nổi, đóng menu.", Color3.fromRGB(100, 150, 255))
    fcOpenBtn = Instance.new("TextButton", cardFc)
    fcOpenBtn.Size = UDim2.new(0.9, 0, 0, 28); fcOpenBtn.Position = UDim2.new(0.05, 0, 0, 70)
    fcOpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); fcOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fcOpenBtn.Text = "📷 FREECAM: ĐANG TẮT"; fcOpenBtn.TextSize = 10
    fcOpenBtn.Font = Enum.Font.GothamBold; fcOpenBtn.ZIndex = 13
    Instance.new("UICorner", fcOpenBtn).CornerRadius = UDim.new(0, 6)

    -- ============== FARMING ==============
    local farmScroll = Instance.new("ScrollingFrame", farmingPage)
    farmScroll.Size = UDim2.new(1, 0, 1, 0); farmScroll.Position = UDim2.new(0, 0, 0, 0)
    farmScroll.BackgroundTransparency = 1; farmScroll.BorderSizePixel = 0
    farmScroll.CanvasSize = UDim2.new(0, 0, 0, 320); farmScroll.ScrollBarThickness = 4; farmScroll.ZIndex = 12
    local farmPad = Instance.new("UIPadding", farmScroll)
    farmPad.PaddingTop = UDim.new(0, 6); farmPad.PaddingBottom = UDim.new(0, 6)

    local function makeSwitch(par, posY)
        local track = Instance.new("TextButton", par)
        track.Size = UDim2.new(0, 52, 0, 26); track.Position = UDim2.new(1, -64, 0, posY)
        track.BackgroundColor3 = Color3.fromRGB(60, 60, 70); track.Text = ""; track.ZIndex = 14
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame", track)
        knob.Size = UDim2.new(0, 20, 0, 20); knob.Position = UDim2.new(0, 3, 0.5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235); knob.ZIndex = 15
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local on = false
        local function set(v)
            on = v
            track.BackgroundColor3 = v and themeColor or Color3.fromRGB(60, 60, 70)
            knob.Position = v and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        end
        return { track = track, knob = knob, set = set, isOn = function() return on end }
    end

    local cardFarm = makeCard(farmScroll, 0, "🌾 OFFICE AUTOFARM — farm văn phòng", "Tự ngồi ghế, giải toán & in ấn.\nSố liệu hiện trong bảng status khi bật.", ACCENT2)
    farmSwitch = makeSwitch(cardFarm, 10)
    farmNote = Instance.new("TextLabel", cardFarm)
    farmNote.Size = UDim2.new(1, -24, 0, 16); farmNote.Position = UDim2.new(0, 12, 0, 86)
    farmNote.BackgroundTransparency = 1; farmNote.Text = ""
    farmNote.TextColor3 = Color3.fromRGB(255, 120, 80); farmNote.TextSize = 10
    farmNote.Font = Enum.Font.GothamBold; farmNote.TextXAlignment = Enum.TextXAlignment.Left
    farmNote.TextWrapped = true; farmNote.ZIndex = 13

    local cardRide = Instance.new("Frame", farmScroll)
    cardRide.Size = UDim2.new(1, -8, 0, 160); cardRide.Position = UDim2.new(0, 4, 0, 120)
    cardRide.BackgroundColor3 = CARD_BG; cardRide.BorderSizePixel = 0; cardRide.ZIndex = 12
    Instance.new("UICorner", cardRide).CornerRadius = UDim.new(0, 10)
    local rs2 = Instance.new("UIStroke", cardRide); rs2.Color = Color3.fromRGB(255, 140, 40); rs2.Thickness = 1; rs2.Transparency = 0.4

    local rideTitle = Instance.new("TextLabel", cardRide)
    rideTitle.Size = UDim2.new(1, -24, 0, 20); rideTitle.Position = UDim2.new(0, 12, 0, 8)
    rideTitle.BackgroundTransparency = 1; rideTitle.Text = "🚕 RIDEGO AUTOFARM"
    rideTitle.TextColor3 = Color3.fromRGB(255, 140, 40); rideTitle.TextSize = 12
    rideTitle.Font = Enum.Font.GothamBold; rideTitle.TextXAlignment = Enum.TextXAlignment.Left; rideTitle.ZIndex = 13

    local rideDesc = Instance.new("TextLabel", cardRide)
    rideDesc.Size = UDim2.new(1, -24, 0, 34); rideDesc.Position = UDim2.new(0, 12, 0, 30)
    rideDesc.BackgroundTransparency = 1; rideDesc.Text = "Spawn xe, đón khách, bay xuyên địa hình.\nChọn xe bên dưới trước khi bật."
    rideDesc.TextColor3 = TXT_DIM; rideDesc.TextSize = 10
    rideDesc.Font = Enum.Font.GothamMedium; rideDesc.TextXAlignment = Enum.TextXAlignment.Left
    rideDesc.TextWrapped = true; rideDesc.ZIndex = 13

    ridegoSwitch = makeSwitch(cardRide, 10)
    ridegoPickLbl = Instance.new("TextLabel", cardRide)
    ridegoPickLbl.Size = UDim2.new(1, -24, 0, 18); ridegoPickLbl.Position = UDim2.new(0, 12, 0, 70)
    ridegoPickLbl.BackgroundTransparency = 1; ridegoPickLbl.Text = "🚗 Xe: (chưa chọn)"
    ridegoPickLbl.TextColor3 = Color3.fromRGB(180, 200, 220); ridegoPickLbl.TextSize = 10
    ridegoPickLbl.Font = Enum.Font.GothamMedium; ridegoPickLbl.TextXAlignment = Enum.TextXAlignment.Left
    ridegoPickLbl.TextTruncate = Enum.TextTruncate.AtEnd; ridegoPickLbl.ZIndex = 13

    ridegoCarBtn = Instance.new("TextButton", cardRide)
    ridegoCarBtn.Size = UDim2.new(1, -24, 0, 30); ridegoCarBtn.Position = UDim2.new(0, 12, 0, 92)
    ridegoCarBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 48); ridegoCarBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
    ridegoCarBtn.Text = "🚗 CHỌN XE (0)"; ridegoCarBtn.TextSize = 11
    ridegoCarBtn.Font = Enum.Font.GothamBold; ridegoCarBtn.TextXAlignment = Enum.TextXAlignment.Left; ridegoCarBtn.ZIndex = 13
    Instance.new("UICorner", ridegoCarBtn).CornerRadius = UDim.new(0, 6)
    local ridegoCarBtnPad = Instance.new("UIPadding", ridegoCarBtn)
    ridegoCarBtnPad.PaddingLeft = UDim.new(0, 10)

    -- CAR MODAL 240x280
    ridegoCarListPanel = Instance.new("Frame", ScreenGui)
    ridegoCarListPanel.Size = UDim2.new(0, 240, 0, 280)
    ridegoCarListPanel.Position = UDim2.new(0.5, -120, 0.5, -140)
    ridegoCarListPanel.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
    ridegoCarListPanel.BackgroundTransparency = 0.05
    ridegoCarListPanel.BorderSizePixel = 0
    ridegoCarListPanel.Visible = false
    ridegoCarListPanel.ZIndex = 200; ridegoCarListPanel.Active = true
    Instance.new("UICorner", ridegoCarListPanel).CornerRadius = UDim.new(0, 10)
    local carPanelStroke = Instance.new("UIStroke", ridegoCarListPanel)
    carPanelStroke.Color = Color3.fromRGB(255, 140, 40); carPanelStroke.Thickness = 2; carPanelStroke.Transparency = 0.1

    local carPickTitle = Instance.new("TextLabel", ridegoCarListPanel)
    carPickTitle.Size = UDim2.new(1, -50, 0, 30); carPickTitle.Position = UDim2.new(0, 12, 0, 4)
    carPickTitle.BackgroundTransparency = 1; carPickTitle.Text = "🚗 CHỌN XE"
    carPickTitle.TextColor3 = Color3.fromRGB(255, 160, 60); carPickTitle.TextSize = 12
    carPickTitle.Font = Enum.Font.GothamBold; carPickTitle.TextXAlignment = Enum.TextXAlignment.Left; carPickTitle.ZIndex = 201

    local carPickClose = Instance.new("TextButton", ridegoCarListPanel)
    carPickClose.Size = UDim2.new(0, 24, 0, 24); carPickClose.Position = UDim2.new(1, -32, 0, 6)
    carPickClose.BackgroundColor3 = Color3.fromRGB(30, 38, 54); carPickClose.TextColor3 = Color3.fromRGB(220, 230, 240)
    carPickClose.Text = "✕"; carPickClose.TextSize = 12; carPickClose.Font = Enum.Font.GothamBold; carPickClose.ZIndex = 201
    Instance.new("UICorner", carPickClose).CornerRadius = UDim.new(0, 6)
    carPickClose.MouseButton1Click:Connect(function()
        ridegoCarListPanel.Visible = false; ridegoCarOpen = false
    end)

    local carPickDiv = Instance.new("Frame", ridegoCarListPanel)
    carPickDiv.Size = UDim2.new(1, -24, 0, 1); carPickDiv.Position = UDim2.new(0, 12, 0, 38)
    carPickDiv.BackgroundColor3 = Color3.fromRGB(40, 55, 80); carPickDiv.BorderSizePixel = 0; carPickDiv.ZIndex = 201

    ridegoCarScroll = Instance.new("ScrollingFrame", ridegoCarListPanel)
    ridegoCarScroll.Size = UDim2.new(1, -16, 1, -52); ridegoCarScroll.Position = UDim2.new(0, 8, 0, 44)
    ridegoCarScroll.BackgroundTransparency = 1; ridegoCarScroll.BorderSizePixel = 0
    ridegoCarScroll.ScrollBarThickness = 4; ridegoCarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ridegoCarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; ridegoCarScroll.ZIndex = 201

    local sListR = Instance.new("UIListLayout", ridegoCarScroll)
    sListR.Padding = UDim.new(0, 5); sListR.SortOrder = Enum.SortOrder.LayoutOrder
    local sPadR = Instance.new("UIPadding", ridegoCarScroll)
    sPadR.PaddingTop = UDim.new(0, 2); sPadR.PaddingLeft = UDim.new(0, 2)
    sPadR.PaddingRight = UDim.new(0, 2); sPadR.PaddingBottom = UDim.new(0, 2)

    ridegoCarListWrap = ridegoCarScroll

    -- ============== SETTINGS ==============
    local settingsScroll = Instance.new("ScrollingFrame", settingsPage)
    settingsScroll.Size = UDim2.new(1, 0, 1, 0); settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0; settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settingsScroll.ScrollBarThickness = 4; settingsScroll.ZIndex = 12
    local settingsList = Instance.new("UIListLayout", settingsScroll)
    settingsList.Padding = UDim.new(0, 6); settingsList.SortOrder = Enum.SortOrder.LayoutOrder
    local settingsPad = Instance.new("UIPadding", settingsScroll)
    settingsPad.PaddingTop = UDim.new(0, 8); settingsPad.PaddingLeft = UDim.new(0, 4)
    settingsPad.PaddingRight = UDim.new(0, 4); settingsPad.PaddingBottom = UDim.new(0, 8)

    local function readFlag(fname)
        if readfile and isfile and isfile(fname) then
            local ok, v = pcall(readfile, fname)
            if ok and v == "1" then return true end
        end
        return false
    end
    local function parseHex(str)
        local input = (str or ""):gsub("^#", "")
        if #input ~= 6 then return nil end
        local r = tonumber(input:sub(1,2), 16); local g = tonumber(input:sub(3,4), 16); local b = tonumber(input:sub(5,6), 16)
        if not (r and g and b) then return nil end
        return Color3.fromRGB(r, g, b), input:upper()
    end
    local QUAL = { Enum.SavedQualitySetting.QualityLevel1, Enum.SavedQualitySetting.QualityLevel2, Enum.SavedQualitySetting.QualityLevel3, Enum.SavedQualitySetting.QualityLevel4, Enum.SavedQualitySetting.QualityLevel5, Enum.SavedQualitySetting.QualityLevel6, Enum.SavedQualitySetting.QualityLevel7, Enum.SavedQualitySetting.QualityLevel8, Enum.SavedQualitySetting.QualityLevel9, Enum.SavedQualitySetting.QualityLevel10 }
    local function setQualityLevel(idx)
        pcall(function()
            if idx == nil then UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
            else UserSettings().GameSettings.SavedQualityLevel = QUAL[idx] end
        end)
    end
    local function bloomSet(on, intensity, threshold)
        pcall(function()
            local b = Lighting:FindFirstChild("KhangLeBloom")
            if not b then b = Instance.new("BloomEffect", Lighting); b.Name = "KhangLeBloom" end
            b.Enabled = on
            if intensity then b.Intensity = intensity end
            if threshold then b.Threshold = threshold end
        end)
    end
    local function sunSet(on, intensity)
        pcall(function()
            local s = Lighting:FindFirstChild("KhangLeSun")
            if not s then s = Instance.new("SunRaysEffect", Lighting); s.Name = "KhangLeSun" end
            s.Enabled = on
            if intensity then s.Intensity = intensity end
        end)
    end
    local function makeSection(order, title, defaultOpen)
        local section = Instance.new("Frame", settingsScroll)
        section.Size = UDim2.new(1, -8, 0, 0); section.AutomaticSize = Enum.AutomaticSize.Y
        section.BackgroundTransparency = 1; section.LayoutOrder = order
        local sl = Instance.new("UIListLayout", section); sl.Padding = UDim.new(0, 0); sl.SortOrder = Enum.SortOrder.LayoutOrder
        local header = Instance.new("TextButton", section)
        header.Size = UDim2.new(1, 0, 0, 28); header.LayoutOrder = 1
        header.BackgroundColor3 = Color3.fromRGB(24, 32, 48); header.TextColor3 = Color3.fromRGB(255, 255, 255)
        header.TextSize = 11; header.Font = Enum.Font.GothamBold; header.TextXAlignment = Enum.TextXAlignment.Left
        header.ZIndex = 14; Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)
        local hp = Instance.new("UIPadding", header); hp.PaddingLeft = UDim.new(0, 8)
        local content = Instance.new("Frame", section)
        content.Size = UDim2.new(1, 0, 0, 0); content.AutomaticSize = Enum.AutomaticSize.Y
        content.LayoutOrder = 2; content.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
        content.BorderSizePixel = 0; content.Visible = defaultOpen or false; content.ZIndex = 13
        Instance.new("UICorner", content).CornerRadius = UDim.new(0, 6)
        local cl = Instance.new("UIListLayout", content); cl.Padding = UDim.new(0, 4); cl.SortOrder = Enum.SortOrder.LayoutOrder
        local cp = Instance.new("UIPadding", content)
        cp.PaddingTop = UDim.new(0, 8); cp.PaddingBottom = UDim.new(0, 8); cp.PaddingLeft = UDim.new(0, 8); cp.PaddingRight = UDim.new(0, 8)
        local isOpen = defaultOpen or false
        header.Text = (isOpen and "▼ " or "▶ ") .. title
        header.MouseButton1Click:Connect(function()
            isOpen = not isOpen; content.Visible = isOpen; header.Text = (isOpen and "▼ " or "▶ ") .. title
        end)
        return content
    end
    local function makeToggle(parent, order, defaultOn, labelOn, labelOff, colorOn, colorOff, cb)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1, 0, 0, 28); b.LayoutOrder = order
        b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 10; b.Font = Enum.Font.GothamBold; b.ZIndex = 14
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local on = defaultOn
        local function paint()
            b.Text = on and labelOn or labelOff
            b.BackgroundColor3 = on and colorOn or colorOff
        end
        paint()
        b.MouseButton1Click:Connect(function() on = not on; paint(); cb(on) end)
        return b
    end
    local function makeInput(parent, order, label, placeholder, btnText, color, onClick)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 26); row.LayoutOrder = order; row.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0, 90, 1, 0); lbl.BackgroundTransparency = 1
        lbl.Text = label; lbl.TextColor3 = Color3.fromRGB(200, 210, 220); lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamBold; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local box = Instance.new("TextBox", row)
        box.Size = UDim2.new(1, -170, 1, 0); box.Position = UDim2.new(0, 92, 0, 0)
        box.BackgroundColor3 = Color3.fromRGB(22, 26, 34); box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.PlaceholderText = placeholder; box.Text = ""; box.TextSize = 10
        box.Font = Enum.Font.GothamBold; box.BorderSizePixel = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(0, 72, 1, 0); btn.Position = UDim2.new(1, -72, 0, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(0, 150, 120)
        btn.Text = btnText; btn.TextColor3 = Color3.new(1, 1, 1); btn.TextSize = 10; btn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local status = Instance.new("TextLabel", parent)
        status.Size = UDim2.new(1, 0, 0, 14); status.LayoutOrder = order + 0.5
        status.BackgroundTransparency = 1; status.Text = ""; status.TextColor3 = Color3.fromRGB(140, 255, 140)
        status.TextSize = 9; status.Font = Enum.Font.GothamBold; status.TextXAlignment = Enum.TextXAlignment.Left
        btn.MouseButton1Click:Connect(function()
            onClick(box.Text, function(msg, ok)
                status.Text = msg
                status.TextColor3 = ok and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 120, 120)
            end)
        end)
        return box
    end

    -- SECTION 1: MAU MENU + NUT NOI (DEFAULT DONG)
    local colorSection = makeSection(1, "🎨 Màu menu + nút nổi", false)
    local presetColors = {
        Color3.fromRGB(0, 229, 160), Color3.fromRGB(56, 189, 248), Color3.fromRGB(167, 139, 250),
        Color3.fromRGB(255, 100, 100), Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 110, 190),
    }

    local menuLbl = Instance.new("TextLabel", colorSection)
    menuLbl.Size = UDim2.new(1, 0, 0, 16); menuLbl.LayoutOrder = 1
    menuLbl.BackgroundTransparency = 1; menuLbl.Text = "MENU CHÍNH"
    menuLbl.TextColor3 = Color3.fromRGB(255, 200, 80); menuLbl.TextSize = 10
    menuLbl.Font = Enum.Font.GothamBold; menuLbl.TextXAlignment = Enum.TextXAlignment.Left

    local menuRow = Instance.new("Frame", colorSection)
    menuRow.Size = UDim2.new(1, 0, 0, 30); menuRow.LayoutOrder = 2; menuRow.BackgroundTransparency = 1
    local mrl = Instance.new("UIListLayout", menuRow)
    mrl.FillDirection = Enum.FillDirection.Horizontal; mrl.Padding = UDim.new(0, 4)
    for _, c in ipairs(presetColors) do
        local sw = Instance.new("TextButton", menuRow)
        sw.Size = UDim2.new(0, 26, 1, 0); sw.BackgroundColor3 = c; sw.Text = ""
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 6)
        sw.MouseButton1Click:Connect(function() applyMenuColor(c) end)
    end
    local menuRainbowSw = Instance.new("TextButton", menuRow)
    menuRainbowSw.Size = UDim2.new(0, 26, 1, 0); menuRainbowSw.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
    menuRainbowSw.Text = "🌈"; menuRainbowSw.TextSize = 14; menuRainbowSw.Font = Enum.Font.GothamBold
    menuRainbowSw.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", menuRainbowSw).CornerRadius = UDim.new(0, 6)
    menuRainbowSw.MouseButton1Click:Connect(function() applyMenuRainbow() end)

    makeInput(colorSection, 3, "Mã menu", "#00E5A0", "ÁP DỤNG", Color3.fromRGB(0, 150, 120), function(txt, cb)
        local col, up = parseHex(txt)
        if not col then cb("❌ mã màu sai", false); return end
        applyMenuColor(col)
        cb("✔ menu = #" .. up, true)
    end)

    local divl = Instance.new("Frame", colorSection)
    divl.Size = UDim2.new(1, 0, 0, 1); divl.LayoutOrder = 5
    divl.BackgroundColor3 = Color3.fromRGB(40, 55, 80); divl.BorderSizePixel = 0

    local floatLbl = Instance.new("TextLabel", colorSection)
    floatLbl.Size = UDim2.new(1, 0, 0, 16); floatLbl.LayoutOrder = 6
    floatLbl.BackgroundTransparency = 1; floatLbl.Text = "NÚT NỔI"
    floatLbl.TextColor3 = Color3.fromRGB(255, 200, 80); floatLbl.TextSize = 10
    floatLbl.Font = Enum.Font.GothamBold; floatLbl.TextXAlignment = Enum.TextXAlignment.Left

    local floatRow = Instance.new("Frame", colorSection)
    floatRow.Size = UDim2.new(1, 0, 0, 30); floatRow.LayoutOrder = 7; floatRow.BackgroundTransparency = 1
    local frl = Instance.new("UIListLayout", floatRow)
    frl.FillDirection = Enum.FillDirection.Horizontal; frl.Padding = UDim.new(0, 4)
    for _, c in ipairs(presetColors) do
        local sw = Instance.new("TextButton", floatRow)
        sw.Size = UDim2.new(0, 26, 1, 0); sw.BackgroundColor3 = c; sw.Text = ""
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 6)
        sw.MouseButton1Click:Connect(function() applyFloatColor(c) end)
    end
    local floatRainbowSw = Instance.new("TextButton", floatRow)
    floatRainbowSw.Size = UDim2.new(0, 26, 1, 0); floatRainbowSw.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
    floatRainbowSw.Text = "🌈"; floatRainbowSw.TextSize = 14; floatRainbowSw.Font = Enum.Font.GothamBold
    floatRainbowSw.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", floatRainbowSw).CornerRadius = UDim.new(0, 6)
    floatRainbowSw.MouseButton1Click:Connect(function() applyFloatRainbow() end)

    makeInput(colorSection, 8, "Mã LED", "#FF00AA", "ÁP DỤNG", Color3.fromRGB(0, 150, 120), function(txt, cb)
        local col, up = parseHex(txt)
        if not col then cb("❌ hex sai", false); return end
        applyFloatColor(col)
        cb("✔ LED = #" .. up, true)
    end)

    -- SECTION 2: TEN HIEN THI
    local nameSection = makeSection(2, "👤 Tên hiển thị", false)
    makeToggle(nameSection, 1, false, "👤 ẨN TÊN: BẬT", "👤 ẨN TÊN: TẮT",
        Color3.fromRGB(120, 80, 200), Color3.fromRGB(60, 60, 70),
        function(v) hideNameOn = v; if v then hideNameTags() else showNameTags() end end)
    makeInput(nameSection, 2, "Tên mới", "Nhập tên", "ĐỔI TÊN", Color3.fromRGB(120, 80, 200), function(txt, cb)
        if txt == "" then cb("❌ nhập tên trước", false); return end
        customName = txt; applyCustomName(); cb("✔ đã đổi tên", true)
    end)

    -- SECTION 3: HIEU NANG
    local perfSection = makeSection(3, "⚡ Hiệu năng", false)
    makeToggle(perfSection, 1, false, "⚡ TỐI ƯU FPS: BẬT", "⚡ TỐI ƯU FPS: TẮT",
        Color3.fromRGB(40, 110, 180), Color3.fromRGB(60, 60, 70), function(v)
        optFPS = v
        if v then
            pcall(function() Lighting.GlobalShadows = false end); bloomSet(false); sunSet(false)
            pcall(function() workspace.StreamingEnabled = true end); setQualityLevel(4)
        else
            pcall(function() Lighting.GlobalShadows = true end); pcall(function() Lighting.Brightness = 2 end)
            bloomSet(true, 0.4, 0.8); setQualityLevel(nil)
        end
    end)
    makeToggle(perfSection, 2, false, "🎨 CHẤT LƯỢNG CAO: BẬT", "🎨 CHẤT LƯỢNG CAO: TẮT",
        Color3.fromRGB(160, 100, 200), Color3.fromRGB(60, 60, 70), function(v)
        if v then
            pcall(function() Lighting.GlobalShadows = true end); pcall(function() Lighting.Brightness = 3 end)
            bloomSet(true, 0.6, 0.7); sunSet(true, 0.3); setQualityLevel(10)
        else bloomSet(true, 0.4, 0.8); sunSet(false); setQualityLevel(nil) end
    end)
    makeToggle(perfSection, 3, false, "📊 FPS/PING: BẬT", "📊 FPS/PING: TẮT",
        Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70),
        function(v) perfOn = v; perfFrame.Visible = v end)
    makeToggle(perfSection, 4, false, "🔒 KHÓA VỊ TRÍ: BẬT", "🔒 KHÓA VỊ TRÍ: TẮT",
        Color3.fromRGB(180, 120, 40), Color3.fromRGB(60, 60, 70),
        function(v) perfLocked = v; perfFrame.Draggable = not v end)

    -- SECTION 4: SERVER
    local serverSection = makeSection(4, "🔄 Server", false)
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local function fetchServers()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok then return nil end
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or not data or not data.data then return nil end
        return data.data
    end
    local btnHop = Instance.new("TextButton", serverSection)
    btnHop.Size = UDim2.new(1, 0, 0, 28); btnHop.LayoutOrder = 1
    btnHop.BackgroundColor3 = Color3.fromRGB(40, 90, 140); btnHop.Text = "🎲 SERVER HOP"
    btnHop.TextColor3 = Color3.new(1,1,1); btnHop.TextSize = 10; btnHop.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnHop).CornerRadius = UDim.new(0, 7)
    local btnSmall = Instance.new("TextButton", serverSection)
    btnSmall.Size = UDim2.new(1, 0, 0, 28); btnSmall.LayoutOrder = 2
    btnSmall.BackgroundColor3 = Color3.fromRGB(40, 120, 90); btnSmall.Text = "🐜 SMALL SERVER"
    btnSmall.TextColor3 = Color3.new(1,1,1); btnSmall.TextSize = 10; btnSmall.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnSmall).CornerRadius = UDim.new(0, 7)
    local btnRejoin = Instance.new("TextButton", serverSection)
    btnRejoin.Size = UDim2.new(1, 0, 0, 28); btnRejoin.LayoutOrder = 3
    btnRejoin.BackgroundColor3 = Color3.fromRGB(140, 80, 40); btnRejoin.Text = "🔁 REJOIN"
    btnRejoin.TextColor3 = Color3.new(1,1,1); btnRejoin.TextSize = 10; btnRejoin.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnRejoin).CornerRadius = UDim.new(0, 7)
    btnHop.MouseButton1Click:Connect(function()
        local ss = fetchServers(); if not ss then return end
        for _, s in ipairs(ss) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player) end); return
            end
        end
    end)
    btnSmall.MouseButton1Click:Connect(function()
        local ss = fetchServers(); if not ss then return end
        local best
        for _, s in ipairs(ss) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                if not best or s.playing < best.playing then best = s end
            end
        end
        if best then pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, player) end) end
    end)
    btnRejoin.MouseButton1Click:Connect(function()
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    end)

    -- SECTION 5: AUTO REJOIN
    local rejoinSection = makeSection(5, "🤖 Auto Rejoin", false)
    local rejoinNote = Instance.new("TextLabel", rejoinSection)
    rejoinNote.Size = UDim2.new(1, 0, 0, 28); rejoinNote.LayoutOrder = 1
    rejoinNote.BackgroundTransparency = 1
    rejoinNote.Text = "Auto Execute: tự load script khi vào game\nAuto Rejoin: tự vào lại khi bị kick\n2 chức năng độc lập"
    rejoinNote.TextColor3 = Color3.fromRGB(160, 170, 190); rejoinNote.TextSize = 9
    rejoinNote.Font = Enum.Font.GothamMedium; rejoinNote.TextXAlignment = Enum.TextXAlignment.Left
    rejoinNote.TextYAlignment = Enum.TextYAlignment.Top; rejoinNote.TextWrapped = true
    makeToggle(rejoinSection, 2, readFlag("autoExecute.txt"), "🔄 AUTO EXECUTE: BẬT", "🔄 AUTO EXECUTE: TẮT",
        Color3.fromRGB(120, 80, 200), Color3.fromRGB(60, 60, 70), function(v)
        if writefile then pcall(writefile, "autoExecute.txt", v and "1" or "0") end
        if v and queue_on_teleport then
            pcall(queue_on_teleport, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()]])
        end
    end)
    makeToggle(rejoinSection, 3, readFlag("autoRejoin.txt"), "🔁 AUTO REJOIN: BẬT", "🔁 AUTO REJOIN: TẮT",
        Color3.fromRGB(140, 80, 40), Color3.fromRGB(60, 60, 70), function(v)
        if writefile then pcall(writefile, "autoRejoin.txt", v and "1" or "0") end
    end)

    -- SECTION 6: ANTI-AFK
    local afkSection = makeSection(6, "🛡️ Anti-AFK", false)
    makeToggle(afkSection, 1, true, "🛡️ ANTI-AFK: BẬT", "🛡️ ANTI-AFK: TẮT",
        Color3.fromRGB(46, 140, 67), Color3.fromRGB(60, 60, 70), function(v) antiAfk = v end)

    selectPage("TUNER")

    local function applyFarmAvailability()
        local ok = checkFarmOK()
        farmOK = ok
        if ok then
            farmNote.Text = ""
            farmSwitch.track.Active = true
            farmSwitch.track.AutoButtonColor = true
            if not farmSwitch.isOn() then
                farmSwitch.track.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                farmSwitch.knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
            end
        else
            farmNote.Text = "⚠ Chỉ hoạt động ở Surakarta"
            farmSwitch.track.Active = false
            farmSwitch.track.AutoButtonColor = false
            farmSwitch.track.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
            farmSwitch.knob.BackgroundColor3 = Color3.fromRGB(120, 120, 125)
        end
    end
    applyFarmAvailability()
    task.spawn(function()
        while true do
            task.wait(2)
            local ok = checkFarmOK()
            if ok ~= farmOK then applyFarmAvailability() end
        end
    end)

    -- FIX: KHONG tu dong hien menu khi bat script
    HubFrame.Visible = false
end

-- ============================================================
-- KHOI 2: AUTO T
-- ============================================================
do
    local autoTActive = false
    ToggleFloatMenuBtn.MouseButton1Click:Connect(function()
        showAutoTFloat = not showAutoTFloat
        AutoTFloatingBtn.Visible = showAutoTFloat
        if showAutoTFloat then
            ToggleFloatMenuBtn.Text = "🕹️ NÚT NỔI AUTO T: ĐANG BẬT"
            ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        else
            ToggleFloatMenuBtn.Text = "🕹️ NÚT NỔI AUTO T: ĐANG TẮT"
            ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            autoTActive = false
            AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game) end)
        end
    end)
    AutoTFloatingBtn.MouseButton1Click:Connect(function()
        autoTActive = not autoTActive
        if autoTActive then
            AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game) end)
        else
            AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game) end)
        end
    end)
    RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local s = h and h.SeatPart
        local isInVehicle = (s and (s:IsA("VehicleSeat") or s:IsA("Seat")))
        if autoTActive then
            if isInVehicle then
                pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game) end)
            else
                autoTActive = false
                AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game) end)
            end
        end
    end)
end

-- ============================================================
-- KHOI 3: DAN AO
-- ============================================================
do
    local currentVehicle, selectedPart, selectedParentContainer = nil, nil, nil
    local modeActive = false
    local originalParents, originalTransparencies, originalColors, originalMaterials, originalDecalTransparencies = {}, {}, {}, {}, {}
    local modelPartsList, currentIndex, lastSelectedPart = {}, 1, nil

    ControlPanel = Instance.new("Frame", ScreenGui)
    ControlPanel.Name = "ControlPanel"
    ControlPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    ControlPanel.Position = UDim2.new(0.5, 190, 0.5, -175)
    ControlPanel.Size = UDim2.new(0, 280, 0, 350)
    ControlPanel.Visible = false; ControlPanel.Active = true; ControlPanel.Draggable = true; ControlPanel.ZIndex = 9
    Instance.new("UICorner", ControlPanel).CornerRadius = UDim.new(0, 12)
    local ControlStroke = Instance.new("UIStroke", ControlPanel)
    ControlStroke.Color = Color3.fromRGB(0, 230, 180); ControlStroke.Thickness = 1.5
    local ControlTitle = Instance.new("TextLabel", ControlPanel)
    ControlTitle.BackgroundTransparency = 1; ControlTitle.Position = UDim2.new(0, 15, 0, 10)
    ControlTitle.Size = UDim2.new(1, -30, 0, 25); ControlTitle.Font = Enum.Font.GothamBold
    ControlTitle.Text = "🚗 QUẢN LÝ & THÁO DÀN ÁO"; ControlTitle.TextColor3 = Color3.fromRGB(0, 230, 180)
    ControlTitle.TextSize = 12; ControlTitle.TextXAlignment = Enum.TextXAlignment.Left
    makeHeaderDraggable(ControlTitle, ControlPanel)
    local ToggleModeBtn = Instance.new("TextButton", ControlPanel)
    ToggleModeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    ToggleModeBtn.Position = UDim2.new(0, 15, 0, 42); ToggleModeBtn.Size = UDim2.new(1, -30, 0, 32)
    ToggleModeBtn.Font = Enum.Font.GothamBold; ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"
    ToggleModeBtn.TextColor3 = Color3.fromRGB(255, 80, 80); ToggleModeBtn.TextSize = 11
    Instance.new("UICorner", ToggleModeBtn).CornerRadius = UDim.new(0, 8)
    local StatusText = Instance.new("TextLabel", ControlPanel)
    StatusText.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    StatusText.Position = UDim2.new(0, 15, 0, 80); StatusText.Size = UDim2.new(1, -30, 0, 50)
    StatusText.Font = Enum.Font.Gotham; StatusText.Text = " Part: Chưa chọn\nCụm: Chưa chọn\nSố part trong cụm: 0"
    StatusText.TextColor3 = Color3.fromRGB(220, 220, 220); StatusText.TextSize = 10
    StatusText.TextXAlignment = Enum.TextXAlignment.Left; StatusText.TextYAlignment = Enum.TextYAlignment.Center
    Instance.new("UICorner", StatusText).CornerRadius = UDim.new(0, 6)
    local function mkBtn(name, y, x, w, col)
        local b = Instance.new("TextButton", ControlPanel)
        b.BackgroundColor3 = col or Color3.fromRGB(45, 45, 55)
        b.Position = UDim2.new(0, x, 0, y); b.Size = UDim2.new(0, w, 0, 30)
        b.Font = Enum.Font.GothamBold; b.Name = name; b.Text = name
        b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 10
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        return b
    end
    local HidePartBtn = mkBtn("Tháo Part Này", 140, 15, 120, Color3.fromRGB(50, 50, 65))
    local HideCompBtn = mkBtn("Tháo Cả Cụm", 140, 145, 120, Color3.fromRGB(50, 50, 65))
    local PrevPartBtn = mkBtn("◀ Mảnh Trước", 176, 15, 120, Color3.fromRGB(40, 90, 110))
    local NextPartBtn = mkBtn("Mảnh Sau ▶", 176, 145, 120, Color3.fromRGB(40, 90, 110))
    local DeselectBtn = mkBtn("Bỏ Chọn", 212, 15, 120, Color3.fromRGB(50, 50, 65))
    local ScanBtn = Instance.new("TextButton", ControlPanel)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); ScanBtn.Position = UDim2.new(0, 145, 0, 212)
    ScanBtn.Size = UDim2.new(0, 120, 0, 30); ScanBtn.Font = Enum.Font.GothamBold
    ScanBtn.Text = "Quét Lại Xe"; ScanBtn.TextColor3 = Color3.fromRGB(255, 200, 0); ScanBtn.TextSize = 10
    Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)
    local RestoreBtn = mkBtn("Khôi Phục Toàn Bộ", 248, 15, 250, Color3.fromRGB(160, 40, 40))
    BodyManagerFloatingBtn.MouseButton1Click:Connect(function()
        ControlPanel.Visible = not ControlPanel.Visible
        if ControlPanel.Visible then BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 100)
        else BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15) end
    end)
    local CloseControlBtn = Instance.new("TextButton", ControlPanel)
    CloseControlBtn.Size = UDim2.new(0, 24, 0, 24); CloseControlBtn.Position = UDim2.new(1, -28, 0, 6)
    CloseControlBtn.BackgroundTransparency = 1; CloseControlBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    CloseControlBtn.Text = "✕"; CloseControlBtn.TextSize = 13; CloseControlBtn.Font = Enum.Font.GothamBold
    CloseControlBtn.MouseButton1Click:Connect(function()
        ControlPanel.Visible = false; BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    end)
    local SelectionBoxObj = Instance.new("SelectionBox")
    SelectionBoxObj.Color3 = Color3.fromRGB(0, 230, 180); SelectionBoxObj.LineThickness = 0.05; SelectionBoxObj.Adornee = nil
    pcall(function() SelectionBoxObj.Parent = CoreGui end)
    if SelectionBoxObj.Parent ~= CoreGui then SelectionBoxObj.Parent = ScreenGui end
    ScanBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then
            ScanBtn.Text = "Không tìm thấy nhân vật!"; task.wait(1.5); ScanBtn.Text = "Quét Lại Xe"; return
        end
        local humanoid = char.Humanoid; local seatPart = humanoid.SeatPart
        if not seatPart then ScanBtn.Text = "Hãy ngồi lên xe!"; task.wait(1.5); ScanBtn.Text = "Quét Lại Xe"; return end
        local model = seatPart.Parent
        while model and model ~= workspace and not model:FindFirstChildOfClass("Humanoid") do
            if model.Parent == workspace then break end
            model = model.Parent
        end
        if model then currentVehicle = model; ScanBtn.Text = "Quét Thành Công!"
            task.wait(1.5); ScanBtn.Text = "Quét Lại Xe"
        else ScanBtn.Text = "Không nhận diện!"; task.wait(1.5); ScanBtn.Text = "Quét Lại Xe" end
    end)
    local function restorePartAppearance()
        if lastSelectedPart and originalTransparencies[lastSelectedPart] then
            lastSelectedPart.Transparency = originalTransparencies[lastSelectedPart]
            lastSelectedPart.Color = originalColors[lastSelectedPart]
            lastSelectedPart.Material = originalMaterials[lastSelectedPart]
            originalTransparencies[lastSelectedPart] = nil; originalColors[lastSelectedPart] = nil
            originalMaterials[lastSelectedPart] = nil
        end
        for d, t in pairs(originalDecalTransparencies) do if d and d.Parent then d.Transparency = t end end
        originalDecalTransparencies = {}; SelectionBoxObj.Adornee = nil
    end
    ToggleModeBtn.MouseButton1Click:Connect(function()
        if not currentVehicle then ToggleModeBtn.Text = "Hãy Quét Xe Trước!"
            task.wait(1.5); ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"; return end
        modeActive = not modeActive
        if modeActive then
            ToggleModeBtn.Text = "Chế độ Soi & Tháo: BẬT"; ToggleModeBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"; ToggleModeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            restorePartAppearance(); selectedPart = nil; selectedParentContainer = nil
            modelPartsList = {}; lastSelectedPart = nil
        end
    end)
    local function updateSelectionInfo()
        restorePartAppearance()
        if not selectedPart or not selectedPart.Parent or not currentVehicle then
            StatusText.Text = " Part: Chưa chọn\nCụm: Chưa chọn\nSố part trong cụm: 0"
            lastSelectedPart = nil; return
        end
        lastSelectedPart = selectedPart
        originalTransparencies[selectedPart] = selectedPart.Transparency
        originalColors[selectedPart] = selectedPart.Color
        originalMaterials[selectedPart] = selectedPart.Material
        selectedPart.Transparency = 0.15; selectedPart.Color = Color3.fromRGB(0, 220, 180)
        selectedPart.Material = Enum.Material.Neon
        for _, d in ipairs(selectedPart:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("Texture") then
                originalDecalTransparencies[d] = d.Transparency; d.Transparency = 0
            end
        end
        local cn = selectedParentContainer and selectedParentContainer.Name or "Không rõ"
        StatusText.Text = string.format(" Part: %s\nCụm: %s\nSố part trong cụm: %d", selectedPart.Name, cn, #modelPartsList)
        SelectionBoxObj.Adornee = selectedPart
    end
    UserInputService.InputBegan:Connect(function(input, gp)
        if not modeActive or not currentVehicle then return end
        if gp then return end
        local sp = nil
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sp = UserInputService:GetMouseLocation()
        elseif input.UserInputType == Enum.UserInputType.Touch then sp = Vector2.new(input.Position.X, input.Position.Y) end
        if sp then
            local ray = camera:ViewportPointToRay(sp.X, sp.Y)
            local org, dir = ray.Origin, ray.Direction * 600
            local target = nil
            for i = 1, 8 do
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Include
                rp.FilterDescendantsInstances = {currentVehicle}; rp.IgnoreWater = true
                local res = workspace:Raycast(org, dir, rp)
                if res and res.Instance then
                    local hit = res.Instance; local hn = hit.Name:lower()
                    if hit.Parent == nil or hn:find("weight") or hn:find("hitbox") or hn:find("collider") or hn:find("chassis") or hn:find("seat") then
                        org = res.Position + (ray.Direction.Unit * 0.2)
                        dir = (ray.Origin + ray.Direction * 600) - org
                    else target = hit; break end
                else break end
            end
            if target and target:IsA("BasePart") then
                selectedPart = target; selectedParentContainer = target.Parent; modelPartsList = {}
                if selectedParentContainer and (selectedParentContainer:IsA("Model") or selectedParentContainer:IsA("Folder")) then
                    for _, ch in ipairs(selectedParentContainer:GetDescendants()) do
                        if ch:IsA("BasePart") then table.insert(modelPartsList, ch) end
                    end
                else table.insert(modelPartsList, selectedPart) end
                for i, p in ipairs(modelPartsList) do if p == target then currentIndex = i; break end end
                updateSelectionInfo()
            end
        end
    end)
    local function hideSinglePart(part)
        if not part or not part:IsA("BasePart") then return end
        if part == lastSelectedPart then
            originalTransparencies[part] = nil; originalColors[part] = nil; originalMaterials[part] = nil
            lastSelectedPart = nil
        end
        for _, d in ipairs(part:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("Texture") then originalDecalTransparencies[d] = nil end
        end
        if not originalParents[part] then originalParents[part] = part.Parent end
        part.Parent = nil; SelectionBoxObj.Adornee = nil
    end
    HidePartBtn.MouseButton1Click:Connect(function()
        if selectedPart and selectedPart:IsA("BasePart") then
            hideSinglePart(selectedPart)
            local found = false
            if #modelPartsList > 0 then
                for _ = 1, #modelPartsList do
                    currentIndex = currentIndex % #modelPartsList + 1
                    local p = modelPartsList[currentIndex]
                    if p and p.Parent ~= nil then selectedPart = p; found = true; break end
                end
            end
            if found then updateSelectionInfo()
            else restorePartAppearance(); selectedPart = nil; selectedParentContainer = nil
                modelPartsList = {}; lastSelectedPart = nil; updateSelectionInfo() end
        end
    end)
    HideCompBtn.MouseButton1Click:Connect(function()
        if selectedParentContainer then
            for _, ch in ipairs(selectedParentContainer:GetDescendants()) do
                if ch:IsA("BasePart") then hideSinglePart(ch) end
            end
            restorePartAppearance(); selectedPart = nil; selectedParentContainer = nil
            modelPartsList = {}; lastSelectedPart = nil; updateSelectionInfo()
        end
    end)
    NextPartBtn.MouseButton1Click:Connect(function()
        if #modelPartsList > 0 then
            local found = false
            for _ = 1, #modelPartsList do
                currentIndex = currentIndex % #modelPartsList + 1
                local p = modelPartsList[currentIndex]
                if p and p.Parent ~= nil then selectedPart = p; found = true; break end
            end
            if found then updateSelectionInfo() else selectedPart = nil; SelectionBoxObj.Adornee = nil end
        end
    end)
    PrevPartBtn.MouseButton1Click:Connect(function()
        if #modelPartsList > 0 then
            local found = false
            for _ = 1, #modelPartsList do
                currentIndex = currentIndex - 1
                if currentIndex < 1 then currentIndex = #modelPartsList end
                local p = modelPartsList[currentIndex]
                if p and p.Parent ~= nil then selectedPart = p; found = true; break end
            end
            if found then updateSelectionInfo() else selectedPart = nil; SelectionBoxObj.Adornee = nil end
        end
    end)
    DeselectBtn.MouseButton1Click:Connect(function()
        restorePartAppearance(); selectedPart = nil; selectedParentContainer = nil
        modelPartsList = {}; lastSelectedPart = nil; updateSelectionInfo()
    end)
    RestoreBtn.MouseButton1Click:Connect(function()
        for p, op in pairs(originalParents) do if p and op and op.Parent then p.Parent = op end end
        originalParents = {}; restorePartAppearance()
        selectedPart = nil; selectedParentContainer = nil; modelPartsList = {}; lastSelectedPart = nil
        updateSelectionInfo()
    end)
end

-- ============================================================
-- KHOI 4: FREECAM
-- ============================================================
do
    local function addStroke(par, col, th)
        local s = Instance.new("UIStroke", par); s.Color = col or Color3.fromRGB(60, 60, 75); s.Thickness = th or 1.5
        return s
    end
    freecamMenuFrame = Instance.new("Frame", ScreenGui)
    freecamMenuFrame.Size = UDim2.new(0, 280, 0, 310); freecamMenuFrame.Position = UDim2.new(0.5, -140, 0.5, -155)
    freecamMenuFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 21); freecamMenuFrame.BackgroundTransparency = 0.12
    freecamMenuFrame.Visible = false; freecamMenuFrame.ZIndex = 15
    Instance.new("UICorner", freecamMenuFrame).CornerRadius = UDim.new(0, 14)
    addStroke(freecamMenuFrame, Color3.fromRGB(70, 70, 95), 1.5)
    local freecamMenuTitle = Instance.new("TextLabel", freecamMenuFrame)
    freecamMenuTitle.Size = UDim2.new(1, 0, 0, 45); freecamMenuTitle.BackgroundTransparency = 1
    freecamMenuTitle.Text = "Freecam Cinematic"; freecamMenuTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
    freecamMenuTitle.TextSize = 15; freecamMenuTitle.Font = Enum.Font.GothamBold; freecamMenuTitle.ZIndex = 16
    local function mkBtn(y, txt, col)
        local b = Instance.new("TextButton", freecamMenuFrame)
        b.Size = UDim2.new(0.88, 0, 0, 36); b.Position = UDim2.new(0.06, 0, 0, y)
        b.BackgroundColor3 = col; b.Text = txt; b.TextColor3 = Color3.fromRGB(235, 235, 245)
        b.TextSize = 13; b.Font = Enum.Font.GothamBold; b.ZIndex = 16
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        addStroke(b, Color3.fromRGB(80, 80, 100), 0.8)
        return b
    end
    local freecamToggleBtn = mkBtn(45, "Freecam: OFF", Color3.fromRGB(45, 45, 58))
    local hideAllBtn = mkBtn(90, "Ẩn Giao Diện: OFF", Color3.fromRGB(50, 50, 68))
    local speedLabel = Instance.new("TextLabel", freecamMenuFrame)
    speedLabel.Size = UDim2.new(0.88, 0, 0, 22); speedLabel.Position = UDim2.new(0.06, 0, 0, 135)
    speedLabel.BackgroundTransparency = 1; speedLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    speedLabel.TextSize = 12; speedLabel.Font = Enum.Font.GothamBold; speedLabel.Text = "Tốc độ di chuyển: 25.0"; speedLabel.ZIndex = 16
    local speedIncBtn = mkBtn(160, "Tăng Tốc (+)", Color3.fromRGB(50, 50, 68))
    speedIncBtn.Size = UDim2.new(0.42, 0, 0, 32); speedIncBtn.Position = UDim2.new(0.06, 0, 0, 160)
    local speedDecBtn = mkBtn(160, "Giảm Tốc (-)", Color3.fromRGB(50, 50, 68))
    speedDecBtn.Size = UDim2.new(0.42, 0, 0, 32); speedDecBtn.Position = UDim2.new(0.52, 0, 0, 160)
    local rotLabel = Instance.new("TextLabel", freecamMenuFrame)
    rotLabel.Size = UDim2.new(0.88, 0, 0, 22); rotLabel.Position = UDim2.new(0.06, 0, 0, 200)
    rotLabel.BackgroundTransparency = 1; rotLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    rotLabel.TextSize = 12; rotLabel.Font = Enum.Font.GothamBold; rotLabel.Text = "Tốc độ xoay: 1.0x"; rotLabel.ZIndex = 16
    local rotIncBtn = mkBtn(225, "Xoay Nhanh (+)", Color3.fromRGB(50, 50, 68))
    rotIncBtn.Size = UDim2.new(0.42, 0, 0, 32); rotIncBtn.Position = UDim2.new(0.06, 0, 0, 225)
    local rotDecBtn = mkBtn(225, "Xoay Chậm (-)", Color3.fromRGB(50, 50, 68))
    rotDecBtn.Size = UDim2.new(0.42, 0, 0, 32); rotDecBtn.Position = UDim2.new(0.52, 0, 0, 225)
    hideFloatBtn = Instance.new("TextButton", ScreenGui)
    hideFloatBtn.Size = UDim2.new(0, 52, 0, 52); hideFloatBtn.Position = UDim2.new(0, 80, 0, 150)
    hideFloatBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28); hideFloatBtn.BackgroundTransparency = 0.2
    hideFloatBtn.Text = "👁️"; hideFloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255); hideFloatBtn.TextSize = 22
    hideFloatBtn.Font = Enum.Font.GothamBold; hideFloatBtn.ZIndex = 10
    Instance.new("UICorner", hideFloatBtn).CornerRadius = UDim.new(0, 7)
    addStroke(hideFloatBtn, Color3.fromRGB(80, 80, 110), 2)
    hideFloatBtn.Visible = false
    local controlFrame = Instance.new("Frame", ScreenGui)
    controlFrame.Size = UDim2.new(0, 205, 0, 195); controlFrame.Position = UDim2.new(0, 20, 1, -200)
    controlFrame.BackgroundTransparency = 1; controlFrame.Visible = false; controlFrame.ZIndex = 1
    local controlButtons = {}
    local function mkPad(txt, size, pos)
        local b = Instance.new("TextButton", controlFrame)
        b.Size = size; b.Position = pos; b.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        b.BackgroundTransparency = 0.35; b.Text = txt; b.TextColor3 = Color3.fromRGB(240, 240, 250)
        b.TextSize = 15; b.Font = Enum.Font.GothamBold; b.ZIndex = 2
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        addStroke(b, Color3.fromRGB(70, 70, 95), 1)
        table.insert(controlButtons, b); return b
    end
    local btnW = mkPad("▲", UDim2.new(0, 44, 0, 44), UDim2.new(0, 48, 0, 0))
    local btnS = mkPad("▼", UDim2.new(0, 44, 0, 44), UDim2.new(0, 48, 0, 96))
    local btnA = mkPad("◀", UDim2.new(0, 44, 0, 44), UDim2.new(0, 0, 0, 48))
    local btnD = mkPad("▶", UDim2.new(0, 44, 0, 44), UDim2.new(0, 96, 0, 48))
    local btnUp = mkPad("+", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 0))
    local btnDown = mkPad("-", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 48))
    local btnZoomIn = mkPad("🔍+", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 100))
    local btnZoomOut = mkPad("🔍-", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 148))
    do
        local dg, ds, sp
        hideFloatBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dg = true; ds = i.Position; sp = hideFloatBtn.Position end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                hideFloatBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = false end
        end)
    end
    do
        local dg, ds, sp
        freecamMenuTitle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dg = true; ds = i.Position; sp = freecamMenuFrame.Position end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                freecamMenuFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = false end
        end)
    end
    FreecamFloatingBtn.MouseButton1Click:Connect(function()
        freecamMenuFrame.Visible = not freecamMenuFrame.Visible
    end)
    local function setRobloxTouchGuiTransparency(t)
        local tg = LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
        if tg then
            for _, d in ipairs(tg:GetDescendants()) do
                if d:IsA("ImageLabel") or d:IsA("ImageButton") then d.ImageTransparency = t
                elseif d:IsA("TextLabel") or d:IsA("TextButton") then d.TextTransparency = t end
            end
        end
    end
    local hideModeActive, isUiHidden = false, false
    hideAllBtn.MouseButton1Click:Connect(function()
        hideModeActive = not hideModeActive
        if hideModeActive then
            hideAllBtn.Text = "Ẩn Giao Diện: ON"; hideAllBtn.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
            hideFloatBtn.Visible = true; hideFloatBtn.BackgroundTransparency = 0.2; hideFloatBtn.TextTransparency = 0
            local s = hideFloatBtn:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 0 end
            freecamMenuFrame.Visible = false
        else
            hideAllBtn.Text = "Ẩn Giao Diện: OFF"; hideAllBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
            hideFloatBtn.Visible = false; isUiHidden = false; FreecamFloatingBtn.Visible = true
            for _, b in ipairs(controlButtons) do
                b.BackgroundTransparency = 0.35; b.TextTransparency = 0
                local s = b:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 0 end
            end
            setRobloxTouchGuiTransparency(0)
        end
    end)
    hideFloatBtn.MouseButton1Click:Connect(function()
        isUiHidden = not isUiHidden
        if isUiHidden then
            FreecamFloatingBtn.Visible = false
            for _, b in ipairs(controlButtons) do
                b.BackgroundTransparency = 1; b.TextTransparency = 1
                local s = b:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 1 end
            end
            hideFloatBtn.BackgroundTransparency = 1; hideFloatBtn.TextTransparency = 1
            local s = hideFloatBtn:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 1 end
            setRobloxTouchGuiTransparency(1)
        else
            FreecamFloatingBtn.Visible = true
            for _, b in ipairs(controlButtons) do
                b.BackgroundTransparency = 0.35; b.TextTransparency = 0
                local s = b:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 0 end
            end
            hideFloatBtn.BackgroundTransparency = 0.2; hideFloatBtn.TextTransparency = 0
            local s = hideFloatBtn:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 0 end
            setRobloxTouchGuiTransparency(0)
        end
    end)
    local speed = 25.0
    speedIncBtn.MouseButton1Click:Connect(function()
        local st = speed < 2 and 0.1 or (speed < 10 and 1 or 5)
        speed = math.clamp(speed + st, 0.3, 150)
        speedLabel.Text = string.format("Tốc độ di chuyển: %.1f", speed)
    end)
    speedDecBtn.MouseButton1Click:Connect(function()
        local st = speed <= 2 and 0.1 or (speed <= 10 and 1 or 5)
        speed = math.clamp(speed - st, 0.3, 150)
        speedLabel.Text = string.format("Tốc độ di chuyển: %.1f", speed)
    end)
    local rotSens = 1.0
    rotIncBtn.MouseButton1Click:Connect(function()
        rotSens = math.clamp(rotSens + 0.1, 0.05, 3.0)
        rotLabel.Text = string.format("Tốc độ xoay: %.2fx", rotSens)
    end)
    rotDecBtn.MouseButton1Click:Connect(function()
        rotSens = math.clamp(rotSens - 0.1, 0.05, 3.0)
        rotLabel.Text = string.format("Tốc độ xoay: %.2fx", rotSens)
    end)
    local freecamActive = false
    local camPos = camera.CFrame.Position
    local camAngles = Vector2.new(0, 0)
    local targetCamAngles = Vector2.new(0, 0)
    local currentFOV = camera.FieldOfView
    local moveStates = {W = false, S = false, A = false, D = false, Up = false, Down = false}
    local function bindTouch(btn, key)
        btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then moveStates[key] = true end end)
        btn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then moveStates[key] = false end end)
    end
    bindTouch(btnW, "W"); bindTouch(btnS, "S"); bindTouch(btnA, "A"); bindTouch(btnD, "D")
    bindTouch(btnUp, "Up"); bindTouch(btnDown, "Down")
    local zIn, zOut = false, false
    btnZoomIn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zIn = true end end)
    btnZoomIn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zIn = false end end)
    btnZoomOut.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zOut = true end end)
    btnZoomOut.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zOut = false end end)
    local function toggleFreecam()
        freecamActive = not freecamActive
        if freecamActive then
            camPos = camera.CFrame.Position
            local rx, ry, rz = camera.CFrame:ToOrientation()
            camAngles = Vector2.new(ry, rx); targetCamAngles = camAngles
            currentFOV = camera.FieldOfView; camera.CameraType = Enum.CameraType.Scriptable
            freecamToggleBtn.Text = "Freecam: ON"; freecamToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 50)
            controlFrame.Visible = true; freecamMenuFrame.Visible = false
        else
            camera.CameraType = Enum.CameraType.Custom; camera.FieldOfView = 70
            freecamToggleBtn.Text = "Freecam: OFF"; freecamToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
            controlFrame.Visible = false
        end
    end
    freecamToggleBtn.MouseButton1Click:Connect(toggleFreecam)
    local activeTouch, lastTouchPos = nil, nil
    local function isInside(pt, f)
        if not f.Visible then return false end
        local ap, as = f.AbsolutePosition, f.AbsoluteSize
        return pt.X >= ap.X and pt.X <= ap.X + as.X and pt.Y >= ap.Y and pt.Y <= ap.Y + as.Y
    end
    UserInputService.TouchStarted:Connect(function(touch)
        if not freecamActive then return end
        local pos = touch.Position
        local inUI = isInside(pos, controlFrame) or isInside(pos, freecamMenuFrame)
            or isInside(pos, FreecamFloatingBtn) or isInside(pos, HubFrame) or isInside(pos, ToggleBtn)
            or (hideFloatBtn.Visible and isInside(pos, hideFloatBtn))
        if not inUI and not activeTouch then activeTouch = touch; lastTouchPos = touch.Position end
    end)
    UserInputService.TouchMoved:Connect(function(touch)
        if freecamActive and touch == activeTouch and lastTouchPos then
            local d = touch.Position - lastTouchPos
            targetCamAngles = targetCamAngles - Vector2.new(d.X * 0.004 * rotSens, d.Y * 0.004 * rotSens)
            lastTouchPos = touch.Position
        end
    end)
    UserInputService.TouchEnded:Connect(function(touch)
        if touch == activeTouch then activeTouch = nil; lastTouchPos = nil end
    end)
    RunService.RenderStepped:Connect(function(dt)
        if not freecamActive then return end
        local sf = math.clamp(dt * 16, 0, 1)
        camAngles = camAngles:Lerp(targetCamAngles, sf)
        if zIn then currentFOV = math.clamp(currentFOV - 35 * dt, 10, 120)
        elseif zOut then currentFOV = math.clamp(currentFOV + 35 * dt, 10, 120) end
        camera.FieldOfView = currentFOV
        local mv = Vector3.new()
        if moveStates.W then mv = mv + Vector3.new(0, 0, -1) end
        if moveStates.S then mv = mv + Vector3.new(0, 0, 1) end
        if moveStates.A then mv = mv + Vector3.new(-1, 0, 0) end
        if moveStates.D then mv = mv + Vector3.new(1, 0, 0) end
        if moveStates.Up then mv = mv + Vector3.new(0, 1, 0) end
        if moveStates.Down then mv = mv + Vector3.new(0, -1, 0) end
        local rotCF = CFrame.Angles(0, camAngles.X, 0) * CFrame.Angles(camAngles.Y, 0, 0)
        camPos = camPos + (rotCF * mv) * speed * dt
        camera.CFrame = CFrame.new(camPos) * rotCF
    end)
end

-- ============================================================
-- KHOI 5: OFFICE FARM
-- ============================================================
do
    local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
    local TeamChangeRequest = JobEvents:WaitForChild("TeamChangeRequest", 5)
    local GenerateQuestion = JobEvents:WaitForChild("GenerateQuestion")
    local CorrectAnswer = JobEvents:WaitForChild("CorrectAnswer")
    local AssignPrintJob = JobEvents:WaitForChild("AssignPrintJob")
    local ClearPrintJob = JobEvents:WaitForChild("ClearPrintJob")
    local Computers = workspace:FindFirstChild("Computers")

    local CHAIR_POS = Vector3.new(-5902.42, 2.71, -228.54)
    local PATTERN = { "CHOICE", "QID" }
    local UUID_PAT = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
    local of_phasing, of_activeBV, of_savedCollide = false, nil, {}
    local of_resetUntil, of_pendingQuestion, of_lastKnownQuestion = 0, nil, nil
    local of_questionArrivedAt, of_nextDelay, of_printAssigned = 0, 2.4, nil
    local of_awaitingAck, of_lastFireAt, of_refired = false, 0, false

    local function of_killBV()
        if of_activeBV then
            pcall(function() of_activeBV.Velocity = Vector3.zero end)
            pcall(function() of_activeBV:Destroy() end)
            of_activeBV = nil
        end
        of_phasing = false
    end
    RunService.Stepped:Connect(function()
        local char = player.Character; if not char then return end
        if of_phasing then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then of_savedCollide[p] = true; p.CanCollide = false end
            end
        elseif next(of_savedCollide) then
            for p in pairs(of_savedCollide) do if p.Parent then p.CanCollide = true end end
            table.clear(of_savedCollide)
        end
    end)
    local function of_enableSit(char)
        local h = char and char:FindFirstChildOfClass("Humanoid")
        if h then h:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
    end
    GenerateQuestion.OnClientEvent:Connect(function(...)
        local q = { text = nil, choices = nil, questionID = nil }
        for _, a in ipairs({ ... }) do
            if type(a) == "string" then
                if a:match(UUID_PAT) then if not q.questionID then q.questionID = a end
                elseif not q.text and a:match("%d") and a:match("[=%?]") then q.text = a end
            elseif type(a) == "table" and not q.choices then q.choices = a end
        end
        of_pendingQuestion = q; of_lastKnownQuestion = q; of_questionArrivedAt = os.clock()
        if farmOffice then setStatus("đang giải") end
    end)
    CorrectAnswer.OnClientEvent:Connect(function(status)
        of_awaitingAck = false; of_refired = false
        local s = type(status) == "string" and status:lower() or ""
        if s == "success" then ofAnswers = ofAnswers + 1; refreshStatPanel() end
    end)
    AssignPrintJob.OnClientEvent:Connect(function(n) of_printAssigned = n end)
    ClearPrintJob.OnClientEvent:Connect(function()
        of_printAssigned = nil; ofPrints = ofPrints + 1; refreshStatPanel()
    end)
    local function of_findButton(text)
        local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return nil end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextButton") and d.Text == text and d.Visible and d.AbsoluteSize.X > 0 then return d end
        end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == text and d.Visible and d.AbsoluteSize.X > 0 then
                local p = d.Parent
                if p and (p:IsA("TextButton") or p:IsA("ImageButton")) then return p end
            end
        end
        return nil
    end
    local function of_onScreen(x, y)
        local cam = workspace.CurrentCamera; if not cam then return false end
        local vp = cam.ViewportSize
        return x >= 0 and y >= 0 and x <= vp.X and y <= vp.Y
    end
    local function of_clickButton(btn)
        if pcall(function() firesignal(btn.MouseButton1Click) end) then return 1 end
        if pcall(function() firesignal(btn.Activated) end) then return 2 end
        local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
        local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
        if of_onScreen(x, y) then
            if pcall(function() touchpress(x, y); task.wait(0.06); touchrelease(x, y) end) then return 3 end
        end
        return nil
    end
    local function of_root() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    local function of_humanoid() local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
    local function of_standUp()
        local h = of_humanoid(); if not h then return end
        if not h.Sit and h:GetState() ~= Enum.HumanoidStateType.Seated then return end
        pcall(function() h.Sit = false end); task.wait(0.25)
        if h.Sit then pcall(function() h.Jump = true end); task.wait(0.3) end
        if h.Sit then pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end); task.wait(0.3) end
    end
    local OF_TELE_MIN = 60
    local function of_walkTo(target, sd, timeout, allowSit)
        sd = sd or 3; timeout = timeout or 20
        local deadline = os.clock() + timeout; local reached = false
        pcall(function()
            while os.clock() < deadline and farmOffice do
                local h = of_humanoid(); local hrp = of_root()
                if not h or not hrp then break end
                if h.Sit or h:GetState() == Enum.HumanoidStateType.Seated then
                    if allowSit then reached = true; break else of_standUp() end
                end
                local delta = target - hrp.Position
                local flat = Vector3.new(delta.X, 0, delta.Z)
                if flat.Magnitude <= sd then reached = true; break end
                h:MoveTo(Vector3.new(target.X, hrp.Position.Y, target.Z)); task.wait(0.15)
            end
        end)
        local h = of_humanoid(); local hrp = of_root()
        if h and hrp then h:MoveTo(hrp.Position) end
        return reached
    end
    local function of_teleNear(target, od)
        local hrp = of_root(); if not hrp then return false end
        local dist = (target - hrp.Position).Magnitude
        if dist < OF_TELE_MIN then
            setStatus("đi bộ (" .. math.floor(dist) .. ")")
            return of_walkTo(target, od or 4, 8, false)
        end
        local dir = (target - hrp.Position); dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) end
        dir = dir.Unit
        local landPos = target - dir * (od or 4)
        landPos = Vector3.new(landPos.X, hrp.Position.Y, landPos.Z)
        setStatus("tele xa (" .. math.floor(dist) .. ")")
        hrp.CFrame = CFrame.new(landPos, Vector3.new(target.X, landPos.Y, target.Z))
        task.wait(0.6)
        return true
    end
    local function of_solve(q)
        if not q or type(q.text) ~= "string" or type(q.choices) ~= "table" then return nil end
        local a, op, b = q.text:match("(%-?%d+%.?%d*)%s*([%+%-%*/xX])%s*(%-?%d+%.?%d*)")
        if not a then return nil end
        a, b = tonumber(a), tonumber(b)
        local r
        if op == "+" then r = a + b
        elseif op == "-" then r = a - b
        elseif op == "*" or op:lower() == "x" then r = a * b
        elseif op == "/" then if b == 0 then return nil end; r = a / b end
        for _, c in ipairs(q.choices) do
            local v = tonumber(c.Text)
            if (v and math.abs(v - r) < 1e-6) or tostring(c.Text) == tostring(r) then return c end
        end
        return nil
    end
    local function of_buildArgs(q, c)
        local out = {}
        for i, v in ipairs(PATTERN) do
            if v == "CHOICE" then out[i] = c.ID
            elseif v == "QID" then out[i] = q.questionID
            elseif v == "TEXT" then out[i] = q.text
            else out[i] = v end
        end
        return out
    end
    local function of_fireAnswer(q)
        local choice = of_solve(q)
        if not choice then warn("[farm] khong parse: " .. tostring(q and q.text)); return false end
        local btn = of_findButton(choice.Text)
        local how = btn and of_clickButton(btn) or nil
        if how then pcall(function() CorrectAnswer:FireServer(unpack(of_buildArgs(q, choice))) end) end
        of_awaitingAck = true; of_lastFireAt = os.clock(); return true
    end
    local of_initialTeleDone = false
    local OF_SKIPPED_SEATS = {}
    local function of_findNearestUntriedSeat(pos, radius, tried)
        local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(pos, radius or 350) end)
        if not ok or not parts then return nil end
        local best, bestD = nil, math.huge
        for _, p in ipairs(parts) do
            if (p:IsA("Seat") or p:IsA("VehicleSeat")) and p.Occupant == nil and not tried[p] and not OF_SKIPPED_SEATS[p] then
                local d = (p.Position - pos).Magnitude
                if d < bestD then best, bestD = p, d end
            end
        end
        return best
    end
    local function of_sitAtChair()
        local h = of_humanoid()
        if h and h.Sit then return true end
        local hrp = of_root(); if not hrp then return false end
        if not of_initialTeleDone then
            local dist = (hrp.Position - CHAIR_POS).Magnitude
            if dist > 500 then setStatus("tele lần đầu"); hrp.CFrame = CFrame.new(CHAIR_POS); task.wait(1.0) end
            of_initialTeleDone = true
        end
        h = of_humanoid(); if h and h.Sit then return true end
        local tried = {}
        while farmOffice do
            hrp = of_root(); if not hrp then return false end
            local seat = of_findNearestUntriedSeat(hrp.Position, 350, tried)
            if not seat then
                setStatus("hết ghế — reset"); tried = {}; task.wait(2)
                seat = of_findNearestUntriedSeat(hrp.Position, 350, tried)
                if not seat then setStatus("không có ghế trống"); task.wait(3); return false end
            end
            tried[seat] = true; setStatus("tìm ghế — tele")
            hrp.CFrame = CFrame.new(seat.Position + Vector3.new(0, 2, 0)); task.wait(1.5)
            h = of_humanoid(); if h and h.Sit then return true end
        end
        return false
    end
    local function of_doPrint(name)
        local Comp = workspace:FindFirstChild("Computers"); if not Comp then return end
        local model = Comp:FindFirstChild(name); if not model then return end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        of_standUp(); setStatus("tới máy in"); of_teleNear(part.Position, 4)
        setStatus("chuẩn bị in"); task.wait(0.5); setStatus("đang in")
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        while of_printAssigned and farmOffice do
            local attempt = 0
            while of_printAssigned and farmOffice and attempt < 3 do
                attempt = attempt + 1
                if attempt == 1 then setStatus("đang in") else setStatus("thử in lại") end
                if prompt then
                    pcall(function() prompt:InputHoldBegin() end)
                    local t1 = os.clock()
                    while of_printAssigned and farmOffice and os.clock() - t1 < 3 do task.wait(0.2) end
                    pcall(function() prompt:InputHoldEnd() end)
                end
                local t2 = os.clock()
                while of_printAssigned and farmOffice and os.clock() - t2 < 3 do task.wait(0.2) end
                if not of_printAssigned then break end
            end
            if not of_printAssigned then break end
            setStatus("chờ 5s thử lại")
            local t3 = os.clock()
            while of_printAssigned and farmOffice and os.clock() - t3 < 5 do task.wait(0.2) end
        end
        if not farmOffice then return end
        setStatus("đã in"); task.wait(2); of_sitAtChair()
    end
    local function of_runCycle()
        while farmOffice and os.clock() < of_resetUntil do setStatus("chờ reset nhân vật"); task.wait(0.2) end
        if not farmOffice then return end
        if not of_sitAtChair() then if farmOffice then task.wait(3) end return end
        setStatus("ngồi ghế, chờ câu hỏi")
        local idleStart = os.clock(); local noQuestionStart = os.clock()
        while farmOffice do
            if of_printAssigned then break end
            if of_pendingQuestion then noQuestionStart = os.clock() end
            if of_pendingQuestion and not of_awaitingAck and (os.clock() - of_questionArrivedAt >= of_nextDelay) then
                local q = of_pendingQuestion; of_pendingQuestion = nil
                of_fireAnswer(q); setStatus("đã giải"); of_nextDelay = math.random(20, 28) / 10
                idleStart = os.clock()
            end
            if of_awaitingAck and os.clock() - of_lastFireAt > 8 and not of_refired then
                of_refired = true
                if of_lastKnownQuestion then of_fireAnswer(of_lastKnownQuestion); setStatus("đã giải") end
                idleStart = os.clock()
            end
            if os.clock() - noQuestionStart > 5 and not of_pendingQuestion and not of_awaitingAck then
                setStatus("5s không câu hỏi — đổi ghế")
                local hh = of_humanoid()
                if hh and hh.Sit then OF_SKIPPED_SEATS[hh.SeatPart] = true; pcall(function() hh.Sit = false end); task.wait(0.5) end
                break
            end
            if os.clock() - idleStart > 60 then break end
            task.wait(0.2)
        end
        if farmOffice and of_printAssigned then
            if not Computers then return end
            of_doPrint(of_printAssigned)
        end
    end
    task.spawn(function()
        while true do
            if farmOffice then
                local ok, err = pcall(of_runCycle)
                if not ok then of_killBV(); warn("[farm] LOOP ERR: " .. tostring(err)); task.wait(1) end
            else task.wait(0.3) end
        end
    end)
    local function stopOffice(forceClose)
        if not farmOffice then
            if forceClose then
                if activeMode == "office" then activeMode = nil end
                statPanel.Visible = false; farmSwitch.set(false)
            end
            return
        end
        farmOffice = false; of_killBV(); of_resetUntil = 0
        if writefile then pcall(writefile, "farmState.txt", "0") end
        local h = of_humanoid(); if h and h.Sit then pcall(function() h.Sit = false end) end
        if activeMode == "office" then activeMode = nil end
        statPanel.Visible = false; farmSwitch.set(false); setStatus("tạm nghỉ")
    end
    _G._officeStop = stopOffice
    farmSwitch.track.MouseButton1Click:Connect(function()
        if not farmOK then return end
        if farmOffice then stopOffice(); return end
        if _G._ridegoStop then pcall(_G._ridegoStop, true) end
        of_initialTeleDone = false; of_printAssigned = nil; of_pendingQuestion = nil; of_awaitingAck = false
        of_lastKnownQuestion = nil; of_questionArrivedAt = 0; of_nextDelay = 2.4; of_refired = false
        of_lastFireAt = 0; of_phasing = false; ofAnswers = 0; OF_SKIPPED_SEATS = {}; ofPrints = 0
        refreshStatPanel(); farmOffice = true; activeMode = "office"; farmStart = os.clock()
        TeamChangeRequest:FireServer("Office Worker", 11378976, 0, 0, "Detector")
        of_resetUntil = os.clock() + 5
        if writefile then pcall(writefile, "farmState.txt", "1"); pcall(writefile, "ridegoState.txt", "0") end
        if queue_on_teleport then
            pcall(queue_on_teleport, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()]])
        end
        local char = player.Character; of_enableSit(char)
        farmSwitch.set(true); statPanel.Visible = true; refreshStatPanel(); setStatus("khởi động office")
    end)
end

---- ============================================================
-- KHOI 6: RIDEGO FARM
-- ============================================================
do
    local STEP_DIST = 250; local LAND_OFFSET = 8; local ARRIVE_DIST = 8
    local ORDER_TIMEOUT = 60; local PICKUP_WAIT = 4; local DROP_WAIT = 5
    local ACK_DELAY = 3; local DECEL_DIST = 200; local TICK = 0.05
    local UNDERGROUND_DEPTH = 200; local UNDER_STEP_MAX = 50; local UNDER_DESCEND_STEPS = 12
    local UNDER_STEP_TIME = 0.03; local TRIP_MILESTONE = 10; local FLY_TIMEOUT = 30; local SEAT_DELAY = 0.5

    local enabled = false
    local hasInitOnce = false
    local orderToken, pickupPos, dropPos, pendingFare = nil, nil, nil, 0
    local myCar, selectedCar = nil, ""
    local carList = {}
    local stats = { trips = 0, earn = 0 }
    local curStatus = "◦ TẮT"
    local holdActive, holdBP, holdGyro = false, nil, nil
    local flying, acceptingOrder = false, false
    local farmStartTime, lastMilestone = 0, 0

    local function setRgStatus(s)
        curStatus = s
        if ridegoStatusLbl then ridegoStatusLbl.Text = "📍 " .. s end
    end

    local function resetRidegoState()
        orderToken = nil; pickupPos = nil; dropPos = nil; pendingFare = 0
        myCar = nil; curStatus = "◦ TẮT"; flying = false; acceptingOrder = false
        farmStartTime = 0; lastMilestone = 0; holdActive = false
        if holdBP then pcall(function() holdBP:Destroy() end) holdBP = nil end
        if holdGyro then pcall(function() holdGyro:Destroy() end) holdGyro = nil end
    end

    local lp = LocalPlayer
    local rs = ReplicatedStorage
    local JobEvents = rs:WaitForChild("JobEvents", 10)
    local TeamChangeRequest = JobEvents and JobEvents:WaitForChild("TeamChangeRequest", 5)
    local TaxiAssets = rs:WaitForChild("TaxiAssets", 10)
    local TaxiEvent
    if TaxiAssets then
        local ev = TaxiAssets:WaitForChild("Events", 5)
        if ev then TaxiEvent = ev:FindFirstChild("TaxiEvent", true) end
    end
    local SpawnCarEvents = rs:WaitForChild("SpawnCarEvents", 10)
    local SpawnCarEv
    if SpawnCarEvents then SpawnCarEv = SpawnCarEvents:WaitForChild("SpawnCar", 5) end
    local DealershipEvents = rs:FindFirstChild("DealershipEvents")
    local InitCarData
    if DealershipEvents then InitCarData = DealershipEvents:FindFirstChild("InitializeCarData") end

    local function char() return lp.Character end
    local function root() local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
    local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end

    local function fire(remote, ...)
        if not remote then return false end
        local args = {...}
        return pcall(function() remote:FireServer(table.unpack(args)) end)
    end
    local function formatTime(sec)
        local h = math.floor(sec / 3600); local m = math.floor((sec % 3600) / 60); local s = math.floor(sec % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end
    local function formatMoney(n)
        local s = tostring(math.floor(n or 0))
        local out = ""; local len = #s
        for i = 1, len do
            out = out .. s:sub(i, i)
            if (len - i) > 0 and (len - i) % 3 == 0 then out = out .. " " end
        end
        return out
    end
    local function flatYawCFrame(cf)
        local look = cf.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
        flat = flat.Unit
        local yaw = math.atan2(flat.X, flat.Z)
        return CFrame.Angles(0, yaw, 0)
    end

    if TaxiEvent then
        TaxiEvent.OnClientEvent:Connect(function(action, data)
            if type(data) ~= "table" then return end
            if action == "OrderOffer" then
                if not acceptingOrder then return end
                orderToken = data.Token
                pcall(function() TaxiEvent:FireServer("AcceptOrder", data.Token) end)
            elseif action == "OrderAccepted" then
                pickupPos = data.PickupPos; dropPos = data.DropPos; orderToken = data.Token
                if type(data.Fare) == "number" then pendingFare = data.Fare else pendingFare = 0 end
            end
        end)
    end

    local function scanCars()
        carList = {}
        if not InitCarData then return carList end
        local ok, data = pcall(function() return InitCarData:InvokeServer() end)
        if not ok or type(data) ~= "table" then return carList end
        for _, v in pairs(data) do
            if type(v) == "table" and type(v.Name) == "string" and v.Name ~= "" then
                table.insert(carList, v.Name)
            end
        end
        local seen, uniq = {}, {}
        for _, n in ipairs(carList) do if not seen[n] then seen[n] = true; table.insert(uniq, n) end end
        table.sort(uniq)
        carList = uniq
        ridegoCarList = uniq
        return carList
    end

    local function renderRidegoCars()
        if not ridegoCarListWrap then return end
        for _, c in ipairs(ridegoCarListWrap:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        ridegoCarListWrap.CanvasSize = UDim2.new(0, 0, 0, #carList * 28 + 8)
        if #carList == 0 then
            local lbl = Instance.new("TextLabel", ridegoCarListWrap)
            lbl.Size = UDim2.new(1, -8, 0, 40); lbl.BackgroundTransparency = 1
            lbl.Text = "Chưa quét xe"; lbl.TextColor3 = Color3.fromRGB(150, 160, 180)
            lbl.TextSize = 10; lbl.Font = Enum.Font.GothamMedium
            ridegoCarBtn.Text = "🚗 CHỌN XE (0)"
            return
        end
        for i, name in ipairs(carList) do
            local btn = Instance.new("TextButton", ridegoCarListWrap)
            btn.Size = UDim2.new(1, -8, 0, 24)
            btn.BackgroundColor3 = (name == selectedCar) and Color3.fromRGB(0, 150, 120) or Color3.fromRGB(30, 38, 54)
            btn.Text = "  " .. name
            btn.TextColor3 = (name == selectedCar) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 230, 240)
            btn.TextSize = 10; btn.Font = Enum.Font.Code
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.LayoutOrder = i
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                selectedCar = name
                ridegoSelectedCar = name
                if writefile then pcall(writefile, "ridegoCar.txt", name) end
                if ridegoPickLbl then ridegoPickLbl.Text = "🚗 Xe: " .. name end
                if ridegoStatusCarLbl then ridegoStatusCarLbl.Text = "🚗 Xe: " .. name end
                renderRidegoCars()
                ridegoCarListPanel.Visible = false
                ridegoCarOpen = false
            end)
        end
        ridegoCarBtn.Text = "🚗 CHỌN XE (" .. #carList .. ")"
    end

    ridegoCarBtn.MouseButton1Click:Connect(function()
        if enabled then return end
        ridegoCarOpen = not ridegoCarOpen
        ridegoCarListPanel.Visible = ridegoCarOpen
    end)

    local function findMyCar()
        local c = char()
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.SeatPart then return h.SeatPart:FindFirstAncestorOfClass("Model") end
        end
        local pname = lp.Name:lower()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") and d.Name:lower():find(pname, 1, true) and d:FindFirstChildWhichIsA("VehicleSeat", true) then
                return d
            end
        end
        return nil
    end
    local function makeRayParams()
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        local ign = {}
        local c = char(); if c then table.insert(ign, c) end
        local car = myCar or findMyCar()
        if car then table.insert(ign, car) end
        p.FilterDescendantsInstances = ign
        p.IgnoreWater = true
        return p
    end
    local function floorBelow(pos)
        if not pos then return nil end
        local p = makeRayParams()
        local o = Vector3.new(pos.X, pos.Y + 4, pos.Z)
        local hit = workspace:Raycast(o, Vector3.new(0, -800, 0), p)
        if hit then return hit.Position.Y end
        return nil
    end

    local npcFollowers = {}
    local npcRenderConn = nil
    local function safeRefreshNpc()
        for _, f in ipairs(npcFollowers) do
            if not f then continue end
            pcall(function()
                if not f.char or not f.char.Parent then return end
                if not f.seat or not f.seat.Parent then return end
                if not f.hrp or not f.hrp.Parent then return end
                if not f.hrp.Anchored then f.hrp.Anchored = true end
                f.hrp.CFrame = f.seat.CFrame * f.offset
                if not f.hrp:FindFirstChild("RG_NpcWeld") then
                    local w = Instance.new("WeldConstraint")
                    w.Name = "RG_NpcWeld"; w.Part0 = f.seat; w.Part1 = f.hrp; w.Parent = f.hrp
                end
            end)
        end
    end
    local function attachNpcFollowers(car)
        npcFollowers = {}
        local myChar = char()
        if not car then return end
        for _, d in ipairs(car:GetDescendants()) do
            if d:IsA("VehicleSeat") and d.Occupant then
                local oh = d.Occupant
                if oh and oh.Parent and oh.Parent ~= myChar then
                    local npcChar = oh.Parent
                    local hrp = npcChar:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local offset = d.CFrame:ToObjectSpace(hrp.CFrame)
                        for _, p in ipairs(npcChar:GetDescendants()) do
                            if p:IsA("BasePart") then
                                pcall(function() p.Anchored = true end)
                                pcall(function() p.CanCollide = false end)
                                pcall(function() p.Massless = true end)
                                pcall(function() p:SetNetworkOwner(lp) end)
                            end
                        end
                        local ex = hrp:FindFirstChild("RG_NpcWeld")
                        if ex then pcall(function() ex:Destroy() end) end
                        local w = Instance.new("WeldConstraint")
                        w.Name = "RG_NpcWeld"; w.Part0 = d; w.Part1 = hrp; w.Parent = hrp
                        pcall(function() oh.PlatformStand = true; oh.WalkSpeed = 0; oh.JumpPower = 0; oh.JumpHeight = 0; oh.AutoRotate = false end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Running, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) end)
                        pcall(function() oh:ChangeState(Enum.HumanoidStateType.Physics) end)
                        table.insert(npcFollowers, { char = npcChar, hum = oh, seat = d, offset = offset, hrp = hrp })
                    end
                end
            end
        end
        if npcRenderConn then pcall(function() npcRenderConn:Disconnect() end); npcRenderConn = nil end
        npcRenderConn = RunService.RenderStepped:Connect(function() pcall(safeRefreshNpc) end)
    end
    local function updateNpcFollowers() pcall(safeRefreshNpc) end
    local function detachNpcFollowers()
        if npcRenderConn then pcall(function() npcRenderConn:Disconnect() end); npcRenderConn = nil end
        for _, f in ipairs(npcFollowers) do
            if f and f.char and f.char.Parent then
                local hrp = f.char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local w = hrp:FindFirstChild("RG_NpcWeld")
                    if w then pcall(function() w:Destroy() end) end
                end
                for _, p in ipairs(f.char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function() p.Anchored = false end)
                        pcall(function() p.CanCollide = true end)
                        pcall(function() p.Massless = false end)
                    end
                end
                if f.hum and f.hum.Parent then
                    pcall(function() f.hum.PlatformStand = false end)
                    pcall(function() f.hum.WalkSpeed = 16 end)
                    pcall(function() f.hum.JumpPower = 50 end)
                    pcall(function() f.hum.AutoRotate = true end)
                end
            end
        end
        npcFollowers = {}
    end

    local function claimNetworkOwner(inst)
        if not inst then return end
        if inst:IsA("BasePart") and not inst.Anchored then pcall(function() inst:SetNetworkOwner(lp) end) end
        for _, p in ipairs(inst:GetDescendants()) do
            if p:IsA("BasePart") and not p.Anchored then pcall(function() p:SetNetworkOwner(lp) end) end
        end
    end
    local function unanchorCar(car)
        if not car then return end
        for _, p in ipairs(car:GetDescendants()) do
            if p:IsA("BasePart") and p.Anchored then pcall(function() p.Anchored = false end) end
        end
    end
    local function fullCollideOn(inst)
        if not inst then return end
        if inst:IsA("BasePart") and not inst.CanCollide then pcall(function() inst.CanCollide = true end) end
        for _, p in ipairs(inst:GetDescendants()) do
            if p:IsA("BasePart") and not p.CanCollide then pcall(function() p.CanCollide = true end) end
        end
    end

    -- HOLD: BodyPosition tai VI TRI HIEN TAI + BodyGyro giu huong
    local function startHold()
        if holdBP then pcall(function() holdBP:Destroy() end) holdBP = nil end
        if holdGyro then pcall(function() holdGyro:Destroy() end) holdGyro = nil end
        local car = myCar or findMyCar(); if not car then return end
        local vs = car:FindFirstChildWhichIsA("VehicleSeat", true); if not vs then return end
        local anchorPos = vs.Position
        local flatRot = flatYawCFrame(vs.CFrame)
        local bp = Instance.new("BodyPosition")
        bp.Name = "RGHoldPos"
        bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bp.P = 8000; bp.D = 1000
        bp.Position = anchorPos
        bp.Parent = vs
        holdBP = bp
        local bg = Instance.new("BodyGyro")
        bg.Name = "RGHoldGyro"
        bg.MaxTorque = Vector3.new(6e5, 6e5, 6e5)
        bg.P = 12000; bg.D = 800
        bg.CFrame = flatRot
        bg.Parent = vs
        holdGyro = bg
        holdActive = true
        task.spawn(function()
            while holdActive and holdBP == bp and bp.Parent do
                bp.Position = anchorPos
                if holdGyro == bg and bg.Parent then bg.CFrame = flatRot end
                task.wait(0.05)
            end
        end)
    end
    local function stopHold()
        holdActive = false
        if holdBP then pcall(function() holdBP:Destroy() end) holdBP = nil end
        if holdGyro then pcall(function() holdGyro:Destroy() end) holdGyro = nil end
    end

    local function getDriveSeat(car)
        if not car then return nil end
        for _, d in ipairs(car:GetDescendants()) do
            if d:IsA("VehicleSeat") then
                local n = d.Name:lower()
                if n:find("drive") or n:find("driver") then return d end
            end
        end
        return car:FindFirstChildWhichIsA("VehicleSeat", true)
    end

    local function forceSeat()
        local h = hum(); local car = myCar or findMyCar()
        if not h or not car then return false end
        local vs = getDriveSeat(car); if not vs then return false end
        if h.Sit and h.SeatPart == vs then pcall(function() h.AutoRotate = false end); return true end
        if h.Sit and h.SeatPart ~= vs then pcall(function() h.Sit = false end); task.wait(0.2) end
        if vs.Occupant and vs.Occupant ~= h then
            local occ = vs.Occupant
            if occ and occ:IsA("Humanoid") then pcall(function() occ.Sit = false end); task.wait(0.2) end
            if vs.Occupant and vs.Occupant ~= h then return false end
        end
        local disabledList = {}
        for _, d in ipairs(car:GetDescendants()) do
            if d:IsA("VehicleSeat") and d ~= vs and not d.Disabled then
                local ok = pcall(function() d.Disabled = true end)
                if ok then table.insert(disabledList, d) end
            end
        end
        local hrp = root()
        if hrp then pcall(function() hrp.CFrame = vs.CFrame end); task.wait(SEAT_DELAY) end
        pcall(function() vs:Sit(h) end); task.wait(0.12)
        pcall(function() h.AutoRotate = false end); pcall(function() h.Sit = true end)
        for i = 1, 3 do
            if h.Sit and h.SeatPart == vs then break end
            local hrpR = root()
            if hrpR then pcall(function() hrpR.CFrame = vs.CFrame end); task.wait(0.1) end
            pcall(function() vs:Sit(h) end); task.wait(0.1)
            if not h.Sit then pcall(function() h.Sit = true end); task.wait(0.06) end
        end
        for _, d in ipairs(disabledList) do pcall(function() d.Disabled = false end) end
        pcall(function() h.AutoRotate = false end)
        return h.Sit and h.SeatPart == vs
    end

    local function seatCar(timeout)
        timeout = timeout or 15
        local deadline = os.clock() + timeout
        while os.clock() < deadline and enabled do
            local h = hum(); local car = findMyCar()
            if h and car then
                local vs = getDriveSeat(car)
                if h.Sit and h.SeatPart == vs then
                    myCar = car
                    pcall(function() h.AutoRotate = false end)
                    return true
                end
                forceSeat()
            end
            task.wait(0.4)
        end
        return false
    end

    local function flyTo(target, flyingLabel)
        flyingLabel = flyingLabel or "bay"
        stopHold()
        local h = hum(); local car = myCar or findMyCar()
        if not h or not car then return false end
        if not h.Sit then forceSeat(); task.wait(0.1) end
        pcall(function() h.AutoRotate = false end)
        local myChar = char()
        local hrp = root()
        local targetFloor = floorBelow(target) or target.Y
        local underY = targetFloor - UNDERGROUND_DEPTH
        setRgStatus("◦ Chuẩn bị")
        unanchorCar(car); task.wait(0.05)
        claimNetworkOwner(car); attachNpcFollowers(car)
        for _, p in ipairs(car:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
        end
        if myChar then
            for _, p in ipairs(myChar:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
            end
        end
        flying = true
        local flyStart = os.clock()
        local startPivot = car:GetPivot()
        local rotOnly = flatYawCFrame(startPivot)
        local curPos = startPivot.Position
        local downStepY = (underY - curPos.Y) / UNDER_DESCEND_STEPS
        for i = 1, UNDER_DESCEND_STEPS do
            curPos = Vector3.new(curPos.X, curPos.Y + downStepY, curPos.Z)
            local cf = CFrame.new(curPos) * rotOnly
            if hrp then pcall(function() hrp.CFrame = cf end) end
            pcall(function() car:PivotTo(cf) end)
            task.wait(UNDER_STEP_TIME)
        end
        setRgStatus("◦ " .. flyingLabel)
        local reached = false; local timedOut = false
        local lastNpcRefresh = 0; local fakeVelCounter = 0
        while enabled do
            local c = myCar or findMyCar(); if not c then break end
            if os.clock() - flyStart > FLY_TIMEOUT then timedOut = true; break end
            local curP = c:GetPivot().Position
            local flat = Vector3.new(target.X - curP.X, 0, target.Z - curP.Z)
            local dist = flat.Magnitude
            if dist < ARRIVE_DIST then reached = true; break end
            local dir = (dist > 0.01) and flat.Unit or Vector3.new(1, 0, 0)
            local spd
            if dist >= DECEL_DIST then spd = STEP_DIST else spd = math.max(STEP_DIST * dist / DECEL_DIST, 6) end
            local step = math.min(spd * TICK, dist, UNDER_STEP_MAX)
            local nextPos = Vector3.new(curP.X + dir.X * step, underY, curP.Z + dir.Z * step)
            local nextCF = CFrame.new(nextPos) * rotOnly
            if hrp then pcall(function() hrp.CFrame = nextCF end) end
            pcall(function() c:PivotTo(nextCF) end)
            fakeVelCounter = fakeVelCounter + 1
            if fakeVelCounter >= 2 then
                fakeVelCounter = 0
                local fakeV = Vector3.new(dir.X * spd, 0, dir.Z * spd)
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.AssemblyLinearVelocity = fakeV end) end
                end
            end
            if os.clock() - lastNpcRefresh > 0.05 then lastNpcRefresh = os.clock(); updateNpcFollowers() end
            task.wait(TICK)
        end
        if timedOut then
            flying = false
            detachNpcFollowers()
            setRgStatus("⚠ Bay quá 30s — hủy")
            return false
        end
        car = myCar or findMyCar()
        if car and reached then
            local realFloor = floorBelow(target) or targetFloor
            local upTargetY = realFloor + LAND_OFFSET
            local upCF = CFrame.new(Vector3.new(target.X, upTargetY, target.Z)) * rotOnly
            if hrp then pcall(function() hrp.CFrame = upCF end) end
            task.wait(0.05)
            pcall(function() car:PivotTo(upCF) end)
            task.wait(0.15)
            for _, p in ipairs(car:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
            end
            if myChar then
                for _, p in ipairs(myChar:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
                end
            end
            task.wait(0.1)
            myCar = car
            startHold()
            local hh = hum()
            local vs = getDriveSeat(car)
            if hh and vs then
                pcall(function() vs:Sit(hh) end)
                task.wait(0.15)
                pcall(function() hh.Sit = true end)
                pcall(function() hh.AutoRotate = false end)
            end
        end
        detachNpcFollowers()
        flying = false
        if not enabled then return false end
        if not h.Sit then forceSeat() end
        task.wait(0.1)
        local h2 = hum()
        if not h2 or not h2.Sit then forceSeat(); task.wait(0.2) end
        task.wait(0.15)
        return reached
    end

    local function spawnAndSeat()
        if not SpawnCarEv then return false end
        if not selectedCar or selectedCar == "" then setRgStatus("⚠ Chưa chọn xe"); return false end
        local car = findMyCar()
        if car and car:FindFirstChildWhichIsA("BasePart", true) then
            setRgStatus("◦ Xe đã có sẵn")
            if seatCar(10) then setRgStatus("◦ Sẵn sàng"); return true end
        end
        setRgStatus("◦ Đang spawn xe"); fire(SpawnCarEv, selectedCar)
        local deadline = os.clock() + 20
        while os.clock() < deadline and enabled do
            car = findMyCar()
            if car and car:FindFirstChildWhichIsA("BasePart", true) then
                local r = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
                if r and r.AssemblyLinearVelocity.Magnitude < 5 then break end
            end
            task.wait(0.5)
        end
        if not car then setRgStatus("⚠ Xe chưa hiện"); return false end
        task.wait(1.5)
        local pivot = car:GetPivot()
        local flatRot = flatYawCFrame(pivot)
        pcall(function() car:PivotTo(CFrame.new(pivot.Position) * flatRot) end)
        task.wait(0.1)
        if seatCar(15) then setRgStatus("◦ Sẵn sàng"); task.wait(1); return true end
        setRgStatus("⚠ Ngồi ghế thất bại"); return false
    end

    local function resetCharacter()
        setRgStatus("◦ Reset nhân vật")
        local h = hum(); if h then pcall(function() h.Health = 0 end) end
        local deadline = os.clock() + 8
        while os.clock() < deadline do
            local n = hum(); if n and n.Health > 0 then break end
            task.wait(0.3)
        end
        task.wait(0.5)
    end

    local function doFullInit()
        setRgStatus("◦ Lần đầu — đổi nghề")
        fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
        task.wait(3)
        if not enabled then return false end
        setRgStatus("◦ Spawn xe")
        if not spawnAndSeat() then return false end
        myCar = findMyCar()
        setRgStatus("◦ Bật online"); fire(TaxiEvent, "GoOnline"); task.wait(2)
        hasInitOnce = true
        setRgStatus("◦ Sẵn sàng nhận đơn")
        return true
    end

    local function doRestartInit()
        -- BO resetCharacter()
        task.wait(0.5)
        if not enabled then return false end
        setRgStatus("◦ Spawn xe")
        if not spawnAndSeat() then return false end
        myCar = findMyCar()
        setRgStatus("◦ Tắt online"); fire(TaxiEvent, "GoOffline"); task.wait(1)
        setRgStatus("◦ Bật lại online"); fire(TaxiEvent, "GoOnline"); task.wait(2)
        setRgStatus("◦ Sẵn sàng nhận đơn")
        return true
    end

    -- recoverFromTimeout: BO resetCharacter
    local function recoverFromTimeout()
        acceptingOrder = false; flying = false
        detachNpcFollowers(); stopHold()
        local car = myCar or findMyCar()
        if car then
            unanchorCar(car)
            for _, p in ipairs(car:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.CanCollide = true end)
                    pcall(function() p.Anchored = false end)
                end
            end
        end
        local c = char(); if c then fullCollideOn(c) end
        resetRidegoState()
        if not enabled then return end
        farmStartTime = os.time()
        fire(TaxiEvent, "GoOffline"); task.wait(1)
        fire(TaxiEvent, "GoOnline"); task.wait(1)
        setRgStatus("◦ Đã khôi phục — chờ đơn")
    end

    local function runTrip()
        local h = hum()
        if not h or not h.Sit then
            setRgStatus("⚠ Hồi sinh xe")
            if not spawnAndSeat() then task.wait(5); return end
            if not enabled then return end
        end
        myCar = findMyCar()
        pcall(function() h.AutoRotate = false end)
        startHold()
        if not pickupPos then
            orderToken = nil; dropPos = nil; pendingFare = 0
            acceptingOrder = true
            setRgStatus("◦ Chờ đơn")
            local deadline = os.clock() + ORDER_TIMEOUT
            while os.clock() < deadline and enabled do
                if pickupPos then break end
                if not holdActive then startHold() end
                task.wait(0.4)
            end
            acceptingOrder = false
            if not enabled then return end
            if not pickupPos then setRgStatus("⚠ Không có đơn"); return end
        else
            acceptingOrder = false; setRgStatus("◦ Đã có đơn — bay luôn")
        end
        local ok1 = flyTo(pickupPos, "đón khách")
        if not enabled then return end
        if not ok1 then recoverFromTimeout(); return end
        setRgStatus("◦ Đã tới"); forceSeat()
        setRgStatus("⌛ Đợi khách lên xe (4s)")
        task.wait(PICKUP_WAIT)
        if not enabled then return end
        if dropPos then
            local ok2 = flyTo(dropPos, "đưa khách tới nơi")
            if not enabled then return end
            if not ok2 then recoverFromTimeout(); return end
            setRgStatus("◦ Đã tới"); forceSeat()
            setRgStatus("⌛ Đợi khách xuống xe (5s)")
            task.wait(DROP_WAIT)
            if not enabled then return end
            stats.trips = stats.trips + 1
            if pendingFare > 0 then stats.earn = stats.earn + pendingFare end
            setRgStatus("✓ Hoàn thành + Rp " .. formatMoney(pendingFare))
            task.wait(ACK_DELAY)
            if not enabled then return end
            fire(TaxiEvent, "AckTripComplete")
            setRgStatus("✓ Đã báo hoàn thành — chờ đơn mới")
            pendingFare = 0
            if stats.trips > 0 and stats.trips % TRIP_MILESTONE == 0 and stats.trips ~= lastMilestone then
                lastMilestone = stats.trips; pickupPos = nil; dropPos = nil; orderToken = nil
                setRgStatus("◦ Đủ " .. TRIP_MILESTONE .. " chuyến — tắt/mở lại online")
                fire(TaxiEvent, "GoOffline"); task.wait(2)
                if not enabled then return end
                fire(TaxiEvent, "GoOnline")
                acceptingOrder = true; task.wait(1.5)
                setRgStatus("◦ Đã mở lại online"); return
            end
        end
        pickupPos = nil; dropPos = nil; orderToken = nil
        task.wait(0.3)
    end

    local loopBusy = false
    local function startLoop()
        if loopBusy then return end
        loopBusy = true
        task.spawn(function()
            farmStartTime = os.time()
            local ok
            if not hasInitOnce then ok = pcall(doFullInit) else ok = pcall(doRestartInit) end
            if not ok or not enabled then
                loopBusy = false
                if not enabled then setRgStatus("◦ TẮT") else setRgStatus("⚠ Khởi tạo thất bại") end
                return
            end
            while enabled do
                local ok2, err = pcall(runTrip)
                if not ok2 then setRgStatus("⚠ Lỗi: " .. tostring(err):sub(1, 40)) end
                task.wait(1)
            end
            loopBusy = false
            setRgStatus("◦ TẮT")
        end)
    end

    -- STATUS PANEL
    ridegoStatusFrame = Instance.new("Frame", ScreenGui)
    ridegoStatusFrame.Size = UDim2.new(0, 250, 0, 148)
    ridegoStatusFrame.Position = UDim2.new(0, 76, 0.5, 20)
    ridegoStatusFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
    ridegoStatusFrame.BackgroundTransparency = 0.15
    ridegoStatusFrame.BorderSizePixel = 0
    ridegoStatusFrame.Active = true; ridegoStatusFrame.Draggable = true
    ridegoStatusFrame.Visible = false; ridegoStatusFrame.ZIndex = 30
    Instance.new("UICorner", ridegoStatusFrame).CornerRadius = UDim.new(0, 10)
    local rgStroke = Instance.new("UIStroke", ridegoStatusFrame)
    rgStroke.Name = "RainbowBorder"; rgStroke.Thickness = 2
    rgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    task.spawn(function()
        local t = 0
        while true do task.wait(0.03); t = t + 0.15
            if rgStroke and rgStroke.Parent then rgStroke.Color = rainbowAt(t) end
        end
    end)
    local rgTitle = Instance.new("TextLabel", ridegoStatusFrame)
    rgTitle.Size = UDim2.new(1, -20, 0, 24); rgTitle.Position = UDim2.new(0, 10, 0, 4)
    rgTitle.BackgroundTransparency = 1; rgTitle.Text = "🚕 RideGo Status"
    rgTitle.TextColor3 = Color3.fromRGB(255, 140, 40); rgTitle.TextSize = 13
    rgTitle.Font = Enum.Font.GothamBold; rgTitle.TextXAlignment = Enum.TextXAlignment.Left; rgTitle.ZIndex = 31
    local function rgLabel(y)
        local l = Instance.new("TextLabel", ridegoStatusFrame)
        l.Size = UDim2.new(1, -20, 0, 18); l.Position = UDim2.new(0, 10, 0, y)
        l.BackgroundTransparency = 1; l.Text = ""
        l.TextColor3 = Color3.fromRGB(200, 220, 240); l.TextSize = 11
        l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd; l.ZIndex = 31
        return l
    end
    ridegoTimeLbl = rgLabel(32); ridegoTripsLbl = rgLabel(50); ridegoEarnLbl = rgLabel(68)
    ridegoStatusCarLbl = rgLabel(86); ridegoStatusLbl = rgLabel(110)
    ridegoStatusCarLbl.Text = "🚗 Xe: (chưa chọn)"

    task.spawn(function()
        while true do
            task.wait(0.3)
            if enabled then
                local sec = os.time() - farmStartTime
                ridegoTimeLbl.Text = "⏱ Thời gian: " .. formatTime(sec)
                ridegoTripsLbl.Text = "🚕 Chuyến: " .. tostring(stats.trips)
                ridegoEarnLbl.Text = "💰 Kiếm: Rp " .. formatMoney(stats.earn)
                if selectedCar ~= "" then ridegoStatusCarLbl.Text = "🚗 Xe: " .. selectedCar end
                ridegoStatusLbl.Text = "📍 " .. curStatus
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if _G._ridegoEnabled and ridegoStatusFrame and not ridegoStatusFrame.Visible then
            ridegoStatusFrame.Visible = true
        end
    end)

    task.spawn(function()
        task.wait(2)
        pcall(scanCars)
        local savedCar = ""
        if readfile and isfile and isfile("ridegoCar.txt") then
            local ok, v = pcall(readfile, "ridegoCar.txt")
            if ok and v and v ~= "" then savedCar = v:gsub("[\r\n%s]+$", "") end
        end
        if savedCar ~= "" and #carList > 0 then
            local found = false
            for _, n in ipairs(carList) do
                if n == savedCar then found = true; break end
            end
            if found then
                selectedCar = savedCar; ridegoSelectedCar = savedCar
            elseif not selectedCar or selectedCar == "" then
                selectedCar = carList[1]; ridegoSelectedCar = selectedCar
            end
        elseif #carList > 0 and (not selectedCar or selectedCar == "") then
            selectedCar = carList[1]; ridegoSelectedCar = selectedCar
        end
        renderRidegoCars()
        if ridegoPickLbl then ridegoPickLbl.Text = "🚗 Xe: " .. ((selectedCar ~= "" and selectedCar) or "(chưa chọn)") end
        if ridegoStatusCarLbl then ridegoStatusCarLbl.Text = "🚗 Xe: " .. ((selectedCar ~= "" and selectedCar) or "(chưa chọn)") end
    end)

    -- stopRidego: BO resetCharacter
    local function stopRidego(forceClose)
        enabled = false
        _G._ridegoEnabled = false
        acceptingOrder = false; flying = false
        detachNpcFollowers(); stopHold()
        local car = myCar or findMyCar()
        if car then
            unanchorCar(car)
            for _, p in ipairs(car:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.CanCollide = true end)
                    pcall(function() p.Anchored = false end)
                end
            end
        end
        local c = char(); if c then fullCollideOn(c) end
        resetRidegoState()
        if writefile then pcall(writefile, "ridegoState.txt", "0") end
        if ridegoStatusFrame then ridegoStatusFrame.Visible = false end
        if ridegoSwitch then ridegoSwitch.set(false) end
        if ridegoCarListPanel then ridegoCarListPanel.Visible = false end
        ridegoCarOpen = false
        setRgStatus("◦ TẮT")
        -- BO task.spawn(function() resetCharacter() end)
    end
    _G._ridegoStop = stopRidego

    ridegoSwitch.track.MouseButton1Click:Connect(function()
        if enabled then stopRidego(); return end
        _G._ridegoEnabled = true
        enabled = true
        ridegoStatusFrame.Visible = true
        pcall(function()
            if _G._officeStop then _G._officeStop(true) end
            resetRidegoState()
            farmStartTime = os.time()
            stats.trips = 0; stats.earn = 0
            ridegoTimeLbl.Text = "⏱ Thời gian: 00:00:00"
            ridegoTripsLbl.Text = "🚕 Chuyến: 0"
            ridegoEarnLbl.Text = "💰 Kiếm: Rp 0"
            ridegoStatusCarLbl.Text = "🚗 Xe: " .. ((selectedCar ~= "" and selectedCar) or "(chưa chọn)")
            ridegoStatusLbl.Text = "📍 ◦ Đang khởi động"
            if writefile then
                pcall(writefile, "ridegoState.txt", "1")
                pcall(writefile, "farmState.txt", "0")
            end
            if queue_on_teleport then
                pcall(queue_on_teleport, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()]])
            end
            ridegoSwitch.set(true)
            startLoop()
        end)
    end)
end
-- ============================================================
-- WIRING CUOI
-- ============================================================
ToggleBtn.MouseButton1Click:Connect(function() HubFrame.Visible = not HubFrame.Visible end)
hubClose.MouseButton1Click:Connect(function() HubFrame.Visible = false end)

local bodyOn = false
bodyOpenBtn.MouseButton1Click:Connect(function()
    bodyOn = not bodyOn
    BodyManagerFloatingBtn.Visible = bodyOn
    if not bodyOn then
        ControlPanel.Visible = false
        BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    end
    bodyOpenBtn.Text = "🚗 DÀN ÁO: " .. (bodyOn and "ĐANG BẬT" or "ĐANG TẮT")
    bodyOpenBtn.BackgroundColor3 = bodyOn and Color3.fromRGB(0, 150, 120) or Color3.fromRGB(30, 30, 40)
end)

local fcOn = false
fcOpenBtn.MouseButton1Click:Connect(function()
    fcOn = not fcOn
    FreecamFloatingBtn.Visible = fcOn
    if not fcOn then freecamMenuFrame.Visible = false end
    fcOpenBtn.Text = "📷 FREECAM: " .. (fcOn and "ĐANG BẬT" or "ĐANG TẮT")
    fcOpenBtn.BackgroundColor3 = fcOn and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(30, 30, 40)
end)

addRGBStroke(ToggleBtn)
addRGBStroke(AutoTFloatingBtn)
addRGBStroke(BodyManagerFloatingBtn)
addRGBStroke(FreecamFloatingBtn)
addRGBStroke(hideFloatBtn)

-- ============================================================
-- AUTO REJOIN v2: multi-detection nut CHƠI
-- ============================================================
local _autoRejoin = false
if readfile and isfile and isfile("autoRejoin.txt") then
    local ok, v = pcall(readfile, "autoRejoin.txt")
    if ok and v == "1" then _autoRejoin = true end
end

if _autoRejoin then
    task.spawn(function()
        local lastAttempt = 0
        if readfile and isfile and isfile("lastRejoin.txt") then
            local ok, v = pcall(readfile, "lastRejoin.txt")
            if ok then lastAttempt = tonumber(v) or 0 end
        end
        while true do
            task.wait(3)
            if os.time() - lastAttempt >= 120 then
                local shouldRejoin = false
                if not game.Players.LocalPlayer.Character then shouldRejoin = true end
                if not shouldRejoin then
                    pcall(function()
                        local cg = game:GetService("CoreGui")
                        for _, d in ipairs(cg:GetDescendants()) do
                            if d:IsA("TextLabel") then
                                local t = d.Text
                                if t == "Mất kết nối" or t:find("Disconnected") or t == "Kết nối bị mất" then
                                    shouldRejoin = true; return
                                end
                            end
                        end
                    end)
                end
                if shouldRejoin then
                    lastAttempt = os.time()
                    if writefile then pcall(writefile, "lastRejoin.txt", tostring(lastAttempt)) end
                    if queue_on_teleport then
                        pcall(queue_on_teleport, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()]])
                    end
                    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
                end
            end
        end
    end)
end

task.spawn(function()
    local wasRejoin = false
    if readfile and isfile and isfile("lastRejoin.txt") then
        local ok, v = pcall(readfile, "lastRejoin.txt")
        if ok then
            local t = tonumber(v) or 0
            if t > 0 and os.time() - t < 300 then wasRejoin = true end
        end
    end
    if not wasRejoin then return end

    -- ========== HELPER: click nut ==========
    local function clickBtn(btn)
        if not btn then return false end
        local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
        local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
        if pcall(function() firesignal(btn.MouseButton1Click) end) then return true end
        if pcall(function() firesignal(btn.Activated) end) then return true end
        if pcall(function()
            touchpress(x, y); task.wait(0.2); touchrelease(x, y)
        end) then return true end
        return false
    end

    -- ========== HELPER: tim nut CHƠI (multi-detect) ==========
    -- Match theo 3 lop: text chinh xac -> text pattern -> (size + position + color)
    local function findPlayBtn()
        local pg = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end

        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

        -- Pattern text (Unicode friendly)
        local function textIsPlay(s)
            if not s or s == "" then return false end
            local u = s:upper()
            return u == "CHƠI" or u == "CHOI"
                or u == "PLAY" or u == "START"
                or u:find("CHƠI") or u:find("PLAY")
                or u:find("CHOI") or u:find("BẮT ĐẦU")
        end

        -- Lop 1: TextButton co Text khop
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 40 then
                if textIsPlay(d.Text) then return d end
            end
        end

        -- Lop 2: Button co TextLabel con khop
        for _, d in ipairs(pg:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible and d.AbsoluteSize.X > 40 then
                for _, c in ipairs(d:GetDescendants()) do
                    if c:IsA("TextLabel") and c.Visible and textIsPlay(c.Text) then
                        return d
                    end
                end
            end
        end

        -- Lop 3: fallback - nut to, giua man hinh, background xanh la
        local best, bestScore = nil, 0
        for _, d in ipairs(pg:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
                local sz = d.AbsoluteSize
                local ap = d.AbsolutePosition
                if sz.X > 150 and sz.Y > 40 then
                    local cx = ap.X + sz.X / 2
                    local cy = ap.Y + sz.Y / 2
                    local inCenterX = cx > vp.X * 0.25 and cx < vp.X * 0.75
                    local inBottomY = cy > vp.Y * 0.45 and cy < vp.Y * 0.92
                    if inCenterX and inBottomY then
                        local score = 1
                        -- uu tien background xanh la (nut CHƠI)
                        if d.BackgroundColor3.G > 0.5 and d.BackgroundColor3.R < 0.5 then
                            score = score + 5
                        end
                        -- uu tien co text label con
                        for _, c in ipairs(d:GetDescendants()) do
                            if c:IsA("TextLabel") and c.Text ~= "" then
                                score = score + 3
                                break
                            end
                        end
                        if score > bestScore then bestScore = score; best = d end
                    end
                end
            end
        end
        if best and bestScore >= 4 then return best end
        return nil
    end

    -- ========== WAIT 15s: cho UI menu chinh load ==========
    task.wait(15)

    -- ========== BUOC 1: click nut CHƠI menu chinh ==========
    local btn1 = nil
    local t0 = os.clock()
    while os.clock() - t0 < 30 do
        btn1 = findPlayBtn()
        if btn1 then break end
        task.wait(1)
    end

    if btn1 then
        clickBtn(btn1)
        task.wait(1)
        -- click lan 2
        pcall(function()
            local x = btn1.AbsolutePosition.X + btn1.AbsoluteSize.X / 2
            local y = btn1.AbsolutePosition.Y + btn1.AbsoluteSize.Y / 2
            touchpress(x, y); task.wait(0.2); touchrelease(x, y)
        end)
    end

    -- ========== BUOC 2: doi menu doi, click nut CHƠI lan 2 ==========
    task.wait(4)

    local btn2 = nil
    local t1 = os.clock()
    while os.clock() - t1 < 30 do
        local b = findPlayBtn()
        if b and b ~= btn1 then btn2 = b; break end
        task.wait(1)
    end

    if btn2 then
        clickBtn(btn2)
        task.wait(1)
        pcall(function()
            local x = btn2.AbsolutePosition.X + btn2.AbsoluteSize.X / 2
            local y = btn2.AbsolutePosition.Y + btn2.AbsoluteSize.Y / 2
            touchpress(x, y); task.wait(0.2); touchrelease(x, y)
        end)
    end

    if writefile then pcall(writefile, "lastRejoin.txt", "0") end

    -- ========== BUOC 3: WAIT 15s cho vao game + load map ==========
    task.wait(15)

    -- ========== BUOC 4: doc state ==========
    local officeFlag, ridegoFlag = false, false
    if readfile and isfile and isfile("farmState.txt") then
        local ok, v = pcall(readfile, "farmState.txt")
        if ok and v == "1" then officeFlag = true end
    end
    if readfile and isfile and isfile("ridegoState.txt") then
        local ok, v = pcall(readfile, "ridegoState.txt")
        if ok and v == "1" then ridegoFlag = true end
    end

    -- ========== BUOC 5: doi map san sang + restore xe + bat farm ==========
    if ridegoFlag then
        local rs = game:GetService("ReplicatedStorage")
        for _ = 1, 60 do
            local c = game.Players.LocalPlayer.Character
            if rs:FindFirstChild("TaxiAssets") and rs:FindFirstChild("SpawnCarEvents") and c then
                break
            end
            task.wait(1)
        end
        task.wait(5)

        -- restore xe tu ridegoCar.txt
        local savedCar = ""
        if readfile and isfile and isfile("ridegoCar.txt") then
            local ok, v = pcall(readfile, "ridegoCar.txt")
            if ok and v and v ~= "" then
                savedCar = v:gsub("[\r\n%s]+$", "")
            end
        end
        if savedCar ~= "" then
            pcall(function()
                selectedCar = savedCar
                ridegoSelectedCar = savedCar
                if ridegoPickLbl then ridegoPickLbl.Text = "🚗 Xe: " .. savedCar end
                if ridegoStatusCarLbl then ridegoStatusCarLbl.Text = "🚗 Xe: " .. savedCar end
                if ridegoCarBtn then ridegoCarBtn.Text = "🚗 CHỌN XE (" .. #ridegoCarList .. ")" end
                if renderRidegoCars then renderRidegoCars() end
            end)
        end
        task.wait(2)

        pcall(function()
            if ridegoSwitch and ridegoSwitch.track then
                firesignal(ridegoSwitch.track.MouseButton1Click)
            end
        end)
    elseif officeFlag then
        for _ = 1, 60 do
            if workspace:FindFirstChild("Computers") then break end
            task.wait(1)
        end
        task.wait(5)
        pcall(function()
            if farmSwitch and farmSwitch.track then
                firesignal(farmSwitch.track.MouseButton1Click)
            end
        end)
    end
end)
