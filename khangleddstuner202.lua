-- language: Lua, file: khangfreecam.lua
-- target: Roblox executor (Delta mobile / Synapse / Wave / Solara)
-- branding: Khang Lê DDS · tiktok @khangdayy215
-- package: FREECAM (chỉ freecam + tháo dàn áo)

local API_URL   = "https://spring-poetry-2831.letrongkhang098.workers.dev"
local TOKEN_FILE = "keyauth_token.json"
local HEARTBEAT_INTERVAL = 60

local BRAND_NAME = "Khang Lê DDS"
local BRAND_SUB  = "@khangdayy215"
local LOCAL_PACKAGE = "freecam"

-- ============================================================
-- PAYLOAD
-- ============================================================
local function PAYLOAD()
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local camera = workspace.CurrentCamera

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

local HUB_BG    = Color3.fromRGB(10, 14, 22)
local HUB_SIDE  = Color3.fromRGB(14, 20, 32)
local CARD_BG   = Color3.fromRGB(18, 26, 40)
local themeColor = Color3.fromRGB(0, 229, 160)
local ACCENT2   = Color3.fromRGB(56, 189, 248)
local TXT_DIM   = Color3.fromRGB(150, 165, 185)

local function rainbowAt(t)
    return Color3.fromHSV((t * 0.06) % 1, 1, 1)
end

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

local ControlPanel, freecamMenuFrame, hideFloatBtn
local HubFrame, hubClose, hubHeader, hubStroke
local bodyOpenBtn, fcOpenBtn
local perfOn, perfLocked = false, false
local antiAfk = true
local optFPS = false
-- ANTI-AFK THỰC SỰ
do
    local vu = game:GetService("VirtualUser")
    local lp = game:GetService("Players").LocalPlayer
    

    -- Cách 1: bắt sự kiện Idled — Roblox gọi khi sắp kick
    lp.Idled:Connect(function()
    if not antiAfk then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            vu:Button2Down(Vector2.new(0, 0), cam.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), cam.CFrame)
        end
    end)
end)

    -- Cách 2: gửi key event mỗi 5 phút (chủ động hơn)
    task.spawn(function()
        while true do
            task.wait(300)
            if antiAfk then
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.1)
                    vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
            end
        end
    end)
end

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
local BodyManagerFloatingBtn = makeFloatBtn("🚗", Color3.fromRGB(0, 230, 180), 0.53); BodyManagerFloatingBtn.Visible = false
local FreecamFloatingBtn = makeFloatBtn("📷", Color3.fromRGB(255, 255, 255), 0.66); FreecamFloatingBtn.Visible = false

task.spawn(function()
    local t = 0
    while true do
        task.wait(0.03); t = t + 0.15
        local cMenu, cFloat
        if menuRainbow then cMenu = rainbowAt(t) else cMenu = menuFixedColor end
        if floatRainbow then cFloat = rainbowAt(t) else cFloat = floatFixedColor end
        if hubStroke and hubStroke.Parent then
            hubStroke.Color = cMenu
            if hubHeader then hubHeader.TextColor3 = cMenu end
            if ToggleBtn then ToggleBtn.TextColor3 = cMenu end
        end
        for _, s in ipairs(floatRGB) do
            if s and s.Parent then s.Color = cFloat; s.Transparency = 0 end
        end
    end
end)

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
-- HUB UI
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
    hubHeader.BackgroundTransparency = 1; hubHeader.Text = "👑 KHANGLE FREECAM"
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
    local function addPage(name)
        if pages[name] then return pages[name] end
        local pg = Instance.new("Frame", content)
        pg.Size = UDim2.new(1, 0, 1, 0); pg.BackgroundTransparency = 1
        pg.ClipsDescendants = false; pg.Visible = false; pg.ZIndex = 11
        pages[name] = pg
        return pg
    end
    local function selectPage(name)
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

    addNav("CHUNG", "🧰"); addNav("SETTINGS", "⚙️")

    local chungPage = pages["CHUNG"]
    local settingsPage = pages["SETTINGS"]

    local function applyMenuColor(c)
        menuRainbow = false; menuFixedColor = c
        if hubStroke then hubStroke.Color = c end
        if hubHeader then hubHeader.TextColor3 = c end
        if ToggleBtn then ToggleBtn.TextColor3 = c end
    end
    local function applyMenuRainbow() menuRainbow = true end
    local function applyFloatColor(c)
        floatRainbow = false; floatFixedColor = c
        for _, s in ipairs(floatRGB) do
            if s and s.Parent then s.Color = c; s.Transparency = 0 end
        end
    end
    local function applyFloatRainbow() floatRainbow = true end

    -- CHUNG
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

    -- SETTINGS
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

    local nameSection = makeSection(2, "👤 Tên hiển thị", false)
    makeToggle(nameSection, 1, false, "👤 ẨN TÊN: BẬT", "👤 ẨN TÊN: TẮT",
        Color3.fromRGB(120, 80, 200), Color3.fromRGB(60, 60, 70),
        function(v) hideNameOn = v; if v then hideNameTags() else showNameTags() end end)
    makeInput(nameSection, 2, "Tên mới", "Nhập tên", "ĐỔI TÊN", Color3.fromRGB(120, 80, 200), function(txt, cb)
        if txt == "" then cb("❌ nhập tên trước", false); return end
        customName = txt; applyCustomName(); cb("✔ đã đổi tên", true)
    end)

    local perfSection = makeSection(3, "⚡ Hiệu năng", false)
    makeToggle(perfSection, 1, false, "⚡ TỐI ƯU FPS: BẬT", "⚡ TỐI ƯU FPS: TẮT",
    Color3.fromRGB(40, 110, 180), Color3.fromRGB(60, 60, 70), function(v)
    optFPS = v
    if v then
        pcall(function() Lighting.GlobalShadows = false end)
        pcall(function() Lighting.Brightness = 1 end)
        pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
        pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
        pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 80) end)
        bloomSet(false)
        sunSet(false)
        pcall(function() workspace.StreamingEnabled = true end)
        setQualityLevel(1)
    else
        pcall(function() Lighting.GlobalShadows = true end)
        pcall(function() Lighting.Brightness = 2 end)
        pcall(function() Lighting.EnvironmentDiffuseScale = 1 end)
        pcall(function() Lighting.EnvironmentSpecularScale = 1 end)
        pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120) end)
        bloomSet(true, 0.3, 0.9)
        sunSet(false)
        setQualityLevel(nil)
    end
end)

