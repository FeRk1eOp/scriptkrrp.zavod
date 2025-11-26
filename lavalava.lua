-- Основной скрипт автоматизации завода
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Переменные для управления циклом
local autoEnabled = false
local currentCycle = 0
local noclipEnabled = false
local noclipConnection = nil

-- Сначала объявляем все функции, которые используются в других функциях

-- Функция для включения/выключения Noclip
local function toggleNoclip()
    local character = player.Character
    if not character then return end
    
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
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

-- Безопасная система телепортации с проверкой поверхности
local function safeAdvancedTeleport(targetCFrame)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    print("🛡️ Запускаем безопасную телепортацию...")
    
    -- Включаем noclip для безопасности
    local wasNoclipEnabled = noclipEnabled
    if not noclipEnabled then
        toggleNoclip()
    end
    
    -- Функция для поиска безопасной позиции на поверхности
    local function findSafePosition(targetPosition)
        -- Проверяем позицию с помощью raycast
        local rayOrigin = targetPosition + Vector3.new(0, 50, 0) -- Начинаем сверху
        local rayDirection = Vector3.new(0, -100, 0) -- Луч вниз
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {character}
        
        local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if rayResult then
            -- Нашли поверхность, возвращаем позицию над ней
            return rayResult.Position + Vector3.new(0, 5, 0)
        else
            -- Не нашли поверхность, используем оригинальную позицию с безопасной высотой
            return targetPosition + Vector3.new(0, 10, 0)
        end
    end
    
    -- Метод 1: Безопасное перемещение к целевой позиции
    local function safeMovementTeleport()
        print("🚶 Метод 1: Безопасное перемещение...")
        
        -- Находим безопасную целевую позицию
        local safeTargetPosition = findSafePosition(targetCFrame.Position)
        local safeTargetCFrame = CFrame.new(safeTargetPosition)
        
        local startPos = humanoidRootPart.Position
        local distance = (safeTargetPosition - startPos).Magnitude
        local steps = math.max(30, distance / 3)
        
        -- Плавное перемещение
        for i = 1, steps do
            if not autoEnabled then break end
            
            local progress = i / steps
            local currentPos = startPos:Lerp(safeTargetPosition, progress)
            
            -- Небольшое смещение для обхода античита
            local offset = Vector3.new(
                math.random(-0.3, 0.3),
                math.random(0, 0.5),
                math.random(-0.3, 0.3)
            )
            
            humanoidRootPart.CFrame = CFrame.new(currentPos + offset)
            wait(0.03)
        end
        
        -- Финальная позиция
        humanoidRootPart.CFrame = safeTargetCFrame
        return true
    end
    
    -- Метод 2: Телепорт через промежуточные точки с проверкой поверхности
    local function surfaceAwareTeleport()
        print("📍 Метод 2: Телепорт с проверкой поверхности...")
        
        local startPos = humanoidRootPart.Position
        local safeTargetPosition = findSafePosition(targetCFrame.Position)
        
        -- Создаем безопасные промежуточные точки
        local points = {}
        local numPoints = 3
        
        for i = 1, numPoints do
            local progress = i / (numPoints + 1)
            local basePoint = startPos:Lerp(safeTargetPosition, progress)
            
            -- Делаем каждую точку безопасной
            local safePoint = findSafePosition(basePoint)
            table.insert(points, safePoint)
        end
        
        table.insert(points, safeTargetPosition)
        
        -- Перемещаемся через точки
        for _, point in ipairs(points) do
            if not autoEnabled then break end
            
            humanoidRootPart.CFrame = CFrame.new(point)
            wait(0.2)
        end
        
        return true
    end
    
    -- Метод 3: Телепорт с временной платформой
    local function platformAssistedTeleport()
        print("🏗️ Метод 3: Телепорт с платформой...")
        
        local safeTargetPosition = findSafePosition(targetCFrame.Position)
        
        -- Создаем временную платформу в целевой позиции
        local platform = Instance.new("Part")
        platform.Name = "SafeTeleportPlatform"
        platform.Size = Vector3.new(6, 1, 6)
        platform.Anchored = true
        platform.CanCollide = true
        platform.Transparency = 0.7
        platform.Material = Enum.Material.Plastic
        platform.BrickColor = BrickColor.new("Bright green")
        platform.CFrame = CFrame.new(safeTargetPosition - Vector3.new(0, 2.5, 0))
        platform.Parent = workspace
        
        -- Телепортируемся на платформу
        humanoidRootPart.CFrame = CFrame.new(safeTargetPosition)
        
        -- Ждем стабилизации
        wait(1.5)
        
        -- Проверяем, стоит ли игрок на платформе
        local playerPos = humanoidRootPart.Position
        local platformPos = platform.Position
        local distance = (playerPos - platformPos).Magnitude
        
        if distance < 10 then
            print("✅ Игрок безопасно телепортирован")
        else
            print("⚠️ Игрок не на платформе, корректируем...")
            humanoidRootPart.CFrame = CFrame.new(safeTargetPosition)
        end
        
        -- Медленно удаляем платформу
        for i = 1, 10 do
            platform.Transparency = platform.Transparency + 0.03
            wait(0.1)
        end
        platform:Destroy()
        
        return true
    end
    
    -- Запускаем методы
    local methods = {
        safeMovementTeleport,
        surfaceAwareTeleport,
        platformAssistedTeleport
    }
    
    local success = false
    
    for attempt = 1, 2 do
        print("\n🔄 Попытка безопасной телепортации " .. attempt .. "/2")
        
        for methodIndex, method in ipairs(methods) do
            if not autoEnabled then break end
            
            print("🔄 Тестируем метод " .. methodIndex .. "...")
            local methodSuccess = pcall(method)
            
            if methodSuccess then
                -- Проверяем результат
                wait(1)
                local finalPosition = humanoidRootPart.Position
                
                -- Проверяем, не под картой ли игрок
                if finalPosition.Y < -100 then
                    print("❌ Игрок под картой, пробуем другой метод...")
                    -- Экстренная телепортация на безопасную высоту
                    humanoidRootPart.CFrame = CFrame.new(targetCFrame.Position.X, 50, targetCFrame.Position.Z)
                else
                    print("✅ Безопасная телепортация успешна методом " .. methodIndex)
                    success = true
                    break
                end
            end
            
            wait(0.5)
        end
        
        if success then
            break
        end
    end
    
    -- Восстанавливаем состояние noclip
    if not wasNoclipEnabled then
        toggleNoclip()
    end
    
    -- Финальная проверка безопасности
    if success then
        wait(1)
        local finalPos = humanoidRootPart.Position
        
        -- Если игрок все еще под картой, используем аварийный телепорт
        if finalPos.Y < -50 then
            print("🚨 АВАРИЙНЫЙ ТЕЛЕПОРТ! Игрок под картой...")
            local emergencyPos = Vector3.new(targetCFrame.Position.X, 100, targetCFrame.Position.Z)
            humanoidRootPart.CFrame = CFrame.new(emergencyPos)
            wait(1)
            
            -- Пытаемся найти поверхность
            local safePos = findSafePosition(targetCFrame.Position)
            humanoidRootPart.CFrame = CFrame.new(safePos)
        end
    end
    
    return success
