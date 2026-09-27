-- ============================================================
-- KHANGLE DDS HUB v20 — RIDEGO FIX + CAR OVERLAY
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

local function checkFarmOK()
    return workspace:FindFirstChild("Computers") ~= nil
end

pcall(function()
    Lighting.GlobalShadows = true
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
    if not Lighting:FindFirstChild("KhangLeBloom") then
        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Name = "KhangLeBloom"
        bloom.Intensity = 0.4
        bloom.Threshold = 0.8
    end
end)

local parent = nil
pcall(function() parent = gethui and gethui() or CoreGui end)
if not parent then parent = LocalPlayer:WaitForChild("PlayerGui") end
if parent:FindFirstChild("KhangLeCustomTuner") then
    parent.KhangLeCustomTuner:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KhangLeCustomTuner"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parent

local function makeHeaderDraggable(header, frame)
    header.Active = true
    local dragging = false
    local dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============ THEME + RAINBOW ============
local HUB_BG    = Color3.fromRGB(10, 14, 22)
local HUB_SIDE  = Color3.fromRGB(14, 20, 32)
local CARD_BG   = Color3.fromRGB(18, 26, 40)
local themeColor = Color3.fromRGB(0, 229, 160)
local ACCENT2   = Color3.fromRGB(56, 189, 248)
local TXT_DIM   = Color3.fromRGB(150, 165, 185)

local RAINBOW = {
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(255, 100, 40),
    Color3.fromRGB(255, 150, 40),
    Color3.fromRGB(255, 200, 40),
    Color3.fromRGB(240, 240, 60),
    Color3.fromRGB(180, 235, 60),
    Color3.fromRGB(100, 230, 90),
    Color3.fromRGB(60, 225, 150),
    Color3.fromRGB(50, 210, 210),
    Color3.fromRGB(60, 180, 240),
    Color3.fromRGB(80, 140, 255),
    Color3.fromRGB(130, 110, 255),
    Color3.fromRGB(180, 90, 255),
    Color3.fromRGB(225, 80, 220),
    Color3.fromRGB(255, 70, 180),
    Color3.fromRGB(255, 60, 120),
}
local RN = #RAINBOW
local function rainbowAt(pos)
    pos = pos % RN
    local idx = math.floor(pos) + 1
    local f = pos - (idx - 1)
    return RAINBOW[idx]:Lerp(RAINBOW[(idx % RN) + 1], f)
end

local menuRainbow = false
local menuFixedColor = Color3.fromRGB(0, 229, 160)

local floatRGB = {}
local ledOn = true
local ledMode = "rainbow"
local ledFixedColor = Color3.fromRGB(0, 229, 160)

local function addRGBStroke(btn)
    local s = Instance.new("UIStroke", btn)
    s.Name = "RGB"
    s.Thickness = 2.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0
    table.insert(floatRGB, s)
    return s
end

-- ============ TAY NAM KHAI BAO TRUOC ============
local ControlPanel, freecamMenuFrame, hideFloatBtn
local HubFrame, hubClose, hubHeader, hubStroke, statPanel
local farmSwitch
local farmNote
local bodyOpenBtn, fcOpenBtn
local ToggleFloatMenuBtn
local lblMode, lblStat1, lblStat2, lblTime, lblWork
local showAutoTFloat = false
local farmOffice = false
local ofAnswers = 0
local ofPrints = 0
local activeMode = nil
local farmStart = 0
local antiAfk = true
local optFPS = false

-- RideGo forward refs
local ridegoSwitch
local ridegoStatusFrame
local ridegoTimeLbl, ridegoTripsLbl, ridegoEarnLbl
local ridegoStatusCarLbl, ridegoStatusLbl
local ridegoPickLbl
local ridegoCarBtn, ridegoCarListPanel, ridegoCarScroll, ridegoCarListWrap
local ridegoCarOpen = false
local ridegoSelectedCar = ""
local ridegoCarList = {}
local farmingPageRef    -- giu ref de dat overlay

_G._officeStop = nil
_G._ridegoStop = nil
_G._ridegoEnabled = false
_G._officeEnabled = false

-- LED nut noi
task.spawn(function()
    local t = 0
    while true do
        t = t + 0.15
        local col
        if ledMode == "rainbow" then col = rainbowAt(t)
        else col = ledFixedColor end
        for _, s in ipairs(floatRGB) do
            if ledOn then
                s.Color = col
                s.Transparency = 0
            else
                s.Transparency = 1
            end
        end
        task.wait(0.03)
    end
end)

-- Menu RGB
task.spawn(function()
    local t = 0
    while true do
        t = t + 0.15
        if hubStroke and hubStroke.Parent and menuRainbow then
            hubStroke.Color = rainbowAt(t)
            if hubHeader then hubHeader.TextColor3 = rainbowAt(t + 2) end
            if ToggleBtn then ToggleBtn.TextColor3 = rainbowAt(t + 4) end
        end
        task.wait(0.03)
    end
end)

-- ============ NUT NOI ============
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 25, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.TextColor3 = themeColor
ToggleBtn.Text = "👑"
ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Draggable = true
ToggleBtn.ZIndex = 10
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 7)

local AutoTFloatingBtn = Instance.new("TextButton")
AutoTFloatingBtn.Size = UDim2.new(0, 48, 0, 48)
AutoTFloatingBtn.Position = UDim2.new(0, 25, 0.53, 0)
AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
AutoTFloatingBtn.TextColor3 = Color3.fromRGB(255, 100, 0)
AutoTFloatingBtn.Text = "🕹️"
AutoTFloatingBtn.TextSize = 22
AutoTFloatingBtn.Font = Enum.Font.GothamBold
AutoTFloatingBtn.Draggable = true
AutoTFloatingBtn.Visible = false
AutoTFloatingBtn.ZIndex = 10
AutoTFloatingBtn.Parent = ScreenGui
Instance.new("UICorner", AutoTFloatingBtn).CornerRadius = UDim.new(0, 7)

local BodyManagerFloatingBtn = Instance.new("TextButton")
BodyManagerFloatingBtn.Size = UDim2.new(0, 48, 0, 48)
BodyManagerFloatingBtn.Position = UDim2.new(0, 25, 0.66, 0)
BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
BodyManagerFloatingBtn.TextColor3 = Color3.fromRGB(0, 230, 180)
BodyManagerFloatingBtn.Text = "🚗"
BodyManagerFloatingBtn.TextSize = 22
BodyManagerFloatingBtn.Font = Enum.Font.GothamBold
BodyManagerFloatingBtn.Draggable = true
BodyManagerFloatingBtn.Visible = false
BodyManagerFloatingBtn.ZIndex = 10
BodyManagerFloatingBtn.Parent = ScreenGui
Instance.new("UICorner", BodyManagerFloatingBtn).CornerRadius = UDim.new(0, 7)

local FreecamFloatingBtn = Instance.new("TextButton")
FreecamFloatingBtn.Size = UDim2.new(0, 48, 0, 48)
FreecamFloatingBtn.Position = UDim2.new(0, 25, 0.79, 0)
FreecamFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
FreecamFloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FreecamFloatingBtn.Text = "📷"
FreecamFloatingBtn.TextSize = 22
FreecamFloatingBtn.Font = Enum.Font.GothamBold
FreecamFloatingBtn.Draggable = true
FreecamFloatingBtn.Visible = false
FreecamFloatingBtn.ZIndex = 10
FreecamFloatingBtn.Parent = ScreenGui
Instance.new("UICorner", FreecamFloatingBtn).CornerRadius = UDim.new(0, 7)

-- ============ BANG STATUS OFFICE ============
do
    statPanel = Instance.new("Frame")
    statPanel.Size = UDim2.new(0, 250, 0, 148)
    statPanel.Position = UDim2.new(0, 76, 0.5, 20)
    statPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
    statPanel.BackgroundTransparency = 0.15
    statPanel.BorderSizePixel = 0
    statPanel.Active = true
    statPanel.Draggable = true
    statPanel.Visible = false
    statPanel.ZIndex = 9
    statPanel.Parent = ScreenGui
    Instance.new("UICorner", statPanel).CornerRadius = UDim.new(0, 10)
    local strokeOff = Instance.new("UIStroke", statPanel)
    strokeOff.Name = "RainbowBorder"
    strokeOff.Thickness = 2
    strokeOff.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    strokeOff.Color = themeColor
    task.spawn(function()
        local t = 0
        while true do
            task.wait(0.03)
            t = t + 0.15
            if strokeOff and strokeOff.Parent then strokeOff.Color = rainbowAt(t) end
        end
    end)
    local statusTitle = Instance.new("TextLabel", statPanel)
    statusTitle.Size = UDim2.new(1, -20, 0, 24)
    statusTitle.Position = UDim2.new(0, 10, 0, 4)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "🌾 Office Status"
    statusTitle.TextColor3 = Color3.fromRGB(255, 140, 40)
    statusTitle.TextSize = 13
    statusTitle.Font = Enum.Font.GothamBold
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.ZIndex = 10
    local function statLabel(y)
        local l = Instance.new("TextLabel", statPanel)
        l.Size = UDim2.new(1, -20, 0, 18)
        l.Position = UDim2.new(0, 10, 0, y)
        l.BackgroundTransparency = 1
        l.Text = ""
        l.TextColor3 = Color3.fromRGB(200, 220, 240)
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.ZIndex = 10
        return l
    end
    lblMode  = statLabel(32)
    lblStat1 = statLabel(50)
    lblStat2 = statLabel(68)
    lblTime  = statLabel(86)
    lblWork  = statLabel(110)
    lblMode.TextColor3 = Color3.fromRGB(255, 200, 80)
end

local function setStatus(t)
    if lblWork then lblWork.Text = "📍 status: " .. t end
end
local function fmtTime(s)
    s = math.floor(s)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, sec) end
    return string.format("%02d:%02d", m, sec)
end
local function refreshStatPanel()
    if activeMode == "office" then
        lblMode.Text = "🌾 OFFICE FARM"
        lblStat1.Text = "🧮 Lượt giải: " .. ofAnswers
        lblStat2.Text = "🖨️ Lượt in: " .. ofPrints
    end
end
task.spawn(function()
    while true do
        task.wait(1)
        if activeMode == "office" and farmStart > 0 then
            lblTime.Text = "⏱ Thời gian: " .. fmtTime(os.clock() - farmStart)
        end
    end
end)

-- ============ FPS / PING ============
local perfOn = false
local perfLocked = false
local perfFrame = Instance.new("Frame")
perfFrame.Size = UDim2.new(0, 160, 0, 40)
perfFrame.Position = UDim2.new(1, -170, 0, 96)
perfFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
perfFrame.BackgroundTransparency = 0.35
perfFrame.BorderSizePixel = 0
perfFrame.Visible = false
perfFrame.ZIndex = 50
perfFrame.Active = true
perfFrame.Draggable = true
perfFrame.Parent = ScreenGui
Instance.new("UICorner", perfFrame).CornerRadius = UDim.new(0, 8)
local perfLabel = Instance.new("TextLabel")
perfLabel.Size = UDim2.new(1, -12, 1, -8)
perfLabel.Position = UDim2.new(0, 6, 0, 4)
perfLabel.BackgroundTransparency = 1
perfLabel.Text = "FPS: -- | Ping: --"
perfLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
perfLabel.TextSize = 11
perfLabel.Font = Enum.Font.GothamBold
perfLabel.TextXAlignment = Enum.TextXAlignment.Left
perfLabel.ZIndex = 51
perfLabel.Parent = perfFrame

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
    while true do
        task.wait(1)
        local fps = fpsFrames
        fpsFrames = 0
        if perfOn then perfLabel.Text = string.format("FPS: %d | Ping: %dms", fps, getPing()) end
    end
end)

-- ============ AN TEN / DOI TEN ============
local hideNameOn = false
local customName = ""
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
    watchChar(c)
    task.wait(0.5)
    if hideNameOn then hideNameTags() end
    if customName ~= "" then applyCustomName() end
