-- 📦 AutoFarmModule.lua: Tự động farm 5 tầng dungeon trong King Legacy với giao diện bật/tắt

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 🎯 Tọa độ vòng dịch chuyển Dungeon
local dungeonCircleCFrame = CFrame.new(10959.5859, 133.835114, 1250.04089)

-- 🎯 Tọa độ khu vực đánh quái trong Dungeon
local DUNGEON_POS = Vector3.new(20072.91, 15584.16, 20049.55)
local DUNGEON_RADIUS = 600

-- ✅ Kiểm tra đã vào dungeon chưa
local function isInDungeon()
    local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    return (HRP.Position - DUNGEON_POS).Magnitude < DUNGEON_RADIUS
end

-- 🛠 Chờ nhân vật load xong
local function waitForCharacter()
    while not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or not LocalPlayer.Character:FindFirstChild("Humanoid") do
        LocalPlayer.CharacterAdded:Wait()
    end
    local character = LocalPlayer.Character
    local HRP = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    if humanoid.Health <= 0 then
        humanoid.Died:Wait()
        return waitForCharacter()
    end
    return HRP
end

-- 🔍 Tìm vòng dungeon trong workspace
local function findDungeonCircle()
    local circle = workspace:FindFirstChild("DungeonCircle")
    if circle then
        print("📍 Đã tìm thấy vòng dungeon tại: " .. tostring(circle.Position))
        return circle.CFrame + Vector3.new(0, 3, 0)
    else
        warn("⚠️ Không tìm thấy vòng dungeon, dùng tọa độ mặc định")
        return dungeonCircleCFrame
    end
end

-- 🌀 Dịch chuyển mượt
local activeTween
local function teleportTo(cframe)
    local HRP = waitForCharacter()
    if activeTween then activeTween:Cancel() end
    local tweenTime = math.min((HRP.Position - cframe.Position).Magnitude / 300, 5)
    local tween = TweenService:Create(HRP, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = cframe})
    activeTween = tween
    tween:Play()
    local success, result = pcall(function() tween.Completed:Wait() end)
    activeTween = nil
    if not success or (HRP.Position - cframe.Position).Magnitude > 5 then
        warn("⚠️ Dịch chuyển thất bại!")
        return false
    end
    print("✅ Dịch chuyển thành công!")
    return true
end

-- ⚔️ Tấn công thường (click chuột)
local function spamClick()
    for i = 1, 5 do
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        task.wait(math.random(0.1, 0.2))
    end
    task.wait(math.random(1.5, 2.5))
end

-- 🌀 Dùng kỹ năng Z
local function pressZ()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
    task.wait(math.random(0.03, 0.07))
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
end

-- ⚔️ Đổi vũ khí
local function equipTool(slot)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    local tools = backpack:GetChildren()
    if tools[slot] then
        LocalPlayer.Character.Humanoid:EquipTool(tools[slot])
        task.wait(0.3)
    end
end

-- 👹 Lấy danh sách quái còn sống
local function getEnemies()
    local enemies = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if obj.Humanoid.Health > 0 then
                table.insert(enemies, obj)
            end
        end
    end
    return enemies
end

-- 🗡️ Tấn công quái
local function attackEnemy(enemy)
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local HRP = waitForCharacter()
    HRP.CFrame = root.CFrame + Vector3.new(0, 10, 0)

    equipTool(1) -- trái ác quỷ
    pressZ()
    task.wait(0.2)

    equipTool(2) -- kiếm
    pressZ()
    spamClick()
end

-- 🔁 Farm tất cả tầng
local function farmDungeon()
    print("➡️ Bắt đầu farm Dungeon...")
    local fruitTimer = tick()
    for floor = 1, 5 do
        print("⚔️ Tầng " .. floor)
        while true do
            local enemies = getEnemies()
            if #enemies == 0 then
                print("✅ Đã clear tầng " .. floor)
                break
            end
            for _, enemy in pairs(enemies) do
                attackEnemy(enemy)
                if tick() - fruitTimer >= 25 then
                    equipTool(1)
                    pressZ()
                    fruitTimer = tick()
                end
                task.wait(0.1)
            end
        end
        task.wait(3)
    end
    print("✅ Clear toàn bộ dungeon!")
end

-- 🌐 UI bật/tắt
local isRunning = false
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AutoFarmUI"

local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 120, 0, 40)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 136, 0)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 16
ToggleButton.Text = "AutoFarm: OFF"

ToggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    ToggleButton.Text = isRunning and "AutoFarm: ON" or "AutoFarm: OFF"
end)

-- 🚀 Chạy vòng lặp chính
local function start()
    spawn(function()
        while true do
            if isRunning then
                local waited = 0
                while not isInDungeon() and waited < 30 do
                    print("⏳ Chờ vào dungeon...")
                    task.wait(1)
                    waited += 1
                end

                if not isInDungeon() then
                    warn("❌ Không vào được dungeon sau 30s. Tele lại.")
                    teleportTo(findDungeonCircle())
                    task.wait(10)
                    continue
                end

                farmDungeon()
                task.wait(2)
                teleportTo(findDungeonCircle())
                task.wait(22)
            else
                task.wait(1)
            end
        end
    end)
end

start()

return {
    Start = function() end
}
