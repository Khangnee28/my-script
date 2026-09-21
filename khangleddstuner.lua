-- ============================================================
-- KHANGLE DDS HUB — 4080 REMIX v14
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
local ControlPanel, freecamMenuFrame, hideFloatBtn, GuideFrame
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

-- ============ NOI DUNG GUIDE (popup 1400 / menu 1500) ============
local guideLines = {
    "Hướng dẫn xài - đọc kĩ trước khi sử dụng:",
    "mọi người hãy để nguyên mặc định xài vì do mình đã test và set như vậy mọi người có thể tùy chỉnh nhưng cần đọc kĩ những cái sau đây:",
    "mã lực: tốc độ đề pa gia tốc mạnh hơn mã lực càng nhiều đề pa càng mạnh ( Lưu ý : để ít thôi nó xoáy bánh trơn không chạy được )",
    "rpm: tua máy ngắn lại hoặc dài ra có nghĩa là khi mọi người chỉnh tua thấp xuống quá và final drive để thấp thì max speed nó sẽ không nhanh hơn tí nào đâu mà còn chậm lại nữa giống kiểu mọi người khoá tua không cho nó chạy hết tua máy",
    "tips chỉnh rpm: mình để mặc định là 3500 mọi người chỉnh final drive khi nào chạy hết ga hết số rồi mà xe nó tằng tằng thì do mọi người chỉnh top speed nó cao hơn nên tới tua đó nó muốn lên thêm mà không được nên mọi người chỉnh rpm lên chút xíu xong khi nào nó k còn tằng nữa mọi người hạ xuống 50 hoặc 100 cho nó tằng để nghe tiếng cho nó hay nha",
    "ratio gear: tỷ lệ của số có nghĩa là khi mọi người chỉnh càng nhỏ số sẽ dài ra và tốc độ của số cũng sẽ tăng lên theo và khi chỉnh số lớn thì số sẽ hết số nhanh hơn phải sang số để chạy nhanh hơn ( không nên chỉnh cái này nếu đi xe tay ga )",
    "final drive: tỷ số truyền động cuối có nghĩa là khi mọi người giảm cái này thì lực tác động lên bánh sau sẽ yếu lại nhưng top speed sẽ tăng lên giống như mọi người đi xe máy nhông to sẽ đề pa mạnh nhưng top speed lại thấp còn nhông nhỏ đề pa yếu nhưng top speed lại nhanh hơn ( nếu hạ cái này nhiều quá thấy đề pa quá yếu thì nên tăng mã lực và rút ngắn cấp số lại nha )",
    "Lưu Ý Quan Trọng: mọi người chỉ nên chỉnh rpm và final drive và mã lực thôi nha khi chỉnh ratio gear và chỉnh cả final drive nữa rất sẽ gây xung đột và lỗi khiến xe chạy nhanh bất thường và tua máy dài mênh mông nên mọi người chọn chỉnh ratio gear hoặc final drive cái nào cũng được nếu mọi người muốn chạy nhanh hơn thì cứ chỉnh 1 trong 2 cái đó thấp xuống còn muốn xe nó tằng tằng đỡ phải canh sợ game kick thì chỉnh rpm thấp xuống cho nó tằng nha",
    "Lưu Ý Về Tốc Độ: khuyên mọi người đừng chỉnh quá nhanh chỉnh mã lực đề pa xoáy bánh cho ngầu thì được nếu chạy quá nhanh hoặc bất thường về tốc độ sẽ bị game kick, nếu mọi người muốn chạy nhanh 400+ km/h thì nên nhấp nhả ga để cho speed nó lên từ từ đừng kéo một phát lên cực nhanh game sẽ phát hiện và kick mọi người vì tốc độ bất thường tốc độ tầm 370 đổ xuống là mọi người có thể kéo hết ga cũng được không cần nhấp nhả nhưng tùy xe nó lên speed chậm hay nhanh nha nó lên speed nhanh quá vẫn bị kick như bình thường nên là mọi người lưu ý với game này không ban người chơi nên bị kick thì mọi người đừng quá lo lắng.",
    "Lưu Ý Về Xe: sẽ có vài xe không áp dụng được top speed chỉ có thể tăng mã lực giúp xe đề pa sẽ mạnh hơn tăng tầm 7 - 12 km/h tùy vào xe còn top speed sẽ không hoạt động nha vì admin lock thông số xe đó nên script sẽ không can thiệp để thay đổi top speed được nhưng bù lại mọi người có thể chỉnh mã lực đề pa xoáy bánh và chỉnh rpm vẫn được nha nhưng đừng chỉnh ratio gear và final drive dễ gây xung đột và lỗi, rpm mình set mặc định là 3500 mọi người thấy chạy max speed mà nó vẫn còn dư cả khúc rpm ở thanh dưới thì mọi người giảm rpm xuống đến khi nào xe nó đờn tằng tằng nha nhưng nếu mọi người thấy xe nó tự chạy bấm dừng không được thì tăng rpm lên một chút tầm 50 - 100 gì đó để nó dư một khoản nhỏ xong lại giảm nhẹ lại 10 - 20 căn đến khi nào nó đờn tua nha để tránh lỗi tiếng pô và chạy cũng sướng hơn nữa",
    "Auto T: tự động bốc đầu cho ai muốn múa lửa",
    "cách dùng: mở menu lên và bật nó lên sau khi bật sẽ hiện một cái bong bóng nổi mọi người kéo đâu cũng được miễn thuận tiện là được sau khi lên xe mọi người bấm vào cái nút đó là được thì khi mọi người vặn ga xe sẽ tự bốc đầu lên cho cảm giác chạy rất phê",
    "lưu ý: sau khi té rất dễ bị lỗi mất nút di chuyển khi bị mọi người chỉ cần ấn vài lần vào màn hình hoặc bấm vào icon roblox trên góc phải vài lần là sẽ bình thường trở lại",
    "Tháo Dàn Áo: tháo mọi thứ của xe bánh xe áo xe cục máy bla bla..vv",
    "cách dùng: bật menu lên và bật quản lý dàn áo sau đó spawn xe muốn tháo và ngồi lên xe bấm quét xe để quét xe sau đó xuống xe bật free cam và click vào chỗ muốn tháo lưu ý bộ phận của xe được gọi là part và part có nhiều cụm tùy xe admin sẽ chia nhỏ từng cụm ra rất dễ tháo còn xe gộp một đống part vào một cụm nếu mọi người bấm vào một chỗ muốn xoá mà thấy cụm đó có tới 100 hoặc hơn 200 part có nghĩa là nó k chia nhỏ cụm ra và gộp thành 1 cụm to mọi người chịu khó bấm tới chỗ mình muốn xoá ví dụ phuộc bla bla có thể tháo luôn cục máy để chụp ảnh sau khi tháo mọi người vẫn chạy bình thường nha nhưng chịu khó xíu sau khi tháo xong hết thì mọi người tắt soi và tháo đi nha là ok",
    "lưu ý: vì xe admin không làm remote event nên khi xoá chỉ mọi người thấy được còn người khác thì không nha ai thích chụp ảnh thì dùng để tháo ra xem chi tiết rồi chụp cho đẹp nha",
    "cách tìm part muốn xoá: khi mọi người click sẽ hiện selection box có màu và tên cụm và part nếu xe được gộp nhiều cụm lại thì rất dễ tháo nó chia nhỏ ra từng part cho mỗi cụm có tên riêng mọi người muốn xoá dàn áo thì cứ di cam lại gần dàn áo rồi bấm vô xong bấm xoá cả mục là xoá hết dàn áo ngoài luôn nếu còn hình mờ hoặc tem có nghĩa xe đó có một cụm to nữa mọi người phải bấm tìm cụm to đó rồi dò từng part để xoá , sẽ có cụm trước và cụm sau là không có gộp chung đâu nha cứ click lên cụm trước hay sau rồi tìm chỗ muốn xoá ví dụ ốp đầu hay ghi đông là ở cụm trước còn cụm giữa là cái khung và mấy part nhỏ nhỏ như ốc máy bla bla nói chung muốn xoá gì thì ngồi mò chút xíu nha là hiểu !",
    "gợi ý: những mảnh dàn áo hay màu sơn và tem admin thường đặt tên part là (livery , paint) còn những xe khác có thể sẽ là những tên khác nhưng có selection box nên mọi người cứ đổi part đến khi nào thấy chỗ mình muốn xoá rồi xoá là được nha",
    "Freecam: freecam này do mình làm và mọi người có thể dùng để quay phim chụp ảnh có thể tùy chỉnh tốc độ xoay camera , di chuyển , zoom , up down như pc luôn nha",
    "cách dùng: mở menu chính lên và mở freecam sau đó mọi người tùy chỉnh tốc độ xoay camera và di chuyển freecam và trong menu có nút ẩn giao diện khi bật lên sẽ hiện nút nổi khi bấm vào sẽ ẩn toàn bộ cụm điều khiển nút nhảy nhưng vẫn bấm và di chuyển được bằng cụm điều khiển nha chỉ ẩn đi thôi chứ không mất và khi ẩn sẽ ẩn luôn nút nổi mọi người chỉ cần nhớ chỗ để nút nổi và ấn lại vị trí đó là được khi mọi người bấm ẩn mình đã cố định ở chỗ mọi người để nút nổi rồi nha",
    "lưu ý: ẩn giao diện sẽ không ẩn được UI của game nha chỉ ẩn được của roblox thôi muốn ẩn UI của game một là mọi người bật freecam của game và bấm nút con mắt sẽ ẩn hết nhưng mà vẫn còn dấu x nha và cũng k có ích lợi gì :v",
    "gợi ý: mọi người nên dùng quay video hoặc chụp ảnh của roblox không cần chụp bằng điện thoại mọi người bấm vô dấu 3 gạch tìm mục chụp ảnh có hình camera sau đó sẽ hiện một cái nút  nổi có thể di chuyển của roblox bấm ở trên là quay video và ở dưới là chụp ảnh và khi dùng cái đó thì không có thứ gì gây cản trở trên màn hình nữa nha nó chỉ quay trong game không vướng víu UI hay script gì đâu nha mọi người có thể thoải mái dùng freecam của mình để quay video không cần ẩn giao diện nha và khi quay hoặc chụp xong mọi người bấm vào roblox trên góc trái màn hình tìm chỗ thư viện ảnh và video của mọi người sẽ ở đó và chỉ việc lưu về nha!",
    "Script By Khang Lê",
    "Id Tiktok: @khangdayy215",
    "Cảm ơn đã tin tưởng và sử dụng script của mình!.",
}
local guideFullText = table.concat(guideLines, "\n\n")

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
    addNav("GUIDE", "📜")
    local tunerPage = pages["TUNER"]
    local chungPage = pages["CHUNG"]
    local settingsPage = pages["SETTINGS"]
    local guidePage = pages["GUIDE"]

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

    -- SETTINGS (ScrollingFrame)
    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Size = UDim2.new(1, 0, 1, 0)
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0
    settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 460)
    settingsScroll.ScrollBarThickness = 4
    settingsScroll.ZIndex = 12
    settingsScroll.Parent = settingsPage

    local function sectionTitle(y, text, color)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 0, 18)
        t.Position = UDim2.new(0, 10, 0, y)
        t.BackgroundTransparency = 1
        t.Text = text
        t.TextColor3 = color or themeColor
        t.TextSize = 11
        t.Font = Enum.Font.GothamBold
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 13
        t.Parent = settingsScroll
        return t
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
    local function makeSwatch(x, y, color, gradient, onClick)
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 34, 0, 26)
        sw.Position = UDim2.new(0, x, 0, y)
        sw.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
        sw.Text = ""
        sw.ZIndex = 14
        sw.Parent = settingsScroll
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 6)
        if gradient then
            local g = Instance.new("UIGradient", sw)
            g.Color = gradient
        end
        local st = Instance.new("UIStroke", sw)
        st.Color = Color3.fromRGB(255, 255, 255)
        st.Transparency = 0.75
        st.Thickness = 1
        sw.MouseButton1Click:Connect(onClick)
        return sw
    end

    sectionTitle(4, "🎨 MÀU MENU CHÍNH", themeColor)
    local themePresets = {
        Color3.fromRGB(0, 229, 160),
        Color3.fromRGB(56, 189, 248),
        Color3.fromRGB(167, 139, 250),
        Color3.fromRGB(255, 100, 100),
        Color3.fromRGB(255, 170, 60),
        Color3.fromRGB(255, 110, 190),
    }
    for i, c in ipairs(themePresets) do
        makeSwatch(10 + (i - 1) * 40, 26, c, nil, function() applyTheme(c) end)
    end
    local menuHexLbl = Instance.new("TextLabel")
    menuHexLbl.Size = UDim2.new(0, 88, 0, 24)
    menuHexLbl.Position = UDim2.new(0, 10, 0, 60)
    menuHexLbl.BackgroundTransparency = 1
    menuHexLbl.Text = "MÃ MENU:"
    menuHexLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    menuHexLbl.TextSize = 10
    menuHexLbl.Font = Enum.Font.GothamBold
    menuHexLbl.TextXAlignment = Enum.TextXAlignment.Left
    menuHexLbl.ZIndex = 13
    menuHexLbl.Parent = settingsScroll
    local menuHexBox = Instance.new("TextBox")
    menuHexBox.Size = UDim2.new(0, 110, 0, 24)
    menuHexBox.Position = UDim2.new(0, 102, 0, 60)
    menuHexBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    menuHexBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuHexBox.PlaceholderText = "#00E5A0"
    menuHexBox.Text = ""
    menuHexBox.TextSize = 10
    menuHexBox.Font = Enum.Font.GothamBold
    menuHexBox.BorderSizePixel = 0
    menuHexBox.ZIndex = 13
    menuHexBox.Parent = settingsScroll
    Instance.new("UICorner", menuHexBox).CornerRadius = UDim.new(0, 6)
    local menuHexApply = Instance.new("TextButton")
    menuHexApply.Size = UDim2.new(0, 70, 0, 24)
    menuHexApply.Position = UDim2.new(0, 220, 0, 60)
    menuHexApply.BackgroundColor3 = Color3.fromRGB(0, 150, 120)
    menuHexApply.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuHexApply.Text = "ÁP DỤNG"
    menuHexApply.TextSize = 10
    menuHexApply.Font = Enum.Font.GothamBold
    menuHexApply.ZIndex = 13
    menuHexApply.Parent = settingsScroll
    Instance.new("UICorner", menuHexApply).CornerRadius = UDim.new(0, 6)
    local menuHexStatus = Instance.new("TextLabel")
    menuHexStatus.Size = UDim2.new(1, -20, 0, 14)
    menuHexStatus.Position = UDim2.new(0, 10, 0, 88)
    menuHexStatus.BackgroundTransparency = 1
    menuHexStatus.Text = ""
    menuHexStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
    menuHexStatus.TextSize = 9
    menuHexStatus.Font = Enum.Font.GothamBold
    menuHexStatus.TextXAlignment = Enum.TextXAlignment.Left
    menuHexStatus.ZIndex = 13
    menuHexStatus.Parent = settingsScroll
    menuHexApply.MouseButton1Click:Connect(function()
        local col, up = parseHex(menuHexBox.Text)
        if not col then
            menuHexStatus.Text = "❌ mã màu sai (VD: #00E5A0)"
            menuHexStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        applyTheme(col)
        menuHexStatus.Text = "✔ màu menu = #" .. up
        menuHexStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
    end)

    sectionTitle(110, "🌈 MÀU LED RGB", ACCENT2)
    local ledPresets = {
        { name = "rainbow", c = nil },
        { name = "blue", c = Color3.fromRGB(0, 150, 255) },
        { name = "red", c = Color3.fromRGB(255, 40, 60) },
        { name = "yellow", c = Color3.fromRGB(255, 210, 40) },
        { name = "purple", c = Color3.fromRGB(180, 80, 255) },
        { name = "white", c = Color3.fromRGB(240, 240, 255) },
    }
    local rainbowGrad = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(90, 230, 90)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(70, 160, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 80, 220)),
    }
    for i, p in ipairs(ledPresets) do
        makeSwatch(10 + (i - 1) * 40, 132, p.c, (p.c == nil and rainbowGrad or nil), function()
            if p.c == nil then
                ledMode = "rainbow"
            else
                ledMode = "fixed"
                ledFixedColor = p.c
            end
        end)
    end
    local hexLbl = Instance.new("TextLabel")
    hexLbl.Size = UDim2.new(0, 88, 0, 24)
    hexLbl.Position = UDim2.new(0, 10, 0, 166)
    hexLbl.BackgroundTransparency = 1
    hexLbl.Text = "HEX LED:"
    hexLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    hexLbl.TextSize = 10
    hexLbl.Font = Enum.Font.GothamBold
    hexLbl.TextXAlignment = Enum.TextXAlignment.Left
    hexLbl.ZIndex = 13
    hexLbl.Parent = settingsScroll
    local hexBox = Instance.new("TextBox")
    hexBox.Size = UDim2.new(0, 110, 0, 24)
    hexBox.Position = UDim2.new(0, 102, 0, 166)
    hexBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    hexBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    hexBox.PlaceholderText = "#FF00AA"
    hexBox.Text = ""
    hexBox.TextSize = 10
    hexBox.Font = Enum.Font.GothamBold
    hexBox.BorderSizePixel = 0
    hexBox.ZIndex = 13
    hexBox.Parent = settingsScroll
    Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 6)
    local hexApply = Instance.new("TextButton")
    hexApply.Size = UDim2.new(0, 70, 0, 24)
    hexApply.Position = UDim2.new(0, 220, 0, 166)
    hexApply.BackgroundColor3 = Color3.fromRGB(0, 150, 120)
    hexApply.TextColor3 = Color3.fromRGB(255, 255, 255)
    hexApply.Text = "ÁP DỤNG"
    hexApply.TextSize = 10
    hexApply.Font = Enum.Font.GothamBold
    hexApply.ZIndex = 13
    hexApply.Parent = settingsScroll
    Instance.new("UICorner", hexApply).CornerRadius = UDim.new(0, 6)
    local hexStatus = Instance.new("TextLabel")
    hexStatus.Size = UDim2.new(1, -20, 0, 14)
    hexStatus.Position = UDim2.new(0, 10, 0, 194)
    hexStatus.BackgroundTransparency = 1
    hexStatus.Text = ""
    hexStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
    hexStatus.TextSize = 9
    hexStatus.Font = Enum.Font.GothamBold
    hexStatus.TextXAlignment = Enum.TextXAlignment.Left
    hexStatus.ZIndex = 13
    hexStatus.Parent = settingsScroll
    hexApply.MouseButton1Click:Connect(function()
        local col, up = parseHex(hexBox.Text)
        if not col then
            hexStatus.Text = "❌ hex phải đủ 6 ký tự (VD: FF00AA)"
            hexStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        ledMode = "fixed"
        ledFixedColor = col
        hexStatus.Text = "✔ đã đổi LED sang #" .. up
        hexStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
    end)

    local function toggleBtn(y, defaultOn, labelOn, labelOff, colorOn, colorOff, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 28)
        b.Position = UDim2.new(0, 10, 0, y)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.ZIndex = 14
        b.Parent = settingsScroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local on = defaultOn
        local function paint()
            b.Text = (on and labelOn or labelOff)
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
    toggleBtn(216, true, "🛡️ ANTI-AFK: ĐANG BẬT", "🛡️ ANTI-AFK: ĐANG TẮT", Color3.fromRGB(46, 140, 67), Color3.fromRGB(60, 60, 70), function(v)
        antiAfk = v
    end)
    toggleBtn(250, false, "📊 HIỆN FPS / PING: ĐANG BẬT", "📊 HIỆN FPS / PING: ĐANG TẮT", Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70), function(v)
        perfOn = v
        perfFrame.Visible = v
    end)
    toggleBtn(284, false, "🔒 KHÓA VỊ TRÍ FPS/PING: ĐANG KHÓA", "🔒 KHÓA VỊ TRÍ FPS/PING: ĐANG MỞ", Color3.fromRGB(180, 120, 40), Color3.fromRGB(60, 60, 70), function(v)
        perfLocked = v
        perfFrame.Draggable = not v
    end)

    -- TOI UU FPS
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
        pcall(function()
            if idx == nil then
                settings().Rendering.QualityLevel = 0
            else
                settings().Rendering.QualityLevel = math.floor(idx * 2.1)
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
    toggleBtn(318, false, "⚡ TỐI ƯU FPS: ĐANG BẬT", "⚡ TỐI ƯU FPS: ĐANG TẮT", Color3.fromRGB(40, 110, 180), Color3.fromRGB(60, 60, 70), function(v)
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
            sunSet(false)
            setQualityLevel(nil)
        end
    end)

    -- AN TEN / DOI TEN
    toggleBtn(352, false, "👤 ẨN TÊN TRÊN ĐẦU: ĐANG BẬT", "👤 ẨN TÊN TRÊN ĐẦU: ĐANG TẮT", Color3.fromRGB(120, 80, 200), Color3.fromRGB(60, 60, 70), function(v)
        hideNameOn = v
        if v then hideNameTags() else showNameTags() end
    end)
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, 88, 0, 24)
    nameLbl.Position = UDim2.new(0, 10, 0, 386)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = "TÊN TÙY CHỈNH:"
    nameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLbl.TextSize = 10
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 13
    nameLbl.Parent = settingsScroll
    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(0, 110, 0, 24)
    nameBox.Position = UDim2.new(0, 102, 0, 386)
    nameBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameBox.PlaceholderText = "Nhập tên mới"
    nameBox.Text = ""
    nameBox.TextSize = 10
    nameBox.Font = Enum.Font.GothamBold
    nameBox.BorderSizePixel = 0
    nameBox.ZIndex = 13
    nameBox.Parent = settingsScroll
    Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)
    local nameApply = Instance.new("TextButton")
    nameApply.Size = UDim2.new(0, 70, 0, 24)
    nameApply.Position = UDim2.new(0, 220, 0, 386)
    nameApply.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    nameApply.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameApply.Text = "ĐỔI TÊN"
    nameApply.TextSize = 10
    nameApply.Font = Enum.Font.GothamBold
    nameApply.ZIndex = 13
    nameApply.Parent = settingsScroll
    Instance.new("UICorner", nameApply).CornerRadius = UDim.new(0, 6)
    local nameStatus = Instance.new("TextLabel")
    nameStatus.Size = UDim2.new(1, -20, 0, 14)
    nameStatus.Position = UDim2.new(0, 10, 0, 414)
    nameStatus.BackgroundTransparency = 1
    nameStatus.Text = ""
    nameStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
    nameStatus.TextSize = 9
    nameStatus.Font = Enum.Font.GothamBold
    nameStatus.TextXAlignment = Enum.TextXAlignment.Left
    nameStatus.ZIndex = 13
    nameStatus.Parent = settingsScroll
    nameApply.MouseButton1Click:Connect(function()
        local input = nameBox.Text
        if input == "" then
            nameStatus.Text = "❌ nhập tên trước"
            nameStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        customName = input
        applyCustomName()
        nameStatus.Text = "✔ đã đổi tên hiển thị"
        nameStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
    end)

    -- GUIDE (nhung thang, 1500)
    local guideHint = Instance.new("TextLabel")
    guideHint.Size = UDim2.new(0.9, 0, 0, 20)
    guideHint.Position = UDim2.new(0.05, 0, 0, 6)
    guideHint.BackgroundTransparency = 1
    guideHint.Text = "Vui lòng đọc kĩ bảng hướng dẫn để tùy chỉnh thông số tránh lỗi !"
    guideHint.TextColor3 = Color3.fromRGB(255, 215, 0)
    guideHint.TextSize = 10
    guideHint.Font = Enum.Font.GothamBold
    guideHint.TextXAlignment = Enum.TextXAlignment.Left
    guideHint.ZIndex = 12
    guideHint.Parent = guidePage
    local guideScroll = Instance.new("ScrollingFrame")
    guideScroll.Size = UDim2.new(1, -8, 1, -34)
    guideScroll.Position = UDim2.new(0, 4, 0, 30)
    guideScroll.BackgroundTransparency = 1
    guideScroll.BorderSizePixel = 0
    guideScroll.CanvasSize = UDim2.new(0, 0, 0, 1500)
    guideScroll.ScrollBarThickness = 4
    guideScroll.ZIndex = 12
    guideScroll.Parent = guidePage
    local guideText = Instance.new("TextLabel")
    guideText.Size = UDim2.new(1, -10, 0, 1500)
    guideText.BackgroundTransparency = 1
    guideText.Text = guideFullText
    guideText.TextColor3 = Color3.fromRGB(220, 220, 220)
    guideText.TextSize = 11
    guideText.Font = Enum.Font.GothamMedium
    guideText.TextXAlignment = Enum.TextXAlignment.Left
    guideText.TextYAlignment = Enum.TextYAlignment.Top
    guideText.TextWrapped = true
    guideText.ZIndex = 13
    guideText.Parent = guideScroll

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

    -- GUIDE FRAME popup (1400)
    GuideFrame = Instance.new("Frame")
    GuideFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    GuideFrame.BorderSizePixel = 0
    GuideFrame.Active = true
    GuideFrame.Draggable = false
    GuideFrame.Visible = false
    GuideFrame.ClipsDescendants = true
    GuideFrame.ZIndex = 9
    GuideFrame.Parent = ScreenGui
    Instance.new("UICorner", GuideFrame).CornerRadius = UDim.new(0, 14)
    local strokeGuide = Instance.new("UIStroke", GuideFrame)
    strokeGuide.Color = Color3.fromRGB(255, 215, 0)
    strokeGuide.Thickness = 1.8
    strokeGuide.Parent = GuideFrame
    local GuideTitle = Instance.new("TextLabel")
    GuideTitle.Size = UDim2.new(1, 0, 0, 42)
    GuideTitle.BackgroundTransparency = 1
    GuideTitle.Text = "📜 HƯỚNG DẪN SỬ DỤNG - VUI LÒNG ĐỌC KĨ!"
    GuideTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    GuideTitle.TextSize = 12
    GuideTitle.Font = Enum.Font.GothamBold
    GuideTitle.Parent = GuideFrame
    makeHeaderDraggable(GuideTitle, GuideFrame)
    local ScrollGuide = Instance.new("ScrollingFrame")
    ScrollGuide.BackgroundTransparency = 1
    ScrollGuide.BorderSizePixel = 0
    ScrollGuide.ScrollBarThickness = 4
    ScrollGuide.ZIndex = 10
    ScrollGuide.Parent = GuideFrame
    local GuideContent = Instance.new("TextLabel")
    GuideContent.BackgroundTransparency = 1
    GuideContent.Text = guideFullText
    GuideContent.TextColor3 = Color3.fromRGB(220, 220, 220)
    GuideContent.TextSize = 12
    GuideContent.Font = Enum.Font.GothamMedium
    GuideContent.TextXAlignment = Enum.TextXAlignment.Left
    GuideContent.TextYAlignment = Enum.TextYAlignment.Top
    GuideContent.TextWrapped = true
    GuideContent.ZIndex = 10
    GuideContent.Parent = ScrollGuide
    local CloseGuideBtn = Instance.new("TextButton")
    CloseGuideBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    CloseGuideBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
    CloseGuideBtn.Text = "✖ ĐÃ HIỂU - VÀO GIAO DIỆN CHÍNH"
    CloseGuideBtn.TextSize = 12
    CloseGuideBtn.Font = Enum.Font.GothamBold
    CloseGuideBtn.ZIndex = 10
    CloseGuideBtn.Parent = GuideFrame
    Instance.new("UICorner", CloseGuideBtn).CornerRadius = UDim.new(0, 8)
    GuideFrame.Size = UDim2.new(0, 540, 0, 350)
    GuideFrame.Position = UDim2.new(0.5, -270, 0.5, -175)
    ScrollGuide.Size = UDim2.new(0.94, 0, 0, 240)
    ScrollGuide.Position = UDim2.new(0.03, 0, 0, 45)
    ScrollGuide.CanvasSize = UDim2.new(0, 0, 0, 1370)
    GuideContent.Size = UDim2.new(1, -10, 0, 1370)
    CloseGuideBtn.Size = UDim2.new(0.94, 0, 0, 38)
    CloseGuideBtn.Position = UDim2.new(0.03, 0, 0, 298)
    GuideFrame.Visible = true
    CloseGuideBtn.MouseButton1Click:Connect(function()
        GuideFrame.Visible = false
        HubFrame.Visible = true
    end)
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
    local PATTERN = { "CHOICE", "QID" }
    local OF_FLY_SPEED = 55
    local OF_FLY_TIMEOUT = 240
    local OF_FLY_ONLY_DIST = 150
    local CHAIR_POS = Vector3.new(-5903, 4, -229)
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

