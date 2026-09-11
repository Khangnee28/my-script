-- KhangLe Custom Tuner - Ultimate Edition (Auto T Tự Ngắt Khi Té/Xuống Xe)
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local parent = nil
pcall(function()
    parent = gethui and gethui() or CoreGui
end)
if not parent then
    parent = LocalPlayer:WaitForChild("PlayerGui")
end

if parent:FindFirstChild("KhangLeCustomTuner") then
    parent.KhangLeCustomTuner:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KhangLeCustomTuner"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parent

-- 1. Nút tròn mở menu chính (Icon vương miện hoàng gia sang trọng 👑)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 40, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
ToggleBtn.Text = "👑"
ToggleBtn.TextSize = 24
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(1, 0)
corner1.Parent = ToggleBtn

local stroke1 = Instance.new("UIStroke")
stroke1.Color = Color3.fromRGB(255, 215, 0)
stroke1.Thickness = 2
stroke1.Parent = ToggleBtn

local shadow1 = Instance.new("UIStroke")
shadow1.Color = Color3.fromRGB(0, 0, 0)
shadow1.Thickness = 4
shadow1.Transparency = 0.5
shadow1.Parent = ToggleBtn

-- 2. Nút nổi Auto T Phím T riêng biệt (Hình điều khiển 🕹️)
local AutoTFloatingBtn = Instance.new("TextButton")
AutoTFloatingBtn.Size = UDim2.new(0, 52, 0, 52)
AutoTFloatingBtn.Position = UDim2.new(0, 40, 0.55, 0)
AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
AutoTFloatingBtn.TextColor3 = Color3.fromRGB(255, 100, 0)
AutoTFloatingBtn.Text = "🕹️"
AutoTFloatingBtn.TextSize = 24
AutoTFloatingBtn.Font = Enum.Font.GothamBold
AutoTFloatingBtn.Draggable = true
AutoTFloatingBtn.Visible = false
AutoTFloatingBtn.Parent = ScreenGui

local cornerAutoTFloat = Instance.new("UICorner")
cornerAutoTFloat.CornerRadius = UDim.new(1, 0)
cornerAutoTFloat.Parent = AutoTFloatingBtn

local strokeAutoTFloat = Instance.new("UIStroke")
strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
strokeAutoTFloat.Thickness = 2
strokeAutoTFloat.Parent = AutoTFloatingBtn

-- BẢNG HƯỚNG DẪN SỬ DỤNG (Hiện đúng 1 lần duy nhất khi execute)
local GuideFrame = Instance.new("Frame")
GuideFrame.Size = UDim2.new(0, 440, 0, 380)
GuideFrame.Position = UDim2.new(0.5, -220, 0.5, -190)
GuideFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
GuideFrame.BorderSizePixel = 0
GuideFrame.Active = true
GuideFrame.Draggable = true
GuideFrame.Visible = true
GuideFrame.Parent = ScreenGui

local cornerGuide = Instance.new("UICorner")
cornerGuide.CornerRadius = UDim.new(0, 14)
cornerGuide.Parent = GuideFrame

local strokeGuide = Instance.new("UIStroke")
strokeGuide.Color = Color3.fromRGB(255, 215, 0)
strokeGuide.Thickness = 1.8
strokeGuide.Parent = GuideFrame

local GuideTitle = Instance.new("TextLabel")
GuideTitle.Size = UDim2.new(1, 0, 0, 45)
GuideTitle.BackgroundTransparency = 1
GuideTitle.Text = "📜 HƯỚNG DẪN SỬ DỤNG - KHANG LÊ TUNER"
GuideTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
GuideTitle.TextSize = 13
GuideTitle.Font = Enum.Font.GothamBold
GuideTitle.Parent = GuideFrame

local ScrollGuide = Instance.new("ScrollingFrame")
ScrollGuide.Size = UDim2.new(0.92, 0, 0, 260)
ScrollGuide.Position = UDim2.new(0.04, 0, 0, 48)
ScrollGuide.BackgroundTransparency = 1
ScrollGuide.BorderSizePixel = 0
ScrollGuide.CanvasSize = UDim2.new(0, 0, 0, 680)
ScrollGuide.ScrollBarThickness = 4
ScrollGuide.Parent = GuideFrame

