-- // Inicializing
local StartTime = tick()

-- // Load UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- // Create Window
local Window = Rayfield:CreateWindow({
	Name = "🌙 Eclipse Hub",
	LoadingTitle = "Eclipse Hub",
	LoadingSubtitle = "by Eclipse Team",
	Theme = "Serenity",
	ToggleUIKeybind = Enum.KeyCode.K,
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
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local _PlayerGui = Player:WaitForChild("PlayerGui")

-- // Events
local Bridge = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bridge")

-- // Sourcemap
-- client
local Client = workspace:WaitForChild("Client")
local Maps = Client:WaitForChild("Maps")

-- server
local Server = workspace:WaitForChild("Server")
local Fighters = Server:WaitForChild("Fighters"):WaitForChild(Player.UserId)
local Stars = Server:WaitForChild("Stars")
local GameEvent = Server:WaitForChild("GameEvent")

-- shared
local Gamemodes = ReplicatedStorage:WaitForChild("Gamemodes")
local Events_Data = ReplicatedStorage:WaitForChild("Game_Events")

-- // Core Variables
local ClickDelay = 0.05
local TargetFPS = 30
local AutoClickKey = Enum.KeyCode.Z
local ClickYOffset = 400
local Star_World = {}
local Trait = {}
local Stats = { Attack = {}, Speed = {}, Ultimate = {} }
local TowerWave = math.huge
local TrialWave = math.huge

-- // Shareds
local Worlds = { "Leaf Village", "Dragon Town", "Slayer Village", "Pirate Island" }
local Traits = {
	"Fortune",
	"Vigor",
	"Swift",
	"Vigor II",
	"Swift II",
	"Fortune II",
	"Swift III",
	"Clover I",
	"Fortune III",
	"Vigor III",
	"Clover II",
	"Scholar",
	"Strongest",
	"Clover III",
	"Monarch",
}
local Gachas = { "Clans", "Races", "Breathings", "Haki" }

-- Control flags / states
local Gamemode = false
local AllowTeleport = true
local State = { Trial = nil, Tower = nil }

local function RGB(r, g, b)
	return string.format("@@%02x%02x%02x", r, g, b)
end

local Logger = {}

Logger.Prefix = "[🌙 Eclipse Hub]"
Logger.Colors = {
	Prefix = RGB(155, 120, 255),
	Info = RGB(180, 180, 180),
	Warn = RGB(255, 215, 100),
	Error = RGB(255, 80, 80),
	Success = RGB(120, 255, 120),
	Reset = "@@ffffff",
}

-- // Helpers
local function Notify(title, content, duration)
	Rayfield:Notify({
		Title = title or "Eclipse Hub",
		Content = content or "",
		Duration = duration or 3,
		Image = "bell-plus",
	})
end

local function Anchor(Toggle: boolean)
	local Root: BasePart = Player.Character:FindFirstChild("HumanoidRootPart")
	if Root then
		Root.Anchored = Toggle
	end
end

-- // Loader System
local function printColored(color, text)
	print(text)
end

function Logger:InitDone()
	local elapsed = tick() - StartTime
	local text = string.format("%s Initialized in %.3fs", self.Prefix, elapsed)
	printColored(self.Colors.Success, text)
end

_G.Logger = Logger

-- // Teleport System
local PRIORITIES = {
	Event = 3, -- Meteor/Star
	Gamemode = 2, -- Trial/Tower
	Star = 1.2, -- Star
	Misc = 1, -- Outros teleportes
	Default = 0,
}
local TeleportManager = {
	Priority = 0,
	CFrame = nil,
}

local function GetPriority()
	return TeleportManager.Priority
end

local function GetCFrame()
	return TeleportManager.CFrame
end

local function SetPriority(priority: string)
	TeleportManager.Priority = PRIORITIES[priority]
end

function TeleportManager:Teleport(cframe: CFrame, priority: string)
	if PRIORITIES[priority] < GetPriority() then
		return false
	end

	local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not Root then
		return false
	end

	TeleportManager.Priority = PRIORITIES[priority]
	TeleportManager.CFrame = cframe
	Root.CFrame = cframe

	return true
end

-- // Jobmanager
local JobManager = {}
JobManager.ActiveJobs = {}

function JobManager:Add(name, startFn, stopFn)
	if not name or not startFn then
		error("JobManager:Add requires a name and start function")
	end

	self.ActiveJobs[name] = {
		Enabled = false,
		Start = startFn,
		Stop = stopFn,
		Thread = nil,
	}
end

function JobManager:Toggle(name, state)
	local job = self.ActiveJobs[name]
	if not job then
		return
	end

	if state then
		if job.Thread then
			task.cancel(job.Thread)
		end

		job.Enabled = true
		job.Thread = task.spawn(function()
			pcall(job.Start)
		end)
	else
		-- desativando
		job.Enabled = false
		if job.Stop then
			pcall(job.Stop)
		end

		if job.Thread then
			task.cancel(job.Thread)
			job.Thread = nil
		end
	end
end

function JobManager:IsRunning(name)
	local job = self.ActiveJobs[name]
	return job and job.Enabled == true
end

function JobManager:StopAll()
	for name, job in pairs(self.ActiveJobs) do
		if job.Enabled then
			self:Toggle(name, false)
		end
	end
end

-- // Jobs Functions

-- GameEvent's
JobManager:Add("AutoMeteor", function()
	Notify("🌠 Auto Meteors", "Auto Meteors Ativado")

	local Meteors_Folder = GameEvent:FindFirstChild("Meteors")
	local Meteors = Events_Data:FindFirstChild("Meteors")

	while JobManager:IsRunning("AutoMeteor") do
		task.wait(1)

		if Meteors.Duration.Value <= 0 then
			continue
		end

		if #Meteors_Folder.Spawned:GetChildren() > 0 then
			Anchor(true)
		else
			Anchor(false)
		end

		for _, Meteor in pairs(Meteors_Folder.Spawned:GetChildren()) do
			if Meteor:IsA("Model") then
				TeleportManager:Teleport(Meteor.Mesh.CFrame, "Event")
				fireproximityprompt(Meteor.Mesh.Prompt)
			end
		end
	end
end, function()
	Notify("🌠 Auto Meteors", "Auto Meteors Desativado")
end)

-- Gamemodes
local GameType = "Trial"
JobManager:Add(GameType, function()
	local Join = CFrame.new(-2549.14233, -256.054443, 1653.51746, 0, 0, 1, 1, 0, 0, 0, 1, 0)
	local Room = CFrame.new(
		-2648.68481,
		-260.956879,
		1653.47253,
		-0.968454599,
		-7.60974643e-08,
		-0.249189988,
		-6.76825351e-08,
		1,
		-4.2337156e-08,
		0.249189988,
		-2.41358027e-08,
		-0.968454599
	)

	Notify("🚀 Auto Trial", "Auto Trial Ativado")
	while JobManager:IsRunning(GameType) do
		task.wait()
		if State[GameType] == "Room" then
			continue
		end

		local GameFolder = Gamemodes:FindFirstChild(GameType)
		if not GameFolder.Open.Value then
			continue
		end

		local Root: BasePart = Player.Character:FindFirstChild("HumanoidRootPart")
		if not Root then
			continue
		end

		if State[GameType] == nil then
			State[GameType] = "Joining"

			Anchor(true)
			TeleportManager:Teleport(Join, "Gamemode")
			task.wait(0.5)
			Bridge:FireServer("Gamemodes", "Trial", "Join")
		end

		if State[GameType] == "Joining" then
			State[GameType] = "Room"

			TeleportManager:Teleport(Room, "Gamemode")

			while JobManager:IsRunning(GameType) do
				task.wait(0.5)
				if GameFolder.Wave.Value >= TrialWave or GameFolder.Timer.Value <= 0 then
					Anchor(false)
					Bridge:FireServer("Gamemodes", "Trial", "Leave")
					State[GameType] = nil
					break
				end
			end
		end
	end
end, function()
	Notify("🚀 Auto Trial", "Auto Trial Desativado")
	Anchor(false)
	SetPriority("Default")
	State[GameType] = nil
end)

GameType = "Tower"
JobManager:Add(GameType, function()
	local Join = CFrame.new(-1569.89355, 59.0314331, 1558.01697, 0, 0, 1, 1, 0, 0, 0, 1, 0)
	local Room = CFrame.new(
		-2509.08838,
		-347.733246,
		2645.0498,
		-0.824129641,
		-4.10594154e-08,
		-0.566401184,
		-2.23142855e-08,
		1,
		-4.0023842e-08,
		0.566401184,
		-2.03459987e-08,
		-0.824129641
	)

	Notify("🏰 Auto Tower", "Auto Tower Ativado")
	while JobManager:IsRunning(GameType) do
		task.wait()
		if State[GameType] == "Room" then
			continue
		end

		local GameFolder = Gamemodes:FindFirstChild(GameType)

		local Root: BasePart = Player.Character:FindFirstChild("HumanoidRootPart")
		if not Root then
			continue
		end

		if State[GameType] == nil then
			State[GameType] = "Joining"

			Anchor(true)
			TeleportManager:Teleport(Join, "Gamemode")
			task.wait(0.5)
			Bridge:FireServer("Gamemodes", "Tower", "Start")
			Bridge:FireServer("Gamemodes", "Tower", "Join")
		end

		if State[GameType] == "Joining" then
			State[GameType] = "Room"

			TeleportManager:Teleport(Room, "Gamemode")

			while JobManager:IsRunning(GameType) do
				task.wait(0.5)
				if (Root.Position - Room.Position).Magnitude > 10 then
					local _: boolean = TeleportManager:Teleport(Room, "Gamemode")
				end

				if GameFolder.Wave.Value >= TowerWave or GameFolder.Timer.Value <= 0 then
					Anchor(false)
					Bridge:FireServer("Gamemodes", "Tower", "Leave")
					State[GameType] = nil
					break
				end
			end
		end
	end
end, function()
	Notify("🏰 Auto Tower", "Auto Tower Desativado")
	Anchor(false)
	SetPriority("Default")
	State[GameType] = nil
end)

-- Star Automation
JobManager:Add("StarFarm", function()
	Notify("⭐ Auto Star", "Auto Star iniciado")
	while JobManager:IsRunning("StarFarm") do
		task.wait(0.1)
		local Root: BasePart = Player.Character:FindFirstChild("HumanoidRootPart")
		if not Root then
			continue
		end

		local Star = Stars:FindFirstChild(Star_World)
		if not Star then
			continue
		end

		if not Maps:FindFirstChild(Star_World) then
			Bridge:FireServer("General", "Teleport", "Teleport", Star_World)
			continue
		end

		if (Root.Position - Star.PrimaryPart.Position).Magnitude > 10 then
			local _: boolean = TeleportManager:Teleport(Star.PrimaryPart.CFrame, "Star")
		end

		Bridge:FireServer("General", "Star", "Open")
	end
end, function()
	Notify("⭐ Auto Star", "Desativado")
	SetPriority("Default")
end)

-- Settings
local AFKConnection
JobManager:Add("AutoAFK", function()
	if AFKConnection then
		AFKConnection:Disconnect()
	end
	AFKConnection = Player.Idled:Connect(function()
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end)
	Notify("😴 Auto-AFK", "Modo AFK ativado")
end, function()
	if AFKConnection then
		AFKConnection:Disconnect()
	end
	Notify("😴 Auto-AFK", "Desativado")
end)

-- Utilities
JobManager:Add("AutoClick", function()
	Notify("🖱️ Auto Click", "Ativado")

	task.spawn(function()
		while JobManager:IsRunning("AutoClick") do
			local mousePos = UserInputService:GetMouseLocation()
			local x, y = mousePos.X, mousePos.Y

			VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)

			task.wait(ClickDelay)
		end
	end)
end, function()
	Notify("🖱️ Auto Click", "Desativado")
end)

-- // Tabs
local GachasTab = Window:CreateTab("Gachas", "sparkles")
local GamemodesTab = Window:CreateTab("Gamemodes", "flag")
local EventsTab = Window:CreateTab("Events", "star")
local SettingsTab = Window:CreateTab("Settings", "cog")
local _WebhookTab = Window:CreateTab("Webhook", "rss")

-- // Gachas Tab
GachasTab:CreateSection("Star Automation")
GachasTab:CreateToggle({
	Name = "⭐ Auto Star",
	CurrentValue = false,
	Flag = "AutoStar",
	Callback = function(Value)
		JobManager:Toggle("StarFarm", Value)
	end,
})
GachasTab:CreateDropdown({
	Name = "🌍 Star World",
	Options = Worlds,
	CurrentOption = {},
	MultipleOptions = false,
	Flag = "StarWorldDropdown",
	Callback = function(Options)
		Star_World = typeof(Options) == "table" and Options[1] or Options
	end,
})
GachasTab:CreateToggle({
	Name = "⚡ Disable UI",
	CurrentValue = false,
	Flag = "Disable_Star",
	Callback = function(Value)
		_PlayerGui.Rewards.Frame.Visible = Value
	end,
})

-- Stats
GachasTab:CreateSection("Gacha Automation")
GachasTab:CreateToggle({
	Name = "📊 Auto Stats",
	CurrentValue = false,
	Flag = "AutoStats",
	Callback = function(Value)
		-- Ainda sendo feito.
	end,
})
GachasTab:CreateDropdown({
	Name = "Attack",
	Options = { "D", "C", "B", "A", "S", "Z", "Z+" },
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "Trait_Damage",
	Callback = function(Value)
		Stats.Attack = Value
	end,
})
GachasTab:CreateDropdown({
	Name = "Speed Attack",
	Options = { "D", "C", "B", "A", "S", "Z", "Z+" },
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "Trait_Speed",
	Callback = function(Value)
		Stats.Speed = Value
	end,
})
GachasTab:CreateDropdown({
	Name = "Ultimate",
	Options = { "D", "C", "B", "A", "S", "Z", "Z+" },
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "Trait_Ultimate",
	Callback = function(Value)
		Stats.Ultimate = Value
	end,
})

-- Traits
GachasTab:CreateToggle({
	Name = "✨ Auto Trait",
	CurrentValue = false,
	Flag = "AutoTrait",
	Callback = function(Value) end,
})
GachasTab:CreateDropdown({
	Name = "Trait",
	Options = Traits,
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "Trait_Box",
	Callback = function(Value)
		Trait = Value
	end,
})

-- Gacha Items
GachasTab:CreateToggle({
	Name = "🎯 Auto Gacha Spin",
	CurrentValue = false,
	Flag = "AutoGachaSpin",
	Callback = function(Value) end,
})
GachasTab:CreateDropdown({
	Name = "Gachas",
	Options = Gachas,
	CurrentOption = {},
	MultipleOptions = false,
	Flag = "Gachas_Box",
	Callback = function(Value)
		Trait = Value
	end,
})

-- // Gamemodes Tab
GamemodesTab:CreateSection("Auto Modes")

-- Trial
GamemodesTab:CreateToggle({
	Name = "🚀 Auto Trial",
	CurrentValue = false,
	Flag = "AutoTrial",
	Callback = function(Value)
		JobManager:Toggle("Trial", Value)
	end,
})
GamemodesTab:CreateInput({
	Name = "Wave limit (Trial)",
	PlaceholderText = "0 = infinite",
	Flag = "TrialLimit",
	Callback = function(Value)
		local num = tonumber(Value) or 0
		TrialWave = (num <= 0 and math.huge or num)
	end,
})

-- Tower
GamemodesTab:CreateToggle({
	Name = "🏯 Auto Tower",
	CurrentValue = false,
	Flag = "AutoTower",
	Callback = function(Value)
		JobManager:Toggle("Tower", Value)
	end,
})
GamemodesTab:CreateInput({
	Name = "Wave limit (Tower)",
	PlaceholderText = "0 = infinite",
	Flag = "TowerLimit",
	Callback = function(Value)
		local num = tonumber(Value) or 0
		TowerWave = (num <= 0 and math.huge or num)
	end,
})

-- // Events Tab
EventsTab:CreateSection("Events Automation")
EventsTab:CreateToggle({
	Name = "🌠 Auto Meteor",
	CurrentValue = false,
	Flag = "AutoMeteor",
	Callback = function(Value)
		JobManager:Toggle("AutoMeteor", Value)
	end,
})

-- // Settings
SettingsTab:CreateSection("Performance")
SettingsTab:CreateToggle({
	Name = "⚙️ Limit FPS",
	CurrentValue = false,
	Flag = "LimitFPS",
	Callback = function(Value)
		JobManager:Toggle("FPSLimit", Value)
	end,
})
SettingsTab:CreateSlider({
	Name = "🎯 Target FPS",
	Range = { 10, 240 },
	Increment = 1,
	CurrentValue = TargetFPS,
	Flag = "TargetFPS",
	Callback = function(Value)
		TargetFPS = math.floor(Value)
	end,
})

SettingsTab:CreateSection("Utilities")
SettingsTab:CreateToggle({
	Name = "😴 Auto-AFK",
	CurrentValue = false,
	Flag = "AutoAFK",
	Callback = function(Value)
		JobManager:Toggle("AutoAFK", Value)
	end,
})
SettingsTab:CreateKeybind({
	Name = "⌨️ AutoClick Key (single)",
	CurrentKeybind = "Z",
	HoldToInteract = false,
	Flag = "AutoClickKey",
	Callback = function(Value)
		AutoClickKey = Value
	end,
})

-- Connections KeyBinds
local AutoClick_Enabled = false

UserInputService.InputBegan:Connect(function(input, GPE)
	if GPE then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == AutoClickKey then
			AutoClick_Enabled = not AutoClick_Enabled
			JobManager:Toggle("AutoClick", AutoClick_Enabled)
			print("Toggled AutoClick:", AutoClick_Enabled)
		end
	end
end)

-- INITED ECLIPSE HUD
Logger:InitDone()
