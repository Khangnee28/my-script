-- language: Luau, executor: Delta
-- RideGo Farm — FINAL v10
-- Noclip theo PHA: BAT khi bat dau bay, TAT khi cham dat.
-- Cho don: noclip OFF, collide ON, hold Y=0 -> xe dung tren dat.
-- Ep ghe lai: CFrame tuyet doi tren ghe + Sit cung + verify 2 lan.

local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ============ CONFIG ============
local STEP_DIST      = 180
local FLY_Y          = 5
local ARRIVE_DIST    = 8
local ORDER_TIMEOUT  = 60
local PICKUP_WAIT    = 8
local DROP_WAIT      = 8
local DECEL_DIST     = 200
local VOID_SCAN_MIN  = 100
local VOID_SCAN_MAX  = 100000
local VOID_SCAN_STEP = 150
local TICK           = 0.05
local LAND_OFFSET    = 3

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
local holdBV = nil
local flying = false

local function resetState()
    orderToken = nil
    pickupPos = nil
    dropPos = nil
    myCar = nil
    initialized = false
    stats.trips = 0
    stats.earn = 0
    curState = "OFF"
    flying = false
    if holdBV then
        pcall(function() holdBV:Destroy() end)
        holdBV = nil
    end
end

-- ============ REMOTES ============
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
            pcall(function() TaxiEvent:FireServer("AcceptOrder", data.Token) end)
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
        if not seen[n] then seen[n] = true; table.insert(uniq, n) end
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

-- ============ RAYCAST ============
local function rayFloorY(fromPos, maxDist, ignoreWater)
    maxDist = maxDist or 800
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    local c = char()
    if c then table.insert(ignore, c) end
    local car = myCar or findMyCar()
    if car then table.insert(ignore, car) end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = ignoreWater or false

    local hit = workspace:Raycast(
        fromPos + Vector3.new(0, 5, 0),
        Vector3.new(0, -maxDist, 0),
        params
    )
    if hit then
        if hit.Material == Enum.Material.Water then return nil end
        return hit.Position.Y
    end
    return nil
end

-- ============ NOCLIP ============
-- Cong tac toan bo: BAT khi bay (xuyen tuong), TAT khi cham dat (va cham san).
local carNoclipOn = false
local noclipHooked = {}

local function walkNoclip(inst)
    if not inst then return end
    if inst:IsA("BasePart") and inst.CanCollide then
        pcall(function() inst.CanCollide = false end)
    end
    for _, p in ipairs(inst:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            pcall(function() p.CanCollide = false end)
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

local function hookNoclip(inst)
    if not inst or noclipHooked[inst] then return end
    noclipHooked[inst] = true
    inst.DescendantAdded:Connect(function(d)
        if carNoclipOn and d:IsA("BasePart") and d.CanCollide then
            pcall(function() d.CanCollide = false end)
        end
    end)
end

local function hookPassengerChars()
    for _, plr in ipairs(Players:GetPlayers()) do
        local c = plr.Character
        if c then
            hookNoclip(c)
            if carNoclipOn then walkNoclip(c) end
        end
    end
end

local function forceNoclip()
    local car = myCar or findMyCar()
    if car then
        walkNoclip(car)
        local vs = car:FindFirstChildWhichIsA("VehicleSeat", true)
        if vs and vs.Occupant then
            local h = vs.Occupant
            if h and h.Parent then walkNoclip(h.Parent) end
        end
    end
    local c = char()
    if c then walkNoclip(c) end
    hookPassengerChars()
end

-- BAT noclip toan bo (khi bat dau bay)
local function noclipAllOn()
    carNoclipOn = true
    local car = myCar or findMyCar()
    if car then hookNoclip(car) end
    local c = char()
    if c then hookNoclip(c) end
    hookPassengerChars()
    forceNoclip()
end

-- TAT noclip, bat lai collide toan bo (khi cham dat)
local function noclipAllOff()
    carNoclipOn = false
    local car = myCar or findMyCar()
    if car then fullCollideOn(car) end
    local c = char()
    if c then fullCollideOn(c) end
    for _, plr in ipairs(Players:GetPlayers()) do
        local pc = plr.Character
        if pc then fullCollideOn(pc) end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(c)
        hookNoclip(c)
        if carNoclipOn then walkNoclip(c) else fullCollideOn(c) end
    end)
