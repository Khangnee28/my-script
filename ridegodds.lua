-- language: Luau, executor: Delta
-- RideGo Farm — FINAL v26
-- AckTripComplete sau khi tra khach 3s. Offline/Online neu >15s khong co don.
-- UNDERGROUND_DEPTH=200. LAND_OFFSET=8. Timer farm. UI status trong suot. LED RGB.
-- Menu chinh 2 nut. Nut an/hien UI. Ten xe hien thi. Print tieng Viet.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ============ CONFIG ============
local STEP_DIST           = 250
local LAND_OFFSET         = 8
local ARRIVE_DIST         = 8
local ORDER_TIMEOUT       = 60
local PICKUP_WAIT         = 4
local DROP_WAIT           = 4
local ACK_DELAY           = 3
local RECONNECT_AFTER     = 15
local DECEL_DIST          = 200
local TICK                = 0.05
local UNDERGROUND_DEPTH   = 200
local UNDER_STEP_MAX      = 50
local UNDER_DESCEND_STEPS = 12
local UNDER_STEP_TIME     = 0.03

-- ============ TRẠNG THÁI ============
local enabled     = false
local initialized = false
local orderToken  = nil
local pickupPos   = nil
local dropPos     = nil
local pendingFare = 0
local myCar       = nil
local selectedCar = ""
local carList     = {}
local stats       = { trips = 0, earn = 0 }
local curStatus   = "◦ TẮT"
local holdBV      = nil
local flying      = false
local acceptingOrder = false
local farmStartTime  = 0

local function resetState()
    orderToken = nil
    pickupPos = nil
    dropPos = nil
    pendingFare = 0
    myCar = nil
    curStatus = "◦ TẮT"
    flying = false
    acceptingOrder = false
    initialized = false
    farmStartTime = 0
    if holdBV then
        pcall(function() holdBV:Destroy() end)
        holdBV = nil
    end
end

local function setStatus(s)
    curStatus = s
    print("[RideGo] " .. s)
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

-- ============ HÀM PHỤ ============
local function char() return lp.Character end
local function root() local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end

local function fire(remote, ...)
    if not remote then return false end
    local args = {...}
    local ok = pcall(function() remote:FireServer(table.unpack(args)) end)
    return ok
end

local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- ============ SỰ KIỆN TAXI ============
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
            if type(data.Fare) == "number" then
                pendingFare = data.Fare
            else
                pendingFare = 0
            end
        end
    end)
end

-- ============ QUÉT XE ============
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

-- ============ TÌM XE ============
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

-- ============ NPC ĐI THEO XE ============
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
                        char = npcChar,
                        hum = oh,
                        seat = d,
                        offset = offset,
                        hrp = hrp,
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

local function updateNpcFollowers()
    pcall(safeRefreshNpc)
end

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

-- ============ CHỦ SỞ HỮU MẠNG ============
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

-- ============ GIỮ XE ĐỨNG YÊN ============
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
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
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

-- ============ GHẾ LÁI ============
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

-- TELE THẲNG VÀO TÂM GHẾ LÁI + ÉP SIT
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

    -- Vô hiệu ghế khác để engine không chọn nhầm
    local disabledList = {}
    for _, d in ipairs(car:GetDescendants()) do
        if d:IsA("VehicleSeat") and d ~= vs and not d.Disabled then
            local ok = pcall(function() d.Disabled = true end)
            if ok then table.insert(disabledList, d) end
        end
    end

    -- Tele vào TÂM ghế lái (offset 1 stud trên tâm)
    local hrp = root()
    if hrp then
        local centerCF = vs.CFrame * CFrame.new(0, 1, 0)
        pcall(function() hrp.CFrame = centerCF end)
        task.wait(0.05)
    end

    -- Ép sit
    pcall(function() vs:Sit(h) end)
    task.wait(0.12)
    pcall(function() h.AutoRotate = false end)
    pcall(function() h.Sit = true end)

    for i = 1, 3 do
        if h.Sit and h.SeatPart == vs then break end
        local hrpR = root()
        if hrpR then
            local cf = vs.CFrame * CFrame.new(0, 1, 0)
            pcall(function() hrpR.CFrame = cf end)
            task.wait(0.06)
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

    -- Khóa AutoRotate
    pcall(function() h.AutoRotate = false end)

    return h.Sit and h.SeatPart == vs
