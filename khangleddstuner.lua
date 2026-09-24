-- ============================================================
-- KHANGLE DDS HUB
-- ============================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local farmSwitch
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local camera = workspace.CurrentCamera
local function checkFarmOK()
    return workspace:FindFirstChild("Computers") ~= nil
end
local count = 0
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

-- v17: nhan dien map — office (Computers) chi co o Surakarta


local parent = nil
pcall(function()
    parent = gethui and gethui() or CoreGui
end)
if not parent then
    parent = LocalPlayer:WaitForChild("PlayerGui")
end
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
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

-- ============ THEME + RAINBOW 12 MAU ============
local HUB_BG    = Color3.fromRGB(10, 14, 22)
local HUB_SIDE  = Color3.fromRGB(14, 20, 32)
local CARD_BG   = Color3.fromRGB(18, 26, 40)
local themeColor = Color3.fromRGB(0, 229, 160)
local ACCENT2   = Color3.fromRGB(56, 189, 248)
local TXT_DIM   = Color3.fromRGB(150, 165, 185)

local RAINBOW = {
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(255, 120, 40),
    Color3.fromRGB(255, 180, 40),
    Color3.fromRGB(255, 230, 60),
    Color3.fromRGB(160, 230, 60),
    Color3.fromRGB(90, 230, 90),
    Color3.fromRGB(60, 220, 160),
    Color3.fromRGB(60, 200, 220),
    Color3.fromRGB(70, 160, 255),
    Color3.fromRGB(110, 110, 255),
    Color3.fromRGB(160, 90, 255),
    Color3.fromRGB(225, 80, 220),
}
local RN = #RAINBOW
local function rainbowAt(pos)
    pos = pos % RN
    local idx = math.floor(pos) + 1
    local f = pos - (idx - 1)
    local a = RAINBOW[idx]
    local b = RAINBOW[(idx % RN) + 1]
    return a:Lerp(b, f)