end)
Players.PlayerRemoving:Connect(function(plr)
    noclipHooked[plr] = nil
end)

task.spawn(function()
    while true do
        task.wait(0.03)
        if carNoclipOn then forceNoclip() end
    end
end)

-- ============ HOLD ============
local function startHold()
    if holdBV then
        pcall(function() holdBV:Destroy() end)
        holdBV = nil
    end
    local car = myCar or findMyCar()
    if not car then return end
    local vs = car:FindFirstChildWhichIsA("VehicleSeat", true)
    if not vs then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "RGHold"
    bv.MaxForce = Vector3.new(1e6, 0, 1e6)
    bv.P = 10000
    bv.Velocity = Vector3.zero
    bv.Parent = vs
    holdBV = bv
    task.spawn(function()
        while holdBV == bv and bv.Parent do
            bv.Velocity = Vector3.zero
            task.wait(0.03)
        end
    end)
end

local function stopHold()
    if holdBV then
        pcall(function() holdBV:Destroy() end)
        holdBV = nil
    end
end

-- ============ SEAT ============
local function getDriveSeat(car)
    if not car then return nil end
    for _, d in ipairs(car:GetDescendants()) do
        if d:IsA("VehicleSeat") then
            local n = d.Name:lower()
            if n:find("drive") or n:find("driver") then
                return d
            end
        end
    end
    return car:FindFirstChildWhichIsA("VehicleSeat", true)
end

-- Ep ngoi ghe lai: CFrame tuyet doi tren ghe + Sit cung + verify 2 lan.
local function forceSeat()
    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return false end
    local vs = getDriveSeat(car)
    if not vs then return false end

    if h.Sit and h.SeatPart == vs then return true end

    if h.Sit and h.SeatPart ~= vs then
        pcall(function() h.Sit = false end)
        task.wait(0.1)
    end

    if vs.Occupant and vs.Occupant ~= h then
        local occ = vs.Occupant
        if occ and occ:IsA("Humanoid") then
            pcall(function() occ.Sit = false end)
            task.wait(0.1)
        end
    end

    -- CFrame toi NGAY TREN ghe lai, khong lech sang ghe khac
    local hrp = root()
    if hrp then
        local seatCF = vs.CFrame * CFrame.new(0, 2.5, 0)
        pcall(function() hrp.CFrame = seatCF end)
        task.wait(0.05)
    end

    pcall(function() vs:Sit(h) end)
    task.wait(0.08)

    -- verify lan 1
    if not h.Sit or h.SeatPart ~= vs then
        local hrp2 = root()
        if hrp2 then
            local seatCF2 = vs.CFrame * CFrame.new(0, 3, 0)
            pcall(function() hrp2.CFrame = seatCF2 end)
            task.wait(0.05)
        end
        pcall(function() vs:Sit(h) end)
        task.wait(0.08)
    end

    -- verify lan cuoi
    if not h.Sit or h.SeatPart ~= vs then
        pcall(function() h.Sit = true end)
        task.wait(0.05)
    end

    return h.Sit and h.SeatPart == vs
end

-- Seat loop: chi chay khi KHONG bay
task.spawn(function()
    while true do
        task.wait(0.15)
        if enabled and not flying and (myCar or findMyCar()) then
            local h = hum()
            if h then
                local car = myCar or findMyCar()
                local vs = getDriveSeat(car)
                local wrongSeat = h.Sit and vs and h.SeatPart ~= vs
                local notSeated = not h.Sit
                if wrongSeat or notSeated then
                    forceSeat()
                end
            end
        end
    end
end)

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
            forceSeat()
        end
        task.wait(0.4)
    end
    return false
