-- language: Luau, executor: Delta
-- RideGo Farm — standalone, không liên quan hub chính.
-- Flow: change job → go online → spawn xe → ngồi → đợi order → accept
--       → tele PickupPos → đợi pickup → tele DropPos → đợi drop → loop

local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ============ CONFIG ============
local CAR_NAME      = "Hando-CBR600RRGP(2018)(NSTRSpec)"
local PICKUP_WAIT   = 4
local DROP_WAIT     = 6
local LOOP_DELAY    = 2
local ORDER_TIMEOUT = 30

-- ============ STATE ============
local enabled    = false
local orderToken = nil
local pickupPos  = nil
local dropPos    = nil
local myCar      = nil
local stats = { trips = 0, earn = 0 }

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

-- ============ HOOK TAXI EVENTS ============
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
local function char()
    return lp.Character
end
local function root()
    local c = char()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function hum()
    local c = char()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function fire(remote, ...)
    if not remote then return false end
    local ok = pcall(function() remote:FireServer(...) end)
    return ok
end

local function teleportTo(pos)
    if not pos then return false end
    local c = char()
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if h and h.SeatPart then
        local car = h.SeatPart:FindFirstAncestorOfClass("Model")
        if car then
            pcall(function() car:PivotTo(CFrame.new(pos)) end)
            task.wait(0.35)
            return true
        end
    end

    hrp.CFrame = CFrame.new(pos)
    task.wait(0.35)
    return true
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

local function waitMyCar(timeout)
    local deadline = os.clock() + (timeout or 12)
    while os.clock() < deadline do
        local car = findMyCar()
        if car then return car end
        task.wait(0.4)
    end
    return nil
end

local function spawnCar()
    if not SpawnCarEv then return false end
    return fire(SpawnCarEv, CAR_NAME)
end

-- ============ FLOW ============
local function changeJob()
    fire(TeamChangeRequest, "RideGO Driver", 11378976, 1, 0, "Detector")
end
local function goOnline()
    fire(TaxiEvent, "GoOnline")
end
local function acceptOrder(token)
    if not token then return false end
    return fire(TaxiEvent, "AcceptOrder", token)
end

-- ============ MAIN LOOP ============
local loopBusy = false

local function runOnce()
    changeJob()
    task.wait(2.5)

    goOnline()
    task.wait(2)

    myCar = findMyCar()
    if not myCar then
        spawnCar()
        myCar = waitMyCar(12)
        if not myCar then return end
    end

    local h = hum()
    if h and not h.Sit then
        for _, d in ipairs(myCar:GetDescendants()) do
            if d:IsA("VehicleSeat") or d:IsA("Seat") then
                pcall(function() d:Sit(h) end)
                task.wait(0.6)
                if h.Sit then break end
            end
        end
    end

    orderToken = nil
    local deadline = os.clock() + ORDER_TIMEOUT
    local onlineLast = os.clock()
    while os.clock() < deadline and enabled do
        if orderToken then
            acceptOrder(orderToken)
            break
        end
        if os.clock() - onlineLast > 15 then
            goOnline()
            onlineLast = os.clock()
        end
        task.wait(0.4)
    end

    deadline = os.clock() + 8
    while os.clock() < deadline and enabled do
        if pickupPos then break end
        task.wait(0.2)
    end
    if not pickupPos then return end

    teleportTo(pickupPos)
    task.wait(PICKUP_WAIT)

    if dropPos then
        teleportTo(dropPos)
        task.wait(DROP_WAIT)
    end

    pickupPos = nil
    dropPos = nil
    orderToken = nil
end

local function startLoop()
    if loopBusy then return end
    loopBusy = true
    task.spawn(function()
        while enabled do
            local ok, err = pcall(runOnce)
            if not ok then
                warn("[ridego] err: " .. tostring(err))
            end
            task.wait(LOOP_DELAY)
        end
        loopBusy = false
    end)
end

-- ============ GUI ============
local cg = game:GetService("CoreGui")
if cg:FindFirstChild("RideGoFarmUI") then cg.RideGoFarmUI:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RideGoFarmUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = cg

local rootUI = Instance.new("Frame", gui)
rootUI.Size = UDim2.new(0, 240, 0, 130)
rootUI.Position = UDim2.new(0, 20, 0.5, -65)
rootUI.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
rootUI.BorderSizePixel = 0
rootUI.Active = true
Instance.new("UICorner", rootUI).CornerRadius = UDim.new(0, 10)
local rs0 = Instance.new("UIStroke", rootUI)
rs0.Color = Color3.fromRGB(255, 140, 40)
rs0.Thickness = 1.5

local title = Instance.new("TextLabel", rootUI)
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "◈ RIDEGO FARM"
title.TextColor3 = Color3.fromRGB(255, 140, 40)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local statLbl = Instance.new("TextLabel", rootUI)
statLbl.Size = UDim2.new(1, -16, 0, 40)
statLbl.Position = UDim2.new(0, 8, 0, 30)
statLbl.BackgroundTransparency = 1
statLbl.Text = "trips: 0 | earn: 0\nstate: OFF"
statLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
statLbl.TextSize = 10
statLbl.Font = Enum.Font.Code
statLbl.TextXAlignment = Enum.TextXAlignment.Left
statLbl.TextYAlignment = Enum.TextYAlignment.Top

local toggleBtn = Instance.new("TextButton", rootUI)
toggleBtn.Size = UDim2.new(1, -16, 0, 30)
toggleBtn.Position = UDim2.new(0, 8, 0, 76)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
toggleBtn.Text = "▶ BẮT ĐẦU FARM"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 7)

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
            "trips: %d | earn: %d\nstate: %s",
            stats.trips, stats.earn,
            enabled and ((myCar or findMyCar()) and "car OK" or "finding car") or "OFF"
        )
    end
end)

-- ============ DRAG ============
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

print("[ridego] loaded — tap START để chạy")
