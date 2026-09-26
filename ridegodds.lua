-- language: Luau, executor: Delta
-- RideGo Farm — FINAL v25
-- Mode UNDERGROUND: CFrame-only, Y co dinh duoi dat, khong dam building, khong void.
-- Mode AUTO/NORMAL/HIGH: BodyVelocity + void scan da huong.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ============ CONFIG ============
local STEP_DIST         = 180
local CRUISE_Y          = 18
local VOID_LOOKAHEAD    = 260
local VOID_DROP_MIN     = 300
local VOID_SCAN_MIN     = 200
local VOID_SCAN_MAX     = 100000
local VOID_SCAN_STEP    = 300
local MAX_CFRAME_DIST   = 10000
local ARRIVE_DIST       = 8
local ORDER_TIMEOUT     = 60
local PICKUP_WAIT       = 8
local DROP_WAIT         = 8
local DECEL_DIST        = 200
local TICK              = 0.05
local LAND_OFFSET       = 2
local MAX_GROUND_FLY    = 280
local UNDERGROUND_DEPTH = 120
local HIGH_EXTRA        = 80
local SURROUND_RADIUS   = 220
local SURROUND_HIGH_MARGIN = 30
local BUILDING_MIN_H    = 8
local VOID_SCAN_COOLDOWN = 0.8
local UNDER_STEP_MAX    = 60
local UNDER_DESCEND_STEPS = 12
local UNDER_ASCEND_STEPS = 12
local UNDER_STEP_TIME   = 0.03

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
local flyModeOverride = "auto"

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

local function isLocalPlayerHum(oh)
    if not oh or not oh.Parent then return false end
    return oh.Parent == char()
end

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

local function makeOverlapParams()
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ign = {}
    local c = char()
    if c then table.insert(ign, c) end
    local car = myCar or findMyCar()
    if car then table.insert(ign, car) end
    params.FilterDescendantsInstances = ign
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

-- ============ NPC FOLLOWERS ============
local npcFollowers = {}
local npcRenderConn = nil

