--[[
	PHASE FREEZE (rodar durante solo_playtest, via MCP eval_client_runtime)

	Efeitos duram milissegundos; screenshot normal não pega nada. Este script:
	  1. limpa efeitos anteriores e descongela
	  2. enquadra a câmera no personagem (3/4, de cima)
	  3. dispara o efeito, espera PHASE segundos e congela tweens + partículas
	Depois disso o Claude chama capture_screenshot. Repita para PHASE = 0.1, 0.5, 1.0.
	No fim, rode com MODE = "release" para devolver a câmera e descongelar.

	EFFECT:
	  "geppo"                → GeppoVFX.Fire no pé direito
	  "block:Categoria/Nome" → VFXBlocks.play de um bloco da VFXLibrary
]]

local MODE = "capture" -- "capture" | "release"
local PHASE = 0.1
local EFFECT = "geppo"
local CAMERA_DISTANCE = 16
-- O Babau Piece tem controlador de câmera próprio que sobrescreve CFrame a cada frame;
-- deixe false e use a câmera padrão (ela já enquadra o personagem).
local FRAME_CAMERA = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VFXUtil = require(Shared.VFXUtil)

local camera = workspace.CurrentCamera
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart") :: BasePart

local function clearEffects()
	VFXUtil.resume()
	for _, child in VFXUtil.container():GetChildren() do
		if child:IsA("ObjectValue") and child.Value then
			child.Value:Destroy()
		end
		child:Destroy()
	end
end

if MODE == "release" then
	clearEffects()
	camera.CameraType = Enum.CameraType.Custom
	return "câmera liberada, efeitos limpos"
end

clearEffects()
root.Anchored = true -- personagem parado para comparar fases

if FRAME_CAMERA then
	local focus = root.Position + Vector3.new(0, -1, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame =
		CFrame.lookAt(focus + Vector3.new(CAMERA_DISTANCE * 0.7, CAMERA_DISTANCE * 0.45, CAMERA_DISTANCE * 0.7), focus)
end

local t0 = os.clock()
if EFFECT == "geppo" then
	local GeppoVFX = require(Shared.GeppoVFX)
	GeppoVFX.Fire(character, character:WaitForChild("RightFoot") :: BasePart)
else
	local category, name = string.match(EFFECT, "^block:([^/]+)/(.+)$")
	assert(category, `EFFECT inválido: {EFFECT}`)
	local VFXBlocks = require(Shared.VFXBlocks)
	VFXBlocks.play(category, name, root.CFrame * CFrame.new(0, -2.5, 0))
end

task.wait(PHASE)
VFXUtil.freeze()
local actual = os.clock() - t0
root.Anchored = false

local count = 0
for _ in VFXUtil.container():GetChildren() do
	count += 1
end
return ("congelado em t=%.3fs (pedido %.2fs), %d instâncias de efeito ativas — tire o screenshot agora"):format(
	actual,
	PHASE,
	count
)
