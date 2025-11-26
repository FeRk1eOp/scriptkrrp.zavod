-- Умный телепорт с обходом античита и Noclip
local noclipEnabled = false
local noclipConnection = nil

-- Функция для взятия ковша в руку
local function equipKovsh()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if not backpack then
        print("❌ Рюкзак не найден")
        return false
    end
    
    if not character then
        print("❌ Персонаж не найден")
        return false
    end
    
    -- Ищем ковш в рюкзаке
    local kovsh = backpack:FindFirstChild("Сосуд")
    if not kovsh then
        print("❌ Ковш не найден в рюкзаке")
        return false
    end
    
    -- Проверяем, не находится ли ковш уже в руке
    if character:FindFirstChild("Сосуд") then
        print("✅ Ковш уже в руке")
        return true
    end
    
    -- Берем ковш в руку
    kovsh.Parent = character
    print("✅ Ковш взят в руку")
    return true
end

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

-- Улучшенная функция умного телепорта с повторными попытками
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
        local steps = 50
        local currentPos = humanoidRootPart.Position
        local targetPos = targetCFrame.Position
        local step = (targetPos - currentPos) / steps
        
        for i = 1, steps do
            humanoidRootPart.CFrame = CFrame.new(currentPos + step * i)
            wait(0.02)
        end
        
        -- Дополнительная проверка и корректировка позиции
        local finalDistance = (humanoidRootPart.Position - targetPos).Magnitude
        if finalDistance > 5 then
            humanoidRootPart.CFrame = targetCFrame
        end
        
        return true
    end
    
    -- Метод 2: Через VehicleSeat
    local function vehicleSeatTeleport()
        local seat = Instance.new("VehicleSeat")
        seat.CFrame = targetCFrame
        seat.Anchored = true
        seat.CanCollide = false
        seat.Parent = workspace
        
        humanoidRootPart.CFrame = targetCFrame
        wait(0.2)
        seat:Destroy()
        return true
    end
    
    -- Метод 3: Через Platform
    local function platformTeleport()
        local platform = Instance.new("Part")
        platform.Anchored = true
        platform.CanCollide = true
        platform.Size = Vector3.new(10, 2, 10)
        platform.CFrame = targetCFrame
        platform.Transparency = 1
        platform.Parent = workspace
        
        humanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 5, 0)
        wait(0.3)
        platform:Destroy()
        return true
    end
    
    -- Пробуем методы по порядку с повторными попытками
    local methods = {gradualTeleport, vehicleSeatTeleport, platformTeleport}
    
    for attempt = 1, 3 do
        print("🔄 Попытка телепортации " .. attempt .. "/3")
        
        for i, method in ipairs(methods) do
            local success, result = pcall(method)
            if success and result then
                -- Проверяем действительно ли мы дошли до цели
                local finalDistance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
                
                if finalDistance <= 10 then
                    print("✅ Телепорт успешен методом " .. i)
                    -- Восстанавливаем исходное состояние Noclip
                    if not wasNoclipEnabled then
                        toggleNoclip()
                    end
                    return true
                else
                    print("⚠️ Телепорт методом " .. i .. " не до конца успешен, расстояние: " .. math.floor(finalDistance))
                end
            else
                print("❌ Метод " .. i .. " не сработал")
            end
            wait(0.5)
        end
        
        print("🔄 Повторная попытка телепортации...")
        wait(1)
    end
    
    -- Восстанавливаем исходное состояние Noclip
    if not wasNoclipEnabled then
        toggleNoclip()
    end
    
    print("❌ Все методы телепортации не сработали")
    return false
end

-- Функция для быстрого сбора слитков через ClickDetector (без задержек)
local function collectShapes()
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    
    print("⚡ Начинаем быстрый сбор слитков...")
    
    for i = 1, 10 do
        local shape = shapesModel:FindFirstChild(tostring(i))
        if shape then
            local clickDetector = shape:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
                print("✅ Слиток " .. i .. " собран")
            else
                print("❌ ClickDetector не найден в форме " .. i)
            end
        else
            print("❌ Форма " .. i .. " не найдена")
        end
        -- Убрана задержка для быстрого сбора
    end
    
    print("🎉 Все слитки собраны!")
end

