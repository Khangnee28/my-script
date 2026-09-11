-- KhangLe Custom Tuner - Part 1 (UI & Vehicle Tuner)
getgenv().KhangLeTuner = getgenv().KhangLeTuner or {}
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("KhangLeCustomTuner") then
    PlayerGui.KhangLeCustomTuner:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KhangLeCustomTuner"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

getgenv().KhangLeTuner.ScreenGui = ScreenGui

-- Nút mở menu chính 🚀
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 40, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
ToggleBtn.Text = "🚀"
ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local c1 = Instance.new("UICorner", ToggleBtn) c1.CornerRadius = UDim.new(1, 0)
local s1 = Instance.new("UIStroke", ToggleBtn) s1.Color = Color3.fromRGB(0, 255, 120) s1.Thickness = 2

-- Nút nổi Auto T 🕹️
local AutoTFloatingBtn = Instance.new("TextButton")
AutoTFloatingBtn.Size = UDim2.new(0, 50, 0, 50)
AutoTFloatingBtn.Position = UDim2.new(0, 40, 0.50, 0)
AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
AutoTFloatingBtn.TextColor3 = Color3.fromRGB(255, 100, 0)
AutoTFloatingBtn.Text = "🕹️"
AutoTFloatingBtn.TextSize = 22
AutoTFloatingBtn.Font = Enum.Font.GothamBold
AutoTFloatingBtn.Draggable = true
AutoTFloatingBtn.Visible = false
AutoTFloatingBtn.Parent = ScreenGui
getgenv().KhangLeTuner.AutoTFloatingBtn = AutoTFloatingBtn

local c2 = Instance.new("UICorner", AutoTFloatingBtn) c2.CornerRadius = UDim.new(1, 0)
local s2 = Instance.new("UIStroke", AutoTFloatingBtn) s2.Color = Color3.fromRGB(255, 100, 0) s2.Thickness = 2

-- Khung Giao Diện Chính
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 460)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
getgenv().KhangLeTuner.MainFrame = MainFrame

local c3 = Instance.new("UICorner", MainFrame) c3.CornerRadius = UDim.new(0, 14)
local s3 = Instance.new("UIStroke", MainFrame) s3.Color = Color3.fromRGB(45, 45, 45) s3.Thickness = 1.8

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "👑 KhangLe Tuner (Part 1 Loaded)"
Title.TextColor3 = Color3.fromRGB(0, 255, 120)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold

-- Hệ thống Tab
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(0.9, 0, 0, 30)
TabContainer.Position = UDim2.new(0.05, 0, 0, 45)
TabContainer.BackgroundTransparency = 1

local Tab1Btn = Instance.new("TextButton", TabContainer)
Tab1Btn.Size = UDim2.new(0.48, 0, 1, 0)
Tab1Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Tab1Btn.Text = "🚗 Độ Xe & T"
Tab1Btn.TextSize = 11
Tab1Btn.Font = Enum.Font.GothamBold
local cT1 = Instance.new("UICorner", Tab1Btn) cT1.CornerRadius = UDim.new(0, 6)

local Tab2Btn = Instance.new("TextButton", TabContainer)
Tab2Btn.Size = UDim2.new(0.48, 0, 1, 0)
Tab2Btn.Position = UDim2.new(0.52, 0, 0, 0)
Tab2Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Tab2Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
Tab2Btn.Text = "💼 Rajawali Farm & Khác"
Tab2Btn.TextSize = 11
Tab2Btn.Font = Enum.Font.GothamBold
local cT2 = Instance.new("UICorner", Tab2Btn) cT2.CornerRadius = UDim.new(0, 6)

-- Trang 1 (Độ xe)
local Page1 = Instance.new("Frame", MainFrame)
Page1.Size = UDim2.new(1, 0, 0, 365)
Page1.Position = UDim2.new(0, 0, 0, 85)
Page1.BackgroundTransparency = 1
Page1.Visible = true
getgenv().KhangLeTuner.Page1 = Page1

