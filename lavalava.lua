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

-- Безопасная телепортация с TweenService
local function safeTweenTeleport(targetCFrame, teleportName)
    local character = player.Character
    if not character then 
        print("❌ Персонаж не найден для телепортации: " .. teleportName)
        return false 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then 
        print("❌ HumanoidRootPart или Humanoid не найден: " .. teleportName)
        return false 
    end
    
    print("🔄 Запускаем безопасную телепортацию: " .. teleportName)
    
    -- Сохраняем исходное состояние
    local wasNoclipEnabled = noclipEnabled
    local originalHealth = humanoid.Health
    
    -- Включаем защиту
    if not noclipEnabled then
        toggleNoclip()
    end
    
    -- Временно увеличиваем здоровье для защиты
    humanoid.MaxHealth = 10000
    humanoid.Health = 10000
    
    -- Вычисляем расстояние для определения времени телепортации
    local startPos = humanoidRootPart.Position
    local endPos = targetCFrame.Position
    local distance = (endPos - startPos).Magnitude
    local tweenTime = math.min(10, math.max(3, distance / 30)) -- Динамическое время от 3 до 10 секунд
    
    print("📏 Расстояние: " .. math.floor(distance) .. ", время телепортации: " .. tweenTime .. "с")
    
    local success = false
    
    -- Используем TweenService для плавной телепортации
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    -- Проверяем, что targetCFrame валиден
    if not targetCFrame or typeof(targetCFrame) ~= "CFrame" then
        print("❌ Неверный targetCFrame для телепортации: " .. teleportName)
        return false
    end
    
    local tween = tweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    
    -- Запускаем твин
    tween:Play()
    
    -- Ждем завершения твина с проверкой состояния
    local startTime = tick()
    while tick() - startTime < tweenTime + 2 do -- +2 секунды на запас
        if not autoEnabled or humanoid.Health <= 0 then
            tween:Cancel()
            break
        end
        
        -- Проверяем, завершился ли твин
        if not tween.PlaybackState == Enum.PlaybackState.Playing then
            break
        end
        
        wait(0.1)
    end
    
    -- Дополнительная проверка и корректировка позиции
    if humanoid.Health > 0 then
        -- Убеждаемся, что мы на месте
        humanoidRootPart.CFrame = targetCFrame
        wait(0.5)
        
        local finalDistance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
        
        if finalDistance <= 15 then
            print("✅ Безопасная телепортация успешна: " .. teleportName)
            success = true
        else
            print("⚠️ Телепортация не совсем точная, корректируем...")
            -- Пробуем еще раз с быстрой телепортацией
            humanoidRootPart.CFrame = targetCFrame
            wait(0.5)
            
            local finalDistance2 = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
            if finalDistance2 <= 15 then
                print("✅ Корректировка успешна: " .. teleportName)
                success = true
            else
                print("❌ Телепортация не удалась: " .. teleportName)
            end
        end
    else
        print("💀 Игрок умер во время телепортации: " .. teleportName)
    end
    
    -- Восстанавливаем здоровье
    if humanoid then
        humanoid.MaxHealth = 100
        humanoid.Health = math.min(originalHealth, 100)
    end
    
    -- Восстанавливаем noclip
    if not wasNoclipEnabled then
        toggleNoclip()
    end
    
    return success
end

-- Обычная ультра-безопасная телепортация (теперь использует safeTweenTeleport)
local function ultraSafeTeleport(targetCFrame)
    return safeTweenTeleport(targetCFrame, "Ультра-безопасная телепортация")
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
        wait(0.5)
        
        pcall(function()
            event:FireServer(clickPart)
            print("✅ Ивент place " .. i)
        end)
        wait(0.5)
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
        wait(0.5)
        
        pcall(function()
            event:FireServer(clickPart)
            print("✅ Ивент place Clear " .. i)
        end)
        wait(0.5)
    end
    
    print("✅ Цикл ClearGiver завершен")
end

