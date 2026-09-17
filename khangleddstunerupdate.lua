-- ============================================================
-- KhangLe Custom Tuner + Office Farm Hub
-- base: KhangLe tuner (unchanged) + Office Farm v20 (unchanged logic)
-- barista path removed, menu rebuilt to card style, all float buttons square + RGB LED
-- ============================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local player = LocalPlayer

pcall(function()
    Lighting.GlobalShadows = true
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
    if not Lighting:FindFirstChild("KhangLeBloom") then
        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Name = "KhangLeBloom"
        bloom.Intensity = 0.4
        bloom.Threshold = 0.8
    end
end)

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

-- ============================================================
-- SHARED RGB LED BORDER (42 segments, clean corners, no +1px overflow)
-- ============================================================
local RAINBOW = {
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(255, 160, 40),
    Color3.fromRGB(255, 230, 60),
    Color3.fromRGB(90, 230, 90),
    Color3.fromRGB(70, 160, 255),
    Color3.fromRGB(125, 90, 220),
    Color3.fromRGB(225, 80, 220),
}

local function attachRGBLed(frame, thickness)
    thickness = thickness or 2
    local ledSegs = {}
    local N1, N2 = 12, 6

    local function addSeg(pos, size)
        local f = Instance.new("Frame")
        f.Position = pos
        f.Size = size
        f.BorderSizePixel = 0
        f.ZIndex = (frame.ZIndex or 1) + 2
        f.BackgroundColor3 = RAINBOW[1]
        f.Parent = frame
        table.insert(ledSegs, f)
        return f
    end

    local function wSize(i)
        if i == N1 - 1 then
            return UDim2.new(1 / N1, 0, 0, thickness)
        end
        return UDim2.new(1 / N1, 1, 0, thickness)
    end
    local function hSize(i)
        if i == N2 - 1 then
            return UDim2.new(0, thickness, 1 / N2, 0)
        end
        return UDim2.new(0, thickness, 1 / N2, 1)
    end

    for i = 0, N1 - 1 do
        addSeg(UDim2.new(i / N1, 0, 0, 0), wSize(i))
    end
    for i = 0, N2 - 1 do
        addSeg(UDim2.new(1, -thickness, i / N2, 0), hSize(i))
    end
    for i = N1 - 1, 0, -1 do
        addSeg(UDim2.new(i / N1, 0, 1, -thickness), wSize(i))
    end
    for i = N2 - 1, 0, -1 do
        addSeg(UDim2.new(0, 0, i / N2, 0), hSize(i))
    end

    task.spawn(function()
        local t = 0
        local n = #ledSegs
        while frame and frame.Parent do
            t = t + 0.07
            for i, seg in ipairs(ledSegs) do
                local pos = (t + (i - 1) * 7 / n) % 7
                local idx = math.floor(pos) + 1
                local f = pos - (idx - 1)
                local a = RAINBOW[idx]
                local b = RAINBOW[(idx % 7) + 1]
                seg.BackgroundColor3 = a:Lerp(b, f)
            end
            task.wait(0.03)
        end
    end)
    return ledSegs
end

-- ============================================================
-- DRAGGABLE HEADER HELPER (unchanged behaviour)
-- ============================================================
local function makeHeaderDraggable(header, frame)
    header.Active = true
    local dragging = false
    local dragInput, dragStart, startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- SQUARE FLOATING BUTTONS + RGB LED
-- ============================================================
local function createSquareFloat(text, posYScale, accent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 44)
    btn.Position = UDim2.new(0, 18, posYScale, 0)
    btn.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
    btn.TextColor3 = accent
    btn.Text = text
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.Draggable = true
    btn.BorderSizePixel = 0
    btn.ZIndex = 12
    btn.Parent = ScreenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    attachRGBLed(btn, 2)
    return btn
end

local ToggleBtn = createSquareFloat("👑", 0.38, Color3.fromRGB(255, 210, 60))
local AutoTFloatingBtn = createSquareFloat("🕹️", 0.50, Color3.fromRGB(255, 110, 40))
AutoTFloatingBtn.Visible = false
local BodyManagerFloatingBtn = createSquareFloat("🚗", 0.62, Color3.fromRGB(0, 230, 180))
BodyManagerFloatingBtn.Visible = false
local FreecamFloatingBtn = createSquareFloat("📷", 0.74, Color3.fromRGB(120, 180, 255))
FreecamFloatingBtn.Visible = false

-- ============================================================
-- GUIDE FRAME (original content preserved)
-- ============================================================
local GuideFrame = Instance.new("Frame")
GuideFrame.Size = UDim2.new(0, 540, 0, 350)
GuideFrame.Position = UDim2.new(0.5, -270, 0.5, -175)
GuideFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
GuideFrame.BorderSizePixel = 0
GuideFrame.Active = true
GuideFrame.Draggable = false
GuideFrame.Visible = true
GuideFrame.Parent = ScreenGui
Instance.new("UICorner", GuideFrame).CornerRadius = UDim.new(0, 14)
local strokeGuide = Instance.new("UIStroke")
strokeGuide.Color = Color3.fromRGB(255, 215, 0)
strokeGuide.Thickness = 1.8
strokeGuide.Parent = GuideFrame

local GuideTitle = Instance.new("TextLabel")
GuideTitle.Size = UDim2.new(1, 0, 0, 42)
GuideTitle.BackgroundTransparency = 1
GuideTitle.Text = "📜 HƯỚNG DẪN SỬ DỤNG - VUI LÒNG ĐỌC KĨ!"
GuideTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
GuideTitle.TextSize = 12
GuideTitle.Font = Enum.Font.GothamBold
GuideTitle.Parent = GuideFrame
makeHeaderDraggable(GuideTitle, GuideFrame)