end

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
task.spawn(function()
    local t = 0
    while true do
        t = t + 0.15
        local col
        if ledMode == "rainbow" then
            col = rainbowAt(t)
        else
            col = ledFixedColor
        end
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

local statRingSegs = {}
local statRingFrame = nil
local function makeStatRing(target, W, H, inset, T, n1, n2)
    local rf = Instance.new("Frame")
    rf.Name = "StatRing"
    rf.BackgroundTransparency = 1
    rf.BorderSizePixel = 0
    rf.Size = UDim2.new(0, W, 0, H)
    rf.Position = target.Position
    rf.Visible = target.Visible
    rf.ZIndex = 20
    rf.Active = false
    rf.Parent = ScreenGui
    local xs = {}
    for i = 0, n1 do xs[i] = math.floor(inset + i * (W - 2 * inset) / n1) end
    local ys = {}
    for i = 0, n2 do ys[i] = math.floor(inset + i * (H - 2 * inset) / n2) end
    local function addPx(x, y, w, h)
        local f = Instance.new("Frame")
        f.Position = UDim2.new(0, x, 0, y)
        f.Size = UDim2.new(0, w, 0, h)
        f.BorderSizePixel = 0
        f.ZIndex = 21
        f.Parent = rf
        table.insert(statRingSegs, f)
    end
    for i = 0, n1 - 1 do addPx(xs[i], inset, xs[i + 1] - xs[i], T) end
    for i = 0, n2 - 1 do addPx(W - inset - T, ys[i], T, ys[i + 1] - ys[i]) end
    for i = n1 - 1, 0, -1 do addPx(xs[i], H - inset - T, xs[i + 1] - xs[i], T) end
    for i = n2 - 1, 0, -1 do addPx(inset, ys[i], T, ys[i + 1] - ys[i]) end
    return rf
end
task.spawn(function()
    local t = 0
    local n = #statRingSegs
    while true do
        t = t + 0.15
        if statRingFrame and ledOn then
            statRingFrame.Position = statPanel and statPanel.Position or statRingFrame.Position
            statRingFrame.Visible = statPanel and statPanel.Visible or false
            if statRingFrame.Visible and n > 0 then
                for i, seg in ipairs(statRingSegs) do
                    seg.BackgroundColor3 = rainbowAt(t + (i - 1) * RN / n)
                end
            end
        end
        task.wait(0.03)
    end
end)

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
local autoRejoinEnabled = false
local optFPS = false

-- ============ NUT NOI (VUONG + LED RGB) ============
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
local strokeAutoTFloat = Instance.new("UIStroke", AutoTFloatingBtn)
strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
strokeAutoTFloat.Thickness = 2

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
local strokeBodyFloat = Instance.new("UIStroke", BodyManagerFloatingBtn)
strokeBodyFloat.Color = Color3.fromRGB(0, 230, 180)
strokeBodyFloat.Thickness = 2

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
local strokeFreecamFloat = Instance.new("UIStroke", FreecamFloatingBtn)
strokeFreecamFloat.Color = Color3.fromRGB(100, 150, 255)
strokeFreecamFloat.Thickness = 2

-- ============ BANG STATUS (GIU NGUYEN VI TRI) ============
do
    statPanel = Instance.new("Frame")
    statPanel.Size = UDim2.new(0, 250, 0, 134)
    statPanel.Position = UDim2.new(0, 76, 0.5, 62)
    statPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    statPanel.BackgroundTransparency = 0.45
    statPanel.BorderSizePixel = 0
    statPanel.Active = true
    statPanel.Draggable = true
    statPanel.Visible = false
    statPanel.ZIndex = 5
    statPanel.Parent = ScreenGui
    Instance.new("UICorner", statPanel).CornerRadius = UDim.new(0, 10)
    local function statLabel(text, y, size, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -24, 0, size or 16)
        l.Position = UDim2.new(0, 14, 0, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color or Color3.fromRGB(235, 235, 235)
        l.Font = Enum.Font.Code
        l.TextSize = size or 15
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 7
        l.Parent = statPanel
        return l
    end
    lblMode  = statLabel("—", 12, 17, Color3.fromRGB(255, 200, 80))
    lblStat1 = statLabel("", 38, 15, Color3.fromRGB(140, 255, 140))
    lblStat2 = statLabel("", 59, 15, Color3.fromRGB(140, 220, 255))
    lblTime  = statLabel("thời gian farm: 00:00", 80, 14, Color3.fromRGB(255, 220, 140))
    lblWork  = statLabel("status: tạm nghỉ", 104, 13, Color3.fromRGB(200, 200, 200))
end

local function setStatus(t)
    if lblWork then
        lblWork.Text = "status: " .. t
    end
end
local function fmtTime(s)
    s = math.floor(s)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, sec)
    end
    return string.format("%02d:%02d", m, sec)
end
local function refreshStatPanel()
    if activeMode == "office" then
        lblMode.Text = "OFFICE STATUS"
        lblMode.TextColor3 = Color3.fromRGB(120, 200, 255)
        lblStat1.Text = "lượt giải: " .. ofAnswers
        lblStat2.Text = "lượt in: " .. ofPrints
    else
        lblMode.Text = "—"
        lblStat1.Text = ""
        lblStat2.Text = ""
    end
end
task.spawn(function()
    while true do
        task.wait(1)
        if activeMode and farmStart > 0 then
            lblTime.Text = "thời gian farm: " .. fmtTime(os.clock() - farmStart)
        end
    end
end)

-- ============ FPS / PING OVERLAY (keo tha + khoa) ============
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
    if (not p) or p <= 0 then
        pcall(function() p = player:GetNetworkPing() end)
    end
    if p and p > 0 and p < 1 then
        p = p * 1000
    end
    return math.floor(p or 0)
end
local fpsFrames = 0
RunService.RenderStepped:Connect(function()
    fpsFrames = fpsFrames + 1
end)
task.spawn(function()
    while true do
        task.wait(1)
        local fps = fpsFrames
        fpsFrames = 0
        if perfOn then
            perfLabel.Text = string.format("FPS: %d | Ping: %dms", fps, getPing())
        end
    end
end)

-- ============ CHUC NANG AN TEN / DOI TEN ============
local hideNameOn = false
local customName = ""

local function getChar() return LocalPlayer.Character end

local function hideNameTags()
    local c = getChar()
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        pcall(function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
    end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BillboardGui") then
            pcall(function() d.Enabled = false end)
        end
    end
end

local function showNameTags()
    local c = getChar()
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        pcall(function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end)
    end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BillboardGui") then
            pcall(function() d.Enabled = true end)
        end
    end
end

local function applyCustomName()
    local c = getChar()
    if not c then return end
    pcall(function() LocalPlayer.DisplayName = customName end)
    local myName = LocalPlayer.Name
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BillboardGui") then
            for _, t in ipairs(d:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text:find(myName, 1, true) then
                    t.Text = customName
                end
            end
        end
    end
end

local function watchChar(c)
    if not c then return end
    c.DescendantAdded:Connect(function(d)
        if d:IsA("BillboardGui") then
            if hideNameOn then
                pcall(function() d.Enabled = false end)
            end
            if customName ~= "" then
                task.wait(0.2)
                applyCustomName()
            end
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
        if hideNameOn then
            hideNameTags()
        end
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
    HubFrame.Draggable = false
    HubFrame.Visible = false
    HubFrame.ClipsDescendants = true
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
    content.ClipsDescendants = true
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
        pg.Visible = false
        pg.ZIndex = 11
        pg.Parent = content
        pages[name] = pg
        return pg
    end
    local function selectPage(name)
        currentPageName = name
        for n, pg in pairs(pages) do
            pg.Visible = (n == name)
        end
        for n, b in pairs(navBtns) do
            if n == name then
                b.BackgroundColor3 = Color3.fromRGB(24, 36, 54)
                b.TextColor3 = themeColor
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
        b.MouseButton1Click:Connect(function()
            selectPage(name)
        end)
        addPage(name)
        return b
    end

    addNav("TUNER", "🎛️")
    addNav("CHUNG", "🧰")
    addNav("SETTINGS", "⚙️")
    
    local tunerPage = pages["TUNER"]
    local chungPage = pages["CHUNG"]
    local settingsPage = pages["SETTINGS"]
    

    -- TUNER
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
    
-- ============================================================
-- TUNER — v3: chặn tune vào bảng nhân vật + bỏ mass/weight khỏi DRAG
-- Giữ: depth 6, count feedback, idempotency guard, RPM filter
-- ============================================================
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
        setStatusTmp("⚠ Xe này đã tune rồi — respawn xe để apply",
                     Color3.fromRGB(255, 180, 60), 4)
        return
    end

    local hpMult    = tonumber(hpBox.Text)         or 5.0
    local rpmAdd    = tonumber(rpmBox.Text)        or 3500
    local gearMult  = tonumber(gearRatioBox.Text)  or 0.8
    local finalMult = tonumber(finalDriveBox.Text) or 0.8
    local count = 0

    -- v3: gom part của nhân vật để chặn tune bảng char-owned
    local charParts = {}
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then charParts[p] = true end
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then charParts[hrp] = true end
    end

    local function isCharOwned(t)
        -- chỉ quét 1 tầng key/value, không đệ quy
        local ok1, res1 = pcall(function()
            for _, v in pairs(t) do
                if typeof(v) == "Instance" and charParts[v] then return true end
            end
            return false
        end)
        if ok1 and res1 then return true end
        return false
    end

    local function unfreeze(t)
        pcall(function() setreadonly(t, false) end)
    end

    local SPEED_KEYS = { topspeed=true, maxspeed=true, speedlimit=true, maxvelocity=true, topspeedkmh=true, maxthrottle=true, limiter=true }
    local POWER_KEYS = { horsepower=true, torque=true, maxpower=true }
    local RPM_KEYS   = { redline=true, maxrpm=true, rpm=true }
    local GEAR_KEYS  = { gearratio=true, finaldrive=true }
    local GEAR_TBL   = { gearratios=true, gears=true }
    -- v3: bỏ mass / weight / weightkg — dính nhân vật
    local DRAG_KEYS  = { drag=true, dragcoefficient=true, airresistance=true }
    local seen = {}

    local function tuneTable(t, depth)
        if depth > 6 or seen[t] then return end
        if isCharOwned(t) then return end   -- v3: chặn bảng thuộc nhân vật
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

    -- tầng 1: VM scan
    if typeof(getgc) == "function" then
        pcall(function()
            for _, obj in pairs(getgc(true)) do
                if typeof(obj) == "table" then
                    pcall(function() tuneTable(obj, 1) end)
                end
            end
        end)
    end

    -- tầng 2: quét xe (Attributes + NumberValue/IntValue)
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
                            -- v3: bỏ mass / weight ở đây luôn
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
                        if obj.Value >= 1000 then
                            obj.Value = obj.Value + rpmAdd; count = count + 1
                        end
                    elseif name:find("gear") or name:find("ratio") then
                        obj.Value = obj.Value * gearMult; count = count + 1
                    elseif name:find("drive") then
                        obj.Value = obj.Value * finalMult; count = count + 1
                    elseif name:find("drag") then
                        -- v3: bỏ mass / weight
                        obj.Value = obj.Value * 0.7; count = count + 1
                    end
                end)
            end
        end
    end

    if count == 0 then
        setStatusTmp("⚠ Không tìm thấy gì để tune",
                     Color3.fromRGB(255, 180, 60), 4)
        return
    end

    if vehicleModel then tunedModels[vehicleModel] = true end

    setStatusTmp("✔ Đã tune (xuống xe lên lại)",
                 Color3.fromRGB(0, 255, 120), 4)
end)

    -- CHUNG (card cao 110, nut y=70)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
    scroll.ScrollBarThickness = 4
    scroll.ZIndex = 12
    scroll.Parent = chungPage
    local function makeCard(y, title, desc, strokeColor)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -8, 0, 110)
        card.Position = UDim2.new(0, 4, 0, y)
        card.BackgroundColor3 = CARD_BG
        card.BorderSizePixel = 0
        card.ZIndex = 12
        card.Parent = scroll
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
    local cardFarm = makeCard(0, "🌾 OFFICE AUTOFARM — farm văn phòng", "Tự ngồi ghế, giải toán & in ấn.\nSố liệu hiện trong bảng status khi bật.", ACCENT2)
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
            if ok ~= farmOK then
                applyFarmAvailability()
            end
        end
    end)
    local cardBody = makeCard(120, "🚗 THÁO DÀN ÁO — quản lý part xe", "BẬT = hiện nút nổi 🚗 để dùng.\nTẮT = ẩn nút nổi, đóng bảng.", Color3.fromRGB(0, 230, 180))
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
    local cardFc = makeCard(240, "📷 FREECAM CINEMATIC — quay phim", "BẬT = hiện nút nổi 📷 để dùng.\nTẮT = ẩn nút nổi, đóng menu.", Color3.fromRGB(100, 150, 255))
    fcOpenBtn = Instance.new("TextButton")
    fcOpenBtn.Size = UDim2.new(0.9, 0, 0, 28)
    fcOpenBtn.Position = UDim2.new(0.05, 0, 0, 70)
    fcOpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    fcOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fcOpenBtn.Text = "📷 FREECAM: ĐANG TẮT"
    fcOpenBtn.TextSize = 10
    fcOpenBtn.Font = Enum.Font.GothamBold
    fcOpenBtn.ZIndex = 13
    fcOpenBtn.Parent = cardFc
    Instance.new("UICorner", fcOpenBtn).CornerRadius = UDim.new(0, 6)
            -- SETTINGS (v15) — collapsible sections
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
    Enum.SavedQualitySetting.QualityLevel1,
    Enum.SavedQualitySetting.QualityLevel2,
    Enum.SavedQualitySetting.QualityLevel3,
    Enum.SavedQualitySetting.QualityLevel4,
    Enum.SavedQualitySetting.QualityLevel5,
    Enum.SavedQualitySetting.QualityLevel6,
    Enum.SavedQualitySetting.QualityLevel7,
    Enum.SavedQualitySetting.QualityLevel8,
    Enum.SavedQualitySetting.QualityLevel9,
    Enum.SavedQualitySetting.QualityLevel10,
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
        if not b then
            b = Instance.new("BloomEffect", Lighting)
            b.Name = "KhangLeBloom"
        end
        b.Enabled = on
        if intensity then b.Intensity = intensity end
        if threshold then b.Threshold = threshold end
    end)