local GuideContent = Instance.new("TextLabel")
GuideContent.Size = UDim2.new(1, 0, 0, 680)
GuideContent.BackgroundTransparency = 1
GuideContent.Text = [[Hướng dẫn xài - đọc kĩ trước khi sử dụng:
mọi người hãy để nguyên mặc định xài vì do mình đã test và set như vậy mọi người có thể tùy chỉnh nhưng cần đọc kĩ những cái sau đây:

mã lực: tốc độ đề pa gia tốc mạnh hơn mã lực càng nhiều đề pa càng mạnh ( Lưu ý : để ít thôi nó xoáy bánh trơn không chạy được )

rpm: tua máy ngắn lại hoặc dài ra có nghĩa là khi mọi người chỉnh tua thấp xuống quá và final drive để thấp thì max speed nó sẽ không nhanh hơn tí nào đâu mà còn chậm lại nữa giống kiểu mọi người khoá tua không cho nó chạy hết tua máy

tips chỉnh rpm: mình để mặc định là 3500 mọi người chỉnh final drive khi nào chạy hết ga hết số rồi mà xe nó tằng tằng thì do mọi người chỉnh top speed nó cao hơn nên tới tua đó nó muốn lên thêm mà không được nên mọi người chỉnh rpm lên chút xíu xong khi nào nó k còn tằng nữa mọi người hạ xuống 50 hoặc 100 cho nó tằng để nghe tiếng cho nó hay nha

ratio gear: tỷ lệ của số có nghĩa là khi mọi người chỉnh càng nhỏ số sẽ dài ra và tốc độ của số cũng sẽ tăng lên theo và khi chỉnh số lớn thì số sẽ hết số nhanh hơn phải sang số để chạy nhanh hơn ( không nên chỉnh cái này nếu đi xe tay ga )

final drive: tỷ số truyền động cuối có nghĩa là khi mọi người giảm cái này thì lực tác động lên bánh sau sẽ yếu lại nhưng top speed sẽ tăng lên giống như mọi người đi xe máy nhông to sẽ đề pa mạnh nhưng top speed lại thấp còn nhông nhỏ đề pa yếu nhưng top speed lại nhanh hơn ( nếu hạ cái này nhiều quá thấy đề pa quá yếu thì nên tăng mã lực và rút ngắn cấp số lại nha ) 

Lưu Ý Quan Trọng: mọi người chỉ nên chỉnh rpm và final drive và mã lực thôi nha khi chỉnh ratio gear và chỉnh cả final drive nữa rất sẽ gây xung đột và lỗi khiến xe chạy nhanh bất thường và tua máy dài mênh mông nên mọi người chọn chỉnh ratio gear hoặc final drive cái nào cũng được nếu mọi người muốn chạy nhanh hơn thì cứ chỉnh 1 trong 2 cái đó thấp xuống còn muốn xe nó tằng tằng đỡ phải canh sợ game kick thì chỉnh rpm thấp xuống cho nó tằng nha 

Lưu Ý Về Tốc Độ: khuyên mọi người đừng chỉnh quá nhanh chỉnh mã lực đề pa xoáy bánh cho ngầu thì được nếu chạy quá nhanh hoặc bất thường về tốc độ sẽ bị game kick, nếu mọi người muốn chạy nhanh 400+ km/h thì nên nhấp nhả ga để cho speed nó lên từ từ đừng kéo một phát lên cực nhanh game sẽ phát hiện và kick mọi người vì tốc độ bất thường tốc độ tầm 370 đổ xuống là mọi người có thể kéo hết ga cũng được không cần nhấp nhả nhưng tùy xe nó lên speed chậm hay nhanh nha nó lên speed nhanh quá vẫn bị kick như bình thường nên là mọi người lưu ý với game này không ban người chơi nên bị kick thì mọi người đừng quá lo lắng.

Auto T: tự động bốc đầu cho ai muốn múa lửa 
cách dùng: mở menu lên và bật nó lên sau khi bật sẽ hiện một cái bong bóng nổi mọi người kéo đâu cũng được miễn thuận tiện là được sau khi lên xe mọi người bấm vào cái nút đó là được thì khi mọi người vặn ga xe sẽ tự bốc đầu lên cho cảm giác chạy rất phê

lưu ý: sau khi té rất dễ bị lỗi mất nút di chuyển khi bị mọi người chỉ cần ấn vài lần vào màn hình hoặc bấm vào icon roblox trên góc phải vài lần là sẽ bình thường trở lại.]]
GuideContent.TextColor3 = Color3.fromRGB(220, 220, 220)
GuideContent.TextSize = 12
GuideContent.Font = Enum.Font.GothamMedium
GuideContent.TextXAlignment = Enum.TextXAlignment.Left
GuideContent.TextYAlignment = Enum.TextYAlignment.Top
GuideContent.TextWrapped = true
GuideContent.Parent = ScrollGuide