end

task.spawn(function()
    while true do
        task.wait(0.15)
        if enabled then
            local h = hum()
            local car = myCar or findMyCar()
            if h and car then
                local vs = getDriveSeat(car)
                if vs then
                    local wrongSeat = h.Sit and h.SeatPart and h.SeatPart ~= vs
                    local notSeated = not h.Sit
                    if wrongSeat then
                        setStatus("⚠ Ngồi sai ghế — nhảy ra ngồi lại")
                        pcall(function() h.Sit = false end)
                        task.wait(0.25)
                        for _ = 1, 6 do
                            if forceSeat() then break end
                            task.wait(0.25)
                        end
                    elseif notSeated and not flying then
                        forceSeat()
                    end
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
                pcall(function() h.AutoRotate = false end)
                return true
            end
            forceSeat()
        end
        task.wait(0.4)
    end
    return false
end

-- ============ NỔI LÊN MẶT ĐẤT ============
local function ascendToGround(car, target, targetFloor)
    if not car then return end
    setStatus("⬆ Nổi lên mặt đất +" .. tostring(LAND_OFFSET) .. " stud")

    local realFloor = floorBelow(target) or targetFloor
    local upTargetY = realFloor + LAND_OFFSET

    local cp = car:GetPivot()
    local rotOnly = cp - cp.Position
    local dest = Vector3.new(target.X, upTargetY, target.Z)
    pcall(function() car:PivotTo(CFrame.new(dest) * rotOnly) end)
    task.wait(0.15)
end

-- ============ BAY DƯỚI LÒNG ĐẤT ============
local function flyTo(target)
    stopHold()
    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return false end
    if not h.Sit then forceSeat(); task.wait(0.1) end
    pcall(function() h.AutoRotate = false end)

    local myChar = char()

    local targetFloor = floorBelow(target) or target.Y
    local underY = targetFloor - UNDERGROUND_DEPTH

    setStatus("⬇ Chuẩn bị bay dưới lòng đất")

    unanchorCar(car)
    task.wait(0.05)

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

    local startPivot = car:GetPivot()
    local rotOnly = startPivot - startPivot.Position  -- rotation khóa

    local curPos = startPivot.Position
    local downStepY = (underY - curPos.Y) / UNDER_DESCEND_STEPS
    for i = 1, UNDER_DESCEND_STEPS do
        curPos = Vector3.new(curPos.X, curPos.Y + downStepY, curPos.Z)
        local cf = CFrame.new(curPos) * rotOnly
        pcall(function() car:PivotTo(cf) end)
        task.wait(UNDER_STEP_TIME)
    end
    setStatus("⬇ Đang bay dưới lòng đất")

    local reached = false
    local lastNpcRefresh = 0
    local fakeVelCounter = 0

    while enabled do
        local c = myCar or findMyCar()
        if not c then break end

        local curP = c:GetPivot().Position
        local flat = Vector3.new(target.X - curP.X, 0, target.Z - curP.Z)
        local dist = flat.Magnitude

        if dist < ARRIVE_DIST then
            reached = true
            break
        end

        local dir = (dist > 0.01) and flat.Unit or Vector3.new(1, 0, 0)

        local spd
        if dist >= DECEL_DIST then
            spd = STEP_DIST
        else
            spd = math.max(STEP_DIST * dist / DECEL_DIST, 6)
        end

        local step = math.min(spd * TICK, dist, UNDER_STEP_MAX)

        local nextPos = Vector3.new(
            curP.X + dir.X * step,
            underY,
            curP.Z + dir.Z * step
        )
        -- Dùng rotOnly cố định → xe không xoay
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
    if not h2 or not h2.Sit then
        forceSeat()
        task.wait(0.2)
    end

    task.wait(0.15)
    return reached
end

-- ============ SPAWN XE ============
local function spawnAndSeat()
    if not SpawnCarEv then return false end
    if not selectedCar or selectedCar == "" then
        setStatus("⚠ Chưa chọn xe")
        return false
    end

    local car = findMyCar()
    if car and car:FindFirstChildWhichIsA("BasePart", true) then
        setStatus("◦ Xe đã có sẵn")
        if seatCar(10) then
            setStatus("◦ Sẵn sàng")
            return true
        end
    end

    setStatus("◦ Đang spawn xe")
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
        setStatus("⚠ Xe chưa hiện")
        return false
    end
    task.wait(1.5)

    if seatCar(15) then
        setStatus("◦ Sẵn sàng")
        task.wait(1)
        return true
    end
    setStatus("⚠ Ngồi ghế thất bại")
    return false
end

-- ============ KHỞI TẠO ============
local function doInit()
    setStatus("◦ Đang đổi nghề")
    fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(3)

    setStatus("◦ Spawn xe")
    if not spawnAndSeat() then return false end
    myCar = findMyCar()

    setStatus("◦ Bật online")
    fire(TaxiEvent, "GoOnline")
    task.wait(2)

    setStatus("◦ Sẵn sàng nhận đơn")
    return true
end

-- ============ CHUYẾN ĐI ============
local function runTrip()
    local h = hum()
    if not h or not h.Sit then
        setStatus("⚠ Hồi sinh xe")
        if not spawnAndSeat() then task.wait(5); return end
    end
    myCar = findMyCar()
    pcall(function() h.AutoRotate = false end)

    startHold()

    orderToken = nil
    pickupPos = nil
    dropPos = nil
    pendingFare = 0
    acceptingOrder = true
    setStatus("◦ Đang chờ đơn")

    local waitStart = os.time()
    local didReconnect = false
    local deadline = os.clock() + ORDER_TIMEOUT

    while os.clock() < deadline and enabled do
        if pickupPos then break end
        if not holdBV or not holdBV.Parent then
            startHold()
        end

        -- Nếu chờ > 15s chưa có đơn → off/on 1 lần
        if not didReconnect and (os.time() - waitStart) >= RECONNECT_AFTER then
            setStatus("◦ Chờ lâu — tắt/mở lại online")
            fire(TaxiEvent, "GoOffline")
            task.wait(1)
            fire(TaxiEvent, "GoOnline")
            didReconnect = true
        end

        task.wait(0.4)
    end

    acceptingOrder = false

    if not pickupPos then
        setStatus("⚠ Không có đơn")
        return
    end

    -- Đón khách
    setStatus("➤ Bay đón khách")
    flyTo(pickupPos)
    task.wait(0.3)
    forceSeat()
    setStatus("⌛ Đợi khách lên xe (4s)")
    task.wait(PICKUP_WAIT)

    -- Trả khách
    if dropPos then
        setStatus("➤ Bay trả khách")
        flyTo(dropPos)
        task.wait(0.3)
        forceSeat()
        setStatus("⌛ Đợi khách xuống xe (4s)")
        task.wait(DROP_WAIT)

        stats.trips = stats.trips + 1
        if pendingFare > 0 then
            stats.earn = stats.earn + pendingFare
        end
        pendingFare = 0
        setStatus("✓ Hoàn thành chuyến")

        -- Báo hoàn thành sau ACK_DELAY (3s)
        task.wait(ACK_DELAY)
        fire(TaxiEvent, "AckTripComplete")
        setStatus("✓ Đã báo hoàn thành — chờ đơn tiếp")
    end

    pickupPos = nil
    dropPos = nil
    orderToken = nil
    task.wait(0.3)
end

-- ============ VÒNG LẶP ============
local loopBusy = false
local function startLoop()
    if loopBusy then return end
    loopBusy = true
    task.spawn(function()
        setStatus("◦ Bắt đầu khởi tạo...")
        farmStartTime = os.time()

        local ok = pcall(doInit)
        initialized = ok

        if not initialized then
            loopBusy = false
            setStatus("⚠ Khởi tạo thất bại")
            return
        end

        while enabled do
            local ok, err = pcall(runTrip)
            if not ok then setStatus("⚠ Lỗi: " .. tostring(err):sub(1, 40)) end
            task.wait(1)
        end
        loopBusy = false
        setStatus("◦ TẮT")
    end)
end

-- ============ GIAO DIỆN ============
local cg = game:GetService("CoreGui")
if cg:FindFirstChild("RideGoFarmUI") then cg.RideGoFarmUI:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RideGoFarmUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = cg

-- Khung chính
local rootUI = Instance.new("Frame", gui)
rootUI.Size = UDim2.new(0, 290, 0, 148)
rootUI.Position = UDim2.new(0, 20, 0.5, -74)
rootUI.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
rootUI.BackgroundTransparency = 0.15  -- trong suốt nhẹ
rootUI.BorderSizePixel = 0
rootUI.Active = true
Instance.new("UICorner", rootUI).CornerRadius = UDim.new(0, 10)

local borderStroke = Instance.new("UIStroke", rootUI)
borderStroke.Color = Color3.fromRGB(255, 140, 40)
borderStroke.Thickness = 2

-- LED RGB viền
task.spawn(function()
    local hue = 0
    while true do
        task.wait(0.03)
        hue = (hue + 0.008) % 1
        pcall(function()
            borderStroke.Color = Color3.fromHSV(hue, 1, 1)
        end)
    end
end)

-- Tiêu đề
local title = Instance.new("TextLabel", rootUI)
title.Size = UDim2.new(1, -40, 0, 24)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "RIDEGO FARM"
title.TextColor3 = Color3.fromRGB(255, 140, 40)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

-- Nút ẩn/hiện
local eyeBtn = Instance.new("TextButton", rootUI)
eyeBtn.Size = UDim2.new(0, 24, 0, 20)
eyeBtn.Position = UDim2.new(1, -34, 0, 6)
eyeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
eyeBtn.Text = "−"
eyeBtn.TextColor3 = Color3.new(1,1,1)
eyeBtn.TextSize = 14
eyeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", eyeBtn).CornerRadius = UDim.new(0, 4)

-- ============ MENU CHÍNH (2 nút) ============
local mainMenu = Instance.new("Frame", rootUI)
mainMenu.Size = UDim2.new(1, -20, 0, 106)
mainMenu.Position = UDim2.new(0, 10, 0, 32)
mainMenu.BackgroundTransparency = 1
mainMenu.Visible = true

local carBtn = Instance.new("TextButton", mainMenu)
carBtn.Size = UDim2.new(1, 0, 0, 32)
carBtn.Position = UDim2.new(0, 0, 0, 0)
carBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
carBtn.Text = "🚗 CHỌN XE (0)"
carBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
carBtn.TextSize = 12
carBtn.Font = Enum.Font.GothamBold
carBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", carBtn).CornerRadius = UDim.new(0, 6)
local carBtnPad = Instance.new("UIPadding", carBtn)
carBtnPad.PaddingLeft = UDim.new(0, 10)

local farmBtn = Instance.new("TextButton", mainMenu)
farmBtn.Size = UDim2.new(1, 0, 0, 40)
farmBtn.Position = UDim2.new(0, 0, 0, 40)
farmBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
farmBtn.Text = "▶ BẮT ĐẦU FARM"
farmBtn.TextColor3 = Color3.new(1,1,1)
farmBtn.TextSize = 14
farmBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 7)

