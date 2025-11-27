-- Основной скрипт автоматизации завода
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Переменные для управления циклом
local autoEnabled = false
local currentCycle = 0
local noclipEnabled = false
local noclipConnection = nil

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

-- СУПЕР-БЕЗОПАСНАЯ ТЕЛЕПОРТАЦИЯ К SHAPES
local function superSafeShapesTeleport()
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then return false end
    
    print("🛡️ ЗАПУСКАЕМ СУПЕР-БЕЗОПАСНУЮ ТЕЛЕПОРТАЦИЮ К SHAPES...")
    
    -- Сохраняем исходное состояние
    local wasNoclipEnabled = noclipEnabled
    
    -- Включаем максимальную защиту
    if not noclipEnabled then
        toggleNoclip()
    end
    
    -- Временно увеличиваем здоровье
    humanoid.MaxHealth = 100000
    humanoid.Health = 100000
    
    -- Находим безопасную позицию у Shapes
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    local shapesPosition = shapesModel:GetModelCFrame()
    if not shapesPosition then
        shapesPosition = shapesModel:GetBoundingBox().CFrame
    end
    
    -- Безопасная позиция СБОКУ от Shapes, а не сверху
    local safeShapesPosition = shapesPosition + Vector3.new(8, 3, 0) -- Сбоку и немного выше
    
    print("📍 Безопасная позиция определена: сбоку от Shapes")
    
    -- Метод 1: ОЧЕНЬ медленное движение с проверкой здоровья
    local function ultraSlowMovement()
        print("🐌 Метод 1: Ультра-медленное движение...")
        
        local startPos = humanoidRootPart.Position
        local endPos = safeShapesPosition.Position
        local distance = (endPos - startPos).Magnitude
        
        -- Очень много мелких шагов
        local steps = math.max(200, distance * 3)
        
        for i = 1, steps do
            if not autoEnabled or humanoid.Health <= 0 then
                print("💀 Прерывание: игрок умер или цикл остановлен")
                return false
            end
            
            local progress = i / steps
            local currentPos = startPos:Lerp(endPos, progress)
            
            -- Двигаемся очень плавно
            humanoidRootPart.CFrame = CFrame.new(currentPos)
            wait(0.01) -- Минимальная задержка
            
            -- Проверяем здоровье каждые 10 шагов
            if i % 10 == 0 and humanoid.Health < 100000 then
                print("🩹 Восстанавливаем здоровье...")
                humanoid.Health = 100000
            end
        end
        
        return true
    end
    
    -- Метод 2: Движение через промежуточные точки
    local function safePathMovement()
        print("🛣️ Метод 2: Движение по безопасному пути...")
        
        local startPos = humanoidRootPart.Position
        local endPos = safeShapesPosition.Position
        
        -- Создаем безопасные промежуточные точки ВЫШЕ основного пути
        local points = {}
        
        -- Точка 1: Высоко над стартовой позицией
        table.insert(points, startPos + Vector3.new(0, 20, 0))
        
        -- Точка 2: Высоко над целевой позицией
        table.insert(points, endPos + Vector3.new(0, 20, 0))
        
        -- Точка 3: Безопасная позиция у Shapes
        table.insert(points, endPos)
        
        -- Двигаемся через точки
        for pointIndex, point in ipairs(points) do
            if not autoEnabled or humanoid.Health <= 0 then break end
            
            print("📍 Двигаемся к точке " .. pointIndex .. "...")
            
            local startPointPos = humanoidRootPart.Position
            local distance = (point - startPointPos).Magnitude
            local steps = math.max(50, distance * 2)
            
            for i = 1, steps do
                if not autoEnabled or humanoid.Health <= 0 then break end
                
                local progress = i / steps
                local currentPos = startPointPos:Lerp(point, progress)
                
                humanoidRootPart.CFrame = CFrame.new(currentPos)
                wait(0.02)
            end
            
            wait(0.5) // Пауза между точками
        end
        
        return true
    end
    
    // Запускаем методы
    local success = false
    
    // Сначала пробуем безопасный путь через верх
    print("🔄 Попытка 1/2: Безопасный путь через верх...")
    local method1Success = pcall(safePathMovement)
    
    if method1Success then
        wait(1)
        if humanoid.Health > 0 then
            local finalDistance = (humanoidRootPart.Position - safeShapesPosition.Position).Magnitude
            if finalDistance <= 10 then
                print("✅ Безопасный путь успешен!")
                success = true
            end
        end
    end
    
    // Если не сработало, пробуем ультра-медленное движение
    if not success then
        print("🔄 Попытка 2/2: Ультра-медленное движение...")
        local method2Success = pcall(ultraSlowMovement)
        
        if method2Success then
            wait(1)
            if humanoid.Health > 0 then
                local finalDistance = (humanoidRootPart.Position - safeShapesPosition.Position).Magnitude
                if finalDistance <= 10 then
                    print("✅ Ультра-медленное движение успешно!")
                    success = true
                end
            end
        end
    end
    
    // Восстанавливаем здоровье
    if humanoid then
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
    
    // Восстанавливаем noclip
    if not wasNoclipEnabled then
        toggleNoclip()
    end
    
    // Даем время на стабилизацию
    if success then
        print("⏳ Стабилизируем позицию...")
        wait(3)
    end
    
    return success