end

-- Функция взятия ковша
local function equipKovsh()
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if not backpack or not character then 
        print("❌ Рюкзак или персонаж не найден")
        return false 
    end
    
    local kovsh = backpack:FindFirstChild("Сосуд")
    if not kovsh then
        print("❌ Ковш не найден в рюкзаке")
        return false
    end
    
    if character:FindFirstChild("Сосуд") then
        print("✅ Ковш уже в руке")
        return true
    end
    
    kovsh.Parent = character
    print("✅ Ковш взят в руку")
    return true
end

-- ЦИКЛ 1: MetalGiver (10 раз)
local function executeMetalCycle()
    local metalGiver = workspace.Jobs["Работник завода"].MetalGiver
    local clickDetector = metalGiver.ClickDetector
    local event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place
    local clickPart = workspace.Jobs["Работник завода"].Water_Clear_Conveyor.ClickPart
    
    print("🔧 Начинаем цикл MetalGiver...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        pcall(function()
            fireclickdetector(clickDetector)
            print("✅ Клик MetalGiver " .. i)
        end)
        wait(0.3)
        
        pcall(function()
            event:FireServer(clickPart)
            print("✅ Ивент place " .. i)
        end)
        wait(0.3)
    end
    
    print("✅ Цикл MetalGiver завершен")
