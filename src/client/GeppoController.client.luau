--[[
	GEPPO (SKY WALK) — controlador do personagem (StarterCharacterScripts)
	Trigger: Espaço no ar. Regras em Shared.GeppoState, números em Shared.GeppoConfig,
	efeitos em Shared.GeppoVFX. Este script só liga input/Humanoid → regras → animação/VFX.

	Expõe o atributo "GeppoCharges" no personagem (lido pelo HUD).

	R15: cada Motor6D vive DENTRO da parte FILHA (RightHip está em RightUpperLeg,
	não em RightFoot.Parent). Errar isso zera a animação corporal — bug do v2.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GeppoConfig = require(Shared:WaitForChild("GeppoConfig"))
local GeppoState = require(Shared:WaitForChild("GeppoState"))
local GeppoVFX = require(Shared:WaitForChild("GeppoVFX"))

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
local rightFoot = character:WaitForChild("RightFoot") :: BasePart

local function joint(partName: string, jointName: string): Motor6D?
	return character:WaitForChild(partName):FindFirstChild(jointName) :: Motor6D?
end

local joints: { [string]: Motor6D? } = {
	waist = joint("UpperTorso", "Waist"),
	neck = joint("Head", "Neck"),
	rightHip = joint("RightUpperLeg", "RightHip"),
	leftHip = joint("LeftUpperLeg", "LeftHip"),
	rightKnee = joint("RightLowerLeg", "RightKnee"),
	leftKnee = joint("LeftLowerLeg", "LeftKnee"),
	rightShoulder = joint("RightUpperArm", "RightShoulder"),
	leftShoulder = joint("LeftUpperArm", "LeftShoulder"),
	rightElbow = joint("RightLowerArm", "RightElbow"),
	leftElbow = joint("LeftLowerArm", "LeftElbow"),
}

local state = GeppoState.new(GeppoConfig)
local isAnimating = false

local function publishCharges()
	character:SetAttribute("GeppoCharges", state.airJumpsLeft)
	character:SetAttribute("GeppoMaxCharges", GeppoConfig.MaxAirJumps)
end

-- Stomp em 3 fases, relativo ao C0 original de cada joint.
local function triggerStompAnimation()
	if isAnimating then
		return
	end
	isAnimating = true

	local snap: { [string]: CFrame } = {}
	for name, j in joints do
		if j then
			snap[name] = j.C0
		end
	end

	local R = math.rad
	local S, D = Enum.EasingStyle, Enum.EasingDirection

	local function tw(name: string, dur: number, style: Enum.EasingStyle, dir: Enum.EasingDirection, rx: number)
		local j = joints[name]
		if j and snap[name] then
			TweenService:Create(j, TweenInfo.new(dur, style, dir), { C0 = snap[name] * CFrame.Angles(R(rx), 0, 0) })
				:Play()
		end
	end

	-- Fase 0: antecipação (0.05s) — joelhos sobem, costas recuam
	tw("waist", 0.05, S.Quad, D.In, -10)
	tw("rightHip", 0.05, S.Quad, D.In, -28)
	tw("leftHip", 0.05, S.Quad, D.In, -28)
	tw("rightKnee", 0.05, S.Quad, D.In, 22)
	tw("leftKnee", 0.05, S.Quad, D.In, 22)

	-- Fase 1: stomp explosivo (0.08s) — pernas e braços para baixo, cabeça olha pra cima
	task.delay(0.05, function()
		tw("waist", 0.08, S.Back, D.Out, 34)
		tw("neck", 0.08, S.Back, D.Out, -42)
		tw("rightHip", 0.08, S.Back, D.Out, 52)
		tw("leftHip", 0.08, S.Back, D.Out, 52)
		tw("rightKnee", 0.08, S.Back, D.Out, -28)
		tw("leftKnee", 0.08, S.Back, D.Out, -28)
		tw("rightShoulder", 0.08, S.Back, D.Out, 60)
		tw("leftShoulder", 0.08, S.Back, D.Out, 60)
		tw("rightElbow", 0.08, S.Back, D.Out, 32)
		tw("leftElbow", 0.08, S.Back, D.Out, 32)
	end)

	-- Fase 2: recuperação (0.40s) — amortece de volta ao C0 original
	task.delay(0.15, function()
		for name, j in joints do
			if j and snap[name] then
				TweenService:Create(j, TweenInfo.new(0.40, S.Quad, D.Out), { C0 = snap[name] }):Play()
			end
		end
		task.delay(0.40, function()
			isAnimating = false
		end)
	end)
end

local function performGeppo()
	if not GeppoState.tryJump(state, os.clock()) then
		return
	end
	publishCharges()

	local move = humanoid.MoveDirection
	local vx, vy, vz = GeppoState.impulse(GeppoConfig, move.X, move.Z)
	rootPart.AssemblyLinearVelocity = Vector3.new(vx, vy, vz)

	triggerStompAnimation()
	task.delay(GeppoConfig.ImpactDelay, GeppoVFX.Fire, character, rightFoot)
end

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
		GeppoState.onGrounded(state)
		publishCharges()
	elseif newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
		GeppoState.onAirborne(state)
	end
end)

UserInputService.JumpRequest:Connect(performGeppo)

publishCharges()