end

// Обычная безопасная телепортация для других мест
local function safeTeleport(targetCFrame)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then return false end
    
    print("🛡️ Безопасная телепортация...")
    
    // Сохраняем исходное состояние
    local wasNoclipEnabled = noclipEnabled
    
    // Включаем защиту
    if not noclipEnabled then
        toggleNoclip()
    end
    
    // Медленная телепортация
    local startPos = humanoidRootPart.Position
    local targetPos = targetCFrame.Position
    local steps = 80
    
    for i = 1, steps do
        if not autoEnabled or humanoid.Health <= 0 then break end
        
        local progress = i / steps
        local currentPos = startPos:Lerp(targetPos, progress)
        
        humanoidRootPart.CFrame = CFrame.new(currentPos)
        wait(0.03)
    end
    
    // Финальная позиция
    humanoidRootPart.CFrame = targetCFrame
    
    // Восстанавливаем noclip
    if not wasNoclipEnabled then
        toggleNoclip()
    end
    
    return true
end

// Функция взятия ковша
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

// ЦИКЛ 1: MetalGiver (10 раз)
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
        wait(0.5)
        
        pcall(function()
            event:FireServer(clickPart)
            print("✅ Ивент place " .. i)
        end)
        wait(0.5)
    end
    
    print("✅ Цикл MetalGiver завершен")
end

// ЦИКЛ 2: ClearGiver (10 раз)
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
        wait(0.5)
        
        pcall(function()
            event:FireServer(clickPart)
            print("✅ Ивент place Clear " .. i)
        end)
        wait(0.5)
    end
    
    print("✅ Цикл ClearGiver завершен")
end

