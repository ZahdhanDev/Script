--// EGG AUTO PICKUP - OWN GAME
--// LocalScript
--// Taruh di StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local Eggs = workspace:WaitForChild("Eggs")
local Remote = ReplicatedStorage:WaitForChild("EggSystemRemote")

local Running = false
local TargetEgg = nil

--==================================================
-- CHARACTER
--==================================================

local function Character()
	return Player.Character
end

local function Root()
	local char = Character()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function Humanoid()
	local char = Character()
	return char and char:FindFirstChildOfClass("Humanoid")
end

--==================================================
-- EGG PART
--==================================================

local function GetEggPart(egg)
	if egg:IsA("BasePart") then
		return egg
	end

	if egg:IsA("Model") then
		return egg.PrimaryPart
			or egg:FindFirstChildWhichIsA("BasePart", true)
	end
end

--==================================================
-- GET AVAILABLE EGGS
--==================================================

local function GetAvailableEggs()
	local list = {}

	for _, egg in ipairs(Eggs:GetChildren()) do
		local part = GetEggPart(egg)

		if part and not egg:GetAttribute("Taken") then
			table.insert(list, egg)
		end
	end

	return list
end

--==================================================
-- FIND NEAREST EGG
--==================================================

local function GetNearestEgg()
	local root = Root()
	if not root then return nil end

	local nearest = nil
	local shortest = math.huge

	for _, egg in ipairs(GetAvailableEggs()) do
		local part = GetEggPart(egg)

		if part then
			local distance = (root.Position - part.Position).Magnitude

			if distance < shortest then
				shortest = distance
				nearest = egg
			end
		end
	end

	return nearest
end

--==================================================
-- WALK TO EGG
--==================================================

local function WalkToEgg(egg)
	local root = Root()
	local humanoid = Humanoid()
	local part = GetEggPart(egg)

	if not root or not humanoid or not part then
		return false
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true
	})

	local success = pcall(function()
		path:ComputeAsync(
			root.Position,
			part.Position
		)
	end)

	if not success or path.Status ~= Enum.PathStatus.Success then
		humanoid:MoveTo(part.Position)
		return true
	end

	for _, waypoint in ipairs(path:GetWaypoints()) do

		if not Running then
			return false
		end

		if not egg.Parent then
			return false
		end

		if egg:GetAttribute("Taken") then
			return false
		end

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end

		humanoid:MoveTo(waypoint.Position)

		local reached = humanoid.MoveToFinished:Wait()

		if not reached then
			return false
		end
	end

	return true
end

--==================================================
-- PICKUP
--==================================================

local function PickupEgg(egg)
	local root = Root()
	local part = GetEggPart(egg)

	if not root or not part then
		return
	end

	local distance = (root.Position - part.Position).Magnitude

	if distance <= 12 then
		Remote:FireServer("Pickup", egg.Name)
	end
end

--==================================================
-- AUTO SYSTEM
--==================================================

local function Start()
	if Running then return end

	Running = true

	task.spawn(function()

		while Running do

			local egg = TargetEgg

			if not egg
				or not egg.Parent
				or egg:GetAttribute("Taken") then

				egg = GetNearestEgg()
				TargetEgg = egg
			end

			if egg then

				local part = GetEggPart(egg)
				local root = Root()

				if part and root then

					local distance =
						(root.Position - part.Position).Magnitude

					if distance > 10 then
						WalkToEgg(egg)
					end

					task.wait(0.15)

					PickupEgg(egg)

				end
			end

			task.wait(0.5)
		end

	end)
end

local function Stop()
	Running = false
	TargetEgg = nil
end

--==================================================
-- SIMPLE CONTROL UI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "EggAutoPickup"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 190, 0, 110)
Frame.Position = UDim2.new(0, 15, 0.5, -55)
Frame.Parent = Gui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🥚 EGG AUTO"
Title.TextScaled = true
Title.BackgroundTransparency = 1
Title.Parent = Frame

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(0.8, 0, 0, 40)
Toggle.Position = UDim2.new(0.1, 0, 0, 50)
Toggle.Text = "START"
Toggle.TextScaled = true
Toggle.Parent = Frame

Toggle.MouseButton1Click:Connect(function()

	if Running then
		Stop()
		Toggle.Text = "START"
	else
		Start()
		Toggle.Text = "STOP"
	end

end)

--==================================================
-- MINIMIZE
--==================================================

local Mini = Instance.new("TextButton")
Mini.Size = UDim2.new(0, 35, 0, 35)
Mini.Position = UDim2.new(0, 205, 0.5, -55)
Mini.Text = "-"
Mini.TextScaled = true
Mini.Parent = Gui

local Minimized = false

Mini.MouseButton1Click:Connect(function()

	Minimized = not Minimized

	Title.Visible = not Minimized
	Toggle.Visible = not Minimized

	if Minimized then
		Frame.Size = UDim2.new(0, 45, 0, 45)
		Mini.Text = "+"
	else
		Frame.Size = UDim2.new(0, 190, 0, 110)
		Mini.Text = "-"
	end

end)

print("[EggAutoPickup] Loaded")
