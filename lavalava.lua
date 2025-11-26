-- Умный телепорт с обходом античита и Noclip
local noclipEnabled = false
local noclipConnection = nil

-- Функция для включения/выключения Noclip
local function toggleNoclip()
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character then return end
    
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        -- Включаем Noclip
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        
        noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            if character and noclipEnabled then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        print("✅ Noclip включен")
    else
        -- Выключаем Noclip
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        print("❌ Noclip выключен")
    end
end

-- Функция умного телепорта
local function smartTeleport(targetCFrame)
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    -- Временно включаем Noclip для телепорта
    local wasNoclipEnabled = noclipEnabled
    if not noclipEnabled then
        toggleNoclip()
    end
    
    -- Метод 1: Постепенный телепорт малыми шагами
    local function gradualTeleport()
        local steps = 30
        local currentPos = humanoidRootPart.Position
        local targetPos = targetCFrame.Position
        local step = (targetPos - currentPos) / steps
        
        for i = 1, steps do
            humanoidRootPart.CFrame = CFrame.new(currentPos + step * i)
            wait(0.01)
        end
        return true
    end
    
    -- Метод 2: Через VehicleSeat
    local function vehicleSeatTeleport()
        local seat = Instance.new("VehicleSeat")
        seat.CFrame = targetCFrame
        seat.Parent = workspace
        
        humanoidRootPart.CFrame = targetCFrame
        wait(0.1)
        seat:Destroy()
        return true
    end
    
    -- Метод 3: Через Platform
    local function platformTeleport()
        local platform = Instance.new("Part")
        platform.Anchored = true
        platform.CanCollide = false
        platform.Size = Vector3.new(5, 1, 5)
        platform.CFrame = targetCFrame
        platform.Transparency = 1
        platform.Parent = workspace
        
        humanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        wait(0.1)
        platform:Destroy()
        return true
    end
    
    -- Пробуем методы по порядку
    local methods = {gradualTeleport, vehicleSeatTeleport, platformTeleport}
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            print("✅ Телепорт успешен методом " .. i)
            -- Восстанавливаем исходное состояние Noclip
            if not wasNoclipEnabled then
                toggleNoclip()
            end
            return true
        else
            print("❌ Метод " .. i .. " не сработал")
        end
        wait(0.5)
    end
    
    -- Восстанавливаем исходное состояние Noclip
    if not wasNoclipEnabled then
        toggleNoclip()
    end
    
    return false
end

-- Функция для автоматического взятия лавы и заливки в формы
local function autoLavaProcess()
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    -- Проверяем персонажа
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("❌ Персонаж не найден")
        return
    end
    
    -- Сохраняем исходную позицию
    local originalPosition = character.HumanoidRootPart.Position
    
    -- Телепортируемся к лаве
    local lavaGiver = workspace.Jobs["Работник завода"].Melting_Conveyor.Lava_Giver
    local targetCFrame = lavaGiver.CFrame + Vector3.new(0, 3, 0)
    
    print("🔄 Телепортируемся к лаве...")
    local teleportSuccess = smartTeleport(targetCFrame)
    
    if not teleportSuccess then
        print("❌ Не удалось телепортироваться к лаве")
        return
    end
    
    wait(2) -- Ждем стабилизации
    
    -- Ивенты для работы с лавой
    local giveLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].give_lava
    local placeLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_lava
    
    print("🔥 Начинаем процесс заполнения 10 форм...")
    
    -- Выполняем 10 циклов
    for i = 1, 10 do
        print("🔄 Цикл " .. i .. "/10")
        
        -- Шаг 1: Берем лаву
        local success1, error1 = pcall(function()
            giveLavaEvent:FireServer(lavaGiver)
            print("✅ Лава взята")
        end)
        
        if not success1 then
            print("❌ Ошибка взятия лавы: " .. tostring(error1))
        end
        
        wait(1) -- Ждем пока лава наберется
        
        -- Шаг 2: Выливаем лаву в форму
        local success2, error2 = pcall(function()
            local shape = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes[tostring(i)]
            
            if shape then
                placeLavaEvent:FireServer(shape)
                print("✅ Лава вылита в форму " .. i)
            else
                print("❌ Форма " .. i .. " не найдена!")
            end
        end)
        
        if not success2 then
            print("❌ Ошибка выливания лавы: " .. tostring(error2))
        end
        
        wait(1) -- Ждем перед следующим циклом
    end
    
    print("🎉 Все 10 форм заполнены лавой!")
    
    -- Возвращаемся на исходную позицию
    print("🔄 Возвращаемся на исходную позицию...")
    smartTeleport(CFrame.new(originalPosition))
    print("✅ Процесс завершен!")