makeToggle(perfSection, 2, false, "🎨 CHẤT LƯỢNG CAO: BẬT", "🎨 CHẤT LƯỢNG CAO: TẮT",
    Color3.fromRGB(160, 100, 200), Color3.fromRGB(60, 60, 70), function(v)
    if v then
        pcall(function() Lighting.GlobalShadows = true end)
        pcall(function() Lighting.Brightness = 2.5 end)
        pcall(function() Lighting.EnvironmentDiffuseScale = 1 end)
        pcall(function() Lighting.EnvironmentSpecularScale = 1 end)
        pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140) end)
        pcall(function() Lighting.Ambient = Color3.fromRGB(120, 120, 120) end)
        bloomSet(true, 0.5, 0.75)
        sunSet(true, 0.2)
        pcall(function() workspace.StreamingEnabled = false end)
        setQualityLevel(10)
    else
        pcall(function() Lighting.GlobalShadows = true end)
        pcall(function() Lighting.Brightness = 2 end)
        pcall(function() Lighting.EnvironmentDiffuseScale = 1 end)
        pcall(function() Lighting.EnvironmentSpecularScale = 1 end)
        pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120) end)
        bloomSet(true, 0.3, 0.9)
        sunSet(false)
        setQualityLevel(nil)
    end
end)
    makeToggle(perfSection, 3, false, "📊 FPS/PING: BẬT", "📊 FPS/PING: TẮT",
        Color3.fromRGB(0, 150, 120), Color3.fromRGB(60, 60, 70),
        function(v) perfOn = v; perfFrame.Visible = v end)
    makeToggle(perfSection, 4, false, "🔒 KHÓA VỊ TRÍ: BẬT", "🔒 KHÓA VỊ TRÍ: TẮT",
        Color3.fromRGB(180, 120, 40), Color3.fromRGB(60, 60, 70),
        function(v) perfLocked = v; perfFrame.Draggable = not v end)

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
            pcall(queue_on_teleport, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangfreecam.lua"))()]])
        end
    end)
    makeToggle(rejoinSection, 3, readFlag("autoRejoin.txt"), "🔁 AUTO REJOIN: BẬT", "🔁 AUTO REJOIN: TẮT",
        Color3.fromRGB(140, 80, 40), Color3.fromRGB(60, 60, 70), function(v)
        if writefile then pcall(writefile, "autoRejoin.txt", v and "1" or "0") end
    end)

    local afkSection = makeSection(6, "🛡️ Anti-AFK", false)
    makeToggle(afkSection, 1, true, "🛡️ ANTI-AFK: BẬT", "🛡️ ANTI-AFK: TẮT",
        Color3.fromRGB(46, 140, 67), Color3.fromRGB(60, 60, 70), function(v) antiAfk = v end)

    selectPage("CHUNG")
    HubFrame.Visible = false
end