local function createInput(name, defaultVal, posY)
    local lbl = Instance.new("TextLabel", Page1)
    lbl.Size = UDim2.new(0.9, 0, 0, 16)
    lbl.Position = UDim2.new(0.05, 0, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", Page1)
    box.Size = UDim2.new(0.9, 0, 0, 26)
    box.Position = UDim2.new(0.05, 0, 0, posY + 16)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultVal)
    box.TextSize = 12
    box.Font = Enum.Font.GothamBold
    box.BorderSizePixel = 0
    local c = Instance.new("UICorner", box) c.CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", box) s.Color = Color3.fromRGB(50, 50, 50) s.Thickness = 1
    return box
end

getgenv().KhangLeTuner.hpBox = createInput("💪 Hệ số Mã lực", "5.0", 0)
getgenv().KhangLeTuner.rpmBox = createInput("🔥 Cộng thêm Tua máy", "8000", 50)
getgenv().KhangLeTuner.gearRatioBox = createInput("⚙️ Tỷ số truyền số", "0.8", 100)
getgenv().KhangLeTuner.finalDriveBox = createInput("⛓️ Tỷ số truyền cuối", "0.8", 150)

local Status = Instance.new("TextLabel", Page1)
Status.Size = UDim2.new(0.9, 0, 0, 26)
Status.Position = UDim2.new(0.05, 0, 0, 202)
Status.BackgroundTransparency = 1
Status.Text = "Trạng thái: Sẵn sàng độ xe."
Status.TextColor3 = Color3.fromRGB(255, 200, 0)
Status.TextSize = 11
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Center
getgenv().KhangLeTuner.Status = Status

local InjectBtn = Instance.new("TextButton", Page1)
InjectBtn.Size = UDim2.new(0.9, 0, 0, 32)
InjectBtn.Position = UDim2.new(0.05, 0, 0, 232)
InjectBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
InjectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
InjectBtn.Text = "⚡ Áp Dụng (Tức Thì)"
InjectBtn.TextSize = 11
InjectBtn.Font = Enum.Font.GothamBold
local c4 = Instance.new("UICorner", InjectBtn) c4.CornerRadius = UDim.new(0, 8)
getgenv().KhangLeTuner.InjectBtn = InjectBtn

local ToggleFloatMenuBtn = Instance.new("TextButton", Page1)
ToggleFloatMenuBtn.Size = UDim2.new(0.9, 0, 0, 32)
ToggleFloatMenuBtn.Position = UDim2.new(0.05, 0, 0, 272)
ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleFloatMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleFloatMenuBtn.Text = "🕹️ Hiện Nút Nổi Auto T: ĐANG TẮT"
ToggleFloatMenuBtn.TextSize = 11
ToggleFloatMenuBtn.Font = Enum.Font.GothamBold
local c5 = Instance.new("UICorner", ToggleFloatMenuBtn) c5.CornerRadius = UDim.new(0, 8)
getgenv().KhangLeTuner.ToggleFloatMenuBtn = ToggleFloatMenuBtn

-- Trang 2 Container
local Page2 = Instance.new("Frame", MainFrame)
Page2.Size = UDim2.new(1, 0, 0, 365)
Page2.Position = UDim2.new(0, 0, 0, 85)
Page2.BackgroundTransparency = 1
Page2.Visible = false
getgenv().KhangLeTuner.Page2 = Page2

Tab1Btn.MouseButton1Click:Connect(function()
    Page1.Visible = true
    Page2.Visible = false
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Tab2Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
end)

Tab2Btn.MouseButton1Click:Connect(function()
    Page1.Visible = false
    Page2.Visible = true
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    Tab2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Tab1Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
end)
-- KhangLe Custom Tuner - Part 2 (Farm, Auto Job & Loops)
local tuner = getgenv().KhangLeTuner
if not tuner or not tuner.Page2 then
    warn("Vui lòng chạy Part 1 trước!")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Page2 = tuner.Page2

-- Nút Bật Rajawali Office Farm
local OfficeFarmBtn = Instance.new("TextButton", Page2)
OfficeFarmBtn.Size = UDim2.new(0.9, 0, 0, 36)
OfficeFarmBtn.Position = UDim2.new(0.05, 0, 0, 10)
OfficeFarmBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
OfficeFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OfficeFarmBtn.Text = "💼 Rajawali Office Farm: TẮT"
OfficeFarmBtn.TextSize = 11
OfficeFarmBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OfficeFarmBtn).CornerRadius = UDim.new(0, 8)

