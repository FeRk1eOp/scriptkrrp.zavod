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
        print("Noclip включен")
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
        print("Noclip выключен")
    end
end

-- Плавная телепортация малыми шагами
local function smoothTeleport(targetCFrame, teleportName)
    local character = player.Character
    if not character then 
        print("Персонаж не найден для телепортации: " .. teleportName)
        return false 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then 
        print("HumanoidRootPart или Humanoid не найден: " .. teleportName)
        return false 
    end
    
    print("Запускаем плавную телепортацию: " .. teleportName)
    
    local wasNoclipEnabled = noclipEnabled
    local originalHealth = humanoid.Health
    
    if not noclipEnabled then
        toggleNoclip()
    end
    
    humanoid.MaxHealth = 10000
    humanoid.Health = 10000
    
    local startPos = humanoidRootPart.Position
    local endPos = targetCFrame.Position
    local distance = (endPos - startPos).Magnitude
    
    print("Расстояние: " .. math.floor(distance))
    
    local success = false
    
    -- Плавная телепортация малыми шагами
    local steps = math.max(20, distance / 5)
    print("Шагов телепортации: " .. steps)
    
    for i = 1, steps do
        if not autoEnabled or humanoid.Health <= 0 then break end
        
        local progress = i / steps
        local currentPos = startPos:Lerp(endPos, progress)
        humanoidRootPart.CFrame = CFrame.new(currentPos, endPos)
        
        wait(0.05)
    end
    
    -- Финальная позиция
    if humanoid.Health > 0 then
        humanoidRootPart.CFrame = targetCFrame
        wait(0.5)
        
        local finalDistance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
        
        if finalDistance <= 10 then
            print("Телепортация успешна: " .. teleportName)
            success = true
        else
            print("Телепортация не совсем точная, но продолжаем...")
            success = true
        end
    else
        print("Игрок умер во время телепортации: " .. teleportName)
    end
    
    if humanoid then
        humanoid.MaxHealth = 100
        humanoid.Health = math.min(originalHealth, 100)
    end
    
    if not wasNoclipEnabled then
        toggleNoclip()
    end
    
    return success
end

-- Функция взятия ковша
local function equipKovsh()
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if not backpack or not character then 
        print("Рюкзак или персонаж не найден")
        return false 
    end
    
    local kovsh = backpack:FindFirstChild("Сосуд")
    if not kovsh then
        print("Ковш не найден в рюкзаке")
        return false
    end
    
    if character:FindFirstChild("Сосуд") then
        print("Ковш уже в руке")
        return true
    end
    
    kovsh.Parent = character
    print("Ковш взят в руку")
    return true
end

-- ЦИКЛ 1: ClearGiver (10 раз)
local function executeClearCycle()
    local clearGiver = workspace.Jobs["Работник завода"].ClearGiver
    local clickDetector = clearGiver.ClickDetector
    local event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place
    local clickPart = workspace.Jobs["Работник завода"].Melting_Conveyor.ClickPart
    
    print("Начинаем цикл ClearGiver...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        pcall(function()
            fireclickdetector(clickDetector)
        end)
        wait(0.5)
        
        pcall(function()
            event:FireServer(clickPart)
        end)
        wait(0.5)
    end
    
    print("Цикл ClearGiver завершен")
end

-- ЦИКЛ 2: MetalGiver (10 раз)
local function executeMetalCycle()
    local metalGiver = workspace.Jobs["Работник завода"].MetalGiver
    local clickDetector = metalGiver.ClickDetector
    local event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place
    local clickPart = workspace.Jobs["Работник завода"].Water_Clear_Conveyor.ClickPart
    
    print("Начинаем цикл MetalGiver...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        pcall(function()
            fireclickdetector(clickDetector)
        end)
        wait(0.5)
        
        pcall(function()
            event:FireServer(clickPart)
        end)
        wait(0.5)
    end
    
    print("Цикл MetalGiver завершен")
end

