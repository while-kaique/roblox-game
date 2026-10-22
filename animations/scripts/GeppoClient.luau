--[[
    =============================================================================
    GEPPO (SKY WALK) — CINEMATIC ANIME EDITION  v3.0
    =============================================================================
    ► Trigger     : Spacebar no ar (pulo duplo)
    ► SFX Geppo   : rbxassetid://96347429008558
                    └─ EqualizerSoundEffect  HighGain=0  LowGain=5  MidGain=5  Priority=2
    ► VFX Ref     : Twist VFX "How to Make Slash VFX" + análise frame-a-frame do Geppo
    ─────────────────────────────────────────────────────────────────────────────
    TÉCNICAS DO TWIST VFX APLICADAS:
      • LightEmission = 1         → remove bordas pretas de texturas transparentes
      • Speed=0.01+VelocityPerp   → partículas congeladas no ar (fragmentos de ar partido)
      • Speed alto + Drag alto    → explosão instantânea que cessa no ar (vento vertical)
      • VelocityParallel          → partículas se esticam na direção do movimento
      • EasingStyle.Circular      → highlight no personagem pulsa como senoide, não linear
      • RotSpeed 400-500          → giro visível em partículas de Lifetime curto
    ─────────────────────────────────────────────────────────────────────────────
    BUG CRÍTICO CORRIGIDO (v3.0):
      ANTES: rightHip = rightFoot.Parent:FindFirstChild("RightUpperLeg") = nil
             (RightFoot.Parent é RightLowerLeg, que NÃO tem RightUpperLeg como filho)
      AGORA: rightHip = character:WaitForChild("RightUpperLeg"):FindFirstChild("RightHip")
      → Sem essa correção, ZERO animação corporal era aplicada.
    ─────────────────────────────────────────────────────────────────────────────
    VFX Frame Timeline (~24fps):
      f0    Impulso físico + Fase 0 de antecipação inicia
      f≈1   Stomp (hips ↓  arms ↓  waist crunch  head ↑)
      f≈2   VFX: core flash + 8 spikes horiz + 4 diag + sparks congeladas + Highlight
      f≈2   Ring #1 expande (dur 0.50s, até 18 studs)
      f≈4   Wind streaks disparam (Speed=75 Drag=7 → explosão que cessa)
      f≈5   Ring #2 (delay 0.08s, dur 0.65s, até 22 studs)
      f≈6   Ring #3 (delay 0.16s, dur 0.80s, até 27 studs)
      f≈12  Todos os VFX dissipados
    =============================================================================
--]]

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Debris           = game:GetService("Debris")
local Players          = game:GetService("Players")

local player    = Players.LocalPlayer
local character = script.Parent
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")
local rightFoot = character:WaitForChild("RightFoot")

-- ── R15 Parts ────────────────────────────────────────────────────────────────
local upperTorso    = character:WaitForChild("UpperTorso")
local head          = character:WaitForChild("Head")
local rightUpperLeg = character:WaitForChild("RightUpperLeg")
local leftUpperLeg  = character:WaitForChild("LeftUpperLeg")
local rightLowerLeg = character:WaitForChild("RightLowerLeg")
local leftLowerLeg  = character:WaitForChild("LeftLowerLeg")
local rightUpperArm = character:WaitForChild("RightUpperArm")
local leftUpperArm  = character:WaitForChild("LeftUpperArm")
local rightLowerArm = character:WaitForChild("RightLowerArm")
local leftLowerArm  = character:WaitForChild("LeftLowerArm")