local function safeRefreshNpc()
    for _, f in ipairs(npcFollowers) do
        if not f then continue end
        pcall(function()
            if not f.char or not f.char.Parent then return end
            if not f.seat or not f.seat.Parent then return end
            if not f.hrp or not f.hrp.Parent then return end

            if not f.hrp.Anchored then
                f.hrp.Anchored = true
            end
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

-- ============ NETWORK OWNER ============
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

-- ============ ANCHOR ============
local function anchorCar(car)
    if not car then return end
    for _, p in ipairs(car:GetDescendants()) do
        if p:IsA("BasePart") and not p.Anchored then
            pcall(function() p.Anchored = true end)
        end
    end
end

local function unanchorCar(car)
    if not car then return end
    for _, p in ipairs(car:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.Anchored = false end)
        end
    end
end

-- ============ NOCLIP CHASSIS ============
local KEEP_COLLIDE = {
    chassis = true, frame = true, base = true,
    wheel = true, tire = true, tyre = true,
    body = true, hull = true, floor = true, under = true,
}

local function isChassisPart(part)
    local n = part.Name:lower()
    for key in pairs(KEEP_COLLIDE) do
        if n:find(key, 1, true) then return true end
    end
    return false
end

local function chassisCollideOn(car)
    if not car then return end
    for _, p in ipairs(car:GetDescendants()) do
        if p:IsA("BasePart") then
            if isChassisPart(p) then
                if not p.CanCollide then pcall(function() p.CanCollide = true end) end
            else
                if p.CanCollide then pcall(function() p.CanCollide = false end) end
            end
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

local function forceSeat()
    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return false end
    local vs = getDriveSeat(car)
    if not vs then return false end

    if h.Sit and h.SeatPart == vs then return true end

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
        local seatCF = vs.CFrame * CFrame.new(0, 2.5, 0)
        pcall(function() hrp.CFrame = seatCF end)
        task.wait(0.08)
    end

    pcall(function() vs:Sit(h) end)
    task.wait(0.12)

    for i = 1, 3 do
        if h.Sit and h.SeatPart == vs then break end
        local hrpR = root()
        if hrpR then
            local seatCFR = vs.CFrame * CFrame.new(0, 3, 0)
            pcall(function() hrpR.CFrame = seatCFR end)
            task.wait(0.08)
        end
        pcall(function() vs:Sit(h) end)
        task.wait(0.12)
        if not h.Sit then
            pcall(function() h.Sit = true end)
            task.wait(0.08)
        end
    end

    for _, d in ipairs(disabledList) do
        pcall(function() d.Disabled = false end)
    end

    return h.Sit and h.SeatPart == vs
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if enabled and not flying then
            local h = hum()
            local car = myCar or findMyCar()
            if h and car then
                local vs = getDriveSeat(car)
                if vs then
                    if h.Sit and h.SeatPart and h.SeatPart ~= vs then
                        setState("sai ghe - tu dong seat lai")
                        pcall(function() h.Sit = false end)
                        task.wait(0.25)
                        for attempt = 1, 5 do
                            if forceSeat() then break end
                            task.wait(0.3)
                        end
                    elseif not h.Sit then
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
                return true
            end
            forceSeat()
        end
        task.wait(0.4)
    end
    return false
end

-- ============ VOID ============
local function pointIsVoid(px, py, pz)
    local params = makeRayParams()
    local origin = Vector3.new(px, py + 30, pz)
    local hit = workspace:Raycast(origin, Vector3.new(0, -VOID_DROP_MIN - 100, 0), params)
    if not hit then return true end
    if hit.Position.Y < py - VOID_DROP_MIN then return true end
    return false
end

local function voidOnPath(curPos, dir)
    for _, frac in ipairs({0.4, 0.7, 1.0}) do
        local d = VOID_LOOKAHEAD * frac
        local px = curPos.X + dir.X * d
        local pz = curPos.Z + dir.Z * d
        if pointIsVoid(px, curPos.Y, pz) then
            return true
        end
    end
    return false
end

local function scanVoidLandingMulti(curPos, dir)
    local params = makeRayParams()
    local angles = {0, 15, -15, 30, -30, 45, -45, 60, -60, 80, -80}
    local best = nil

    for _, deg in ipairs(angles) do
        local rad = math.rad(deg)
        local cosA, sinA = math.cos(rad), math.sin(rad)
        local nd = Vector3.new(
            dir.X * cosA - dir.Z * sinA,
            0,
            dir.X * sinA + dir.Z * cosA
        )
        if nd.Magnitude > 0.01 then
            nd = nd.Unit
            local dist = VOID_SCAN_MIN
            while dist <= VOID_SCAN_MAX do
                local px = curPos.X + nd.X * dist
                local pz = curPos.Z + nd.Z * dist
                local origin = Vector3.new(px, curPos.Y + 500, pz)
                local hit = workspace:Raycast(origin, Vector3.new(0, -3000, 0), params)
                if hit and hit.Position.Y > -50 then
                    local score = dist + math.abs(deg) * 15
                    if not best or score < best.score then
                        best = {
                            dist = dist,
                            floorY = hit.Position.Y,
                            dir = nd,
                            deg = deg,
                            score = score,
                        }
                    end
                    break
                end
                dist = dist + VOID_SCAN_STEP
            end
        end
    end
    return best
end

-- ============ SURROUND SCAN ============
local function scanSurroundHeight(targetPos)
    local params = makeOverlapParams()
    local boxSize = Vector3.new(SURROUND_RADIUS * 2, 900, SURROUND_RADIUS * 2)
    local boxCF = CFrame.new(targetPos + Vector3.new(0, 250, 0))

    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInBox(boxCF, boxSize, params)
    end)
    if not ok or not parts then return nil end

    local targetFloorY = floorBelow(targetPos) or targetPos.Y
    local maxTop = nil

    for _, p in ipairs(parts) do
        if p:IsA("BasePart") then
            local topY = p.Position.Y + (p.Size.Y / 2)
            if topY > targetFloorY + BUILDING_MIN_H then
                if not maxTop or topY > maxTop then maxTop = topY end
            end
        end
    end
    return maxTop
