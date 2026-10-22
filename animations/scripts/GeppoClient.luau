--[[
    =============================================================================
    GEPPO (SKY WALK) MID-AIR DOUBLE-JUMP CONTROLLER
    =============================================================================
    - Trigger: Press Spacebar while mid-air (Double-Space)
    - Kinematics: Upward + Forward directional momentum thrust
    - VFX: Multi-layered sonic boom air shockwave, wind burst particles & whoosh
    - Procedural Body Recoil: Dynamic anime stomp pose on R15 joints
    =============================================================================
--]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local rightFoot = character:WaitForChild("RightFoot")

-- R15 Joints for procedural animation recoil
local lowerTorso = character:WaitForChild("LowerTorso")
local upperTorso = character:WaitForChild("UpperTorso")
local head = character:WaitForChild("Head")

local waist = upperTorso:FindFirstChild("Waist")
local neck = head:FindFirstChild("Neck")
local rightHip = rightFoot.Parent:FindFirstChild("RightUpperLeg") and rightFoot.Parent.RightUpperLeg:FindFirstChild("RightHip")

-- Config
local MAX_JUMPS = 5
local COOLDOWN = 0.22
local JUMP_POWER_Y = 56
local JUMP_POWER_XZ = 40

local airJumpsLeft = MAX_JUMPS
local lastJumpTime = 0
local isMidAir = false

-- Reset air jumps on landing
humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
		airJumpsLeft = MAX_JUMPS
		isMidAir = false
	elseif newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
		isMidAir = true
	end
end)

-- Sonic Boom Shockwave VFX
local function spawnGeppoVFX()
	local footCF = rightFoot.CFrame
	
	-- 1. Expanding Sonic Disc
	local shockwave = Instance.new("Part")
	shockwave.Name = "Geppo_ShockwaveRing"
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = Color3.fromRGB(210, 245, 255)
	shockwave.Transparency = 0.3
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.CanQuery = false
	shockwave.CanTouch = false
	shockwave.Size = Vector3.new(0.3, 2, 2)
	-- Orient horizontally under foot
	shockwave.CFrame = (footCF * CFrame.new(0, -0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	shockwave.Parent = workspace
	
	local tween = TweenService:Create(shockwave, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.05, 16, 16),
		Transparency = 1
	})
	tween:Play()
	Debris:AddItem(shockwave, 0.3)
	
	-- 2. Wind Particle Burst
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.new(0, -0.5, 0)
	attachment.Parent = rightFoot
	
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "Geppo_WindBurst"
	particles.Texture = "rbxassetid://243098098"
	particles.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255))
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 5.5)
	})
	particles.Speed = NumberRange.new(15, 30)
	particles.SpreadAngle = Vector2.new(60, 60)
	particles.Lifetime = NumberRange.new(0.2, 0.35)
	particles.Rate = 0
	particles.Parent = attachment
	
	particles:Emit(30)
	Debris:AddItem(attachment, 0.5)
	
	-- 3. Sound Effect
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9114223175" -- Punchy anime air pop
	sound.Volume = 1.3
	sound.PlaybackSpeed = 1.15
	sound.Parent = rightFoot
	sound:Play()
	Debris:AddItem(sound, 1.2)
end

-- Procedural Anime Recoil (Stomp Down, Chest Crunch, Head Look Up)
local function triggerProceduralRecoil()
	if waist then
		local origC0 = waist.C0
		-- Crunch forward heavily on Frame 6
		local tweenCrunch = TweenService:Create(waist, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = origC0 * CFrame.Angles(math.rad(35), 0, 0)
		})
		tweenCrunch:Play()
		
		-- Recover smoothly
		task.delay(0.12, function()
			local tweenRecover = TweenService:Create(waist, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				C0 = origC0
			})
			tweenRecover:Play()
		end)
	end
	
	if neck then
		local origNeck = neck.C0
		-- Head snaps UP looking at destination
		local tweenHead = TweenService:Create(neck, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = origNeck * CFrame.Angles(math.rad(-30), 0, 0)
		})
		tweenHead:Play()
		
		task.delay(0.12, function()
			local tweenRecover = TweenService:Create(neck, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				C0 = origNeck
			})
			tweenRecover:Play()
		end)
	end
end

-- Execute Geppo
local function performGeppo()
	if not isMidAir or airJumpsLeft <= 0 then return end
	local now = tick()
	if now - lastJumpTime < COOLDOWN then return end
	
	lastJumpTime = now
	airJumpsLeft = airJumpsLeft - 1
	
	-- 1. Kinetic Momentum (Upward + Move Direction)
	local moveDir = humanoid.MoveDirection
	local velX = moveDir.X * JUMP_POWER_XZ
	local velZ = moveDir.Z * JUMP_POWER_XZ
	rootPart.AssemblyLinearVelocity = Vector3.new(velX, JUMP_POWER_Y, velZ)
	
	-- 2. Visual Effects & Audio
	spawnGeppoVFX()
	
	-- 3. Anime Recoil
	triggerProceduralRecoil()
	
	print("[Geppo] Air Jump executed! Jumps remaining: " .. airJumpsLeft)
end

-- Input Listeners (Spacebar)
UserInputService.JumpRequest:Connect(function()
	if isMidAir then
		performGeppo()
	end
end)

print("[Geppo Controller] Initialized successfully. Double-space mid-air to Sky Walk!")