-- ============================================================
-- KHOI: DAN AO
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
-- KHOI: FREECAM
-- ============================================================
do
    local function addStroke(par, col, th)
        local s = Instance.new("UIStroke", par); s.Color = col or Color3.fromRGB(60, 60, 75); s.Thickness = th or 1.5
        return s
    end

    freecamMenuFrame = Instance.new("Frame", ScreenGui)
    freecamMenuFrame.Size = UDim2.new(0, 300, 0, 230); freecamMenuFrame.Position = UDim2.new(0.5, -150, 0.5, -115)
    freecamMenuFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 21); freecamMenuFrame.BackgroundTransparency = 0.12
    freecamMenuFrame.Visible = false; freecamMenuFrame.ZIndex = 15
    Instance.new("UICorner", freecamMenuFrame).CornerRadius = UDim.new(0, 14)
    addStroke(freecamMenuFrame, Color3.fromRGB(70, 70, 95), 1.5)

    local freecamMenuTitle = Instance.new("TextLabel", freecamMenuFrame)
    freecamMenuTitle.Size = UDim2.new(1, 0, 0, 42); freecamMenuTitle.BackgroundTransparency = 1
    freecamMenuTitle.Text = "Freecam Cinematic"; freecamMenuTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
    freecamMenuTitle.TextSize = 15; freecamMenuTitle.Font = Enum.Font.GothamBold; freecamMenuTitle.ZIndex = 16

    local function mkBtn(y, txt, col)
        local b = Instance.new("TextButton", freecamMenuFrame)
        b.Size = UDim2.new(0.9, 0, 0, 32); b.Position = UDim2.new(0.05, 0, 0, y)
        b.BackgroundColor3 = col; b.Text = txt; b.TextColor3 = Color3.fromRGB(235, 235, 245)
        b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.ZIndex = 16
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        addStroke(b, Color3.fromRGB(80, 80, 100), 0.8)
        return b
    end

    local freecamToggleBtn = mkBtn(42, "Freecam: OFF", Color3.fromRGB(45, 45, 58))
    local followBtn = mkBtn(78, "Khóa Tầm: OFF", Color3.fromRGB(50, 50, 68))

    local function makeCompactRow(y, labelText)
        local row = Instance.new("Frame", freecamMenuFrame)
        row.Size = UDim2.new(0.9, 0, 0, 30); row.Position = UDim2.new(0.05, 0, 0, y)
        row.BackgroundTransparency = 1; row.ZIndex = 16
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -80, 1, 0); lbl.Position = UDim2.new(0, 4, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(180, 180, 200); lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 17
        local dec = Instance.new("TextButton", row)
        dec.Size = UDim2.new(0, 34, 0, 26); dec.Position = UDim2.new(1, -76, 0, 2)
        dec.BackgroundColor3 = Color3.fromRGB(50, 50, 68); dec.Text = "−"
        dec.TextColor3 = Color3.fromRGB(235, 235, 245); dec.TextSize = 15; dec.Font = Enum.Font.GothamBold; dec.ZIndex = 17
        Instance.new("UICorner", dec).CornerRadius = UDim.new(0, 6)
        local inc = Instance.new("TextButton", row)
        inc.Size = UDim2.new(0, 34, 0, 26); inc.Position = UDim2.new(1, -38, 0, 2)
        inc.BackgroundColor3 = Color3.fromRGB(50, 50, 68); inc.Text = "+"
        inc.TextColor3 = Color3.fromRGB(235, 235, 245); inc.TextSize = 15; inc.Font = Enum.Font.GothamBold; inc.ZIndex = 17
        Instance.new("UICorner", inc).CornerRadius = UDim.new(0, 6)
        return lbl, dec, inc
    end

    local spdLbl, spdDec, spdInc = makeCompactRow(116, "Tốc độ di chuyển: 25.0")
    local rotLbl, rotDec, rotInc = makeCompactRow(150, "Tốc độ xoay: 1.00x")
    local rollLbl, rollDec, rollInc = makeCompactRow(184, "Tốc độ nghiêng: 1.00x")

    hideFloatBtn = Instance.new("TextButton", ScreenGui)
    hideFloatBtn.Size = UDim2.new(0, 52, 0, 52); hideFloatBtn.Position = UDim2.new(0, 80, 0, 150)
    hideFloatBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28); hideFloatBtn.BackgroundTransparency = 0.2
    hideFloatBtn.Text = "👁️"; hideFloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255); hideFloatBtn.TextSize = 22
    hideFloatBtn.Font = Enum.Font.GothamBold; hideFloatBtn.ZIndex = 10
    Instance.new("UICorner", hideFloatBtn).CornerRadius = UDim.new(0, 7)
    addStroke(hideFloatBtn, Color3.fromRGB(80, 80, 110), 2)
    hideFloatBtn.Visible = false

    local controlFrame = Instance.new("Frame", ScreenGui)
    controlFrame.Size = UDim2.new(0, 245, 0, 160)
    controlFrame.Position = UDim2.new(0, 80, 1, -215)
    controlFrame.BackgroundTransparency = 1; controlFrame.Visible = false; controlFrame.ZIndex = 1
    controlFrame.Active = false

    if readfile and isfile and isfile("freecam_pos.txt") then
        local ok, data = pcall(readfile, "freecam_pos.txt")
        if ok then
            local xs, xo, ys, yo = data:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
            if xs then
                controlFrame.Position = UDim2.new(tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo))
            end
        end
    end

    local dragBar = Instance.new("Frame", controlFrame)
    dragBar.Size = UDim2.new(1, 0, 0, 22); dragBar.Position = UDim2.new(0, 0, 0, -26)
    dragBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40); dragBar.BackgroundTransparency = 0.3
    dragBar.ZIndex = 2
    Instance.new("UICorner", dragBar).CornerRadius = UDim.new(0, 6)
    addStroke(dragBar, Color3.fromRGB(80, 80, 100), 1)
    local dragLbl = Instance.new("TextLabel", dragBar)
    dragLbl.Size = UDim2.new(1, -30, 1, 0); dragLbl.Position = UDim2.new(0, 6, 0, 0)
    dragLbl.BackgroundTransparency = 1; dragLbl.Text = "≡ KÉO"
    dragLbl.TextColor3 = Color3.fromRGB(150, 150, 170); dragLbl.TextSize = 10
    dragLbl.Font = Enum.Font.GothamBold; dragLbl.TextXAlignment = Enum.TextXAlignment.Left; dragLbl.ZIndex = 3

    local eyeBtn = Instance.new("TextButton", dragBar)
    eyeBtn.Size = UDim2.new(0, 20, 0, 20); eyeBtn.Position = UDim2.new(1, -22, 0.5, -10)
    eyeBtn.BackgroundTransparency = 1; eyeBtn.Text = "👁"
    eyeBtn.TextColor3 = Color3.fromRGB(200, 200, 220); eyeBtn.TextSize = 12
    eyeBtn.Font = Enum.Font.GothamBold; eyeBtn.ZIndex = 3

    local dragBarDragging = false
    local dragStartPos, dragFrameStart
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragBarDragging = true; dragStartPos = input.Position; dragFrameStart = controlFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragBarDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - dragStartPos
            controlFrame.Position = UDim2.new(
                dragFrameStart.X.Scale, dragFrameStart.X.Offset + d.X,
                dragFrameStart.Y.Scale, dragFrameStart.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragBarDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragBarDragging = false
            if writefile then
                pcall(writefile, "freecam_pos.txt",
                    tostring(controlFrame.Position.X.Scale) .. "|" ..
                    tostring(controlFrame.Position.X.Offset) .. "|" ..
                    tostring(controlFrame.Position.Y.Scale) .. "|" ..
                    tostring(controlFrame.Position.Y.Offset))
            end
        end
    end)

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
    local btnDown = mkPad("-", UDim2.new(0, 38, 0, 38), UDim2.new(0, 194, 0, 0))
    local btnRollL = mkPad("Q", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 48))
    local btnRollR = mkPad("E", UDim2.new(0, 38, 0, 38), UDim2.new(0, 194, 0, 48))
    local btnZoomIn = mkPad("🔍+", UDim2.new(0, 38, 0, 38), UDim2.new(0, 152, 0, 96))
    local btnZoomOut = mkPad("🔍-", UDim2.new(0, 38, 0, 38), UDim2.new(0, 194, 0, 96))

    local floatEye = Instance.new("TextButton", ScreenGui)
    floatEye.Size = UDim2.new(0, 44, 0, 44)
    floatEye.Position = UDim2.new(0, 20, 0.5, -22)
    floatEye.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    floatEye.BackgroundTransparency = 0.7
    floatEye.Text = "👁"; floatEye.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatEye.TextSize = 20; floatEye.Font = Enum.Font.GothamBold
    floatEye.Visible = false; floatEye.ZIndex = 20; floatEye.Active = false
    Instance.new("UICorner", floatEye).CornerRadius = UDim.new(1, 0)

    do
        local dg, ds, sp
        floatEye.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dg = true; ds = i.Position; sp = floatEye.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                floatEye.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = false end
        end)
    end

    local hiddenMode = false
    local function setRobloxTouchGuiTransparency(t)
        local target = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if target then
            local tg = target:FindFirstChild("TouchGui")
            if tg then
                for _, d in ipairs(tg:GetDescendants()) do
                    if d:IsA("ImageLabel") or d:IsA("ImageButton") then d.ImageTransparency = t
                    elseif d:IsA("TextLabel") or d:IsA("TextButton") then d.TextTransparency = t end
                end
            end
        end
        pcall(function()
            local cg = game:GetService("CoreGui")
            local tg = cg:FindFirstChild("TouchGui")
            if tg then
                for _, d in ipairs(tg:GetDescendants()) do
                    if d:IsA("ImageLabel") or d:IsA("ImageButton") then d.ImageTransparency = t
                    elseif d:IsA("TextLabel") or d:IsA("TextButton") then d.TextTransparency = t end
                end
            end
        end)
    end

    local function toggleHidden()
        hiddenMode = not hiddenMode
        if hiddenMode then
            for _, b in ipairs(controlButtons) do
                b.BackgroundTransparency = 1; b.TextTransparency = 1
                local s = b:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 1 end
            end
            dragBar.BackgroundTransparency = 1
            dragLbl.TextTransparency = 1
            eyeBtn.TextTransparency = 1
            local s = dragBar:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 1 end
            FreecamFloatingBtn.Visible = false
            HubFrame.Visible = false
            ToggleBtn.Visible = false
            freecamMenuFrame.Visible = false
            setRobloxTouchGuiTransparency(1)
            floatEye.Visible = true
        else
            for _, b in ipairs(controlButtons) do
                b.BackgroundTransparency = 0.35; b.TextTransparency = 0
                local s = b:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 0 end
            end
            dragBar.BackgroundTransparency = 0.3
            dragLbl.TextTransparency = 0
            eyeBtn.TextTransparency = 0
            local s = dragBar:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 0 end
            FreecamFloatingBtn.Visible = true
            ToggleBtn.Visible = true
            setRobloxTouchGuiTransparency(0)
            floatEye.Visible = false
        end
    end

    eyeBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleHidden()
        end
    end)

    local floatEyeClickReady = false
    floatEye.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            floatEyeClickReady = true
        end
    end)
    floatEye.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            if floatEyeClickReady then toggleHidden() end
            floatEyeClickReady = false
        end
    end)

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

    local speed = 25.0
    local rotSens = 1.0
    local rollSens = 1.0
    local rollSpeed = 1.8

    local function autoRepeat(btn, step)
        local holding = false
        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                holding = true
                step()
                task.spawn(function()
                    task.wait(0.45)
                    while holding do
                        step()
                        task.wait(0.07)
                    end
                end)
            end
        end)
        btn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                holding = false
            end
        end)
    end

    autoRepeat(spdInc, function()
        local st = speed < 2 and 0.1 or (speed < 10 and 1 or 5)
        speed = math.clamp(speed + st, 0.3, 250)
        spdLbl.Text = string.format("Tốc độ di chuyển: %.1f", speed)
    end)
    autoRepeat(spdDec, function()
        local st = speed <= 2 and 0.1 or (speed <= 10 and 1 or 5)
        speed = math.clamp(speed - st, 0.3, 250)
        spdLbl.Text = string.format("Tốc độ di chuyển: %.1f", speed)
    end)
    autoRepeat(rotInc, function()
        rotSens = math.clamp(rotSens + 0.05, 0.1, 3.0)
        rotLbl.Text = string.format("Tốc độ xoay: %.2fx", rotSens)
    end)
    autoRepeat(rotDec, function()
        rotSens = math.clamp(rotSens - 0.05, 0.1, 3.0)
        rotLbl.Text = string.format("Tốc độ xoay: %.2fx", rotSens)
    end)
    autoRepeat(rollInc, function()
        rollSens = math.clamp(rollSens + 0.05, 0.1, 5.0)
        rollLbl.Text = string.format("Tốc độ nghiêng: %.2fx", rollSens)
    end)
    autoRepeat(rollDec, function()
        rollSens = math.clamp(rollSens - 0.05, 0.1, 5.0)
        rollLbl.Text = string.format("Tốc độ nghiêng: %.2fx", rollSens)
    end)

    local freecamActive = false
    local followMode = false
    local followOffset = Vector3.new(0, 0, 0)
    local camPos = camera.CFrame.Position
    local camAngles = Vector3.new(0, 0, 0)
    local targetCamAngles = Vector3.new(0, 0, 0)
    local currentFOV = camera.FieldOfView
    local moveStates = {W = false, S = false, A = false, D = false, Up = false, Down = false, RollL = false, RollR = false}

    local function bindTouch(btn, key)
        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then moveStates[key] = true end
        end)
        btn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then moveStates[key] = false end
        end)
    end
    bindTouch(btnW, "W"); bindTouch(btnS, "S"); bindTouch(btnA, "A"); bindTouch(btnD, "D")
    bindTouch(btnUp, "Up"); bindTouch(btnDown, "Down")
    bindTouch(btnRollL, "RollL"); bindTouch(btnRollR, "RollR")

    local zIn, zOut = false, false
    btnZoomIn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zIn = true end end)
    btnZoomIn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zIn = false end end)
    btnZoomOut.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zOut = true end end)
    btnZoomOut.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then zOut = false end end)

    local function getPlayerPos()
        local c = LocalPlayer.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        return hrp and hrp.Position or nil
    end

    local function toggleFreecam()
        freecamActive = not freecamActive
        if freecamActive then
            camPos = camera.CFrame.Position
            local rx, ry = camera.CFrame:ToOrientation()
            camAngles = Vector3.new(ry, rx, 0); targetCamAngles = camAngles
            currentFOV = camera.FieldOfView; camera.CameraType = Enum.CameraType.Scriptable
            freecamToggleBtn.Text = "Freecam: ON"; freecamToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 50)
            controlFrame.Visible = true; freecamMenuFrame.Visible = false
        else
            camera.CameraType = Enum.CameraType.Custom; camera.FieldOfView = 70
            freecamToggleBtn.Text = "Freecam: OFF"; freecamToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
            controlFrame.Visible = false
            if followMode then
                followMode = false
                followBtn.Text = "Khóa Tầm: OFF"; followBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
            end
        end
    end
    freecamToggleBtn.MouseButton1Click:Connect(toggleFreecam)

    followBtn.MouseButton1Click:Connect(function()
        if not freecamActive then return end
        followMode = not followMode
        if followMode then
            local pp = getPlayerPos()
            if pp then followOffset = camPos - pp else followOffset = Vector3.new(0, 20, 20) end
            followBtn.Text = "Khóa Tầm: ON"; followBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 50)
        else
            followBtn.Text = "Khóa Tầm: OFF"; followBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
        end
    end)

    local function isInside(pt, f)
        if not f.Visible then return false end
        local ap, as = f.AbsolutePosition, f.AbsoluteSize
        return pt.X >= ap.X and pt.X <= ap.X + as.X and pt.Y >= ap.Y and pt.Y <= ap.Y + as.Y
    end
    local function isInAnyButton(pos)
        for _, b in ipairs(controlButtons) do
            if isInside(pos, b) then return true end
        end
        return false
    end

    local rotateTouch = nil
    local lastRotatePos = nil

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not freecamActive then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        if isInside(pos, freecamMenuFrame) or isInside(pos, FreecamFloatingBtn)
           or isInside(pos, HubFrame) or isInside(pos, ToggleBtn)
           or (hideFloatBtn.Visible and isInside(pos, hideFloatBtn))
           or (floatEye.Visible and isInside(pos, floatEye))
           or isInside(pos, dragBar) then
            return
        end
        if isInAnyButton(pos) then return end
        if gameProcessed then return end
        local vp = workspace.CurrentCamera.ViewportSize
        if pos.X < vp.X * 0.55 and pos.Y > vp.Y * 0.45 then return end
        if rotateTouch then return end
        rotateTouch = input
        lastRotatePos = pos
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not freecamActive then return end
        if input ~= rotateTouch or not lastRotatePos then return end
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local d = pos - lastRotatePos
        targetCamAngles = Vector3.new(
            targetCamAngles.X - d.X * 0.004 * rotSens,
            targetCamAngles.Y - d.Y * 0.004 * rotSens,
            targetCamAngles.Z
        )
        lastRotatePos = pos
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == rotateTouch then
            rotateTouch = nil
            lastRotatePos = nil
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if not freecamActive then return end
        local sf = math.clamp(dt * 16, 0, 1)
        camAngles = camAngles:Lerp(targetCamAngles, sf)
        if zIn then currentFOV = math.clamp(currentFOV - 35 * dt, 10, 120)
        elseif zOut then currentFOV = math.clamp(currentFOV + 35 * dt, 10, 120) end
        camera.FieldOfView = currentFOV

        if moveStates.RollL then targetCamAngles = Vector3.new(targetCamAngles.X, targetCamAngles.Y, targetCamAngles.Z + rollSpeed * rollSens * dt) end
        if moveStates.RollR then targetCamAngles = Vector3.new(targetCamAngles.X, targetCamAngles.Y, targetCamAngles.Z - rollSpeed * rollSens * dt) end

        local mv = Vector3.new()
        if moveStates.W then mv = mv + Vector3.new(0, 0, -1) end
        if moveStates.S then mv = mv + Vector3.new(0, 0, 1) end
        if moveStates.A then mv = mv + Vector3.new(-1, 0, 0) end
        if moveStates.D then mv = mv + Vector3.new(1, 0, 0) end
        if moveStates.Up then mv = mv + Vector3.new(0, 1, 0) end
        if moveStates.Down then mv = mv + Vector3.new(0, -1, 0) end

        local rotCF = CFrame.Angles(0, camAngles.X, 0) * CFrame.Angles(camAngles.Y, 0, 0) * CFrame.Angles(0, 0, camAngles.Z)
        if followMode then
            local pp = getPlayerPos()
            if pp then
                followOffset = followOffset + (rotCF * mv) * speed * dt
                camPos = pp + followOffset
            end
        else
            camPos = camPos + (rotCF * mv) * speed * dt
        end

        camera.CFrame = CFrame.new(camPos) * rotCF
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
addRGBStroke(BodyManagerFloatingBtn)
addRGBStroke(FreecamFloatingBtn)
addRGBStroke(hideFloatBtn)