local CloseGuideBtn = Instance.new("TextButton")
CloseGuideBtn.Size = UDim2.new(0.92, 0, 0, 36)
CloseGuideBtn.Position = UDim2.new(0.04, 0, 0, 320)
CloseGuideBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
CloseGuideBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
CloseGuideBtn.Text = "✖ ĐÃ HIỂU - VÀO GIAO DIỆN CHÍNH"
CloseGuideBtn.TextSize = 12
CloseGuideBtn.Font = Enum.Font.GothamBold
CloseGuideBtn.Parent = GuideFrame

local cornerCloseGuide = Instance.new("UICorner")
cornerCloseGuide.CornerRadius = UDim.new(0, 8)
cornerCloseGuide.Parent = CloseGuideBtn

-- Khung Giao Diện Chính
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 424)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -212)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 14)
corner2.Parent = MainFrame

local stroke2 = Instance.new("UIStroke")
stroke2.Color = Color3.fromRGB(50, 50, 60)
stroke2.Thickness = 1.5
stroke2.Parent = MainFrame

CloseGuideBtn.MouseButton1Click:Connect(function()
    GuideFrame.Visible = false
    MainFrame.Visible = true
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Tiêu đề Menu Chính
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 48)
Title.BackgroundTransparency = 1
Title.Text = "👑 Khang Lê Custom Tuner"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Nút Đóng Menu (Dấu X)
local CloseMenuBtn = Instance.new("TextButton")
CloseMenuBtn.Size = UDim2.new(0, 32, 0, 32)
CloseMenuBtn.Position = UDim2.new(1, -38, 0, 8)
CloseMenuBtn.BackgroundTransparency = 1
CloseMenuBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseMenuBtn.Text = "✕"
CloseMenuBtn.TextSize = 16
CloseMenuBtn.Font = Enum.Font.GothamBold
CloseMenuBtn.Parent = MainFrame

CloseMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Hàm tạo ô nhập liệu tinh chỉnh
local function createInput(name, defaultVal, posY)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.9, 0, 0, 18)
    lbl.Position = UDim2.new(0.05, 0, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = MainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.9, 0, 0, 30)
    box.Position = UDim2.new(0.05, 0, 0, posY + 18)
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultVal)
    box.TextSize = 13
    box.Font = Enum.Font.GothamBold
    box.BorderSizePixel = 0
    box.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 75)
    stroke.Thickness = 1
    stroke.Parent = box

    return box
end

-- Thiết lập: Mã lực, RPM (Mặc định 3500), Ratio Gear, Final Drive
local hpBox = createInput("💪 Hệ số Mã lực (Mặc định: 5.0)", "5.0", 48)
local rpmBox = createInput("🔥 Cộng thêm Tua máy - RPM (Mặc định: 3500)", "3500", 112)
local gearRatioBox = createInput("⚙️ Tỷ số truyền số - Ratio Gear (Mặc định: 0.8)", "0.8", 176)
local finalDriveBox = createInput("⛓️ Tỷ số truyền cuối - Final Drive (Mặc định: 0.8)", "0.8", 240)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 22)
Status.Position = UDim2.new(0.05, 0, 0, 304)
Status.BackgroundTransparency = 1
Status.Text = "Trạng thái: Sẵn sàng độ xe trực tiếp."
Status.TextColor3 = Color3.fromRGB(255, 200, 0)
Status.TextSize = 11
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Center
Status.Parent = MainFrame

-- Nút Áp Dụng Độ Xe
local InjectBtn = Instance.new("TextButton")
InjectBtn.Size = UDim2.new(0.9, 0, 0, 34)
InjectBtn.Position = UDim2.new(0.05, 0, 0, 330)
InjectBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
InjectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
InjectBtn.Text = "⚡ ÁP DỤNG TUNER (TỨC THÌ)"
InjectBtn.TextSize = 11
InjectBtn.Font = Enum.Font.GothamBold
InjectBtn.Parent = MainFrame

local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(0, 8)
corner4.Parent = InjectBtn

-- Nút bật/tắt hiển thị nút nổi Auto T trong menu
local showAutoTFloat = false
local ToggleFloatMenuBtn = Instance.new("TextButton")
ToggleFloatMenuBtn.Size = UDim2.new(0.9, 0, 0, 34)
ToggleFloatMenuBtn.Position = UDim2.new(0.05, 0, 0, 372)
ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ToggleFloatMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleFloatMenuBtn.Text = "🕹️ NÚT NỔI AUTO T: ĐANG TẮT"
ToggleFloatMenuBtn.TextSize = 11
ToggleFloatMenuBtn.Font = Enum.Font.GothamBold
ToggleFloatMenuBtn.Parent = MainFrame