end
local function sunSet(on, intensity)
    pcall(function()
        local s = Lighting:FindFirstChild("KhangLeSun")
        if not s then
            s = Instance.new("SunRaysEffect", Lighting)
            s.Name = "KhangLeSun"
        end
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
        cp.PaddingTop = UDim.new(0, 8)
        cp.PaddingBottom = UDim.new(0, 8)
        cp.PaddingLeft = UDim.new(0, 8)
        cp.PaddingRight = UDim.new(0, 8)

        local isOpen = defaultOpen or false
        header.Text = (isOpen and "▼ " or "▶ ") .. title
        header.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            content.Visible = isOpen
            header.Text = (isOpen and "▼ " or "▶ ") .. title
        end)
        return content
    end

    -- helper tạo nút toggle trong section
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

    -- helper tạo hàng input (label + textbox + nút)
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

    -- ============ SECTION: MÀU MENU + LED ============
    local colorSection = makeSection(1, "🎨 Màu menu + LED", false)
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
    for i, c in ipairs(themePresets) do
        local sw = Instance.new("TextButton", colorRow)
        sw.Size = UDim2.new(0, 30, 1, 0)
        sw.BackgroundColor3 = c
        sw.Text = ""
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 6)
        sw.MouseButton1Click:Connect(function() applyTheme(c) end)
    end
    makeInput(colorSection, 2, "Mã menu", "#00E5A0", "ÁP DỤNG", Color3.fromRGB(0, 150, 120), function(txt, cb)
        local col, up = parseHex(txt)
        if not col then cb("❌ mã màu sai (VD: #00E5A0)", false) return end
        applyTheme(col)
        cb("✔ màu menu = #" .. up, true)
    end)
    makeInput(colorSection, 4, "Mã LED", "#FF00AA", "ÁP DỤNG", Color3.fromRGB(0, 150, 120), function(txt, cb)
        local col, up = parseHex(txt)
        if not col then cb("❌ hex sai", false) return end
        ledMode = "fixed"
        ledFixedColor = col
        cb("✔ LED = #" .. up, true)
    end)
    makeToggle(colorSection, 6, ledMode == "rainbow", "🌈 LED: RAINBOW", "🌈 LED: ĐƠN SẮC", Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70), function(v)
        if v then ledMode = "rainbow" else ledMode = "fixed" end
    end)

    -- ============ SECTION: TÊN HIỂN THỊ ============
    local nameSection = makeSection(2, "👤 Tên hiển thị", false)
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

    -- ============ SECTION: HIỆU NĂNG ============
    local perfSection = makeSection(3, "⚡ Hiệu năng", false)
    makeToggle(perfSection, 1, false, "⚡ TỐI ƯU FPS: BẬT", "⚡ TỐI ƯU FPS: TẮT", Color3.fromRGB(40, 110, 180), Color3.fromRGB(60, 60, 70), function(v)
        optFPS = v
        if v then
            pcall(function() Lighting.GlobalShadows = false end)
            bloomSet(false)
            sunSet(false)
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
            bloomSet(true, 0.6, 0.7)
            sunSet(true, 0.3)
            setQualityLevel(10)
        else
            bloomSet(true, 0.4, 0.8)
            sunSet(false)
            setQualityLevel(nil)
        end
    end)
    makeToggle(perfSection, 3, false, "📊 FPS/PING: BẬT", "📊 FPS/PING: TẮT", Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70), function(v)
        perfOn = v
        perfFrame.Visible = v
    end)
    makeToggle(perfSection, 4, false, "🔒 KHÓA VỊ TRÍ: BẬT", "🔒 KHÓA VỊ TRÍ: TẮT", Color3.fromRGB(180, 120, 40), Color3.fromRGB(60, 60, 70), function(v)
        perfLocked = v
        perfFrame.Draggable = not v
    end)

    -- ============ SECTION: SERVER ============
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
        local servers = fetchServers()
        if not servers then return end
        for _, s in ipairs(servers) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player) end)
                return
            end
        end
    end)
    btnSmall.MouseButton1Click:Connect(function()
        local servers = fetchServers()
        if not servers then return end
        local best = nil
        for _, s in ipairs(servers) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                if not best or s.playing < best.playing then best = s end
            end
        end
        if best then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, player) end)
        end
    end)
    btnRejoin.MouseButton1Click:Connect(function()
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    end)

    -- ============ SECTION: AUTO REJOIN ============
    local rejoinSection = makeSection(5, "🤖 Auto Rejoin", false)
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

            -- AUTO EXECUTE: chỉ tự load script khi vào game mới
    makeToggle(rejoinSection, 2, readFlag("autoExecute.txt"), "🔄 AUTO EXECUTE: BẬT", "🔄 AUTO EXECUTE: TẮT", Color3.fromRGB(120, 80, 200), Color3.fromRGB(60, 60, 70), function(v)
        if writefile then pcall(writefile, "autoExecute.txt", v and "1" or "0") end
        if v and queue_on_teleport then
            pcall(queue_on_teleport, [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangleddstuner.lua"))()
]])
        end
    end)

    -- AUTO REJOIN: chỉ tự vào lại game khi bị kick
    makeToggle(rejoinSection, 3, readFlag("autoRejoin.txt"), "🔁 AUTO REJOIN: BẬT", "🔁 AUTO REJOIN: TẮT", Color3.fromRGB(140, 80, 40), Color3.fromRGB(60, 60, 70), function(v)
        if writefile then pcall(writefile, "autoRejoin.txt", v and "1" or "0") end
    end)

    -- ============ SECTION: ANTI-AFK ============
    local afkSection = makeSection(6, "🛡️ Anti-AFK", false)
    makeToggle(afkSection, 1, true, "🛡️ ANTI-AFK: BẬT", "🛡️ ANTI-AFK: TẮT", Color3.fromRGB(46, 140, 67), Color3.fromRGB(60, 60, 70), function(v)
        antiAfk = v
    end)
    
    

    

    


    



    selectPage("TUNER")

    function applyTheme(c)
        themeColor = c
        hubStroke.Color = c
        hubHeader.TextColor3 = c
        ToggleBtn.TextColor3 = c
        if currentPageName then
            selectPage(currentPageName)
        end
        if farmSwitch and farmSwitch.isOn() then
            farmSwitch.set(true)
        end
    end

    
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
            strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
            end)
        end
    end)
    AutoTFloatingBtn.MouseButton1Click:Connect(function()
        autoTActive = not autoTActive
        if autoTActive then
            AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            strokeAutoTFloat.Color = Color3.fromRGB(0, 255, 120)
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            end)
        else
            AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
            end)
        end
    end)
    RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local s = h and h.SeatPart
        local isInVehicle = (s and (s:IsA("VehicleSeat") or s:IsA("Seat")))
        if autoTActive then
            if isInVehicle then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
                end)
            else
                autoTActive = false
                AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
                pcall(function()
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
                end)
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
    ControlStroke.Parent = ControlPanel
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
            strokeBodyFloat.Color = Color3.fromRGB(0, 255, 180)
        else
            BodyManagerFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            strokeBodyFloat.Color = Color3.fromRGB(0, 230, 180)
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
        strokeBodyFloat.Color = Color3.fromRGB(0, 230, 180)
    end)
    local SelectionBoxObj = Instance.new("SelectionBox")
    SelectionBoxObj.Color3 = Color3.fromRGB(0, 230, 180)
    SelectionBoxObj.LineThickness = 0.05
    SelectionBoxObj.Adornee = nil
    pcall(function()
        SelectionBoxObj.Parent = CoreGui
    end)
    if SelectionBoxObj.Parent ~= CoreGui then
        SelectionBoxObj.Parent = ScreenGui
    end
    ScanBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then
            ScanBtn.Text = "Không tìm thấy nhân vật!"
            task.wait(1.5)
            ScanBtn.Text = "Quét Lại Xe"
            return
        end
        local humanoid = char.Humanoid
        local seatPart = humanoid.SeatPart
        if not seatPart then
            ScanBtn.Text = "Hãy ngồi lên xe!"
            task.wait(1.5)
            ScanBtn.Text = "Quét Lại Xe"
            return
        end
        local model = seatPart.Parent
        while model and model ~= workspace and not model:FindFirstChildOfClass("Humanoid") do
            if model.Parent == workspace then break end
            model = model.Parent
        end
        if model then
            currentVehicle = model
            ScanBtn.Text = "Quét Thành Công!"
            task.wait(1.5)
            ScanBtn.Text = "Quét Lại Xe"
        else
            ScanBtn.Text = "Không nhận diện!"
            task.wait(1.5)
            ScanBtn.Text = "Quét Lại Xe"
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
            if decal and decal.Parent then
                decal.Transparency = trans
            end
        end
        originalDecalTransparencies = {}
        SelectionBoxObj.Adornee = nil
    end
    ToggleModeBtn.MouseButton1Click:Connect(function()
        if not currentVehicle then
            ToggleModeBtn.Text = "Hãy Quét Xe Trước!"
            task.wait(1.5)
            ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"
            return
        end
        modeActive = not modeActive
        if modeActive then
            ToggleModeBtn.Text = "Chế độ Soi & Tháo: BẬT"
            ToggleModeBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            ToggleModeBtn.Text = "Chế độ Soi & Tháo: TẮT"
            ToggleModeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            restorePartAppearance()
            selectedPart = nil
            selectedParentContainer = nil
            modelPartsList = {}
            lastSelectedPart = nil
        end
    end)
    local function updateSelectionInfo()
        restorePartAppearance()
        if not selectedPart or not selectedPart.Parent or not currentVehicle then
            StatusText.Text = " Part: Chưa chọn\nCụm: Chưa chọn\nSố part trong cụm: 0"
            lastSelectedPart = nil
            return
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
                        if child:IsA("BasePart") then
                            table.insert(modelPartsList, child)
                        end
                    end
                else
                    table.insert(modelPartsList, selectedPart)
                end
                for i, p in ipairs(modelPartsList) do
                    if p == targetPart then
                        currentIndex = i
                        break
                    end
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
        if not originalParents[part] then
            originalParents[part] = part.Parent
        end
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
                        selectedPart = p
                        foundNext = true
                        break
                    end
                end
            end
            if foundNext then
                updateSelectionInfo()
            else
                restorePartAppearance()
                selectedPart = nil
                selectedParentContainer = nil
                modelPartsList = {}
                lastSelectedPart = nil
                updateSelectionInfo()
            end
        end
    end)
    HideCompBtn.MouseButton1Click:Connect(function()
        if selectedParentContainer then
            for _, child in ipairs(selectedParentContainer:GetDescendants()) do
                if child:IsA("BasePart") then
                    hideSinglePart(child)
                end
            end
            restorePartAppearance()
            selectedPart = nil
            selectedParentContainer = nil
            modelPartsList = {}
            lastSelectedPart = nil
            updateSelectionInfo()
        end
    end)
    NextPartBtn.MouseButton1Click:Connect(function()
        if #modelPartsList > 0 then
            local found = false
            for count = 1, #modelPartsList do
                currentIndex = currentIndex % #modelPartsList + 1
                local p = modelPartsList[currentIndex]
                if p and p.Parent ~= nil then
                    selectedPart = p
                    found = true
                    break
                end
            end
            if found then
                updateSelectionInfo()
            else
                selectedPart = nil
                SelectionBoxObj.Adornee = nil
            end
        end
    end)
    PrevPartBtn.MouseButton1Click:Connect(function()
        if #modelPartsList > 0 then
            local found = false
            for count = 1, #modelPartsList do
                currentIndex = currentIndex - 1
                if currentIndex < 1 then currentIndex = #modelPartsList end
                local p = modelPartsList[currentIndex]
                if p and p.Parent ~= nil then
                    selectedPart = p
                    found = true
                    break
                end
            end
            if found then
                updateSelectionInfo()
            else
                selectedPart = nil
                SelectionBoxObj.Adornee = nil
            end
        end
    end)
    DeselectBtn.MouseButton1Click:Connect(function()
        restorePartAppearance()
        selectedPart = nil
        selectedParentContainer = nil
        modelPartsList = {}
        lastSelectedPart = nil
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
        selectedPart = nil
        selectedParentContainer = nil
        modelPartsList = {}
        lastSelectedPart = nil
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
    local hideDragging, hideDragStart, hideStartPos
    hideFloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hideDragging = true
            hideDragStart = input.Position
            hideStartPos = hideFloatBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if hideDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - hideDragStart
            hideFloatBtn.Position = UDim2.new(hideStartPos.X.Scale, hideStartPos.X.Offset + delta.X, hideStartPos.Y.Scale, hideStartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hideDragging = false
        end
    end)
    local freecamMenuDragging, freecamMenuDragStart, freecamMenuStartPos
    freecamMenuTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            freecamMenuDragging = true
            freecamMenuDragStart = input.Position
            freecamMenuStartPos = freecamMenuFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if freecamMenuDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - freecamMenuDragStart
            freecamMenuFrame.Position = UDim2.new(freecamMenuStartPos.X.Scale, freecamMenuStartPos.X.Offset + delta.X, freecamMenuStartPos.Y.Scale, freecamMenuStartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            freecamMenuDragging = false
        end
    end)
    FreecamFloatingBtn.MouseButton1Click:Connect(function()
        freecamMenuFrame.Visible = not freecamMenuFrame.Visible
    end)
    local function setRobloxTouchGuiTransparency(transparency)
        local touchGui = LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
        if touchGui then
            local descTable = touchGui:GetDescendants()
            for i = 1, #descTable do
                local descendant = descTable[i]
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
    bindTouch(btnW, "W")
    bindTouch(btnS, "S")
    bindTouch(btnA, "A")
    bindTouch(btnD, "D")
    bindTouch(btnUp, "Up")
    bindTouch(btnDown, "Down")
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
        if touch == activeTouch then
            activeTouch = nil
            lastTouchPos = nil
        end
    end)
    RunService.RenderStepped:Connect(function(dt)
        if not freecamActive then return end
        local smoothFactor = math.clamp(dt * 16, 0, 1)
        camAngles = camAngles:Lerp(targetCamAngles, smoothFactor)
        if zoomInActive then
            currentFOV = math.clamp(currentFOV - 35 * dt, 10, 120)
        elseif zoomOutActive then
            currentFOV = math.clamp(currentFOV + 35 * dt, 10, 120)
        end
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
-- KHOI 5: OFFICE FARM v20 (logic officefarm v51 giu nguyen)
-- ============================================================

    local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
    local TeamChangeRequest = JobEvents:WaitForChild("TeamChangeRequest", 5)
    local GenerateQuestion = JobEvents:WaitForChild("GenerateQuestion")
    local CorrectAnswer   = JobEvents:WaitForChild("CorrectAnswer")
    local AssignPrintJob  = JobEvents:WaitForChild("AssignPrintJob")
    local ClearPrintJob   = JobEvents:WaitForChild("ClearPrintJob")
    local Computers = workspace:FindFirstChild("Computers")

    local OF_FLY_SPEED = 55
    local OF_FLY_TIMEOUT = 240
    local OF_FLY_ONLY_DIST = 150
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
                if p.Parent then
                    p.CanCollide = true
                end
            end
            table.clear(of_savedCollide)
        end
    end)
    local of_sprintOn = false