-- ============================================================
-- AUTO REJOIN
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
                        pcall(queue_on_teleport, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/refs/heads/main/khangfreecam.lua"))()]])
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
    repeat task.wait(1) until game:IsLoaded()
    task.wait(3)
    local pg = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    for _ = 1, 30 do
        if pg then break end
        task.wait(1)
        pg = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    if not pg then return end
    for _ = 1, 30 do
        if pg:FindFirstChild("mainMenuSystem") then break end
        task.wait(1)
    end
    task.wait(3)
    local function findPlayBtn()
        local p = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not p then return nil end
        local menu = p:FindFirstChild("mainMenuSystem")
        local base = menu and menu:FindFirstChild("baseFrame")
        local play = base and base:FindFirstChild("playFrame")
        if play then
            for _, d in ipairs(play:GetDescendants()) do
                if d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 40 then return d end
            end
        end
        for _, d in ipairs(p:GetDescendants()) do
            if d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 40 then
                local u = (d.Text or ""):upper():gsub("%s+", "")
                if u == "CHƠI" or u == "CHOI" or u == "PLAY" then return d end
            end
        end
        return nil
    end
    local btn1 = nil
    for _ = 1, 40 do
        btn1 = findPlayBtn()
        if btn1 then break end
        task.wait(1)
    end
    if btn1 then
        pcall(function() firesignal(btn1.MouseButton1Click) end)
    end
    local playReady = false
    for _ = 1, 40 do
        pcall(function()
            local m = pg:FindFirstChild("mainMenuSystem")
            local b = m and m:FindFirstChild("baseFrame")
            local play = b and b:FindFirstChild("playFrame")
            if play and play.Visible and play.AbsoluteSize.X > 40 then
                playReady = true
            end
        end)
        if playReady then break end
        task.wait(0.5)
    end
    task.wait(2)
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("menuToggleRequest", 5):FireServer()
    end)
    task.wait(10)
    if writefile then pcall(writefile, "lastRejoin.txt", "0") end