-- ============ PANEL STATUS (hiện khi farm) ============
local statusPanel = Instance.new("Frame", rootUI)
statusPanel.Size = UDim2.new(1, -20, 0, 106)
statusPanel.Position = UDim2.new(0, 10, 0, 32)
statusPanel.BackgroundTransparency = 1
statusPanel.Visible = false

local function makeStatusLabel(y)
    local lbl = Instance.new("TextLabel", statusPanel)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Position = UDim2.new(0, 0, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = ""
    lbl.TextColor3 = Color3.fromRGB(200, 220, 240)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local timeLbl   = makeStatusLabel(0)
local tripsLbl  = makeStatusLabel(18)
local earnLbl   = makeStatusLabel(36)
local carLbl    = makeStatusLabel(54)
local statusLbl = makeStatusLabel(74)

-- ============ PANEL DANH SÁCH XE ============
local carListPanel = Instance.new("Frame", rootUI)
carListPanel.Size = UDim2.new(1, -20, 0, 0)
carListPanel.Position = UDim2.new(0, 10, 0, 32)
carListPanel.BackgroundTransparency = 1
carListPanel.Visible = false

local scroll = Instance.new("ScrollingFrame", carListPanel)
scroll.Size = UDim2.new(1, 0, 0, 190)
scroll.Position = UDim2.new(0, 0, 0, 0)
scroll.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
scroll.BackgroundTransparency = 0.15
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
local uiHidden = false

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
        lbl.Text = "Chưa quét xe"
        lbl.TextColor3 = Color3.fromRGB(150, 160, 180)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium
        carBtn.Text = "🚗 CHỌN XE (0)"
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
            carOpen = false
            carListPanel.Visible = false
            carListPanel.Size = UDim2.new(1, -20, 0, 0)
            rootUI.Size = UDim2.new(0, 290, 0, 148)
            carBtn.Text = "🚗 CHỌN XE (" .. #carList .. ")"
            print("[RideGo] Đã chọn xe: " .. name)
        end)
    end
    carBtn.Text = "🚗 CHỌN XE (" .. #carList .. ")"