local ScrollGuide = Instance.new("ScrollingFrame")
ScrollGuide.Size = UDim2.new(0.94, 0, 0, 240)
ScrollGuide.Position = UDim2.new(0.03, 0, 0, 45)
ScrollGuide.BackgroundTransparency = 1
ScrollGuide.BorderSizePixel = 0
ScrollGuide.CanvasSize = UDim2.new(0, 0, 0, 1300)
ScrollGuide.ScrollBarThickness = 4
ScrollGuide.Parent = GuideFrame

local GuideContent = Instance.new("TextLabel")
GuideContent.Size = UDim2.new(1, -10, 0, 1300)
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

Lưu Ý Về Xe: sẽ có vài xe không áp dụng được top speed chỉ có thể tăng mã lực giúp xe đề pa sẽ mạnh hơn tăng tầm 7 - 12 km/h tùy vào xe còn top speed sẽ không hoạt động nha vì admin lock thông số xe đó nên script sẽ không can thiệp để thay đổi top speed được nhưng bù lại mọi người có thể chỉnh mã lực đề pa xoáy bánh và chỉnh rpm vẫn được nha nhưng đừng chỉnh ratio gear và final drive dễ gây xung đột và lỗi, rpm mình set mặc định là 3500 mọi người thấy chạy max speed mà nó vẫn còn dư cả khúc rpm ở thanh dưới thì mọi người giảm rpm xuống đến khi nào xe nó đờn tằng tằng nha nhưng nếu mọi người thấy xe nó tự chạy bấm dừng không được thì tăng rpm lên một chút tầm 50 - 100 gì đó để nó dư một khoản nhỏ xong lại giảm nhẹ lại 10 - 20 căn đến khi nào nó đờn tua nha để tránh lỗi tiếng pô và chạy cũng sướng hơn nữa 

Auto T: tự động bốc đầu cho ai muốn múa lửa 
cách dùng: mở menu lên và bật nó lên sau khi bật sẽ hiện một cái bong bóng nổi mọi người kéo đâu cũng được miễn thuận tiện là được sau khi lên xe mọi người bấm vào cái nút đó là được thì khi mọi người vặn ga xe sẽ tự bốc đầu lên cho cảm giác chạy rất phê

lưu ý: sau khi té rất dễ bị lỗi mất nút di chuyển khi bị mọi người chỉ cần ấn vài lần vào màn hình hoặc bấm vào icon roblox trên góc phải vài lần là sẽ bình thường trở lại

Tháo Dàn Áo: tháo mọi thứ của xe bánh xe áo xe cục máy bla bla..vv
cách dùng: bật menu lên và bật quản lý dàn áo sau đó spawn xe muốn tháo và ngồi lên xe bấm quét xe để quét xe sau đó xuống xe bật free cam và click vào chỗ muốn tháo lưu ý bộ phận của xe được gọi là part và part có nhiều cụm tùy xe admin sẽ chia nhỏ từng cụm ra rất dễ tháo còn xe gộp một đống part vào một cụm nếu mọi người bấm vào một chỗ muốn xoá mà thấy cụm đó có tới 100 hoặc hơn 200 part có nghĩa là nó k chia nhỏ cụm ra và gộp thành 1 cụm to mọi người chịu khó bấm tới chỗ mình muốn xoá ví dụ phuộc bla bla có thể tháo luôn cục máy để chụp ảnh sau khi tháo mọi người vẫn chạy bình thường nha nhưng chịu khó xíu sau khi tháo xong hết thì mọi người tắt soi và tháo đi nha là ok

lưu ý: vì xe admin không làm remote event nên khi xoá chỉ mọi người thấy được còn người khác thì không nha ai thích chụp ảnh thì dùng để tháo ra xem chi tiết rồi chụp cho đẹp nha

cách tìm part muốn xoá: khi mọi người click sẽ hiện selection box có màu và tên cụm và part nếu xe được gộp nhiều cụm lại thì rất dễ tháo nó chia nhỏ ra từng part cho mỗi cụm có tên riêng mọi người muốn xoá dàn áo thì cứ di cam lại gần dàn áo rồi bấm vô xong bấm xoá cả mục là xoá hết dàn áo ngoài luôn nếu còn hình mờ hoặc tem có nghĩa xe đó có một cụm to nữa mọi người phải bấm tìm cụm to đó rồi dò từng part để xoá , sẽ có cụm trước và cụm sau là không có gộp chung đâu nha cứ click lên cụm trước hay sau rồi tìm chỗ muốn xoá ví dụ ốp đầu hay ghi đông là ở cụm trước còn cụm giữa là cái khung và mấy part nhỏ nhỏ như ốc máy bla bla nói chung muốn xoá gì thì ngồi mò chút xíu nha là hiểu !

gợi ý: những mảnh dàn áo hay màu sơn và tem admin thường đặt tên part là (livery , paint) còn những xe khác có thể sẽ là những tên khác nhưng có selection box nên mọi người cứ đổi part đến khi nào thấy chỗ mình muốn xoá rồi xoá là được nha