-- Nút Tự Động Đổi Nghề
local AutoJobBtn = Instance.new("TextButton", Page2)
AutoJobBtn.Size = UDim2.new(0.9, 0, 0, 36)
AutoJobBtn.Position = UDim2.new(0.05, 0, 0, 52)
AutoJobBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
AutoJobBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoJobBtn.Text = "👔 Tự Động Đổi Nghề (Office Worker): TẮT"
AutoJobBtn.TextSize = 10
AutoJobBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AutoJobBtn).CornerRadius = UDim.new(0, 8)

-- Nút Anti-AFK
local AntiAfkBtn = Instance.new("TextButton", Page2)
AntiAfkBtn.Size = UDim2.new(0.9, 0, 0, 36)
AntiAfkBtn.Position = UDim2.new(0.05, 0, 0, 94)
AntiAfkBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
AntiAfkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AntiAfkBtn.Text = "🛡️ Anti-AFK: ĐANG BẬT"
AntiAfkBtn.TextSize = 11
AntiAfkBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AntiAfkBtn).CornerRadius = UDim.new(0, 8)

local OfficeInfo = Instance.new("TextLabel", Page2)
OfficeInfo.Size = UDim2.new(0.9, 0, 0, 110)
OfficeInfo.Position = UDim2.new(0.05, 0, 0, 136)
OfficeInfo.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
OfficeInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
OfficeInfo.Text = "💡 ĐÃ CHIA 2 PHẦN THÀNH CÔNG:\n- Phần 1 & 2 đã liên kết hoàn tất.\n- Bật Rajawali Farm & Auto Đổi Nghề ở đây."
OfficeInfo.TextSize = 11
OfficeInfo.Font = Enum.Font.Gotham
OfficeInfo.TextXAlignment = Enum.TextXAlignment.Left
OfficeInfo.TextYAlignment = Enum.TextYAlignment.Top
Instance.new("UICorner", OfficeInfo).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", OfficeInfo).Color = Color3.fromRGB(40, 40, 40)

-- Logic Nút nổi Auto T
local showAutoTFloat = false
local autoTActive = false
tuner.ToggleFloatMenuBtn.MouseButton1Click:Connect(function()
    showAutoTFloat = not showAutoTFloat
    tuner.AutoTFloatingBtn.Visible = showAutoTFloat
    tuner.ToggleFloatMenuBtn.Text = showAutoTFloat and "🕹️ Hiện Nút Nổi Auto T: ĐANG BẬT" or "🕹️ Hiện Nút Nổi Auto T: ĐANG TẮT"
    tuner.ToggleFloatMenuBtn.BackgroundColor3 = showAutoTFloat and Color3.fromRGB(200, 100, 0) or Color3.fromRGB(35, 35, 35)
    if not showAutoTFloat then
        autoTActive = false
        tuner.AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game) end)
    end
end)

tuner.AutoTFloatingBtn.MouseButton1Click:Connect(function()
    autoTActive = not autoTActive
    tuner.AutoTFloatingBtn.BackgroundColor3 = autoTActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(18, 18, 18)
    pcall(function() VirtualInputManager:SendKeyEvent(autoTActive, Enum.KeyCode.T, false, game) end)
end)

local officeFarmActive = false
local autoJobActive = false
local antiAfkActive = true

OfficeFarmBtn.MouseButton1Click:Connect(function()
    officeFarmActive = not officeFarmActive
    OfficeFarmBtn.Text = officeFarmActive and "💼 Rajawali Office Farm: BẬT" or "💼 Rajawali Office Farm: TẮT"
    OfficeFarmBtn.BackgroundColor3 = officeFarmActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(35, 35, 35)
end)

AutoJobBtn.MouseButton1Click:Connect(function()
    autoJobActive = not autoJobActive
    AutoJobBtn.Text = autoJobActive and "👔 Tự Động Đổi Nghề (Office Worker): BẬT" or "👔 Tự Động Đổi Nghề (Office Worker): TẮT"
    AutoJobBtn.BackgroundColor3 = autoJobActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(35, 35, 35)
end)

