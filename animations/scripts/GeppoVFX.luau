--[[
    =============================================================================
    GEPPO VFX MODULE — CINEMATIC ANIME EDITION  v3.0
    =============================================================================
    Módulo reutilizável para VFX do Geppo.
    Pode ser chamado por qualquer script de habilidade/ability:
        local GeppoVFX = require(path.to.GeppoVFX)
        GeppoVFX.Fire(character, rightFoot)

    ─────────────────────────────────────────────────────────────────────────────
    Técnicas do Twist VFX ("How to Make Slash VFX | Roblox Studio") aplicadas:
      • LightEmission  = 1         → remove bordas pretas de texturas transparentes
      • Speed=0.01+VelocityPerp    → partículas congelam no ar (fragmentos)
      • Speed alto + Drag alto     → explosão violenta que cessa instantaneamente
      • VelocityParallel           → partículas se esticam na direção (linhas de vento)
      • EasingStyle.Circular       → Highlight pulsa como senoide, não troca de cor dura
      • RotSpeed 400-500           → giro visível em partículas de Lifetime curto
      • ZOffset                    → controla Z-sorting entre camadas de partículas
    ─────────────────────────────────────────────────────────────────────────────
    SFX:
      Geppo Sound : rbxassetid://96347429008558
        └─ EqualizerSoundEffect  HighGain=0  LowGain=5  MidGain=5  Priority=2
    =============================================================================
--]]

local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")

local GeppoVFX = {}

-- ── Textura ────────────────────────────────────────────────────────────────────
local SPARK_TEXTURE = "rbxassetid://296874871"

-- =============================================================================
-- HELPER: cria CFrame com eixo Z apontando para `dir`
-- =============================================================================
local function makeSpikeCFrame(origin, dir, halfLen)
	local yaw   = math.atan2(dir.X, dir.Z)
	local pitch = math.asin(math.clamp(dir.Y, -1, 1))
	return CFrame.new(origin + dir * halfLen)
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(pitch, 0, 0)
end

local function shootSpike(origin, dir, thick, startLen, endLen, duration, startTransp)
	startTransp = startTransp or 0
	local halfStart = startLen / 2
	local halfEnd   = endLen   / 2
	local startCF   = makeSpikeCFrame(origin, dir, halfStart)
	local endCF     = makeSpikeCFrame(origin, dir, halfEnd)

	local spike = Instance.new("Part")
	spike.Material     = Enum.Material.Neon
	spike.Color        = Color3.fromRGB(255, 255, 255)
	spike.Transparency = startTransp
	spike.Anchored     = true
	spike.CanCollide   = false
	spike.CanQuery     = false
	spike.CanTouch     = false
	spike.CastShadow   = false
	spike.Size         = Vector3.new(thick, thick, startLen)
	spike.CFrame       = startCF
	spike.Parent       = workspace

	TweenService:Create(spike,
		TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			Size   = Vector3.new(0.035, 0.035, endLen),
			CFrame = endCF,
			Transparency = 1,
		}
	):Play()
	Debris:AddItem(spike, duration + 0.04)
end

-- =============================================================================
-- STARBURST: núcleo flash branco opaco + 8 spikes + 4 diagonais + sparks
-- =============================================================================
function GeppoVFX.SpawnStarburst(footPart, pos)
	pos = pos or (footPart.Position + Vector3.new(0, -0.3, 0))

	-- Esfera-núcleo (flash branco que expande e desaparece)
	local core = Instance.new("Part")
	core.Shape        = Enum.PartType.Ball
	core.Material     = Enum.Material.Neon
	core.Color        = Color3.fromRGB(255, 255, 255)
	core.Transparency = 0
	core.Anchored     = true
	core.CanCollide   = false
	core.CanQuery     = false
	core.CanTouch     = false
	core.CastShadow   = false
	core.Size         = Vector3.new(2.2, 2.2, 2.2)
	core.CFrame       = CFrame.new(pos)
	core.Parent       = workspace
	TweenService:Create(core,
		TweenInfo.new(0.13, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = Vector3.new(5, 5, 5), Transparency = 1 }
	):Play()
	Debris:AddItem(core, 0.17)

	-- 8 spikes horizontais (estrela plana)
	for i = 0, 7 do
		local rad = math.rad(i * 45)
		local dir = Vector3.new(math.cos(rad), 0, math.sin(rad))
		shootSpike(pos, dir, 0.36, 1.2, 10.5, 0.20)
	end

	-- 4 spikes diagonais para cima (~45°)
	for i = 0, 3 do
		local rad = math.rad(i * 90 + 45)
		local horiz = Vector3.new(math.cos(rad), 0, math.sin(rad))
		local dir   = (horiz + Vector3.new(0, 0.95, 0)).Unit
		shootSpike(pos, dir, 0.26, 1.0, 6.5, 0.22, 0.05)
	end

	-- Twist VFX: partículas congeladas (fragmentos de ar partido)
	local att = Instance.new("Attachment")
	att.Parent = footPart

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture        = SPARK_TEXTURE
	sparks.LightEmission  = 1
	sparks.LightInfluence = 0
	sparks.Color          = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	sparks.Transparency   = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0),
		NumberSequenceKeypoint.new(0.4, 0.1),
		NumberSequenceKeypoint.new(1,   1),
	})
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.6),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	sparks.Speed       = NumberRange.new(0.01, 0.01)
	sparks.Orientation = Enum.ParticleEmitterOrientation.VelocityPerpendicular
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Lifetime    = NumberRange.new(0.14, 0.22)
	sparks.Rotation    = NumberRange.new(0, 360)
	sparks.RotSpeed    = NumberRange.new(400, 500)
	sparks.Rate        = 0
	sparks.ZOffset     = 0.5
	sparks.Parent      = att

	sparks:Emit(16)
	Debris:AddItem(att, 0.3)
