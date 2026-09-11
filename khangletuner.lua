--[==[
    PROTECTED BY KHANG LE - ULTIMATE TUNER EDITION
    DO NOT REMOVE THIS HEADER OR DECOMPILE
]==]
local _P_Env = getgenv and getgenv() or _G
if _P_Env._KhangLeProtectedTuner then
    pcall(function() _P_Env._KhangLeProtectedTuner:Destroy() end)
end

local _0x1 = game:GetService("CoreGui")
local _0x2 = game:GetService("Players")
local _0x3 = game:GetService("RunService")
local _0x4 = game:GetService("VirtualInputManager")
local _0x5 = _0x2.LocalPlayer

local _0x6 = nil
pcall(function()
    _0x6 = gethui and gethui() or _0x1
end)
if not _0x6 then
    _0x6 = _0x5:WaitForChild("PlayerGui")
end

if _0x6:FindFirstChild("KhangLeCustomTuner") then
    _0x6.KhangLeCustomTuner:Destroy()
end

local _0x7 = Instance.new("ScreenGui")
_0x7.Name = "KhangLeCustomTuner"
_0x7.ResetOnSpawn = false
_0x7.Parent = _0x6
_P_Env._KhangLeProtectedTuner = _0x7

local _0x8 = Instance.new("TextButton")
_0x8.Size = UDim2.new(0, 52, 0, 52)
_0x8.Position = UDim2.new(0, 40, 0.4, 0)
_0x8.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
_0x8.TextColor3 = Color3.fromRGB(255, 215, 0)
_0x8.Text = "\xF0\x9F\x91\x91"
_0x8.TextSize = 24
_0x8.Font = Enum.Font.GothamBold
_0x8.Draggable = true
_0x8.Parent = _0x7

local _0x9 = Instance.new("UICorner")
_0x9.CornerRadius = UDim.new(1, 0)
_0x9.Parent = _0x8

local _0x10 = Instance.new("UIStroke")
_0x10.Color = Color3.fromRGB(255, 215, 0)
_0x10.Thickness = 2
_0x10.Parent = _0x8

local _0x11 = Instance.new("UIStroke")
_0x11.Color = Color3.fromRGB(0, 0, 0)
_0x11.Thickness = 4
_0x11.Transparency = 0.5
_0x11.Parent = _0x8

local _0x12 = Instance.new("TextButton")
_0x12.Size = UDim2.new(0, 52, 0, 52)
_0x12.Position = UDim2.new(0, 40, 0.55, 0)
_0x12.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
_0x12.TextColor3 = Color3.fromRGB(255, 100, 0)
_0x12.Text = "\xF0\x9F\x8E\xAE"
_0x12.TextSize = 24
_0x12.Font = Enum.Font.GothamBold
_0x12.Draggable = true
_0x12.Visible = false
_0x12.Parent = _0x7

local _0x13 = Instance.new("UICorner")
_0x13.CornerRadius = UDim.new(1, 0)
_0x13.Parent = _0x12

local _0x14 = Instance.new("UIStroke")
_0x14.Color = Color3.fromRGB(255, 100, 0)
_0x14.Thickness = 2
_0x14.Parent = _0x12

local _0x15 = Instance.new("Frame")
_0x15.Size = UDim2.new(0, 440, 0, 380)
_0x15.Position = UDim2.new(0.5, -220, 0.5, -190)
_0x15.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
_0x15.BorderSizePixel = 0
_0x15.Active = true
_0x15.Draggable = true
_0x15.Visible = true
_0x15.Parent = _0x7

local _0x16 = Instance.new("UICorner")
_0x16.CornerRadius = UDim.new(0, 14)
_0x16.Parent = _0x15

local _0x17 = Instance.new("UIStroke")
_0x17.Color = Color3.fromRGB(255, 215, 0)
_0x17.Thickness = 1.8
_0x17.Parent = _0x15

local _0x18 = Instance.new("TextLabel")
_0x18.Size = UDim2.new(1, 0, 0, 45)
_0x18.BackgroundTransparency = 1
_0x18.Text = "\xF0\x9F\x93\x9C H\xC6\xB0\xE1\xBB\x94NG D\xE1\xBA\xAAN S\xC4\xB0 D\xE1\xBB\xA4NG - KHANG L\xC3\x8A TUNER"
_0x18.TextColor3 = Color3.fromRGB(255, 215, 0)
_0x18.TextSize = 13
_0x18.Font = Enum.Font.GothamBold
_0x18.Parent = _0x15

