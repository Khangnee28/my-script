-- language: Luau, executor: Delta
-- RideGo Farm v5 — clean
-- Init 1 lần: đổi job + online + spawn xe + seat.
-- Loop: đợi đơn → accept → bay pickup → đợi khách lên → bay drop → đợi xuống → loop.
-- Noclip + seat watcher giữ vững suốt trip.

local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ============ CONFIG ============
local FLY_SPEED     = 130
local FLY_TIMEOUT   = 40
local ARRIVE_DIST   = 6
local ORDER_TIMEOUT = 30
local PICKUP_WAIT   = 8
local DROP_WAIT     = 8

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
local InitCarData
if DealershipEvents then
    InitCarData = DealershipEvents:FindFirstChild("InitializeCarData")
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

-- ============ HOOK TAXI (auto accept) ============
if TaxiEvent then
    TaxiEvent.OnClientEvent:Connect(function(action, data)
        if type(data) ~= "table" then return end
        if action == "OrderOffer" then
            orderToken = data.Token
            pcall(function()
                TaxiEvent:FireServer("AcceptOrder", data.Token)
            end)
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

-- ============ SCAN CARS ============
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
        if not seen[n] then
            seen[n] = true
            table.insert(uniq, n)
        end
    end
    table.sort(uniq)
    carList = uniq
    return carList
end

-- ============ FIND CAR ============
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

-- ============ NOCLIP ============
local noclipOn = false
local noclipHooked = {}

local function forceNoclip(inst)
    if not inst then return end
    for _, p in ipairs(inst:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            pcall(function() p.CanCollide = false end)
        end
    end
end

local function hookNoclip(inst)
    if not inst or noclipHooked[inst] then return end
    noclipHooked[inst] = true
    inst.DescendantAdded:Connect(function(d)
        if noclipOn and d:IsA("BasePart") then
            pcall(function() d.CanCollide = false end)
        end
    end)
end

local function setNoclip(on)
    noclipOn = on
    if not on then return end
    local c = char()
    if c then forceNoclip(c); hookNoclip(c) end
    local car = myCar or findMyCar()
    if car then forceNoclip(car); hookNoclip(car) end
end

-- watcher noclip
task.spawn(function()
    while true do
        task.wait(0.1)
        if noclipOn then
            local c = char()
            if c then forceNoclip(c); hookNoclip(c) end
            local car = myCar or findMyCar()
            if car then forceNoclip(car); hookNoclip(car) end
        end
    end
end)

-- ============ RAYCAST FLOOR ============
local function rayFloorY(fromPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    local c = char()
    if c then table.insert(ignore, c) end
    -- ignore tất cả model có VehicleSeat (xe)
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChildWhichIsA("VehicleSeat", true) then
            table.insert(ignore, d)
        end
    end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = false
    local hit = workspace:Raycast(fromPos + Vector3.new(0, 5, 0), Vector3.new(0, -300, 0), params)
    if hit then return hit.Position.Y end
    return nil
end
-- freeze xe tại vị trí (không rơi, không trôi)
local freezeBV = nil
local function freezeCar(on)
    if freezeBV then
        pcall(function() freezeBV:Destroy() end)
        freezeBV = nil
    end
    if not on then return end

    local h = hum()
    if not h or not h.SeatPart then return end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "RGFreeze"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    bv.Parent = h.SeatPart
    freezeBV = bv

    -- loop giữ velocity = 0
    task.spawn(function()
        while freezeBV == bv and bv.Parent do
            bv.Velocity = Vector3.zero
            task.wait(0.1)
        end
    end)
end
-- ============ SEAT CAR ============
local function seatCar(timeout)
    timeout = timeout or 15
    local deadline = os.clock() + timeout
    while os.clock() < deadline and enabled do
        local h = hum()
        local hrp = root()
        if h and h.Sit then
            myCar = findMyCar()
            return true
        end

        if h and hrp then
            local car = findMyCar()
            if car then
                local vs = car:FindFirstChildWhichIsA("VehicleSeat", true)
                if vs and not vs.Occupant then
                    pcall(function()
                        hrp.CFrame = CFrame.new(vs.Position + Vector3.new(0, 2, 0))
                    end)
                    task.wait(0.4)
                    pcall(function() vs:Sit(h) end)
                    task.wait(0.6)
                    if h.Sit then myCar = car return true end
                    pcall(function() h.Sit = true end)
                    task.wait(0.5)
                    if h.Sit then myCar = car return true end
                end
            end
        end
        task.wait(0.4)
    end
    return false
end

-- seat watcher — tự seat lại nếu té
task.spawn(function()
    while true do
        task.wait(0.15)
        if enabled and myCar and myCar.Parent then
            local h = hum()
            if h and not h.Sit then
                local vs = myCar:FindFirstChildWhichIsA("VehicleSeat", true)
                local hrp = root()
                if vs and hrp then
                    pcall(function()
                        hrp.CFrame = CFrame.new(vs.Position + Vector3.new(0, 2, 0))
                    end)
                    task.wait(0.1)
                    pcall(function() vs:Sit(h) end)
                    task.wait(0.15)
                    if not h.Sit then
                        pcall(function() h.Sit = true end)
                    end
                end
            end
        end
    end
end)

-- ============ FLY ============
local function flyTo(target, timeout)
    timeout = timeout or FLY_TIMEOUT
    local deadline = os.clock() + timeout
    local h = hum()
    local hrp = root()
    if not h or not hrp then return false end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "RGFly"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)

    local attach = hrp
    if h.SeatPart then attach = h.SeatPart end
    bv.Parent = attach

    setNoclip(true)

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
            if dist < ARRIVE_DIST then
                reached = true
                break
            end

            local speed = FLY_SPEED
            if dist < 60 then
                speed = math.max(FLY_SPEED * (dist / 60), 20)
            end

            local dir = delta.Unit
            if hrp.Position.Y - target.Y < -20 then
                dir = Vector3.new(dir.X, math.max(dir.Y, 0.5), dir.Z).Unit
            end
            bv.Velocity = dir * speed

            -- void detect
if os.clock() - lastCheck > 0.15 then
    local origin = Vector3.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
    local belowY = rayFloorY(origin)
    local isVoid = (belowY == nil) or (hrp.Position.Y - belowY > 50)

    if isVoid then
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(0, 0, 0)

        local forward = delta.Unit
        local curY = hrp.Position.Y

        local jumpDist = 100
        for testDist = 60, 400, 25 do
            local testPos = hrp.Position + forward * testDist
            local fY = rayFloorY(testPos)
            if fY and math.abs(curY - fY) < 80 then
                jumpDist = testDist
                break
            end
        end

        local dest = hrp.Position + forward * jumpDist
        dest = Vector3.new(dest.X, curY + 8, dest.Z)

        local carModel = nil
        if h.SeatPart then
            carModel = h.SeatPart:FindFirstAncestorOfClass("Model")
        elseif myCar then
            carModel = myCar
        end

        if carModel then
            pcall(function() carModel:PivotTo(CFrame.new(dest)) end)
        end
        pcall(function() hrp.CFrame = CFrame.new(dest) end)
        task.wait(0.2)

        if not h.Sit then
            local vs = carModel and carModel:FindFirstChildWhichIsA("VehicleSeat", true)
            if vs then
                pcall(function() vs:Sit(h) end)
                task.wait(0.2)
                if not h.Sit then
                    pcall(function() h.Sit = true end)
                    task.wait(0.2)
                end
            end
        end

        bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        task.wait(0.3)
    end

    lastCheck = os.clock()
end

-- ============ SPAWN & SEAT ============
local function spawnAndSeat()
    if not SpawnCarEv then return false end
    if not selectedCar or selectedCar == "" then
        setState("chưa chọn xe")
        return false
    end

    local car = findMyCar()
    if car and car:FindFirstChildWhichIsA("BasePart", true) then
        setState("ngồi xe có sẵn")
        if seatCar(10) then
            setState("sẵn sàng")
            return true
        end
    end

    setState("spawn " .. selectedCar:sub(1, 20))
    fire(SpawnCarEv, selectedCar)

    local deadline = os.clock() + 20
    while os.clock() < deadline and enabled do
        car = findMyCar()
        if car and car:FindFirstChildWhichIsA("BasePart", true) then
            local r = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
            if r and r.AssemblyLinearVelocity.Magnitude < 5 then
                break
            end
        end
        task.wait(0.5)
    end

    if not car then
        setState("xe chưa hiện")
        return false
    end

    task.wait(1.5)

    if seatCar(15) then
        setState("sẵn sàng")
        task.wait(1)
        return true
    end
    setState("seat fail")
    return false
end

-- ============ INIT ============
local function doInit()
    local h = hum()
    if h and h.Sit then
        myCar = findMyCar()
setNoclip(false)
setState("sẵn sàng")
return true
    end

    setState("đổi job")
    fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(3)

    setState("online")
    fire(TaxiEvent, "GoOnline")
    task.wait(2)

    setState("spawn xe")
    if not spawnAndSeat() then
        return false
    end

    myCar = findMyCar()
    setNoclip(true)
    setState("sẵn sàng")
    return true
end

-- ============ RUN TRIP ============

local function runTrip()
    local h = hum()
    if not h or not h.Sit then
        setState("respawn xe")
        if not spawnAndSeat() then
            task.wait(5)
            return
        end
    end
    myCar = findMyCar()

    setNoclip(false)
    setState("chờ đơn")
    orderToken = nil
    pickupPos = nil
    freezeCar(true)

    local deadline = os.clock() + ORDER_TIMEOUT
    while os.clock() < deadline and enabled do
        if pickupPos then break end
        local hrp = root()
        if hrp and hrp.Position.Y < -50 then
            setState("void — tele lên")
            pcall(function() hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z) end)
            task.wait(0.5)
        end
        task.wait(0.4)
    end

    if not pickupPos then
        setState("no pickup")
        freezeCar(false)
        return
    end

    freezeCar(false)
    setState("đón khách")
    setNoclip(true)
    flyTo(pickupPos, 40)
    setNoclip(false)
    freezeCar(true)

    setState("khách lên xe (" .. PICKUP_WAIT .. "s)")
    task.wait(PICKUP_WAIT)
    freezeCar(false)

    if dropPos then
        setState("trả khách")
        setNoclip(true)
        flyTo(dropPos, 50)
        setNoclip(false)
        freezeCar(true)

        setState("khách xuống xe (" .. DROP_WAIT .. "s)")
        task.wait(DROP_WAIT)
        freezeCar(false)
    end

    pickupPos = nil
    dropPos = nil
    orderToken = nil
    setState("chu kỳ xong")
end

-- ============ LOOP ============
local loopBusy = false

local function startLoop()
    if loopBusy then return end
    loopBusy = true
    task.spawn(function()
        if not initialized then
            local ok = pcall(doInit)
            initialized = ok
        end
        if not initialized then
            loopBusy = false
            return
        end

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
title.Text = "◈ RIDEGO v5"
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
    if enabled then startLoop() end
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

task.spawn(function()
    task.wait(1)
    scanCars()
    if #carList > 0 and (not selectedCar or selectedCar == "") then
        selectedCar = carList[1]
    end
    renderCars()
    scanBtn.Text = "🔍 QUÉT XE (" .. #carList .. ")"
end)

print("[ridego v5] loaded")
