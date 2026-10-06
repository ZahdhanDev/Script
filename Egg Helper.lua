-- EggHelper.lua
-- Untuk game milik sendiri

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

local RARITY_RANK = {
	COMMON = 1,
	UNCOMMON = 2,
	RARE = 3,
	EPIC = 4,
	LEGENDARY = 5,
	MYTHIC = 6,
	COSMIC = 7,
	SECRET = 8,
	ETERNAL = 9,
	DIVINE = 10
}

local AUTO_EGG = true
local SCAN_DELAY = 2

-- =========================
-- ANTI AFK
-- =========================

player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

-- =========================
-- AMBIL DATA EGG
-- =========================

local function readEgg(egg)
	local rarity = egg:GetAttribute("Rarity")
	local animal = egg:GetAttribute("Animal")
	local income = egg:GetAttribute("IncomePerSecond")
	local weight = egg:GetAttribute("Weight")
	local mutation = egg:GetAttribute("Mutation")

	return {
		rarity = string.upper(tostring(rarity or "UNKNOWN")),
		animal = tostring(animal or "UNKNOWN"),
		income = tonumber(income) or 0,
		weight = tonumber(weight) or 0,
		mutation = tostring(mutation or "None")
	}
end

-- =========================
-- CARI EGG TERBAIK
-- =========================

local function getBestEgg()
	local eggs = workspace:FindFirstChild("Eggs")
	if not eggs then
		return nil
	end

	local bestEgg = nil
	local bestData = nil
	local bestRank = -1

	for _, egg in ipairs(eggs:GetChildren()) do
		local data = readEgg(egg)
		local rank = RARITY_RANK[data.rarity] or 0

		-- Prioritas:
		-- 1. Rarity
		-- 2. Income
		-- 3. Weight
		if rank > bestRank
			or (rank == bestRank and bestData and data.income > bestData.income)
			or (rank == bestRank and bestData
				and data.income == bestData.income
				and data.weight > bestData.weight) then

			bestEgg = egg
			bestData = data
			bestRank = rank
		end
	end

	return bestEgg, bestData
end

-- =========================
-- POSISI OBJECT
-- =========================

local function getPosition(object)
	if object:IsA("BasePart") then
		return object.Position
	end

	if object:IsA("Model") then
		if object.PrimaryPart then
			return object.PrimaryPart.Position
		end

		local part = object:FindFirstChildWhichIsA("BasePart")
		if part then
			return part.Position
		end
	end

	return nil
end

-- =========================
-- PATHFINDING
-- =========================

local function moveToEgg(egg)
	local character = player.Character
	if not character then return end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return
	end

	local target = getPosition(egg)
	if not target then return end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true
	})

	local success = pcall(function()
		path:ComputeAsync(root.Position, target)
	end)

	if not success or path.Status ~= Enum.PathStatus.Success then
		return
	end

	for _, waypoint in ipairs(path:GetWaypoints()) do
		if not AUTO_EGG then
			break
		end

		if waypoint.Action ==
			Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end

		humanoid:MoveTo(waypoint.Position)

		local reached =
			humanoid.MoveToFinished:Wait()

		if not reached then
			break
		end
	end
end

-- =========================
-- GUI
-- =========================

local gui = Instance.new("ScreenGui")
gui.Name = "EggHelper"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("TextLabel")
panel.Size = UDim2.new(0, 310, 0, 170)
panel.Position = UDim2.new(0.5, -155, 0, 20)
panel.BackgroundTransparency = 0.1
panel.TextSize = 17
panel.TextWrapped = true
panel.Text = "Scanning Egg..."
panel.Parent = gui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 45)
button.Position = UDim2.new(0.5, -100, 0, 205)
button.TextSize = 18
button.Text = "AUTO EGG: ON"
button.Parent = gui

button.MouseButton1Click:Connect(function()
	AUTO_EGG = not AUTO_EGG

	if AUTO_EGG then
		button.Text = "AUTO EGG: ON"
	else
		button.Text = "AUTO EGG: OFF"
	end
end)

-- =========================
-- LIVE SCANNER
-- =========================

task.spawn(function()
	while true do
		local egg, data = getBestEgg()

		if egg and data then
			panel.Text =
				"🥚 BEST EGG\n" ..
				"Name: " .. egg.Name .. "\n" ..
				"Rarity: " .. data.rarity .. "\n" ..
				"Animal: " .. data.animal .. "\n" ..
				"Income: $" ..
				tostring(data.income) .. "/s\n" ..
				"Weight: " ..
				tostring(data.weight) .. "\n" ..
				"Mutation: " ..
				data.mutation

			if AUTO_EGG then
				task.spawn(function()
					moveToEgg(egg)
				end)
			end
		else
			panel.Text =
				"🥚 Tidak ada Egg\n" ..
				"Pastikan Workspace.Eggs tersedia."
		end

		task.wait(SCAN_DELAY)
	end
end)
