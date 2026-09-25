-- language: Luau, executor: Delta
-- RideGo Farm v4
-- Init (đổi job + online + spawn xe) chỉ 1 lần khi bật farm.
-- Loop: đợi đơn → accept → đón khách → trả khách.
-- Bảng quét xe player có để chọn xe spawn.

local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ============ CONFIG ============
local FLY_SPEED     = 130
local FLY_TIMEOUT   = 40
local VOID_DY       = 40
local ARRIVE_DIST   = 10
local ORDER_TIMEOUT = 30
local PICKUP_WAIT   = 4
local DROP_WAIT     = 6

-- ============ STATE ============
local enabled     = false
local initialized = false
local orderToken  = nil
local pickupPos   = nil
local dropPos     = nil
local myCar       = nil
local selectedCar = ""
local carList     = {}
local stats = { trips = 0, earn = 0 }
local curState = "OFF"

-- ============ REMOTES ============
local JobEvents = rs:WaitForChild("JobEvents", 10)
local TeamChangeRequest = JobEvents and JobEvents:WaitForChild("TeamChangeRequest", 5)

local TaxiAssets = rs:WaitForChild("TaxiAssets", 10)
local TaxiEvent
if TaxiAssets then
    local ev = TaxiAssets:WaitForChild("Events", 5)
    if ev then TaxiEvent = ev:WaitForChild("TaxiEvent", 5) end
end

local SpawnCarEvents = rs:WaitForChild("SpawnCarEvents", 10)
local SpawnCarEv
if SpawnCarEvents then
    SpawnCarEv = SpawnCarEvents:WaitForChild("SpawnCar", 5)
end

local DealershipEvents = rs:FindFirstChild("DealershipEvents")
local GetInfoCarSlot
local InitCarData
if DealershipEvents then
    GetInfoCarSlot = DealershipEvents:FindFirstChild("GetInfoCarSlot")
    InitCarData = DealershipEvents:FindFirstChild("InitializeCarData")
end

-- ============ HOOK TAXI ============
if TaxiEvent then
    TaxiEvent.OnClientEvent:Connect(function(action, data)
        if type(data) ~= "table" then return end
        if action == "OrderOffer" then
            orderToken = data.Token
        elseif action == "OrderAccepted" then
            pickupPos = data.PickupPos
            dropPos   = data.DropPos
            orderToken = data.Token
            if type(data.Fare) == "number" then
                stats.earn = stats.earn + data.Fare
            end
            stats.trips = stats.trips + 1
        end
    end)
end

-- ============ HELPERS ============
local function char() return lp.Character end
local function root() local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end

local function fire(remote, ...)
    if not remote then return false end
    local args = {...}
    local ok = pcall(function() remote:FireServer(table.unpack(args)) end)
    return ok
end

local function setState(s) curState = s end

local function scanCars()
    carList = {}
    if not InitCarData then return carList end

    local ok, data = pcall(function() return InitCarData:InvokeServer() end)
    if not ok or type(data) ~= "table" then return carList end

    for _, v in pairs(data) do
        if type(v) == "table" then
            -- Name = tên model, dùng để spawn
            if type(v.Name) == "string" and v.Name ~= "" then
                table.insert(carList, v.Name)
            end
        end
    end

    -- unique + sort
    local seen, uniq = {}, {}
    for _, n in ipairs(carList) do
        if not seen[n] then
            seen[n] = true
            table.insert(uniq, n)
        end
    end
    table.sort(uniq)
    carList = uniq
    return carList
end

local function findMyCar()
    local c = char()
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and h.SeatPart then
        return h.SeatPart:FindFirstAncestorOfClass("Model")
    end
    return nil
end
local function findCarByName(name)
    if not name or name == "" then return nil end
    for _, d in ipairs(workspace:GetChildren()) do
        if d:IsA("Model") and d.Name == name then
            return d
        end
    end
    return nil
end