-- Функция для автоматической загрузки слитков в бокс
local function autoLoadMetals()
    local Event = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_metal
    local box = workspace.Jobs["Работник завода"].Box_Conveyor.Box.body
    
    print("🔄 Начинаем загрузку слитков в бокс...")
    
    for i = 1, 10 do
        local success, error = pcall(function()
            Event:FireServer(box)
            print("✅ Слиток " .. i .. " загружен в бокс!")
        end)
        
        if not success then
            print("❌ Ошибка загрузки: " .. tostring(error))
        end
        
        wait(0.5)
    end
    
    print("🎉 Все слитки загружены в бокс!")
end

-- Функция для полного автоматического процесса
local function fullAutoProcess()
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    -- Проверяем персонажа
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("❌ Персонаж не найден")
        return
    end
    
    -- Берем ковш в руку
    if not equipKovsh() then
        print("❌ Не удалось взять ковш, процесс прерван")
        return
    end
    
    -- Телепортируемся к Shapes
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    local shapesCFrame = shapesModel:GetModelCFrame() or shapesModel:GetBoundingBox().p
    
    print("🔄 Телепортируемся к Shapes...")
    local teleportSuccess = smartTeleport(shapesCFrame + Vector3.new(0, 5, 0))
    
    if not teleportSuccess then
        print("❌ Не удалось телепортироваться к Shapes")
        return
    end
    
    wait(2) -- Ждем стабилизации
    
    -- Ивенты для работы с лавой
    local giveLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].give_lava
    local placeLavaEvent = game:GetService("ReplicatedStorage").Events.Jobs["Работник завода"].place_lava
    local lavaGiver = workspace.Jobs["Работник завода"].Melting_Conveyor.Lava_Giver
    
    print("🔥 Начинаем процесс заполнения 10 форм...")
    
    -- Выполняем 10 циклов заливки лавы
    for i = 1, 10 do
        print("🔄 Цикл " .. i .. "/10 - Заливка лавы")
        
        -- Берем лаву
        local success1, error1 = pcall(function()
            giveLavaEvent:FireServer(lavaGiver)
            print("✅ Лава взята")
        end)
        
        if not success1 then
            print("❌ Ошибка взятия лавы: " .. tostring(error1))
        end
        
        wait(1)
        
        -- Выливаем лаву в форму
        local success2, error2 = pcall(function()
            local shape = shapesModel:FindFirstChild(tostring(i))
            
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
        
        wait(1)
    end
    
    print("🎉 Все 10 форм заполнены лавой!")
    
    -- Ждем 18 секунд пока Shapes едет (увеличено с 8 до 18)
    print("⏳ Ждем 18 секунд пока Shapes едет...")
    wait(18)
    
    -- Выключаем Noclip после ожидания
    if noclipEnabled then
        toggleNoclip()
        print("✅ Noclip выключен после ожидания")
    end
    
    -- Быстро собираем слитки (без задержек)
    collectShapes()
    
    -- Телепортируемся к боксу
    local box = workspace.Jobs["Работник завода"].Box_Conveyor.Box
    local boxCFrame = box:GetModelCFrame() or box:GetBoundingBox().p
    
    print("🔄 Телепортируемся к боксу...")
    local boxTeleportSuccess = smartTeleport(boxCFrame + Vector3.new(0, 5, 0))
    
    if not boxTeleportSuccess then
        print("❌ Не удалось телепортироваться к боксу")
        return
    end
    
    wait(2) -- Ждем стабилизации
    
    -- Загружаем слитки в бокс
    autoLoadMetals()
    
    print("🎉 Полный процесс завершен!")
end

-- Функция для телепорта к Shapes
local function teleportToShapes()
    local shapesModel = workspace.Jobs["Работник завода"].Shapes_Conveyor.Shapes
    local shapesCFrame = shapesModel:GetModelCFrame() or shapesModel:GetBoundingBox().p
    
    print("🔄 Телепортируемся к Shapes...")
    smartTeleport(shapesCFrame + Vector3.new(0, 5, 0))
end

-- Функция для телепорта к боксу
local function teleportToBox()
    local box = workspace.Jobs["Работник завода"].Box_Conveyor.Box
    local boxCFrame = box:GetModelCFrame() or box:GetBoundingBox().p
    
    print("🔄 Телепортируемся к боксу...")
    smartTeleport(boxCFrame + Vector3.new(0, 5, 0))
end

-- Создаем GUI
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FullAutoGUI"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 280)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
titleLabel.Text = "🏭 Полный Авто-Процесс"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Кнопка полного автоматического процесса
local fullAutoButton = Instance.new("TextButton")
fullAutoButton.Size = UDim2.new(0.9, 0, 0, 40)
fullAutoButton.Position = UDim2.new(0.05, 0, 0.12, 0)
fullAutoButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.1)
fullAutoButton.Text = "🔥 ПОЛНЫЙ АВТО-ПРОЦЕСС"
fullAutoButton.TextColor3 = Color3.new(1, 1, 1)
fullAutoButton.TextSize = 12
fullAutoButton.Font = Enum.Font.GothamBold
fullAutoButton.Parent = mainFrame