AntiAfkBtn.MouseButton1Click:Connect(function()
    antiAfkActive = not antiAfkActive
    AntiAfkBtn.Text = antiAfkActive and "🛡️ Anti-AFK: ĐANG BẬT" or "🛡️ Anti-AFK: ĐANG TẮT"
    AntiAfkBtn.BackgroundColor3 = antiAfkActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(35, 35, 35)
end)

LocalPlayer.Idled:Connect(function()
    if antiAfkActive then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

local function findRajawaliOffice()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("rajawali") or name:find("office") then
                if obj:IsA("Model") then
                    return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                else
                    return obj
                end
            end
        end
    end
    return nil
end

local function triggerAutoJob()
    pcall(function()
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local action = (prompt.ActionText or ""):lower()
                local objText = (prompt.ObjectText or ""):lower()
                if action:find("office") or action:find("job") or action:find("karyawan") or objText:find("office") or objText:find("job") then
                    fireproximityprompt(prompt)
                end
            end
        end
    end)
end

RunService.Stepped:Connect(function()
    if officeFarmActive and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local root = c and c:FindFirstChild("HumanoidRootPart")
    local s = h and h.SeatPart
    local isInVehicle = (s and (s:IsA("VehicleSeat") or s:IsA("Seat")))

    if autoTActive then
        if isInVehicle then
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game) end)
        else
            autoTActive = false
            tuner.AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game) end)
        end
    end

    if autoJobActive then
        triggerAutoJob()
    end

    if officeFarmActive and h and root then
        pcall(function()
            local targetPart = findRajawaliOffice()
            if targetPart then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                h:MoveTo(targetPart.Position)
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Parent and (prompt.Parent.Position - root.Position).Magnitude < 15 then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end)
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end)
    end
end)

-- Logic Độ Xe (Inject)
tuner.InjectBtn.MouseButton1Click:Connect(function()
    local hpMult = tonumber(tuner.hpBox.Text) or 5.0
    local rpmAdd = tonumber(tuner.rpmBox.Text) or 8000
    local gearMult = tonumber(tuner.gearRatioBox.Text) or 0.8
    local count = 0

    if typeof(getgc) == "function" then
        for _, obj in pairs(getgc(true)) do
            if typeof(obj) == "table" then
                pcall(function()
                    for k, v in pairs(obj) do
                        if type(k) == "string" then
                            if k == "Horsepower" or k == "Torque" or k == "MaxPower" then
                                if type(v) == "number" then obj[k] = v * hpMult count = count + 1 end
                            elseif k == "Redline" or k == "MaxRPM" or k == "RPM" then
                                if type(v) == "number" then obj[k] = v + rpmAdd count = count + 1 end
                            elseif k == "GearRatio" or k == "FinalDrive" then
                                if type(v) == "number" and v > 0 then obj[k] = v * gearMult count = count + 1 end
                            elseif k == "GearRatios" or k == "Gears" then
                                if type(v) == "table" then
                                    for i, gVal in pairs(v) do
                                        if type(gVal) == "number" then v[i] = gVal * gearMult count = count + 1 end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
        local vehicleModel = seat.Parent
        for _, obj in pairs(vehicleModel:GetDescendants()) do
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                pcall(function()
                    local name = obj.Name:lower()
                    if name:find("horsepower") or name:find("power") then obj.Value = obj.Value * hpMult count = count + 1
                    elseif name:find("rpm") or name:find("redline") then obj.Value = obj.Value + rpmAdd count = count + 1
                    elseif name:find("gear") or name:find("ratio") or name:find("drive") then obj.Value = obj.Value * gearMult count = count + 1 end
                end)
            end
        end
    end

    if count > 0 or seat then
        tuner.Status.Text = "✔ Đã áp dụng thành công!"
        tuner.Status.TextColor3 = Color3.fromRGB(0, 255, 120)
    else
        tuner.Status.Text = "❌ Hãy ngồi lên xe rồi bấm!"
        tuner.Status.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end)