-- ЦИКЛ 3: Лава и сбор металла
local function executeLavaCycle()
    if not equipKovsh() then
        print("Не удалось взять ковш")
        return false
    end
    
    -- Телепортируемся к Shapes
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    if not shapesModel then
        print("Модель Shapes не найдена!")
        return false
    end
    
    -- Получаем безопасную позицию над Shapes
    local shapesPosition
    if shapesModel:IsA("Model") then
        shapesPosition = shapesModel:GetModelCFrame()
    else
        shapesPosition = shapesModel.CFrame
    end
    
    if not shapesPosition then
        shapesPosition = shapesModel:GetBoundingBox().CFrame
    end
    
    -- Добавляем безопасную высоту
    shapesPosition = shapesPosition + Vector3.new(0, 10, 0)
    
    print("Телепортация к Shapes...")
    if not smoothTeleport(shapesPosition, "Shapes") then
        print("Не удалось телепортироваться к Shapes")
        return false
    end
    
    -- Даем время на стабилизацию
    wait(3)
    
    -- Проверяем, жив ли игрок
    local character = player.Character
    if not character or not character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("Humanoid").Health <= 0 then
        print("Игрок умер, прерываем цикл")
        return false
    end
    
    -- Ивенты для лавы
    local giveLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].give_lava
    local placeLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_lava
    local lavaGiver = workspace.Jobs["Работник завода"].Melting_Conveyor.Lava_Giver
    
    print("Начинаем заливку лавы...")
    
    for i = 1, 10 do
        if not autoEnabled then break end
        
        -- Проверяем здоровье перед каждым действием
        if character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("Игрок умер во время заливки лавы")
            return false
        end
        
        pcall(function()
            giveLavaEvent:FireServer(lavaGiver)
            print("Взяли лаву " .. i)
        end)
        wait(0.7)
        
        pcall(function()
            local shape = shapesModel:FindFirstChild(tostring(i))
            if shape then
                placeLavaEvent:FireServer(shape)
                print("Вылили лаву в форму " .. i)
            else
                print("Форма " .. i .. " не найдена!")
            end
        end)
        wait(0.7)
    end
    
    print("Заливка лавы завершена")
    
    -- ВКЛЮЧАЕМ NOCLIP НА ВРЕМЯ ОЖИДАНИЯ 18 СЕКУНД
    local wasNoclipBeforeWait = noclipEnabled
    if not noclipEnabled then
        toggleNoclip()
        print("Noclip включен на время ожидания")
    end
    
    -- Ждем 18 секунд с проверкой здоровья
    print("Ждем 18 секунд с включенным noclip...")
    for i = 1, 18 do
        if not autoEnabled then break end
        
        -- Проверяем, не умер ли игрок
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("Игрок умер во время ожидания")
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
        print("Noclip выключен после ожидания")
    end
    
    -- Собираем слитки
    print("Собираем слитки...")
    for i = 1, 10 do
        if not autoEnabled then break end
        
        -- Проверка здоровья
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("Игрок умер во время сбора")
            return false
        end
        
        local shape = shapesModel:FindFirstChild(tostring(i))
        if shape then
            local clickDetector = shape:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
                print("Собрали слиток " .. i)
            end
        end
        wait(0.2)
    end
    
    print("Слитки собраны")
    return true
end

-- Главная функция автоматического цикла
local function startAutoCycle()
    if autoEnabled then
        print("Авто-цикл уже запущен!")
        return
    end
    
    autoEnabled = true
    currentCycle = 0
    
    print("ЗАПУСК АВТОМАТИЧЕСКОГО ЦИКЛА!")
    
    while autoEnabled do
        currentCycle = currentCycle + 1
        print("ЗАПУСК ЦИКЛА " .. currentCycle)
        
        if not player.Character or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            print("Игрок мертв, ждем респавна...")
            wait(5)
            if not player.Character then
                print("Персонаж не респавнится, прерываем цикл")
                break
            end
        end
        
        -- НАЧИНАЕМ С CLEARGIVER
        
        -- Телепорт к ClearGiver
        local clearGiver = workspace.Jobs["Работник завода"].ClearGiver
        local clearCFrame = clearGiver.CFrame + Vector3.new(0, 5, 0)
        print("Телепортация к ClearGiver...")
        smoothTeleport(clearCFrame, "ClearGiver")
        wait(3)
        
        if not autoEnabled then break end
        executeClearCycle()
        
        -- Ждем 10 секунд после ClearGiver
        if not autoEnabled then break end
        print("Ждем 10 секунд после ClearGiver...")
        for i = 1, 10 do
            if not autoEnabled then break end
            wait(1)
        end
        
        -- ПЕРЕХОДИМ К METALGIVER
        
        -- Телепорт к MetalGiver
        local metalGiver = workspace.Jobs["Работник завода"].MetalGiver
        local metalCFrame = metalGiver.CFrame + Vector3.new(0, 5, 0)
        print("Телепортация к MetalGiver...")
        smoothTeleport(metalCFrame, "MetalGiver")
        wait(3)
        
        if not autoEnabled then break end
        executeMetalCycle()
        
        -- Ждем 10 секунд после MetalGiver
        if not autoEnabled then break end
        print("Ждем 10 секунд после MetalGiver...")
        for i = 1, 10 do
            if not autoEnabled then break end
            wait(1)
        end
        
        -- ЗАВЕРШАЕМ РАЗЛИВКОЙ ЛАВЫ
        
        if not autoEnabled then break end
        local lavaSuccess = executeLavaCycle()
        
        if not lavaSuccess then
            print("Ошибка в цикле лавы, прерываем цикл")
        end
        
        print("ЦИКЛ " .. currentCycle .. " ЗАВЕРШЕН!")
        break -- Завершаем после одного цикла
    end
    
    print("АВТОМАТИЧЕСКИЙ ЦИКЛ ОСТАНОВЛЕН")
    
    if noclipEnabled then
        toggleNoclip()
    end
