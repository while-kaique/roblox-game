--[[
	GEPPO VFX — Cinematic Anime Edition v3.1
	Módulo reutilizável: GeppoVFX.Fire(character, footPart)

	Técnicas (Twist VFX "How to Make Slash VFX"):
	  • LightEmission = 1        → remove bordas pretas de texturas transparentes
	  • Speed=0.01 + VelocityPerpendicular → partículas congeladas no ar (fragmentos)
	  • Speed alto + Drag alto   → explosão violenta que cessa instantaneamente
	  • VelocityParallel         → partículas se esticam (linhas de vento)
	  • EasingStyle.Circular     → Highlight pulsa como senoide
	  • RotSpeed 400-500         → giro visível em partículas de Lifetime curto

	Timeline (~24fps, a partir do impacto):
	  f0  core flash + 8 spikes horiz + 4 diag + sparks congeladas + Highlight
	  f0  Ring #1 (0.50s, até 18 studs)  · f2 wind streaks
	  f2  Ring #2 (+0.08s, 0.65s, 22)    · f4 Ring #3 (+0.16s, 0.80s, 27)
	  f10 tudo dissipado

	Tudo passa por VFXUtil → compatível com studio-tools/vfx_phase_freeze.luau.
]]

local VFXUtil = require(script.Parent.VFXUtil)
local SoundLibrary = require(script.Parent.SoundLibrary)

local GeppoVFX = {}

local SPARK_TEXTURE = "rbxassetid://296874871"
local WHITE = Color3.new(1, 1, 1)

-- CFrame com eixo Z apontando para `dir`: yaw = atan2(x, z), pitch = asin(y)
local function makeSpikeCFrame(origin: Vector3, dir: Vector3, halfLen: number): CFrame
	local yaw = math.atan2(dir.X, dir.Z)
	local pitch = math.asin(math.clamp(dir.Y, -1, 1))
	return CFrame.new(origin + dir * halfLen) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
end

local function shootSpike(
	origin: Vector3,
	dir: Vector3,
	thick: number,
	startLen: number,
	endLen: number,
	duration: number,
	startTransp: number?
)
	local spike = VFXUtil.ghostPart({
		Transparency = startTransp or 0,
		Size = Vector3.new(thick, thick, startLen),
		CFrame = makeSpikeCFrame(origin, dir, startLen / 2),
	})
	VFXUtil.tween(spike, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.035, 0.035, endLen),
		CFrame = makeSpikeCFrame(origin, dir, endLen / 2),
		Transparency = 1,
	})
	VFXUtil.cleanup(spike, duration + 0.04)
end

local function emitterOn(footPart: BasePart): Attachment
	local att = Instance.new("Attachment")
	att.Parent = footPart
	VFXUtil.track(att)
	return att
end

function GeppoVFX.SpawnStarburst(footPart: BasePart, pos: Vector3)
	local core = VFXUtil.ghostPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		CFrame = CFrame.new(pos),
	})
	VFXUtil.tween(
		core,
		TweenInfo.new(0.13, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = Vector3.new(5, 5, 5), Transparency = 1 }
	)
	VFXUtil.cleanup(core, 0.17)

	-- 8 spikes horizontais (estrela plana no plano do pé)
	for i = 0, 7 do
		local rad = math.rad(i * 45)
		shootSpike(pos, Vector3.new(math.cos(rad), 0, math.sin(rad)), 0.36, 1.2, 10.5, 0.20)
	end

	-- 4 spikes diagonais para cima (~45°, defasados 45° dos horizontais)
	for i = 0, 3 do
		local rad = math.rad(i * 90 + 45)
		local dir = (Vector3.new(math.cos(rad), 0, math.sin(rad)) + Vector3.new(0, 0.95, 0)).Unit
		shootSpike(pos, dir, 0.26, 1.0, 6.5, 0.22, 0.05)
	end

	-- Fragmentos de ar partido: Speed=0.01 + VelocityPerpendicular congela no ar
	local att = emitterOn(footPart)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = SPARK_TEXTURE
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Color = ColorSequence.new(WHITE)
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.6),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	sparks.Speed = NumberRange.new(0.01, 0.01)
	sparks.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Lifetime = NumberRange.new(0.14, 0.22)
	sparks.Rotation = NumberRange.new(0, 360)
	sparks.RotSpeed = NumberRange.new(400, 500)
	sparks.Rate = 0
	sparks.ZOffset = 0.5
	sparks.Parent = att
	sparks:Emit(16)
	VFXUtil.cleanup(att, 0.3)