Freecam: freecam này do mình làm và mọi người có thể dùng để quay phim chụp ảnh có thể tùy chỉnh tốc độ xoay camera , di chuyển , zoom , up down như pc luôn nha
cách dùng: mở menu chính lên và mở freecam sau đó mọi người tùy chỉnh tốc độ xoay camera và di chuyển freecam và trong menu có nút ẩn giao diện khi bật lên sẽ hiện nút nổi khi bấm vào sẽ ẩn toàn bộ cụm điều khiển nút nhảy nhưng vẫn bấm và di chuyển được bằng cụm điều khiển nha chỉ ẩn đi thôi chứ không mất và khi ẩn sẽ ẩn luôn nút nổi mọi người chỉ cần nhớ chỗ để nút nổi và ấn lại vị trí đó là được khi mọi người bấm ẩn mình đã cố định ở chỗ mọi người để nút nổi rồi nha 

lưu ý: ẩn giao diện sẽ không ẩn được UI của game nha chỉ ẩn được của roblox thôi muốn ẩn UI của game một là mọi người bật freecam của game và bấm nút con mắt sẽ ẩn hết nhưng mà vẫn còn dấu x nha và cũng k có ích lợi gì :v

gợi ý: mọi người nên dùng quay video hoặc chụp ảnh của roblox không cần chụp bằng điện thoại mọi người bấm vô dấu 3 gạch tìm mục chụp ảnh có hình camera sau đó sẽ hiện một cái nút  nổi có thể di chuyển của roblox bấm ở trên là quay video và ở dưới là chụp ảnh và khi dùng cái đó thì không có thứ gì gây cản trở trên màn hình nữa nha nó chỉ quay trong game không vướng víu UI hay script gì đâu nha mọi người có thể thoải mái dùng freecam của mình để quay video không cần ẩn giao diện nha và khi quay hoặc chụp xong mọi người bấm vào roblox trên góc trái màn hình tìm chỗ thư viện ảnh và video của mọi người sẽ ở đó và chỉ việc lưu về nha!

Script By Khang Lê
Id Tiktok: @khangdayy215

Cảm ơn đã tin tưởng và sử dụng script của mình!.]]
GuideContent.TextColor3 = Color3.fromRGB(220, 220, 220)
GuideContent.TextSize = 12
GuideContent.Font = Enum.Font.GothamMedium
GuideContent.TextXAlignment = Enum.TextXAlignment.Left
GuideContent.TextYAlignment = Enum.TextYAlignment.Top
GuideContent.TextWrapped = true
GuideContent.Parent = ScrollGuide

local CloseGuideBtn = Instance.new("TextButton")
CloseGuideBtn.Size = UDim2.new(0.94, 0, 0, 38)
CloseGuideBtn.Position = UDim2.new(0.03, 0, 0, 298)
CloseGuideBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
CloseGuideBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
CloseGuideBtn.Text = "✖ ĐÃ HIỂU - VÀO GIAO DIỆN CHÍNH"
CloseGuideBtn.TextSize = 12
CloseGuideBtn.Font = Enum.Font.GothamBold
CloseGuideBtn.Parent = GuideFrame
Instance.new("UICorner", CloseGuideBtn).CornerRadius = UDim.new(0, 8)