local _0x19 = Instance.new("ScrollingFrame")
_0x19.Size = UDim2.new(0.92, 0, 0, 260)
_0x19.Position = UDim2.new(0.04, 0, 0, 48)
_0x19.BackgroundTransparency = 1
_0x19.BorderSizePixel = 0
_0x19.CanvasSize = UDim2.new(0, 0, 0, 680)
_0x19.ScrollBarThickness = 4
_0x19.Parent = _0x15

local _0x20 = Instance.new("TextLabel")
_0x20.Size = UDim2.new(1, 0, 0, 680)
_0x20.BackgroundTransparency = 1
_0x20.Text = "H\xC6\xB0\xE1\xBB\x93ng d\xE1\xBA\xABn x\xC3\xA0i - \xC4\x91\xE1\xBB\x8Dc k\xC4\xA9 tr\xC6\xB0\xE1\xBB\x9Bc khi s\xE1\xBB\xAD d\xE1\xBB\xA5ng:\nm\xE1\xBB\x8Di ng\xC6\xB0\xE1\xBB\x9Di h\xC3\xA3y \xC4\x91\xE1\xBB\x83 nguyen m\xE1\xBA\xB7c \xC4\x91\xE1\xBB\x8Bnh x\xC3\xA0i v\xEC do m\xC3\xACnh \xC4\x91\xC3\xA3 test v\xC3\xA0 set nh\xC6\xB0 v\xE1\xBA\xADy m\xE1\xBB\x8Di ng\xC6\xB0\xE1\xBB\x9Di c\xC3\xB3 th\xE1\xBB\x83 t\xC3\xB9y ch\xE1\xBB\x89nh nh\xC6\xB0ng c\xE1\xBA\xA7n \xC4\x91\xE1\xBB\x8Dc k\xC4\xA9 nh\xE1\xBB\xAFng c\xC3\xA1i sau \xC4\x91\xC3\xA2y:\n\nm\xC3\xA3 l\xE1\xBB\xB1c: t\xE1\xBB\x91c \xC4\x91\xE1\xBB\x99 \xC4\x91\xE1\xBB\x81 pa gia t\xE1\xBB\x91c m\xE1\xBA\xA1nh h\xC6\xA1n m\xC3\xA3 l\xE1\xBB\xB1c c\xC3\xA0ng nhi\xE1\xBB\x81u \xC4\x91\xE1\xBB\x81 pa c\xC3\xA0ng m\xE1\xBA\xA1nh ( L\xC6\xB0u \xC3\x9D : \xC4\x91\xE1\xBB\x83 \xC3\xadt th\xC3\xB4i n\xC3\xB3 xo\xC3\xA1y b\xC3\xA1nh tr\xC6\xA1n kh\xC3\xB4ng ch\xE1\xBA\xA1y \xC4\x91\xC6\xB0\xE1\xBB\xA3c )\n\nrpm: tua m\xC3\xA1y ng\xE1\xBA\xAFn l\xE1\xBA\xA1i ho\xE1\xBA\xB7c d\xC3\xA0i ra c\xC3\xB3 ngh\xC4\xA9a l\xE1\xBA\xA5 khi m\xE1\xBB\x8Di ng\xC6\xB0\xE1\xBB\x9Di ch\xE1\xBB\x89nh tua th\xE1\xBA\xA5p xu\xE1\xBB\x91ng qu\xC3\xA1 v\xC3\xA0 final drive \xC4\x91\xE1\xBB\x83 th\xE1\xBA\xA5p th\xEC max speed n\xC3\xB3 s\xE1\xBA\xBD kh\xC3\xB4ng nhanh h\xC6\xA1n t\xED nào \xC4\x91\xC3\xA2y m\xE1\xBB\x81 c\xC3\xB2n ch\xE1\xBA\xADm l\xE1\xBA\xA1i n\xE1\xBB\xAF\x61..."
_0x20.TextColor3 = Color3.fromRGB(220, 220, 220)
_0x20.TextSize = 12
_0x20.Font = Enum.Font.GothamMedium
_0x20.TextXAlignment = Enum.TextXAlignment.Left
_0x20.TextYAlignment = Enum.TextYAlignment.Top
_0x20.TextWrapped = true
_0x20.Parent = _0x19

local _0x21 = Instance.new("TextButton")
_0x21.Size = UDim2.new(0.92, 0, 0, 36)
_0x21.Position = UDim2.new(0.04, 0, 0, 320)
_0x21.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
_0x21.TextColor3 = Color3.fromRGB(15, 15, 15)
_0x21.Text = "\xE2\x9C\x96 \xC4\x90\xC3\x83 HI\xE1\xBB\x82U - V\xC3\x80O GIAO DI\xE1\xBB\x86N CH\xC3\x8DNH"
_0x21.TextSize = 12
_0x21.Font = Enum.Font.GothamBold
_0x21.Parent = _0x15