-- ── Motor6D Joints (cada joint vive DENTRO da parte FILHA no R15) ─────────────
-- BUGFIX v3.0: paths corretos — anteriormente rightHip/leftHip/knees/shoulders eram nil
local joints = {
	waist         = upperTorso:FindFirstChild("Waist"),
	neck          = head:FindFirstChild("Neck"),
	rightHip      = rightUpperLeg:FindFirstChild("RightHip"),      -- CORRIGIDO
	leftHip       = leftUpperLeg:FindFirstChild("LeftHip"),        -- CORRIGIDO
	rightKnee     = rightLowerLeg:FindFirstChild("RightKnee"),     -- NOVO
	leftKnee      = leftLowerLeg:FindFirstChild("LeftKnee"),       -- NOVO
	rightShoulder = rightUpperArm:FindFirstChild("RightShoulder"), -- NOVO
	leftShoulder  = leftUpperArm:FindFirstChild("LeftShoulder"),   -- NOVO
	rightElbow    = rightLowerArm:FindFirstChild("RightElbow"),    -- NOVO
	leftElbow     = leftLowerArm:FindFirstChild("LeftElbow"),      -- NOVO
}

-- ── Config ─────────────────────────────────────────────────────────────────────
local MAX_JUMPS     = 5
local COOLDOWN      = 0.22
local JUMP_POWER_Y  = 58
local JUMP_POWER_XZ = 42

local airJumpsLeft = MAX_JUMPS
local lastJumpTime = 0
local isMidAir     = false
local isAnimating  = false

-- ── Textura de partícula nítida (funciona bem com LightEmission=1) ─────────────
local SPARK_TEXTURE = "rbxassetid://296874871"

-- =============================================================================
-- HELPER: eixo Z do Part aponta para `dir` (matemática verificada)
--   yaw   = atan2(dir.X, dir.Z)  — gira Z no plano XZ
--   pitch = asin(dir.Y)          — inclina Z para cima/baixo
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
	spike.Material    = Enum.Material.Neon
	spike.Color       = Color3.fromRGB(255, 255, 255)
	spike.Transparency = startTransp
	spike.Anchored    = true
	spike.CanCollide  = false
	spike.CanQuery    = false
	spike.CanTouch    = false
	spike.CastShadow  = false
	spike.Size        = Vector3.new(thick, thick, startLen)
	spike.CFrame      = startCF
	spike.Parent      = workspace

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
-- VFX 1: STARBURST — núcleo flash + spikes + faíscas congeladas
-- =============================================================================
local function spawnStarburst(pos)
	-- ── Núcleo: esfera branca opaca que expande rapidamente e desaparece
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

	-- ── 8 spikes horizontais (estrela plana no plano do pé)
	for i = 0, 7 do
		local rad = math.rad(i * 45)
		local dir = Vector3.new(math.cos(rad), 0, math.sin(rad))
		shootSpike(pos, dir, 0.36, 1.2, 10.5, 0.20)
	end

	-- ── 4 spikes diagonais para cima (~45°, offset de 45° dos horizontais)
	for i = 0, 3 do
		local rad = math.rad(i * 90 + 45)
		local horiz = Vector3.new(math.cos(rad), 0, math.sin(rad))
		local dir   = (horiz + Vector3.new(0, 0.95, 0)).Unit
		shootSpike(pos, dir, 0.26, 1.0, 6.5, 0.22, 0.05)
	end

	-- ── TWIST VFX: partículas congeladas no ar (Speed=0.01 + VelocityPerpendicular)
	-- Cria fragmentos planos nítidos que parecem o ar se partindo
	local att = Instance.new("Attachment")
	att.Parent = rightFoot  -- parentado ao pé; partículas emitem para o mundo

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture        = SPARK_TEXTURE
	sparks.LightEmission  = 1           -- TWIST VFX: elimina bordas pretas
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
	sparks.Speed       = NumberRange.new(0.01, 0.01)  -- TWIST VFX: congela no ar
	sparks.Orientation = Enum.ParticleEmitterOrientation.VelocityPerpendicular
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Lifetime    = NumberRange.new(0.14, 0.22)
	sparks.Rotation    = NumberRange.new(0, 360)
	sparks.RotSpeed    = NumberRange.new(400, 500)  -- TWIST VFX: giro extremo p/ vida curta
	sparks.Rate        = 0
	sparks.ZOffset     = 0.5
	sparks.Parent      = att

	sparks:Emit(16)
	Debris:AddItem(att, 0.3)