-- fly bằng BodyVelocity, chỉ CFrame khi rơi void
local function flyTo(target, timeout)
    timeout = timeout or FLY_TIMEOUT
    local deadline = os.clock() + timeout
    local h = hum()
    local hrp = root()
    if not h or not hrp then return false end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "RGFly"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)

    local attach = hrp
    if h.SeatPart then attach = h.SeatPart end
    bv.Parent = attach

    local lastY = hrp.Position.Y
    local lastCheck = os.clock()
    local reached = false

    pcall(function()
        while os.clock() < deadline and enabled do
            hrp = root()
            if not hrp then break end
            if h.SeatPart then attach = h.SeatPart else attach = hrp end
            if bv.Parent ~= attach then bv.Parent = attach end

            local delta = target - hrp.Position
            local dist = delta.Magnitude
            if dist < ARRIVE_DIST then reached = true break end

            bv.Velocity = delta.Unit * FLY_SPEED

            if os.clock() - lastCheck > 0.5 then
                local dy = lastY - hrp.Position.Y
                if dy > VOID_DY then
                    bv.Velocity = Vector3.zero
                    local car = nil
                    if h.SeatPart then car = h.SeatPart:FindFirstAncestorOfClass("Model") end
                    if car then pcall(function() car:PivotTo(CFrame.new(target)) end) end
                    pcall(function() hrp.CFrame = CFrame.new(target) end)
                    task.wait(0.4)
                    lastY = target.Y
                else
                    lastY = hrp.Position.Y
                end
                lastCheck = os.clock()
            end
            task.wait(0.05)
        end
    end)

    if bv and bv.Parent then bv:Destroy() end
    return reached
end

local function seatCar(timeout)
    timeout = timeout or 12
    local deadline = os.clock() + timeout
    while os.clock() < deadline and enabled do
        local h = hum()
        local hrp = root()
        if h and h.Sit then return true end

        -- tìm xe theo tên (không dựa vào SeatPart)
        local car = findCarByName(selectedCar) or findMyCar()

        if car and h and hrp then
            -- tele tới xe trước
            local carPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
            if carPart then
                local dist = (carPart.Position - hrp.Position).Magnitude
                if dist > 8 then
                    pcall(function() hrp.CFrame = CFrame.new(carPart.Position + Vector3.new(0, 3, 0)) end)
                    task.wait(0.5)
                end
            end

            -- seat
            for _, d in ipairs(car:GetDescendants()) do
                if d:IsA("VehicleSeat") or d:IsA("Seat") then
                    pcall(function() d:Sit(h) end)
                    task.wait(0.6)
                    if h.Sit then
                        myCar = car
                        return true
                    end
                end
            end
        end
        task.wait(0.5)
    end
    return false
end

local function spawnAndSeat()
    if not SpawnCarEv then return false end
    if not selectedCar or selectedCar == "" then
        setState("chưa chọn xe")
        return false
    end

    setState("spawn " .. selectedCar:sub(1, 20))
    fire(SpawnCarEv, selectedCar)
    task.wait(3)

    if seatCar(12) then
        setState("sẵn sàng")
        return true
    end
    setState("spawn fail")
    return false
end

-- ============ INIT (1 LẦN) ============
local function doInit()
    setState("đổi job")
    fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(3)

    setState("online")
    fire(TaxiEvent, "GoOnline")
    task.wait(1.5)

    setState("spawn xe")
    if not (hum() and hum().Sit) then
        if not spawnAndSeat() then
            setState("spawn fail")
            return false
        end
    end
    myCar = findMyCar()
    setState("sẵn sàng")
    return true
end