local _0x22 = Instance.new("UICorner")
_0x22.CornerRadius = UDim.new(0, 8)
_0x22.Parent = _0x21

local _0x23 = Instance.new("Frame")
_0x23.Size = UDim2.new(0, 340, 0, 424)
_0x23.Position = UDim2.new(0.5, -170, 0.5, -212)
_0x23.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
_0x23.BorderSizePixel = 0
_0x23.Active = true
_0x23.Draggable = true
_0x23.Visible = false
_0x23.Parent = _0x7

local _0x24 = Instance.new("UICorner")
_0x24.CornerRadius = UDim.new(0, 14)
_0x24.Parent = _0x23

local _0x25 = Instance.new("UIStroke")
_0x25.Color = Color3.fromRGB(50, 50, 60)
_0x25.Thickness = 1.5
_0x25.Parent = _0x23

_0x21.MouseButton1Click:Connect(function()
    _0x15.Visible = false
    _0x23.Visible = true
end)

_0x8.MouseButton1Click:Connect(function()
    _0x23.Visible = not _0x23.Visible
end)

local _0x26 = Instance.new("TextLabel")
_0x26.Size = UDim2.new(1, 0, 0, 48)
_0x26.BackgroundTransparency = 1
_0x26.Text = "\xF0\x9F\x91\x91 Khang L\xC3\x8A Custom Tuner"
_0x26.TextColor3 = Color3.fromRGB(255, 215, 0)
_0x26.TextSize = 15
_0x26.Font = Enum.Font.GothamBold
_0x26.Parent = _0x23

local _0x27 = Instance.new("TextButton")
_0x27.Size = UDim2.new(0, 32, 0, 32)
_0x27.Position = UDim2.new(1, -38, 0, 8)
_0x27.BackgroundTransparency = 1
_0x27.TextColor3 = Color3.fromRGB(180, 180, 180)
_0x27.Text = "\xE2\x95\xAE"
_0x27.TextSize = 16
_0x27.Font = Enum.Font.GothamBold
_0x27.Parent = _0x23

_0x27.MouseButton1Click:Connect(function()
    _0x23.Visible = false
end)

local function _0x28(_0x29, _0x30, _0x31)
    local _0x32 = Instance.new("TextLabel")
    _0x32.Size = UDim2.new(0.9, 0, 0, 18)
    _0x32.Position = UDim2.new(0.05, 0, 0, _0x31)
    _0x32.BackgroundTransparency = 1
    _0x32.Text = _0x29
    _0x32.TextColor3 = Color3.fromRGB(210, 210, 210)
    _0x32.TextSize = 11
    _0x32.Font = Enum.Font.GothamMedium
    _0x32.TextXAlignment = Enum.TextXAlignment.Left
    _0x32.Parent = _0x23

    local _0x33 = Instance.new("TextBox")
    _0x33.Size = UDim2.new(0.9, 0, 0, 30)
    _0x33.Position = UDim2.new(0.05, 0, 0, _0x31 + 18)
    _0x33.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    _0x33.TextColor3 = Color3.fromRGB(255, 255, 255)
    _0x33.Text = tostring(_0x30)
    _0x33.TextSize = 13
    _0x33.Font = Enum.Font.GothamBold
    _0x33.BorderSizePixel = 0
    _0x33.Parent = _0x23

    local _0x34 = Instance.new("UICorner")
    _0x34.CornerRadius = UDim.new(0, 8)
    _0x34.Parent = _0x33

    local _0x35 = Instance.new("UIStroke")
    _0x35.Color = Color3.fromRGB(60, 60, 75)
    _0x35.Thickness = 1
    _0x35.Parent = _0x33

    return _0x33
end

local _0x36 = _0x28("\xF0\x9F\x92\xAA H\xE1\xBB\x87 s\xE1\xBB\x91 M\xC3\xA3 l\xE1\xBB\xAB\x63 (M\xE1\xBA\xB7\x63 \xC4\x91\xE1\xBB\x8Bnh: 5.0)", "5.0", 48)
local _0x37 = _0x28("\xF0\x9F\x94\xA5 C\xE1\xBB\x99ng th\xC3\xAAm Tua m\xC3\xA1y - RPM (M\xE1\xBA\xB7\x63 \xC4\x91\xE1\xBB\x8Bnh: 3500)", "3500", 112)
local _0x38 = _0x28("\xE2\x9A\x99\xEF\xB8\x8F T\xE1\xBB\xB7 s\xE1\xBB\x91 truy\xE1\xBB\x81n s\xE1\xBB\x91 - Ratio Gear (M\xE1\xBA\xB7\x63 \xC4\x91\xE1\xBB\x8Bnh: 0.8)", "0.8", 176)
local _0x39 = _0x28("\xE2\x9A\x93 T\xE1\xBB\xB7 s\xE1\xBB\x91 truy\xE1\xBB\x81n cu\xE1\xBB\x91i - Final Drive (M\xE1\xBA\xB7\x63 \xC4\x91\xE1\xBB\x8Bnh: 0.8)", "0.8", 240)

