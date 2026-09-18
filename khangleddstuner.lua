-- ============================================================
-- DDS FARM HUB v52 — gucci4080 build
-- v52: tu nhan map — map KHONG co office thi TAT nut OFFICE
--        + dong bao duoi nut: "Chi hoat dong o Surakarta"
--        Surakarta => moi thu binh thuong; LED/status giu nguyen
-- QUY TAC VANG: khong in ten ham executor ra console
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
local TeamChangeRequest = JobEvents:WaitForChild("TeamChangeRequest", 5)
local GenerateQuestion = JobEvents:WaitForChild("GenerateQuestion")
local CorrectAnswer   = JobEvents:WaitForChild("CorrectAnswer")
local AssignPrintJob  = JobEvents:WaitForChild("AssignPrintJob")
local ClearPrintJob   = JobEvents:WaitForChild("ClearPrintJob")
-- v52: khong dung WaitForChild (se treo o map khong co Computers)
local Computers = workspace:FindFirstChild("Computers")

-- ============ TRANG THAI CHUNG ============
local activeMode = nil
local farmOffice = false
local farmStart = 0
local antiAfk = true
local ofAnswers = 0
local ofPrints = 0
pcall(function()
    player.Kicked:Connect(function(reason)
        warn("[farm] KICK MSG: " .. tostring(reason))
    end)
end)

-- ============ ANTI-AFK ============
task.spawn(function()
    while true do
        if antiAfk then
            pcall(function()
                VirtualInputManager:SendMouseMoveEvent(math.random(-3, 3), math.random(-3, 3))
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local seated = (hum and hum.Sit) or false
                if not seated then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                end
            end)
        end
        task.wait(45 + math.random(5, 15))
    end
end)

-- ============ GUI CHUNG ============
local gui = Instance.new("ScreenGui")
gui.Name = "DDSFarmHub4080"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end
local crownBtn = Instance.new("TextButton")
crownBtn.Size = UDim2.new(0, 48, 0, 48)
crownBtn.Position = UDim2.new(0, 16, 0.5, -24)
crownBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crownBtn.Text = "👑"
crownBtn.TextSize = 22
crownBtn.Font = Enum.Font.GothamBold
crownBtn.Active = true
crownBtn.Draggable = true
crownBtn.Parent = gui
Instance.new("UICorner", crownBtn).CornerRadius = UDim.new(1, 0)
local crownGrad = Instance.new("UIGradient")
crownGrad.Color = ColorSequence.new(
    Color3.fromRGB(255, 225, 110),
    Color3.fromRGB(215, 140, 20)
)
crownGrad.Rotation = 45
crownGrad.Parent = crownBtn
local crownStroke = Instance.new("UIStroke")
crownStroke.Color = Color3.fromRGB(120, 75, 5)
crownStroke.Thickness = 2
crownStroke.Parent = crownBtn
local mainMenu = Instance.new("Frame")
mainMenu.Size = UDim2.new(0, 280, 0, 122)
mainMenu.Position = UDim2.new(0, 76, 0.5, -61)
mainMenu.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
mainMenu.BackgroundTransparency = 0.04
mainMenu.BorderSizePixel = 0
mainMenu.Active = true
mainMenu.Draggable = true
mainMenu.Visible = false
mainMenu.Parent = gui
Instance.new("UICorner", mainMenu).CornerRadius = UDim.new(0, 12)
local mmStroke = Instance.new("UIStroke")
mmStroke.Color = Color3.fromRGB(255, 200, 80)
mmStroke.Thickness = 1.5
mmStroke.Transparency = 0.3
mmStroke.Parent = mainMenu
local mmTitle = Instance.new("TextLabel")
mmTitle.Size = UDim2.new(1, -46, 0, 34)
mmTitle.Position = UDim2.new(0, 12, 0, 8)
mmTitle.BackgroundTransparency = 1
mmTitle.Text = "👑 DDS FARM HUB — 4080"
mmTitle.TextColor3 = Color3.fromRGB(255, 200, 80)
mmTitle.Font = Enum.Font.Code
mmTitle.TextSize = 17
mmTitle.TextXAlignment = Enum.TextXAlignment.Left
mmTitle.Parent = mainMenu
local mmHide = Instance.new("TextButton")
mmHide.Size = UDim2.new(0, 30, 0, 30)
mmHide.Position = UDim2.new(1, -38, 0, 10)
mmHide.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
mmHide.Text = "—"
mmHide.Font = Enum.Font.Code
mmHide.TextSize = 16
mmHide.TextColor3 = Color3.fromRGB(230, 230, 230)
mmHide.Parent = mainMenu
Instance.new("UICorner", mmHide).CornerRadius = UDim.new(0, 8)
local OFFICE_C  = Color3.fromRGB(45, 100, 160)
local ON_C      = Color3.fromRGB(46, 140, 67)
local OFF_DIS   = Color3.fromRGB(70, 70, 80)
local function mainBtn(y, baseColor)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -24, 0, 46)
    b.Position = UDim2.new(0, 12, 0, y)
    b.BackgroundColor3 = baseColor
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.Code
    b.TextSize = 17
    b.Parent = mainMenu
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.72, 0.72, 0.72))
    g.Rotation = 90
    g.Parent = b
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.75
    s.Thickness = 1
    s.Parent = b
    return b