local function of_sprintToggle()
    pcall(function()
        keypress(Enum.KeyCode.LeftShift)
    end)
end

local of_sprintActivated = false

local function of_ensureSprint(h)
    if of_sprintActivated then return end
    pcall(function() keypress(Enum.KeyCode.LeftShift) end)
    of_sprintActivated = true
end

local function of_endSprint(h)
    -- không làm gì, sprint giữ nguyên
end
    local function of_enableSit(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        end
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
        if farmOffice then
            setStatus("đang giải")
        end
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
    AssignPrintJob.OnClientEvent:Connect(function(name)
        of_printAssigned = name
    end)
    ClearPrintJob.OnClientEvent:Connect(function()
        of_printAssigned = nil
        ofPrints = ofPrints + 1
        refreshStatPanel()
    end)
    local function of_findButton(text)
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextButton") and d.Text == text and d.Visible and d.AbsoluteSize.X > 0 then
                return d
            end
        end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == text and d.Visible and d.AbsoluteSize.X > 0 then
                local p = d.Parent
                if p and (p:IsA("TextButton") or p:IsA("ImageButton")) then
                    return p
                end
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
        if pcall(function() firesignal(btn.MouseButton1Click) end) then
            return 1
        end
        if pcall(function() firesignal(btn.Activated) end) then
            return 2
        end
        local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
        local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
        if of_onScreen(x, y) then
            if pcall(function()
                touchpress(x, y)
                task.wait(0.06)
                touchrelease(x, y)
            end) then
                return 3
            end
        end
        return nil
    end
    local function of_root()
        local c = player.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function of_humanoid()
        local c = player.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    local function of_seatsNear(pos, radius)
        local out = {}
        local ok, parts = pcall(function()
            return workspace:GetPartBoundsInRadius(pos, radius)
        end)
        if not ok or not parts then return out end
        for _, p in ipairs(parts) do
            if p:IsA("Seat") or p:IsA("VehicleSeat") then
                table.insert(out, p)
            end
        end
        return out
    end
    
    local function of_flyTo(target, stopDist, timeout)
    local hrp = of_root()
    if not hrp then return false end

    -- 1 frame, giống King Akbar. Không stepped, không BodyVelocity.
    local look = Vector3.new(target.X, hrp.Position.Y, target.Z)
    hrp.CFrame = CFrame.new(target, look)
    task.wait(0.15)

    local ok = hrp.Position and (hrp.Position - target).Magnitude <= (stopDist or 8) + 5
    return ok or false
end
    local function of_standUp()
    local h = of_humanoid()
    if not h then return end
    if not h.Sit and h:GetState() ~= Enum.HumanoidStateType.Seated then return end

    pcall(function() h.Sit = false end)
    task.wait(0.25)

    if h.Sit then
        pcall(function() h.Jump = true end)
        task.wait(0.3)
    end

    if h.Sit then
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        task.wait(0.3)
    end
end
    
local OF_TELE_MIN = 60   -- dưới 40 studs → đi bộ

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
    if allowSit then
        reached = true
        break
    else
        of_standUp()
    end
end

            local delta = target - hrp.Position
            local flat = Vector3.new(delta.X, 0, delta.Z)
            if flat.Magnitude <= stopDist then
                reached = true
                break
            end

            h:MoveTo(Vector3.new(target.X, hrp.Position.Y, target.Z))
            task.wait(0.15)
        end
    end)

    local h = of_humanoid()
    local hrp = of_root()
    if h and hrp then
        h:MoveTo(hrp.Position)
    end
    return reached