end

-- Создаем GUI
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoLavaGUI"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 190)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
titleLabel.Text = "🌋 Авто-Лава Процесс"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Кнопка автоматического процесса
local autoProcessButton = Instance.new("TextButton")
autoProcessButton.Size = UDim2.new(0.9, 0, 0, 40)
autoProcessButton.Position = UDim2.new(0.05, 0, 0.2, 0)
autoProcessButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.1)
autoProcessButton.Text = "🔥 АВТОМАТИЧЕСКИЙ ПРОЦЕСС"
autoProcessButton.TextColor3 = Color3.new(1, 1, 1)
autoProcessButton.TextSize = 12
autoProcessButton.Font = Enum.Font.GothamBold
autoProcessButton.Parent = mainFrame

-- Кнопка Noclip
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9, 0, 0, 30)
noclipButton.Position = UDim2.new(0.05, 0, 0.5, 0)
noclipButton.BackgroundColor3 = Color3.new(0.5, 0, 0.5)
noclipButton.Text = "👻 Noclip: ВЫКЛ"
noclipButton.TextColor3 = Color3.new(1, 1, 1)
noclipButton.TextSize = 12
noclipButton.Font = Enum.Font.Gotham
noclipButton.Parent = mainFrame

-- Кнопка телепорта к лаве
local teleportButton = Instance.new("TextButton")
teleportButton.Size = UDim2.new(0.9, 0, 0, 30)
teleportButton.Position = UDim2.new(0.05, 0, 0.7, 0)
teleportButton.BackgroundColor3 = Color3.new(0, 0.5, 1)
teleportButton.Text = "📌 Телепорт к лаве"
teleportButton.TextColor3 = Color3.new(1, 1, 1)
teleportButton.TextSize = 12
teleportButton.Font = Enum.Font.Gotham
teleportButton.Parent = mainFrame

-- Кнопка закрытия GUI
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.9, 0, 0, 30)
closeButton.Position = UDim2.new(0.05, 0, 0.9, 0)
closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
closeButton.Text = "❌ Закрыть"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 12
closeButton.Font = Enum.Font.Gotham
closeButton.Parent = mainFrame

-- Подключаем функции к кнопкам
autoProcessButton.MouseButton1Click:Connect(function()
    print("🚀 Запускаем автоматический процесс...")
    autoLavaProcess()
end)

teleportButton.MouseButton1Click:Connect(function()
    local lavaGiver = workspace.Jobs["Работник завода"].Melting_Conveyor.Lava_Giver
    local targetCFrame = lavaGiver.CFrame + Vector3.new(0, 3, 0)
    smartTeleport(targetCFrame)
end)

noclipButton.MouseButton1Click:Connect(function()
    toggleNoclip()
    noclipButton.Text = noclipEnabled and "👻 Noclip: ВКЛ" or "👻 Noclip: ВЫКЛ"
    noclipButton.BackgroundColor3 = noclipEnabled and Color3.new(0, 0.8, 0) or Color3.new(0.5, 0, 0.5)
end)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("✅ GUI закрыт")
end)

-- Делаем GUI перемещаемым
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function updateInput(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

print("✅ Авто-Лава процесс создан!")
print("🔥 Нажми кнопку 'АВТОМАТИЧЕСКИЙ ПРОЦЕСС' для запуска")