end)
end
-- ============================================================

local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local function http_post(path, body, headers)
    headers = headers or {}
    headers["Content-Type"] = "application/json"
    local opts = {
        Url = API_URL .. path, Method = "POST",
        Headers = headers, Body = HttpService:JSONEncode(body),
    }
    local r
    if type(request) == "function" then r = request(opts)
    elseif syn and syn.request then r = syn.request(opts)
    elseif http_request then r = http_request(opts)
    elseif http and http.request then r = http.request(opts)
    else return nil, { detail = "no http" } end
    local ok, parsed = pcall(HttpService.JSONDecode, HttpService, r.Body)
    return r.StatusCode, ok and parsed or r.Body
end

local function get_hwid()
    if type(gethwid) == "function" then
        local ok, v = pcall(gethwid)
        if ok and v and #tostring(v) > 4 then return tostring(v) end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id then return id end
    return tostring(game:GetService("Players").LocalPlayer.UserId)
end

local HWID = get_hwid()

local function save_token(tok)
    if writefile then pcall(writefile, TOKEN_FILE, HttpService:JSONEncode({ token = tok, hwid = HWID })) end
end
local function load_token()
    if readfile and isfile and isfile(TOKEN_FILE) then
        local ok, data = pcall(readfile, TOKEN_FILE)
        if ok then
            local ok2, j = pcall(HttpService.JSONDecode, HttpService, data)
            if ok2 and j.hwid == HWID then return j.token end
        end
    end
    return nil
end

local C = {
    bg_top     = Color3.fromRGB(30, 22, 52),
    bg_bot     = Color3.fromRGB(10, 8, 18),
    card_edge  = Color3.fromRGB(90, 70, 150),
    input_bg   = Color3.fromRGB(10, 8, 18),
    input_edge = Color3.fromRGB(70, 58, 110),
    input_focus= Color3.fromRGB(160, 110, 255),
    accent1    = Color3.fromRGB(139, 92, 246),
    accent2    = Color3.fromRGB(236, 72, 153),
    accent3    = Color3.fromRGB(59, 130, 246),
    ok         = Color3.fromRGB(74, 222, 128),
    err        = Color3.fromRGB(248, 113, 113),
    text       = Color3.fromRGB(244, 242, 255),
    text_dim   = Color3.fromRGB(150, 145, 180),
    text_faint = Color3.fromRGB(90, 85, 125),
}

local player = game:GetService("Players").LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "KeyAuth_" .. tostring(math.random(100000, 999999))
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = pg

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Parent = gui
TweenService:Create(overlay, TweenInfo.new(0.4), { BackgroundTransparency = 0.55 }):Play()

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 320)
frame.Position = UDim2.new(0.5, -200, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(22, 18, 34)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.ZIndex = 2
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 22)

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.bg_top),
    ColorSequenceKeypoint.new(1, C.bg_bot),
})
bgGrad.Rotation = 135
bgGrad.Parent = frame