-- ЦИКЛ 3: Лава и сбор металла (ИСПРАВЛЕННАЯ ВЕРСИЯ)
local function executeLavaCycle()
    if not equipKovsh() then
        print("❌ Не удалось взять ковш")
        return false
    end
    
    -- Телепортируемся к Shapes - БЕЗОПАСНАЯ ВЕРСИЯ
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    if not shapesModel then
        print("❌ Модель Shapes не найдена!")
        return false
    end
    
    -- Получаем безопасную позицию ДАЛЕКО НАД Shapes
    local shapesPosition
    if shapesModel:IsA("Model") then
        shapesPosition = shapesModel:GetModelCFrame()
    else
        shapesPosition = shapesModel.CFrame
    end
    
    if not shapesPosition then
        shapesPosition = shapesModel:GetBoundingBox().CFrame
    end
    
    -- УВЕЛИЧИВАЕМ ВЫСОТУ ДО 15 И ОТОДВИГАЕМСЯ ОТ КОНВЕЙЕРА
    shapesPosition = shapesPosition + Vector3.new(2, 15, 2) -- Смещение по X и Z для безопасности
    
    print("🔄 СУПЕР-БЕЗОПАСНАЯ телепортация к Shapes...")
    
    -- Используем улучшенную телепортацию с дополнительными проверками
    local teleportSuccess = false
    for attempt = 1, 3 do -- 3 попытки телепортации
        print("🔄 Попытка телепортации " .. attempt .. "/3")
        
        if safeTweenTeleport(shapesPosition, "Shapes (попытка " .. attempt .. ")") then
            teleportSuccess = true
            break
        else
            wait(2) -- Ждем между попытками
        end
    end
    
    if not teleportSuccess then
        print("❌ Все попытки телепортации к Shapes провалились")
        return false
    end
    
    -- ДАЕМ БОЛЬШЕ ВРЕМЕНИ НА СТАБИЛИЗАЦИЮ
    print("⏳ Стабилизируем позицию...")
    wait(5)
    
    -- Плавно опускаемся ближе к Shapes
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = character.HumanoidRootPart
        local targetPosition = shapesModel.Position + Vector3.new(2, 8, 2) -- Безопасная высота над формами
        
        print("🪂 Плавное опускание к формам...")
        for i = 1, 10 do
            if not autoEnabled then break end
            local progress = i / 10
            local currentY = humanoidRootPart.Position.Y * (1 - progress) + targetPosition.Y * progress
            local currentPos = Vector3.new(targetPosition.X, currentY, targetPosition.Z)
            humanoidRootPart.CFrame = CFrame.new(currentPos)
            wait(0.2)
        end
    end
    
    -- Проверяем, жив ли игрок
    local character = player.Character
    if not character or not character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("Humanoid").Health <= 0 then
        print("💀 Игрок умер при телепортации к Shapes")
        return false
    end
    
    -- Ивенты для лавы
    local giveLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].give_lava
    local placeLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_lava
    local lavaGiver = workspace.Jobs["Работник завода"].Melting_Conveyor.Lava_Giver
    
    print("🌋 Начинаем заливку лавы...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        -- Проверяем здоровье перед каждым действием
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
    
    -- ВКЛЮЧАЕМ NOCLIP НА ВРЕМЯ ОЖИДАНИЯ 18 СЕКУНД
    local wasNoclipBeforeWait = noclipEnabled
    if not noclipEnabled then
        toggleNoclip()
        print("👻 Noclip включен на время ожидания")
    end
    
    -- Ждем 18 секунд с проверкой здоровья
    print("⏳ Ждем 18 секунд с включенным noclip...")
    for i = 1, 18 do
        if not autoEnabled then break end
        
        -- Проверяем, не умер ли игрок
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("💀 Игрок умер во время ожидания")
            -- Выключаем noclip перед выходом
            if not wasNoclipBeforeWait then
                toggleNoclip()
            end
            return false
        end
        wait(1)
    end
    
    -- ВЫКЛЮЧАЕМ NOCLIP ПОСЛЕ ОЖИДАНИЯ (если он был выключен до этого)
    if not wasNoclipBeforeWait then
        toggleNoclip()
        print("👻 Noclip выключен после ожидания")
    end
    
    -- Собираем слитки
    print("💰 Собираем слитки...")
    for i = 1, 10 do
        if not autoEnabled then break end
        
        -- Проверка здоровья
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

-- ЦИКЛ 4: Загрузка в бокс
local function executeBoxCycle()
    -- Получаем позицию бокса
    local box = workspace.Jobs["Работник завода"].Box_Conveyor.Box
    local boxPosition = box:GetModelCFrame()
    if not boxPosition then
        boxPosition = box:GetBoundingBox().CFrame
    end
    
    -- Добавляем безопасную высоту и отодвигаем от бокса
    boxPosition = boxPosition + Vector3.new(0, 5, 3)
    
    print("🔄 Безопасная телепортация к боксу...")
    
    if not safeTweenTeleport(boxPosition, "Бокс") then
        print("❌ Не удалось телепортироваться к боксу")
        return false
    end
    
    -- Даем БОЛЬШЕ времени на стабилизацию для бокса
    wait(5)
    
    -- Проверяем, жив ли игрок
    local character = player.Character
    if not character or not character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("Humanoid").Health <= 0 then
        print("💀 Игрок умер при телепортации к боксу")
        return false
    end
    
    -- Загружаем металл в бокс
    local Event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_metal
    local boxPart = workspace.Jobs["Работник завода"].Box_Conveyor.Box.body
    
    print("📦 Загружаем металл в бокс...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        -- Проверка здоровья
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
        
        -- Проверяем, жив ли игрок перед началом цикла
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("💀 Игрок мертв, ждем респавна...")
            wait(5)
            if not player.Character then
                print("❌ Персонаж не респавнится, прерываем цикл")
                break
            end
        end
        
        -- ЦИКЛ 1: MetalGiver
        if not autoEnabled then break end
        executeMetalCycle()
        
        if not autoEnabled then break end
        
        -- Телепорт к ClearGiver
        local clearGiver = workspace.Jobs["Работник завода"].ClearGiver
        local clearCFrame = clearGiver.CFrame + Vector3.new(0, 5, 0)
        
        print("🔄 Безопасная телепортация к ClearGiver...")
        safeTweenTeleport(clearCFrame, "ClearGiver")
        
        -- Даем время на стабилизацию
        wait(3)
        
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
            if не autoEnabled then break end
            wait(1)
        end
        
        -- Телепорт к MetalGiver для следующего цикла
        if не autoEnabled then break end
        local metalGiver = workspace.Jobs["Работник завода"].MetalGiver
        local metalCFrame = metalGiver.CFrame + Vector3.new(0, 5, 0)
        
        print("🔄 Безопасная телепортация к MetalGiver...")
        safeTweenTeleport(metalCFrame, "MetalGiver")
        
        -- Даем время на стабилизацию
        wait(3)
        
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
print("🌀  TweenService-телепортация активирована для всех точек")
print("👻  Noclip автоматически включается на время ожидания после лавы")
print("🛡️  Улучшенная защита от смерти при телепортации к Shapes")
print("📝 Инструкция:")
print("   🚀 Нажми 'ЗАПУСТИТЬ АВТО-ЦИКЛ' для начала")
print("   🛑 Нажми 'ОСТАНОВИТЬ ЦИКЛ' для остановки")