end

-- ============ DESCEND ============
local function descendAndLand(car, target, cruiseY, flyMode, bv, bg)
    if not car then return end
    setState("ha xuong")

    if bv and bv.Parent then
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(0, 0, 0)
    end

    anchorCar(car)
    task.wait(0.08)

    if bv and bv.Parent then bv:Destroy() end
    if bg and bg.Parent then bg:Destroy() end
    task.wait(0.05)

    local pivotPos = car:GetPivot().Position
    local params = makeRayParams()
    local origin = Vector3.new(target.X, pivotPos.Y + 100, target.Z)
    local hit = workspace:Raycast(origin, Vector3.new(0, -3000, 0), params)

    if not hit then
        setState("khong thay dat - giu anchor")
        return
    end

    local bbCF, bbSize = car:GetBoundingBox()
    local bbCenter = bbCF.Position
    local bbBottomOffset = bbSize.Y / 2
    local targetCenterY = hit.Position.Y + bbBottomOffset + LAND_OFFSET
    local offsetPivotToCenterY = bbCenter.Y - pivotPos.Y
    local targetPivotY = targetCenterY - offsetPivotToCenterY

    local curPivotCF = car:GetPivot()
    local curPos = curPivotCF.Position
    local rot = curPivotCF - curPos
    local finalPos = Vector3.new(target.X, targetPivotY, target.Z)
    pcall(function() car:PivotTo(CFrame.new(finalPos) * rot) end)
    task.wait(0.15)

    unanchorCar(car)
    task.wait(0.08)
    chassisCollideOn(car)
end

-- ============ FLY UNDERGROUND (CFrame-only) ============
local function flyUnderground(target)
    stopHold()
    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return false end
    if not h.Sit then forceSeat(); task.wait(0.1) end

    local myChar = char()

    local targetFloor = floorBelow(target) or target.Y
    local underY = targetFloor - UNDERGROUND_DEPTH

    setState("under - chuan bi")

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
    local rotOnly = startPivot - startPivot.Position

    -- Di xuong duoi dat bang nhieu step nho
    local curPos = startPivot.Position
    local downStepY = (underY - curPos.Y) / UNDER_DESCEND_STEPS
    for i = 1, UNDER_DESCEND_STEPS do
        curPos = Vector3.new(curPos.X, curPos.Y + downStepY, curPos.Z)
        local cf = CFrame.new(curPos) * rotOnly
        pcall(function() car:PivotTo(cf) end)
        task.wait(UNDER_STEP_TIME)
    end
    setState("under - bay")

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
        local nextCF = CFrame.new(nextPos) * rotOnly
        pcall(function() c:PivotTo(nextCF) end)

        -- Fake velocity nhe cho game doc duong di
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

    -- ===== ASCEND: noi len mat dat =====
    car = myCar or findMyCar()
    if car and reached then
        setState("under - noi len")
        local ascendSteps = UNDER_ASCEND_STEPS
        local curPivot = car:GetPivot()
        local curP = curPivot.Position
        local rot = curPivot - curP
        local upTargetY = targetFloor + CRUISE_Y
        local upStepY = (upTargetY - curP.Y) / ascendSteps

        for i = 1, ascendSteps do
            curP = Vector3.new(curP.X, curP.Y + upStepY, curP.Z)
            pcall(function() car:PivotTo(CFrame.new(curP) * rot) end)
            task.wait(UNDER_STEP_TIME)
        end

        task.wait(0.1)

        descendAndLand(car, target, CRUISE_Y, "normal", nil, nil)
    end

    detachNpcFollowers()

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

