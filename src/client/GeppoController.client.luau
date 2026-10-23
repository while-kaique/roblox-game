--[[
	GEPPO (SKY WALK) — controlador do personagem (StarterCharacterScripts)
	Trigger: toque DUPLO de Espaço (1 toque = pulo normal); depois do 1º Geppo, até pousar,
	cada toque já é Geppo (GeppoState.press); segurar o toque que disparou um Geppo repete
	sozinho até acabar as cargas (GeppoState.autoReady). Regras em Shared.GeppoState,
	números em Shared.GeppoConfig, efeitos em Shared.GeppoVFX. Este script só liga
	input/Humanoid → regras → física/animação/VFX.

	Tipos (input relativo à câmera no 2º toque): nada/S = para cima (balístico); W = frente;
	A/D = lados. Frente e lados são dash em linha reta (LinearVelocity, sem gravidade) por
	GeppoConfig.DashTime, com o corpo de frente para a câmera; depois caem.

	Expõe o atributo "GeppoCharges" no personagem (lido pelo HUD).

	Não usar JumpRequest no teclado: o Roblox dispara várias vezes enquanto o Espaço está
	apertado, e um pulo comum virava Geppo. O R15 atual usa AnimationConstraint, não Motor6D.
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GeppoConfig = require(Shared:WaitForChild("GeppoConfig"))
local GeppoState = require(Shared:WaitForChild("GeppoState"))
local GeppoVFX = require(Shared:WaitForChild("GeppoVFX"))

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
local rightFoot = character:WaitForChild("RightFoot") :: BasePart
local leftFoot = character:WaitForChild("LeftFoot") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator

-- Pé que "pisa" o ar em cada tipo (VFX/SFX saem dele).
local PUSH_FOOT: { [GeppoState.Kind]: BasePart } = {
	Up = rightFoot,
	Forward = rightFoot,
	Right = leftFoot,
	Left = rightFoot,
}

local state = GeppoState.new(GeppoConfig)

local function publishCharges()
	character:SetAttribute("GeppoCharges", state.airJumpsLeft)
	character:SetAttribute("GeppoMaxCharges", GeppoConfig.MaxAirJumps)
end

-- Animações ---------------------------------------------------------------------------
-- Duas trilhas por tipo, alternadas: Play numa trilha que já toca volta ao quadro 0 na hora
-- (corte). Qualquer Geppo seguido faz crossfade da trilha que estiver tocando para a nova.

type Slot = { id: string, animation: Animation, tracks: { AnimationTrack }, current: number }

local slots: { [string]: Slot } = {}
local playing: AnimationTrack? = nil

local function animationId(kind: GeppoState.Kind): string
	local teste = character:GetAttribute(`GeppoAnim{kind}Teste`)
	if typeof(teste) == "string" and teste ~= "" then
		return teste
	end
	return (GeppoConfig.Animations :: { [string]: string })[kind] or ""
end

-- Carrega na primeira vez (e de novo se o id mudar).
local function slotFor(kind: GeppoState.Kind): Slot?
	local id = animationId(kind)
	local slot = slots[kind]
	if slot and slot.id == id then
		return slot
	end
	if slot then
		for _, t in slot.tracks do
			t:Destroy()
		end
		slots[kind] = nil
	end
	if id == "" then
		return nil
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local novo: Slot = { id = id, animation = anim, tracks = {}, current = 1 }
	for i = 1, 2 do
		local t = animator:LoadAnimation(anim)
		t.Priority = Enum.AnimationPriority.Action2
		t.Looped = false
		-- A volta é a mistura com a animação de baixo (queda), não um quadro final neutro.
		t:GetMarkerReachedSignal("Soltar"):Connect(function()
			t:Stop(GeppoConfig.AnimReleaseFade)
		end)
		novo.tracks[i] = t
	end
	slots[kind] = novo
	return novo
end

local function playAnimation(kind: GeppoState.Kind)
	local previous = playing
	local chained = previous ~= nil and previous.IsPlaying
	local fade = if chained then GeppoConfig.AnimChainFade else GeppoConfig.AnimFadeIn
	if previous and chained then
		previous:Stop(fade)
	end
	playing = nil
	local slot = slotFor(kind)
	if slot == nil then
		return
	end
	slot.current = 3 - slot.current
	local t = slot.tracks[slot.current]
	t:Play(fade)
	playing = t
end

-- Pré-carrega as 4 ao nascer: sem isso o 1º Geppo de cada tipo saía sem animação (o asset
-- ainda estava baixando quando a trilha tocou; acontece no jogo publicado também).
task.spawn(function()
	local animations: { Instance } = {}
	for _, kind: GeppoState.Kind in { "Up", "Forward", "Right", "Left" } do
		local slot = slotFor(kind)
		if slot then
			table.insert(animations, slot.animation)
		end
	end
	ContentProvider:PreloadAsync(animations)
end)

local function stopAnimation()
	if playing and playing.IsPlaying then
		playing:Stop(GeppoConfig.AnimFadeOut)
	end
	playing = nil
end

-- Dash (frente/lados) ----------------------------------------------------------------

local dashAttachment = Instance.new("Attachment")
dashAttachment.Name = "GeppoDash"
dashAttachment.Parent = rootPart

local dashForce = Instance.new("LinearVelocity")
dashForce.Name = "GeppoDash"
dashForce.Attachment0 = dashAttachment
dashForce.RelativeTo = Enum.ActuatorRelativeTo.World
dashForce.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
dashForce.MaxForce = math.huge
dashForce.Enabled = false
dashForce.Parent = rootPart

local dashToken = 0
local dashFacing: CFrame? = nil -- orientação alvo do corpo durante o dash
local DASH_TURN = 25 -- quão rápido o corpo vira para a frente da câmera (1/s)

local function endDash(carry: boolean)
	dashToken += 1
	if not dashForce.Enabled then
		return
	end
	dashForce.Enabled = false
	dashFacing = nil
	humanoid.AutoRotate = true
	if carry then
		-- Solta em queda livre a partir daqui: guarda um pouco do embalo horizontal.
		local v = dashForce.VectorVelocity * GeppoConfig.DashCarry
		rootPart.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
	end
end

local function startDash(velocity: Vector3, facing: Vector3)
	endDash(false)
	local token = dashToken
	dashForce.VectorVelocity = velocity
	dashForce.Enabled = true
	rootPart.AssemblyLinearVelocity = velocity
	-- Corpo de frente para a câmera: no lateral a inclinação fica de lado de verdade (o
	-- AutoRotate viraria o boneco para a direção do movimento).
	humanoid.AutoRotate = false
	dashFacing = CFrame.lookAt(Vector3.zero, facing)
	task.delay(GeppoConfig.DashTime, function()
		if token == dashToken then
			endDash(true)
		end
	end)
end

RunService.Heartbeat:Connect(function(dt)
	local alvo = dashFacing
	if alvo then
		local giro = rootPart.CFrame.Rotation:Lerp(alvo, math.min(1, dt * DASH_TURN))
		rootPart.CFrame = CFrame.new(rootPart.Position) * giro
	end
end)

-- Geppo ------------------------------------------------------------------------------

-- Frente e direita da câmera no plano, unitárias.
local function cameraBasis(): (Vector3, Vector3)
	local cf = (Workspace.CurrentCamera :: Camera).CFrame
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if look.Magnitude < 1e-3 then
		look = Vector3.new(cf.UpVector.X, 0, cf.UpVector.Z)
	end
	look = look.Unit
	return look, Vector3.new(-look.Z, 0, look.X)
end

local function performGeppo(): boolean
	local look, right = cameraBasis()
	local move = humanoid.MoveDirection
	local kind = GeppoState.classify(GeppoConfig, move:Dot(look), move:Dot(right))
	if not GeppoState.tryJump(state, os.clock(), kind) then
		return false
	end
	publishCharges()

	local vx, vy, vz, dash = GeppoState.velocity(GeppoConfig, kind, look.X, look.Z, right.X, right.Z)
	if dash then
		startDash(Vector3.new(vx, vy, vz), look)
	else
		-- Para cima: só a vertical; o embalo horizontal continua. Cortando um dash, herda só a
		-- sobra (DashCarry), não a velocidade cheia — senão sobe na diagonal (medido: 54 studs/s).
		endDash(true)
		local v = rootPart.AssemblyLinearVelocity
		rootPart.AssemblyLinearVelocity = Vector3.new(v.X, vy, v.Z)
	end

	playAnimation(kind)
	task.delay(GeppoConfig.ImpactDelay, GeppoVFX.Fire, character, PUSH_FOOT[kind])
	return true
end

-- Um toque que dispara Geppo arma a repetição enquanto estiver segurado.
local function onTap()
	if GeppoState.press(state, os.clock()) and performGeppo() then
		GeppoState.holdStart(state)
	end
end

local function isJumpKey(input: InputObject): boolean
	return input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA
end

-- Teclado/controle: uma borda por toque (InputBegan). O 1º toque no chão vira o pulo normal
-- do Humanoid; o 2º, já no ar e dentro da janela, é o Geppo.
UserInputService.InputBegan:Connect(function(input)
	if not UserInputService:GetFocusedTextBox() and isJumpKey(input) then
		onTap()
	end
end)

-- "Segurando" pelo estado real da tecla a cada quadro (no teste chegou um InputEnded falso
-- 0,23 s depois do aperto, com o Espaço ainda embaixo).
local function jumpKeyHeld(): boolean
	return UserInputService:IsKeyDown(Enum.KeyCode.Space)
		or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
end

-- Celular: o botão de pulo só chega como JumpRequest, que repete enquanto o dedo está em
-- cima. Uma pausa sem pedidos separa um toque do outro (e marca que soltou).
local TOUCH_GAP = 0.12
local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local lastRequest = -math.huge
if touchOnly then
	UserInputService.JumpRequest:Connect(function()
		local now = os.clock()
		if now - lastRequest > TOUCH_GAP then
			onTap()
		end
		lastRequest = now
	end)
end

-- Segurando: o próximo Geppo sai sozinho colado no fim do atual (direção relida a cada um),
-- até acabar as cargas.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local held = if touchOnly then now - lastRequest <= TOUCH_GAP else jumpKeyHeld()
	if not held then
		GeppoState.holdEnd(state)
	end
	if GeppoState.autoReady(state, now, Workspace.Gravity) then
		performGeppo()
	end
end)

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
		GeppoState.onGrounded(state)
		publishCharges()
		endDash(false)
		stopAnimation()
	elseif newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
		GeppoState.onAirborne(state)
	end
end)

publishCharges()