end

-- ЦИКЛ 2: ClearGiver (10 раз)
local function executeClearCycle()
    local clearGiver = workspace.Jobs["Работник завода"].ClearGiver
    local clickDetector = clearGiver.ClickDetector
    local event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place
    local clickPart = workspace.Jobs["Работник завода"].Melting_Conveyor.ClickPart
    
    print("🔥 Начинаем цикл ClearGiver...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        pcall(function()
            fireclickdetector(clickDetector)
            print("✅ Клик ClearGiver " .. i)
        end)
        wait(0.3)
        
        pcall(function()
            event:FireServer(clickPart)
            print("✅ Ивент place Clear " .. i)
        end)
        wait(0.3)
    end
    
    print("✅ Цикл ClearGiver завершен")
end

-- ЦИКЛ 3: Лава и сбор металла
local function executeLavaCycle()
    if not equipKovsh() then
        print("❌ Не удалось взять ковш")
        return false
    end
    
    -- Телепортируемся к Shapes с безопасной позицией
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    local shapesPosition = shapesModel:GetModelCFrame()
    if not shapesPosition then
        shapesPosition = shapesModel:GetBoundingBox().CFrame
    end
    
    print("🔄 Безопасная телепортация к Shapes...")
    if not safeAdvancedTeleport(shapesPosition) then
        print("❌ Не удалось телепортироваться к Shapes")
        return false
    end
    wait(2)
    
    -- Ивенты для лавы
    local giveLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].give_lava
    local placeLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_lava
    local lavaGiver = workspace.Jobs["Работник завода"].Melting_Conveyor.Lava_Giver
    
    print("🌋 Начинаем заливку лавы...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        pcall(function()
            giveLavaEvent:FireServer(lavaGiver)
            print("✅ Взяли лаву " .. i)
        end)
        wait(0.5)
        
        pcall(function()
            local shape = shapesModel:FindFirstChild(tostring(i))
            if shape then
                placeLavaEvent:FireServer(shape)
                print("✅ Вылили лаву в форму " .. i)
            else
                print("❌ Форма " .. i .. " не найдена!")
            end
        end)
        wait(0.5)
    end
    
    print("✅ Заливка лавы завершена")
    
    -- Ждем 18 секунд
    print("⏳ Ждем 18 секунд...")
    for i = 1, 18 do
        if not autoEnabled then break end
        wait(1)
    end
    
    -- Собираем слитки
    print("💰 Собираем слитки...")
    for i = 1, 10 do
        if not autoEnabled then break end
        
        local shape = shapesModel:FindFirstChild(tostring(i))
        if shape then
            local clickDetector = shape:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
                print("✅ Собрали слиток " .. i)
            end
        end
    end
    
    print("✅ Слитки собраны")
    return true
end

-- ЦИКЛ 4: Загрузка в бокс
local function executeBoxCycle()
    -- Телепортируемся к боксу с безопасной позицией
    local box = workspace.Jobs["Работник завода"].Box_Conveyor.Box
    local boxPosition = box:GetModelCFrame()
    if not boxPosition then
        boxPosition = box:GetBoundingBox().CFrame
    end
    
    print("🔄 Безопасная телепортация к боксу...")
    if not safeAdvancedTeleport(boxPosition) then
        print("❌ Не удалось телепортироваться к боксу")
        return false
    end
    wait(2)
    
    -- Загружаем металл в бокс
    local Event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_metal
    local boxPart = workspace.Jobs["Работник завода"].Box_Conveyor.Box.body
    
    print("📦 Загружаем металл в бокс...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        pcall(function()
            Event:FireServer(boxPart)
            print("✅ Загрузили слиток " .. i)
        end)
        wait(0.3)
    end
    
    print("✅ Загрузка в бокс завершена")
    return true