local _0x40 = Instance.new("TextLabel")
_0x40.Size = UDim2.new(0.9, 0, 0, 22)
_0x40.Position = UDim2.new(0.05, 0, 0, 304)
_0x40.BackgroundTransparency = 1
_0x40.Text = "Tr\xE1\xBA\xA1ng th\xC3\xA1i: S\xE1\xBA\xB5n s\xE1\xBB\x81n \xC4\x91\xE1\xBB\x99 xe tr\xE1\xBB\xB1c ti\xE1\xBA\xBFp."
_0x40.TextColor3 = Color3.fromRGB(255, 200, 0)
_0x40.TextSize = 11
_0x40.Font = Enum.Font.GothamBold
_0x40.TextXAlignment = Enum.TextXAlignment.Center
_0x40.Parent = _0x23

local _0x41 = Instance.new("TextButton")
_0x41.Size = UDim2.new(0.9, 0, 0, 34)
_0x41.Position = UDim2.new(0.05, 0, 0, 330)
_0x41.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
_0x41.TextColor3 = Color3.fromRGB(255, 255, 255)
_0x41.Text = "\xE2\x9A\xA1 \xC3\x81P D\xE1\xBB\xA4NG TUNER (T\xC6\xA8C TH\xC3\x8C)"
_0x41.TextSize = 11
_0x41.Font = Enum.Font.GothamBold
_0x41.Parent = _0x23

local _0x42 = Instance.new("UICorner")
_0x42.CornerRadius = UDim.new(0, 8)
_0x42.Parent = _0x41

local _0x43 = false
local _0x44 = Instance.new("TextButton")
_0x44.Size = UDim2.new(0.9, 0, 0, 34)
_0x44.Position = UDim2.new(0.05, 0, 0, 372)
_0x44.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
_0x44.TextColor3 = Color3.fromRGB(255, 255, 255)
_0x44.Text = "\xF0\x9F\x8E\xAE N\xC3\x9AT N\xE1\xBB\x94I AUTO T: \xC4\x90ANG T\xE1\xBA\xAFT"
_0x44.TextSize = 11
_0x44.Font = Enum.Font.GothamBold
_0x44.Parent = _0x23

local _0x45 = Instance.new("UICorner")
_0x45.CornerRadius = UDim.new(0, 8)
_0x45.Parent = _0x44

local _0x46 = false

_0x44.MouseButton1Click:Connect(function()
    _0x43 = not _0x43
    _0x12.Visible = _0x43
    if _0x43 then
        _0x44.Text = "\xF0\x9F\x8E\xAE N\xC3\x9AT N\xE1\xBB\x94I AUTO T: \xC4\x90ANG B\xBA\xAcT"
        _0x44.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    else
        _0x44.Text = "\xF0\x9F\x8E\xAE N\xC3\x9AT N\xE1\xBB\x94I AUTO T: \xC4\x90ANG T\xE1\xBA\xAFT"
        _0x44.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        _0x46 = false
        _0x12.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        _0x14.Color = Color3.fromRGB(255, 100, 0)
        pcall(function()
            _0x4:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end)
    end
end)

_0x12.MouseButton1Click:Connect(function()
    _0x46 = not _0x46
    if _0x46 then
        _0x12.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        _0x14.Color = Color3.fromRGB(0, 255, 120)
        pcall(function()
            _0x4:SendKeyEvent(true, Enum.KeyCode.T, false, game)
        end)
    else
        _0x12.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        _0x14.Color = Color3.fromRGB(255, 100, 0)
        pcall(function()
            _0x4:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end)
    end
end)

_0x3.Heartbeat:Connect(function()
    local _0x47 = _0x5.Character
    local _0x48 = _0x47 and _0x47:FindFirstChildOfClass("Humanoid")
    local _0x49 = _0x48 and _0x48.SeatPart
    local _0x50 = (_0x49 and (_0x49:IsA("VehicleSeat") or _0x49:IsA("Seat")))

    if _0x46 then
        if _0x50 then
            pcall(function()
                _0x4:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            end)
        else
            _0x46 = false
            _0x12.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            _0x14.Color = Color3.fromRGB(255, 100, 0)
            pcall(function()
                _0x4:SendKeyEvent(false, Enum.KeyCode.T, false, game)
            end)
        end
    end
end)