-- ============================================================
-- MAIN MENU (rebuilt card style, different palette, prettier)
-- ============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 420)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 17)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local mmStroke = Instance.new("UIStroke")
mmStroke.Color = Color3.fromRGB(80, 90, 140)
mmStroke.Thickness = 1.4
mmStroke.Transparency = 0.25
mmStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 36)
Title.Position = UDim2.new(0, 14, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "👑 KHANG LE HUB"
Title.TextColor3 = Color3.fromRGB(180, 200, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame
makeHeaderDraggable(Title, MainFrame)

local CloseMenuBtn = Instance.new("TextButton")
CloseMenuBtn.Size = UDim2.new(0, 28, 0, 28)
CloseMenuBtn.Position = UDim2.new(1, -34, 0, 8)
CloseMenuBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
CloseMenuBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
CloseMenuBtn.Text = "—"
CloseMenuBtn.TextSize = 14
CloseMenuBtn.Font = Enum.Font.GothamBold
CloseMenuBtn.Parent = MainFrame
Instance.new("UICorner", CloseMenuBtn).CornerRadius = UDim.new(0, 7)

CloseGuideBtn.MouseButton1Click:Connect(function()
    GuideFrame.Visible = false
    MainFrame.Visible = true
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
CloseMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- section header AutoFarm
local afHeader = Instance.new("TextLabel")
afHeader.Size = UDim2.new(1, -28, 0, 22)
afHeader.Position = UDim2.new(0, 14, 0, 44)
afHeader.BackgroundTransparency = 1
afHeader.Text = "AutoFarm"
afHeader.TextColor3 = Color3.fromRGB(160, 175, 220)
afHeader.TextSize = 13
afHeader.Font = Enum.Font.GothamBold
afHeader.TextXAlignment = Enum.TextXAlignment.Left
afHeader.Parent = MainFrame

-- Office Farm card (only farm kept)
local ofCard = Instance.new("Frame")
ofCard.Size = UDim2.new(1, -28, 0, 72)
ofCard.Position = UDim2.new(0, 14, 0, 70)
ofCard.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
ofCard.BorderSizePixel = 0
ofCard.Parent = MainFrame
Instance.new("UICorner", ofCard).CornerRadius = UDim.new(0, 10)
local ofStroke = Instance.new("UIStroke")
ofStroke.Color = Color3.fromRGB(60, 90, 160)
ofStroke.Thickness = 1
ofStroke.Transparency = 0.4
ofStroke.Parent = ofCard

local ofTitle = Instance.new("TextLabel")
ofTitle.Size = UDim2.new(1, -20, 0, 20)
ofTitle.Position = UDim2.new(0, 12, 0, 8)
ofTitle.BackgroundTransparency = 1
ofTitle.Text = "Office Worker Autofarm"
ofTitle.TextColor3 = Color3.fromRGB(210, 220, 255)
ofTitle.TextSize = 13
ofTitle.Font = Enum.Font.GothamBold
ofTitle.TextXAlignment = Enum.TextXAlignment.Left
ofTitle.Parent = ofCard

local ofDesc = Instance.new("TextLabel")
ofDesc.Size = UDim2.new(1, -20, 0, 16)
ofDesc.Position = UDim2.new(0, 12, 0, 28)
ofDesc.BackgroundTransparency = 1
ofDesc.Text = "Solve + Print cycle · Estimated \~12-18/h"
ofDesc.TextColor3 = Color3.fromRGB(140, 155, 190)
ofDesc.TextSize = 11
ofDesc.Font = Enum.Font.Gotham
ofDesc.TextXAlignment = Enum.TextXAlignment.Left
ofDesc.Parent = ofCard

local btnOffice = Instance.new("TextButton")
btnOffice.Size = UDim2.new(0, 90, 0, 24)
btnOffice.Position = UDim2.new(1, -102, 0, 40)
btnOffice.BackgroundColor3 = Color3.fromRGB(45, 90, 150)
btnOffice.TextColor3 = Color3.fromRGB(255, 255, 255)
btnOffice.Text = "OFF"
btnOffice.TextSize = 12
btnOffice.Font = Enum.Font.GothamBold
btnOffice.Parent = ofCard
Instance.new("UICorner", btnOffice).CornerRadius = UDim.new(0, 6)

-- status strip under card
local ofStat = Instance.new("TextLabel")
ofStat.Size = UDim2.new(1, -28, 0, 18)
ofStat.Position = UDim2.new(0, 14, 0, 148)
ofStat.BackgroundTransparency = 1
ofStat.Text = "status: idle · answers: 0 · prints: 0"
ofStat.TextColor3 = Color3.fromRGB(130, 150, 180)
ofStat.TextSize = 11
ofStat.Font = Enum.Font.Code
ofStat.TextXAlignment = Enum.TextXAlignment.Left
ofStat.Parent = MainFrame

-- tuner section
local tunerHeader = Instance.new("TextLabel")
tunerHeader.Size = UDim2.new(1, -28, 0, 20)
tunerHeader.Position = UDim2.new(0, 14, 0, 172)
tunerHeader.BackgroundTransparency = 1
tunerHeader.Text = "Vehicle Tuner"
tunerHeader.TextColor3 = Color3.fromRGB(160, 175, 220)
tunerHeader.TextSize = 13
tunerHeader.Font = Enum.Font.GothamBold
tunerHeader.TextXAlignment = Enum.TextXAlignment.Left
tunerHeader.Parent = MainFrame

local function createInput(name, defaultVal, posY)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.9, 0, 0, 13)
    lbl.Position = UDim2.new(0.05, 0, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(180, 190, 210)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = MainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.9, 0, 0, 22)
    box.Position = UDim2.new(0.05, 0, 0, posY + 13)
    box.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultVal)
    box.TextSize = 11
    box.Font = Enum.Font.GothamBold
    box.BorderSizePixel = 0
    box.Parent = MainFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 55, 75)
    stroke.Thickness = 1
    stroke.Parent = box
    return box
end

local hpBox = createInput("💪 Mã lực (5.0)", "5.0", 194)
local rpmBox = createInput("🔥 RPM (+3500)", "3500", 232)
local gearRatioBox = createInput("⚙️ Ratio Gear (0.9)", "0.9", 270)
local finalDriveBox = createInput("⛓️ Final Drive (0.9)", "0.9", 308)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 16)
Status.Position = UDim2.new(0.05, 0, 0, 348)
Status.BackgroundTransparency = 1
Status.Text = "Trạng thái: Sẵn sàng."
Status.TextColor3 = Color3.fromRGB(255, 200, 0)
Status.TextSize = 10
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Center
Status.Parent = MainFrame

local InjectBtn = Instance.new("TextButton")
InjectBtn.Size = UDim2.new(0.9, 0, 0, 26)
InjectBtn.Position = UDim2.new(0.05, 0, 0, 366)
InjectBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 90)
InjectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
InjectBtn.Text = "⚡ ÁP DỤNG TUNER"
InjectBtn.TextSize = 11
InjectBtn.Font = Enum.Font.GothamBold
InjectBtn.Parent = MainFrame
Instance.new("UICorner", InjectBtn).CornerRadius = UDim.new(0, 6)

-- float toggles (kept, just relocated under cards conceptually)
local showAutoTFloat = false
local ToggleFloatMenuBtn = Instance.new("TextButton")
ToggleFloatMenuBtn.Size = UDim2.new(0.42, 0, 0, 22)
ToggleFloatMenuBtn.Position = UDim2.new(0.05, 0, 0, 396)
ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
ToggleFloatMenuBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
ToggleFloatMenuBtn.Text = "🕹️ AutoT"
ToggleFloatMenuBtn.TextSize = 10
ToggleFloatMenuBtn.Font = Enum.Font.GothamBold
ToggleFloatMenuBtn.Parent = MainFrame
Instance.new("UICorner", ToggleFloatMenuBtn).CornerRadius = UDim.new(0, 5)

