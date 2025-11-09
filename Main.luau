-- // Inicializing
local StartTime = tick()

-- // Load Rayfield
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
local HttpService = game:GetService("HttpService") -- for webhook preview (if needed)
local Player = Players.LocalPlayer
local _PlayerGui = Player:WaitForChild("PlayerGui")
local Bridge = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bridge")

-- // Core Variables
local ClickDelay = 0.05
local TargetFPS = 30
local AutoClickKey = Enum.KeyCode.Z
local ClickYOffset = 400
local Star_World = {}
local Trait = {}
local Stats = { Attack = {}, Speed = {}, Ultimate = {} }

-- Control flags / states
local Gamemode = false
local AllowTeleport = true
local State = { Trial = false, Tower = false }

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

-- =========================
-- Loader / Debug
-- =========================

local function printColored(color, text)
	print(text)
end

function Logger:Info(text)
	printColored(self.Colors.Info, string.format("%s [INFO] %s", self.Prefix, text))
end

function Logger:Success(text)
	printColored(self.Colors.Success, string.format("%s [OK] %s", self.Prefix, text))
end

function Logger:Warn(text)
	printColored(self.Colors.Warn, string.format("%s [WARN] %s", self.Prefix, text))
end

function Logger:Error(text)
	printColored(self.Colors.Error, string.format("%s [ERROR] %s", self.Prefix, text))
end

function Logger:InitDone()
	local elapsed = tick() - StartTime
	local text = string.format("%s Initialized in %.3fs", self.Prefix, elapsed)
	printColored(self.Colors.Success, text)
end

_G.Logger = Logger

-- =========================
-- Teleport Queue / Priority
-- =========================
local TeleportQueue = {
	Queue = {},
	IsTeleporting = false,
	LastTeleportAt = 0,
	Cooldown = 0.35,
}

local PRIORITIES = {
	Event = 1, -- e.g. Meteor/Star
	Gamemode = 2, -- Trial/Tower
	Misc = 3, -- other teleports
}

function TeleportQueue:Add(cf, tag, callback)
	local priority = PRIORITIES[tag] or PRIORITIES.Misc
	if self.Queue[cf] then
		return
	end

	self.Queue[cf] = { cf = cf, tag = tag or "Misc", priority = priority, callback = callback }
	table.sort(self.Queue, function(a, b)
		if a.priority == b.priority then
			return false
		end
		return a.priority < b.priority
	end)
end

function TeleportQueue:ProcessOnce()
	if self.IsTeleporting then
		return
	end
	if #self.Queue == 0 then
		return
	end
	if not AllowTeleport then
		return
	end

	if Gamemode then
		local idx = nil
		for i, job in ipairs(self.Queue) do
			if job.priority == PRIORITIES.Gamemode then
				idx = i
				break
			end
		end
		if not idx then
			return
		end
		local job = table.remove(self.Queue, idx)
		self:ExecuteJob(job)
		return
	end

	local job = table.remove(self.Queue, 1)
	if job then
		self:ExecuteJob(job)
	end
end

function TeleportQueue:ExecuteJob(job)
	self.IsTeleporting = true
	local cf = job.cf
	local callback = job.callback

	local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		table.insert(self.Queue, job)
		self.IsTeleporting = false
		return
	end

	root.CFrame = cf

	if callback then
		pcall(callback)
	end

	self.LastTeleportAt = os.clock()
	task.wait(math.max(0.15, self.Cooldown))
	self.IsTeleporting = false
end

-- processing loop
task.spawn(function()
	while true do
		pcall(function()
			TeleportQueue:ProcessOnce()
		end)
		task.wait(0.2)
	end
end)

local function SafeTeleport(cf, tag, callback)
	if not cf then
		return false
	end
	TeleportQueue:Add(cf, tag or "Misc", callback)
	return true
end

-- =========================
-- Helpers
-- =========================
local function Notify(title, content, duration)
	Rayfield:Notify({
		Title = title or "Eclipse Hub",
		Content = content or "",
		Duration = duration or 3,
		Image = "bell-plus",
	})
end

-- =========================
-- Job Manager
-- =========================
local JobManager = {}
JobManager.ActiveJobs = {}

function JobManager:Add(name, startFn, stopFn)
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

	job.Enabled = state
	if state then
		if job.Thread then
			task.cancel(job.Thread)
		end
		job.Thread = task.spawn(job.Start)
	else
		if job.Stop then
			job.Stop()
		end
		if job.Thread then
			task.cancel(job.Thread)
		end
		job.Thread = nil
	end
end

function JobManager:IsRunning(name)
	local job = self.ActiveJobs[name]
	return job and job.Enabled
end