local gridHolder = Instance.new("Frame")
gridHolder.Size = UDim2.new(1, 0, 1, 0)
gridHolder.BackgroundTransparency = 1
gridHolder.ClipsDescendants = true
gridHolder.ZIndex = 3
gridHolder.Parent = frame

for row = 1, 10 do
    for col = 1, 16 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 2, 0, 2)
        dot.Position = UDim2.new(0, col * 26 - 6, 0, row * 26 - 6)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BackgroundTransparency = 0.94
        dot.BorderSizePixel = 0
        dot.ZIndex = 3
        dot.Parent = gridHolder
        local c = Instance.new("UICorner", dot); c.CornerRadius = UDim.new(1, 0)
    end
end

local stroke = Instance.new("UIStroke", frame)
stroke.Color = C.card_edge
stroke.Thickness = 1.2
stroke.Transparency = 0.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

task.spawn(function()
    while gui.Parent do
        TweenService:Create(stroke, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.15, Color = C.accent1 }):Play()
        task.wait(2.5)
        TweenService:Create(stroke, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.6, Color = C.card_edge }):Play()
        task.wait(2.5)
    end
end)

task.spawn(function()
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 440, 0, 350),
        Position = UDim2.new(0.5, -220, 0.5, -175),
        BackgroundTransparency = 0,
    }):Play()
    task.wait(0.5)
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 440, 0, 340),
        Position = UDim2.new(0.5, -220, 0.5, -170),
    }):Play()
end)

do
    local drag, ds, sp
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

local badge = Instance.new("Frame")
badge.Size = UDim2.new(0, 52, 0, 52)
badge.Position = UDim2.new(0, 24, 0, 22)
badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
badge.BorderSizePixel = 0
badge.ClipsDescendants = true
badge.ZIndex = 4
badge.Parent = frame
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 14)
local badgeGrad = Instance.new("UIGradient")
badgeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent1),
    ColorSequenceKeypoint.new(1, C.accent2),
})
badgeGrad.Rotation = 45
badgeGrad.Parent = badge

local badgeImage = Instance.new("ImageLabel")
badgeImage.Size = UDim2.new(1, -6, 1, -6)
badgeImage.Position = UDim2.new(0.5, 0, 0.5, 0)
badgeImage.AnchorPoint = Vector2.new(0.5, 0.5)
badgeImage.BackgroundTransparency = 1
badgeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
badgeImage.ScaleType = Enum.ScaleType.Fit
badgeImage.ZIndex = 5
badgeImage.Parent = badge

task.spawn(function()
    local ok = pcall(function()
        local logo = game:HttpGet("https://raw.githubusercontent.com/Khangnee28/my-script/main/logo.png")
        writefile("khangle_logo.png", logo)
        badgeImage.Image = getcustomasset("khangle_logo.png")
    end)
    if not ok then
        local fallback = Instance.new("TextLabel")
        fallback.Size = UDim2.new(1, 0, 1, 0)
        fallback.BackgroundTransparency = 1
        fallback.Text = "K"
        fallback.Font = Enum.Font.GothamBlack
        fallback.TextSize = 26
        fallback.TextColor3 = Color3.fromRGB(255, 255, 255)
        fallback.ZIndex = 5
        fallback.Parent = badge
    end
end)

local badgeShine = Instance.new("Frame")
badgeShine.Size = UDim2.new(0, 30, 2, 0)
badgeShine.Position = UDim2.new(0, -40, 0, -10)
badgeShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
badgeShine.BackgroundTransparency = 0.4
badgeShine.BorderSizePixel = 0
badgeShine.Rotation = 20
badgeShine.ZIndex = 5
badgeShine.Parent = badge

task.spawn(function()
    while gui.Parent do
        badgeShine.Position = UDim2.new(0, -40, 0, -10)
        badgeShine.BackgroundTransparency = 1
        task.wait(2.5)
        badgeShine.BackgroundTransparency = 0.4
        TweenService:Create(badgeShine, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 70, 0, -10),
        }):Play()
        task.wait(0.9)
        badgeShine.BackgroundTransparency = 1
        task.wait(0.1)
    end
end)

local brand = Instance.new("TextLabel")
brand.Size = UDim2.new(1, -180, 0, 26)
brand.Position = UDim2.new(0, 88, 0, 26)
brand.BackgroundTransparency = 1
brand.Text = BRAND_NAME
brand.Font = Enum.Font.GothamBold
brand.TextSize = 18
brand.TextColor3 = C.text
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.ZIndex = 4
brand.Parent = frame

local subBrand = Instance.new("TextLabel")
subBrand.Size = UDim2.new(1, -180, 0, 18)
subBrand.Position = UDim2.new(0, 88, 0, 50)
subBrand.BackgroundTransparency = 1
subBrand.Text = "tiktok " .. BRAND_SUB
subBrand.Font = Enum.Font.Gotham
subBrand.TextSize = 12
subBrand.TextColor3 = C.text_dim
subBrand.TextXAlignment = Enum.TextXAlignment.Left
subBrand.ZIndex = 4
subBrand.Parent = frame

task.spawn(function()
    while gui.Parent do
        TweenService:Create(subBrand, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextColor3 = C.accent2 }):Play()
        task.wait(1.5)
        TweenService:Create(subBrand, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextColor3 = C.text_dim }):Play()
        task.wait(1.5)
    end
end)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 32, 0, 32)
close.Position = UDim2.new(1, -44, 0, 22)
close.BackgroundColor3 = Color3.fromRGB(42, 36, 62)
close.BorderSizePixel = 0
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.TextColor3 = C.text_dim
close.AutoButtonColor = false
close.ZIndex = 4
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

close.MouseEnter:Connect(function()
    TweenService:Create(close, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(200, 60, 80), TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)
close.MouseLeave:Connect(function()
    TweenService:Create(close, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(42, 36, 62), TextColor3 = C.text_dim }):Play()
end)

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -48, 0, 1)
divider.Position = UDim2.new(0, 24, 0, 92)
divider.BackgroundColor3 = C.card_edge
divider.BackgroundTransparency = 0.7
divider.BorderSizePixel = 0
divider.ZIndex = 4
divider.Parent = frame

local divGrad = Instance.new("UIGradient")
divGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1),
})
divGrad.Parent = divider

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -48, 0, 18)
label.Position = UDim2.new(0, 24, 0, 106)
label.BackgroundTransparency = 1
label.Text = "LICENSE KEY"
label.Font = Enum.Font.GothamBold
label.TextSize = 10
label.TextColor3 = C.text_faint
label.TextXAlignment = Enum.TextXAlignment.Left
label.ZIndex = 4
label.Parent = frame