end
local btnOffice = mainBtn(50, OFFICE_C)
btnOffice.Text = "AUTO FARM OFFICE: OFF"
-- v52: dong thong bao duoi nut OFFICE
local lblFarmNote = Instance.new("TextLabel")
lblFarmNote.Size = UDim2.new(1, -24, 0, 16)
lblFarmNote.Position = UDim2.new(0, 12, 0, 98)
lblFarmNote.BackgroundTransparency = 1
lblFarmNote.Text = ""
lblFarmNote.TextSize = 10
lblFarmNote.Font = Enum.Font.Code
lblFarmNote.TextXAlignment = Enum.TextXAlignment.Left
lblFarmNote.Parent = mainMenu

-- ============ BANG STATUS + VIEN LED ============
local statPanel = Instance.new("Frame")
statPanel.Size = UDim2.new(0, 250, 0, 134)
statPanel.Position = UDim2.new(0, 76, 0.5, 62)
statPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
statPanel.BackgroundTransparency = 0.45
statPanel.BorderSizePixel = 0
statPanel.Active = true
statPanel.Draggable = true
statPanel.Visible = false
statPanel.Parent = gui
Instance.new("UICorner", statPanel).CornerRadius = UDim.new(0, 6)
local RAINBOW = {
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(255, 160, 40),
    Color3.fromRGB(255, 230, 60),
    Color3.fromRGB(90, 230, 90),
    Color3.fromRGB(70, 160, 255),
    Color3.fromRGB(125, 90, 220),
    Color3.fromRGB(225, 80, 220),
}
local LED_N1 = 14
local LED_N2 = 7
local LED_T = 3
local ledSegs = {}
local function addSeg(pos, size)
    local f = Instance.new("Frame")
    f.Position = pos
    f.Size = size
    f.BorderSizePixel = 0
    f.ZIndex = 5
    f.Parent = statPanel
    table.insert(ledSegs, f)
    return f
end
local function wSize(i)
    if i == LED_N1 - 1 then
        return UDim2.new(1 / LED_N1, 0, 0, LED_T)
    end
    return UDim2.new(1 / LED_N1, 1, 0, LED_T)
end
local function hSize(i)
    if i == LED_N2 - 1 then
        return UDim2.new(0, LED_T, 1 / LED_N2, 0)
    end
    return UDim2.new(0, LED_T, 1 / LED_N2, 1)
end
for i = 0, LED_N1 - 1 do
    addSeg(UDim2.new(i / LED_N1, 0, 0, 0), wSize(i))
end
for i = 0, LED_N2 - 1 do
    addSeg(UDim2.new(1, -LED_T, i / LED_N2, 0), hSize(i))
end
for i = LED_N1 - 1, 0, -1 do
    addSeg(UDim2.new(i / LED_N1, 0, 1, -LED_T), wSize(i))
end
for i = LED_N2 - 1, 0, -1 do
    addSeg(UDim2.new(0, 0, i / LED_N2, 0), hSize(i))
end
task.spawn(function()
    local t = 0
    local n = #ledSegs
    while true do
        t = t + 0.08
        for i, seg in ipairs(ledSegs) do
            local pos = (t + (i - 1) * 7 / n) % 7
            local idx = math.floor(pos) + 1
            local f = pos - (idx - 1)
            local a = RAINBOW[idx]
            local b = RAINBOW[(idx % 7) + 1]
            seg.BackgroundColor3 = a:Lerp(b, f)
        end
        task.wait(0.03)
    end
end)
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
    l.ZIndex = 6
    l.Parent = statPanel
    return l