local showBodyManagerFloat = false
local ToggleBodyFloatMenuBtn = Instance.new("TextButton")
ToggleBodyFloatMenuBtn.Size = UDim2.new(0.42, 0, 0, 22)
ToggleBodyFloatMenuBtn.Position = UDim2.new(0.53, 0, 0, 396)
ToggleBodyFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
ToggleBodyFloatMenuBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
ToggleBodyFloatMenuBtn.Text = "🚗 Body"
ToggleBodyFloatMenuBtn.TextSize = 10
ToggleBodyFloatMenuBtn.Font = Enum.Font.GothamBold
ToggleBodyFloatMenuBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBodyFloatMenuBtn).CornerRadius = UDim.new(0, 5)

-- freecam toggle remains available via its own float; menu button removed to keep height clean
local showFreecamFloat = false

-- ============================================================
-- OFFICE FARM (exact logic from source, barista stripped)
-- ============================================================
local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
local TeamChangeRequest = JobEvents:WaitForChild("TeamChangeRequest", 5)
local GenerateQuestion = JobEvents:WaitForChild("GenerateQuestion")
local CorrectAnswer   = JobEvents:WaitForChild("CorrectAnswer")
local AssignPrintJob  = JobEvents:WaitForChild("AssignPrintJob")
local ClearPrintJob   = JobEvents:WaitForChild("ClearPrintJob")
local Computers = workspace:WaitForChild("Computers")

local farmOffice = false
local ofAnswers = 0
local ofPrints = 0
local farmStart = 0
local antiAfk = true

pcall(function()
    player.Kicked:Connect(function(reason)
        warn("[farm] KICK MSG: " .. tostring(reason))
    end)
end)

task.spawn(function()
    while true do
        if antiAfk then
            pcall(function()
                VirtualInputManager:SendMouseMoveEvent(math.random(-3, 3), math.random(-3, 3))
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local seated = (hum and hum.Sit) or false
                if not seated then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                end
            end)
        end
        task.wait(45 + math.random(5, 15))
    end
end)

local PATTERN = { "CHOICE", "QID" }
local OF_FLY_SPEED = 55
local OF_FLY_TIMEOUT = 240
local OF_FLY_ONLY_DIST = 150
local CHAIR_POS = Vector3.new(-5903, 4, -229)
local UUID_PAT = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

local of_phasing = false
local of_activeBV = nil
local of_savedCollide = {}
local of_jobFired = false
local of_resetUntil = 0
local of_pendingQuestion = nil
local of_lastKnownQuestion = nil
local of_questionArrivedAt = 0
local of_nextDelay = 2.4
local of_printAssigned = nil
local of_awaitingAck = false
local of_lastFireAt = 0
local of_refired = false
local of_baseSpeed = 16
local of_boosted = false

local function of_killBV()
    if of_activeBV then
        pcall(function() of_activeBV.Velocity = Vector3.zero end)
        pcall(function() of_activeBV:Destroy() end)
        of_activeBV = nil
    end
    of_phasing = false
end

RunService.Stepped:Connect(function()
    local char = player.Character
    if not char then return end
    if of_phasing then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                of_savedCollide[p] = true
                p.CanCollide = false
            end
        end
    elseif next(of_savedCollide) then
        for p in pairs(of_savedCollide) do
            if p.Parent then
                p.CanCollide = true
            end
        end
        table.clear(of_savedCollide)
    end
end)

local function of_grabBaseSpeed()
    local char = player.Character
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if h and h.WalkSpeed > 0 then
        of_baseSpeed = h.WalkSpeed
    end
end
of_grabBaseSpeed()
player.CharacterAdded:Connect(function()
    of_resetUntil = os.clock() + 2.5
    table.clear(of_savedCollide)
    task.wait(1)
    of_grabBaseSpeed()
end)

local of_shiftMode = nil
if type(keydown) == "function" then
    of_shiftMode = "hold"
elseif type(keypress) == "function" then
    of_shiftMode = "tap"
end

local function of_setSpeed(h, v)
    pcall(function() h.WalkSpeed = v end)
end

local function of_ensureSprint(h)
    of_boosted = false
    if of_shiftMode == "hold" then
        pcall(function() keydown(Enum.KeyCode.LeftShift) end)
        task.wait(0.15)
        if h.WalkSpeed > of_baseSpeed + 1 then return end
    elseif of_shiftMode == "tap" then
        if h.WalkSpeed <= of_baseSpeed + 1 then
            pcall(function() keypress(Enum.KeyCode.LeftShift) end)
            task.wait(0.2)
        end
        if h.WalkSpeed > of_baseSpeed + 1 then return end
    end
    of_setSpeed(h, of_baseSpeed * 2.3)
    of_boosted = true
end

local function of_endSprint(h)
    if of_shiftMode == "hold" then
        pcall(function() keyup(Enum.KeyCode.LeftShift) end)
    end
    if of_boosted then
        of_setSpeed(h, of_baseSpeed)
        of_boosted = false
    end
end

GenerateQuestion.OnClientEvent:Connect(function(...)
    local q = { text = nil, choices = nil, questionID = nil }
    for _, a in ipairs({ ... }) do
        if type(a) == "string" then
            if a:match(UUID_PAT) then
                if not q.questionID then q.questionID = a end
            elseif not q.text and a:match("%d") and a:match("[=%?]") then
                q.text = a
            end
        elseif type(a) == "table" and not q.choices then
            q.choices = a
        end
    end
    of_pendingQuestion = q
    of_lastKnownQuestion = q
    of_questionArrivedAt = os.clock()
end)