-- ============ FLY (BodyVelocity) ============
local function flyTo(target)
    -- UNDERGROUND -> ham rieng, khong BodyVelocity
    if flyModeOverride == "underground" then
        return flyUnderground(target)
    end

    -- AUTO: neu scan thay building qua cao -> cung dung underground
    if flyModeOverride == "auto" then
        local surroundTop = scanSurroundHeight(target)
        local targetFloor = floorBelow(target) or target.Y
        if surroundTop then
            local buildingH = surroundTop - targetFloor
            if buildingH > MAX_GROUND_FLY then
                return flyUnderground(target)
            end
        end
    end

    stopHold()
    local h = hum()
    local car = myCar or findMyCar()
    if not h or not car then return false end
    if not h.Sit then forceSeat(); task.wait(0.1) end

    local myChar = char()

    setState("quet vung")
    local flyMode = "normal"
    local cruiseY = CRUISE_Y

    if flyModeOverride ~= "auto" then
        flyMode = flyModeOverride
        if flyMode == "high" then
            cruiseY = HIGH_EXTRA
        elseif flyMode == "underground" then
            cruiseY = -UNDERGROUND_DEPTH
        end
        setState("bay: " .. flyMode .. " (manual)")
    else
        local surroundTop = scanSurroundHeight(target)
        local targetFloor = floorBelow(target) or target.Y
        if surroundTop then
            local buildingH = surroundTop - targetFloor
            if buildingH > MAX_GROUND_FLY then
                flyMode = "underground"
                cruiseY = -UNDERGROUND_DEPTH
            elseif buildingH > 30 then
                flyMode = "high"
                cruiseY = buildingH + SURROUND_HIGH_MARGIN
            end
        end
        setState("bay: " .. flyMode .. " (auto)")
    end

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

    local bv = Instance.new("BodyVelocity")
    bv.Name = "RGFly"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.P = 5000
    bv.Velocity = Vector3.zero
    bv.Parent = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)

    local bg = Instance.new("BodyGyro")
    bg.Name = "RGGyro"
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P = 5000
    bg.D = 500
    bg.Parent = bv.Parent

    local reached = false
    local ownerRefreshCounter = 0
    local lastVoidScan = 0

    while enabled do
        local ok, loopErr = pcall(function()
            local c = myCar or findMyCar()
            if not c then return "break" end

            local curPos = c:GetPivot().Position
            local flat = Vector3.new(target.X - curPos.X, 0, target.Z - curPos.Z)
            local dist = flat.Magnitude

            if dist < ARRIVE_DIST then
                reached = true
                return "break"
            end

            local dir = (dist > 0.01) and flat.Unit or Vector3.new(1, 0, 0)

            local nextStep = TICK * STEP_DIST * 1.5
            local probeAheadX = curPos.X + dir.X * math.max(nextStep, 40)
            local probeAheadZ = curPos.Z + dir.Z * math.max(nextStep, 40)

            local blocked = false
            if pointIsVoid(probeAheadX, curPos.Y, probeAheadZ) then
                blocked = true
            end
            if not blocked then
                if voidOnPath(curPos, dir) then blocked = true end
            end

            if blocked and os.clock() - lastVoidScan > VOID_SCAN_COOLDOWN then
                lastVoidScan = os.clock()
                setState("void - quet da huong")
                bv.Velocity = Vector3.zero

                local landing = scanVoidLandingMulti(curPos, dir)
                if landing and landing.dist <= MAX_CFRAME_DIST then
                    local landPos = curPos + landing.dir * landing.dist
                    local destY
                    if flyMode == "underground" then
                        destY = landing.floorY - UNDERGROUND_DEPTH
                    else
                        destY = landing.floorY + cruiseY
                    end
                    anchorCar(c)
                    local dest = Vector3.new(landPos.X, destY, landPos.Z)
                    local startPivot = c:GetPivot()
                    local rot = startPivot - startPivot.Position
                    c:PivotTo(CFrame.new(dest) * rot)
                    task.wait(0.08)
                    unanchorCar(c)
                    claimNetworkOwner(c)
                    setState(string.format("void-CFrame%.0f/%d°", landing.dist, landing.deg))
                    task.wait(0.3)
                    return "continue"
                else
                    setState("void - bay tiep")
                end
            end

            local floorY = floorBelow(curPos) or (curPos.Y - math.abs(cruiseY))
            local targetY
            if flyMode == "underground" then
                targetY = floorY - UNDERGROUND_DEPTH
            else
                targetY = floorY + cruiseY
            end

            bg.CFrame = CFrame.lookAt(curPos, Vector3.new(target.X, curPos.Y, target.Z))

            local spd
            if dist >= DECEL_DIST then
                spd = STEP_DIST
            else
                spd = math.max(STEP_DIST * dist / DECEL_DIST, 6)
            end
            local vx = dir.X * spd
            local vz = dir.Z * spd
            local dy = targetY - curPos.Y
            local vy = math.clamp(dy * 4, -50, 50)

            bv.Velocity = Vector3.new(vx, vy, vz)

            updateNpcFollowers()

            ownerRefreshCounter = ownerRefreshCounter + 1
            if ownerRefreshCounter >= 10 then
                ownerRefreshCounter = 0
                claimNetworkOwner(c)
            end

            return "tick"
        end)

        if not ok then
            setState("ERR loop: " .. tostring(loopErr):sub(1, 50))
            task.wait(0.2)
        elseif loopErr == "break" then
            break
        end

        task.wait(TICK)
    end

    car = myCar or findMyCar()
    pcall(function() descendAndLand(car, target, cruiseY, flyMode, bv, bg) end)
    pcall(detachNpcFollowers)

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
rootUI.Size = UDim2.new(0, 280, 0, 184)
rootUI.Position = UDim2.new(0, 20, 0.5, -92)
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