end

-- Функция остановки цикла
local function stopAutoCycle()
    if autoEnabled then
        autoEnabled = false
        print("Останавливаем автоматический цикл...")
    else
        print("Авто-цикл не запущен!")
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
titleLabel.Text = "АВТОМАТИЧЕСКИЙ ЗАВОД"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local cycleLabel = Instance.new("TextLabel")
cycleLabel.Size = UDim2.new(1, 0, 0, 20)
cycleLabel.Position = UDim2.new(0, 0, 0.15, 0)
cycleLabel.BackgroundTransparency = 1
cycleLabel.Text = "Цикл: 0"
cycleLabel.TextColor3 = Color3.new(1, 1, 1)
cycleLabel.TextSize = 14
cycleLabel.Font = Enum.Font.Gotham
cycleLabel.Parent = mainFrame

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.9, 0, 0, 40)
startButton.Position = UDim2.new(0.05, 0, 0.3, 0)
startButton.BackgroundColor3 = Color3.new(0, 0.6, 0)
startButton.Text = "ЗАПУСТИТЬ АВТО-ЦИКЛ"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Parent = mainFrame

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0.9, 0, 0, 40)
stopButton.Position = UDim2.new(0.05, 0, 0.6, 0)
stopButton.BackgroundColor3 = Color3.new(0.8, 0, 0)
stopButton.Text = "ОСТАНОВИТЬ ЦИКЛ"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = mainFrame

local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.4, 0, 0, 25)
noclipButton.Position = UDim2.new(0.05, 0, 0.85, 0)
noclipButton.BackgroundColor3 = Color3.new(0.5, 0, 0.5)
noclipButton.Text = "Noclip: ВЫКЛ"
noclipButton.TextColor3 = Color3.new(1, 1, 1)
noclipButton.TextSize = 12
noclipButton.Font = Enum.Font.Gotham
noclipButton.Parent = mainFrame

local kovshButton = Instance.new("TextButton")
kovshButton.Size = UDim2.new(0.4, 0, 0, 25)
kovshButton.Position = UDim2.new(0.55, 0, 0.85, 0)
kovshButton.BackgroundColor3 = Color3.new(0.2, 0.5, 0.2)
kovshButton.Text = "Взять ковш"
kovshButton.TextColor3 = Color3.new(1, 1, 1)
kovshButton.TextSize = 12
kovshButton.Font = Enum.Font.Gotham
kovshButton.Parent = mainFrame

startButton.MouseButton1Click:Connect(function()
    spawn(startAutoCycle)
end)

stopButton.MouseButton1Click:Connect(function()
    stopAutoCycle()
end)

noclipButton.MouseButton1Click:Connect(function()
    toggleNoclip()
    noclipButton.Text = noclipEnabled and "Noclip: ВКЛ" or "Noclip: ВЫКЛ"
    noclipButton.BackgroundColor3 = noclipEnabled and Color3.new(0, 0.8, 0) or Color3.new(0.5, 0, 0.5)
end)

kovshButton.MouseButton1Click:Connect(function()
    equipKovsh()
end)

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

print("АВТОМАТИЧЕСКИЙ ЗАВОД ЗАГРУЖЕН!")
print("Порядок работы: ClearGiver -> MetalGiver -> Разливка лавы")
print("Нажми 'ЗАПУСТИТЬ АВТО-ЦИКЛ' для начала")