end

-- Главная функция автоматического цикла
local function startAutoCycle()
    if autoEnabled then
        print("❌ Авто-цикл уже запущен!")
        return
    end
    
    autoEnabled = true
    currentCycle = 0
    
    print("🚀 ЗАПУСК АВТОМАТИЧЕСКОГО ЦИКЛА С БЕЗОПАСНОЙ ТЕЛЕПОРТАЦИЕЙ!")
    
    while autoEnabled do
        currentCycle = currentCycle + 1
        print("\n🎯 ЗАПУСК ЦИКЛА " .. currentCycle .. " ================")
        
        -- ЦИКЛ 1: MetalGiver
        if not autoEnabled then break end
        executeMetalCycle()
        
        if not autoEnabled then break end
        
        -- Телепорт к ClearGiver
        local clearGiver = workspace.Jobs["Работник завода"].ClearGiver
        local clearCFrame = clearGiver.CFrame
        
        print("🔄 Безопасная телепортация к ClearGiver...")
        safeAdvancedTeleport(clearCFrame)
        
        print("⏳ Ждем 10 секунд...")
        for i = 1, 10 do
            if not autoEnabled then break end
            wait(1)
        end
        
        -- ЦИКЛ 2: ClearGiver
        if not autoEnabled then break end
        executeClearCycle()
        
        -- Ожидание 15 секунд
        if not autoEnabled then break end
        print("⏳ Ждем 15 секунд...")
        for i = 1, 15 do
            if not autoEnabled then break end
            wait(1)
        end
        
        -- ЦИКЛ 3: Лава и сбор
        if not autoEnabled then break end
        local lavaSuccess = executeLavaCycle()
        
        if not lavaSuccess then
            print("❌ Ошибка в цикле лавы, продолжаем...")
        end
        
        -- ЦИКЛ 4: Загрузка в бокс
        if not autoEnabled then break end
        local boxSuccess = executeBoxCycle()
        
        if not boxSuccess then
            print("❌ Ошибка в цикле бокса, продолжаем...")
        end
        
        -- Ожидание 20 секунд перед следующим циклом
        if not autoEnabled then break end
        print("⏳ Ждем 20 секунд перед следующим циклом...")
        for i = 1, 20 do
            if not autoEnabled then break end
            wait(1)
        end
        
        -- Телепорт к MetalGiver для следующего цикла
        if not autoEnabled then break end
        local metalGiver = workspace.Jobs["Работник завода"].MetalGiver
        local metalCFrame = metalGiver.CFrame
        
        print("🔄 Безопасная телепортация к MetalGiver...")
        safeAdvancedTeleport(metalCFrame)
        wait(2)
        
        print("🎉 ЦИКЛ " .. currentCycle .. " ЗАВЕРШЕН! ================")
    end
    
    print("❌ АВТОМАТИЧЕСКИЙ ЦИКЛ ОСТАНОВЛЕН")
    
    -- Выключаем noclip при остановке
    if noclipEnabled then
        toggleNoclip()
    end
end

-- Функция остановки цикла
local function stopAutoCycle()
    if autoEnabled then
        autoEnabled = false
        print("🛑 Останавливаем автоматический цикл...")
    else
        print("ℹ️ Авто-цикл не запущен!")
    end
end