// ЦИКЛ 3: Лава и сбор металла (С СУПЕР-БЕЗОПАСНОЙ ТЕЛЕПОРТАЦИЕЙ)
local function executeLavaCycle()
    if not equipKovsh() then
        print("❌ Не удалось взять ковш")
        return false
    end
    
    print("🌀 СУПЕР-БЕЗОПАСНАЯ телепортация к Shapes...")
    if not superSafeShapesTeleport() then
        print("❌ Не удалось безопасно телепортироваться к Shapes")
        return false
    end
    
    // Даем БОЛЬШЕ времени на стабилизацию
    print("⏳ Стабилизация после телепортации...")
    wait(5)
    
    // Проверяем, жив ли игрок
    local character = player.Character
    if not character or not character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("Humanoid").Health <= 0 then
        print("💀 Игрок умер при телепортации к Shapes")
        return false
    end
    
    // Ивенты для лавы
    local giveLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].give_lava
    local placeLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_lava
    local lavaGiver = workspace.Jobs["Работник завода"].Melting_Conveyor.Lava_Giver
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    
    print("🌋 Начинаем заливку лавы...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        // Проверяем здоровье перед каждым действием
        if character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("💀 Игрок умер во время заливки лавы")
            return false
        end
        
        pcall(function()
            giveLavaEvent:FireServer(lavaGiver)
            print("✅ Взяли лаву " .. i)
        end)
        wait(0.7)
        
        pcall(function()
            local shape = shapesModel:FindFirstChild(tostring(i))
            if shape then
                placeLavaEvent:FireServer(shape)
                print("✅ Вылили лаву в форму " .. i)
            else
                print("❌ Форма " .. i .. " не найдена!")
            end
        end)
        wait(0.7)
    end
    
    print("✅ Заливка лавы завершена")
    
    // ВКЛЮЧАЕМ NOCLIP НА ВРЕМЯ ОЖИДАНИЯ 18 СЕКУНД
    local wasNoclipBeforeWait = noclipEnabled
    if not noclipEnabled then
        toggleNoclip()
        print("👻 Noclip включен на время ожидания")
    end
    
    // Ждем 18 секунд с проверкой здоровья
    print("⏳ Ждем 18 секунд с включенным noclip...")
    for i = 1, 18 do
        if not autoEnabled then break end
        
        // Проверяем, не умер ли игрок
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("💀 Игрок умер во время ожидания")
            // Выключаем noclip перед выходом
            if not wasNoclipBeforeWait then
                toggleNoclip()
            end
            return false
        end
        wait(1)
    end
    
    // ВЫКЛЮЧАЕМ NOCLIP ПОСЛЕ ОЖИДАНИЯ (если он был выключен до этого)
    if not wasNoclipBeforeWait then
        toggleNoclip()
        print("👻 Noclip выключен после ожидания")
    end
    
    // Собираем слитки
    print("💰 Собираем слитки...")
    for i = 1, 10 do
        if not autoEnabled then break end
        
        // Проверка здоровья
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("💀 Игрок умер во время сбора")
            return false
        end
        
        local shape = shapesModel:FindFirstChild(tostring(i))
        if shape then
            local clickDetector = shape:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
                print("✅ Собрали слиток " .. i)
            end
        end
        wait(0.2)
    end
    
    print("✅ Слитки собраны")
    return true
end

// ЦИКЛ 4: Загрузка в бокс
local function executeBoxCycle()
    // Телепортируемся к боксу
    local box = workspace.Jobs["Работник завода"].Box_Conveyor.Box
    local boxPosition = box:GetModelCFrame()
    if not boxPosition then
        boxPosition = box:GetBoundingBox().CFrame
    end
    
    // Добавляем безопасную высоту
    boxPosition = boxPosition + Vector3.new(0, 5, 0)
    
    print("🔄 Безопасная телепортация к боксу...")
    if not safeTeleport(boxPosition) then
        print("❌ Не удалось телепортироваться к боксу")
        return false
    end
    
    // Даем время на стабилизацию
    wait(3)
    
    // Проверяем, жив ли игрок
    local character = player.Character
    if not character or not character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("Humanoid").Health <= 0 then
        print("💀 Игрок умер при телепортации к боксу")
        return false
    end
    
    // Загружаем металл в бокс
    local Event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_metal
    local boxPart = workspace.Jobs["Работник завода"].Box_Conveyor.Box.body
    
    print("📦 Загружаем металл в бокс...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        // Проверка здоровья
        if character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("💀 Игрок умер во время загрузки")
            return false
        end
        
        pcall(function()
            Event:FireServer(boxPart)
            print("✅ Загрузили слиток " .. i)
        end)
        wait(0.5)
    end
    
    print("✅ Загрузка в бокс завершена")
    return true
end

// Главная функция автоматического цикла
local function startAutoCycle()
    if autoEnabled then
        print("❌ Авто-цикл уже запущен!")
        return
    end
    
    autoEnabled = true
    currentCycle = 0
    
    print("🚀 ЗАПУСК АВТОМАТИЧЕСКОГО ЦИКЛА С СУПЕР-БЕЗОПАСНОЙ ТЕЛЕПОРТАЦИЕЙ!")
    
    while autoEnabled do
        currentCycle = currentCycle + 1
        print("\n🎯 ЗАПУСК ЦИКЛА " .. currentCycle .. " ================")
        
        // Проверяем, жив ли игрок перед началом цикла
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("💀 Игрок мертв, ждем респавна...")
            wait(5)
            if not player.Character then
                print("❌ Персонаж не респавнится, прерываем цикл")
                break
            end
        end
        
        // ЦИКЛ 1: MetalGiver
        if not autoEnabled then break end
        executeMetalCycle()
        
        if not autoEnabled then break end
        
        // Телепорт к ClearGiver
        local clearGiver = workspace.Jobs["Работник завода"].ClearGiver
        local clearCFrame = clearGiver.CFrame + Vector3.new(0, 5, 0)
        
        print("🔄 Безопасная телепортация к ClearGiver...")
        safeTeleport(clearCFrame)
        
        // Даем время на стабилизацию
        wait(3)
        
        print("⏳ Ждем 10 секунд...")
        for i = 1, 10 do
            if not autoEnabled then break end
            wait(1)
        end
        
        // ЦИКЛ 2: ClearGiver
        if not autoEnabled then break end
        executeClearCycle()
        
        // Ожидание 15 секунд
        if not autoEnabled then break end
        print("⏳ Ждем 15 секунд...")
        for i = 1, 15 do
            if not autoEnabled then break end
            wait(1)
        end
        
        // ЦИКЛ 3: Лава и сбор (С СУПЕР-БЕЗОПАСНОСТЬЮ)
        if not autoEnabled then break end
        local lavaSuccess = executeLavaCycle()
        
        if not lavaSuccess then
            print("❌ Ошибка в цикле лавы, продолжаем...")
        end
        
        // ЦИКЛ 4: Загрузка в бокс
        if not autoEnabled then break end
        local boxSuccess = executeBoxCycle()
        
        if not boxSuccess then
            print("❌ Ошибка в цикле бокса, продолжаем...")
        end
        
        // Ожидание 20 секунд перед следующим циклом
        if not autoEnabled then break end
        print("⏳ Ждем 20 секунд перед следующим циклом...")
        for i = 1, 20 do
            if not autoEnabled then break end
            wait(1)
        end
        
        // Телепорт к MetalGiver для следующего цикла
        if not autoEnabled then break end
        local metalGiver = workspace.Jobs["Работник завода"].MetalGiver
        local metalCFrame = metalGiver.CFrame + Vector3.new(0, 5, 0)
        
        print("🔄 Безопасная телепортация к MetalGiver...")
        safeTeleport(metalCFrame)
        
        // Даем время на стабилизацию
        wait(3)
        
        print("🎉 ЦИКЛ " .. currentCycle .. " ЗАВЕРШЕН! ================")
    end
    
    print("❌ АВТОМАТИЧЕСКИЙ ЦИКЛ ОСТАНОВЛЕН")
    
    // Выключаем noclip при остановке
    if noclipEnabled then
        toggleNoclip()
    end
end

// Функция остановки цикла
local function stopAutoCycle()
    if autoEnabled then
        autoEnabled = false
        print("🛑 Останавливаем автоматический цикл...")
    else
        print("ℹ️ Авто-цикл не запущен!")
    end
end

// Создаем GUI для управления
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFactoryGUI"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 220)
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

// Информация о цикле
local cycleLabel = Instance.new("TextLabel")
cycleLabel.Size = UDim2.new(1, 0, 0, 20)
cycleLabel.Position = UDim2.new(0, 0, 0.15, 0)
cycleLabel.BackgroundTransparency = 1
cycleLabel.Text = "Цикл: 0"
cycleLabel.TextColor3 = Color3.new(1, 1, 1)
cycleLabel.TextSize = 14
cycleLabel.Font = Enum.Font.Gotham
cycleLabel.Parent = mainFrame

// Кнопка запуска
local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.9, 0, 0, 40)
startButton.Position = UDim2.new(0.05, 0, 0.3, 0)
startButton.BackgroundColor3 = Color3.new(0, 0.6, 0)
startButton.Text = "🚀 ЗАПУСТИТЬ АВТО-ЦИКЛ"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Parent = mainFrame

// Кнопка остановки
local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0.9, 0, 0, 40)
stopButton.Position = UDim2.new(0.05, 0, 0.6, 0)
stopButton.BackgroundColor3 = Color3.new(0.8, 0, 0)
stopButton.Text = "🛑 ОСТАНОВИТЬ ЦИКЛ"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = mainFrame