end

-- =============================================================================
-- WIND STREAKS: rajadas verticais (Speed=75 + Drag=7)
-- =============================================================================
function GeppoVFX.SpawnWindStreaks(footPart)
	local att = Instance.new("Attachment")
	att.Parent = footPart

	local streaks = Instance.new("ParticleEmitter")
	streaks.Texture        = SPARK_TEXTURE
	streaks.LightEmission  = 1
	streaks.LightInfluence = 0
	streaks.Color          = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	streaks.Transparency   = NumberSequence.new({
		NumberSequenceKeypoint.new(0,    0),
		NumberSequenceKeypoint.new(0.3,  0),
		NumberSequenceKeypoint.new(1,    1),
	})
	streaks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.22),
		NumberSequenceKeypoint.new(0.4, 0.14),
		NumberSequenceKeypoint.new(1,   0),
	})
	streaks.Speed        = NumberRange.new(60, 80)
	streaks.Drag         = 7
	streaks.Acceleration = Vector3.new(0, -8, 0)
	streaks.SpreadAngle  = Vector2.new(14, 14)
	streaks.Lifetime     = NumberRange.new(0.30, 0.50)
	streaks.Orientation  = Enum.ParticleEmitterOrientation.VelocityParallel
	streaks.Rate         = 0
	streaks.Rotation     = NumberRange.new(-15, 15)
	streaks.ZOffset      = 1
	streaks.Parent       = att

	streaks:Emit(22)
	Debris:AddItem(att, 0.6)
end

-- =============================================================================
-- SHOCKWAVE RINGS: 3 anéis de choque escalonados
-- =============================================================================
function GeppoVFX.SpawnShockwaveRings(pos)
	local ringConfigs = {
		{ delay = 0.00, startD = 1.8, endD = 18, dur = 0.50, startT = 0.10 },
		{ delay = 0.08, startD = 1.4, endD = 22, dur = 0.65, startT = 0.20 },
		{ delay = 0.16, startD = 1.0, endD = 27, dur = 0.80, startT = 0.30 },
	}
	for _, r in ipairs(ringConfigs) do
		task.delay(r.delay, function()
			local ring = Instance.new("Part")
			ring.Shape        = Enum.PartType.Cylinder
			ring.Material     = Enum.Material.Neon
			ring.Color        = Color3.fromRGB(255, 255, 255)
			ring.Transparency = r.startT
			ring.Anchored     = true
			ring.CanCollide   = false
			ring.CanQuery     = false
			ring.CanTouch     = false
			ring.CastShadow   = false
			ring.Size         = Vector3.new(0.24, r.startD, r.startD)
			ring.CFrame       = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent       = workspace
			TweenService:Create(ring,
				TweenInfo.new(r.dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Size = Vector3.new(0.032, r.endD, r.endD), Transparency = 1 }
			):Play()
			Debris:AddItem(ring, r.dur + 0.04)
		end)
	end
end

-- =============================================================================
-- HIGHLIGHT PULSE: brilho senoidal no personagem (Circular easing)
-- =============================================================================
function GeppoVFX.SpawnHighlight(character)
	local hl = Instance.new("Highlight")
	hl.FillColor           = Color3.fromRGB(220, 240, 255)
	hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency    = 1
	hl.OutlineTransparency = 1
	hl.Parent              = character

	TweenService:Create(hl,
		TweenInfo.new(0.07, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
		{ FillTransparency = 0.35, OutlineTransparency = 0.15 }
	):Play()
	task.delay(0.07, function()
		TweenService:Create(hl,
			TweenInfo.new(0.28, Enum.EasingStyle.Circular, Enum.EasingDirection.In),
			{ FillTransparency = 1, OutlineTransparency = 1 }
		):Play()
		Debris:AddItem(hl, 0.38)
	end)
end

-- =============================================================================
-- SFX: som do Geppo com EqualizerSoundEffect
-- =============================================================================
function GeppoVFX.PlaySound(parent)
	local sound         = Instance.new("Sound")
	sound.SoundId       = "rbxassetid://96347429008558"
	sound.Volume        = 1.4
	sound.PlaybackSpeed = 1.05

	local eq    = Instance.new("EqualizerSoundEffect")
	eq.HighGain = 0
	eq.LowGain  = 5
	eq.MidGain  = 5
	eq.Priority = 2
	eq.Parent   = sound

	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 2)
end

-- =============================================================================
-- FIRE: dispara TUDO junto sincronizado (atalho para quem não quer chamar um a um)
--   character : Model (o personagem R15)
--   footPart  : BasePart (RightFoot ou LeftFoot)
-- =============================================================================
function GeppoVFX.Fire(character, footPart)
	local pos = footPart.Position + Vector3.new(0, -0.3, 0)
	GeppoVFX.PlaySound(footPart)
	GeppoVFX.SpawnStarburst(footPart, pos)
	GeppoVFX.SpawnWindStreaks(footPart)
	GeppoVFX.SpawnShockwaveRings(pos)
	GeppoVFX.SpawnHighlight(character)
end

-- =============================================================================
-- PLAY WITH ANIM TRACK: toca uma AnimationTrack e sincroniza VFX ao impact frame
--   animTrack : AnimationTrack (carregada via Humanoid:LoadAnimation())
--   character : Model
--   footPart  : BasePart
-- =============================================================================
function GeppoVFX.PlayGeppoWithVFX(animTrack, character, footPart)
	animTrack:Play(0.04, 1, 1)
	-- Impact frame (~0.05s de antecipação → frame 2 @ 24fps)
	task.delay(0.05, function()
		GeppoVFX.Fire(character, footPart)
	end)
end

return GeppoVFX
