local a=game:GetService("CoreGui")local b=game:GetService("Players")local c=game:GetService("RunService")local d=game:GetService("VirtualInputManager")local e=b.LocalPlayer
local f=nil pcall(function()f=gethui and gethui()or a end)if not f then f=e:WaitForChild("PlayerGui")end
if f:FindFirstChild("KhangLeCustomTuner")then f.KhangLeCustomTuner:Destroy()end
local g=Instance.new("ScreenGui")g.Name="KhangLeCustomTuner"g.ResetOnSpawn=false g.Parent=f
local h=Instance.new("TextButton")h.Size=UDim2.new(0,52,0,52)h.Position=UDim2.new(0,40,0.4,0)h.BackgroundColor3=Color3.fromRGB(15,15,15)h.TextColor3=Color3.fromRGB(255,215,0)h.Text="👑"h.TextSize=24 h.Font=Enum.Font.GothamBold h.Draggable=true h.Parent=g
local i=Instance.new("UICorner")i.CornerRadius=UDim.new(1,0)i.Parent=h
local j=Instance.new("UIStroke")j.Color=Color3.fromRGB(255,215,0)j.Thickness=2 j.Parent=h
local k=Instance.new("UIStroke")k.Color=Color3.fromRGB(0,0,0)k.Thickness=4 k.Transparency=0.5 k.Parent=h
local l=Instance.new("TextButton")l.Size=UDim2.new(0,52,0,52)l.Position=UDim2.new(0,40,0.55,0)l.BackgroundColor3=Color3.fromRGB(15,15,15)l.TextColor3=Color3.fromRGB(255,100,0)l.Text="🕹️"l.TextSize=24 l.Font=Enum.Font.GothamBold l.Draggable=true l.Visible=false l.Parent=g
local m=Instance.new("UICorner")m.CornerRadius=UDim.new(1,0)m.Parent=l
local n=Instance.new("UIStroke")n.Color=Color3.fromRGB(255,100,0)n.Thickness=2 n.Parent=l
local o=Instance.new("Frame")o.Size=UDim2.new(0,440,0,380)o.Position=UDim2.new(0.5,-220,0.5,-190)o.BackgroundColor3=Color3.fromRGB(15,15,18)o.BorderSizePixel=0 o.Active=true o.Draggable=true o.Visible=true o.Parent=g
local p=Instance.new("UICorner")p.CornerRadius=UDim.new(0,14)p.Parent=o
local q=Instance.new("UIStroke")q.Color=Color3.fromRGB(255,215,0)q.Thickness=1.8 q.Parent=o
local r=Instance.new("TextLabel")r.Size=UDim2.new(1,0,0,45)r.BackgroundTransparency=1 r.Text="📜 HƯỚNG DẪN SỬ DỤNG - KHANG LÊ TUNER"r.TextColor3=Color3.fromRGB(255,215,0)r.TextSize=13 r.Font=Enum.Font.GothamBold r.Parent=o
local s=Instance.new("ScrollingFrame")s.Size=UDim2.new(0.92,0,0,260)s.Position=UDim2.new(0.04,0,0,48)s.BackgroundTransparency=1 s.BorderSizePixel=0 s.CanvasSize=UDim2.new(0,0,0,680)s.ScrollBarThickness=4 s.Parent=o
local t=Instance.new("TextLabel")t.Size=UDim2.new(1,0,0,680)t.BackgroundTransparency=1 t.Text=[[Hướng dẫn xài - đọc kĩ trước khi sử dụng:
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

lưu ý: sau khi té rất dễ bị lỗi mất nút di chuyển khi bị mọi người chỉ cần ấn vài lần vào màn hình hoặc bấm vào icon roblox trên góc phải vài lần là sẽ bình thường trở lại.]]t.TextColor3=Color3.fromRGB(220,220,220)t.TextSize=12 t.Font=Enum.Font.GothamMedium t.TextXAlignment=Enum.TextXAlignment.Left t.TextYAlignment=Enum.TextYAlignment.Top t.TextWrapped=true t.Parent=s
local u=Instance.new("TextButton")u.Size=UDim2.new(0.92,0,0,36)u.Position=UDim2.new(0.04,0,0,320)u.BackgroundColor3=Color3.fromRGB(255,215,0)u.TextColor3=Color3.fromRGB(15,15,15)u.Text="✖ ĐÃ HIỂU - VÀO GIAO DIỆN CHÍNH"u.TextSize=12 u.Font=Enum.Font.GothamBold u.Parent=o
local v=Instance.new("UICorner")v.CornerRadius=UDim.new(0,8)v.Parent=u
local w=Instance.new("Frame")w.Size=UDim2.new(0,340,0,424)w.Position=UDim2.new(0.5,-170,0.5,-212)w.BackgroundColor3=Color3.fromRGB(14,14,18)w.BorderSizePixel=0 w.Active=true w.Draggable=true w.Visible=false w.Parent=g
local x=Instance.new("UICorner")x.CornerRadius=UDim.new(0,14)x.Parent=w
local y=Instance.new("UIStroke")y.Color=Color3.fromRGB(50,50,60)y.Thickness=1.5 y.Parent=w
u.MouseButton1Click:Connect(function()o.Visible=false w.Visible=true end)
h.MouseButton1Click:Connect(function()w.Visible=not w.Visible end)
local z=Instance.new("TextLabel")z.Size=UDim2.new(1,0,0,48)z.BackgroundTransparency=1 z.Text="👑 Khang Lê Custom Tuner"z.TextColor3=Color3.fromRGB(255,215,0)z.TextSize=15 z.Font=Enum.Font.GothamBold z.Parent=w
local A=Instance.new("TextButton")A.Size=UDim2.new(0,32,0,32)A.Position=UDim2.new(1,-38,0,8)A.BackgroundTransparency=1 A.TextColor3=Color3.fromRGB(180,180,180)A.Text="✕"A.TextSize=16 A.Font=Enum.Font.GothamBold A.Parent=w
A.MouseButton1Click:Connect(function()w.Visible=false end)
local function B(C,D,E)
local F=Instance.new("TextLabel")F.Size=UDim2.new(0.9,0,0,18)F.Position=UDim2.new(0.05,0,0,E)F.BackgroundTransparency=1 F.Text=C F.TextColor3=Color3.fromRGB(210,210,210)F.TextSize=11 F.Font=Enum.Font.GothamMedium F.TextXAlignment=Enum.TextXAlignment.Left F.Parent=w
local G=Instance.new("TextBox")G.Size=UDim2.new(0.9,0,0,30)G.Position=UDim2.new(0.05,0,0,E+18)G.BackgroundColor3=Color3.fromRGB(22,22,28)G.TextColor3=Color3.fromRGB(255,255,255)G.Text=tostring(D)G.TextSize=13 G.Font=Enum.Font.GothamBold G.BorderSizePixel=0 G.Parent=w
local H=Instance.new("UICorner")H.CornerRadius=UDim.new(0,8)H.Parent=G
local I=Instance.new("UIStroke")I.Color=Color3.fromRGB(60,60,75)I.Thickness=1 I.Parent=G
return G end
local J=B("💪 Hệ số Mã lực (Mặc định: 5.0)","5.0",48)
local K=B("🔥 Cộng thêm Tua máy - RPM (Mặc định: 3500)","3500",112)
local L=B("⚙️ Tỷ số truyền số - Ratio Gear (Mặc định: 0.8)","0.8",176)
local M=B("⛓️ Tỷ số truyền cuối - Final Drive (Mặc định: 0.8)","0.8",240)
local N=Instance.new("TextLabel")N.Size=UDim2.new(0.9,0,0,22)N.Position=UDim2.new(0.05,0,0,304)N.BackgroundTransparency=1 N.Text="Trạng thái: Sẵn sàng độ xe trực tiếp."N.TextColor3=Color3.fromRGB(255,200,0)N.TextSize=11 N.Font=Enum.Font.GothamBold N.TextXAlignment=Enum.TextXAlignment.Center N.Parent=w
local O=Instance.new("TextButton")O.Size=UDim2.new(0.9,0,0,34)O.Position=UDim2.new(0.05,0,0,330)O.BackgroundColor3=Color3.fromRGB(0,200,100)O.TextColor3=Color3.fromRGB(255,255,255)O.Text="⚡ ÁP DỤNG TUNER (TỨC THÌ)"O.TextSize=11 O.Font=Enum.Font.GothamBold O.Parent=w
local P=Instance.new("UICorner")P.CornerRadius=UDim.new(0,8)P.Parent=O
local Q=false
local R=Instance.new("TextButton")R.Size=UDim2.new(0.9,0,0,34)R.Position=UDim2.new(0.05,0,0,372)R.BackgroundColor3=Color3.fromRGB(30,30,40)R.TextColor3=Color3.fromRGB(255,255,255)R.Text="🕹️ NÚT NỔI AUTO T: ĐANG TẮT"R.TextSize=11 R.Font=Enum.Font.GothamBold R.Parent=w
local S=Instance.new("UICorner")S.CornerRadius=UDim.new(0,8)S.Parent=R
local T=false
R.MouseButton1Click:Connect(function()
Q=not Q l.Visible=Q
if Q then R.Text="🕹️ NÚT NỔI AUTO T: ĐANG BẬT"R.BackgroundColor3=Color3.fromRGB(200,100,0)
else R.Text="🕹️ NÚT NỔI AUTO T: ĐANG TẮT"R.BackgroundColor3=Color3.fromRGB(30,30,40)T=false l.BackgroundColor3=Color3.fromRGB(15,15,15)n.Color=Color3.fromRGB(255,100,0)
pcall(function()d:SendKeyEvent(false,Enum.KeyCode.T,false,game)end)end end)
l.MouseButton1Click:Connect(function()
T=not T
if T then l.BackgroundColor3=Color3.fromRGB(0,170,0)n.Color=Color3.fromRGB(0,255,120)
pcall(function()d:SendKeyEvent(true,Enum.KeyCode.T,false,game)end)
else l.BackgroundColor3=Color3.fromRGB(15,15,15)n.Color=Color3.fromRGB(255,100,0)
pcall(function()d:SendKeyEvent(false,Enum.KeyCode.T,false,game)end)end end)
c.Heartbeat:Connect(function()
local U=e.Character local V=U and U:FindFirstChildOfClass("Humanoid")local W=V and V.SeatPart
local X=(W and(W:IsA("VehicleSeat")or W:IsA("Seat")))
if T then
if X then pcall(function()d:SendKeyEvent(true,Enum.KeyCode.T,false,game)end)
else T=false l.BackgroundColor3=Color3.fromRGB(15,15,15)n.Color=Color3.fromRGB(255,100,0)
pcall(function()d:SendKeyEvent(false,Enum.KeyCode.T,false,game)end)end end end)
O.MouseButton1Click:Connect(function()
local Y=tonumber(J.Text)or 5.0 local Z=tonumber(K.Text)or 3500 local aa=tonumber(L.Text)or 0.8 local ab=tonumber(M.Text)or 0.8 local ac=0
if typeof(getgc)=="function"then
for _,ad in pairs(getgc(true))do
if typeof(ad)=="table"then
pcall(function()
for ae,af in pairs(ad)do
if type(ae)=="string"then
if ae=="Horsepower"or ae=="Torque"or ae=="MaxPower"then
if type(af)=="number"then ad[ae]=af*Y ac=ac+1 end
elseif ae=="Redline"or ae=="MaxRPM"or ae=="RPM"then
if type(af)=="number"then ad[ae]=af+Z ac=ac+1 end
elseif ae=="GearRatio"or ae=="FinalDrive"then
local ag=(ae=="FinalDrive")and ab or aa
if type(af)=="number"and af>0 then ad[ae]=af*ag ac=ac+1 end
elseif ae=="GearRatios"or ae=="Gears"then
if type(af)=="table"then
for ah,ai in pairs(af)do
if type(ai)=="number"then af[ah]=ai*aa ac=ac+1 end end end end end end end)end end end
local aj=e.Character local ak=aj and aj:FindFirstChildOfClass("Humanoid")local al=ak and ak.SeatPart
if al and(al:IsA("VehicleSeat")or al:IsA("Seat"))then
local am=al.Parent
for _,an in pairs(am:GetDescendants())do
if an:IsA("NumberValue")or an:IsA("IntValue")then
pcall(function()
local ao=an.Name:lower()
if ao:find("horsepower")or ao:find("power")then an.Value=an.Value*Y ac=ac+1
elseif ao:find("rpm")or ao:find("redline")then an.Value=an.Value+Z ac=ac+1
elseif ao:find("gear")or ao:find("ratio")then an.Value=an.Value*aa ac=ac+1
elseif ao:find("drive")then an.Value=an.Value*ab ac=ac+1 end end)end end end
if ac>0 or al then N.Text="✔ Đã áp dụng thành công (xuống xe lên lại)!"N.TextColor3=Color3.fromRGB(0,255,120)
else N.Text="❌ Hãy ngồi lên xe rồi bấm áp dụng nhé!"N.TextColor3=Color3.fromRGB(255,50,50)end
task.delay(3,function()if N and N.Parent then N.Text="Trạng thái: Sẵn sàng."N.TextColor3=Color3.fromRGB(255,200,0)end end)end)