local function of_ensureSprint(h)
    if of_sprintOn then return end
    of_sprintToggle()
    of_sprintOn = true
end

local function of_endSprint(h)
    if not of_sprintOn then return end
    of_sprintToggle()
    of_sprintOn = false
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
        local hrp = of_root()
        if not h or not hrp then return end
        if not h.Sit and h:GetState() ~= Enum.HumanoidStateType.Seated then return end
        local tries = 0
        while tries < 3 and h.Sit do
            tries += 1
            pcall(function() h.Sit = false end)
            pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
            pcall(function()
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bv.Velocity = Vector3.new(0, 22, 0)
                bv.Parent = hrp
                task.wait(0.22)
                bv.Velocity = Vector3.zero
                bv:Destroy()
            end)
            task.wait(0.4)
        end
        task.wait(0.4)
end
    

local function of_walkTo(target, stopDist, timeout, allowSit, useNoclip)
    stopDist = stopDist or 3
    timeout = timeout or 120
    local deadline = os.clock() + timeout
    local h0 = of_humanoid()
    if h0 then of_ensureSprint(h0) end

    local hrp = of_root()
    if not hrp then return end

    -- Compute path bằng Roblox built-in, tự tránh tường/ghế
    local path = PathfindingService:CreatePath({
        AgentRadius = 3,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
        WaypointSpacing = 4,
    })

    local computeOk = pcall(function()
        path:ComputeAsync(hrp.Position, target)
    end)

    local waypoints = {}
    if computeOk and path.Status == Enum.PathStatus.Success then
        waypoints = path:GetWaypoints()
    else
        -- fallback: đi thẳng nếu không compute được
        waypoints = { { Position = target, Action = Enum.PathWaypointAction.Walk } }
    end

    for i = 2, #waypoints do
        if not farmOffice then break end
        if os.clock() > deadline then break end

        local wp = waypoints[i]
        local isLast = (i == #waypoints)
        local threshold = isLast and stopDist or 3

        if wp.Action == Enum.PathWaypointAction.Jump then
            local h = of_humanoid()
            if h then pcall(function() h.Jump = true end) end
            task.wait(0.2)
        end

        local wpDeadline = os.clock() + 10
        while os.clock() < wpDeadline and farmOffice do
            local h = of_humanoid()
            local hrp2 = of_root()
            if not h or not hrp2 then return end
            if h.Sit or h:GetState() == Enum.HumanoidStateType.Seated then
                if allowSit then break end
                of_standUp()
            end
            local d = (wp.Position - hrp2.Position).Magnitude
            if d <= threshold then break end
            h:MoveTo(wp.Position)
            task.wait(0.1)
        end
    end

    local h = of_humanoid()
    local hrpF = of_root()
    if h and hrpF then
        h:MoveTo(hrpF.Position)
        of_endSprint(h)
    end
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
    local function of_sitAtChair()
        local h = of_humanoid()
        if h and h.Sit then
            of_killBV()
            return true
        end
        local hrp = of_root()
        if hrp and (hrp.Position - CHAIR_POS).Magnitude > OF_FLY_ONLY_DIST then
            setStatus("bay tới văn phòng")
            of_flyTo(CHAIR_POS, 8, OF_FLY_TIMEOUT)
        end
        setStatus("đi bộ vào ghế")
        of_walkTo(CHAIR_POS, 2, 60, true, false)
        h = of_humanoid()
        if h and h.Sit then
            of_killBV()
            return true
        end
        local t0 = os.clock()
        while os.clock() - t0 < 2 and farmOffice do
            h = of_humanoid()
            if h and h.Sit then
                of_killBV()
                return true
            end
            task.wait(0.2)
        end
        if farmOffice then
            h = of_humanoid()
            if h and not h.Sit then
                setStatus("ép ngồi ghế")
                of_forceSit(h)
            end
        end
        h = of_humanoid()
        of_killBV()
        return (h and h.Sit) or false
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
        return workspace:GetPartBoundsInRadius(pos, radius)
    end)
    if not ok or not parts then return nil end
    for _, p in ipairs(parts) do
        if (p:IsA("Seat") or p:IsA("VehicleSeat")) and p.Occupant == nil then
            local d = (p.Position - pos).Magnitude
            table.insert(candidates, { seat = p, dist = d })
        end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    return candidates[1].seat
