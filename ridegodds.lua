-- language: Luau, executor: Delta
-- RideGo Farm - anchor teleport edition
-- Xe anchor trong lúc bay -> khong roi void, khong va tuong, khong xe char.

local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ============ CONFIG ============
local STEP_DIST     = 25      -- studs moi buoc
local STEP_DELAY    = 0.06    -- giay giua cac buoc
local ARRIVE_DIST   = 8
local FLY_TIMEOUT   = 60
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
    if ev then TaxiEvent = ev:WaitForChild("SpawnCar", 5) or ev:WaitForChild("TaxiEvent", 5) end
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

-- ============ TAXI HOOK ============
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

-- ============ ANCHOR CAR ============
local function anchorCar(on)
    local car = myCar or findMyCar()
    if not car then return end
    for _, p in ipairs(car:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.Anchored = on end)
            if on then
                pcall(function()
                    p.AssemblyLinearVelocity = Vector3.zero
                    p.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end
end

-- ============ SEAT WATCHER ============
local function getDriveSeat(car)
    if not car then return nil end
    -- ưu tiên DriveSeat / DriverSeat
    for _, d in ipairs(car:GetDescendants()) do
        if d:IsA("VehicleSeat") then
            local n = d.Name:lower()
            if n:find("drive") or n:find("driver") then
                return d
            end
        end
    end
    -- fallback: VehicleSeat đầu tiên
    return car:FindFirstChildWhichIsA("VehicleSeat", true)
end

local function forceSeat()
    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return end
    if h.Sit then
        -- check có đang ngồi DriveSeat không
        local vs = getDriveSeat(car)
        if vs and h.SeatPart ~= vs then
            -- ngồi nhầm ghế → đứng lên
            pcall(function() h.Sit = false end)
            task.wait(0.2)
        else
            return
        end
    end
    local vs = getDriveSeat(car)
    if not vs then return end
    if vs.Occupant and vs.Occupant ~= h then return end
    local hrp = root()
    if hrp then
        pcall(function() hrp.CFrame = CFrame.new(vs.Position + Vector3.new(0, 2, 0)) end)
        task.wait(0.05)
    end
    pcall(function() vs:Sit(h) end)
    task.wait(0.05)
    if not h.Sit or h.SeatPart ~= vs then
        pcall(function() h.Sit = true end)
    end
end

-- ============ SEAT ============
local function seatCar(timeout)
    timeout = timeout or 15
    local deadline = os.clock() + timeout
    while os.clock() < deadline and enabled do
        local h = hum()
        local car = findMyCar()
        if h and car then
            local vs = getDriveSeat(car)
            if h.Sit and h.SeatPart == vs then
                myCar = car
                return true
            end
            if h.Sit and h.SeatPart ~= vs then
                -- ngồi nhầm ghế → đứng lên
                pcall(function() h.Sit = false end)
                task.wait(0.3)
            end
            if vs and not vs.Occupant then
                local hrp = root()
                if hrp then
                    pcall(function() hrp.CFrame = CFrame.new(vs.Position + Vector3.new(0, 2, 0)) end)
                    task.wait(0.3)
                end
                pcall(function() vs:Sit(h) end)
                task.wait(0.5)
                if h.Sit and h.SeatPart == vs then
                    myCar = car
                    return true
                end
                pcall(function() h.Sit = true end)
                task.wait(0.4)
                if h.Sit and h.SeatPart == vs then
                    myCar = car
                    return true
                end
            end
        end
        task.wait(0.4)
    end
    return false
end

-- ============ FLY (anchored + PivotTo) ============
local function rayFloorY(fromPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    local c = char()
    if c then table.insert(ignore, c) end
    local car = myCar or findMyCar()
    if car then table.insert(ignore, car) end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local hit = workspace:Raycast(fromPos + Vector3.new(0, 2, 0), Vector3.new(0, -500, 0), params)
    if hit then return hit.Position.Y end
    return nil
end

local function flyTo(target, timeout)
    timeout = timeout or FLY_TIMEOUT
    local deadline = os.clock() + timeout

    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return false end

    anchorCar(true)
    task.wait(0.1)
    if not h.Sit then forceSeat(); task.wait(0.1) end

    local reached = false
    local GROUND_OFFSET = 8   -- bay cao 8 studs tren mat dat

    while os.clock() < deadline and enabled do
        car = myCar or findMyCar()
        if not car then break end

        local hrp = root()
        if not hrp then break end

        local vs = getDriveSeat(car)
        local curPos = (h.Sit and vs) and vs.Position or hrp.Position

        -- chi check khoang cach ngang (X,Z)
        local delta = target - curPos
        local flat = Vector3.new(delta.X, 0, delta.Z)
        local dist = flat.Magnitude
        if dist < ARRIVE_DIST then
            reached = true
            break
        end

        local dir = flat.Unit

        -- raycast phia truoc 40 studs: check void
        local aheadPos = curPos + dir * 40
        local aheadFloorY = rayFloorY(aheadPos)
        local isVoidAhead = (aheadFloorY == nil) or (aheadFloorY < -50)

        if isVoidAhead then
            -- tim bo ben kia void
            local jumpDist = 80
            local jumpFloorY = nil
            for testDist = 50, 400, 25 do
                local testPos = curPos + dir * testDist
                local fY = rayFloorY(testPos)
                if fY and fY > -50 then
                    jumpDist = testDist
                    jumpFloorY = fY
                    break
                end
            end
            if jumpFloorY then
                local dest = Vector3.new(
                    curPos.X + dir.X * jumpDist,
                    jumpFloorY + GROUND_OFFSET,
                    curPos.Z + dir.Z * jumpDist
                )
                pcall(function() car:PivotTo(CFrame.new(dest)) end)
                if not h.Sit then forceSeat() end
                task.wait(0.15)
            else
                -- khong tim duoc bo -> dung lai
                break
            end
        else
            -- buoc binh thuong: 25 studs
            local step = math.min(STEP_DIST, dist)
            local flatNext = curPos + dir * step

            -- raycast xuong tai vi tri moi -> lay Y cua mat dat
            local nextFloorY = rayFloorY(flatNext)
            local nextY
            if nextFloorY then
                nextY = nextFloorY + GROUND_OFFSET
            else
                nextY = curPos.Y
            end

            local nextPos = Vector3.new(flatNext.X, nextY, flatNext.Z)
            pcall(function() car:PivotTo(CFrame.new(nextPos)) end)
            if not h.Sit then forceSeat() end
            task.wait(STEP_DELAY)
        end
    end

    anchorCar(false)

    local h2 = hum()
    if h2 and h2.SeatPart then
        pcall(function()
            h2.SeatPart.AssemblyLinearVelocity = Vector3.zero
            h2.SeatPart.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    task.wait(0.2)
    return reached
end
-- ============ SPAWN ============
local function spawnAndSeat()
    if not SpawnCarEv then return false end
    if not selectedCar or selectedCar == "" then
        setState("chua chon xe")
        return false
    end

    local car = findMyCar()
    if car and car:FindFirstChildWhichIsA("BasePart", true) then
        setState("ngoi xe co san")
        if seatCar(10) then
            setState("san sang")
            return true
        end
    end

    setState("spawn xe")
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
        setState("xe chua hien")
        return false
    end

    task.wait(1.5)

    if seatCar(15) then
        setState("san sang")
        task.wait(1)
        return true
    end
    setState("seat fail")
    return false
end

-- ============ INIT ============
local function doInit()
    -- 1. spawn xe + seat TRUOC
    setState("spawn xe")
    if not spawnAndSeat() then
        return false
    end

    myCar = findMyCar()

    -- 2. doi job
    setState("doi job")
    fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(3)

    -- 3. online (nhan don)
    setState("online")
    fire(TaxiEvent, "GoOnline")
    task.wait(2)

    setState("san sang")
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
    anchorCar(true)   -- giu xe dung yen khi cho don

    setState("cho don")
    orderToken = nil
    pickupPos = nil

    local deadline = os.clock() + ORDER_TIMEOUT
    while os.clock() < deadline and enabled do
        if pickupPos then break end
        local hrp = root()
        if hrp and hrp.Position.Y < -50 then
            -- re-seat + tele len
            forceSeat()
            pcall(function() hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z) end)
        end
        task.wait(0.4)
    end

    if not pickupPos then
        setState("no pickup")
        anchorCar(false)
        return
    end

    setState("don khach")
    flyTo(pickupPos, 50)
    -- anchored -> khong roi
    anchorCar(true)

    setState("khach len xe")
    task.wait(PICKUP_WAIT)
    anchorCar(false)

    if dropPos then
        setState("tra khach")
        flyTo(dropPos, 60)
        anchorCar(true)

        setState("khach xuong xe")
        task.wait(DROP_WAIT)
        anchorCar(false)
    end

    pickupPos = nil
    dropPos = nil
    orderToken = nil
    setState("chu ky xong")
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
title.Text = "RIDEGO FARM"
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
toggleBtn.Text = "BAT DAU FARM"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 7)

local carHeader = Instance.new("TextButton", rootUI)
carHeader.Size = UDim2.new(1, -16, 0, 26)
carHeader.Position = UDim2.new(0, 8, 0, 114)
carHeader.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
carHeader.Text = "> CHON XE (0)"
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
scanBtn.Text = "QUET XE"
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
        lbl.Text = "chua quet xe"
        lbl.TextColor3 = Color3.fromRGB(150, 160, 180)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium
        carHeader.Text = (carOpen and "v " or "> ") .. "CHON XE (0)"
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

    carHeader.Text = (carOpen and "v " or "> ") .. "CHON XE (" .. #carList .. ")"
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
    carHeader.Text = (carOpen and "v " or "> ") .. "CHON XE (" .. #carList .. ")"
end)

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "dang quet..."
    task.spawn(function()
        scanCars()
        if #carList > 0 and (not selectedCar or selectedCar == "") then
            selectedCar = carList[1]
        end
        renderCars()
        scanBtn.Text = "QUET XE (" .. #carList .. ")"
    end)
end)

local function paint()
    if enabled then
        toggleBtn.Text = "DUNG FARM"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    else
        toggleBtn.Text = "BAT DAU FARM"
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
            (selectedCar ~= "" and selectedCar:sub(1, 30)) or "(chua chon)"
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
    scanBtn.Text = "QUET XE (" .. #carList .. ")"
end)

print("[ridego] loaded")