end)
if LocalPlayer.Character then watchChar(LocalPlayer.Character) end
task.spawn(function()
    while true do
        task.wait(1)
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
    HubFrame.BorderSizePixel = 0
    HubFrame.Active = true
    HubFrame.Visible = false
    HubFrame.ClipsDescendants = false
    HubFrame.ZIndex = 8
    HubFrame.Parent = ScreenGui
    Instance.new("UICorner", HubFrame).CornerRadius = UDim.new(0, 12)
    hubStroke = Instance.new("UIStroke", HubFrame)
    hubStroke.Color = themeColor
    hubStroke.Thickness = 1.5
    hubStroke.Transparency = 0.25

    hubHeader = Instance.new("TextLabel")
    hubHeader.Size = UDim2.new(1, -40, 0, 34)
    hubHeader.Position = UDim2.new(0, 12, 0, 0)
    hubHeader.BackgroundTransparency = 1
    hubHeader.Text = "👑 KHANGLE DDS HUB"
    hubHeader.TextColor3 = themeColor
    hubHeader.TextSize = 13
    hubHeader.Font = Enum.Font.GothamBold
    hubHeader.TextXAlignment = Enum.TextXAlignment.Left
    hubHeader.ZIndex = 18
    hubHeader.Parent = HubFrame
    makeHeaderDraggable(hubHeader, HubFrame)

    hubClose = Instance.new("TextButton")
    hubClose.Size = UDim2.new(0, 26, 0, 26)
    hubClose.Position = UDim2.new(1, -30, 0, 4)
    hubClose.BackgroundTransparency = 1
    hubClose.TextColor3 = TXT_DIM
    hubClose.Text = "✕"
    hubClose.TextSize = 14
    hubClose.Font = Enum.Font.GothamBold
    hubClose.ZIndex = 19
    hubClose.Parent = HubFrame

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 96, 1, -34)
    sidebar.Position = UDim2.new(0, 0, 0, 34)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 14
    sidebar.Parent = HubFrame

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -104, 1, -42)
    content.Position = UDim2.new(0, 100, 0, 34)
    content.BackgroundColor3 = HUB_BG
    content.BorderSizePixel = 0
    content.ClipsDescendants = false
    content.ZIndex = 10
    content.Parent = HubFrame
    Instance.new("UICorner", content).CornerRadius = UDim.new(0, 12)

    local pages = {}
    local navBtns = {}
    local currentPageName = nil
    local function addPage(name)
        if pages[name] then return pages[name] end
        local pg = Instance.new("Frame")
        pg.Size = UDim2.new(1, 0, 1, 0)
        pg.BackgroundTransparency = 1
        pg.ClipsDescendants = false
        pg.Visible = false
        pg.ZIndex = 11
        pg.Parent = content
        pages[name] = pg
        return pg
    end
    local function selectPage(name)
        currentPageName = name
        for n, pg in pairs(pages) do pg.Visible = (n == name) end
        for n, b in pairs(navBtns) do
            if n == name then
                b.BackgroundColor3 = Color3.fromRGB(24, 36, 54)
                b.TextColor3 = menuRainbow and Color3.fromRGB(255, 255, 255) or themeColor
            else
                b.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
                b.TextColor3 = TXT_DIM
            end
        end
    end
    local navIndex = 0
    local function addNav(name, icon)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -12, 0, 40)
        b.Position = UDim2.new(0, 6, 0, 6 + navIndex * 44)
        b.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
        b.Text = icon .. " " .. name
        b.TextColor3 = TXT_DIM
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.ZIndex = 15
        b.Parent = sidebar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        navIndex = navIndex + 1
        navBtns[name] = b
        b.MouseButton1Click:Connect(function() selectPage(name) end)
        addPage(name)
        return b
    end

    addNav("TUNER", "🎛️")
    addNav("CHUNG", "🧰")
    addNav("FARMING", "🌾")
    addNav("SETTINGS", "⚙️")

    local tunerPage = pages["TUNER"]
    local chungPage = pages["CHUNG"]
    local farmingPage = pages["FARMING"]
    local settingsPage = pages["SETTINGS"]
    farmingPageRef = farmingPage

    -- ================= TUNER =================
    local function createInput(name, defaultVal, posY, pg)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.9, 0, 0, 14)
        lbl.Position = UDim2.new(0.05, 0, 0, posY)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 12
        lbl.Parent = pg
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.9, 0, 0, 24)
        box.Position = UDim2.new(0.05, 0, 0, posY + 14)
        box.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.Text = tostring(defaultVal)
        box.TextSize = 11
        box.Font = Enum.Font.GothamBold
        box.BorderSizePixel = 0
        box.ZIndex = 12
        box.Parent = pg
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", box)
        stroke.Color = Color3.fromRGB(60, 60, 75)
        stroke.Thickness = 1
        return box
    end
    local hpBox = createInput("💪 Hệ số Mã lực (Mặc định: 5.0)", "5.0", 6, tunerPage)
    local rpmBox = createInput("🔥 Cộng thêm Tua máy - RPM (Mặc định: 3500)", "3500", 48, tunerPage)
    local gearRatioBox = createInput("⚙️ Tỷ số truyền số - Ratio Gear (Mặc định: 0.9)", "0.9", 90, tunerPage)
    local finalDriveBox = createInput("⛓️ Tỷ số truyền cuối - Final Drive (Mặc định: 0.9)", "0.9", 132, tunerPage)
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(0.9, 0, 0, 18)
    Status.Position = UDim2.new(0.05, 0, 0, 174)
    Status.BackgroundTransparency = 1
    Status.Text = "Trạng thái: Sẵn sàng."
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 10
    Status.Font = Enum.Font.GothamBold
    Status.TextXAlignment = Enum.TextXAlignment.Center
    Status.ZIndex = 12
    Status.Parent = tunerPage
    local InjectBtn = Instance.new("TextButton")
    InjectBtn.Size = UDim2.new(0.9, 0, 0, 28)
    InjectBtn.Position = UDim2.new(0.05, 0, 0, 194)
    InjectBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    InjectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    InjectBtn.Text = "⚡ ÁP DỤNG TUNER"
    InjectBtn.TextSize = 11
    InjectBtn.Font = Enum.Font.GothamBold
    InjectBtn.ZIndex = 12
    InjectBtn.Parent = tunerPage
    Instance.new("UICorner", InjectBtn).CornerRadius = UDim.new(0, 7)
    ToggleFloatMenuBtn = Instance.new("TextButton")
    ToggleFloatMenuBtn.Size = UDim2.new(0.9, 0, 0, 28)
    ToggleFloatMenuBtn.Position = UDim2.new(0.05, 0, 0, 226)
    ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ToggleFloatMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleFloatMenuBtn.Text = "🕹️ NÚT NỔI AUTO T: ĐANG TẮT"
    ToggleFloatMenuBtn.TextSize = 11
    ToggleFloatMenuBtn.Font = Enum.Font.GothamBold
    ToggleFloatMenuBtn.ZIndex = 12
    ToggleFloatMenuBtn.Parent = tunerPage
    Instance.new("UICorner", ToggleFloatMenuBtn).CornerRadius = UDim.new(0, 7)

    -- ============ TUNER LOGIC ============
    local statusThread = nil
    local tunedModels = setmetatable({}, { __mode = "k" })
    local function setStatusTmp(msg, color, revertDelay)
        if not Status or not Status.Parent then return end
        if statusThread then task.cancel(statusThread); statusThread = nil end
        Status.Text = msg
        Status.TextColor3 = color
        statusThread = task.delay(revertDelay or 3, function()
            if Status and Status.Parent then
                Status.Text = "Trạng thái: Sẵn sàng."
                Status.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
        end)
    end
    InjectBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        local isInVehicle = seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat"))
        if not isInVehicle then
            setStatusTmp("❌ Hãy ngồi lên xe rồi bấm áp dụng nhé!", Color3.fromRGB(255, 50, 50))
            return
        end
        local vehicleModel = seat.Parent
        if vehicleModel and tunedModels[vehicleModel] then
            setStatusTmp("⚠ Xe này đã tune rồi — respawn xe để apply", Color3.fromRGB(255, 180, 60), 4)
            return
        end
        local hpMult    = tonumber(hpBox.Text)         or 5.0
        local rpmAdd    = tonumber(rpmBox.Text)        or 3500
        local gearMult  = tonumber(gearRatioBox.Text)  or 0.8
        local finalMult = tonumber(finalDriveBox.Text) or 0.8
        local count = 0
        local charParts = {}
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then charParts[p] = true end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then charParts[hrp] = true end
        end
        local function isCharOwned(t)
            local ok1, res1 = pcall(function()
                for _, v in pairs(t) do
                    if typeof(v) == "Instance" and charParts[v] then return true end
                end
                return false
            end)
            if ok1 and res1 then return true end
            return false
        end
        local function unfreeze(t) pcall(function() setreadonly(t, false) end) end
        local SPEED_KEYS = { topspeed=true, maxspeed=true, speedlimit=true, maxvelocity=true, topspeedkmh=true, maxthrottle=true, limiter=true }
        local POWER_KEYS = { horsepower=true, torque=true, maxpower=true }
        local RPM_KEYS   = { redline=true, maxrpm=true, rpm=true }
        local GEAR_KEYS  = { gearratio=true, finaldrive=true }
        local GEAR_TBL   = { gearratios=true, gears=true }
        local DRAG_KEYS  = { drag=true, dragcoefficient=true, airresistance=true }
        local seen = {}
        local function tuneTable(t, depth)
            if depth > 6 or seen[t] then return end
            if isCharOwned(t) then return end
            seen[t] = true
            unfreeze(t)
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
                            if type(g) == "number" then
                                if pcall(function() v[i] = g * gearMult end) then count = count + 1 end
                            end
                        end
                    elseif DRAG_KEYS[lk] and type(v) == "number" and v > 0 then
                        if pcall(function() t[k] = v * 0.7 end) then count = count + 1 end
                    elseif type(v) == "table" then
                        tuneTable(v, depth + 1)
                    end
                elseif type(v) == "table" then
                    tuneTable(v, depth + 1)
                end
            end
        end
        if typeof(getgc) == "function" then
            pcall(function()
                for _, obj in pairs(getgc(true)) do
                    if typeof(obj) == "table" then
                        pcall(function() tuneTable(obj, 1) end)
                    end
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
                            elseif ln:find("drag") then
                                obj:SetAttribute(an, av * 0.7); count = count + 1
                            end
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
                        elseif name:find("drive") then
                            obj.Value = obj.Value * finalMult; count = count + 1
                        elseif name:find("drag") then
                            obj.Value = obj.Value * 0.7; count = count + 1
                        end
                    end)
                end
            end
        end
        if count == 0 then
            setStatusTmp("⚠ Không tìm thấy gì để tune", Color3.fromRGB(255, 180, 60), 4)
            return
        end
        if vehicleModel then tunedModels[vehicleModel] = true end
        setStatusTmp("✔ Đã tune (xuống xe lên lại)", Color3.fromRGB(0, 255, 120), 4)
    end)

    -- ================= CHUNG =================
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 260)
    scroll.ScrollBarThickness = 4
    scroll.ZIndex = 12
    scroll.Parent = chungPage

    local function makeCard(par, y, title, desc, strokeColor)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -8, 0, 110)
        card.Position = UDim2.new(0, 4, 0, y)
        card.BackgroundColor3 = CARD_BG
        card.BorderSizePixel = 0
        card.ZIndex = 12
        card.Parent = par
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
        local cs = Instance.new("UIStroke", card)
        cs.Color = strokeColor
        cs.Thickness = 1
        cs.Transparency = 0.4
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -24, 0, 20)
        t.Position = UDim2.new(0, 12, 0, 8)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = strokeColor
        t.TextSize = 12
        t.Font = Enum.Font.GothamBold
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 13
        t.Parent = card
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -24, 0, 34)
        d.Position = UDim2.new(0, 12, 0, 30)
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = TXT_DIM
        d.TextSize = 10
        d.Font = Enum.Font.GothamMedium
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextWrapped = true
        d.ZIndex = 13
        d.Parent = card
        return card
    end

    local cardBody = makeCard(scroll, 0, "🚗 THÁO DÀN ÁO — quản lý part xe", "BẬT = hiện nút nổi 🚗 để dùng.\nTẮT = ẩn nút nổi, đóng bảng.", Color3.fromRGB(0, 230, 180))
    bodyOpenBtn = Instance.new("TextButton")
    bodyOpenBtn.Size = UDim2.new(0.9, 0, 0, 28)
    bodyOpenBtn.Position = UDim2.new(0.05, 0, 0, 70)
    bodyOpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    bodyOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bodyOpenBtn.Text = "🚗 DÀN ÁO: ĐANG TẮT"
    bodyOpenBtn.TextSize = 10
    bodyOpenBtn.Font = Enum.Font.GothamBold
    bodyOpenBtn.ZIndex = 13
    bodyOpenBtn.Parent = cardBody
    Instance.new("UICorner", bodyOpenBtn).CornerRadius = UDim.new(0, 6)

    local cardFc = makeCard(scroll, 120, "📷 FREECAM CINEMATIC — quay phim", "BẬT = hiện nút nổi 📷 để dùng.\nTẮT = ẩn nút nổi, đóng menu.", Color3.fromRGB(100, 150, 255))
    fcOpenBtn = Instance.new("TextButton", cardFc)
    fcOpenBtn.Size = UDim2.new(0.9, 0, 0, 28)
    fcOpenBtn.Position = UDim2.new(0.05, 0, 0, 70)
    fcOpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    fcOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fcOpenBtn.Text = "📷 FREECAM: ĐANG TẮT"
    fcOpenBtn.TextSize = 10
    fcOpenBtn.Font = Enum.Font.GothamBold
    fcOpenBtn.ZIndex = 13
    Instance.new("UICorner", fcOpenBtn).CornerRadius = UDim.new(0, 6)

    -- ================= FARMING =================
    local farmScroll = Instance.new("ScrollingFrame")
    farmScroll.Size = UDim2.new(1, 0, 1, 0)
    farmScroll.BackgroundTransparency = 1
    farmScroll.BorderSizePixel = 0
    farmScroll.CanvasSize = UDim2.new(0, 0, 0, 320)   -- gon: office 110 + gap 10 + ridego 160 + pad
    farmScroll.ScrollBarThickness = 4
    farmScroll.ZIndex = 12
    farmScroll.Parent = farmingPage

    local function makeSwitch(par, posY)
        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, 52, 0, 26)
        track.Position = UDim2.new(1, -64, 0, posY)
        track.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        track.Text = ""
        track.ZIndex = 14
        track.Parent = par
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new(0, 3, 0.5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
        knob.ZIndex = 15
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local on = false
        local function set(v)
            on = v
            track.BackgroundColor3 = v and themeColor or Color3.fromRGB(60, 60, 70)
            knob.Position = v and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        end
        return { track = track, knob = knob, set = set, isOn = function() return on end }
    end

    -- OFFICE CARD
    local cardFarm = makeCard(farmScroll, 0, "🌾 OFFICE AUTOFARM — farm văn phòng", "Tự ngồi ghế, giải toán & in ấn.\nSố liệu hiện trong bảng status khi bật.", ACCENT2)
    farmSwitch = makeSwitch(cardFarm, 10)
    farmNote = Instance.new("TextLabel")
    farmNote.Size = UDim2.new(1, -24, 0, 16)
    farmNote.Position = UDim2.new(0, 12, 0, 86)
    farmNote.BackgroundTransparency = 1
    farmNote.Text = ""
    farmNote.TextColor3 = Color3.fromRGB(255, 120, 80)
    farmNote.TextSize = 10
    farmNote.Font = Enum.Font.GothamBold
    farmNote.TextXAlignment = Enum.TextXAlignment.Left
    farmNote.TextWrapped = true
    farmNote.ZIndex = 13
    farmNote.Parent = cardFarm

    -- RIDEGO CARD (gon, khong list inline)
    local cardRide = Instance.new("Frame")
    cardRide.Size = UDim2.new(1, -8, 0, 160)   -- 160px co dinh
    cardRide.Position = UDim2.new(0, 4, 0, 120)
    cardRide.BackgroundColor3 = CARD_BG
    cardRide.BorderSizePixel = 0
    cardRide.ZIndex = 12
    cardRide.Parent = farmScroll
    Instance.new("UICorner", cardRide).CornerRadius = UDim.new(0, 10)
    local rs2 = Instance.new("UIStroke", cardRide)
    rs2.Color = Color3.fromRGB(255, 140, 40)
    rs2.Thickness = 1
    rs2.Transparency = 0.4

    local rideTitle = Instance.new("TextLabel", cardRide)
    rideTitle.Size = UDim2.new(1, -24, 0, 20)
    rideTitle.Position = UDim2.new(0, 12, 0, 8)
    rideTitle.BackgroundTransparency = 1
    rideTitle.Text = "🚕 RIDEGO AUTOFARM"   -- da xoa "tai xe taxi"
    rideTitle.TextColor3 = Color3.fromRGB(255, 140, 40)
    rideTitle.TextSize = 12
    rideTitle.Font = Enum.Font.GothamBold
    rideTitle.TextXAlignment = Enum.TextXAlignment.Left
    rideTitle.ZIndex = 13

    local rideDesc = Instance.new("TextLabel", cardRide)
    rideDesc.Size = UDim2.new(1, -24, 0, 34)
    rideDesc.Position = UDim2.new(0, 12, 0, 30)
    rideDesc.BackgroundTransparency = 1
    rideDesc.Text = "Spawn xe, đón khách, bay xuyên địa hình.\nChọn xe bên dưới trước khi bật."
    rideDesc.TextColor3 = TXT_DIM
    rideDesc.TextSize = 10
    rideDesc.Font = Enum.Font.GothamMedium
    rideDesc.TextXAlignment = Enum.TextXAlignment.Left
    rideDesc.TextWrapped = true
    rideDesc.ZIndex = 13

    ridegoSwitch = makeSwitch(cardRide, 10)

    ridegoPickLbl = Instance.new("TextLabel", cardRide)
    ridegoPickLbl.Size = UDim2.new(1, -24, 0, 18)
    ridegoPickLbl.Position = UDim2.new(0, 12, 0, 70)
    ridegoPickLbl.BackgroundTransparency = 1
    ridegoPickLbl.Text = "🚗 Xe: (chưa chọn)"
    ridegoPickLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
    ridegoPickLbl.TextSize = 10
    ridegoPickLbl.Font = Enum.Font.GothamMedium
    ridegoPickLbl.TextXAlignment = Enum.TextXAlignment.Left
    ridegoPickLbl.TextTruncate = Enum.TextTruncate.AtEnd
    ridegoPickLbl.ZIndex = 13

    ridegoCarBtn = Instance.new("TextButton", cardRide)
    ridegoCarBtn.Size = UDim2.new(1, -24, 0, 30)
    ridegoCarBtn.Position = UDim2.new(0, 12, 0, 92)
    ridegoCarBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
    ridegoCarBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
    ridegoCarBtn.Text = "🚗 CHỌN XE (0)"
    ridegoCarBtn.TextSize = 11
    ridegoCarBtn.Font = Enum.Font.GothamBold
    ridegoCarBtn.TextXAlignment = Enum.TextXAlignment.Left
    ridegoCarBtn.ZIndex = 13
    Instance.new("UICorner", ridegoCarBtn).CornerRadius = UDim.new(0, 6)
    local ridegoCarBtnPad = Instance.new("UIPadding", ridegoCarBtn)
    ridegoCarBtnPad.PaddingLeft = UDim.new(0, 10)

    -- OVERLAY CAR PICKER (con cua farmingPage, de len card farm)
    ridegoCarListPanel = Instance.new("Frame", farmingPage)
    ridegoCarListPanel.Size = UDim2.new(0, 260, 0, 150)
    ridegoCarListPanel.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
    ridegoCarListPanel.BackgroundTransparency = 0.05
    ridegoCarListPanel.BorderSizePixel = 0
    ridegoCarListPanel.Visible = false
    ridegoCarListPanel.ZIndex = 60
    Instance.new("UICorner", ridegoCarListPanel).CornerRadius = UDim.new(0, 8)
    local overlayStroke = Instance.new("UIStroke", ridegoCarListPanel)
    overlayStroke.Color = Color3.fromRGB(255, 140, 40)
    overlayStroke.Thickness = 1.5
    overlayStroke.Transparency = 0.3

    ridegoCarScroll = Instance.new("ScrollingFrame", ridegoCarListPanel)
    ridegoCarScroll.Size = UDim2.new(1, -8, 1, -8)
    ridegoCarScroll.Position = UDim2.new(0, 4, 0, 4)
    ridegoCarScroll.BackgroundTransparency = 1
    ridegoCarScroll.BorderSizePixel = 0
    ridegoCarScroll.ScrollBarThickness = 4
    ridegoCarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ridegoCarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ridegoCarScroll.ZIndex = 61

    local sListR = Instance.new("UIListLayout", ridegoCarScroll)
    sListR.Padding = UDim.new(0, 4)
    sListR.SortOrder = Enum.SortOrder.LayoutOrder
    local sPadR = Instance.new("UIPadding", ridegoCarScroll)
    sPadR.PaddingTop = UDim.new(0, 4)
    sPadR.PaddingLeft = UDim.new(0, 4)
    sPadR.PaddingRight = UDim.new(0, 4)
    sPadR.PaddingBottom = UDim.new(0, 4)

    ridegoCarListWrap = ridegoCarScroll

    -- ================= SETTINGS =================
    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Size = UDim2.new(1, 0, 1, 0)
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0
    settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settingsScroll.ScrollBarThickness = 4
    settingsScroll.ZIndex = 12
    settingsScroll.Parent = settingsPage

    local settingsList = Instance.new("UIListLayout", settingsScroll)
    settingsList.Padding = UDim.new(0, 6)
    settingsList.SortOrder = Enum.SortOrder.LayoutOrder
    local settingsPad = Instance.new("UIPadding", settingsScroll)
    settingsPad.PaddingTop = UDim.new(0, 8)
    settingsPad.PaddingLeft = UDim.new(0, 4)
    settingsPad.PaddingRight = UDim.new(0, 4)
    settingsPad.PaddingBottom = UDim.new(0, 8)

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
        local r = tonumber(input:sub(1,2), 16)
        local g = tonumber(input:sub(3,4), 16)
        local b = tonumber(input:sub(5,6), 16)
        if not (r and g and b) then return nil end
        return Color3.fromRGB(r, g, b), input:upper()
    end
    local QUAL = {
        Enum.SavedQualitySetting.QualityLevel1, Enum.SavedQualitySetting.QualityLevel2,
        Enum.SavedQualitySetting.QualityLevel3, Enum.SavedQualitySetting.QualityLevel4,
        Enum.SavedQualitySetting.QualityLevel5, Enum.SavedQualitySetting.QualityLevel6,
        Enum.SavedQualitySetting.QualityLevel7, Enum.SavedQualitySetting.QualityLevel8,
        Enum.SavedQualitySetting.QualityLevel9, Enum.SavedQualitySetting.QualityLevel10,
    }
    local function setQualityLevel(idx)
        pcall(function()
            if idx == nil then
                UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
            else
                UserSettings().GameSettings.SavedQualityLevel = QUAL[idx]
            end
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
        section.Size = UDim2.new(1, -8, 0, 0)
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.BackgroundTransparency = 1
        section.LayoutOrder = order
        local sl = Instance.new("UIListLayout", section)
        sl.Padding = UDim.new(0, 0)
        sl.SortOrder = Enum.SortOrder.LayoutOrder
        local header = Instance.new("TextButton", section)
        header.Size = UDim2.new(1, 0, 0, 28)
        header.LayoutOrder = 1
        header.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
        header.TextColor3 = themeColor
        header.TextSize = 11
        header.Font = Enum.Font.GothamBold
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.ZIndex = 14
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)
        local hp = Instance.new("UIPadding", header)
        hp.PaddingLeft = UDim.new(0, 8)
        local content = Instance.new("Frame", section)
        content.Size = UDim2.new(1, 0, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.LayoutOrder = 2
        content.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
        content.BorderSizePixel = 0
        content.Visible = defaultOpen or false
        content.ZIndex = 13
        Instance.new("UICorner", content).CornerRadius = UDim.new(0, 6)
        local cl = Instance.new("UIListLayout", content)
        cl.Padding = UDim.new(0, 4)
        cl.SortOrder = Enum.SortOrder.LayoutOrder
        local cp = Instance.new("UIPadding", content)
        cp.PaddingTop = UDim.new(0, 8); cp.PaddingBottom = UDim.new(0, 8)
        cp.PaddingLeft = UDim.new(0, 8); cp.PaddingRight = UDim.new(0, 8)
        local isOpen = defaultOpen or false
        header.Text = (isOpen and "▼ " or "▶ ") .. title
        header.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            content.Visible = isOpen
            header.Text = (isOpen and "▼ " or "▶ ") .. title
        end)
        return content
    end

    local function makeToggle(parent, order, defaultOn, labelOn, labelOff, colorOn, colorOff, cb)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1, 0, 0, 28)
        b.LayoutOrder = order
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.ZIndex = 14
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local on = defaultOn
        local function paint()
            b.Text = on and labelOn or labelOff
            b.BackgroundColor3 = on and colorOn or colorOff
        end
        paint()
        b.MouseButton1Click:Connect(function()
            on = not on
            paint()
            cb(on)
        end)
        return b
    end

    local function makeInput(parent, order, label, placeholder, btnText, color, onClick)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 26)
        row.LayoutOrder = order
        row.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0, 80, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(200, 210, 220)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local box = Instance.new("TextBox", row)
        box.Size = UDim2.new(1, -160, 1, 0)
        box.Position = UDim2.new(0, 82, 0, 0)
        box.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.PlaceholderText = placeholder
        box.Text = ""
        box.TextSize = 10
        box.Font = Enum.Font.GothamBold
        box.BorderSizePixel = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(0, 72, 1, 0)
        btn.Position = UDim2.new(1, -72, 0, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(0, 150, 120)
        btn.Text = btnText
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local status = Instance.new("TextLabel", parent)
        status.Size = UDim2.new(1, 0, 0, 14)
        status.LayoutOrder = order + 0.5
        status.BackgroundTransparency = 1
        status.Text = ""
        status.TextColor3 = Color3.fromRGB(140, 255, 140)
        status.TextSize = 9
        status.Font = Enum.Font.GothamBold
        status.TextXAlignment = Enum.TextXAlignment.Left
        btn.MouseButton1Click:Connect(function()
            onClick(box.Text, function(msg, ok)
                status.Text = msg
                status.TextColor3 = ok and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 120, 120)
            end)
        end)
        return box
    end

    -- SECTION 1: MAU MENU
    local colorSection = makeSection(1, "🎨 Màu menu (chính)", false)
    local colorRow = Instance.new("Frame", colorSection)
    colorRow.Size = UDim2.new(1, 0, 0, 30)
    colorRow.LayoutOrder = 1
    colorRow.BackgroundTransparency = 1
    local colorList = Instance.new("UIListLayout", colorRow)
    colorList.FillDirection = Enum.FillDirection.Horizontal
    colorList.Padding = UDim.new(0, 4)
    local themePresets = {
        Color3.fromRGB(0, 229, 160),
        Color3.fromRGB(56, 189, 248),
        Color3.fromRGB(167, 139, 250),
        Color3.fromRGB(255, 100, 100),
        Color3.fromRGB(255, 170, 60),
        Color3.fromRGB(255, 110, 190),
    }
    for _, c in ipairs(themePresets) do
        local sw = Instance.new("TextButton", colorRow)
        sw.Size = UDim2.new(0, 26, 1, 0)
        sw.BackgroundColor3 = c
        sw.Text = ""
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 6)
        sw.MouseButton1Click:Connect(function()
            menuRainbow = false
            menuFixedColor = c
            applyTheme(c)
        end)
    end
    local rainbowSw = Instance.new("TextButton", colorRow)
    rainbowSw.Size = UDim2.new(0, 26, 1, 0)
    rainbowSw.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
    rainbowSw.Text = "🌈"
    rainbowSw.TextSize = 14
    rainbowSw.Font = Enum.Font.GothamBold
    rainbowSw.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", rainbowSw).CornerRadius = UDim.new(0, 6)
    rainbowSw.MouseButton1Click:Connect(function() menuRainbow = true end)

    makeInput(colorSection, 2, "Mã menu", "#00E5A0", "ÁP DỤNG", Color3.fromRGB(0, 150, 120), function(txt, cb)
        local col, up = parseHex(txt)
        if not col then cb("❌ mã màu sai (VD: #00E5A0)", false) return end
        menuRainbow = false
        menuFixedColor = col
        applyTheme(col)
        cb("✔ màu menu = #" .. up, true)
    end)

    -- SECTION 2: LED NUT NOI
    local ledSection = makeSection(2, "💡 LED nút nổi", false)
    makeToggle(ledSection, 1, ledOn, "💡 LED NÚT NỔI: BẬT", "💡 LED NÚT NỔI: TẮT", Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70), function(v)
        ledOn = v
    end)
    local ledColorRow = Instance.new("Frame", ledSection)
    ledColorRow.Size = UDim2.new(1, 0, 0, 30)
    ledColorRow.LayoutOrder = 2
    ledColorRow.BackgroundTransparency = 1
    local ledColorList = Instance.new("UIListLayout", ledColorRow)
    ledColorList.FillDirection = Enum.FillDirection.Horizontal
    ledColorList.Padding = UDim.new(0, 4)
    for _, c in ipairs(themePresets) do
        local sw = Instance.new("TextButton", ledColorRow)
        sw.Size = UDim2.new(0, 26, 1, 0)
        sw.BackgroundColor3 = c
        sw.Text = ""
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 6)
        sw.MouseButton1Click:Connect(function()
            ledMode = "fixed"; ledFixedColor = c; ledOn = true
        end)
    end
    local ledRainbowSw = Instance.new("TextButton", ledColorRow)
    ledRainbowSw.Size = UDim2.new(0, 26, 1, 0)
    ledRainbowSw.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
    ledRainbowSw.Text = "🌈"
    ledRainbowSw.TextSize = 14
    ledRainbowSw.Font = Enum.Font.GothamBold
    ledRainbowSw.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", ledRainbowSw).CornerRadius = UDim.new(0, 6)
    ledRainbowSw.MouseButton1Click:Connect(function()
        ledMode = "rainbow"; ledOn = true
    end)
    makeInput(ledSection, 3, "Mã LED", "#FF00AA", "ÁP DỤNG", Color3.fromRGB(0, 150, 120), function(txt, cb)
        local col, up = parseHex(txt)
        if not col then cb("❌ hex sai", false) return end
        ledMode = "fixed"; ledFixedColor = col; ledOn = true
        cb("✔ LED = #" .. up, true)
    end)
    makeToggle(ledSection, 4, ledMode == "rainbow", "🌈 LED: RAINBOW", "🌈 LED: ĐƠN SẮC", Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70), function(v)
        if v then ledMode = "rainbow" else ledMode = "fixed" end
    end)

    -- SECTION 3: TEN HIEN THI
    local nameSection = makeSection(3, "👤 Tên hiển thị", false)
    makeToggle(nameSection, 1, false, "👤 ẨN TÊN: BẬT", "👤 ẨN TÊN: TẮT", Color3.fromRGB(120, 80, 200), Color3.fromRGB(60, 60, 70), function(v)
        hideNameOn = v
        if v then hideNameTags() else showNameTags() end
    end)
    makeInput(nameSection, 2, "Tên mới", "Nhập tên", "ĐỔI TÊN", Color3.fromRGB(120, 80, 200), function(txt, cb)
        if txt == "" then cb("❌ nhập tên trước", false) return end
        customName = txt
        applyCustomName()
        cb("✔ đã đổi tên", true)
    end)

    -- SECTION 4: HIEU NANG
    local perfSection = makeSection(4, "⚡ Hiệu năng", false)
    makeToggle(perfSection, 1, false, "⚡ TỐI ƯU FPS: BẬT", "⚡ TỐI ƯU FPS: TẮT", Color3.fromRGB(40, 110, 180), Color3.fromRGB(60, 60, 70), function(v)
        optFPS = v
        if v then
            pcall(function() Lighting.GlobalShadows = false end)
            bloomSet(false); sunSet(false)
            pcall(function() workspace.StreamingEnabled = true end)
            setQualityLevel(4)
        else
            pcall(function() Lighting.GlobalShadows = true end)
            pcall(function() Lighting.Brightness = 2 end)
            bloomSet(true, 0.4, 0.8)
            setQualityLevel(nil)
        end
    end)
    makeToggle(perfSection, 2, false, "🎨 CHẤT LƯỢNG CAO: BẬT", "🎨 CHẤT LƯỢNG CAO: TẮT", Color3.fromRGB(160, 100, 200), Color3.fromRGB(60, 60, 70), function(v)
        if v then
            pcall(function() Lighting.GlobalShadows = true end)
            pcall(function() Lighting.Brightness = 3 end)
            bloomSet(true, 0.6, 0.7); sunSet(true, 0.3)
            setQualityLevel(10)
        else
            bloomSet(true, 0.4, 0.8); sunSet(false)
            setQualityLevel(nil)
        end
    end)
    makeToggle(perfSection, 3, false, "📊 FPS/PING: BẬT", "📊 FPS/PING: TẮT", Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70), function(v)
        perfOn = v; perfFrame.Visible = v
    end)
    makeToggle(perfSection, 4, false, "🔒 KHÓA VỊ TRÍ: BẬT", "🔒 KHÓA VỊ TRÍ: TẮT", Color3.fromRGB(180, 120, 40), Color3.fromRGB(60, 60, 70), function(v)
        perfLocked = v; perfFrame.Draggable = not v
    end)

    -- SECTION 5: SERVER
    local serverSection = makeSection(5, "🔄 Server", false)
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
    btnHop.Size = UDim2.new(1, 0, 0, 28)
    btnHop.LayoutOrder = 1
    btnHop.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
    btnHop.Text = "🎲 SERVER HOP"
    btnHop.TextColor3 = Color3.new(1,1,1)
    btnHop.TextSize = 10
    btnHop.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnHop).CornerRadius = UDim.new(0, 7)
    local btnSmall = Instance.new("TextButton", serverSection)
    btnSmall.Size = UDim2.new(1, 0, 0, 28)
    btnSmall.LayoutOrder = 2
    btnSmall.BackgroundColor3 = Color3.fromRGB(40, 120, 90)
    btnSmall.Text = "🐜 SMALL SERVER"
    btnSmall.TextColor3 = Color3.new(1,1,1)
    btnSmall.TextSize = 10
    btnSmall.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnSmall).CornerRadius = UDim.new(0, 7)
    local btnRejoin = Instance.new("TextButton", serverSection)
    btnRejoin.Size = UDim2.new(1, 0, 0, 28)
    btnRejoin.LayoutOrder = 3
    btnRejoin.BackgroundColor3 = Color3.fromRGB(140, 80, 40)
    btnRejoin.Text = "🔁 REJOIN"
    btnRejoin.TextColor3 = Color3.new(1,1,1)
    btnRejoin.TextSize = 10
    btnRejoin.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnRejoin).CornerRadius = UDim.new(0, 7)
    btnHop.MouseButton1Click:Connect(function()
        local servers = fetchServers(); if not servers then return end
        for _, s in ipairs(servers) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player) end)
                return
            end
        end
    end)
    btnSmall.MouseButton1Click:Connect(function()
        local servers = fetchServers(); if not servers then return end
        local best = nil
        for _, s in ipairs(servers) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                if not best or s.playing < best.playing then best = s end
            end
        end
        if best then pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, player) end) end
    end)
    btnRejoin.MouseButton1Click:Connect(function()
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    end)

    -- SECTION 6: AUTO REJOIN
    local rejoinSection = makeSection(6, "🤖 Auto Rejoin", false)
    local rejoinNote = Instance.new("TextLabel", rejoinSection)
    rejoinNote.Size = UDim2.new(1, 0, 0, 28)
    rejoinNote.LayoutOrder = 1
    rejoinNote.BackgroundTransparency = 1
    rejoinNote.Text = "Auto Execute: tự load script khi vào game\nAuto Rejoin: tự vào lại khi bị kick\n2 chức năng độc lập"
    rejoinNote.TextColor3 = Color3.fromRGB(160, 170, 190)
    rejoinNote.TextSize = 9
    rejoinNote.Font = Enum.Font.GothamMedium
    rejoinNote.TextXAlignment = Enum.TextXAlignment.Left
    rejoinNote.TextYAlignment = Enum.TextYAlignment.Top
    rejoinNote.TextWrapped = true
    makeToggle(rejoinSection, 2, readFlag("autoExecute.txt"), "🔄 AUTO EXECUTE: BẬT", "🔄 AUTO EXECUTE: TẮT", Color3.fromRGB(120, 80, 200), Color3.fromRGB(60, 60, 70), function(v)
        if writefile then pcall(writefile, "autoExecute.txt", v and "1" or "0") end
        if v and queue_on_teleport then
            pcall(queue_on_teleport, [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()
]])
        end
    end)
    makeToggle(rejoinSection, 3, readFlag("autoRejoin.txt"), "🔁 AUTO REJOIN: BẬT", "🔁 AUTO REJOIN: TẮT", Color3.fromRGB(140, 80, 40), Color3.fromRGB(60, 60, 70), function(v)
        if writefile then pcall(writefile, "autoRejoin.txt", v and "1" or "0") end
    end)

    -- SECTION 7: ANTI-AFK
    local afkSection = makeSection(7, "🛡️ Anti-AFK", false)
    makeToggle(afkSection, 1, true, "🛡️ ANTI-AFK: BẬT", "🛡️ ANTI-AFK: TẮT", Color3.fromRGB(46, 140, 67), Color3.fromRGB(60, 60, 70), function(v)
        antiAfk = v
    end)

    selectPage("TUNER")

    function applyTheme(c)
        themeColor = c
        if not menuRainbow then
            hubStroke.Color = c
            hubHeader.TextColor3 = c
            ToggleBtn.TextColor3 = c
        end
        if currentPageName then selectPage(currentPageName) end
        if farmSwitch and farmSwitch.isOn() then farmSwitch.set(true) end
        if ridegoSwitch and ridegoSwitch.isOn() then ridegoSwitch.set(true) end
    end

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

    HubFrame.Visible = true
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
-- KHOI 3: QUAN LY DAN AO
-- ============================================================
do
    local currentVehicle = nil
    local selectedPart = nil
    local selectedParentContainer = nil
    local modeActive = false
    local originalParents = {}
    local originalTransparencies = {}
    local originalColors = {}
    local originalMaterials = {}
    local originalDecalTransparencies = {}
    local modelPartsList = {}
    local currentIndex = 1
    local lastSelectedPart = nil
    ControlPanel = Instance.new("Frame")
    ControlPanel.Name = "ControlPanel"
    ControlPanel.Parent = ScreenGui
    ControlPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    ControlPanel.Position = UDim2.new(0.5, 190, 0.5, -175)
    ControlPanel.Size = UDim2.new(0, 280, 0, 350)
    ControlPanel.Visible = false
    ControlPanel.Active = true
    ControlPanel.Draggable = true
    ControlPanel.ZIndex = 9
    Instance.new("UICorner", ControlPanel).CornerRadius = UDim.new(0, 12)
    local ControlStroke = Instance.new("UIStroke", ControlPanel)
    ControlStroke.Color = Color3.fromRGB(0, 230, 180)
    ControlStroke.Thickness = 1.5
    local ControlTitle = Instance.new("TextLabel")
    ControlTitle.Parent = ControlPanel
    ControlTitle.BackgroundTransparency = 1
    ControlTitle.Position = UDim2.new(0, 15, 0, 10)
    ControlTitle.Size = UDim2.new(1, -30, 0, 25)
    ControlTitle.Font = Enum.Font.GothamBold
    ControlTitle.Text = "🚗 QUẢN LÝ & THÁO DÀN ÁO"
    ControlTitle.TextColor3 = Color3.fromRGB(0, 230, 180)
    ControlTitle.TextSize = 12
    ControlTitle.TextXAlignment = Enum.TextXAlignment.Left
    makeHeaderDraggable(ControlTitle, ControlPanel)
    local ToggleModeBtn = Instance.new("TextButton")
    ToggleModeBtn.Parent = ControlPanel
    ToggleModeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    ToggleModeBtn.Position = UDim2.new(0, 15, 0, 42)
    ToggleModeBtn.Size = UDim2.new(1, -30, 0, 32)
    ToggleModeBtn.Font = Enum.Font.GothamBold
    ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"
    ToggleModeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    ToggleModeBtn.TextSize = 11
    Instance.new("UICorner", ToggleModeBtn).CornerRadius = UDim.new(0, 8)
    local StatusText = Instance.new("TextLabel")
    StatusText.Parent = ControlPanel
    StatusText.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    StatusText.Position = UDim2.new(0, 15, 0, 80)
    StatusText.Size = UDim2.new(1, -30, 0, 50)
    StatusText.Font = Enum.Font.Gotham
    StatusText.Text = " Part: Chưa chọn\nCụm: Chưa chọn\nSố part trong cụm: 0"
    StatusText.TextColor3 = Color3.fromRGB(220, 220, 220)
    StatusText.TextSize = 10
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.TextYAlignment = Enum.TextYAlignment.Center
    Instance.new("UICorner", StatusText).CornerRadius = UDim.new(0, 6)
    local function createActionButton(name, posY, posX, sizeX, color)
        local btn = Instance.new("TextButton")
        btn.Parent = ControlPanel
        btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 55)
        btn.Position = UDim2.new(0, posX, 0, posY)
        btn.Size = UDim2.new(0, sizeX, 0, 30)
        btn.Font = Enum.Font.GothamBold
        btn.Name = name
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 10
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end
    local HidePartBtn = createActionButton("Tháo Part Này", 140, 15, 120, Color3.fromRGB(50, 50, 65))
    local HideCompBtn = createActionButton("Tháo Cả Cụm", 140, 145, 120, Color3.fromRGB(50, 50, 65))
    local PrevPartBtn  = createActionButton("◀ Mảnh Trước", 176, 15, 120, Color3.fromRGB(40, 90, 110))
    local NextPartBtn  = createActionButton("Mảnh Sau ▶", 176, 145, 120, Color3.fromRGB(40, 90, 110))
    local DeselectBtn  = createActionButton("Bỏ Chọn", 212, 15, 120, Color3.fromRGB(50, 50, 65))
    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Parent = ControlPanel
    ScanBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    ScanBtn.Position = UDim2.new(0, 145, 0, 212)
    ScanBtn.Size = UDim2.new(0, 120, 0, 30)
    ScanBtn.Font = Enum.Font.GothamBold
    ScanBtn.Text = "Quét Lại Xe"
    ScanBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
    ScanBtn.TextSize = 10
    Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)
    local RestoreBtn   = createActionButton("Khôi Phục Toàn Bộ", 248, 15, 250, Color3.fromRGB(160, 40, 40))
    BodyManagerFloatingBtn.MouseButton1Click:Connect(function()
        ControlPanel.Visible = not ControlPanel.Visible
        if ControlPanel.Visible then
            BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 100)
        else
            BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        end
    end)
    local CloseControlBtn = Instance.new("TextButton")
    CloseControlBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseControlBtn.Position = UDim2.new(1, -28, 0, 6)
    CloseControlBtn.BackgroundTransparency = 1
    CloseControlBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    CloseControlBtn.Text = "✕"
    CloseControlBtn.TextSize = 13
    CloseControlBtn.Font = Enum.Font.GothamBold
    CloseControlBtn.Parent = ControlPanel
    CloseControlBtn.MouseButton1Click:Connect(function()
        ControlPanel.Visible = false
        BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    end)
    local SelectionBoxObj = Instance.new("SelectionBox")
    SelectionBoxObj.Color3 = Color3.fromRGB(0, 230, 180)
    SelectionBoxObj.LineThickness = 0.05
    SelectionBoxObj.Adornee = nil
    pcall(function() SelectionBoxObj.Parent = CoreGui end)
    if SelectionBoxObj.Parent ~= CoreGui then SelectionBoxObj.Parent = ScreenGui end
    ScanBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then
            ScanBtn.Text = "Không tìm thấy nhân vật!"
            task.wait(1.5); ScanBtn.Text = "Quét Lại Xe"; return
        end
        local humanoid = char.Humanoid
        local seatPart = humanoid.SeatPart
        if not seatPart then
            ScanBtn.Text = "Hãy ngồi lên xe!"
            task.wait(1.5); ScanBtn.Text = "Quét Lại Xe"; return
        end
        local model = seatPart.Parent
        while model and model ~= workspace and not model:FindFirstChildOfClass("Humanoid") do
            if model.Parent == workspace then break end
            model = model.Parent
        end
        if model then
            currentVehicle = model
            ScanBtn.Text = "Quét Thành Công!"
            task.wait(1.5); ScanBtn.Text = "Quét Lại Xe"
        else
            ScanBtn.Text = "Không nhận diện!"
            task.wait(1.5); ScanBtn.Text = "Quét Lại Xe"
        end
    end)
    local function restorePartAppearance()
        if lastSelectedPart and originalTransparencies[lastSelectedPart] then
            lastSelectedPart.Transparency = originalTransparencies[lastSelectedPart]
            lastSelectedPart.Color = originalColors[lastSelectedPart]
            lastSelectedPart.Material = originalMaterials[lastSelectedPart]
            originalTransparencies[lastSelectedPart] = nil
            originalColors[lastSelectedPart] = nil
            originalMaterials[lastSelectedPart] = nil
        end
        for decal, trans in pairs(originalDecalTransparencies) do
            if decal and decal.Parent then decal.Transparency = trans end
        end
        originalDecalTransparencies = {}
        SelectionBoxObj.Adornee = nil
    end
    ToggleModeBtn.MouseButton1Click:Connect(function()
        if not currentVehicle then
            ToggleModeBtn.Text = "Hãy Quét Xe Trước!"
            task.wait(1.5); ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"; return
        end
        modeActive = not modeActive
        if modeActive then
            ToggleModeBtn.Text = "Chế độ Soi & Tháo: BẬT"
            ToggleModeBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"
            ToggleModeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            restorePartAppearance()
            selectedPart = nil; selectedParentContainer = nil
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
        selectedPart.Transparency = 0.15
        selectedPart.Color = Color3.fromRGB(0, 220, 180)
        selectedPart.Material = Enum.Material.Neon
        for _, descendant in ipairs(selectedPart:GetDescendants()) do
            if descendant:IsA("Decal") or descendant:IsA("Texture") then
                originalDecalTransparencies[descendant] = descendant.Transparency
                descendant.Transparency = 0
            end
        end
        local containerName = selectedParentContainer and selectedParentContainer.Name or "Không rõ"
        StatusText.Text = string.format(" Part: %s\nCụm: %s\nSố part trong cụm: %d", selectedPart.Name, containerName, #modelPartsList)
        SelectionBoxObj.Adornee = selectedPart
    end
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not modeActive or not currentVehicle then return end
        if gameProcessed then return end
        local screenPos = nil
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            screenPos = UserInputService:GetMouseLocation()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            screenPos = Vector2.new(input.Position.X, input.Position.Y)
        end
        if screenPos then
            local unitRay = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
            local currentOrigin = unitRay.Origin
            local currentDir = unitRay.Direction * 600
            local targetPart = nil
            for i = 1, 8 do
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Include
                raycastParams.FilterDescendantsInstances = {currentVehicle}
                raycastParams.IgnoreWater = true
                local raycastResult = workspace:Raycast(currentOrigin, currentDir, raycastParams)
                if raycastResult and raycastResult.Instance then
                    local hit = raycastResult.Instance
                    local hitName = hit.Name:lower()
                    if hit.Parent == nil or hitName:find("weight") or hitName:find("hitbox") or hitName:find("collider") or hitName:find("chassis") or hitName:find("seat") then
                        currentOrigin = raycastResult.Position + (unitRay.Direction.Unit * 0.2)
                        currentDir = (unitRay.Origin + unitRay.Direction * 600) - currentOrigin
                    else
                        targetPart = hit
                        break
                    end
                else
                    break
                end
            end
            if targetPart and targetPart:IsA("BasePart") then
                selectedPart = targetPart
                selectedParentContainer = targetPart.Parent
                modelPartsList = {}
                if selectedParentContainer and (selectedParentContainer:IsA("Model") or selectedParentContainer:IsA("Folder")) then
                    for _, child in ipairs(selectedParentContainer:GetDescendants()) do
                        if child:IsA("BasePart") then table.insert(modelPartsList, child) end
                    end
                else
                    table.insert(modelPartsList, selectedPart)
                end
                for i, p in ipairs(modelPartsList) do
                    if p == targetPart then currentIndex = i; break end
                end
                updateSelectionInfo()
            end
        end
    end)
    local function hideSinglePart(part)
        if not part or not part:IsA("BasePart") then return end
        if part == lastSelectedPart then
            originalTransparencies[part] = nil
            originalColors[part] = nil
            originalMaterials[part] = nil
            lastSelectedPart = nil
        end
        for _, descendant in ipairs(part:GetDescendants()) do
            if descendant:IsA("Decal") or descendant:IsA("Texture") then
                originalDecalTransparencies[descendant] = nil
            end
        end
        if not originalParents[part] then originalParents[part] = part.Parent end
        part.Parent = nil
        SelectionBoxObj.Adornee = nil
    end
    HidePartBtn.MouseButton1Click:Connect(function()
        if selectedPart and selectedPart:IsA("BasePart") then
            hideSinglePart(selectedPart)
            local foundNext = false
            if #modelPartsList > 0 then
                for count = 1, #modelPartsList do
                    currentIndex = currentIndex % #modelPartsList + 1
                    local p = modelPartsList[currentIndex]
                    if p and p.Parent ~= nil then
                        selectedPart = p; foundNext = true; break
                    end
                end
            end
            if foundNext then updateSelectionInfo()
            else
                restorePartAppearance()
                selectedPart = nil; selectedParentContainer = nil
                modelPartsList = {}; lastSelectedPart = nil
                updateSelectionInfo()
            end
        end
    end)
    HideCompBtn.MouseButton1Click:Connect(function()
        if selectedParentContainer then
            for _, child in ipairs(selectedParentContainer:GetDescendants()) do
                if child:IsA("BasePart") then hideSinglePart(child) end
            end
            restorePartAppearance()
            selectedPart = nil; selectedParentContainer = nil
            modelPartsList = {}; lastSelectedPart = nil
            updateSelectionInfo()
        end
    end)
    NextPartBtn.MouseButton1Click:Connect(function()
        if #modelPartsList > 0 then
            local found = false
            for count = 1, #modelPartsList do
                currentIndex = currentIndex % #modelPartsList + 1
                local p = modelPartsList[currentIndex]
                if p and p.Parent ~= nil then selectedPart = p; found = true; break end
            end
            if found then updateSelectionInfo()
            else selectedPart = nil; SelectionBoxObj.Adornee = nil end
        end
    end)
    PrevPartBtn.MouseButton1Click:Connect(function()
        if #modelPartsList > 0 then
            local found = false
            for count = 1, #modelPartsList do
                currentIndex = currentIndex - 1
                if currentIndex < 1 then currentIndex = #modelPartsList end
                local p = modelPartsList[currentIndex]
                if p and p.Parent ~= nil then selectedPart = p; found = true; break end
            end
            if found then updateSelectionInfo()
            else selectedPart = nil; SelectionBoxObj.Adornee = nil end
        end
    end)
    DeselectBtn.MouseButton1Click:Connect(function()
        restorePartAppearance()
        selectedPart = nil; selectedParentContainer = nil
        modelPartsList = {}; lastSelectedPart = nil
        updateSelectionInfo()
    end)
    RestoreBtn.MouseButton1Click:Connect(function()
        for part, originalParent in pairs(originalParents) do
            if part and originalParent and originalParent.Parent then
                part.Parent = originalParent
            end
        end
        originalParents = {}
        restorePartAppearance()
        selectedPart = nil; selectedParentContainer = nil
        modelPartsList = {}; lastSelectedPart = nil
        updateSelectionInfo()
    end)
end

-- ============================================================
-- KHOI 4: FREECAM CINEMATIC
-- ============================================================
do
    local function addStroke(par, color, thickness)
        local stroke = Instance.new("UIStroke", par)
        stroke.Color = color or Color3.fromRGB(60, 60, 75)
        stroke.Thickness = thickness or 1.5
        return stroke
    end
    freecamMenuFrame = Instance.new("Frame", ScreenGui)
    freecamMenuFrame.Size = UDim2.new(0, 280, 0, 310)
    freecamMenuFrame.Position = UDim2.new(0.5, -140, 0.5, -155)
    freecamMenuFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 21)
    freecamMenuFrame.BackgroundTransparency = 0.12
    freecamMenuFrame.Visible = false
    freecamMenuFrame.ZIndex = 15
    Instance.new("UICorner", freecamMenuFrame).CornerRadius = UDim.new(0, 14)
    addStroke(freecamMenuFrame, Color3.fromRGB(70, 70, 95), 1.5)
    local freecamMenuTitle = Instance.new("TextLabel", freecamMenuFrame)
    freecamMenuTitle.Size = UDim2.new(1, 0, 0, 45)
    freecamMenuTitle.BackgroundTransparency = 1
    freecamMenuTitle.Text = "Freecam Cinematic"
    freecamMenuTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
    freecamMenuTitle.TextSize = 15
    freecamMenuTitle.Font = Enum.Font.GothamBold
    freecamMenuTitle.ZIndex = 16
    local function createFreecamMenuBtn(posY, text, color)
        local btn = Instance.new("TextButton", freecamMenuFrame)
        btn.Size = UDim2.new(0.88, 0, 0, 36)
        btn.Position = UDim2.new(0.06, 0, 0, posY)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(235, 235, 245)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 16
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        addStroke(btn, Color3.fromRGB(80, 80, 100), 0.8)
        return btn
    end
    local freecamToggleBtn = createFreecamMenuBtn(45, "Freecam: OFF", Color3.fromRGB(45, 45, 58))
    local hideAllBtn = createFreecamMenuBtn(90, "Ẩn Giao Diện: OFF", Color3.fromRGB(50, 50, 68))
    local speedLabel = Instance.new("TextLabel", freecamMenuFrame)
    speedLabel.Size = UDim2.new(0.88, 0, 0, 22)
    speedLabel.Position = UDim2.new(0.06, 0, 0, 135)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    speedLabel.TextSize = 12
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.Text = "Tốc độ di chuyển: 25.0"
    speedLabel.ZIndex = 16
    local speedIncBtn = createFreecamMenuBtn(160, "Tăng Tốc (+)", Color3.fromRGB(50, 50, 68))
    speedIncBtn.Size = UDim2.new(0.42, 0, 0, 32)
    speedIncBtn.Position = UDim2.new(0.06, 0, 0, 160)
    local speedDecBtn = createFreecamMenuBtn(160, "Giảm Tốc (-)", Color3.fromRGB(50, 50, 68))
    speedDecBtn.Size = UDim2.new(0.42, 0, 0, 32)
    speedDecBtn.Position = UDim2.new(0.52, 0, 0, 160)
    local rotLabel = Instance.new("TextLabel", freecamMenuFrame)
    rotLabel.Size = UDim2.new(0.88, 0, 0, 22)
    rotLabel.Position = UDim2.new(0.06, 0, 0, 200)
    rotLabel.BackgroundTransparency = 1
    rotLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    rotLabel.TextSize = 12
    rotLabel.Font = Enum.Font.GothamBold
    rotLabel.Text = "Tốc độ xoay: 1.0x"
    rotLabel.ZIndex = 16
    local rotIncBtn = createFreecamMenuBtn(225, "Xoay Nhanh (+)", Color3.fromRGB(50, 50, 68))
    rotIncBtn.Size = UDim2.new(0.42, 0, 0, 32)
    rotIncBtn.Position = UDim2.new(0.06, 0, 0, 225)
    local rotDecBtn = createFreecamMenuBtn(225, "Xoay Chậm (-)", Color3.fromRGB(50, 50, 68))
    rotDecBtn.Size = UDim2.new(0.42, 0, 0, 32)
    rotDecBtn.Position = UDim2.new(0.52, 0, 0, 225)
    hideFloatBtn = Instance.new("TextButton", ScreenGui)
    hideFloatBtn.Size = UDim2.new(0, 52, 0, 52)
    hideFloatBtn.Position = UDim2.new(0, 80, 0, 150)
    hideFloatBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    hideFloatBtn.BackgroundTransparency = 0.2
    hideFloatBtn.Text = "👁️"
    hideFloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hideFloatBtn.TextSize = 22
    hideFloatBtn.Font = Enum.Font.GothamBold
    hideFloatBtn.ZIndex = 10
    Instance.new("UICorner", hideFloatBtn).CornerRadius = UDim.new(0, 7)
    addStroke(hideFloatBtn, Color3.fromRGB(80, 80, 110), 2)
    hideFloatBtn.Visible = false
    local controlFrame = Instance.new("Frame", ScreenGui)
    controlFrame.Size = UDim2.new(0, 205, 0, 195)
    controlFrame.Position = UDim2.new(0, 20, 1, -200)
    controlFrame.BackgroundTransparency = 1
    controlFrame.Visible = false
    controlFrame.ZIndex = 1
    local controlButtons = {}
    local function createPadBtn(text, size, pos)
        local btn = Instance.new("TextButton", controlFrame)
        btn.Size = size
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        btn.BackgroundTransparency = 0.35
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(240, 240, 250)
        btn.TextSize = 15
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 2
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        addStroke(btn, Color3.fromRGB(70, 70, 95), 1)
        table.insert(controlButtons, btn)
        return btn
    end
    local btnW = createPadBtn("▲", UDim2.new(0, 44, 0, 44), UDim2.new(0, 48, 0, 0))
    local btnS = createPadBtn("▼", UDim2.new(0, 44, 0, 44), UDim2.new(0, 48, 0, 96))
    local btnA = createPadBtn("◀", UDim2.new(0, 44, 0, 44), UDim2.new(0, 0, 0, 48))
    local btnD = createPadBtn("▶", UDim2.new(0, 44, 0, 44), UDim2.new(0, 96, 0, 48))
    local btnUp = createPadBtn("+", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 0))
    local btnDown = createPadBtn("-", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 48))
    local btnZoomIn = createPadBtn("🔍+", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 100))
    local btnZoomOut = createPadBtn("🔍-", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 148))
    do
        local dragging, dragStart, startPos
        hideFloatBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = hideFloatBtn.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                hideFloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end
    do
        local dragging, dragStart, startPos
        freecamMenuTitle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = freecamMenuFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                freecamMenuFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end
    FreecamFloatingBtn.MouseButton1Click:Connect(function()
        freecamMenuFrame.Visible = not freecamMenuFrame.Visible
    end)
    local function setRobloxTouchGuiTransparency(transparency)
        local touchGui = LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
        if touchGui then
            for _, descendant in ipairs(touchGui:GetDescendants()) do
                if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
                    descendant.ImageTransparency = transparency
                elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                    descendant.TextTransparency = transparency
                end
            end
        end
    end
    local hideModeActive = false
    local isUiHidden = false
    hideAllBtn.MouseButton1Click:Connect(function()
        hideModeActive = not hideModeActive
        if hideModeActive then
            hideAllBtn.Text = "Ẩn Giao Diện: ON"
            hideAllBtn.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
            hideFloatBtn.Visible = true
            hideFloatBtn.BackgroundTransparency = 0.2
            hideFloatBtn.TextTransparency = 0
            local stroke = hideFloatBtn:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Transparency = 0 end
            freecamMenuFrame.Visible = false
        else
            hideAllBtn.Text = "Ẩn Giao Diện: OFF"
            hideAllBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
            hideFloatBtn.Visible = false
            isUiHidden = false
            FreecamFloatingBtn.Visible = true
            for i = 1, #controlButtons do
                local btn = controlButtons[i]
                btn.BackgroundTransparency = 0.35
                btn.TextTransparency = 0
                local stroke = btn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Transparency = 0 end
            end
            setRobloxTouchGuiTransparency(0)
        end
    end)
    hideFloatBtn.MouseButton1Click:Connect(function()
        isUiHidden = not isUiHidden
        if isUiHidden then
            FreecamFloatingBtn.Visible = false
            for i = 1, #controlButtons do
                local btn = controlButtons[i]
                btn.BackgroundTransparency = 1
                btn.TextTransparency = 1
                local stroke = btn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Transparency = 1 end
            end
            hideFloatBtn.BackgroundTransparency = 1
            hideFloatBtn.TextTransparency = 1
            local hideStroke = hideFloatBtn:FindFirstChildOfClass("UIStroke")
            if hideStroke then hideStroke.Transparency = 1 end
            setRobloxTouchGuiTransparency(1)
        else
            FreecamFloatingBtn.Visible = true
            for i = 1, #controlButtons do
                local btn = controlButtons[i]
                btn.BackgroundTransparency = 0.35
                btn.TextTransparency = 0
                local stroke = btn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Transparency = 0 end
            end
            hideFloatBtn.BackgroundTransparency = 0.2
            hideFloatBtn.TextTransparency = 0
            local hideStroke = hideFloatBtn:FindFirstChildOfClass("UIStroke")
            if hideStroke then hideStroke.Transparency = 0 end
            setRobloxTouchGuiTransparency(0)
        end
    end)
    local speed = 25.0
    speedIncBtn.MouseButton1Click:Connect(function()
        local step = speed < 2 and 0.1 or (speed < 10 and 1 or 5)
        speed = math.clamp(speed + step, 0.3, 150)
        speedLabel.Text = string.format("Tốc độ di chuyển: %.1f", speed)
    end)
    speedDecBtn.MouseButton1Click:Connect(function()
        local step = speed <= 2 and 0.1 or (speed <= 10 and 1 or 5)
        speed = math.clamp(speed - step, 0.3, 150)
        speedLabel.Text = string.format("Tốc độ di chuyển: %.1f", speed)
    end)
    local rotSensitivity = 1.0
    rotIncBtn.MouseButton1Click:Connect(function()
        rotSensitivity = math.clamp(rotSensitivity + 0.1, 0.05, 3.0)
        rotLabel.Text = string.format("Tốc độ xoay: %.2fx", rotSensitivity)
    end)
    rotDecBtn.MouseButton1Click:Connect(function()
        rotSensitivity = math.clamp(rotSensitivity - 0.1, 0.05, 3.0)
        rotLabel.Text = string.format("Tốc độ xoay: %.2fx", rotSensitivity)
    end)
    local freecamActive = false
    local camPos = camera.CFrame.Position
    local camAngles = Vector2.new(0, 0)
    local targetCamAngles = Vector2.new(0, 0)
    local currentFOV = camera.FieldOfView
    local moveStates = {W = false, S = false, A = false, D = false, Up = false, Down = false}
    local function bindTouch(btn, key)
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                moveStates[key] = true
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                moveStates[key] = false
            end
        end)
    end
    bindTouch(btnW, "W"); bindTouch(btnS, "S"); bindTouch(btnA, "A"); bindTouch(btnD, "D")
    bindTouch(btnUp, "Up"); bindTouch(btnDown, "Down")
    local zoomInActive, zoomOutActive = false, false
    btnZoomIn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then zoomInActive = true end end)
    btnZoomIn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then zoomInActive = false end end)
    btnZoomOut.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then zoomOutActive = true end end)
    btnZoomOut.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then zoomOutActive = false end end)
    local function toggleFreecam()
        freecamActive = not freecamActive
        if freecamActive then
            camPos = camera.CFrame.Position
            local rx, ry, rz = camera.CFrame:ToOrientation()
            camAngles = Vector2.new(ry, rx)
            targetCamAngles = camAngles
            currentFOV = camera.FieldOfView
            camera.CameraType = Enum.CameraType.Scriptable
            freecamToggleBtn.Text = "Freecam: ON"
            freecamToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 50)
            controlFrame.Visible = true
            freecamMenuFrame.Visible = false
        else
            camera.CameraType = Enum.CameraType.Custom
            camera.FieldOfView = 70
            freecamToggleBtn.Text = "Freecam: OFF"
            freecamToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
            controlFrame.Visible = false
        end
    end
    freecamToggleBtn.MouseButton1Click:Connect(toggleFreecam)
    local activeTouch = nil
    local lastTouchPos = nil
    local function isPointInsideFrame(point, frame)
        if not frame.Visible then return false end
        local absPos = frame.AbsolutePosition
        local absSize = frame.AbsoluteSize
        return point.X >= absPos.X and point.X <= absPos.X + absSize.X and point.Y >= absPos.Y and point.Y <= absPos.Y + absSize.Y
    end
    UserInputService.TouchStarted:Connect(function(touch)
        if not freecamActive then return end
        local pos = touch.Position
        local touchingUI = isPointInsideFrame(pos, controlFrame)
            or isPointInsideFrame(pos, freecamMenuFrame)
            or isPointInsideFrame(pos, FreecamFloatingBtn)
            or isPointInsideFrame(pos, HubFrame)
            or isPointInsideFrame(pos, ToggleBtn)
            or (hideFloatBtn.Visible and isPointInsideFrame(pos, hideFloatBtn))
        if not touchingUI and not activeTouch then
            activeTouch = touch
            lastTouchPos = touch.Position
        end
    end)
    UserInputService.TouchMoved:Connect(function(touch)
        if freecamActive and touch == activeTouch and lastTouchPos then
            local delta = touch.Position - lastTouchPos
            targetCamAngles = targetCamAngles - Vector2.new(delta.X * 0.004 * rotSensitivity, delta.Y * 0.004 * rotSensitivity)
            lastTouchPos = touch.Position
        end
    end)
    UserInputService.TouchEnded:Connect(function(touch)
        if touch == activeTouch then activeTouch = nil; lastTouchPos = nil end
    end)
    RunService.RenderStepped:Connect(function(dt)
        if not freecamActive then return end
        local smoothFactor = math.clamp(dt * 16, 0, 1)
        camAngles = camAngles:Lerp(targetCamAngles, smoothFactor)
        if zoomInActive then currentFOV = math.clamp(currentFOV - 35 * dt, 10, 120)
        elseif zoomOutActive then currentFOV = math.clamp(currentFOV + 35 * dt, 10, 120) end
        camera.FieldOfView = currentFOV
        local moveDir = Vector3.new()
        if moveStates.W then moveDir = moveDir + Vector3.new(0, 0, -1) end
        if moveStates.S then moveDir = moveDir + Vector3.new(0, 0, 1) end
        if moveStates.A then moveDir = moveDir + Vector3.new(-1, 0, 0) end
        if moveStates.D then moveDir = moveDir + Vector3.new(1, 0, 0) end
        if moveStates.Up then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if moveStates.Down then moveDir = moveDir + Vector3.new(0, -1, 0) end
        local rotCFrame = CFrame.Angles(0, camAngles.X, 0) * CFrame.Angles(camAngles.Y, 0, 0)
        camPos = camPos + (rotCFrame * moveDir) * speed * dt
        camera.CFrame = CFrame.new(camPos) * rotCFrame
    end)