end

-- =============================================================================
-- VFX 2: RAJADAS DE VENTO VERTICAIS
-- TWIST VFX: Speed=75 + Drag=7 → explosão que cessa quase instantaneamente
--            VelocityParallel  → partículas se esticam = linhas de vento
-- =============================================================================
local function spawnWindStreaks(pos)
	local att = Instance.new("Attachment")
	att.Parent = rightFoot

	local streaks = Instance.new("ParticleEmitter")
	streaks.Texture        = SPARK_TEXTURE
	streaks.LightEmission  = 1           -- TWIST VFX: sem bordas pretas
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
	-- TWIST VFX: Speed alto + Drag alto = explosão violenta que para instantaneamente
	streaks.Speed       = NumberRange.new(60, 80)
	streaks.Drag        = 7
	streaks.Acceleration = Vector3.new(0, -8, 0)  -- leve queda para naturalidade
	streaks.SpreadAngle = Vector2.new(14, 14)      -- quase vertical
	streaks.Lifetime    = NumberRange.new(0.30, 0.50)
	streaks.Orientation = Enum.ParticleEmitterOrientation.VelocityParallel  -- estica
	streaks.Rate        = 0
	streaks.Rotation    = NumberRange.new(-15, 15)
	streaks.ZOffset     = 1
	streaks.Parent      = att

	streaks:Emit(22)
	Debris:AddItem(att, 0.6)
end

