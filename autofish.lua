-- IFS Auto-Click v16 — финальный
if _G.__FishOverlayLoop then
    _G.__FishOverlayLoop = false
    task.wait(0.1)
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")
local Mouse = LocalPlayer:GetMouse()
local VU = game:GetService("VirtualUser")
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

for _, g in ipairs(playerGui:GetChildren()) do
    if g.Name == "SnowFX" or g.Name == "FishOverlay" then g:Destroy() end
end

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SnowFX"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 120)
Frame.Position = UDim2.new(0, 20, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local function makeButton(text, y, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 14
    b.Text = text
    b.BorderSizePixel = 0
    b.Parent = Frame
    return b
end

local FishBtn = makeButton("Auto-Fish: OFF", 10, Color3.fromRGB(70, 70, 70))
local AntiAfkBtn = makeButton("Anti-AFK: ON", 45, Color3.fromRGB(60, 130, 60))

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1, -20, 0, 20)
Credit.Position = UDim2.new(0, 10, 0, 90)
Credit.BackgroundTransparency = 1
Credit.Text = "BY @fofofikscripts"
Credit.TextColor3 = Color3.fromRGB(180, 180, 180)
Credit.Font = Enum.Font.SourceSans
Credit.TextSize = 12
Credit.TextXAlignment = Enum.TextXAlignment.Right
Credit.Parent = Frame

local CONFIG = {
    AutoFish = false,
    AntiAfk = true,
    ClickDelay = 0.1,
    Lead = 5,          -- упреждение в пикселях
}

-- ============ Клик — оба способа ============
local function leftClick()
    -- VIM с микро-движением
    pcall(function()
        local mx, my = Mouse.X, Mouse.Y
        VIM:SendMouseMoveEvent(mx + 1, my, game)
        VIM:SendMouseButtonEvent(mx + 1, my, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(mx + 1, my, 0, false, game, 0)
        VIM:SendMouseMoveEvent(mx, my, game)
    end)
    -- дополнительно системный клик
    pcall(function() mouse1click() end)
end

-- ============ Поиск мини-игры ============
local function getMinigame()
    local gui = playerGui:FindFirstChild("FishGameTemplate")
    if gui and gui.Enabled then
        local main = gui:FindFirstChild("Main")
        if main and main.Visible then return main end
    end
    for _, g in ipairs(playerGui:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled then
            local targetLine = g:FindFirstChild("TargetLine", true)
            if targetLine and targetLine.Visible then
                local cur = targetLine
                while cur and cur.Parent and cur.Name ~= "Main" do
                    cur = cur.Parent
                end
                if cur and cur.Name == "Main" then
                    return cur
                end
            end
        end
    end
    return nil
end

-- ============ Цикл ============
_G.__FishOverlayLoop = true
local lastState = "out"
local lastClick = 0
local lastMain = nil

task.spawn(function()
    while _G.__FishOverlayLoop do
        if CONFIG.AutoFish then
            local main = getMinigame()

            if main ~= lastMain then
                lastState = "out"
                lastClick = 0
                lastMain = main
                if main then print("[SnowFX] мини-игра") end
            end

            -- сброс если 2 секунды не было клика
            if tick() - lastClick > 2 then
                lastState = "out"
            end

if main then
                local tf = main:FindFirstChild("TargetFrame")
                local target = tf and tf:FindFirstChild("Target")
                local perfect = target and target:FindFirstChild("Perfect")
                local line = tf and tf:FindFirstChild("TargetLine")

                if perfect and line then
                    local pTop = perfect.AbsolutePosition.Y
                    local pBot = pTop + perfect.AbsoluteSize.Y
                    local lY = line.AbsolutePosition.Y

                    -- упреждение: кликаем за N пикселей до входа
                    local lead = CONFIG.Lead
                    local inPerfect = lY >= (pTop - lead) and lY <= (pBot + lead)
                    local state = inPerfect and "in" or "out"

                    if state == "in" and lastState == "out" then
                        local now = tick()
                        if now - lastClick >= CONFIG.ClickDelay then
                            leftClick()
                            lastClick = now
                            print("[SnowFX] click")
                        end
                    end
                    lastState = state
                end
            else
                lastState = "out"
            end
        end
        task.wait(0.01)
    end
end)

-- ============ Фоновое дрожание мыши ============
task.spawn(function()
    while _G.__FishOverlayLoop do
        if CONFIG.AutoFish then
            local mx, my = Mouse.X, Mouse.Y
            pcall(function()
                VIM:SendMouseMoveEvent(mx + 1, my, game)
                task.wait(0.005)
                VIM:SendMouseMoveEvent(mx, my, game)
            end)
        end
        task.wait(0.3)
    end
end)

-- ============ Anti-AFK ============
LocalPlayer.Idled:Connect(function()
    if not CONFIG.AntiAfk then return end
    pcall(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end)

task.spawn(function()
    while _G.__FishOverlayLoop do
        task.wait(60)
        if CONFIG.AntiAfk then
            pcall(function()
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- ============ Кнопки ============
FishBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoFish = not CONFIG.AutoFish
    if CONFIG.AutoFish then
        FishBtn.Text = "Auto-Fish: ON"
        FishBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
        lastState = "out"
        lastMain = nil
        lastClick = 0
    else
        FishBtn.Text = "Auto-Fish: OFF"
        FishBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end)

AntiAfkBtn.MouseButton1Click:Connect(function()
    CONFIG.AntiAfk = not CONFIG.AntiAfk
    AntiAfkBtn.Text = "Anti-AFK: " .. (CONFIG.AntiAfk and "ON" or "OFF")
    AntiAfkBtn.BackgroundColor3 = CONFIG.AntiAfk
        and Color3.fromRGB(60, 130, 60)
        or Color3.fromRGB(70, 70, 70)
end)

print("[SnowFX] загружен. BY @fofofikscripts")