-- =========================
-- Jobs
-- =========================

-- Auto Star Farm
JobManager:Add("StarFarm", function()
	Notify("⭐ Auto Star", "Auto Star iniciado.")
	while JobManager:IsRunning("StarFarm") do
		local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
		local Folder = workspace:FindFirstChild("Server")
		local StarsFolder = Folder and Folder:FindFirstChild("Stars")
		if not (StarsFolder and Star_World and Root) then
			continue
		end

		local Star = StarsFolder:FindFirstChild(Star_World)
		if Star and Star:FindFirstChild("Model") then
			local Target = Star.Model:FindFirstChild("Root")
			if Target then
				if not workspace.Client.Maps:FindFirstChild(Star_World) then
					Bridge:FireServer("General", "Teleport", "Teleport", Star_World)
				end

				print("safafaw")
				Bridge:FireServer("General", "Star", "Open")
				SafeTeleport(Target.CFrame, "Misc", function() end)
			end
		end
		task.wait()
	end
end, function()
	Notify("⭐ Auto Star", "Parado.")
end)

-- Auto Click
JobManager:Add("AutoClick", function()
	Notify("🖱️ Auto Click", "Ativado")
	while JobManager:IsRunning("AutoClick") do
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
		local x = viewport.X / 2
		local y = viewport.Y / 2 + ClickYOffset
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
		task.wait(ClickDelay)
	end
end, function()
	Notify("🖱️ Auto Click", "Desativado")
end)

-- FPS Limit
local FPSConnection
JobManager:Add("FPSLimit", function()
	local TargetFrameTime = 1 / TargetFPS
	if FPSConnection then
		FPSConnection:Disconnect()
	end

	FPSConnection = RunService.RenderStepped:Connect(function()
		local t0 = tick()
		repeat
		until t0 + TargetFrameTime < tick()
	end)
end, function()
	if FPSConnection then
		FPSConnection:Disconnect()
		FPSConnection = nil
	end
end)

-- Auto AFK
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

-- Gamemodes: Trial
local TrialWave = 0
JobManager:Add("Trial", function()
	local LobbyCF = CFrame.new(-2545.5, -262.1, 1653.3)
	local TrialCF = CFrame.new(-2649.7, -260.9, 1655.4)
	local Folder = ReplicatedStorage:WaitForChild("Gamemodes"):WaitForChild("Trial")
	Notify("🚀 Auto Trial", "Iniciado")

	while JobManager:IsRunning("Trial") do
		local Opened = Folder:FindFirstChild("Open")
		local Wave = Folder:FindFirstChild("Wave")
		if not Opened or not Wave then
			task.wait(0.6)
			continue
		end

		if Opened.Value and not State.Trial then
			local cb = function()
				State.Trial = true
				Gamemode = true
				task.wait(2.5)
				pcall(function()
					Bridge:FireServer("Gamemodes", "Trial", "Start")
					Bridge:FireServer("Gamemodes", "Trial", "Join")
				end)
			end
			SafeTeleport(LobbyCF, "Gamemode", cb)
		elseif State.Trial then
			SafeTeleport(TrialCF, "Gamemode", nil)
			local maxWave = TrialWave <= 0 and math.huge or TrialWave
			if Wave.Value >= maxWave then
				pcall(function()
					Bridge:FireServer("Gamemodes", "Trial", "Leave")
				end)
				State.Trial = false
				Gamemode = false
			end
		end
		task.wait(0.5)
	end
end, function()
	State.Trial = false
	Gamemode = false
	Notify("🚀 Auto Trial", "Parado")
end)

-- Gamemodes: Tower
local TowerWave = 0
JobManager:Add("Tower", function()
	local LobbyCF = CFrame.new(-1569.89, 59.03, 1558.01)
	local TowerCF = CFrame.new(-2508.79, -347.73, 2644.37)
	local Folder = ReplicatedStorage:WaitForChild("Gamemodes"):WaitForChild("Tower")
	Notify("🏰 Auto Tower", "Iniciado")

	while JobManager:IsRunning("Tower") do
		local Opened = Folder:FindFirstChild("Open")
		local Wave = Folder:FindFirstChild("Wave")
		if not Opened or not Wave then
			task.wait(0.6)
			continue
		end

		if Opened.Value and not State.Tower then
			local cb = function()
				State.Tower = true
				Gamemode = true
				task.wait(2.5)
				pcall(function()
					Bridge:FireServer("Gamemodes", "Tower", "Start")
					Bridge:FireServer("Gamemodes", "Tower", "Join")
				end)
			end
			SafeTeleport(LobbyCF, "Gamemode", cb)
		elseif State.Tower then
			SafeTeleport(TowerCF, "Gamemode", nil)
			local maxWave = TowerWave <= 0 and math.huge or TowerWave
			if Wave.Value >= maxWave then
				pcall(function()
					Bridge:FireServer("Gamemodes", "Tower", "Leave")
				end)
				State.Tower = false
				Gamemode = false
			end
		end
		task.wait(0.5)
	end
end, function()
	State.Tower = false
	Gamemode = false
	Notify("🏰 Auto Tower", "Parado")
end)