end

-- Rajadas verticais: Speed alto + Drag alto = explosão que para quase instantaneamente
function GeppoVFX.SpawnWindStreaks(footPart: BasePart)
	local att = emitterOn(footPart)
	local streaks = Instance.new("ParticleEmitter")
	streaks.Texture = SPARK_TEXTURE
	streaks.LightEmission = 1
	streaks.LightInfluence = 0
	streaks.Color = ColorSequence.new(WHITE)
	streaks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	streaks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(0.4, 0.14),
		NumberSequenceKeypoint.new(1, 0),
	})
	streaks.Speed = NumberRange.new(60, 80)
	streaks.Drag = 7
	streaks.Acceleration = Vector3.new(0, -8, 0)
	streaks.SpreadAngle = Vector2.new(14, 14)
	streaks.Lifetime = NumberRange.new(0.30, 0.50)
	streaks.Orientation = Enum.ParticleOrientation.VelocityParallel
	streaks.Rate = 0
	streaks.Rotation = NumberRange.new(-15, 15)
	streaks.ZOffset = 1
	streaks.Parent = att
	streaks:Emit(22)
	VFXUtil.cleanup(att, 0.6)
end

local RINGS = {
	{ delay = 0.00, startD = 1.8, endD = 18, dur = 0.50, startT = 0.10 },
	{ delay = 0.08, startD = 1.4, endD = 22, dur = 0.65, startT = 0.20 },
	{ delay = 0.16, startD = 1.0, endD = 27, dur = 0.80, startT = 0.30 },
}

function GeppoVFX.SpawnShockwaveRings(pos: Vector3)
	for _, r in RINGS do
		VFXUtil.delay(r.delay, function()
			local ring = VFXUtil.ghostPart({
				Shape = Enum.PartType.Cylinder,
				Transparency = r.startT,
				Size = Vector3.new(0.24, r.startD, r.startD),
				CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
			})
			VFXUtil.tween(
				ring,
				TweenInfo.new(r.dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Size = Vector3.new(0.032, r.endD, r.endD), Transparency = 1 }
			)
			VFXUtil.cleanup(ring, r.dur + 0.04)
		end)
	end
end

function GeppoVFX.SpawnHighlight(character: Model)
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(220, 240, 255)
	hl.OutlineColor = WHITE
	hl.FillTransparency = 1
	hl.OutlineTransparency = 1
	hl.Parent = character
	VFXUtil.track(hl)

	VFXUtil.tween(
		hl,
		TweenInfo.new(0.07, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
		{ FillTransparency = 0.35, OutlineTransparency = 0.15 }
	)
	VFXUtil.delay(0.07, function()
		VFXUtil.tween(
			hl,
			TweenInfo.new(0.28, Enum.EasingStyle.Circular, Enum.EasingDirection.In),
			{ FillTransparency = 1, OutlineTransparency = 1 }
		)
		VFXUtil.cleanup(hl, 0.38)
	end)
end

-- Dispara tudo sincronizado no frame de impacto.
function GeppoVFX.Fire(character: Model, footPart: BasePart)
	local pos = footPart.Position + Vector3.new(0, -0.3, 0)
	SoundLibrary.play("geppo", footPart)
	GeppoVFX.SpawnStarburst(footPart, pos)
	GeppoVFX.SpawnWindStreaks(footPart)
	GeppoVFX.SpawnShockwaveRings(pos)
	GeppoVFX.SpawnHighlight(character)
end

return GeppoVFX