end

-- ============ NÚT CHỌN XE ============
carBtn.MouseButton1Click:Connect(function()
    if enabled then return end  -- đang farm thì không cho đổi
    carOpen = not carOpen
    carListPanel.Visible = carOpen
    mainMenu.Visible = not carOpen
    if carOpen then
        carListPanel.Size = UDim2.new(1, -20, 0, 190)
        rootUI.Size = UDim2.new(0, 290, 0, 232)
    else
        carListPanel.Size = UDim2.new(1, -20, 0, 0)
        rootUI.Size = UDim2.new(0, 290, 0, 148)
    end
end)

-- ============ NÚT ẨN/HIỆN ============
eyeBtn.MouseButton1Click:Connect(function()
    uiHidden = not uiHidden
    if uiHidden then
        mainMenu.Visible = false
        statusPanel.Visible = false
        carListPanel.Visible = false
        rootUI.Size = UDim2.new(0, 60, 0, 32)
        title.Visible = false
        eyeBtn.Position = UDim2.new(0, 6, 0, 6)
        eyeBtn.Text = "+"
    else
        rootUI.Size = UDim2.new(0, 290, 0, 148)
        title.Visible = true
        eyeBtn.Position = UDim2.new(1, -34, 0, 6)
        eyeBtn.Text = "−"
        if enabled then
            statusPanel.Visible = true
        else
            mainMenu.Visible = true
        end
    end
end)