end
local lblMode  = statLabel("—", 10, 17, Color3.fromRGB(255, 200, 80))
local lblStat1 = statLabel("", 36, 15, Color3.fromRGB(140, 255, 140))
local lblStat2 = statLabel("", 57, 15, Color3.fromRGB(140, 220, 255))
local lblTime  = statLabel("thời gian farm: 00:00", 78, 14, Color3.fromRGB(255, 220, 140))
local lblWork  = statLabel("status: tạm nghỉ", 102, 13, Color3.fromRGB(200, 200, 200))
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
task.spawn(function()
    while true do
        task.wait(1)
        if activeMode and farmStart > 0 then
            lblTime.Text = "thời gian farm: " .. fmtTime(os.clock() - farmStart)
        end
    end
end)
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
crownBtn.MouseButton1Click:Connect(function()
    mainMenu.Visible = not mainMenu.Visible
end)
mmHide.MouseButton1Click:Connect(function()
    mainMenu.Visible = false
end)
UserInputService.InputBegan:Connect(function(inp, proc)
    if proc then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        mainMenu.Visible = not mainMenu.Visible
    end
end)

-- ============================================================
-- OFFICE FARM v20 (giu nguyen logic)
-- ============================================================
local PATTERN = { "CHOICE", "QID" }
local OF_FLY_SPEED = 55
local OF_FLY_TIMEOUT = 240
local OF_FLY_ONLY_DIST = 150
local CHAIR_POS = Vector3.new(-5903, 4, -229)
local UUID_PAT = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

-- ============ v52: NHAN DIEN MAP CO FARM HAY KHONG ============
local function countOfficeSeats()
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(CHAIR_POS, 10)
    end)
    if not ok or not parts then return 0 end
    local n = 0
    for _, p in ipairs(parts) do
        if p:IsA("Seat") or p:IsA("VehicleSeat") then
            n = n + 1
        end
    end
    return n
end
local farmOK = (workspace:FindFirstChild("Computers") ~= nil) and (countOfficeSeats() > 0)
if farmOK then
    lblFarmNote.Text = "✔ Surakarta — office farm sẵn sàng"
    lblFarmNote.TextColor3 = Color3.fromRGB(140, 255, 140)
else
    lblFarmNote.Text = "⚠ Chỉ hoạt động ở Surakarta"
    lblFarmNote.TextColor3 = Color3.fromRGB(255, 120, 80)
    btnOffice.Text = "AUTO FARM OFFICE: OFF"
    btnOffice.BackgroundColor3 = OFF_DIS
    btnOffice.Active = false
end

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
local of_baseSpeed = 16
local of_boosted = false
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
local function of_grabBaseSpeed()
    local char = player.Character
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if h and h.WalkSpeed > 0 then
        of_baseSpeed = h.WalkSpeed
    end
end
of_grabBaseSpeed()
player.CharacterAdded:Connect(function()
    of_resetUntil = os.clock() + 2.5
    table.clear(of_savedCollide)
    task.wait(1)
    of_grabBaseSpeed()
end)
local of_shiftMode = nil
if type(keydown) == "function" then
    of_shiftMode = "hold"
elseif type(keypress) == "function" then
    of_shiftMode = "tap"
end
local function of_setSpeed(h, v)
    pcall(function() h.WalkSpeed = v end)
end
local function of_ensureSprint(h)
    of_boosted = false
    if of_shiftMode == "hold" then
        pcall(function() keydown(Enum.KeyCode.LeftShift) end)
        task.wait(0.15)
        if h.WalkSpeed > of_baseSpeed + 1 then return end
    elseif of_shiftMode == "tap" then
        if h.WalkSpeed <= of_baseSpeed + 1 then
            pcall(function() keypress(Enum.KeyCode.LeftShift) end)
            task.wait(0.2)
        end
        if h.WalkSpeed > of_baseSpeed + 1 then return end
    end
    of_setSpeed(h, of_baseSpeed * 2.3)
    of_boosted = true