// Кнопка Noclip
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.4, 0, 0, 25)
noclipButton.Position = UDim2.new(0.05, 0, 0.85, 0)
noclipButton.BackgroundColor3 = Color3.new(0.5, 0, 0.5)
noclipButton.Text = "👻 Noclip: ВЫКЛ"
noclipButton.TextColor3 = Color3.new(1, 1, 1)
noclipButton.TextSize = 12
noclipButton.Font = Enum.Font.Gotham
noclipButton.Parent = mainFrame

// Кнопка взятия ковша
local kovshButton = Instance.new("TextButton")
kovshButton.Size = UDim2.new(0.4, 0, 0, 25)
kovshButton.Position = UDim2.new(0.55, 0, 0.85, 0)
kovshButton.BackgroundColor3 = Color3.new(0.2, 0.5, 0.2)
kovshButton.Text = "🥄 Взять ковш"
kovshButton.TextColor3 = Color3.new(1, 1, 1)
kovshButton.TextSize = 12
kovshButton.Font = Enum.Font.Gotham
kovshButton.Parent = mainFrame

// Подключаем функции к кнопкам
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

// Обновление информации о цикле
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

// Делаем GUI перемещаемым
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

print("✅ АВТОМАТИЧЕСКИЙ ЗАВОД С СУПЕР-БЕЗОПАСНОЙ ТЕЛЕПОРТАЦИЕЙ ЗАГРУЖЕН!")
print("🛡️  Максимальная защита для телепортации к Shapes активирована")
print("👻  Noclip автоматически включается на время ожидания после лавы")
print("📝 Инструкция:")
print("   🚀 Нажми 'ЗАПУСТИТЬ АВТО-ЦИКЛ' для начала")
print("   🛑 Нажми 'ОСТАНОВИТЬ ЦИКЛ' для остановки")