-- Auto Meteor
JobManager:Add("AutoMeteor", function()
	local Collected = {}
	local MeteorsFolder =
		workspace:WaitForChild("Server"):WaitForChild("GameEvent"):WaitForChild("Meteors"):WaitForChild("Spawned")
	Notify("🌠 Auto Meteor", "Iniciado")

	while JobManager:IsRunning("AutoMeteor") do
		for _, Meteor in pairs(MeteorsFolder:GetChildren()) do
			if Meteor:IsA("Model") and Meteor:FindFirstChild("Mesh") then
				local Prompt = Meteor.Mesh:FindFirstChildOfClass("ProximityPrompt")
				if Prompt and not Collected[Meteor] then
					AllowTeleport = false
					local targetCf = Meteor.Mesh.CFrame + vector.create(0, 3, 0)
					local cb = function()
						task.wait(0.25)
						pcall(fireproximityprompt, Prompt)
						task.wait(0.5)
					end
					SafeTeleport(targetCf, "Event", cb)
					Collected[Meteor] = true
				end
			end
		end
		task.wait(0.6)
	end
end, function()
	AllowTeleport = true
	Notify("🌠 Auto Meteor", "Parado")
end)

-- =========================
-- UI
-- =========================

-- Gachas Tab
local GachasTab = Window:CreateTab("Gachas", "sparkles")
GachasTab:CreateSection("Star Automation")
GachasTab:CreateToggle({
	Name = "⭐ Auto Star",
	CurrentValue = false,
	Flag = "AutoStar",
	Callback = function(v)
		JobManager:Toggle("StarFarm", v)
	end,
})
GachasTab:CreateDropdown({
	Name = "🌍 Star World",
	Options = { "Leaf Village", "Dragon Town", "Slayer Village", "Pirate Island" },
	CurrentOption = {},
	MultipleOptions = false,
	Flag = "StarWorldDropdown",
	Callback = function(Options)
		Star_World = typeof(Options) == "table" and Options[1] or Options
	end,
})

GachasTab:CreateSection("Gacha Automation")
-- stats
GachasTab:CreateToggle({
	Name = "📊 Auto Stats",
	CurrentValue = false,
	Flag = "AutoStats",
	Callback = function(v)
		-- TODO: implement auto stats allocation
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
	Flag = "Trait_Damage",
	Callback = function(Value)
		Stats.Speed = Value
	end,
})
GachasTab:CreateDropdown({
	Name = "Ultimate",
	Options = { "D", "C", "B", "A", "S", "Z", "Z+" },
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "Trait_Damage",
	Callback = function(Value)
		Stats.Ultimate = Value
	end,
})

-- trait
GachasTab:CreateToggle({
	Name = "✨ Auto Trait",
	CurrentValue = false,
	Flag = "AutoTrait",
	Callback = function(v)
		-- TODO: implement auto trait reroll/select
	end,
})
GachasTab:CreateDropdown({
	Name = "Trait",
	Options = {
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
	},
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "Trait_Box",
	Callback = function(Value)
		Trait = Value
	end,
})
GachasTab:CreateToggle({
	Name = "🎯 Auto Gacha Spin",
	CurrentValue = false,
	Flag = "AutoGachaSpin",
	Callback = function(v)
		-- TODO: implement auto gacha spin
	end,
})

-- Gamemodes Tab
local GamemodesTab = Window:CreateTab("Gamemodes", "flag")
GamemodesTab:CreateSection("Auto Modes")
GamemodesTab:CreateToggle({
	Name = "🚀 Auto Trial",
	CurrentValue = false,
	Flag = "AutoTrial",
	Callback = function(v)
		JobManager:Toggle("Trial", v)
	end,
})
GamemodesTab:CreateInput({
	Name = "Wave limit (Trial)",
	PlaceholderText = "0 = infinite",
	Flag = "TrialLimit",
	Callback = function(t)
		TrialWave = tonumber(t) or 0
	end,
})
GamemodesTab:CreateToggle({
	Name = "🏯 Auto Tower",
	CurrentValue = false,
	Flag = "AutoTower",
	Callback = function(v)
		JobManager:Toggle("Tower", v)
	end,
})
GamemodesTab:CreateInput({
	Name = "Wave limit (Tower)",
	PlaceholderText = "0 = infinite",
	Flag = "TowerLimit",
	Callback = function(t)
		TowerWave = tonumber(t) or 0
	end,
})

