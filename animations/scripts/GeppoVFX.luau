--[[
    =============================================================================
    GEPPO (SKY WALK) IN-GAME WIND & SHOCKWAVE VFX HANDLER FOR ROBLOX (LUAU)
    =============================================================================
    Place inside: StarterCharacterScripts or inside a Tool / Ability script
    SFX:
      Geppo Sound : rbxassetid://96347429008558
        └─ EqualizerSoundEffect  HighGain=0  LowGain=5  MidGain=5  Priority=2
      Dash Sound  : rbxassetid://128746179989349
    VFX Model (Creator Marketplace): assetid 137725942081281
    =============================================================================
--]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local RightFoot = Character:WaitForChild("RightFoot")

local GeppoVFX = {}

-- Creates the expanding air shockwave sonic boom ring under the stomping foot
function GeppoVFX.SpawnWindShockwave(foot)
	local footPart = foot or RightFoot
	local shockwaveCFrame = footPart.CFrame * CFrame.Angles(math.rad(15), 0, 0)
	
	-- 1. Expanding Sonic Disc / Cylinder
	local ring = Instance.new("Part")
	ring.Name = "Geppo_ShockwaveRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(220, 245, 255)
	ring.Transparency = 0.35
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Size = Vector3.new(0.3, 1.5, 1.5)
	ring.CFrame = shockwaveCFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	
	-- Expand and fade out
	local targetSize = Vector3.new(0.05, 14, 14)
	local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local tween = TweenService:Create(ring, tweenInfo, {
		Size = targetSize,
		Transparency = 1
	})
	tween:Play()
	Debris:AddItem(ring, 0.3)
	
	-- 2. Wind Particle Burst
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.new(0, -0.4, 0)
	attachment.Parent = footPart
	
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "WindBurst"
	particles.Texture = "rbxassetid://243098098" -- Standard soft air smoke
	particles.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255))
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(1, 5.0)
	})
	particles.Speed = NumberRange.new(12, 28)
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Lifetime = NumberRange.new(0.15, 0.35)
	particles.Rate = 0
	particles.Parent = attachment
	
	particles:Emit(25)
	Debris:AddItem(attachment, 0.5)
	
	-- 3. Sound Effect (Geppo - rbxassetid://96347429008558)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://96347429008558"
	sound.Volume = 1.2
	sound.PlaybackSpeed = 1.1

	-- EqualizerSoundEffect: boost lows/mids for punchy anime stomp
	local eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain  = 0
	eq.LowGain   = 5
	eq.MidGain   = 5
	eq.Priority  = 2
	eq.Parent    = sound

	sound.Parent = footPart
	sound:Play()
	Debris:AddItem(sound, 1.5)
end

-- Play Geppo with sync to impact frame
function GeppoVFX.PlayGeppoWithVFX(animTrack)
	animTrack:Play(0.05, 1, 1)
	
	-- Frame 6 at 24 FPS is approx 0.25 seconds
	task.delay(0.25, function()
		GeppoVFX.SpawnWindShockwave(RightFoot)
	end)
end

return GeppoVFX