end

-- ============================================================
-- KHOI 5: OFFICE FARM
-- ============================================================
do
    local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
    local TeamChangeRequest = JobEvents:WaitForChild("TeamChangeRequest", 5)
    local GenerateQuestion = JobEvents:WaitForChild("GenerateQuestion")
    local CorrectAnswer   = JobEvents:WaitForChild("CorrectAnswer")
    local AssignPrintJob  = JobEvents:WaitForChild("AssignPrintJob")
    local ClearPrintJob   = JobEvents:WaitForChild("ClearPrintJob")
    local Computers = workspace:FindFirstChild("Computers")

    local CHAIR_POS = Vector3.new(-5902.42, 2.71, -228.54)
    local PATTERN = { "CHOICE", "QID" }
    local UUID_PAT = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
    local of_phasing = false
    local of_activeBV = nil
    local of_savedCollide = {}
    local of_jobFired = false
    local of_resetUntil = 0
    local of_pendingQuestion = nil
    local of_lastKnownQuestion = nil
    local of_questionArrivedAt = 0
    local of_nextDelay = 2.4
    local of_printAssigned = nil
    local of_awaitingAck = false
    local of_lastFireAt = 0
    local of_refired = false

    local function of_killBV()
        if of_activeBV then
            pcall(function() of_activeBV.Velocity = Vector3.zero end)
            pcall(function() of_activeBV:Destroy() end)
            of_activeBV = nil
        end
        of_phasing = false
    end
    RunService.Stepped:Connect(function()
        local char = player.Character
        if not char then return end
        if of_phasing then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    of_savedCollide[p] = true
                    p.CanCollide = false
                end
            end
        elseif next(of_savedCollide) then
            for p in pairs(of_savedCollide) do
                if p.Parent then p.CanCollide = true end
            end
            table.clear(of_savedCollide)
        end
    end)
    local function of_enableSit(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
    end

    GenerateQuestion.OnClientEvent:Connect(function(...)
        local q = { text = nil, choices = nil, questionID = nil }
        for _, a in ipairs({ ... }) do
            if type(a) == "string" then
                if a:match(UUID_PAT) then
                    if not q.questionID then q.questionID = a end
                elseif not q.text and a:match("%d") and a:match("[=%?]") then
                    q.text = a
                end
            elseif type(a) == "table" and not q.choices then
                q.choices = a
            end
        end
        of_pendingQuestion = q
        of_lastKnownQuestion = q
        of_questionArrivedAt = os.clock()
        if farmOffice then setStatus("đang giải") end
    end)
    CorrectAnswer.OnClientEvent:Connect(function(status)
        of_awaitingAck = false
        of_refired = false
        local s = type(status) == "string" and status:lower() or ""
        if s == "success" then
            ofAnswers = ofAnswers + 1
            refreshStatPanel()
        end
    end)
    AssignPrintJob.OnClientEvent:Connect(function(name) of_printAssigned = name end)
    ClearPrintJob.OnClientEvent:Connect(function()
        of_printAssigned = nil
        ofPrints = ofPrints + 1
        refreshStatPanel()
    end)

    local function of_findButton(text)
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
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
        local cam = workspace.CurrentCamera
        if not cam then return false end
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
    local function of_seatsNear(pos, radius)
        local out = {}
        local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(pos, radius) end)
        if not ok or not parts then return out end
        for _, p in ipairs(parts) do
            if p:IsA("Seat") or p:IsA("VehicleSeat") then table.insert(out, p) end
        end
        return out
    end
    local function of_standUp()
        local h = of_humanoid()
        if not h then return end
        if not h.Sit and h:GetState() ~= Enum.HumanoidStateType.Seated then return end
        pcall(function() h.Sit = false end)
        task.wait(0.25)
        if h.Sit then pcall(function() h.Jump = true end); task.wait(0.3) end
        if h.Sit then pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end); task.wait(0.3) end
    end
    local OF_TELE_MIN = 60
    local function of_walkTo(target, stopDist, timeout, allowSit, useNoclip)
        stopDist = stopDist or 3
        timeout = timeout or 20
        local deadline = os.clock() + timeout
        local reached = false
        pcall(function()
            while os.clock() < deadline and farmOffice do
                local h = of_humanoid()
                local hrp = of_root()
                if not h or not hrp then break end
                if h.Sit or h:GetState() == Enum.HumanoidStateType.Seated then
                    if allowSit then reached = true; break
                    else of_standUp() end
                end
                local delta = target - hrp.Position
                local flat = Vector3.new(delta.X, 0, delta.Z)
                if flat.Magnitude <= stopDist then reached = true; break end
                h:MoveTo(Vector3.new(target.X, hrp.Position.Y, target.Z))
                task.wait(0.15)
            end
        end)
        local h = of_humanoid()
        local hrp = of_root()
        if h and hrp then h:MoveTo(hrp.Position) end
        return reached
    end
    local function of_teleNear(target, offsetDist)
        local hrp = of_root()
        if not hrp then return false end
        local dist = (target - hrp.Position).Magnitude
        if dist < OF_TELE_MIN then
            setStatus("đi bộ (" .. math.floor(dist) .. ")")
            return of_walkTo(target, offsetDist or 4, 8, false, false)
        end
        local dir = (target - hrp.Position)
        dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) end
        dir = dir.Unit
        local landPos = target - dir * (offsetDist or 4)
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
        elseif op == "/" then
            if b == 0 then return nil end
            r = a / b
        end
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
        if not choice then
            warn("[farm] khong parse duoc: " .. tostring(q and q.text))
            return false
        end
        local btn = of_findButton(choice.Text)
        local how = btn and of_clickButton(btn) or nil
        if how then
            pcall(function() CorrectAnswer:FireServer(unpack(of_buildArgs(q, choice))) end)
        end
        of_awaitingAck = true
        of_lastFireAt = os.clock()
        return true
    end
    local of_initialTeleDone = false
    local OF_SKIPPED_SEATS = {}
    local function of_findNearestUntriedSeat(pos, radius, tried)
        local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(pos, radius or 350) end)
        if not ok or not parts then return nil end
        local best, bestD = nil, math.huge
        for _, p in ipairs(parts) do
            if (p:IsA("Seat") or p:IsA("VehicleSeat"))
               and p.Occupant == nil
               and not tried[p]
               and not OF_SKIPPED_SEATS[p] then
                local d = (p.Position - pos).Magnitude
                if d < bestD then best, bestD = p, d end
            end
        end
        return best
    end
    local function of_sitAtChair(searchFrom)
        local h = of_humanoid()
        if h and h.Sit then return true end
        local hrp = of_root()
        if not hrp then return false end
        if not of_initialTeleDone then
            local dist = (hrp.Position - CHAIR_POS).Magnitude
            if dist > 500 then
                setStatus("tele lần đầu")
                hrp.CFrame = CFrame.new(CHAIR_POS)
                task.wait(1.0)
            end
            of_initialTeleDone = true
        end
        h = of_humanoid()
        if h and h.Sit then return true end
        local tried = {}
        while farmOffice do
            hrp = of_root()
            if not hrp then return false end
            local seat = of_findNearestUntriedSeat(hrp.Position, 350, tried)
            if not seat then
                setStatus("hết ghế — reset")
                tried = {}
                task.wait(2)
                seat = of_findNearestUntriedSeat(hrp.Position, 350, tried)
                if not seat then
                    setStatus("không có ghế trống")
                    task.wait(3)
                    return false
                end
            end
            tried[seat] = true
            setStatus("tìm ghế — tele")
            hrp.CFrame = CFrame.new(seat.Position + Vector3.new(0, 2, 0))
            task.wait(1.5)
            h = of_humanoid()
            if h and h.Sit then return true end
        end
        return false
    end
    local function of_doPrint(name)
        local Computers_ = workspace:FindFirstChild("Computers")
        if not Computers_ then return end
        local model = Computers_:FindFirstChild(name)
        if not model then return end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        of_standUp()
        setStatus("tới máy in")
        of_teleNear(part.Position, 4)
        setStatus("chuẩn bị in")
        task.wait(0.5)
        setStatus("đang in")
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        while of_printAssigned and farmOffice do
            local attempt = 0
            while of_printAssigned and farmOffice and attempt < 3 do
                attempt = attempt + 1
                if attempt == 1 then setStatus("đang in")
                else setStatus("thử in lại") end
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
        setStatus("đã in")
        task.wait(2)
        of_sitAtChair()
    end
    local function of_runCycle()
        while farmOffice and os.clock() < of_resetUntil do
            setStatus("chờ reset nhân vật")
            task.wait(0.2)
        end
        if not farmOffice then return end
        if not of_sitAtChair() then
            if farmOffice then task.wait(3) end
            return
        end
        setStatus("ngồi ghế, chờ câu hỏi")
        local idleStart = os.clock()
        local noQuestionStart = os.clock()
        while farmOffice do
            if of_printAssigned then break end
            if of_pendingQuestion then noQuestionStart = os.clock() end
            if of_pendingQuestion and not of_awaitingAck and (os.clock() - of_questionArrivedAt >= of_nextDelay) then
                local q = of_pendingQuestion
                of_pendingQuestion = nil
                of_fireAnswer(q)
                setStatus("đã giải")
                of_nextDelay = math.random(20, 28) / 10
                idleStart = os.clock()
            end
            if of_awaitingAck and os.clock() - of_lastFireAt > 8 and not of_refired then
                of_refired = true
                if of_lastKnownQuestion then
                    of_fireAnswer(of_lastKnownQuestion)
                    setStatus("đã giải")
                end
                idleStart = os.clock()
            end
            if os.clock() - noQuestionStart > 5
               and not of_pendingQuestion
               and not of_awaitingAck then
                setStatus("5s không câu hỏi — đổi ghế")
                local hh = of_humanoid()
                if hh and hh.Sit then
                    OF_SKIPPED_SEATS[hh.SeatPart] = true
                    pcall(function() hh.Sit = false end)
                    task.wait(0.5)
                end
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
                if not ok then
                    of_killBV()
                    warn("[farm] LOOP ERR: " .. tostring(err))
                    task.wait(1)
                end
            else
                task.wait(0.3)
            end
        end
    end)

    local function stopOffice(forceClose)
        if not farmOffice then
            if forceClose then
                if activeMode == "office" then
                    activeMode = nil
                end
                statPanel.Visible = false
                farmSwitch.set(false)
            end
            return
        end
        farmOffice = false
        _G._officeEnabled = false
        of_killBV()
        of_jobFired = false
        of_resetUntil = 0
        if writefile then pcall(writefile, "farmState.txt", "0") end
        local h = of_humanoid()
        if h and h.Sit then
            pcall(function() h.Sit = false end)
        end
        if activeMode == "office" then activeMode = nil end
        statPanel.Visible = false
        farmSwitch.set(false)
        setStatus("tạm nghỉ")
    end
    _G._officeStop = stopOffice

    farmSwitch.track.MouseButton1Click:Connect(function()
        if not farmOK then return end
        if farmOffice then
            stopOffice()
            return
        end
        if _G._ridegoStop then pcall(_G._ridegoStop, true) end
        of_initialTeleDone = false
        of_printAssigned = nil
        of_pendingQuestion = nil
        of_awaitingAck = false
        of_lastKnownQuestion = nil
        of_questionArrivedAt = 0
        of_nextDelay = 2.4
        of_refired = false
        of_lastFireAt = 0
        of_phasing = false
        ofAnswers = 0
        OF_SKIPPED_SEATS = {}
        ofPrints = 0
        refreshStatPanel()
        farmOffice = true
        _G._officeEnabled = true
        activeMode = "office"
        farmStart = os.clock()
        TeamChangeRequest:FireServer("Office Worker", 11378976, 0, 0, "Detector")
        of_jobFired = true
        of_resetUntil = os.clock() + 5
        if writefile then
            pcall(writefile, "farmState.txt", "1")
            pcall(writefile, "ridegoState.txt", "0")
        end
        if queue_on_teleport then
            pcall(queue_on_teleport, [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()
]])
        end
        local char = player.Character
        of_enableSit(char)
        farmSwitch.set(true)
        statPanel.Visible = true
        refreshStatPanel()
        setStatus("khởi động office")
    end)