-- Создаем GUI для управления
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFactoryGUI"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
titleLabel.Text = "🏭 АВТОМАТИЧЕСКИЙ ЗАВОД"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Информация о цикле
local cycleLabel = Instance.new("TextLabel")
cycleLabel.Size = UDim2.new(1, 0, 0, 20)
cycleLabel.Position = UDim2.new(0, 0, 0.15, 0)
cycleLabel.BackgroundTransparency = 1
cycleLabel.Text = "Цикл: 0"
cycleLabel.TextColor3 = Color3.new(1, 1, 1)
cycleLabel.TextSize = 14
cycleLabel.Font = Enum.Font.Gotham
cycleLabel.Parent = mainFrame

-- Кнопка запуска
local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.9, 0, 0, 40)
startButton.Position = UDim2.new(0.05, 0, 0.3, 0)
startButton.BackgroundColor3 = Color3.new(0, 0.6, 0)
startButton.Text = "🚀 ЗАПУСТИТЬ АВТО-ЦИКЛ"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Parent = mainFrame

-- Кнопка остановки
local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0.9, 0, 0, 40)
stopButton.Position = UDim2.new(0.05, 0, 0.6, 0)
stopButton.BackgroundColor3 = Color3.new(0.8, 0, 0)
stopButton.Text = "🛑 ОСТАНОВИТЬ ЦИКЛ"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = mainFrame

-- Кнопка Noclip
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.4, 0, 0, 25)
noclipButton.Position = UDim2.new(0.05, 0, 0.85, 0)
noclipButton.BackgroundColor3 = Color3.new(0.5, 0, 0.5)
noclipButton.Text = "👻 Noclip: ВЫКЛ"
noclipButton.TextColor3 = Color3.new(1, 1, 1)
noclipButton.TextSize = 12
noclipButton.Font = Enum.Font.Gotham
noclipButton.Parent = mainFrame

-- Кнопка взятия ковша
local kovshButton = Instance.new("TextButton")
kovshButton.Size = UDim2.new(0.4, 0, 0, 25)
kovshButton.Position = UDim2.new(0.55, 0, 0.85, 0)
kovshButton.BackgroundColor3 = Color3.new(0.2, 0.5, 0.2)
kovshButton.Text = "🥄 Взять ковш"
kovshButton.TextColor3 = Color3.new(1, 1, 1)
kovshButton.TextSize = 12
kovshButton.Font = Enum.Font.Gotham
kovshButton.Parent = mainFrame

-- Подключаем функции к кнопкам
startButton.MouseButton1Click:Connect(function()
    spawn(startAutoCycle)
end)

stopButton.MouseButton1Click:Connect(function()
    stopAutoCycle()
end)

noclipButton.MouseButton1Click:Connect(function()
    toggleNoclip()
    noclipButton.Text = noclipEnabled and "👻 Noclip: ВКЛ" or "👻 Noclip: ВЫКЛ"
    noclipButton.BackgroundColor3 = noclipEnabled and Color3.new(0, 0.8, 0) or Color3.new(0.5, 0, 0.5)
end)

kovshButton.MouseButton1Click:Connect(function()
    equipKovsh()
end)

-- Обновление информации о цикле
game:GetService("RunService").Heartbeat:Connect(function()
    if autoEnabled then
        cycleLabel.Text = "Цикл: " .. currentCycle .. " (работает...)"
        cycleLabel.TextColor3 = Color3.new(0, 1, 0)
        startButton.BackgroundColor3 = Color3.new(0, 0.3, 0)
    else
        cycleLabel.Text = "Цикл: " .. currentCycle .. " (остановлен)"
        cycleLabel.TextColor3 = Color3.new(1, 0, 0)
        startButton.BackgroundColor3 = Color3.new(0, 0.6, 0)
    end
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

print("✅ АВТОМАТИЧЕСКИЙ ЗАВОД С БЕЗОПАСНОЙ ТЕЛЕПОРТАЦИЕЙ ЗАГРУЖЕН!")
print("🛡️  Система защиты от падения под карту активирована")
print("📝 Инструкция:")
print("   🚀 Нажми 'ЗАПУСТИТЬ АВТО-ЦИКЛ' для начала")
print("   🛑 Нажми 'ОСТАНОВИТЬ ЦИКЛ' для остановки")