local inputWrap = Instance.new("Frame")
inputWrap.Size = UDim2.new(1, -48, 0, 52)
inputWrap.Position = UDim2.new(0, 24, 0, 128)
inputWrap.BackgroundColor3 = C.input_bg
inputWrap.BorderSizePixel = 0
inputWrap.ZIndex = 4
inputWrap.Parent = frame
Instance.new("UICorner", inputWrap).CornerRadius = UDim.new(0, 12)

local inputStroke = Instance.new("UIStroke", inputWrap)
inputStroke.Color = C.input_edge
inputStroke.Thickness = 1.5

local inputGlow = Instance.new("Frame")
inputGlow.Size = UDim2.new(1, 0, 1, 0)
inputGlow.BackgroundColor3 = C.input_focus
inputGlow.BackgroundTransparency = 1
inputGlow.BorderSizePixel = 0
inputGlow.ZIndex = 4
inputGlow.Parent = inputWrap
Instance.new("UICorner", inputGlow).CornerRadius = UDim.new(0, 12)

local lockIcon = Instance.new("TextLabel")
lockIcon.Size = UDim2.new(0, 26, 1, 0)
lockIcon.Position = UDim2.new(0, 14, 0, 0)
lockIcon.BackgroundTransparency = 1
lockIcon.Text = ">"
lockIcon.Font = Enum.Font.GothamBold
lockIcon.TextSize = 16
lockIcon.TextColor3 = C.text_faint
lockIcon.ZIndex = 5
lockIcon.Parent = inputWrap

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -60, 1, 0)
box.Position = UDim2.new(0, 46, 0, 0)
box.BackgroundTransparency = 1
box.Text = ""
box.PlaceholderText = "KEY-XXXX-XXXX-XXXX-XXXX"
box.Font = Enum.Font.Code
box.TextSize = 15
box.TextColor3 = C.text
box.PlaceholderColor3 = C.text_faint
box.ClearTextOnFocus = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.ZIndex = 5
box.Parent = inputWrap

box.Focused:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.25), { Color = C.input_focus, Transparency = 0 }):Play()
    TweenService:Create(inputGlow, TweenInfo.new(0.3), { BackgroundTransparency = 0.92 }):Play()
    TweenService:Create(lockIcon, TweenInfo.new(0.2), { TextColor3 = C.input_focus }):Play()
end)
box.FocusLost:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.25), { Color = C.input_edge, Transparency = 0.2 }):Play()
    TweenService:Create(inputGlow, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(lockIcon, TweenInfo.new(0.2), { TextColor3 = C.text_faint }):Play()
end)

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -48, 0, 48)
btn.Position = UDim2.new(0, 24, 0, 192)
btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btn.BorderSizePixel = 0
btn.Text = "KÍCH HOẠT"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.AutoButtonColor = false
btn.ClipsDescendants = true
btn.ZIndex = 5
btn.Parent = frame
btn.TextStrokeTransparency = 0
btn.TextStrokeColor3 = Color3.fromRGB(15, 5, 45)
btn.TextSize = 17
btn.Font = Enum.Font.GothamBlack
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

local btnGrad = Instance.new("UIGradient")
btnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent1),
    ColorSequenceKeypoint.new(1, C.accent3),
})
btnGrad.Parent = btn

local btnStroke = Instance.new("UIStroke", btn)
btnStroke.Color = Color3.fromRGB(180, 160, 255)
btnStroke.Thickness = 1
btnStroke.Transparency = 0.7

local btnShine = Instance.new("Frame")
btnShine.Size = UDim2.new(0, 50, 1, 0)
btnShine.Position = UDim2.new(0, -80, 0, 0)
btnShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btnShine.BackgroundTransparency = 0.75
btnShine.BorderSizePixel = 0
btnShine.Rotation = 15
btnShine.ZIndex = 6
btnShine.Parent = btn

task.spawn(function()
    while gui.Parent do
        task.wait(3)
        btnShine.Position = UDim2.new(0, -80, 0, 0)
        TweenService:Create(btnShine, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, 40, 0, 0),
        }):Play()
    end
end)

btn.MouseEnter:Connect(function()
    TweenService:Create(btnStroke, TweenInfo.new(0.15), { Transparency = 0.2 }):Play()
end)
btn.MouseLeave:Connect(function()
    TweenService:Create(btnStroke, TweenInfo.new(0.15), { Transparency = 0.7 }):Play()
end)

btn.MouseButton1Down:Connect(function()
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 10, 0, 10)
    ripple.Position = UDim2.new(0.5, -5, 0.5, -5)
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.BorderSizePixel = 0
    ripple.ZIndex = 6
    ripple.Parent = btn
    local c = Instance.new("UICorner", ripple); c.CornerRadius = UDim.new(1, 0)
    TweenService:Create(ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 400),
        Position = UDim2.new(0.5, -200, 0.5, -200),
        BackgroundTransparency = 1,
    }):Play()
    task.delay(0.7, function() ripple:Destroy() end)
end)

local hwidBtn = Instance.new("TextButton")
hwidBtn.Size = UDim2.new(1, -48, 0, 24)
hwidBtn.Position = UDim2.new(0, 24, 0, 250)
hwidBtn.BackgroundTransparency = 1
hwidBtn.Text = ""
hwidBtn.AutoButtonColor = false
hwidBtn.ZIndex = 4
hwidBtn.Parent = frame

local hwidText = Instance.new("TextLabel")
hwidText.Size = UDim2.new(1, -50, 1, 0)
hwidText.BackgroundTransparency = 1
local hwidShort = #HWID > 22 and (HWID:sub(1, 22) .. "...") or HWID
hwidText.Text = "HWID · " .. hwidShort
hwidText.Font = Enum.Font.Code
hwidText.TextSize = 11
hwidText.TextColor3 = C.text_faint
hwidText.TextXAlignment = Enum.TextXAlignment.Left
hwidText.ZIndex = 5
hwidText.Parent = hwidBtn

local copyIcon = Instance.new("TextLabel")
copyIcon.Size = UDim2.new(0, 44, 1, 0)
copyIcon.Position = UDim2.new(1, -44, 0, 0)
copyIcon.BackgroundTransparency = 1
copyIcon.Text = "copy"
copyIcon.Font = Enum.Font.Gotham
copyIcon.TextSize = 11
copyIcon.TextColor3 = C.accent1
copyIcon.TextXAlignment = Enum.TextXAlignment.Right
copyIcon.ZIndex = 5
copyIcon.Parent = hwidBtn

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -48, 0, 32)
status.Position = UDim2.new(0, 24, 0, 282)
status.BackgroundTransparency = 1
status.Text = ""
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = C.text_dim
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextWrapped = true
status.ZIndex = 4
status.Parent = frame

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -48, 0, 14)
footer.Position = UDim2.new(0, 24, 1, -20)
footer.BackgroundTransparency = 1
footer.Text = "powered by " .. BRAND_NAME .. " · " .. BRAND_SUB
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextColor3 = C.text_faint
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.ZIndex = 4
footer.Parent = frame