-- ============ NÚT BẮT ĐẦU/DỪNG ============
farmBtn.MouseButton1Click:Connect(function()
    if enabled then
        -- Dừng + reset toàn bộ
        enabled = false
        resetState()
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

        farmBtn.Text = "▶ BẮT ĐẦU FARM"
        farmBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
        statusPanel.Visible = false
        mainMenu.Visible = true
        rootUI.Size = UDim2.new(0, 290, 0, 148)
        carBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 48)

        print("[RideGo] Đã DỪNG farm — reset toàn bộ")
    else
        -- Bắt đầu
        resetState()
        enabled = true
        farmStartTime = os.time()

        farmBtn.Text = "■ DỪNG FARM"
        farmBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        mainMenu.Visible = false
        carListPanel.Visible = false
        statusPanel.Visible = true
        rootUI.Size = UDim2.new(0, 290, 0, 148)

        print("[RideGo] BẮT ĐẦU farm")
        startLoop()
    end
end)

-- ============ VÒNG CẬP NHẬT STATUS ============
task.spawn(function()
    while true do
        task.wait(0.3)
        if enabled then
            local sec = os.time() - farmStartTime
            timeLbl.Text   = "⏱ Thời gian: " .. formatTime(sec)
            tripsLbl.Text  = "🚕 Chuyến: " .. tostring(stats.trips)
            earnLbl.Text   = "💰 Kiếm: Rp " .. tostring(stats.earn)
            carLbl.Text    = "🚗 Xe: " .. ((selectedCar ~= "" and selectedCar:sub(1, 24)) or "(chưa chọn)")
            statusLbl.Text = "📍 " .. curStatus
        end
    end
end)

-- ============ KÉO UI ============
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

-- ============ TỰ QUÉT XE ============
task.spawn(function()
    task.wait(1)
    scanCars()
    if #carList > 0 and (not selectedCar or selectedCar == "") then
        selectedCar = carList[1]
    end
    renderCars()
    print("[RideGo] Đã quét được " .. #carList .. " xe")
end)

print("[RideGo] Đã load v26")
