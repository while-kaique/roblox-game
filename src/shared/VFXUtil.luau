--[[
	Utilitários de VFX com suporte a "Phase Freeze".

	Todo efeito criado por aqui vai para workspace.VFXActive, e cada Tween fica
	parentado à instância que anima. Assim, studio-tools/vfx_phase_freeze.luau
	consegue pausar TUDO num instante t (tweens + partículas) sem precisar
	compartilhar estado de módulo, e o Claude tira screenshots de cada fase.
]]

local TweenService = game:GetService("TweenService")

local VFXUtil = {}

local FOLDER_NAME = "VFXActive"
local FROZEN_ATTR = "Frozen"

function VFXUtil.container(): Folder
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = workspace
	end
	return folder
end

function VFXUtil.isFrozen(): boolean
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	return folder ~= nil and folder:GetAttribute(FROZEN_ATTR) == true
end

-- Espera `t` segundos e, se o VFX estiver congelado, espera até descongelar.
local function waitRespectingFreeze(t: number)
	task.wait(t)
	while VFXUtil.isFrozen() do
		task.wait()
	end
end

function VFXUtil.delay(t: number, fn: () -> ())
	task.spawn(function()
		waitRespectingFreeze(t)
		fn()
	end)
end

function VFXUtil.cleanup(instance: Instance, t: number)
	VFXUtil.delay(t, function()
		instance:Destroy()
	end)
end

function VFXUtil.tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local tween = TweenService:Create(instance, info, goal)
	tween.Parent = instance
	tween:Play()
	return tween
end

-- Part neon "fantasma" (sem colisão/query/sombra), já dentro de VFXActive.
function VFXUtil.ghostPart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = VFXUtil.container()
	return part
end

-- Registra uma instância fora de VFXActive (ex.: Highlight ou Attachment no personagem)
-- para o freeze achá-la.
function VFXUtil.track(instance: Instance)
	local ref = Instance.new("ObjectValue")
	ref.Name = "Tracked"
	ref.Value = instance
	ref.Parent = VFXUtil.container()
	instance.Destroying:Once(function()
		ref:Destroy()
	end)
end

local function eachEffectInstance(fn: (Instance) -> ())
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if not folder then
		return
	end
	local roots: { Instance } = { folder }
	for _, ref in folder:GetChildren() do
		if ref:IsA("ObjectValue") and ref.Value then
			table.insert(roots, ref.Value)
		end
	end
	for _, root in roots do
		fn(root)
		for _, inst in root:GetDescendants() do
			fn(inst)
		end
	end
end

function VFXUtil.freeze()
	VFXUtil.container():SetAttribute(FROZEN_ATTR, true)
	eachEffectInstance(function(inst)
		if inst:IsA("Tween") and inst.PlaybackState == Enum.PlaybackState.Playing then
			inst:Pause()
		elseif inst:IsA("ParticleEmitter") then
			inst.TimeScale = 0
		end
	end)
end

function VFXUtil.resume()
	VFXUtil.container():SetAttribute(FROZEN_ATTR, false)
	eachEffectInstance(function(inst)
		if inst:IsA("Tween") and inst.PlaybackState == Enum.PlaybackState.Paused then
			inst:Play()
		elseif inst:IsA("ParticleEmitter") then
			inst.TimeScale = 1
		end
	end)
end

return VFXUtil