local function burst(centerX, centerY, color)
    for i = 1, 14 do
        local p = Instance.new("Frame")
        p.Size = UDim2.new(0, 6, 0, 6)
        p.Position = UDim2.new(0, centerX, 0, centerY)
        p.BackgroundColor3 = color
        p.BackgroundTransparency = 0
        p.BorderSizePixel = 0
        p.ZIndex = 7
        p.Parent = frame
        local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(1, 0)
        local angle = (i / 14) * math.pi * 2
        local dist = 80 + math.random(20, 60)
        local dx = math.cos(angle) * dist
        local dy = math.sin(angle) * dist
        TweenService:Create(p, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, centerX + dx, 0, centerY + dy),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 2, 0, 2),
        }):Play()
        task.delay(0.8, function() p:Destroy() end)
    end
end

hwidBtn.MouseButton1Click:Connect(function()
    if setclipboard then pcall(setclipboard, HWID) end
    copyIcon.Text = "copied"
    TweenService:Create(copyIcon, TweenInfo.new(0.15), { TextColor3 = C.ok }):Play()
    task.wait(1.2)
    copyIcon.Text = "copy"
    TweenService:Create(copyIcon, TweenInfo.new(0.15), { TextColor3 = C.accent1 }):Play()
end)

close.MouseButton1Click:Connect(function()
    TweenService:Create(frame, TweenInfo.new(0.2), { Size = UDim2.new(0, 400, 0, 320), BackgroundTransparency = 1 }):Play()
    TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
    task.wait(0.2)
    gui:Destroy()
end)

local running = false
local token = nil

local function set_status(text, color)
    status.Text = text
    TweenService:Create(status, TweenInfo.new(0.15), { TextColor3 = color or C.text_dim }):Play()
end

local function set_btn(text, colorSeq)
    btn.Text = text
    if colorSeq then btnGrad.Color = colorSeq end
end

local function launch()
    if running then return end
    running = true
    TweenService:Create(frame, TweenInfo.new(0.25), { Size = UDim2.new(0, 400, 0, 320), BackgroundTransparency = 1 }):Play()
    TweenService:Create(overlay, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
    task.wait(0.25)
    gui:Destroy()
    task.spawn(function()
        local ok, err = pcall(PAYLOAD)
        if not ok then warn("[keyauth] payload error:", err) end
    end)
end

local function start_heartbeat()
    task.spawn(function()
        local firstSend = true
        while token and not running do
            if not firstSend then task.wait(HEARTBEAT_INTERVAL) end
            firstSend = false
            if not token or running then break end
            local code = http_post("/heartbeat", {}, {
                ["Authorization"] = "Bearer " .. token,
                ["X-HWID"] = HWID,
                ["X-Player-Name"] = player.Name,
            })
            if code ~= 200 then token = nil; break end
        end
    end)
end

local GRAD_OK   = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.ok), ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 197, 94)) })
local GRAD_LOAD = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 100, 220)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 70, 180)) })
local GRAD_IDLE = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.accent1), ColorSequenceKeypoint.new(1, C.accent3) })

local function do_auth(key)
    local code, body = http_post("/auth", {
    key = key,
    hwid = HWID,
    name = player.Name,
    package = LOCAL_PACKAGE,
})
    if not code then
        set_status("Khong ket noi duoc server", C.err)
        set_btn("KÍCH HOẠT", GRAD_IDLE)
        return
    end
    if code == 200 and type(body) == "table" and body.token then
        token = body.token
        save_token(token)
        burst(220, 216, C.ok)
        set_status("License hợp lệ", C.ok)
        set_btn("ĐÃ KÍCH HOẠT", GRAD_OK)
        start_heartbeat()
        task.wait(0.9)
        launch()
    else
        local msg = "Key không hợp lệ"
        if type(body) == "table" and body.detail then
            local d = body.detail
            if d == "invalid key" then msg = "Key không tồn tại"
            elseif d == "key expired" then msg = "Key đã hết hạn"
            elseif d == "key revoked" then msg = "Key đã bị thu hồi"
            elseif d == "hwid mismatch" then msg = "Key đã kích hoạt cho thiết bị khác"
            else msg = d end
elseif d:find("key chỉ dùng cho") then msg = d
        end
        set_status(msg, C.err)
        set_btn("KÍCH HOẠT", GRAD_IDLE)
        TweenService:Create(stroke, TweenInfo.new(0.1), { Color = C.err, Transparency = 0 }):Play()
        task.wait(0.15)
        TweenService:Create(stroke, TweenInfo.new(0.4), { Color = C.card_edge, Transparency = 0.5 }):Play()
        local orig = frame.Position
        for i = 1, 3 do
            TweenService:Create(frame, TweenInfo.new(0.05), { Position = orig + UDim2.new(0, 10, 0, 0) }):Play()
            task.wait(0.05)
            TweenService:Create(frame, TweenInfo.new(0.05), { Position = orig - UDim2.new(0, 10, 0, 0) }):Play()
            task.wait(0.05)
        end
        TweenService:Create(frame, TweenInfo.new(0.08), { Position = orig }):Play()
    end
end

btn.MouseButton1Click:Connect(function()
    if running then return end
    local key = box.Text:gsub("%s+", ""):upper()
    if #key < 10 then
        set_status("Key quá ngắn", C.err)
        return
    end
    set_btn("ĐANG KIỂM TRA...", GRAD_LOAD)
    set_status("Đang xác thực...", C.text_dim)
    task.spawn(do_auth, key)
end)

box.FocusLost:Connect(function(enter)
    if enter then btn:Activate() end
end)

task.spawn(function()
    local saved = load_token()
    if not saved then return end
    set_btn("DANG TỰ ĐỘNG ĐĂNG NHẬP...", GRAD_LOAD)
    set_status("Dang kiem tra phien cu...", C.text_dim)
    local code = http_post("/heartbeat", {}, {
        ["Authorization"] = "Bearer " .. saved,
        ["X-HWID"] = HWID,
    })
    if code == 200 then
        token = saved
        set_status("Auto-login thành công", C.ok)
        set_btn("ĐÃ KÍCH HOẠT", GRAD_OK)
        start_heartbeat()
        task.wait(0.6)
        launch()
    else
        set_btn("KÍCH HOẠT", GRAD_IDLE)
        set_status("", C.text_dim)
    end
end)
