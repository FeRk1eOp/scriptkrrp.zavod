-- Основной скрипт автоматизации завода
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Переменные для управления циклом
local autoEnabled = false
local currentCycle = 0
local noclipEnabled = false
local noclipConnection = nil

-- Улучшенная система телепортации с обходом античита
local function advancedTeleport(targetCFrame)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    print("🎯 Запускаем усовершенствованную телепортацию...")
    
    -- Метод 1: Медленное движение с имитацией ходьбы
    local function slowMovementTeleport()
        print("🚶 Метод 1: Медленное движение...")
        local startPos = humanoidRootPart.Position
        local endPos = targetCFrame.Position
        local distance = (endPos - startPos).Magnitude
        local steps = math.max(50, distance / 2) -- Больше шагов для больших расстояний
        
        for i = 1, steps do
            if not autoEnabled then break end
            
            local progress = i / steps
            local currentPos = startPos:Lerp(endPos, progress)
            
            -- Добавляем небольшую случайность для имитации естественного движения
            local randomOffset = Vector3.new(
                math.random(-0.5, 0.5),
                math.random(-0.1, 0.1),
                math.random(-0.5, 0.5)
            )
            
            humanoidRootPart.CFrame = CFrame.new(currentPos + randomOffset)
            wait(0.03) -- Очень маленькая задержка
        end
        
        humanoidRootPart.CFrame = targetCFrame
        return true
    end
    
    -- Метод 2: Телепорт через несколько промежуточных точек
    local function multiPointTeleport()
        print("📍 Метод 2: Многоточечная телепортация...")
        local startPos = humanoidRootPart.Position
        local endPos = targetCFrame.Position
        
        -- Создаем 3-4 случайные промежуточные точки
        local points = {}
        local numPoints = 4
        
        for i = 1, numPoints do
            local progress = i / (numPoints + 1)
            local basePoint = startPos:Lerp(endPos, progress)
            
            -- Добавляем случайное смещение
            local randomOffset = Vector3.new(
                math.random(-10, 10),
                math.random(5, 15),
                math.random(-10, 10)
            )
            
            table.insert(points, basePoint + randomOffset)
        end
        
        table.insert(points, endPos) -- Конечная точка
        
        -- Последовательно телепортируемся через все точки
        for _, point in ipairs(points) do
            if not autoEnabled then break end
            
            humanoidRootPart.CFrame = CFrame.new(point)
            wait(0.1) -- Короткая пауза между точками
        end
        
        return true
    end
    
    -- Метод 3: Физическое перемещение через BodyMover
    local function physicsTeleport()
        print("⚡ Метод 3: Физическое перемещение...")
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = (targetCFrame.Position - humanoidRootPart.Position).Unit * 50
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Parent = humanoidRootPart
        
        -- Ждем достижения цели или таймаута
        local startTime = tick()
        while (humanoidRootPart.Position - targetCFrame.Position).Magnitude > 5 do
            if not autoEnabled or (tick() - startTime) > 10 then
                break
            end
            wait(0.1)
        end
        
        bodyVelocity:Destroy()
        return true
    end
    
    -- Метод 4: Телепорт через временный портал (объект)
    local function portalTeleport()
        print("🌀 Метод 4: Портал...")
        
        -- Создаем "портал" в текущей позиции
        local startPortal = Instance.new("Part")
        startPortal.Name = "TeleportPortal"
        startPortal.Size = Vector3.new(5, 8, 1)
        startPortal.Anchored = true
        startPortal.CanCollide = false
        startPortal.Transparency = 0.7
        startPortal.Material = Enum.Material.Neon
        startPortal.BrickColor = BrickColor.new("Bright blue")
        startPortal.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        startPortal.Parent = workspace
        
        -- Создаем "портал" в целевой позиции
        local endPortal = Instance.new("Part")
        endPortal.Name = "TeleportPortal"
        endPortal.Size = Vector3.new(5, 8, 1)
        endPortal.Anchored = true
        endPortal.CanCollide = false
        endPortal.Transparency = 0.7
        endPortal.Material = Enum.Material.Neon
        endPortal.BrickColor = BrickColor.new("Bright blue")
        endPortal.CFrame = targetCFrame * CFrame.new(0, 0, -3)
        endPortal.Parent = workspace
        
        -- Анимация "входа" в портал
        for i = 1, 10 do
            humanoidRootPart.CFrame = startPortal.CFrame * CFrame.new(0, 0, -0.5 * i)
            wait(0.05)
        end
        
        -- Мгновенная телепортация
        humanoidRootPart.CFrame = endPortal.CFrame * CFrame.new(0, 0, 3)
        
        -- Анимация "выхода" из портала
        for i = 1, 5 do
            humanoidRootPart.CFrame = endPortal.CFrame * CFrame.new(0, 0, 0.5 * i)
            wait(0.05)
        end
        
        -- Удаляем порталы
        wait(0.5)
        startPortal:Destroy()
        endPortal:Destroy()
        
        return true
    end
    
    -- Метод 5: Использование VehicleSeat с улучшениями
    local function vehicleSeatTeleport()
        print("💺 Метод 5: Улучшенный VehicleSeat...")
        
        -- Создаем сиденье в целевой позиции
        local seat = Instance.new("VehicleSeat")
        seat.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        seat.Anchored = true
        seat.CanCollide = false
        seat.Transparency = 1
        seat.Parent = workspace
        
        -- Сажаем игрока на сиденье
        humanoidRootPart.CFrame = seat.CFrame
        
        -- Ждем пока игрок сядет
        wait(1)
        
        -- Медленно перемещаем сиденье к финальной позиции
        local steps = 20
        local startPos = seat.Position
        local endPos = targetCFrame.Position
        
        for i = 1, steps do
            local progress = i / steps
            local currentPos = startPos:Lerp(endPos, progress)
            seat.CFrame = CFrame.new(currentPos)
            wait(0.05)
        end
        
        -- Поднимаем игрока
        seat:Destroy()
        humanoidRootPart.CFrame = targetCFrame
        
        return true
    end
    
    -- Метод 6: Имитация падения с неба
    local function fallingTeleport()
        print("🌠 Метод 6: Падение с неба...")
        
        -- Телепортируем высоко над целью
        local highPosition = targetCFrame.Position + Vector3.new(0, 50, 0)
        humanoidRootPart.CFrame = CFrame.new(highPosition)
        wait(0.5)
        
        -- Медленно опускаемся
        local steps = 25
        for i = 1, steps do
            local height = 50 - (i * 2)
            humanoidRootPart.CFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, height, 0))
            wait(0.1)
        end
        
        humanoidRootPart.CFrame = targetCFrame
        return true
    end
    
    -- Запускаем все методы по порядку
    local methods = {
        slowMovementTeleport,
        multiPointTeleport, 
        physicsTeleport,
        portalTeleport,
        vehicleSeatTeleport,
        fallingTeleport
    }
    
    -- Перемешиваем методы для большей эффективности
    for i = #methods, 2, -1 do
        local j = math.random(1, i)
        methods[i], methods[j] = methods[j], methods[i]
    end
    
    local success = false
    
    for attempt = 1, 2 do  -- 2 попытки
        print("\n🔄 Попытка телепортации " .. attempt .. "/2")
        
        for methodIndex, method in ipairs(methods) do
            if not autoEnabled then break end
            
            print("🔄 Тестируем метод " .. methodIndex .. "...")
            local methodSuccess = pcall(method)
            
            if methodSuccess then
                -- Проверяем результат
                wait(1)  -- Ждем возможного отката античита
                local finalDistance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
                
                if finalDistance <= 10 then
                    print("✅ Телепортация успешна методом " .. methodIndex)
                    success = true
                    break
                else
                    print("⚠️ Метод " .. methodIndex .. " не достиг цели, расстояние: " .. math.floor(finalDistance))
                end
            else
                print("❌ Метод " .. methodIndex .. " вызвал ошибку")
            end
            
            wait(0.5)
        end
        
        if success then
            break
        end
        
        print("🔄 Пробуем другую комбинацию методов...")
        wait(2)
    end
    
    -- Финальная проверка и корректировка
    if success then
        wait(2)  -- Ждем возможного отката
        local finalDistance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
        
        if finalDistance > 5 then
            print("🔄 Финальная корректировка позиции...")
            humanoidRootPart.CFrame = targetCFrame
        end
    end
    
    return success