end

-- ============ VOID SCAN ============
local function scanVoidBridge(curPos, dir, curFloorY)
    for testDist = VOID_SCAN_MIN, VOID_SCAN_MAX, VOID_SCAN_STEP do
        local testPos = curPos + dir * testDist
        local fY = rayFloorY(testPos, 1500)
        if fY and fY > -10 then
            if not curFloorY or math.abs(curFloorY - fY) < 80 then
                return testDist, fY
            end
        end
    end
    return nil, nil
end

-- ============ FLY ============
local function flyTo(target)
    stopHold()
    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return false end

    -- BAT NOCLIP TOAN BO NGAY khi bat dau bay
    noclipAllOn()
    flying = true
    if not h.Sit then forceSeat(); task.wait(0.1) end

    local vs = getDriveSeat(car)
    local attach = vs or root()
    if not attach then flying = false; return false end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "RGFly"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.P = 5000
    bv.Velocity = Vector3.zero
    bv.Parent = attach

    local bg = Instance.new("BodyGyro")
    bg.Name = "RGGyro"
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P = 5000
    bg.D = 500
    bg.Parent = attach

    local reached = false
    local lastVoidCheck = 0

    while enabled do
        car = myCar or findMyCar()
        if not car then break end
        local hrp = root()
        if not hrp then break end

        vs = getDriveSeat(car)
        if vs and attach ~= vs then
            attach = vs
            bv.Parent = vs
            bg.Parent = vs
        end

        local curPos = (h.Sit and vs) and vs.Position or hrp.Position
        local delta = target - curPos
        local flat = Vector3.new(delta.X, 0, delta.Z)
        local dist = flat.Magnitude

        if dist < ARRIVE_DIST then
            reached = true
            bv.Velocity = Vector3.zero
            bv.MaxForce = Vector3.new(0, 0, 0)
            break
        end

        local dir = (dist > 0.01) and flat.Unit or Vector3.new(1, 0, 0)

        pcall(function()
            bg.CFrame = CFrame.lookAt(curPos, Vector3.new(target.X, curPos.Y, target.Z))
        end)

        if os.clock() - lastVoidCheck > 0.25 then
            lastVoidCheck = os.clock()
            local curFloorY = rayFloorY(curPos, 500)
            local aheadFloorY = rayFloorY(curPos + dir * 100, 800)
            local voidHere = (curFloorY == nil) or (curFloorY < -20)
            local voidAhead = (aheadFloorY == nil) or (aheadFloorY < -20)

            if voidHere or voidAhead then
                setState("void - scan")
                bv.Velocity = Vector3.zero
                local jumpDist, jumpY = scanVoidBridge(curPos, dir, curFloorY)
                local dest
                if jumpDist and jumpY then
                    dest = Vector3.new(
                        curPos.X + dir.X * jumpDist,
                        jumpY + FLY_Y,
                        curPos.Z + dir.Z * jumpDist
                    )
                    setState("void - qua " .. jumpDist)
                else
                    dest = Vector3.new(target.X, target.Y + 15, target.Z)
                    setState("void - tele target")
                end
                local carModel = myCar or findMyCar()
                if carModel then
                    pcall(function() carModel:PivotTo(CFrame.new(dest)) end)
                end
                if not h.Sit then forceSeat() end
                task.wait(0.4)
                lastVoidCheck = os.clock() + 0.5
            end
        end

        local curFloorY2 = rayFloorY(curPos, 500)
        local targetY = curPos.Y
        if curFloorY2 and curFloorY2 > -20 then
            local candidateY = curFloorY2 + FLY_Y
            if candidateY <= curPos.Y + 15 then
                targetY = candidateY
            end
        end

        local speed
        if dist >= DECEL_DIST then
            speed = STEP_DIST
        else
            speed = math.max(STEP_DIST * dist / DECEL_DIST, 6)
        end

        local vx = dir.X * speed
        local vz = dir.Z * speed
        local vy = (targetY - curPos.Y) * 5
        vy = math.clamp(vy, -40, 40)

        bv.Velocity = Vector3.new(vx, vy, vz)
        if not h.Sit then forceSeat() end
        task.wait(TICK)
    end

    if bv and bv.Parent then bv:Destroy() end
    if bg and bg.Parent then bg:Destroy() end
    task.wait(0.1)

    -- ===== HA XUONG: TAT NOCLIP, BAT COLLIDE, roi ha =====
    car = myCar or findMyCar()
    if not car then flying = false; task.wait(0.2); return reached end

    local vs2 = getDriveSeat(car)
    local endPos = (vs2 and vs2.Position) or (root() and root().Position)
    if not endPos then flying = false; task.wait(0.2); return reached end

    -- TAT noclip ngay -> bat collide toan bo truoc khi ha
    noclipAllOff()
    task.wait(0.05)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ign = {}
    local cc = char()
    if cc then table.insert(ign, cc) end
    table.insert(ign, car)
    params.FilterDescendantsInstances = ign
    params.IgnoreWater = true

    local origin = Vector3.new(endPos.X, endPos.Y + 300, endPos.Z)
    local hit = workspace:Raycast(origin, Vector3.new(0, -3000, 0), params)

    if hit then
        local targetY = hit.Position.Y + LAND_OFFSET
        local landed = Vector3.new(endPos.X, targetY, endPos.Z)
        pcall(function() car:PivotTo(CFrame.new(landed)) end)
        task.wait(0.2)
    else
        setState("khong thay dat - giu do cao")
    end

    flying = false

    if not h.Sit then forceSeat() end
    task.wait(0.1)

    startHold()

    local h2 = hum()
    if not h2 or not h2.Sit then
        forceSeat()
        task.wait(0.2)
    end

    task.wait(0.15)
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
            if r and r.AssemblyLinearVelocity.Magnitude < 5 then break end
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
    setState("doi job")
    fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(3)

    setState("spawn xe")
    if not spawnAndSeat() then return false end
    myCar = findMyCar()

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
        if not spawnAndSeat() then task.wait(5); return end
    end
    myCar = findMyCar()

    -- Cho don: noclip OFF, collide ON, hold Y=0
    noclipAllOff()
    startHold()

    setState("cho don")
    orderToken = nil
    pickupPos = nil
    local deadline = os.clock() + ORDER_TIMEOUT
    while os.clock() < deadline and enabled do
        if pickupPos then break end
        if not holdBV or not holdBV.Parent then
            startHold()
        end
        task.wait(0.4)
    end

    if not pickupPos then setState("no pickup"); return end

    setState("don khach")
    flyTo(pickupPos)
    task.wait(0.5)
    forceSeat()
    setState("khach len xe")
    task.wait(PICKUP_WAIT)

    if dropPos then
        setState("tra khach")
        flyTo(dropPos)
        task.wait(0.5)
        forceSeat()
        setState("khach xuong xe")
        task.wait(DROP_WAIT)
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
        if not initialized then loopBusy = false return end
        while enabled do
            local ok, err = pcall(runTrip)
            if not ok then setState("ERR: " .. tostring(err):sub(1, 40)) end
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
        btn.BackgroundColor3 = (name == selectedCar) and Color3.fromRGB(0, 150, 120) or Color3.fromRGB(30, 38, 54)
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
    if enabled then
        enabled = false
        resetState()
        noclipAllOff()
        local h = hum()
        if h and h.Sit then
            pcall(function() h.Sit = false end)
        end
        paint()
    else
        resetState()
        enabled = true
        paint()
        startLoop()
    end
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
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dStart = input.Position; dStartPos = rootUI.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - dStart
        rootUI.Position = UDim2.new(dStartPos.X.Scale, dStartPos.X.Offset + d.X, dStartPos.Y.Scale, dStartPos.Y.Offset + d.Y)
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

print("[ridego] loaded v10")