local modeBtn = Instance.new("TextButton", rootUI)
modeBtn.Size = UDim2.new(1, -16, 0, 26)
modeBtn.Position = UDim2.new(0, 8, 0, 114)
modeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
modeBtn.Text = "MODE: AUTO"
modeBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
modeBtn.TextSize = 11
modeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 6)

local carHeader = Instance.new("TextButton", rootUI)
carHeader.Size = UDim2.new(1, -16, 0, 26)
carHeader.Position = UDim2.new(0, 8, 0, 146)
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
carBody.Position = UDim2.new(0, 8, 0, 178)
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
        rootUI.Size = UDim2.new(0, 280, 0, 384)
    else
        carBody.Size = UDim2.new(1, -16, 0, 0)
        rootUI.Size = UDim2.new(0, 280, 0, 184)
    end
    carHeader.Text = (carOpen and "v " or "> ") .. "CHON XE (" .. #carList .. ")"
end)

local modeTexts = {
    auto = "MODE: AUTO",
    normal = "MODE: NORMAL (thap)",
    high = "MODE: HIGH (cao)",
    underground = "MODE: UNDER (CFrame duoi dat)",
}
local modeOrder = {"auto", "normal", "high", "underground"}
local modeColors = {
    auto = Color3.fromRGB(60, 40, 100),
    normal = Color3.fromRGB(30, 90, 60),
    high = Color3.fromRGB(100, 70, 20),
    underground = Color3.fromRGB(80, 30, 30),
}

modeBtn.MouseButton1Click:Connect(function()
    local idx = 1
    for i, m in ipairs(modeOrder) do
        if m == flyModeOverride then idx = i; break end
    end
    idx = idx + 1
    if idx > #modeOrder then idx = 1 end
    flyModeOverride = modeOrder[idx]
    modeBtn.Text = modeTexts[flyModeOverride]
    modeBtn.BackgroundColor3 = modeColors[flyModeOverride]
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
        detachNpcFollowers()
        local car = myCar or findMyCar()
        if car then
            unanchorCar(car)
            for _, p in ipairs(car:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.CanCollide = true end)
                end
            end
        end
        local c = char()
        if c then fullCollideOn(c) end
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

print("[ridego] loaded v25")