end

-- Остальной код остается таким же, но используем advancedTeleport вместо safeTeleport

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
    
    -- Телепортируемся к Shapes
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    local shapesPosition = shapesModel:GetModelCFrame()
    if not shapesPosition then
        shapesPosition = shapesModel:GetBoundingBox().CFrame
    end
    local shapesCFrame = shapesPosition + Vector3.new(0, 5, 0)
    
    print("🔄 Усовершенствованная телепортация к Shapes...")
    if not advancedTeleport(shapesCFrame) then
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
    -- Телепортируемся к боксу
    local box = workspace.Jobs["Работник завода"].Box_Conveyor.Box
    local boxPosition = box:GetModelCFrame()
    if not boxPosition then
        boxPosition = box:GetBoundingBox().CFrame
    end
    local boxCFrame = boxPosition + Vector3.new(0, 5, 0)
    
    print("🔄 Усовершенствованная телепортация к боксу...")
    if not advancedTeleport(boxCFrame) then
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
    
    -- Включаем noclip для всего цикла
    if not noclipEnabled then
        toggleNoclip()
    end
    
    print("🚀 ЗАПУСК АВТОМАТИЧЕСКОГО ЦИКЛА С УСОВЕРШЕНСТВОВАННОЙ ТЕЛЕПОРТАЦИЕЙ!")
    
    while autoEnabled do
        currentCycle = currentCycle + 1
        print("\n🎯 ЗАПУСК ЦИКЛА " .. currentCycle .. " ================")
        
        -- ЦИКЛ 1: MetalGiver
        if not autoEnabled then break end
        executeMetalCycle()
        
        if not autoEnabled then break end
        
        -- Телепорт к ClearGiver
        local clearGiver = workspace.Jobs["Работник завода"].ClearGiver
        local clearCFrame = clearGiver.CFrame + Vector3.new(0, 5, 0)
        
        print("🔄 Усовершенствованная телепортация к ClearGiver...")
        advancedTeleport(clearCFrame)
        
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
        local metalCFrame = metalGiver.CFrame + Vector3.new(0, 5, 0)
        
        print("🔄 Усовершенствованная телепортация к MetalGiver...")
        advancedTeleport(metalCFrame)
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

-- Создаем GUI для управления (остается без изменений)
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

print("✅ АВТОМАТИЧЕСКИЙ ЗАВОД С УСОВЕРШЕНСТВОВАННОЙ ТЕЛЕПОРТАЦИЕЙ ЗАГРУЖЕН!")
print("🎯 6 методов обхода анти-телепорта активированы")
print("📝 Инструкция:")
print("   🚀 Нажми 'ЗАПУСТИТЬ АВТО-ЦИКЛ' для начала")
print("   🛑 Нажми 'ОСТАНОВИТЬ ЦИКЛ' для остановки")
print("   👻 Noclip будет автоматически включен для лучшего обхода")