end
local function of_teleTo(target)
    local hrp = of_root()
    if not hrp then return false end

    local dist = (target - hrp.Position).Magnitude
    if dist < OF_TELE_MIN then
        return of_walkTo(target, 3, 15, false, false)
    end

    setStatus("tele xa (" .. math.floor(dist) .. ")")
    hrp.CFrame = CFrame.new(target)
    task.wait(0.6)
    return true
end

local function of_teleNear(target, offsetDist)
    local hrp = of_root()
    if not hrp then return false end

    local dist = (target - hrp.Position).Magnitude
    if dist < OF_TELE_MIN then
        -- gần → đi bộ, fail thì return false
        setStatus("đi bộ (" .. math.floor(dist) .. ")")
        return of_walkTo(target, offsetDist or 4, 8, false, false)
    end

    -- xa → tele
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



    local function of_forceSit(h)
        for _, seat in ipairs(of_seatsNear(CHAIR_POS, 8)) do
            if seat.Occupant == nil then
                local okSit = pcall(function() seat:Sit(h) end)
                if okSit then
                    task.wait(0.3)
                    if h.Sit then return true end
                end
            end
        end
        return false
    end
    
    
    

        
    local function of_solve(q)
        if not q or type(q.text) ~= "string" or type(q.choices) ~= "table" then
            return nil
        end
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
            if (v and math.abs(v - r) < 1e-6) or tostring(c.Text) == tostring(r) then
                return c
            end
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
        
            pcall(function()
                CorrectAnswer:FireServer(unpack(of_buildArgs(q, choice)))
            end)
        end
        of_awaitingAck = true
        of_lastFireAt = os.clock()
        return true
    end
   
   local function of_findNearestSeat(pos, radius)
    radius = radius or 150
    local candidates = {}
    local ok, parts = pcall(function()
    return workspace:GetPartBoundsInRadius(pos, math.min(radius, 40))
end)
    if not ok or not parts then return nil end

    for _, p in ipairs(parts) do
        if (p:IsA("Seat") or p:IsA("VehicleSeat")) and p.Occupant == nil then
            local parentName = p.Parent and p.Parent.Name or ""
            local isWorkChair = (parentName == "Setup")
                or parentName:lower():find("chair")
                or parentName:lower():find("seat")

            if isWorkChair then
                local d = (p.Position - pos).Magnitude
                table.insert(candidates, { seat = p, dist = d })
            end
        end
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    return candidates[1].seat
end
local function of_findSeatAtDist(pos, minDist, maxDist)
    local out = {}
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(pos, maxDist or 250)
    end)
    if not ok or not parts then return nil end

    for _, p in ipairs(parts) do
        if (p:IsA("Seat") or p:IsA("VehicleSeat")) and p.Occupant == nil then
            local d = (p.Position - pos).Magnitude
            if d >= (minDist or 60) then
                table.insert(out, { seat = p, dist = d })
            end
        end
    end
    if #out == 0 then return nil end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out[1].seat