-- Кнопка взятия ковша
local kovshButton = Instance.new("TextButton")
kovshButton.Size = UDim2.new(0.9, 0, 0, 30)
kovshButton.Position = UDim2.new(0.05, 0, 0.3, 0)
kovshButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
kovshButton.Text = "🥄 Взять ковш"
kovshButton.TextColor3 = Color3.new(1, 1, 1)
kovshButton.TextSize = 12
kovshButton.Font = Enum.Font.Gotham
kovshButton.Parent = mainFrame

-- Кнопка Noclip
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9, 0, 0, 30)
noclipButton.Position = UDim2.new(0.05, 0, 0.45, 0)
noclipButton.BackgroundColor3 = Color3.new(0.5, 0, 0.5)
noclipButton.Text = "👻 Noclip: ВЫКЛ"
noclipButton.TextColor3 = Color3.new(1, 1, 1)
noclipButton.TextSize = 12
noclipButton.Font = Enum.Font.Gotham
noclipButton.Parent = mainFrame

-- Кнопка телепорта к Shapes
local shapesTeleportButton = Instance.new("TextButton")
shapesTeleportButton.Size = UDim2.new(0.9, 0, 0, 30)
shapesTeleportButton.Position = UDim2.new(0.05, 0, 0.6, 0)
shapesTeleportButton.BackgroundColor3 = Color3.new(0, 0.5, 1)
shapesTeleportButton.Text = "📦 Телепорт к Shapes"
shapesTeleportButton.TextColor3 = Color3.new(1, 1, 1)
shapesTeleportButton.TextSize = 12
shapesTeleportButton.Font = Enum.Font.Gotham
shapesTeleportButton.Parent = mainFrame

-- Кнопка телепорта к боксу
local boxTeleportButton = Instance.new("TextButton")
boxTeleportButton.Size = UDim2.new(0.9, 0, 0, 30)
boxTeleportButton.Position = UDim2.new(0.05, 0, 0.75, 0)
boxTeleportButton.BackgroundColor3 = Color3.new(0.5, 0.3, 0.1)
boxTeleportButton.Text = "📦 Телепорт к боксу"
boxTeleportButton.TextColor3 = Color3.new(1, 1, 1)
boxTeleportButton.TextSize = 12
boxTeleportButton.Font = Enum.Font.Gotham
boxTeleportButton.Parent = mainFrame

-- Кнопка сбора слитков
local collectButton = Instance.new("TextButton")
collectButton.Size = UDim2.new(0.9, 0, 0, 30)
collectButton.Position = UDim2.new(0.05, 0, 0.9, 0)
collectButton.BackgroundColor3 = Color3.new(0.3, 0.2, 0.6)
collectButton.Text = "💰 Собрать слитки"
collectButton.TextColor3 = Color3.new(1, 1, 1)
collectButton.TextSize = 12
collectButton.Font = Enum.Font.Gotham
collectButton.Parent = mainFrame

-- Подключаем функции к кнопкам
fullAutoButton.MouseButton1Click:Connect(function()
    print("🚀 Запускаем полный автоматический процесс...")
    fullAutoProcess()
end)

kovshButton.MouseButton1Click:Connect(function()
    equipKovsh()
end)

shapesTeleportButton.MouseButton1Click:Connect(function()
    teleportToShapes()
end)

boxTeleportButton.MouseButton1Click:Connect(function()
    teleportToBox()
end)

collectButton.MouseButton1Click:Connect(function()
    collectShapes()
end)

noclipButton.MouseButton1Click:Connect(function()
    toggleNoclip()
    noclipButton.Text = noclipEnabled and "👻 Noclip: ВКЛ" or "👻 Noclip: ВЫКЛ"
    noclipButton.BackgroundColor3 = noclipEnabled and Color3.new(0, 0.8, 0) or Color3.new(0.5, 0, 0.5)
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

print("✅ Полный авто-процесс создан!")
print("⏱️ Увеличенная задержка до 18 секунд")
print("⚡ Быстрый сбор слитков без задержек")
print("🔥 Нажми кнопку 'ПОЛНЫЙ АВТО-ПРОЦЕСС' для запуска")