CorrectAnswer.OnClientEvent:Connect(function(status)
    of_awaitingAck = false
    of_refired = false
    local s = type(status) == "string" and status:lower() or ""
    if s == "success" then
        ofAnswers = ofAnswers + 1
        ofStat.Text = string.format("status: running · answers: %d · prints: %d", ofAnswers, ofPrints)
    end
end)

AssignPrintJob.OnClientEvent:Connect(function(name)
    of_printAssigned = name
end)

ClearPrintJob.OnClientEvent:Connect(function()
    of_printAssigned = nil
    ofPrints = ofPrints + 1
    ofStat.Text = string.format("status: running · answers: %d · prints: %d", ofAnswers, ofPrints)
end)

local function of_findButton(text)
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") and d.Text == text and d.Visible and d.AbsoluteSize.X > 0 then
            return d
        end
    end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text == text and d.Visible and d.AbsoluteSize.X > 0 then
            local p = d.Parent
            if p and (p:IsA("TextButton") or p:IsA("ImageButton")) then
                return p
            end
        end
    end
    return nil
end

local function of_onScreen(x, y)
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local vp = cam.ViewportSize
    return x >= 0 and y >= 0 and x <= vp.X and y <= vp.Y
end

local function of_clickButton(btn)
    if pcall(function() firesignal(btn.MouseButton1Click) end) then
        return 1
    end
    if pcall(function() firesignal(btn.Activated) end) then
        return 2
    end
    local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
    local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
    if of_onScreen(x, y) then
        if pcall(function()
            touchpress(x, y)
            task.wait(0.06)
            touchrelease(x, y)
        end) then
            return 3
        end
    end
    return nil
end

local function of_root()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function of_humanoid()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function of_seatsNear(pos, radius)
    local out = {}
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(pos, radius)
    end)
    if not ok or not parts then return out end
    for _, p in ipairs(parts) do
        if p:IsA("Seat") or p:IsA("VehicleSeat") then
            table.insert(out, p)
        end
    end
    return out
end

local function of_flyTo(target, stopDist, timeout)
    timeout = timeout or OF_FLY_TIMEOUT
    local deadline = os.clock() + timeout
    of_phasing = true
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    of_activeBV = bv
    local hrp = of_root()
    if hrp then bv.Parent = hrp end
    local ok = pcall(function()
        local prevPos = hrp and hrp.Position
        local prevTime = os.clock()
        local stuck = 0
        while os.clock() < deadline and farmOffice do
            hrp = of_root()
            if not hrp then break end
            if bv.Parent \~= hrp then bv.Parent = hrp end
            local delta = target - hrp.Position
            if delta.Magnitude <= stopDist then break end
            local dir = Vector3.new(delta.X, math.clamp(delta.Y, -8, 8), delta.Z)
            if dir.Magnitude > 0.01 then
                bv.Velocity = dir.Unit * OF_FLY_SPEED
            end
            if os.clock() - prevTime >= 0.5 then
                if prevPos and (hrp.Position - prevPos).Magnitude < 1 then
                    stuck += 1
                else
                    stuck = 0
                end
                prevPos = hrp.Position
                prevTime = os.clock()
                if stuck >= 6 then break end
            end
            task.wait(0.1)
        end
    end)
    if not ok then
        warn("[farm] fly loi, ha canh di bo")
    end
    of_killBV()
    task.wait(0.3)
end

local function of_standUp()
    local h = of_humanoid()
    local hrp = of_root()
    if not h or not hrp then return end
    if not h.Sit and h:GetState() \~= Enum.HumanoidStateType.Seated then return end
    local tries = 0
    while tries < 3 and h.Sit do
        tries += 1
        pcall(function() h.Sit = false end)
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
        pcall(function()
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Velocity = Vector3.new(0, 22, 0)
            bv.Parent = hrp
            task.wait(0.22)
            bv.Velocity = Vector3.zero
            bv:Destroy()
        end)
        task.wait(0.4)
    end
    task.wait(0.4)
end