end
local of_initialTeleDone = false
local OF_SKIPPED_SEATS = {}
local function of_findNearestUntriedSeat(pos, radius, tried)
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(pos, radius or 350)
    end)
    if not ok or not parts then return nil end

    local best, bestD = nil, math.huge
    for _, p in ipairs(parts) do
        if (p:IsA("Seat") or p:IsA("VehicleSeat"))
           and p.Occupant == nil
           and not tried[p]
and not OF_SKIPPED_SEATS[p] then
            local d = (p.Position - pos).Magnitude
if d < bestD then best, bestD = p, d end        end
    end
    return best
end


local function of_sitAtChair(searchFrom)
    local h = of_humanoid()
    if h and h.Sit then return true end

    local hrp = of_root()
    if not hrp then return false end

    -- tele lần đầu khi ở xa (spawn)
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
if h and h.Sit then
    return true
end

    -- loop vô hạn: thử mọi ghế trống cho tới khi ngồi được
    local tried = {}

    while farmOffice do
        hrp = of_root()
        if not hrp then return false end

        local seat = of_findNearestUntriedSeat(hrp.Position, 350, tried)
        if not seat then
            -- hết ghế chưa thử → reset danh sách, thử lại từ đầu
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
        local Computers = workspace:FindFirstChild("Computers")
        if not Computers then return end
        local model = Computers:FindFirstChild(name)
        if not model then
            
            return
        end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        of_standUp()
        setStatus("tới máy in")