end

local function of_sitAtNearestChair(fromPos)
    local h = of_humanoid()
    if not h then return false end
    if h.Sit then return true end

    local pos = fromPos or (of_root() and of_root().Position) or CHAIR_POS
    local seat = of_findNearestSeat(pos, 150)
    if not seat then
        setStatus("không tìm ghế — về office cũ")
        return of_sitAtChair()
    end

    setStatus("đi bộ tới ghế")
    of_walkTo(seat.Position, 2, 60, true, false)

    h = of_humanoid()
    if h and h.Sit then return true end

    local t0 = os.clock()
    while os.clock() - t0 < 2 and farmOffice do
        h = of_humanoid()
        if h and h.Sit then return true end
        task.wait(0.2)
    end

    if farmOffice then
        h = of_humanoid()
        if h and not h.Sit then
            pcall(function() seat:Sit(h) end)
            task.wait(0.3)
        end
    end

    h = of_humanoid()
    return (h and h.Sit) or false
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
        setStatus("đi bộ tới máy in")
        of_walkTo(part.Position, 3, 60, false, false)
        setStatus("chuẩn bị in")
        task.wait(0.5)
        setStatus("đang in")
        if of_printAssigned and farmOffice then
            local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function() prompt:InputHoldBegin() end)
                local t1 = os.clock()
                while of_printAssigned and farmOffice and os.clock() - t1 < 4 do
                    task.wait(0.2)
                end
                pcall(function() prompt:InputHoldEnd() end)
            end
        end
            local t2 = os.clock()
    while of_printAssigned and farmOffice and os.clock() - t2 < 6 do
        task.wait(0.2)
    end
    setStatus("đã in")

    task.wait(0.3)
    of_sitAtNearestChair(part.Position)
end
    local function of_runCycle()
        while farmOffice and os.clock() < of_resetUntil do
            setStatus("chờ reset nhân vật")
            task.wait(0.2)
        end
        if not farmOffice then return end
        if not of_sitAtChair() then
            if farmOffice then
                
                task.wait(2)
            end
            return
        end
        setStatus("ngồi ghế, chờ câu hỏi")
        local idleStart = os.clock()
        while farmOffice do
            if of_printAssigned then break end
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
        if activeMode == "office" then
            activeMode = nil
            statPanel.Visible = false
        end
        farmSwitch.set(false)
        setStatus("tạm nghỉ")
    end
    farmSwitch.track.MouseButton1Click:Connect(function()
        if not farmOK then return end
        local want = not farmOffice
        if farmOffice then
            stopOffice()
            return
        end
        farmOffice = true
        activeMode = "office"
        farmStart = os.clock()
        if not of_jobFired then
            TeamChangeRequest:FireServer("Office Worker", 11378976, 0, 0, "Detector")
            of_jobFired = true
            of_resetUntil = os.clock() + 5
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
                     
