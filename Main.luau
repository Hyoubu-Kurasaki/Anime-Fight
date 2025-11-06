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
		FileName = "Settings",
	},
})

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Bridge = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bridge")

-- // Variables
local StarFarmEnabled = false
local AutoClickEnabled = false
local ClickDelay = 0.05
local TargetFPS = 30
local FPSEnabled = false
local AFKEnabled = false
local TrialEnabled = false
local TrialWave = 0
local TowerEnabled = false
local TowerWave = 0
local AutoTpEnabled = false
local Part = nil
local Gamemode = false
local AutoCollectMeteor = false
local State = {
	Trial = false,
	Tower = false,
}

local FPSConnection = nil
local AFKConnection
local ClickYOffset = 400
local AutoClickKey = Enum.KeyCode.Z

-- // Private Functions
local function StartStarFarm()
	task.spawn(function()
		while StarFarmEnabled do
			pcall(function()
				Bridge:FireServer("General", "Star", "Open")
			end)
			task.wait(0.25)
		end
	end)
end

local function StartAFK()
	if AFKConnection then
		AFKConnection:Disconnect()
		AFKConnection = nil
	end

	if not AFKEnabled then
		return
	end

	AFKConnection = Player.Idled:Connect(function()
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
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

	if not FPSEnabled or TargetFPS <= 0 then
		return
	end
	local TargetFrameTime = 1 / TargetFPS

	FPSConnection = RunService.RenderStepped:Connect(function()
		local t0 = tick()
		repeat
		until t0 + TargetFrameTime < tick()
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

local function StartTrial()
	task.spawn(function()
		local Lobby = CFrame.new(
			-2545.59814,
			-262.194031,
			1653.35571,
			-0.0989561975,
			-3.3608444e-08,
			0.995091796,
			1.30098812e-08,
			1,
			3.50679734e-08,
			-0.995091796,
			1.64162195e-08,
			-0.0989561975
		)

		local Trial = CFrame.new(
			-2649.79639,
			-260.956909,
			1655.41675,
			-0.81860286,
			6.67227482e-08,
			0.574359953,
			3.90344326e-08,
			1,
			-6.05352923e-08,
			-0.574359953,
			-2.71345506e-08,
			-0.81860286
		)

		local TrialFolder = ReplicatedStorage.Gamemodes.Trial
		local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

		if not Root then
			return
		end

		Rayfield:Notify({
			Title = "Hyoubu Hub",
			Content = "Auto Trial iniciado.",
			Duration = 3,
			Image = 4483362458,
		})

		while TrialEnabled do
			local Opened = TrialFolder:FindFirstChild("Open")
			local Wave = TrialFolder:FindFirstChild("Wave")

			if not Opened or not Wave then
				continue
			end

			if Opened.Value and not State.Trial then
				State.Trial = true
				State.Trial_State = "Teleporting"
				Gamemode = true

				Root.CFrame = Lobby

				task.wait(2.5)

				Bridge:FireServer("Gamemodes", "Trial", "Join")
				State.Trial_State = "Joined"
			end

			if State.Trial then
				if State.Trial_State == "Joined" then
					State.Trial_State = "InGame"
				end

                if State.Trial_State == "InGame" then
                    Root.CFrame = Trial
                end

				local maxWave = TrialWave <= 0 and math.huge or TrialWave
				if Wave.Value >= maxWave then
					State.Trial_State = "Leaving"
				end

				if State.Trial_State == "Leaving" then
					Bridge:FireServer("Gamemodes", "Trial", "Leave")

					State.Trial = false
					State.Trial_State = nil
					Gamemode = false
				end
			end

			task.wait()
		end
	end)
end

local function StartTower()
	task.spawn(function()
		local targetLobby = CFrame.new(
			-1568.71289,
			53.5078697,
			1560.44226,
			-0.893741369,
			-2.02394439e-08,
			0.448582649,
			-2.50651699e-09,
			1,
			4.01247497e-08,
			-0.448582649,
			3.47367681e-08,
			-0.893741369
		)

		local targetCFrame = CFrame.new(
			-2509.34204,
			-347.733246,
			2646.52539,
			-0.907230675,
			2.57756465e-08,
			-0.420633405,
			1.02833333e-08,
			1,
			3.90988717e-08,
			0.420633405,
			3.11461825e-08,
			-0.907230675
		)

		Rayfield:Notify({
			Title = "Hyoubu Hub",
			Content = "Auto Tower iniciado.",
			Duration = 3,
			Image = 4483362458,
		})

		local TowerFolder = ReplicatedStorage.Gamemodes.Tower
		local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

		if not Root then
			return
		end

		while TowerEnabled do
			local Opened = TowerFolder:FindFirstChild("Open")
			local Wave = TowerFolder:FindFirstChild("Wave")

			if not Opened or not Wave then
				continue
			end

			if Opened.Value and not State.Tower then
				State.Tower = true
				State.Tower_State = "Teleporting"
				Gamemode = true

				Root.CFrame = targetLobby

				task.wait(2.5)

				Bridge:FireServer("Gamemodes", "Tower", "Join")
				State.Tower_State = "Joined"
			end

			if State.Tower then
				if State.Tower_State == "Joined" then
					State.Tower_State = "InGame"
				end

                if State.Tower_State == "InGame" then
                    Root.CFrame = targetCFrame
                end

				local maxWave = TowerWave <= 0 and math.huge or TowerWave
				if Wave.Value >= maxWave then
					State.Tower_State = "Leaving"
				end

				if State.Tower_State == "Leaving" then
					Bridge:FireServer("Gamemodes", "Tower", "Leave")

					State.Tower = false
					State.Tower_State = nil
					Gamemode = false
				end
			end

			task.wait()
		end
	end)
end

local function StartAutoTP()
	if Part then
		Part:Destroy()
	end

	Part = Instance.new("Part")
	Part.Anchored = true
	Part.CanCollide = false
	Part.Transparency = 1
	Part.Parent = workspace
	Part.CFrame = Player.Character:WaitForChild("HumanoidRootPart").CFrame

	task.spawn(function()
		while AutoTpEnabled do
			if not Gamemode then
				local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
				if Root and Part then
					Root.CFrame = Part.CFrame
				end
			end
			task.wait(1.5)
		end
	end)
end

local function StartAutoMeteor()
	task.spawn(function()
		Rayfield:Notify({
			Title = "🌠 Auto Meteor",
			Content = "Auto Collect iniciado.",
			Duration = 3,
			Image = 4483362458,
		})

		local Collected = {}

		while AutoCollectMeteor do
			for _, Meteor in pairs(workspace.Server.GameEvent.Meteors.Spawned:GetChildren()) do
				if Meteor:IsA("Model") and Meteor:FindFirstChild("Mesh") then
					local Prompt = Meteor.Mesh:FindFirstChildOfClass("ProximityPrompt")
					if Prompt and not Collected[Meteor] then
						Prompt.HoldDuration = 0
						Prompt.RequiresLineOfSight = false
						Prompt.MaxActivationDistance = 30

						local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
						if Root then
							local dist = (Root.Position - Meteor.Mesh.Position).Magnitude
							if dist > 25 then
								local oldCFrame = Root.CFrame
								Root.CFrame = Meteor.Mesh.CFrame + vector.create(0, 3, 0)

								pcall(function()
									fireproximityprompt(Prompt, 0)
								end)

								task.wait()
								Root.CFrame = oldCFrame
							else
								pcall(function()
									fireproximityprompt(Prompt, 0)
								end)
							end

							Collected[Meteor] = true
						end
					end
				end
			end

			task.wait(0.5)
		end
	end)
end

-- // Keybind Handler
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == AutoClickKey then
		AutoClickEnabled = not AutoClickEnabled
		Rayfield:Notify({
			Title = "🖱️ Auto Click",
			Content = AutoClickEnabled and "Ativado!" or "Desativado!",
			Duration = 3,
			Image = 4483362458,
		})
		if AutoClickEnabled then
			StartAutoClick()
		end
	end
end)

-- // UI Tabs
local MainTab = Window:CreateTab("General", 6022668969)
MainTab:CreateToggle({
	Name = "⭐ Speed Star",
	CurrentValue = false,
	Flag = "AutoStarFarm",
	Callback = function(Value)
		StarFarmEnabled = Value
		if Value then
			StartStarFarm()
		end
	end,
})

MainTab:CreateToggle({
	Name = "⚠️ Disable UI",
	CurrentValue = false,
	Flag = "UI",
	Callback = function(Value)
		PlayerGui.Rewards.Frame.List.Frame.Visible = not Value
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
				Image = 4483362458,
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
				Image = 4483362458,
			})
		else
			Rayfield:Notify({
				Title = "Hyoubu Hub | Aviso",
				Content = "Tecla inválida.",
				Duration = 3,
				Image = 4483362458,
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
	Range = { 1, 1000 },
	Increment = 1,
	Suffix = " FPS",
	CurrentValue = TargetFPS,
	Flag = "FPSSliderValue",
	Callback = function(Value)
		TargetFPS = math.floor(Value)
		if FPSEnabled then
			FPS()
		end
	end,
})

-- // Autos Tab
local Autos = Window:CreateTab("Autos", 6022668969)
local Trial
local Tower

Trial = Autos:CreateToggle({
	Name = "🚀 Auto Trial",
	CurrentValue = false,
	Flag = "AutoTrial",
	Callback = function(Value)
		TrialEnabled = Value
		if Value then
			Tower:Set(false)
			StartTrial()
		end
	end,
})

Autos:CreateInput({
	Name = "🚀 Sair em qual wave",
	CurrentValue = "0",
	PlaceholderText = "0 é infinito",
	Flag = "TrialInput",
	Callback = function(Text)
		local num = tonumber(Text)
		if num then
			TrialWave = num
			Rayfield:Notify({
				Title = "Hyoubu Hub",
				Content = "Wave limite do Trial: " .. (num == 0 and "infinito" or tostring(num)),
				Duration = 3,
				Image = 4483362458,
			})
		end
	end,
})

Tower = Autos:CreateToggle({
	Name = "🏰 Auto Tower",
	CurrentValue = false,
	Flag = "AutoTower",
	Callback = function(Value)
		TowerEnabled = Value
		if Value then
			Trial:Set(false)
			StartTower()
		end
	end,
})

Autos:CreateInput({
	Name = "🏰 Sair em qual wave",
	CurrentValue = "0",
	PlaceholderText = "0 é infinito",
	Flag = "TowerInput",
	Callback = function(Text)
		local num = tonumber(Text)
		if num then
			TowerWave = num
		end
	end,
})

Autos:CreateToggle({
	Name = "🌀 Auto TP",
	CurrentValue = false,
	Flag = "Auto_TP",
	Callback = function(Value)
		AutoTpEnabled = Value
		if Value then
			StartAutoTP()
		end
	end,
})

local Events = Window:CreateTab("Events", 6022668969)
Events:CreateToggle({
	Name = "🌠 Auto Collect Meteor",
	CurrentValue = false,
	Flag = "Auto_TP",
	Callback = function(Value)
		AutoCollectMeteor = Value
		StartAutoMeteor()
	end,
})

-- // Configs
local Config = Window:CreateTab("Settings", 6022668969)
Config:CreateToggle({
	Name = "😴 Auto-AFK",
	CurrentValue = false,
	Flag = "AFK",
	Callback = function(Value)
		AFKEnabled = Value
		StartAFK()
		Rayfield:Notify({
			Title = "Hyoubu Hub",
			Content = Value and "Modo AFK ativado — você não será kickado!" or "Modo AFK desativado.",
			Duration = 3,
			Image = 4483362458,
		})
	end,
})

Rayfield:Notify({
	Title = "Hyoubu Hub",
	Content = "Interface carregada com sucesso!",
	Duration = 5,
	Image = 4483362458,
})