of_teleNear(part.Position, 4)
        setStatus("chuẩn bị in")
        task.wait(0.5)
        setStatus("đang in")
    
local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)

-- loop vô hạn cho tới khi in được hoặc tắt farm
while of_printAssigned and farmOffice do
    local attempt = 0

    -- thử tối đa 3 lần trong batch
    while of_printAssigned and farmOffice and attempt < 3 do
        attempt = attempt + 1

        if attempt == 1 then
            setStatus("đang in")
        else
            setStatus("thử in lại")
        end

        if prompt then
            pcall(function() prompt:InputHoldBegin() end)
            local t1 = os.clock()
            while of_printAssigned and farmOffice and os.clock() - t1 < 3 do
                task.wait(0.2)
            end
            pcall(function() prompt:InputHoldEnd() end)
        end

        -- chờ ClearPrintJob event
        local t2 = os.clock()
        while of_printAssigned and farmOffice and os.clock() - t2 < 3 do
            task.wait(0.2)
        end

        if not of_printAssigned then break end
    end

    -- in xong → thoát loop
    if not of_printAssigned then break end

    -- 3 lần fail → chờ 5s rồi thử batch mới
    setStatus("chờ 5s thử lại")
    local t3 = os.clock()
    while of_printAssigned and farmOffice and os.clock() - t3 < 5 do
        task.wait(0.2)
    end
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
    if farmOffice then
        task.wait(3)
    end
    return
end
        setStatus("ngồi ghế, chờ câu hỏi")