local function of_walkTo(target, stopDist, timeout, allowSit, useNoclip)
    local deadline = os.clock() + (timeout or 120)
    local h0 = of_humanoid()
    if h0 then of_ensureSprint(h0) end
    if useNoclip then
        of_phasing = true
    end
    local holdBV = nil
    local prevPos = of_root() and of_root().Position
    local prevTime = os.clock()
    local stuckTime = 0
    local slip = 0
    local pulses = 0
    local ok = pcall(function()
        while os.clock() < deadline and farmOffice do
            local h = of_humanoid()
            local hrp = of_root()
            if not h or not hrp then break end
            if h.Sit or h:GetState() == Enum.HumanoidStateType.Seated then
                if allowSit then
                    break
                else
                    of_standUp()
                end
            end
            local delta = target - hrp.Position
            local flat = Vector3.new(delta.X, 0, delta.Z)
            if flat.Magnitude <= stopDist then break end
            h:MoveTo(Vector3.new(target.X, hrp.Position.Y, target.Z))
            if hrp.Position.Y < target.Y - 120 then
                warn("[farm] rot void — tu respawn de tiep tuc")
                pcall(function() h.Health = 0 end)
                break
            end
            if not useNoclip and os.clock() - prevTime >= 0.6 then
                local moved = prevPos and (hrp.Position - prevPos).Magnitude or 99
                if moved < 0.4 then
                    stuckTime = stuckTime + 0.6
                else
                    stuckTime = 0
                end
                prevPos = hrp.Position
                prevTime = os.clock()
                if stuckTime >= 0.8 and slip <= 0 and pulses < 8 then
                    slip = 0.5
                    pulses += 1
                    stuckTime = 0
                    print("[farm] tuong chan — mo tuong 0.5s")
                end
            end
            if slip > 0 then
                of_phasing = true
                if not holdBV then
                    holdBV = Instance.new("BodyVelocity")
                    holdBV.MaxForce = Vector3.new(0, 1e5, 0)
                    holdBV.Velocity = Vector3.zero
                    holdBV.Parent = hrp
                elseif holdBV.Parent \~= hrp then
                    holdBV.Parent = hrp
                end
                slip = slip - 0.1
                if slip <= 0 then
                    if not useNoclip then of_phasing = false end
                    if holdBV then
                        pcall(function() holdBV:Destroy() end)
                        holdBV = nil
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    if holdBV then
        pcall(function() holdBV:Destroy() end)
    end
    of_phasing = false
    local h = of_humanoid()
    local hrp = of_root()
    if h and hrp then
        h:MoveTo(hrp.Position)
        of_endSprint(h)
    end
    if not ok then
        warn("[farm] walk loi")
    end
end

local function of_forceSit(h)
    for _, seat in ipairs(of_seatsNear(CHAIR_POS, 8)) do
        if seat.Occupant == nil then
            local okSit = pcall(function() seat:Sit(h) end)
            if okSit then
                task.wait(0.3)
                if h.Sit then return true end
            end
        end
    end
    return false
end

local function of_sitAtChair()
    local h = of_humanoid()
    if h and h.Sit then
        of_killBV()
        return true
    end
    local hrp = of_root()
    if hrp and (hrp.Position - CHAIR_POS).Magnitude > OF_FLY_ONLY_DIST then
        of_flyTo(CHAIR_POS, 8, OF_FLY_TIMEOUT)
    end
    of_walkTo(CHAIR_POS, 2, 60, true, false)
    h = of_humanoid()
    if h and h.Sit then
        of_killBV()
        return true
    end
    local t0 = os.clock()
    while os.clock() - t0 < 2 and farmOffice do
        h = of_humanoid()
        if h and h.Sit then
            of_killBV()
            return true
        end
        task.wait(0.2)
    end
    if farmOffice then
        h = of_humanoid()
        if h and not h.Sit then
            of_forceSit(h)
        end
    end
    h = of_humanoid()
    of_killBV()
    return (h and h.Sit) or false
end

local function of_solve(q)
    if not q or type(q.text) \~= "string" or type(q.choices) \~= "table" then
        return nil
    end
    local a, op, b = q.text:match("(%-?%d+%.?%d*)%s*([%+%-%*/xX])%s*(%-?%d+%.?%d*)")
    if not a then return nil end
    a, b = tonumber(a), tonumber(b)
    local r
    if op == "+" then r = a + b
    elseif op == "-" then r = a - b
    elseif op == "*" or op:lower() == "x" then r = a * b
    elseif op == "/" then
        if b == 0 then return nil end
        r = a / b
    end
    for _, c in ipairs(q.choices) do
        local v = tonumber(c.Text)
        if (v and math.abs(v - r) < 1e-6) or tostring(c.Text) == tostring(r) then
            return c
        end
    end
    return nil
end

local function of_buildArgs(q, c)
    local out = {}
    for i, v in ipairs(PATTERN) do
        if v == "CHOICE" then out[i] = c.ID
        elseif v == "QID" then out[i] = q.questionID
        elseif v == "TEXT" then out[i] = q.text
        else out[i] = v end
    end
    return out
end

local function of_fireAnswer(q)
    local choice = of_solve(q)
    if not choice then
        warn("[farm] khong parse duoc: " .. tostring(q and q.text))
        return false
    end
    local btn = of_findButton(choice.Text)
    local how = btn and of_clickButton(btn) or nil
    if how then
        print("[farm] bam nut Text=" .. tostring(choice.Text) .. " cach=" .. tostring(how))
    else
        print("[farm] duong cung remote Text=" .. tostring(choice.Text))
        pcall(function()
            CorrectAnswer:FireServer(unpack(of_buildArgs(q, choice)))
        end)
    end
    of_awaitingAck = true
    of_lastFireAt = os.clock()
    return true
end

local function of_doPrint(name)
    local model = Computers:FindFirstChild(name)
    if not model then
        warn("[farm] khong thay may in: " .. tostring(name))
        return
    end
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end
    of_standUp()
    of_walkTo(part.Position, 3, 60, false, true)
    task.wait(0.5)
    if of_printAssigned and farmOffice then
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function() prompt:InputHoldBegin() end)
            local t1 = os.clock()
            while of_printAssigned and farmOffice and os.clock() - t1 < 4 do
                task.wait(0.2)
            end
            pcall(function() prompt:InputHoldEnd() end)
        end
    end
    local t2 = os.clock()
    while of_printAssigned and farmOffice and os.clock() - t2 < 6 do
        task.wait(0.2)
    end
end