local cornerFloatMenu = Instance.new("UICorner")
cornerFloatMenu.CornerRadius = UDim.new(0, 8)
cornerFloatMenu.Parent = ToggleFloatMenuBtn

local autoTActive = false

ToggleFloatMenuBtn.MouseButton1Click:Connect(function()
    showAutoTFloat = not showAutoTFloat
    AutoTFloatingBtn.Visible = showAutoTFloat
    if showAutoTFloat then
        ToggleFloatMenuBtn.Text = "🕹️ NÚT NỔI AUTO T: ĐANG BẬT"
        ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    else
        ToggleFloatMenuBtn.Text = "🕹️ NÚT NỔI AUTO T: ĐANG TẮT"
        ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        autoTActive = false
        AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end)
    end
end)

-- Xử lý khi bấm vào nút nổi Auto T (🕹️) trên màn hình
AutoTFloatingBtn.MouseButton1Click:Connect(function()
    autoTActive = not autoTActive
    if autoTActive then
        AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        strokeAutoTFloat.Color = Color3.fromRGB(0, 255, 120)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
        end)
    else
        AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end)
    end
end)

-- Vòng lặp giám sát thông minh: Tự động tắt Auto T nếu bị té hoặc xuống xe
RunService.Heartbeat:Connect(function()
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local s = h and h.SeatPart
    local isInVehicle = (s and (s:IsA("VehicleSeat") or s:IsA("Seat")))

    if autoTActive then
        if isInVehicle then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            end)
        else
            autoTActive = false
            AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            strokeAutoTFloat.Color = Color3.fromRGB(255, 100, 0)
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
            end)
        end
    end
end)

InjectBtn.MouseButton1Click:Connect(function()
    local hpMult = tonumber(hpBox.Text) or 5.0
    local rpmAdd = tonumber(rpmBox.Text) or 3500
    local gearMult = tonumber(gearRatioBox.Text) or 0.8
    local finalMult = tonumber(finalDriveBox.Text) or 0.8
    local count = 0

    -- 1. Quét RAM getgc
    if typeof(getgc) == "function" then
        for _, obj in pairs(getgc(true)) do
            if typeof(obj) == "table" then
                pcall(function()
                    for k, v in pairs(obj) do
                        if type(k) == "string" then
                            if k == "Horsepower" or k == "Torque" or k == "MaxPower" then
                                if type(v) == "number" then
                                    obj[k] = v * hpMult
                                    count = count + 1
                                end
                            elseif k == "Redline" or k == "MaxRPM" or k == "RPM" then
                                if type(v) == "number" then
                                    obj[k] = v + rpmAdd
                                    count = count + 1
                                end
                            elseif k == "GearRatio" or k == "FinalDrive" then
                                local mult = (k == "FinalDrive") and finalMult or gearMult
                                if type(v) == "number" and v > 0 then
                                    obj[k] = v * mult
                                    count = count + 1
                                end
                            elseif k == "GearRatios" or k == "Gears" then
                                if type(v) == "table" then
                                    for i, gVal in pairs(v) do
                                        if type(gVal) == "number" then
                                            v[i] = gVal * gearMult
                                            count = count + 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end

    -- 2. Quét trực tiếp chiếc xe đang ngồi
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
        local vehicleModel = seat.Parent
        for _, obj in pairs(vehicleModel:GetDescendants()) do
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                pcall(function()
                    local name = obj.Name:lower()
                    if name:find("horsepower") or name:find("power") then
                        obj.Value = obj.Value * hpMult
                        count = count + 1
                    elseif name:find("rpm") or name:find("redline") then
                        obj.Value = obj.Value + rpmAdd
                        count = count + 1
                    elseif name:find("gear") or name:find("ratio") then
                        obj.Value = obj.Value * gearMult
                        count = count + 1
                    elseif name:find("drive") then
                        obj.Value = obj.Value * finalMult
                        count = count + 1
                    end
                end)
            end
        end
    end

    if count > 0 or seat then
        Status.Text = "✔ Đã áp dụng thành công (xuống xe lên lại)!"
        Status.TextColor3 = Color3.fromRGB(0, 255, 120)
    else
        Status.Text = "❌ Hãy ngồi lên xe rồi bấm áp dụng nhé!"
        Status.TextColor3 = Color3.fromRGB(255, 50, 50)
    end

    -- Tự động quay về trạng thái sẵn sàng sau 3 giây
    task.delay(3, function()
        if Status and Status.Parent then
            Status.Text = "Trạng thái: Sẵn sàng."
            Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end)
end)