_0x41.MouseButton1Click:Connect(function()
    local _0x51 = tonumber(_0x36.Text) or 5.0
    local _0x52 = tonumber(_0x37.Text) or 3500
    local _0x53 = tonumber(_0x38.Text) or 0.8
    local _0x54 = tonumber(_0x39.Text) or 0.8
    local _0x55 = 0

    if typeof(getgc) == "function" then
        for _, _0x56 in pairs(getgc(true)) do
            if typeof(_0x56) == "table" then
                pcall(function()
                    for _0x57, _0x58 in pairs(_0x56) do
                        if type(_0x57) == "string" then
                            if _0x57 == "Horsepower" or _0x57 == "Torque" or _0x57 == "MaxPower" then
                                if type(_0x58) == "number" then
                                    _0x56[_0x57] = _0x58 * _0x51
                                    _0x55 = _0x55 + 1
                                end
                            elseif _0x57 == "Redline" or _0x57 == "MaxRPM" or _0x57 == "RPM" then
                                if type(_0x58) == "number" then
                                    _0x56[_0x57] = _0x58 + _0x52
                                    _0x55 = _0x55 + 1
                                end
                            elseif _0x57 == "GearRatio" or _0x57 == "FinalDrive" then
                                local _0x59 = (_0x57 == "FinalDrive") and _0x54 or _0x53
                                if type(_0x58) == "number" and _0x58 > 0 then
                                    _0x56[_0x57] = _0x58 * _0x59
                                    _0x55 = _0x55 + 1
                                end
                            elseif _0x57 == "GearRatios" or _0x57 == "Gears" then
                                if type(_0x58) == "table" then
                                    for _0x60, _0x61 in pairs(_0x58) do
                                        if type(_0x61) == "number" then
                                            _0x58[_0x60] = _0x61 * _0x53
                                            _0x55 = _0x55 + 1
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

    local _0x62 = _0x5.Character
    local _0x63 = _0x62 and _0x62:FindFirstChildOfClass("Humanoid")
    local _0x64 = _0x63 and _0x63.SeatPart
    if _0x64 and (_0x64:IsA("VehicleSeat") or _0x64:IsA("Seat")) then
        local _0x65 = _0x64.Parent
        for _, _0x66 in pairs(_0x65:GetDescendants()) do
            if _0x66:IsA("NumberValue") or _0x66:IsA("IntValue") then
                pcall(function()
                    local _0x67 = _0x66.Name:lower()
                    if _0x67:find("horsepower") or _0x67:find("power") then
                        _0x66.Value = _0x66.Value * _0x51
                        _0x55 = _0x55 + 1
                    elseif _0x67:find("rpm") or _0x67:find("redline") then
                        _0x66.Value = _0x66.Value + _0x52
                        _0x55 = _0x55 + 1
                    elseif _0x67:find("gear") or _0x67:find("ratio") then
                        _0x66.Value = _0x66.Value * _0x53
                        _0x55 = _0x55 + 1
                    elseif _0x67:find("drive") then
                        _0x66.Value = _0x66.Value * _0x54
                        _0x55 = _0x55 + 1
                    end
                end)
            end
        end
    end

    if _0x55 > 0 or _0x64 then
        _0x40.Text = "\xE2\x9C\x94 \x44\xC3\xA3 \xC3\xA1p d\xE1\xBB\xA5ng th\xC3\xA0nh c\xC3\xB4ng (xu\xE1\xBB\x91ng xe l\xC3\xAAn l\xE1\xBA\xA1i)!"
        _0x40.TextColor3 = Color3.fromRGB(0, 255, 120)
    else
        _0x40.Text = "\xE2\x9D\x8C H\xC3\xA3y ng\xE1\xBB\x93i l\xC3\xAAn xe r\xE1\xBB\x93i b\xE1\xBA\xबली \xC3\xA1p d\xE1\xBB\xA5ng nh\xC3\xA9!"
        _0x40.TextColor3 = Color3.fromRGB(255, 50, 50)
    end

    task.delay(3, function()
        if _0x40 and _0x40.Parent then
            _0x40.Text = "Tr\xE1\xBA\xA1ng th\xC3\xA1i: S\xE1\xBA\xB5n s\xE1\xBB\x81n."
            _0x40.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end)
end)
    