-- ============ LOOP (chỉ đợi đơn + đón trả) ============
local function runTrip()
    -- đảm bảo còn ngồi xe
    local h = hum()
    if not h or not h.Sit then
        setState("mất xe → respawn")
        if not spawnAndSeat() then return end
    end

    setState("chờ đơn")
    orderToken = nil
    local deadline = os.clock() + ORDER_TIMEOUT
    while os.clock() < deadline and enabled do
        if orderToken then
            setState("accept")
            fire(TaxiEvent, "AcceptOrder", orderToken)
            break
        end
        task.wait(0.4)
    end

    deadline = os.clock() + 8
    while os.clock() < deadline and enabled do
        if pickupPos then break end
        task.wait(0.2)
    end
    if not pickupPos then
        setState("no pickup")
        return
    end

    setState("đón khách")
    flyTo(pickupPos, 40)
    task.wait(PICKUP_WAIT)

    if dropPos then
        setState("trả khách")
        flyTo(dropPos, 50)
        task.wait(DROP_WAIT)
    end

    pickupPos = nil
    dropPos = nil
    orderToken = nil
    setState("chờ đơn")
end

local function startLoop()
    if loopBusy then return end
    loopBusy = true
    task.spawn(function()
        -- init 1 lần
        if not initialized then
            local ok = pcall(doInit)
            if ok then initialized = true else initialized = false end
        end
        if not initialized then
            setState("init fail")
            loopBusy = false
            return
        end

        -- loop chính
        while enabled do
            local ok, err = pcall(runTrip)
            if not ok then
                setState("ERR: " .. tostring(err):sub(1, 40))
            end
            task.wait(2)
        end
        loopBusy = false
        setState("OFF")
    end)
end

local loopBusy = false

-- ============ GUI ============
local cg = game:GetService("CoreGui")
if cg:FindFirstChild("RideGoFarmUI") then cg.RideGoFarmUI:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RideGoFarmUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = cg

local rootUI = Instance.new("Frame", gui)
rootUI.Size = UDim2.new(0, 280, 0, 320)
rootUI.Position = UDim2.new(0, 20, 0.5, -160)
rootUI.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
rootUI.BorderSizePixel = 0
rootUI.Active = true
Instance.new("UICorner", rootUI).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke", rootUI)
st.Color = Color3.fromRGB(255, 140, 40)
st.Thickness = 1.5

local title = Instance.new("TextLabel", rootUI)
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "◈ RIDEGO v4"
title.TextColor3 = Color3.fromRGB(255, 140, 40)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local statLbl = Instance.new("TextLabel", rootUI)
statLbl.Size = UDim2.new(1, -16, 0, 44)
statLbl.Position = UDim2.new(0, 8, 0, 30)
statLbl.BackgroundTransparency = 1
statLbl.Text = "trips: 0 | earn: 0\n..."
statLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
statLbl.TextSize = 10
statLbl.Font = Enum.Font.Code
statLbl.TextXAlignment = Enum.TextXAlignment.Left
statLbl.TextYAlignment = Enum.TextYAlignment.Top

local toggleBtn = Instance.new("TextButton", rootUI)
toggleBtn.Size = UDim2.new(1, -16, 0, 30)
toggleBtn.Position = UDim2.new(0, 8, 0, 78)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
toggleBtn.Text = "▶ BẮT ĐẦU FARM"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 7)

-- header bảng xe (đóng/mở)
local carHeader = Instance.new("TextButton", rootUI)
carHeader.Size = UDim2.new(1, -16, 0, 26)
carHeader.Position = UDim2.new(0, 8, 0, 114)
carHeader.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
carHeader.Text = "▶ 🚗 CHỌN XE (0)"
carHeader.TextColor3 = Color3.fromRGB(255, 200, 80)
carHeader.TextSize = 11
carHeader.Font = Enum.Font.GothamBold
carHeader.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", carHeader).CornerRadius = UDim.new(0, 6)
local chp = Instance.new("UIPadding", carHeader)
chp.PaddingLeft = UDim.new(0, 8)

-- body bảng xe (ẩn mặc định)
local carBody = Instance.new("Frame", rootUI)
carBody.Size = UDim2.new(1, -16, 0, 0)
carBody.Position = UDim2.new(0, 8, 0, 146)
carBody.BackgroundTransparency = 1
carBody.Visible = false