-- Events Tab
local EventsTab = Window:CreateTab("Events", "star")
EventsTab:CreateSection("Events Automation")
EventsTab:CreateToggle({
	Name = "🌠 Auto Meteor",
	CurrentValue = false,
	Flag = "AutoMeteor",
	Callback = function(v)
		JobManager:Toggle("AutoMeteor", v)
	end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", "cog")
SettingsTab:CreateSection("Performance")
SettingsTab:CreateToggle({
	Name = "⚙️ Limit FPS",
	CurrentValue = false,
	Flag = "LimitFPS",
	Callback = function(v)
		JobManager:Toggle("FPSLimit", v)
	end,
})
SettingsTab:CreateSlider({
	Name = "🎯 Target FPS",
	Range = { 10, 240 },
	Increment = 1,
	CurrentValue = TargetFPS,
	Flag = "TargetFPS",
	Callback = function(v)
		TargetFPS = math.floor(v)
	end,
})
SettingsTab:CreateSection("Utilities")
SettingsTab:CreateToggle({
	Name = "😴 Auto-AFK",
	CurrentValue = false,
	Flag = "AutoAFK",
	Callback = function(v)
		JobManager:Toggle("AutoAFK", v)
	end,
})
SettingsTab:CreateToggle({
	Name = "🖱️ Auto Click",
	CurrentValue = false,
	Flag = "AutoClick",
	Callback = function(v)
		JobManager:Toggle("AutoClick", v)
	end,
})
SettingsTab:CreateKeybind({
	Name = "⌨️ AutoClick Key (single)",
	CurrentKeybind = "Z",
	HoldToInteract = false,
	Flag = "AutoClickKey",
	Callback = function(t)
		AutoClickKey = t
	end,
})

-- Webhook Tab
local WebhookTab = Window:CreateTab("Webhook", "rss")
WebhookTab:CreateSection("Webhook Settings")
local webhookUrl = ""
local webhookEnabled = false
local webhookOnSecret = false
local webhookOnTrialEnd = false

WebhookTab:CreateInput({
	Name = "Webhook URL",
	PlaceholderText = "https://discord.com/api/webhooks/...",
	Flag = "WebhookURL",
	Callback = function(t)
		webhookUrl = t or ""
	end,
})
WebhookTab:CreateToggle({
	Name = "Enable Webhook",
	CurrentValue = false,
	Flag = "WebhookEnable",
	Callback = function(v)
		webhookEnabled = v
	end,
})
WebhookTab:CreateToggle({
	Name = "Notify on Secret Pickup",
	CurrentValue = false,
	Flag = "WebhookSecret",
	Callback = function(v)
		webhookOnSecret = v
	end,
})
WebhookTab:CreateToggle({
	Name = "Notify on Trial End",
	CurrentValue = false,
	Flag = "WebhookTrial",
	Callback = function(v)
		webhookOnTrialEnd = v
	end,
})
WebhookTab:CreateButton({
	Name = "Send Test Webhook",
	Callback = function()
		if not webhookEnabled or webhookUrl == "" then
			Notify("Webhook", "Webhook não configurado.", 3)
			return
		end
		pcall(function()
			task.spawn(function()
				local payload = {
					username = "Eclipse Hub",
					content = ("Test webhook from %s"):format(Player.Name),
				}
				local ok, err = pcall(function() end)
			end)
		end)
		Notify("Webhook", "Teste enfileirado", 3)
	end,
})
WebhookTab:CreateParagraph({
	Title = "Uso",
	Content = "Cole sua webhook URL acima. Quando ativado, o hub pode notificar eventos (ex: secreto pego, trial finalizado).",
})

-- // HotKeys
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == AutoClickKey then
		local job = JobManager.ActiveJobs["AutoClick"]
		JobManager:Toggle("AutoClick", not (job and job.Enabled))
	end
end)

-- // Webhooks
local function TrySendWebhookOnSecret(secretName)
	if not webhookEnabled or webhookUrl == "" or not webhookOnSecret then
		return
	end
	Notify("Webhook", ("(hook) secret: %s"):format(secretName), 3)
end

local function TrySendWebhookOnTrialEnd(info)
	if not webhookEnabled or webhookUrl == "" or not webhookOnTrialEnd then
		return
	end
	Notify("Webhook", "Trial end (hook enqueued).", 3)
end

Notify("🌙 Eclipse Hub", "Interface carregada com sucesso!", 5)

Logger:InitDone()