local idleStart = os.clock()
local noQuestionStart = os.clock()
while farmOffice do
    if of_printAssigned then break end

    -- có câu hỏi → reset timer
    if of_pendingQuestion then
        noQuestionStart = os.clock()
    end

    if of_pendingQuestion and not of_awaitingAck and (os.clock() - of_questionArrivedAt >= of_nextDelay) then                local q = of_pendingQuestion
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
                -- 5s không câu hỏi mới → đứng lên, đổi ghế
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
    -- DIEU KHIEN (noi vao farmSwitch cua script chinh)
    local function stopOffice()
    farmOffice = false
    of_killBV()
    of_jobFired = false
    of_resetUntil = 0
    if writefile then pcall(writefile, "farmState.txt", "0") end


    -- đứng lên khỏi ghế
    local h = of_humanoid()
    if h and h.Sit then
        pcall(function() h.Sit = false end)
        task.wait(0.3)
    end

    if activeMode == "office" then
        activeMode = nil
        statPanel.Visible = false
    end
    farmSwitch.set(false)
    setStatus("tạm nghỉ")
end
    farmSwitch.track.MouseButton1Click:Connect(function()
    if not farmOK then return end
    if farmOffice then
        stopOffice()
        return
    end

    -- RESET toàn bộ state trước khi bật
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
    activeMode = "office"
    farmStart = os.clock()

    TeamChangeRequest:FireServer("Office Worker", 11378976, 0, 0, "Detector")
    of_jobFired = true
    
    of_resetUntil = os.clock() + 5
   if writefile then pcall(writefile, "farmState.txt", "1") end     
    -- auto bật rejoin
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

-- ============ HET KHOI 5 ============


-- ============ NOI DAY CUOI + LED RGB NUT NOI ============
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
        strokeBodyFloat.Color = Color3.fromRGB(0, 230, 180)
    end
    bodyOpenBtn.Text = "🚗 DÀN ÁO: " .. (bodyOn and "ĐANG BẬT" or "ĐANG TẮT")
    bodyOpenBtn.BackgroundColor3 = bodyOn and Color3.fromRGB(0, 150, 120) or Color3.fromRGB(30, 30, 40)
end)

local fcOn = false
fcOpenBtn.MouseButton1Click:Connect(function()
    fcOn = not fcOn
    FreecamFloatingBtn.Visible = fcOn
    if not fcOn then
        freecamMenuFrame.Visible = false
    end
    fcOpenBtn.Text = "📷 FREECAM: " .. (fcOn and "ĐANG BẬT" or "ĐANG TẮT")
    fcOpenBtn.BackgroundColor3 = fcOn and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(30, 30, 40)
end)

addRGBStroke(ToggleBtn)
addRGBStroke(AutoTFloatingBtn)
addRGBStroke(BodyManagerFloatingBtn)
addRGBStroke(FreecamFloatingBtn)
addRGBStroke(hideFloatBtn)
statRingFrame = makeStatRing(statPanel, 250, 134, 4, 3, 14, 7) 
-- ============================================================
-- OFFICE STATUS: VIEN CAU VONG MUOT (giong Brainrot Finder)
-- Dan vao CUOI script chinh, sau dong statRingFrame = makeStatRing(...)
-- ============================================================
-- 1) Bo vien LED cu (dang segment bi dut) di
if statRingFrame then
    statRingFrame:Destroy()
    statRingFrame = nil
end
-- 2) Them vien UIStroke cau vong muot, chay doc lap luon on (giong Brainrot)
local statStroke = Instance.new("UIStroke")
statStroke.Name = "RainbowBorder"
statStroke.Thickness = 2
statStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
statStroke.Transparency = 0
statStroke.Parent = statPanel
task.spawn(function()
    local t = 0
    while true do
        t = t + 0.12
        local pos = t % RN
        local idx = math.floor(pos) + 1
        local f = pos - (idx - 1)
        statStroke.Color = RAINBOW[idx]:Lerp(RAINBOW[(idx % RN) + 1], f)
        task.wait(0.03)

    end
end)

-- đọc state auto execute + auto rejoin
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

-- Auto Rejoin: cooldown 2 phút + check popup chính xác
if _autoRejoin then
    task.spawn(function()
        -- đọc timestamp lần rejoin trước
        local lastAttempt = 0
        if readfile and isfile and isfile("lastRejoin.txt") then
            local ok, v = pcall(readfile, "lastRejoin.txt")
            if ok then lastAttempt = tonumber(v) or 0 end
        end

        while true do
            task.wait(3)

            -- cooldown 120s
            if os.time() - lastAttempt < 120 then
                -- trong cooldown, bỏ qua
            else
                local shouldRejoin = false

                -- char mất
                local c = game.Players.LocalPlayer.Character
                if not c then shouldRejoin = true end

                -- check popup "Mất kết nối" chính xác
                if not shouldRejoin then
                    pcall(function()
                        local cg = game:GetService("CoreGui")
                        for _, d in ipairs(cg:GetDescendants()) do
                            if d:IsA("TextLabel") then
                                local t = d.Text
                                if t == "Mất kết nối" or t:find("Disconnected")
                                   or t == "Kết nối bị mất" then
                                    shouldRejoin = true
                                    return
                                end
                            end
                        end
                    end)
                end

                if shouldRejoin then
                    lastAttempt = os.time()
                    if writefile then
                        pcall(writefile, "lastRejoin.txt", tostring(lastAttempt))
                    end
                    pcall(function()
                        game:GetService("TeleportService"):Teleport(game.PlaceId)
                    end)
                end
            end
        end
    end)
end
-- sau rejoin: đợi 15s → fire toggle request → đợi 10s → bật farm
task.spawn(function()
    task.wait(15)   -- chờ game load ổn định sau rejoin

    pcall(function()
        game:GetService("ReplicatedStorage")
            :WaitForChild("menuToggleRequest", 5)
            :FireServer()
    end)

    task.wait(10)   -- chờ UI game load xong sau toggle

    if readfile and isfile and isfile("farmState.txt") then
        local ok, v = pcall(readfile, "farmState.txt")
        if ok and v == "1" then
            pcall(function()
                firesignal(farmSwitch.track.MouseButton1Click)
            end)
        end
    end
end)