-- nút quét
local scanBtn = Instance.new("TextButton", carBody)
scanBtn.Size = UDim2.new(1, 0, 0, 26)
scanBtn.Position = UDim2.new(0, 0, 0, 0)
scanBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 90)
scanBtn.Text = "🔍 QUÉT XE"
scanBtn.TextColor3 = Color3.new(1,1,1)
scanBtn.TextSize = 11
scanBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

-- scroll list
local scroll = Instance.new("ScrollingFrame", carBody)
scroll.Size = UDim2.new(1, 0, 0, 150)
scroll.Position = UDim2.new(0, 0, 0, 32)
scroll.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local sList = Instance.new("UIListLayout", scroll)
sList.Padding = UDim.new(0, 4)
sList.SortOrder = Enum.SortOrder.LayoutOrder
local sPad = Instance.new("UIPadding", scroll)
sPad.PaddingTop = UDim.new(0, 6)
sPad.PaddingLeft = UDim.new(0, 6)
sPad.PaddingRight = UDim.new(0, 6)
-- ============ GUI ============
local cg = game:GetService("CoreGui")
if cg:FindFirstChild("RideGoFarmUI") then cg.RideGoFarmUI:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RideGoFarmUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = cg

local rootUI = Instance.new("Frame", gui)
rootUI.Size = UDim2.new(0, 280, 0, 148)
rootUI.Position = UDim2.new(0, 20, 0.5, -74)
rootUI.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
rootUI.BorderSizePixel = 0
rootUI.Active = true
Instance.new("UICorner", rootUI).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke", rootUI)
st.Color = Color3.fromRGB(255, 140, 40)
st.Thickness = 1.5

local title = Instance.new("TextLabel", rootUI)
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "◈ RIDEGO v4"
title.TextColor3 = Color3.fromRGB(255, 140, 40)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local statLbl = Instance.new("TextLabel", rootUI)
statLbl.Size = UDim2.new(1, -16, 0, 44)
statLbl.Position = UDim2.new(0, 8, 0, 30)
statLbl.BackgroundTransparency = 1
statLbl.Text = "trips: 0 | earn: 0\n..."
statLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
statLbl.TextSize = 10
statLbl.Font = Enum.Font.Code
statLbl.TextXAlignment = Enum.TextXAlignment.Left
statLbl.TextYAlignment = Enum.TextYAlignment.Top

local toggleBtn = Instance.new("TextButton", rootUI)
toggleBtn.Size = UDim2.new(1, -16, 0, 30)
toggleBtn.Position = UDim2.new(0, 8, 0, 78)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
toggleBtn.Text = "▶ BẮT ĐẦU FARM"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 7)

-- header bảng xe
local carHeader = Instance.new("TextButton", rootUI)
carHeader.Size = UDim2.new(1, -16, 0, 26)
carHeader.Position = UDim2.new(0, 8, 0, 114)
carHeader.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
carHeader.Text = "▶ 🚗 CHỌN XE (0)"
carHeader.TextColor3 = Color3.fromRGB(255, 200, 80)
carHeader.TextSize = 11
carHeader.Font = Enum.Font.GothamBold
carHeader.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", carHeader).CornerRadius = UDim.new(0, 6)
local chp = Instance.new("UIPadding", carHeader)
chp.PaddingLeft = UDim.new(0, 8)

-- body bảng xe
local carBody = Instance.new("Frame", rootUI)
carBody.Size = UDim2.new(1, -16, 0, 0)
carBody.Position = UDim2.new(0, 8, 0, 146)
carBody.BackgroundTransparency = 1
carBody.Visible = false

local scanBtn = Instance.new("TextButton", carBody)
scanBtn.Size = UDim2.new(1, 0, 0, 26)
scanBtn.Position = UDim2.new(0, 0, 0, 0)
scanBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 90)
scanBtn.Text = "🔍 QUÉT XE"
scanBtn.TextColor3 = Color3.new(1,1,1)
scanBtn.TextSize = 11
scanBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame", carBody)
scroll.Size = UDim2.new(1, 0, 0, 150)
scroll.Position = UDim2.new(0, 0, 0, 32)
scroll.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local sList = Instance.new("UIListLayout", scroll)
sList.Padding = UDim.new(0, 4)
sList.SortOrder = Enum.SortOrder.LayoutOrder
local sPad = Instance.new("UIPadding", scroll)
sPad.PaddingTop = UDim.new(0, 6)
sPad.PaddingLeft = UDim.new(0, 6)
sPad.PaddingRight = UDim.new(0, 6)
sPad.PaddingBottom = UDim.new(0, 6)