end

-- ============================================================
-- KHOI 6: RIDEGO FARM
-- ============================================================
do
    local rs_ = ReplicatedStorage
    local lp = LocalPlayer

    local STEP_DIST           = 250
    local LAND_OFFSET         = 8
    local ARRIVE_DIST         = 8
    local ORDER_TIMEOUT       = 60
    local PICKUP_WAIT         = 4
    local DROP_WAIT           = 5
    local ACK_DELAY           = 3
    local DECEL_DIST          = 200
    local TICK                = 0.05
    local UNDERGROUND_DEPTH   = 200
    local UNDER_STEP_MAX      = 50
    local UNDER_DESCEND_STEPS = 12
    local UNDER_STEP_TIME     = 0.03
    local TRIP_MILESTONE      = 10
    local FLY_TIMEOUT         = 30
    local SEAT_DELAY          = 0.5

    local orderToken  = nil
    local pickupPos   = nil
    local dropPos     = nil
    local pendingFare = 0
    local myCar       = nil
    local selectedCar = ""
    local carList     = {}
    local stats       = { trips = 0, earn = 0 }
    local curStatus   = "◦ TẮT"
    local holdActive  = false
    local holdBP      = nil
    local holdGyro    = nil
    local flying      = false
    local acceptingOrder = false
    local farmStartTime  = 0
    local lastMilestone = 0

    local function isEnabled() return _G._ridegoEnabled end

    local function resetState()
        orderToken = nil
        pickupPos = nil
        dropPos = nil
        pendingFare = 0
        myCar = nil
        curStatus = "◦ TẮT"
        flying = false
        acceptingOrder = false
        farmStartTime = 0
        lastMilestone = 0
        holdActive = false
        if holdBP then pcall(function() holdBP:Destroy() end) holdBP = nil end
        if holdGyro then pcall(function() holdGyro:Destroy() end) holdGyro = nil end
    end

    local function setRgStatus(s)
        curStatus = s
        if ridegoStatusLbl then ridegoStatusLbl.Text = "📍 " .. s end
    end

    local JobEvents = rs_:WaitForChild("JobEvents", 10)
    local TeamChangeRequest = JobEvents and JobEvents:WaitForChild("TeamChangeRequest", 5)
    local TaxiAssets = rs_:WaitForChild("TaxiAssets", 10)
    local TaxiEvent
    if TaxiAssets then
        local ev = TaxiAssets:WaitForChild("Events", 5)
        if ev then TaxiEvent = ev:FindFirstChild("TaxiEvent", true) end
    end
    local SpawnCarEvents = rs_:WaitForChild("SpawnCarEvents", 10)
    local SpawnCarEv
    if SpawnCarEvents then SpawnCarEv = SpawnCarEvents:WaitForChild("SpawnCar", 5) end
    local DealershipEvents = rs_:FindFirstChild("DealershipEvents")
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
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        local s = math.floor(sec % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end
    local function formatMoney(n)
        local s = tostring(math.floor(n or 0))
        local out = ""
        local len = #s
        for i = 1, len do
            out = out .. s:sub(i, i)
            local remain = len - i
            if remain > 0 and remain % 3 == 0 then out = out .. " " end
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
                pickupPos = data.PickupPos
                dropPos   = data.DropPos
                orderToken = data.Token
                if type(data.Fare) == "number" then pendingFare = data.Fare
                else pendingFare = 0 end
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
        for _, n in ipairs(carList) do
            if not seen[n] then seen[n] = true; table.insert(uniq, n) end
        end
        table.sort(uniq)
        carList = uniq
        ridegoCarList = uniq
        return carList
    end

    local function closeCarOverlay()
        ridegoCarOpen = false
        if ridegoCarListPanel then ridegoCarListPanel.Visible = false end
    end

    local function renderRidegoCars()
        if not ridegoCarListWrap then return end
        for _, c in ipairs(ridegoCarListWrap:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        ridegoCarListWrap.CanvasSize = UDim2.new(0, 0, 0, #carList * 28 + 8)
        if #carList == 0 then
            local lbl = Instance.new("TextLabel", ridegoCarListWrap)
            lbl.Size = UDim2.new(1, -8, 0, 40)
            lbl.BackgroundTransparency = 1
            lbl.Text = "Chưa quét xe"
            lbl.TextColor3 = Color3.fromRGB(150, 160, 180)
            lbl.TextSize = 10
            lbl.Font = Enum.Font.GothamMedium
            ridegoCarBtn.Text = "🚗 CHỌN XE (0)"
            return
        end
        for i, name in ipairs(carList) do
            local btn = Instance.new("TextButton", ridegoCarListWrap)
            btn.Size = UDim2.new(1, -8, 0, 24)
            btn.BackgroundColor3 = (name == selectedCar) and Color3.fromRGB(0, 150, 120) or Color3.fromRGB(30, 38, 54)
            btn.Text = "  " .. name
            btn.TextColor3 = Color3.fromRGB(220, 230, 240)
            btn.TextSize = 10
            btn.Font = Enum.Font.Code
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.LayoutOrder = i
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                selectedCar = name
                ridegoSelectedCar = name
                if ridegoPickLbl then ridegoPickLbl.Text = "🚗 Xe: " .. name end
                if ridegoStatusCarLbl then ridegoStatusCarLbl.Text = "🚗 Xe: " .. name end
                renderRidegoCars()
                closeCarOverlay()
            end)
        end
        ridegoCarBtn.Text = "🚗 CHỌN XE (" .. #carList .. ")"
    end

    ridegoCarBtn.MouseButton1Click:Connect(function()
        if _G._ridegoEnabled then return end
        ridegoCarOpen = not ridegoCarOpen
        if ridegoCarOpen then
            local ap = ridegoCarBtn.AbsolutePosition
            local as = ridegoCarBtn.AbsoluteSize
            ridegoCarListPanel.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
            ridegoCarListPanel.Visible = true
        else
            ridegoCarListPanel.Visible = false
        end
    end)

    local function findMyCar()
        local c = char()
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.SeatPart then
                return h.SeatPart:FindFirstAncestorOfClass("Model")
            end
        end
        local pname = lp.Name:lower()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") and d.Name:lower():find(pname, 1, true)
               and d:FindFirstChildWhichIsA("VehicleSeat", true) then
                return d
            end
        end
        return nil
    end
    local function makeRayParams()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ign = {}
        local c = char()
        if c then table.insert(ign, c) end
        local car = myCar or findMyCar()
        if car then table.insert(ign, car) end
        params.FilterDescendantsInstances = ign
        params.IgnoreWater = true
        return params
    end
    local function floorBelow(pos)
        if not pos then return nil end
        local params = makeRayParams()
        local origin = Vector3.new(pos.X, pos.Y + 4, pos.Z)
        local hit = workspace:Raycast(origin, Vector3.new(0, -800, 0), params)
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
                local targetCF = f.seat.CFrame * f.offset
                f.hrp.CFrame = targetCF
                if not f.hrp:FindFirstChild("RG_NpcWeld") then
                    local w = Instance.new("WeldConstraint")
                    w.Name = "RG_NpcWeld"
                    w.Part0 = f.seat
                    w.Part1 = f.hrp
                    w.Parent = f.hrp
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
                        local existing = hrp:FindFirstChild("RG_NpcWeld")
                        if existing then pcall(function() existing:Destroy() end) end
                        local w = Instance.new("WeldConstraint")
                        w.Name = "RG_NpcWeld"
                        w.Part0 = d
                        w.Part1 = hrp
                        w.Parent = hrp
                        pcall(function()
                            oh.PlatformStand = true
                            oh.WalkSpeed = 0
                            oh.JumpPower = 0
                            oh.JumpHeight = 0
                            oh.AutoRotate = false
                        end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Running, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
                        pcall(function() oh:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) end)
                        pcall(function() oh:ChangeState(Enum.HumanoidStateType.Physics) end)
                        table.insert(npcFollowers, {
                            char = npcChar, hum = oh, seat = d,
                            offset = offset, hrp = hrp,
                        })
                    end
                end
            end
        end
        if npcRenderConn then
            pcall(function() npcRenderConn:Disconnect() end)
            npcRenderConn = nil
        end
        npcRenderConn = RunService.RenderStepped:Connect(function()
            pcall(safeRefreshNpc)
        end)
    end
    local function updateNpcFollowers() pcall(safeRefreshNpc) end
    local function detachNpcFollowers()
        if npcRenderConn then
            pcall(function() npcRenderConn:Disconnect() end)
            npcRenderConn = nil
        end
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
        if inst:IsA("BasePart") and not inst.Anchored then
            pcall(function() inst:SetNetworkOwner(lp) end)
        end
        for _, p in ipairs(inst:GetDescendants()) do
            if p:IsA("BasePart") and not p.Anchored then
                pcall(function() p:SetNetworkOwner(lp) end)
            end
        end
    end
    local function unanchorCar(car)
        if not car then return end
        for _, p in ipairs(car:GetDescendants()) do
            if p:IsA("BasePart") and p.Anchored then
                pcall(function() p.Anchored = false end)
            end
        end
    end
    local function fullCollideOn(inst)
        if not inst then return end
        if inst:IsA("BasePart") and not inst.CanCollide then
            pcall(function() inst.CanCollide = true end)
        end
        for _, p in ipairs(inst:GetDescendants()) do
            if p:IsA("BasePart") and not p.CanCollide then
                pcall(function() p.CanCollide = true end)
            end
        end
    end

    local function startHold()
        if holdBP then pcall(function() holdBP:Destroy() end) holdBP = nil end
        if holdGyro then pcall(function() holdGyro:Destroy() end) holdGyro = nil end
        local car = myCar or findMyCar()
        if not car then return end
        local vs = car:FindFirstChildWhichIsA("VehicleSeat", true)
        if not vs then return end
        local curCF = vs.CFrame
        local bp = Instance.new("BodyPosition")
        bp.Name = "RGHoldPos"
        bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bp.P = 4000; bp.D = 300
        bp.Position = curCF.Position
        bp.Parent = vs
        holdBP = bp
        local flatRot = flatYawCFrame(curCF)
        local bg = Instance.new("BodyGyro")
        bg.Name = "RGHoldGyro"
        bg.MaxTorque = Vector3.new(3e5, 3e5, 3e5)
        bg.P = 8000; bg.D = 1000
        bg.CFrame = flatRot
        bg.Parent = vs
        holdGyro = bg
        holdActive = true
        task.spawn(function()
            while holdActive and holdBP == bp and bp.Parent do
                bp.Position = curCF.Position
                if holdGyro == bg and bg.Parent then bg.CFrame = flatRot end
                task.wait(0.1)
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
        local h = hum()
        local car = myCar or findMyCar()
        if not h or not car then return false end
        local vs = getDriveSeat(car)
        if not vs then return false end
        if h.Sit and h.SeatPart == vs then
            pcall(function() h.AutoRotate = false end)
            return true
        end
        if h.Sit and h.SeatPart ~= vs then
            pcall(function() h.Sit = false end)
            task.wait(0.2)
        end
        if vs.Occupant and vs.Occupant ~= h then
            local occ = vs.Occupant
            if occ and occ:IsA("Humanoid") then
                pcall(function() occ.Sit = false end)
                task.wait(0.2)
            end
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
        if hrp then
            pcall(function() hrp.CFrame = vs.CFrame end)
            task.wait(SEAT_DELAY)
        end
        pcall(function() vs:Sit(h) end)
        task.wait(0.12)
        pcall(function() h.AutoRotate = false end)
        pcall(function() h.Sit = true end)
        for i = 1, 3 do
            if h.Sit and h.SeatPart == vs then break end
            local hrpR = root()
            if hrpR then
                pcall(function() hrpR.CFrame = vs.CFrame end)
                task.wait(0.1)
            end
            pcall(function() vs:Sit(h) end)
            task.wait(0.1)
            if not h.Sit then
                pcall(function() h.Sit = true end)
                task.wait(0.06)
            end
        end
        for _, d in ipairs(disabledList) do
            pcall(function() d.Disabled = false end)
        end
        pcall(function() h.AutoRotate = false end)
        return h.Sit and h.SeatPart == vs
    end

    task.spawn(function()
        while true do
            task.wait(0.15)
            if isEnabled() then
                local h = hum()
                local car = myCar or findMyCar()
                if h and car then
                    local vs = getDriveSeat(car)
                    if vs then
                        local wrongSeat = h.Sit and h.SeatPart and h.SeatPart ~= vs
                        local notSeated = not h.Sit
                        if wrongSeat then
                            setRgStatus("⚠ Ngồi sai ghế — nhảy ra ngồi lại")
                            pcall(function() h.Sit = false end)
                            task.wait(0.25)
                            for _ = 1, 6 do
                                if forceSeat() then break end
                                task.wait(0.25)
                            end
                        elseif notSeated and not flying then
                            forceSeat()
                        end
                        pcall(function() h.AutoRotate = false end)
                    end
                end
            end
        end
    end)

    local function seatCar(timeout)
        timeout = timeout or 15
        local deadline = os.clock() + timeout
        while os.clock() < deadline and isEnabled() do
            local h = hum()
            local car = findMyCar()
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

    local function ascendToGround(car, target, targetFloor)
        if not car then return end
        local realFloor = floorBelow(target) or targetFloor
        local upTargetY = realFloor + LAND_OFFSET
        local cp = car:GetPivot()
        local flatRot = flatYawCFrame(cp)
        local dest = Vector3.new(target.X, upTargetY, target.Z)
        pcall(function() car:PivotTo(CFrame.new(dest) * flatRot) end)
        task.wait(0.15)
    end

    local function flyTo(target, flyingLabel)
        flyingLabel = flyingLabel or "bay"
        stopHold()
        local h = hum()
        local car = myCar or findMyCar()
        if not h or not car then return false end
        if not h.Sit then forceSeat(); task.wait(0.1) end
        if not isEnabled() then return false end
        pcall(function() h.AutoRotate = false end)
        local myChar = char()
        local targetFloor = floorBelow(target) or target.Y
        local underY = targetFloor - UNDERGROUND_DEPTH
        setRgStatus("◦ Chuẩn bị")
        unanchorCar(car)
        task.wait(0.05)
        if not isEnabled() then return false end
        claimNetworkOwner(car)
        attachNpcFollowers(car)
        for _, p in ipairs(car:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
        if myChar then
            for _, p in ipairs(myChar:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.CanCollide = false end)
                end
            end
        end
        flying = true
        local flyStart = os.clock()
        local startPivot = car:GetPivot()
        local rotOnly = flatYawCFrame(startPivot)
        local curPos = startPivot.Position
        local downStepY = (underY - curPos.Y) / UNDER_DESCEND_STEPS
        for i = 1, UNDER_DESCEND_STEPS do
            if not isEnabled() then break end
            curPos = Vector3.new(curPos.X, curPos.Y + downStepY, curPos.Z)
            local cf = CFrame.new(curPos) * rotOnly
            pcall(function() car:PivotTo(cf) end)
            task.wait(UNDER_STEP_TIME)
        end
        setRgStatus("◦ " .. flyingLabel)
        local reached = false
        local timedOut = false
        local lastNpcRefresh = 0
        local fakeVelCounter = 0
        while isEnabled() do
            local c = myCar or findMyCar()
            if not c then break end
            if os.clock() - flyStart > FLY_TIMEOUT then
                timedOut = true
                break
            end
            local curP = c:GetPivot().Position
            local flat = Vector3.new(target.X - curP.X, 0, target.Z - curP.Z)
            local dist = flat.Magnitude
            if dist < ARRIVE_DIST then reached = true; break end
            local dir = (dist > 0.01) and flat.Unit or Vector3.new(1, 0, 0)
            local spd
            if dist >= DECEL_DIST then spd = STEP_DIST
            else spd = math.max(STEP_DIST * dist / DECEL_DIST, 6) end
            local step = math.min(spd * TICK, dist, UNDER_STEP_MAX)
            local nextPos = Vector3.new(curP.X + dir.X * step, underY, curP.Z + dir.Z * step)
            pcall(function() c:PivotTo(CFrame.new(nextPos) * rotOnly) end)
            fakeVelCounter = fakeVelCounter + 1
            if fakeVelCounter >= 2 then
                fakeVelCounter = 0
                local fakeV = Vector3.new(dir.X * spd, 0, dir.Z * spd)
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function() p.AssemblyLinearVelocity = fakeV end)
                    end
                end
            end
            if os.clock() - lastNpcRefresh > 0.05 then
                lastNpcRefresh = os.clock()
                updateNpcFollowers()
            end
            task.wait(TICK)
        end
        if timedOut then
            flying = false
            detachNpcFollowers()
            setRgStatus("⚠ Bay quá 30s — hủy")
            return false
        end
        if not isEnabled() then
            flying = false
            detachNpcFollowers()
            return false
        end
        car = myCar or findMyCar()
        if car and reached then
            ascendToGround(car, target, targetFloor)
            myCar = car
            startHold()
            pcall(function() hum().AutoRotate = false end)
        end
        detachNpcFollowers()
        flying = false
        if not h.Sit then forceSeat() end
        task.wait(0.1)
        local h2 = hum()
        if not h2 or not h2.Sit then forceSeat(); task.wait(0.2) end
        task.wait(0.15)
        return reached
    end

    local function spawnAndSeat()
        if not SpawnCarEv then return false end
        if not selectedCar or selectedCar == "" then
            setRgStatus("⚠ Chưa chọn xe")
            return false
        end
        local car = findMyCar()
        if car and car:FindFirstChildWhichIsA("BasePart", true) then
            setRgStatus("◦ Xe đã có sẵn")
            if seatCar(10) then
                setRgStatus("◦ Sẵn sàng")
                return true
            end
        end
        setRgStatus("◦ Đang spawn xe")
        fire(SpawnCarEv, selectedCar)
        local deadline = os.clock() + 20
        while os.clock() < deadline and isEnabled() do
            car = findMyCar()
            if car and car:FindFirstChildWhichIsA("BasePart", true) then
                local r = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
                if r and r.AssemblyLinearVelocity.Magnitude < 5 then break end
            end
            task.wait(0.5)
        end
        if not car then
            setRgStatus("⚠ Xe chưa hiện")
            return false
        end
        task.wait(1.5)
        if not isEnabled() then return false end
        local pivot = car:GetPivot()
        local flatRot = flatYawCFrame(pivot)
        pcall(function() car:PivotTo(CFrame.new(pivot.Position) * flatRot) end)
        task.wait(0.1)
        if seatCar(15) then
            setRgStatus("◦ Sẵn sàng")
            task.wait(1)
            return true
        end
        setRgStatus("⚠ Ngồi ghế thất bại")
        return false
    end

    local function resetCharacter()
        setRgStatus("◦ Reset nhân vật")
        local h = hum()
        if h then pcall(function() h.Health = 0 end) end
        local deadline = os.clock() + 8
        while os.clock() < deadline do
            local newH = hum()
            if newH and newH.Health > 0 then break end
            task.wait(0.3)
        end
        task.wait(0.5)
    end

    local function doFullInit()
        setRgStatus("◦ Lần đầu — đổi nghề")
        fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
        task.wait(3)
        if not isEnabled() then return false end
        setRgStatus("◦ Spawn xe")
        if not spawnAndSeat() then return false end
        myCar = findMyCar()
        setRgStatus("◦ Bật online")
        fire(TaxiEvent, "GoOnline")
        task.wait(2)
        setRgStatus("◦ Sẵn sàng nhận đơn")
        return true
    end
    local function doRestartInit()
        resetCharacter()
        task.wait(0.5)
        if not isEnabled() then return false end
        setRgStatus("◦ Spawn xe")
        if not spawnAndSeat() then return false end
        myCar = findMyCar()
        setRgStatus("◦ Tắt online")
        fire(TaxiEvent, "GoOffline")
        task.wait(1)
        setRgStatus("◦ Bật lại online")
        fire(TaxiEvent, "GoOnline")
        task.wait(2)
        setRgStatus("◦ Sẵn sàng nhận đơn")
        return true
    end
    local function recoverFromTimeout()
        acceptingOrder = false
        flying = false
        detachNpcFollowers()
        stopHold()
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
        local c = char()
        if c then fullCollideOn(c) end
        resetState()
        resetCharacter()
        if not isEnabled() then return end
        farmStartTime = os.time()
        fire(TaxiEvent, "GoOffline")
        task.wait(1)
        fire(TaxiEvent, "GoOnline")
        task.wait(1)
        setRgStatus("◦ Đã khôi phục — chờ đơn")
    end

    local function runTrip()
        local h = hum()
        if not h or not h.Sit then
            setRgStatus("⚠ Hồi sinh xe")
            if not spawnAndSeat() then task.wait(5); return end
            if not isEnabled() then return end
        end
        myCar = findMyCar()
        pcall(function() h.AutoRotate = false end)
        startHold()
        if not pickupPos then
            orderToken = nil
            dropPos = nil
            pendingFare = 0
            acceptingOrder = true
            setRgStatus("◦ Chờ đơn")
            local deadline = os.clock() + ORDER_TIMEOUT
            while os.clock() < deadline and isEnabled() do
                if pickupPos then break end
                if not holdActive then startHold() end
                task.wait(0.4)
            end
            acceptingOrder = false
            if not isEnabled() then return end
            if not pickupPos then
                setRgStatus("⚠ Không có đơn")
                return
            end
        else
            acceptingOrder = false
            setRgStatus("◦ Đã có đơn — bay luôn")
        end
        local ok1 = flyTo(pickupPos, "đón khách")
        if not isEnabled() then return end
        if not ok1 then
            recoverFromTimeout()
            return
        end
        setRgStatus("◦ Đã tới")
        forceSeat()
        setRgStatus("⌛ Đợi khách lên xe (4s)")
        task.wait(PICKUP_WAIT)
        if not isEnabled() then return end
        if dropPos then
            local ok2 = flyTo(dropPos, "đưa khách tới nơi")
            if not isEnabled() then return end
            if not ok2 then
                recoverFromTimeout()
                return
            end
            setRgStatus("◦ Đã tới")
            forceSeat()
            setRgStatus("⌛ Đợi khách xuống xe (5s)")
            task.wait(DROP_WAIT)
            if not isEnabled() then return end
            stats.trips = stats.trips + 1
            if pendingFare > 0 then stats.earn = stats.earn + pendingFare end
            setRgStatus("✓ Hoàn thành + Rp " .. formatMoney(pendingFare))
            task.wait(ACK_DELAY)
            if not isEnabled() then return end
            fire(TaxiEvent, "AckTripComplete")
            setRgStatus("✓ Đã báo hoàn thành — chờ đơn mới")
            pendingFare = 0
            if stats.trips > 0 and stats.trips % TRIP_MILESTONE == 0 and stats.trips ~= lastMilestone then
                lastMilestone = stats.trips
                pickupPos = nil
                dropPos = nil
                orderToken = nil
                setRgStatus("◦ Đủ " .. TRIP_MILESTONE .. " chuyến — tắt/mở lại online")
                fire(TaxiEvent, "GoOffline")
                task.wait(2)
                if not isEnabled() then return end
                fire(TaxiEvent, "GoOnline")
                acceptingOrder = true
                task.wait(1.5)
                setRgStatus("◦ Đã mở lại online")
                return
            end
        end
        pickupPos = nil
        dropPos = nil
        orderToken = nil
        task.wait(0.3)
    end

    local loopBusy = false
    local function startLoop()
        if loopBusy then return end
        loopBusy = true
        task.spawn(function()
            farmStartTime = os.time()
            local ok
            if not _G._ridegoHasInitOnce then ok = pcall(doFullInit)
            else ok = pcall(doRestartInit) end
            if ok then _G._ridegoHasInitOnce = true end
            if not ok or not isEnabled() then
                loopBusy = false
                if not isEnabled() then
                    setRgStatus("◦ TẮT")
                else
                    setRgStatus("⚠ Khởi tạo thất bại")
                end
                return
            end
            while isEnabled() do
                local ok2, err = pcall(runTrip)
                if not ok2 then setRgStatus("⚠ Lỗi: " .. tostring(err):sub(1, 40)) end
                task.wait(1)
            end
            loopBusy = false
            setRgStatus("◦ TẮT")
        end)
    end

    -- ============ RIDEGO STATUS PANEL ============
    ridegoStatusFrame = Instance.new("Frame")
    ridegoStatusFrame.Size = UDim2.new(0, 250, 0, 148)
    ridegoStatusFrame.Position = UDim2.new(0, 76, 0.5, 190)
    ridegoStatusFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
    ridegoStatusFrame.BackgroundTransparency = 0.15
    ridegoStatusFrame.BorderSizePixel = 0
    ridegoStatusFrame.Active = true
    ridegoStatusFrame.Draggable = true
    ridegoStatusFrame.Visible = false
    ridegoStatusFrame.ZIndex = 9
    ridegoStatusFrame.Parent = ScreenGui
    Instance.new("UICorner", ridegoStatusFrame).CornerRadius = UDim.new(0, 10)
    local rgStroke = Instance.new("UIStroke", ridegoStatusFrame)
    rgStroke.Name = "RainbowBorder"
    rgStroke.Thickness = 2
    rgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    task.spawn(function()
        local t = 0
        while true do
            task.wait(0.03)
            t = t + 0.15
            if rgStroke and rgStroke.Parent then
                rgStroke.Color = rainbowAt(t)
            end
        end
    end)

    local rgTitle = Instance.new("TextLabel", ridegoStatusFrame)
    rgTitle.Size = UDim2.new(1, -20, 0, 24)
    rgTitle.Position = UDim2.new(0, 10, 0, 4)
    rgTitle.BackgroundTransparency = 1
    rgTitle.Text = "🚕 RideGo Status"
    rgTitle.TextColor3 = Color3.fromRGB(255, 140, 40)
    rgTitle.TextSize = 13
    rgTitle.Font = Enum.Font.GothamBold
    rgTitle.TextXAlignment = Enum.TextXAlignment.Left
    rgTitle.ZIndex = 10

    local function rgLabel(y)
        local l = Instance.new("TextLabel", ridegoStatusFrame)
        l.Size = UDim2.new(1, -20, 0, 18)
        l.Position = UDim2.new(0, 10, 0, y)
        l.BackgroundTransparency = 1
        l.Text = ""
        l.TextColor3 = Color3.fromRGB(200, 220, 240)
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.ZIndex = 10
        return l
    end

    ridegoTimeLbl       = rgLabel(32)
    ridegoTripsLbl      = rgLabel(50)
    ridegoEarnLbl       = rgLabel(68)
    ridegoStatusCarLbl  = rgLabel(86)
    ridegoStatusLbl     = rgLabel(110)
    ridegoStatusCarLbl.Text = "🚗 Xe: (chưa chọn)"

    task.spawn(function()
        while true do
            task.wait(0.3)
            if isEnabled() then
                local sec = os.time() - farmStartTime
                ridegoTimeLbl.Text  = "⏱ Thời gian: " .. formatTime(sec)
                ridegoTripsLbl.Text = "🚕 Chuyến: " .. tostring(stats.trips)
                ridegoEarnLbl.Text  = "💰 Kiếm: Rp " .. formatMoney(stats.earn)
                if selectedCar ~= "" then
                    ridegoStatusCarLbl.Text = "🚗 Xe: " .. selectedCar
                end
                ridegoStatusLbl.Text = "📍 " .. curStatus
            end
        end
    end)

    task.spawn(function()
        task.wait(2)
        pcall(scanCars)
        if #carList > 0 and (not selectedCar or selectedCar == "") then
            selectedCar = carList[1]
            ridegoSelectedCar = selectedCar
        end
        renderRidegoCars()
        if ridegoPickLbl then
            ridegoPickLbl.Text = "🚗 Xe: " .. ((selectedCar ~= "" and selectedCar) or "(chưa chọn)")
        end
        if ridegoStatusCarLbl then
            ridegoStatusCarLbl.Text = "🚗 Xe: " .. ((selectedCar ~= "" and selectedCar) or "(chưa chọn)")
        end
    end)

    -- ============ STOP + SWITCH ============
    local function stopRidego(forceClose)
        -- Luon force reset UI + state, ke ca khi _G._ridegoEnabled = false
        _G._ridegoEnabled = false
        acceptingOrder = false
        flying = false
        detachNpcFollowers()
        stopHold()
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
        local c = char()
        if c then fullCollideOn(c) end
        resetState()
        if writefile then pcall(writefile, "ridegoState.txt", "0") end
        if ridegoStatusFrame then ridegoStatusFrame.Visible = false end
        if ridegoSwitch then ridegoSwitch.set(false) end
        closeCarOverlay()
        setRgStatus("◦ TẮT")
        -- reset character trong task rieng
        task.spawn(function() resetCharacter() end)
    end
    _G._ridegoStop = stopRidego

    ridegoSwitch.track.MouseButton1Click:Connect(function()
        if _G._ridegoEnabled then
            stopRidego()
            return
        end
        -- Mutex: tat office truoc
        if _G._officeStop then pcall(_G._officeStop, true) end
        resetState()
        _G._ridegoEnabled = true
        farmStartTime = os.time()
        stats.trips = 0
        stats.earn = 0
        -- hien status NGAY lap tuc
        ridegoStatusFrame.Visible = true
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
            pcall(queue_on_teleport, [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()
]])
        end
        ridegoSwitch.set(true)
        startLoop()
    end)
end

-- ============================================================
-- WIRING CUOI + AUTO REJOIN
-- ============================================================
ToggleBtn.MouseButton1Click:Connect(function()
    HubFrame.Visible = not HubFrame.Visible
end)
hubClose.MouseButton1Click:Connect(function()
    HubFrame.Visible = false
end)

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

-- Auto Execute + Auto Rejoin
local _autoExecute = false
local _autoRejoin = false
if readfile and isfile then
    if isfile("autoExecute.txt") then
        local ok, v = pcall(readfile, "autoExecute.txt")
        if ok and v == "1" then _autoExecute = true end
    end
    if isfile("autoRejoin.txt") then
        local ok, v = pcall(readfile, "autoRejoin.txt")
        if ok and v == "1" then _autoRejoin = true end
    end
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
            if os.time() - lastAttempt < 120 then
                -- cooldown
            else
                local shouldRejoin = false
                local c = game.Players.LocalPlayer.Character
                if not c then shouldRejoin = true end
                if not shouldRejoin then
                    pcall(function()
                        local cg = game:GetService("CoreGui")
                        for _, d in ipairs(cg:GetDescendants()) do
                            if d:IsA("TextLabel") then
                                local t = d.Text
                                if t == "Mất kết nối" or t:find("Disconnected") or t == "Kết nối bị mất" then
                                    shouldRejoin = true
                                    return
                                end
                            end
                        end
                    end)
                end
                if shouldRejoin then
                    lastAttempt = os.time()
                    if writefile then pcall(writefile, "lastRejoin.txt", tostring(lastAttempt)) end
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
            if t > 0 and os.time() - t < 60 then wasRejoin = true end
        end
    end
    if not wasRejoin then return end
    task.wait(15)

    local pg = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end

    local function clickAt(label)
        if not label then return false end
        local x = label.AbsolutePosition.X + label.AbsoluteSize.X / 2
        local y = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2
        if pcall(function() touchpress(x, y); task.wait(0.1); touchrelease(x, y) end) then return true end
        local p = label.Parent
        if p and p:IsA("TextButton") then
            if pcall(function() firesignal(p.MouseButton1Click) end) then return true end
        end
        return false
    end
    local function findHomePlay()
        local menu = pg:FindFirstChild("mainMenuSystem")
        if not menu then return nil end
        local base = menu:FindFirstChild("baseFrame"); if not base then return nil end
        local home = base:FindFirstChild("homeFrame"); if not home then return nil end
        for _, d in ipairs(home:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == "PLAY" and d.Visible and d.AbsoluteSize.X > 0 then return d end
        end
        return nil
    end
    local function findTeamPlay()
        local menu = pg:FindFirstChild("mainMenuSystem")
        if not menu then return nil end
        local base = menu:FindFirstChild("baseFrame"); if not base then return nil end
        local play = base:FindFirstChild("playFrame"); if not play then return nil end
        for _, d in ipairs(play:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == "PLAY" and d.Visible and d.AbsoluteSize.X > 0 then
                local home = base:FindFirstChild("homeFrame")
                if not (home and d:IsDescendantOf(home)) then return d end
            end
        end
        return nil
    end

    local lbl1 = nil
    for i = 1, 8 do
        lbl1 = findHomePlay()
        if lbl1 then break end
        task.wait(1)
    end
    if lbl1 then clickAt(lbl1) end

    task.wait(3)

    local lbl2 = nil
    for i = 1, 8 do
        lbl2 = findTeamPlay()
        if lbl2 then break end
        task.wait(1)
    end
    if lbl2 then clickAt(lbl2) end

    if writefile then pcall(writefile, "lastRejoin.txt", "0") end
    task.wait(10)

    local officeFlag = false
    local ridegoFlag = false
    if readfile and isfile and isfile("farmState.txt") then
        local ok, v = pcall(readfile, "farmState.txt")
        if ok and v == "1" then officeFlag = true end
    end
    if readfile and isfile and isfile("ridegoState.txt") then
        local ok, v = pcall(readfile, "ridegoState.txt")
        if ok and v == "1" then ridegoFlag = true end
    end
    if officeFlag then
        pcall(function() firesignal(farmSwitch.track.MouseButton1Click) end)
    elseif ridegoFlag then
        pcall(function() firesignal(ridegoSwitch.track.MouseButton1Click) end)
    end
end)