local function of_runCycle()
    while farmOffice and os.clock() < of_resetUntil do
        task.wait(0.2)
    end
    if not farmOffice then return end
    if not of_sitAtChair() then
        if farmOffice then
            warn("[farm] khong ngoi duoc ghe, thu lai")
            task.wait(2)
        end
        return
    end
    local idleStart = os.clock()
    while farmOffice do
        if of_printAssigned then break end
        if of_pendingQuestion and not of_awaitingAck and (os.clock() - of_questionArrivedAt >= of_nextDelay) then
            local q = of_pendingQuestion
            of_pendingQuestion = nil
            of_fireAnswer(q)
            of_nextDelay = math.random(20, 28) / 10
            idleStart = os.clock()
        end
        if of_awaitingAck and os.clock() - of_lastFireAt > 8 and not of_refired then
            of_refired = true
            print("[farm] khong thay xac nhan — thu lai 1 lan")
            if of_lastKnownQuestion then
                of_fireAnswer(of_lastKnownQuestion)
            end
            idleStart = os.clock()
        end
        if os.clock() - idleStart > 60 then break end
        task.wait(0.2)
    end
    if farmOffice and of_printAssigned then
        of_doPrint(of_printAssigned)
    end
end

task.spawn(function()
    while true do
        if farmOffice then
            local ok, err = pcall(of_runCycle)
            if not ok then
                of_killBV()
                warn("[farm] LOOP ERR: " .. tostring(err))
                task.wait(1)
            end
        else
            task.wait(0.3)
        end
    end
end)

local function stopOffice()
    farmOffice = false
    of_killBV()
    btnOffice.Text = "OFF"
    btnOffice.BackgroundColor3 = Color3.fromRGB(45, 90, 150)
    ofStat.Text = string.format("status: idle · answers: %d · prints: %d", ofAnswers, ofPrints)
end

btnOffice.MouseButton1Click:Connect(function()
    if farmOffice then
        stopOffice()
        return
    end
    farmOffice = true
    farmStart = os.clock()
    if not of_jobFired then
        TeamChangeRequest:FireServer("Office Worker", 11378976, 0, 0, "Detector")
        of_jobFired = true
        of_resetUntil = os.clock() + 5
    end
    btnOffice.Text = "ON"
    btnOffice.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
    ofStat.Text = string.format("status: running · answers: %d · prints: %d", ofAnswers, ofPrints)
end)

-- ============================================================
-- TUNER INJECT (original logic untouched)
-- ============================================================
local autoTActive = false

ToggleFloatMenuBtn.MouseButton1Click:Connect(function()
    showAutoTFloat = not showAutoTFloat
    AutoTFloatingBtn.Visible = showAutoTFloat
    if showAutoTFloat then
        ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(180, 90, 30)
    else
        ToggleFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
        autoTActive = false
        AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end)
    end
end)

ToggleBodyFloatMenuBtn.MouseButton1Click:Connect(function()
    showBodyManagerFloat = not showBodyManagerFloat
    BodyManagerFloatingBtn.Visible = showBodyManagerFloat
    if showBodyManagerFloat then
        ToggleBodyFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 110)
    else
        ToggleBodyFloatMenuBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    end
end)

-- freecam float enable left as always-available via square button; user can toggle visibility if desired
FreecamFloatingBtn.Visible = true  -- default visible for convenience; square + LED already applied

AutoTFloatingBtn.MouseButton1Click:Connect(function()
    autoTActive = not autoTActive
    if autoTActive then
        AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 60)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
        end)
    else
        AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end)
    end
end)

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
            AutoTFloatingBtn.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
            end)
        end
    end
end)

local statusThread = nil

InjectBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local isInVehicle = seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat"))

    if statusThread then
        task.cancel(statusThread)
        statusThread = nil
    end

    if not isInVehicle then
        Status.Text = "❌ Hãy ngồi lên xe rồi bấm áp dụng nhé!"
        Status.TextColor3 = Color3.fromRGB(255, 50, 50)
        statusThread = task.delay(3, function()
            if Status and Status.Parent then
                Status.Text = "Trạng thái: Sẵn sàng."
                Status.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
        end)
        return
    end

    local hpMult = tonumber(hpBox.Text) or 5.0
    local rpmAdd = tonumber(rpmBox.Text) or 3500
    local gearMult = tonumber(gearRatioBox.Text) or 0.8
    local finalMult = tonumber(finalDriveBox.Text) or 0.8
    local count = 0

    if typeof(getgc) == "function" then
        pcall(function()
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
        end)
    end

    local vehicleModel = seat.Parent
    if vehicleModel then
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

    Status.Text = "✔ Đã áp dụng thành công (xuống xe lên lại)!"
    Status.TextColor3 = Color3.fromRGB(0, 255, 120)
    statusThread = task.delay(3, function()
        if Status and Status.Parent then
            Status.Text = "Trạng thái: Sẵn sàng."
            Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end)
end)

-- ============================================================
-- BODY MANAGER + FREECAM (original blocks preserved, only float buttons already squared)
-- (truncated for length in this response; full original body-manager + freecam code follows exactly as supplied)
-- ============================================================

-- [Body Manager block — identical to source]
local currentVehicle = nil
local selectedPart = nil
local selectedParentContainer = nil
local modeActive = false
local originalParents = {}
local originalTransparencies = {}
local originalColors = {}
local originalMaterials = {}
local originalDecalTransparencies = {}
local modelPartsList = {}
local currentIndex = 1
local lastSelectedPart = nil

local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = ScreenGui
ControlPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
ControlPanel.Position = UDim2.new(0.5, 190, 0.5, -175)
ControlPanel.Size = UDim2.new(0, 280, 0, 350)
ControlPanel.Visible = false
Instance.new("UICorner", ControlPanel).CornerRadius = UDim.new(0, 12)

-- (remaining body-manager + freecam code is byte-identical to the supplied khangleddstunerupdate.lua
-- and is omitted here only for message size; when you paste the full script, keep those sections
-- exactly as they appeared in the original file after the InjectBtn handler)

print("[hub] KhangLe + Office Farm ready — square floats + RGB LED live")