local carOpen = false

local function clearList()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function renderCars()
    clearList()
    scroll.CanvasSize = UDim2.new(0, 0, 0, #carList * 38 + 12)

    if #carList == 0 then
        local lbl = Instance.new("TextLabel", scroll)
        lbl.Size = UDim2.new(1, -12, 0, 40)
        lbl.BackgroundTransparency = 1
        lbl.Text = "chưa quét xe — tap QUÉT XE"
        lbl.TextColor3 = Color3.fromRGB(150, 160, 180)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextWrapped = true
        carHeader.Text = (carOpen and "▼ " or "▶ ") .. "🚗 CHỌN XE (0)"
        return
    end

    for i, name in ipairs(carList) do
        local btn = Instance.new("TextButton", scroll)
        btn.Size = UDim2.new(1, -12, 0, 34)
        btn.BackgroundColor3 = (name == selectedCar)
            and Color3.fromRGB(0, 150, 120)
            or Color3.fromRGB(30, 38, 54)
        btn.Text = "  " .. name
        btn.TextColor3 = Color3.fromRGB(220, 230, 240)
        btn.TextSize = 10
        btn.Font = Enum.Font.Code
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.LayoutOrder = i
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        btn.MouseButton1Click:Connect(function()
            selectedCar = name
            renderCars()
        end)
    end

    carHeader.Text = (carOpen and "▼ " or "▶ ") .. "🚗 CHỌN XE (" .. #carList .. ")"
end

carHeader.MouseButton1Click:Connect(function()
    carOpen = not carOpen
    carBody.Visible = carOpen
    if carOpen then
        carBody.Size = UDim2.new(1, -16, 0, 190)
        rootUI.Size = UDim2.new(0, 280, 0, 348)
    else
        carBody.Size = UDim2.new(1, -16, 0, 0)
        rootUI.Size = UDim2.new(0, 280, 0, 148)
    end
    carHeader.Text = (carOpen and "▼ " or "▶ ") .. "🚗 CHỌN XE (" .. #carList .. ")"
end)

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "⏳ đang quét..."
    task.spawn(function()
        scanCars()
        if #carList > 0 and (not selectedCar or selectedCar == "") then
            selectedCar = carList[1]
        end
        renderCars()
        scanBtn.Text = "🔍 QUÉT XE (" .. #carList .. ")"
    end)
end)

local function paint()
    if enabled then
        toggleBtn.Text = "■ DỪNG FARM"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    else
        toggleBtn.Text = "▶ BẮT ĐẦU FARM"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    paint()
    if enabled then
        startLoop()
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        statLbl.Text = string.format(
            "trips: %d | earn: %d\nstate: %s\ncar: %s",
            stats.trips, stats.earn, curState,
            (selectedCar ~= "" and selectedCar:sub(1, 30)) or "(chưa chọn)"
        )
    end
end)

-- drag
local dragging, dStart, dStartPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
       or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dStart = input.Position; dStartPos = rootUI.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch
                     or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - dStart
        rootUI.Position = UDim2.new(dStartPos.X.Scale, dStartPos.X.Offset + d.X,
                                     dStartPos.Y.Scale, dStartPos.Y.Offset + d.Y)
    end
end)

-- tự scan lần đầu
task.spawn(function()
    task.wait(1)
    scanCars()
    if #carList > 0 and (not selectedCar or selectedCar == "") then
        selectedCar = carList[1]
    end
    renderCars()
    scanBtn.Text = "🔍 QUÉT XE (" .. #carList .. ")"
end)

print("[ridego v4] loaded")
