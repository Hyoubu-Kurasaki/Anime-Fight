-- // Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- // Create Window
local Window = Rayfield:CreateWindow({
    Name = "⭐ Hyoubu Hub",
    LoadingTitle = "Hyoubu Hub",
    LoadingSubtitle = "eu odeio o z1nz",
    Theme = "Default",
    ToggleUIKeybind = "K",
    
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "HyoubuHub",
        FileName = "Settings"
    }
})

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Bridge = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bridge")

-- // Variables
local StarFarmEnabled = false
local AutoClickEnabled = false
local ClickDelay = 0.05
local TargetFPS = 30
local FPSEnabled = false
local FPSConnection = nil

local ClickYOffset = 400
local AutoClickKey = Enum.KeyCode.Z 

-- // Private Functions
local function StartStarFarm()
    task.spawn(function()
        while StarFarmEnabled do
            Bridge:FireServer("General", "Star", "Open")
            task.wait(0.25)
        end
    end)
end

local function StartAutoClick()
    task.spawn(function()
        while AutoClickEnabled do
            local viewport = workspace.CurrentCamera.ViewportSize
            local x = viewport.X / 2
            local y = viewport.Y / 2 + ClickYOffset

            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)

            task.wait(ClickDelay)
        end
    end)
end

local function FPS()
    if FPSConnection then
        FPSConnection:Disconnect()
        FPSConnection = nil
    end
    
    if not FPSEnabled or TargetFPS <= 0 then return end
    local TargetFrameTime = 1 / TargetFPS
    
    FPSConnection = RunService.RenderStepped:Connect(function()
        local t0 = tick()
        repeat until t0 + TargetFrameTime < tick()
    end)
end

local function ToggleFPSLimit(Value)
    FPSEnabled = Value
    if Value then
        FPS()
    elseif FPSConnection then
        FPSConnection:Disconnect()
        FPSConnection = nil
    end
end

-- // Keybind Handler
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == AutoClickKey then
        AutoClickEnabled = not AutoClickEnabled
        Rayfield:Notify({
            Title = "🖱️ Auto Click",
            Content = AutoClickEnabled and "Ativado!" or "Desativado!",
            Duration = 3,
            Image = 4483362458
        })
        if AutoClickEnabled then
            StartAutoClick()
        end
    end
end)

-- // Tabs
local MainTab = Window:CreateTab("Main", 6022668969)

MainTab:CreateToggle({
    Name = "⭐ Speed Star",
    CurrentValue = false,
    Flag = "AutoStarFarm",
    Callback = function(Value)
        StarFarmEnabled = Value
        if Value then StartStarFarm() end
    end,
})

MainTab:CreateInput({
    Name = "🕐 Atraso do Clique (segundos)",
    CurrentValue = tostring(ClickDelay),
    PlaceholderText = "Ex: 0.05 (Rápido)",
    RemoveTextAfterFocusLost = false,
    Flag = "AutoClickDelayInput",
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0.001 then
            ClickDelay = num
        else
            Rayfield:Notify({
                Title = "Hyoubu Hub | Aviso",
                Content = "Atraso inválido. Usando: " .. tostring(ClickDelay),
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

MainTab:CreateInput({
    Name = "⌨️ Tecla pra ativar clique",
    PlaceholderText = "Z",
    RemoveTextAfterFocusLost = false,
    Flag = "ClickKeyInput",
    Callback = function(Text)
        local key = Enum.KeyCode[string.upper(Text)]
        if key then
            AutoClickKey = key
            Rayfield:Notify({
                Title = "Hyoubu Hub",
                Content = "Tecla definida para: " .. Text:upper(),
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Hyoubu Hub | Aviso",
                Content = "Tecla inválida.",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "⚙️ Limite de FPS (Ativar)",
    CurrentValue = false,
    Flag = "FPSEnableToggle",
    Callback = ToggleFPSLimit,
})

MainTab:CreateSlider({
    Name = "⚙️ FPS Alvo",
    Range = {1, 60},
    Increment = 1,
    Suffix = " FPS",
    CurrentValue = TargetFPS,
    Flag = "FPSSliderValue",
    Callback = function(Value)
        TargetFPS = math.floor(Value)
        if FPSEnabled then FPS() end
    end,
})

Rayfield:Notify({
    Title = "Hyoubu Hub",
    Content = "Interface carregada com sucesso!",
    Duration = 5,
    Image = 4483362458
})
