--[[
	ANIM IMPORT (rodar no Studio em modo edição, via MCP execute_luau)

	Lê o JSON gerado por animations/scripts/r15_lib.py (export_json) e:
	  1. monta uma KeyframeSequence em ServerStorage.AnimacoesGeradas.<nome> (Pose por frame,
	     hierarquia HumanoidRootPart > LowerTorso > ..., Easing Linear; markers viram
	     KeyframeMarker);
	  2. cria/reaproveita o boneco Workspace.AnimPreview (R15 padrão, a 40 studs do spawn)
	     e posa o quadro de PREVIEW_T (cinemática direta), para screenshot.

	De onde vem o JSON: do servidor local (o execute_luau roda como plugin e pode ler
	localhost), suba antes:  python -m http.server 8765 --bind 127.0.0.1 --directory animations/exports
	Sem servidor: anim_to_luau.py --embed cola o JSON no DATA.
	O Claude gera o script com anim_to_luau.py <nome> [--t s] e manda no execute_luau.

	Publicar: botão direito na KeyframeSequence → "Save to Roblox" (conta do dono do jogo,
	senão a animação não toca), ou export_rbxm + scripts/opencloud_upload.py --type Animation.
	MODE = "clear" apaga o AnimPreview.
]]

local NOME = "__ANIM_NOME__"
local URL = "http://127.0.0.1:8765/"
local DATA = [==[__ANIM_JSON__]==]
local MODE = "import" -- "import" | "clear"
local PREVIEW_T = 0 -- segundos; -1 = último quadro

local HttpService = game:GetService("HttpService")

if string.sub(DATA, 1, 2) == "__" then
	DATA = HttpService:GetAsync(URL .. NOME .. ".anim.json", true)
end
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local function preview(): Model
	local rig = workspace:FindFirstChild("AnimPreview")
	if rig and rig:IsA("Model") then
		return rig
	end
	local novo =
		Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	novo.Name = "AnimPreview"
	novo:PivotTo(CFrame.new(0, 3.2, 40) * CFrame.Angles(0, math.pi, 0))
	local raiz = novo:FindFirstChild("HumanoidRootPart") :: BasePart
	raiz.Anchored = true
	novo.Parent = workspace
	return novo
end

if MODE == "clear" then
	local rig = workspace:FindFirstChild("AnimPreview")
	if rig then
		rig:Destroy()
	end
	return "AnimPreview removido"
end

local anim = HttpService:JSONDecode(DATA)

local function cframe(c: { number }): CFrame
	return CFrame.new(table.unpack(c, 1, 12))
end

-- KeyframeSequence
local pasta = ServerStorage:FindFirstChild("AnimacoesGeradas")
if not pasta then
	pasta = Instance.new("Folder")
	pasta.Name = "AnimacoesGeradas"
	pasta.Parent = ServerStorage
end
local antiga = pasta:FindFirstChild(anim.name)
if antiga then
	antiga:Destroy()
end
local seq = Instance.new("KeyframeSequence")
seq.Name = anim.name
seq.Loop = anim.loop
seq.Priority = (Enum.AnimationPriority :: any)[anim.priority]

local function filhos(parte: string): { string }
	local lista = {}
	for filho, pai in anim.hierarchy do
		if pai == parte then
			table.insert(lista, filho)
		end
	end
	return lista
end

for _, quadro in anim.frames do
	local kf = Instance.new("Keyframe")
	kf.Time = quadro.t
	local function montar(parte: string, pai: Instance)
		local pose = Instance.new("Pose")
		pose.Name = parte
		pose.Weight = 1
		pose.EasingStyle = Enum.PoseEasingStyle.Linear
		local c = quadro.poses[parte]
		pose.CFrame = if c then cframe(c) else CFrame.identity
		pose.Parent = pai
		for _, filho in filhos(parte) do
			montar(filho, pose)
		end
	end
	montar("HumanoidRootPart", kf)
	kf.Parent = seq
end
for nome, t in anim.markers do
	local alvo: Keyframe? = nil
	for _, kf in seq:GetChildren() do
		if kf:IsA("Keyframe") and (alvo == nil or math.abs(kf.Time - t) < math.abs(alvo.Time - t)) then
			alvo = kf
		end
	end
	if alvo then
		local marker = Instance.new("KeyframeMarker")
		marker.Name = nome
		alvo:AddMarker(marker)
	end
end
seq.Parent = pasta

-- Preview: quadro mais próximo de PREVIEW_T, por cinemática direta com as partes ancoradas.
-- (Em modo edição o AnimationConstraint não é resolvido — é física —, então escrever o
-- Transform não mexe nada.) parte1 = parte0 · Attachment0 · Pose · Attachment1⁻¹.
local rig = preview()
local alvoT = if PREVIEW_T < 0 then anim.frames[#anim.frames].t else PREVIEW_T
local escolhido = anim.frames[1]
for _, quadro in anim.frames do
	if math.abs(quadro.t - alvoT) < math.abs(escolhido.t - alvoT) then
		escolhido = quadro
	end
end
local juntas: { [BasePart]: { AnimationConstraint } } = {}
for _, d in rig:GetDescendants() do
	if d:IsA("BasePart") then
		d.Anchored = true
	elseif d:IsA("AnimationConstraint") and d.Attachment0 and d.Attachment1 then
		local p0 = d.Attachment0.Parent :: BasePart
		juntas[p0] = juntas[p0] or {}
		table.insert(juntas[p0], d)
	end
end
local aplicadas = 0
local function fk(parte: BasePart)
	for _, j in juntas[parte] or {} do
		local a0, a1 = j.Attachment0 :: Attachment, j.Attachment1 :: Attachment
		local p1 = a1.Parent :: BasePart
		local c = escolhido.poses[p1.Name]
		p1.CFrame = parte.CFrame * a0.CFrame * (if c then cframe(c) else CFrame.identity) * a1.CFrame:Inverse()
		aplicadas += 1
		fk(p1)
	end
end
fk(rig:FindFirstChild("HumanoidRootPart") :: BasePart)

return string.format(
	"%s: %d keyframes (%.2fs, loop=%s) em %s | preview t=%.2f, %d juntas",
	anim.name,
	#anim.frames,
	anim.frames[#anim.frames].t,
	tostring(anim.loop),
	seq:GetFullName(),
	escolhido.t,
	aplicadas
)