-- =============================================================================
-- VFX 3: 3 ANÉIS DE CHOQUE ESCALONADOS
-- Timing baseado na análise frame-a-frame: expandem, ficam finos e somem
-- =============================================================================
local function spawnShockwaveRings(pos)
	local ringConfigs = {
		{ delay=0.00, startD=1.8, endD=18, dur=0.50, startT=0.10 },
		{ delay=0.08, startD=1.4, endD=22, dur=0.65, startT=0.20 },
		{ delay=0.16, startD=1.0, endD=27, dur=0.80, startT=0.30 },
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
-- VFX 4: HIGHLIGHT PULSE NO PERSONAGEM
-- TWIST VFX: EasingStyle.Circular → brilho senoidal, não troca de cor dura
-- =============================================================================
local function spawnCharacterHighlight()
	local hl = Instance.new("Highlight")
	hl.FillColor          = Color3.fromRGB(220, 240, 255)
	hl.OutlineColor       = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency   = 1
	hl.OutlineTransparency = 1
	hl.Parent             = character

	-- Acende com Circular easing (pulso senoidal, não linear)
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
-- SFX: GEPPO COM EQUALIZERSOUNDEFFECT
-- =============================================================================
local function playGeppoSound()
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

	sound.Parent = rootPart
	sound:Play()
	Debris:AddItem(sound, 2)
end

-- =============================================================================
-- ANIMAÇÃO CORPORAL: STOMP EM 3 FASES
-- v3.0: Todos os 10 joints operacionais (antes: apenas waist e neck)
-- =============================================================================
local function triggerStompAnimation()
	if isAnimating then return end
	isAnimating = true

	-- Snapshot dos C0 ANTES de qualquer tween — base para todos os offsets
	-- (garante que as fases são relativas à posição original, não umas às outras)
	local snap = {}
	for name, joint in pairs(joints) do
		if joint then snap[name] = joint.C0 end
	end

	local R = math.rad
	local S, D = Enum.EasingStyle, Enum.EasingDirection

	local function tw(name, dur, style, dir, rx, ry, rz)
		local j = joints[name]
		if not j or not snap[name] then return end
		TweenService:Create(j,
			TweenInfo.new(dur, style, dir),
			{ C0 = snap[name] * CFrame.Angles(R(rx or 0), R(ry or 0), R(rz or 0)) }
		):Play()
	end
	local function restore(name, dur)
		local j = joints[name]
		if not j or not snap[name] then return end
		TweenService:Create(j,
			TweenInfo.new(dur, S.Quad, D.Out),
			{ C0 = snap[name] }
		):Play()
	end

	-- ── FASE 0: Antecipação (dur 0.05s)
	-- Joelhos sobem, costas recuam levemente acumulando energia
	tw("waist",     0.05, S.Quad, D.In, -10)
	tw("rightHip",  0.05, S.Quad, D.In, -28)
	tw("leftHip",   0.05, S.Quad, D.In, -28)
	tw("rightKnee", 0.05, S.Quad, D.In,  22)
	tw("leftKnee",  0.05, S.Quad, D.In,  22)

	-- ── FASE 1: Stomp Explosivo (delay 0.05s, dur 0.08s)
	-- Pernas chutam PARA BAIXO violentamente
	-- Braços varrem PARA BAIXO (impulso)
	-- Peito crunch para frente, cabeça snaps UP olhando o destino
	task.delay(0.05, function()
		tw("waist",         0.08, S.Back, D.Out,  34)
		tw("neck",          0.08, S.Back, D.Out, -42)
		tw("rightHip",      0.08, S.Back, D.Out,  52)
		tw("leftHip",       0.08, S.Back, D.Out,  52)
		tw("rightKnee",     0.08, S.Back, D.Out, -28)
		tw("leftKnee",      0.08, S.Back, D.Out, -28)
		tw("rightShoulder", 0.08, S.Back, D.Out,  60)
		tw("leftShoulder",  0.08, S.Back, D.Out,  60)
		tw("rightElbow",    0.08, S.Back, D.Out,  32)
		tw("leftElbow",     0.08, S.Back, D.Out,  32)
	end)

	-- ── FASE 2: Recuperação (delay 0.15s, dur 0.40s)
	-- Volta suave para posição original — efeito de amortecimento de gravidade
	task.delay(0.15, function()
		for name in pairs(joints) do restore(name, 0.40) end
		task.delay(0.40, function() isAnimating = false end)
	end)
end

-- =============================================================================
-- GEPPO PRINCIPAL
-- =============================================================================
local function performGeppo()
	if not isMidAir or airJumpsLeft <= 0 then return end
	local now = tick()
	if now - lastJumpTime < COOLDOWN then return end

	lastJumpTime = now
	airJumpsLeft = airJumpsLeft - 1

	-- 1. Impulso físico (para cima + direção do WASD)
	local moveDir = humanoid.MoveDirection
	rootPart.AssemblyLinearVelocity = Vector3.new(
		moveDir.X * JUMP_POWER_XZ,
		JUMP_POWER_Y,
		moveDir.Z * JUMP_POWER_XZ
	)

	-- 2. Animação corporal (inicia imediatamente com antecipação)
	triggerStompAnimation()

	-- 3. VFX + SFX no frame de impacto do stomp (~0.05s = frame 2 @ 24fps)
	local footPos = rightFoot.Position + Vector3.new(0, -0.3, 0)
	task.delay(0.05, function()
		playGeppoSound()
		spawnStarburst(footPos)
		spawnWindStreaks(footPos)
		spawnShockwaveRings(footPos)
		spawnCharacterHighlight()
	end)

	print("[Geppo v3] Jumps remaining: " .. airJumpsLeft)
end

-- =============================================================================
-- ESTADO & INPUT
-- =============================================================================
humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed
		or newState == Enum.HumanoidStateType.Running then
		airJumpsLeft = MAX_JUMPS
		isMidAir     = false
	elseif newState == Enum.HumanoidStateType.Freefall
		or newState == Enum.HumanoidStateType.Jumping then
		isMidAir = true
	end
end)

UserInputService.JumpRequest:Connect(function()
	if isMidAir then performGeppo() end
end)

print("[Geppo Cinematic v3] Initialized — Double-Space mid-air to Sky Walk!")