end
local function of_endSprint(h)
    if of_shiftMode == "hold" then
        pcall(function() keyup(Enum.KeyCode.LeftShift) end)
    end
    if of_boosted then
        of_setSpeed(h, of_baseSpeed)
        of_boosted = false
    end
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
    timeout = timeout or OF_FLY_TIMEOUT
    local deadline = os.clock() + timeout
    of_phasing = true
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    of_activeBV = bv
    local hrp = of_root()
    if hrp then bv.Parent = hrp end
    local ok = pcall(function()
        local prevPos = hrp and hrp.Position
        local prevTime = os.clock()
        local stuck = 0
        while os.clock() < deadline and farmOffice do
            hrp = of_root()
            if not hrp then break end
            if bv.Parent ~= hrp then bv.Parent = hrp end
            local delta = target - hrp.Position
            if delta.Magnitude <= stopDist then break end
            local dir = Vector3.new(delta.X, math.clamp(delta.Y, -8, 8), delta.Z)
            if dir.Magnitude > 0.01 then
                bv.Velocity = dir.Unit * OF_FLY_SPEED
            end
            if os.clock() - prevTime >= 0.5 then
                if prevPos and (hrp.Position - prevPos).Magnitude < 1 then
                    stuck += 1
                else
                    stuck = 0
                end
                prevPos = hrp.Position
                prevTime = os.clock()
                if stuck >= 6 then break end
            end
            task.wait(0.1)
        end
    end)
    if not ok then
        warn("[farm] fly loi, ha canh di bo")
    end
    of_killBV()
    task.wait(0.3)
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
    local deadline = os.clock() + (timeout or 120)
    local h0 = of_humanoid()
    if h0 then of_ensureSprint(h0) end
    if useNoclip then
        of_phasing = true
    end
    local holdBV = nil
    local prevPos = of_root() and of_root().Position
    local prevTime = os.clock()
    local stuckTime = 0
    local slip = 0
    local pulses = 0
    local ok = pcall(function()
        while os.clock() < deadline and farmOffice do
            local h = of_humanoid()
            local hrp = of_root()
            if not h or not hrp then break end
            if h.Sit or h:GetState() == Enum.HumanoidStateType.Seated then
                if allowSit then
                    break
                else
                    of_standUp()
                end
            end
            local delta = target - hrp.Position
            local flat = Vector3.new(delta.X, 0, delta.Z)
            if flat.Magnitude <= stopDist then break end
            h:MoveTo(Vector3.new(target.X, hrp.Position.Y, target.Z))
            if hrp.Position.Y < target.Y - 120 then
                warn("[farm] rot void — tu respawn de tiep tuc")
                pcall(function() h.Health = 0 end)
                break
            end
            if not useNoclip and os.clock() - prevTime >= 0.6 then
                local moved = prevPos and (hrp.Position - prevPos).Magnitude or 99
                if moved < 0.4 then
                    stuckTime = stuckTime + 0.6
                else
                    stuckTime = 0
                end
                prevPos = hrp.Position
                prevTime = os.clock()
                if stuckTime >= 0.8 and slip <= 0 and pulses < 8 then
                    slip = 0.5
                    pulses += 1
                    stuckTime = 0
                end
            end
            if slip > 0 then
                of_phasing = true
                if not holdBV then
                    holdBV = Instance.new("BodyVelocity")
                    holdBV.MaxForce = Vector3.new(0, 1e5, 0)
                    holdBV.Velocity = Vector3.zero
                    holdBV.Parent = hrp
                elseif holdBV.Parent ~= hrp then
                    holdBV.Parent = hrp
                end
                slip = slip - 0.1
                if slip <= 0 then
                    if not useNoclip then of_phasing = false end
                    if holdBV then
                        pcall(function() holdBV:Destroy() end)
                        holdBV = nil
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    if holdBV then
        pcall(function() holdBV:Destroy() end)
    end
    of_phasing = false
    local h = of_humanoid()
    local hrp = of_root()
    if h and hrp then
        h:MoveTo(hrp.Position)
        of_endSprint(h)
    end
    if not ok then
        warn("[farm] walk loi")
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
    if not how then
        pcall(function()
            CorrectAnswer:FireServer(unpack(of_buildArgs(q, choice)))
        end)
    end
    of_awaitingAck = true
    of_lastFireAt = os.clock()
    return true
end
local function of_doPrint(name)
    local model = Computers and Computers:FindFirstChild(name)
    if not model then
        warn("[farm] khong thay may in: " .. tostring(name))
        return
    end
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end
    of_standUp()
    setStatus("đi bộ tới máy in")
    of_walkTo(part.Position, 3, 60, false, true)
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
end
local function of_runCycle()
    while farmOffice and os.clock() < of_resetUntil do
        setStatus("chờ reset nhân vật")
        task.wait(0.2)
    end
    if not farmOffice then return end
    if not of_sitAtChair() then
        if farmOffice then
            warn("[farm] khong ngoi duoc ghe, thu lai")
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
-- ============ DIEU KHIEN ============
local function stopOffice()
    farmOffice = false
    of_killBV()
    if activeMode == "office" then
        activeMode = nil
        statPanel.Visible = false
    end
    btnOffice.Text = "AUTO FARM OFFICE: OFF"
    btnOffice.BackgroundColor3 = farmOK and OFFICE_C or OFF_DIS
    setStatus("tạm nghỉ")
end
btnOffice.MouseButton1Click:Connect(function()
    if not farmOK then return end
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
    btnOffice.Text = "AUTO FARM OFFICE: ON"
    btnOffice.BackgroundColor3 = ON_C
    statPanel.Visible = true
    refreshStatPanel()
    setStatus("khởi động office")
end)
setStatus("tạm nghỉ")
print("[hub v52] san sang — bam vuong miện de mo menu (office only, tu nhan map)")
