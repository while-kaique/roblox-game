--[[
	EXTRATOR DE BLOCOS DE VFX (rodar no Studio em modo edição via MCP execute_luau)

	Pega um modelo de efeito (ex.: inserido do Toolbox com insert_asset), separa cada
	ParticleEmitter/Beam/Trail em um "bloco" (Attachment + emissores) e classifica
	por categoria em ReplicatedStorage.VFXStaging/<Categoria>/<Nome>.
	Depois, a skill roblox-vfx exporta cada bloco com export_rbxm para
	assets/vfx/<Categoria>/<Nome>.rbxm (o Rojo sincroniza em VFXLibrary) e apaga o staging.

	Beams/Trails mantêm seus Attachments de origem dentro do bloco.
]]

local SOURCE_PATH = "Workspace.InsertedVFX" -- caminho do modelo a extrair
local PREFIX = "" -- prefixo opcional no nome dos blocos
local SOURCE_ASSET_ID = 0 -- id do Toolbox (vai como atributo, para créditos/licença)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function resolve(path: string): Instance
	local node: Instance = game
	for _, piece in string.split(path, ".") do
		local nextNode = if node == game
			then game:FindFirstChild(piece) or game:GetService(piece)
			else node:FindFirstChild(piece)
		assert(nextNode, `não achei "{piece}" em {node:GetFullName()}`)
		node = nextNode
	end
	return node
end

local KEYWORDS = {
	{ "Flames", { "fire", "flame", "burn", "fogo", "chama", "ember" } },
	{ "Smoke", { "smoke", "fumaca", "fog", "dust", "poeira", "cloud" } },
	{ "Shockwaves", { "shock", "wave", "ring", "onda", "anel", "impact" } },
	{ "Sparks", { "spark", "star", "glitter", "faisca", "particle", "shard" } },
	{ "Spheres", { "orb", "sphere", "ball", "glow", "aura", "esfera", "core" } },
	{ "Streaks", { "wind", "slash", "streak", "line", "vento", "speed" } },
}

local function classify(inst: Instance): string
	if inst:IsA("Beam") then
		return "Beams"
	elseif inst:IsA("Trail") then
		return "Trails"
	end
	local text = string.lower(inst.Name .. " " .. (inst.Parent and inst.Parent.Name or ""))
	if inst:IsA("ParticleEmitter") then
		text ..= " " .. string.lower(inst.Texture)
	end
	for _, entry in KEYWORDS do
		for _, word in entry[2] do
			if string.find(text, word, 1, true) then
				return entry[1]
			end
		end
	end
	if inst:IsA("ParticleEmitter") then
		if inst.Orientation == Enum.ParticleOrientation.VelocityParallel then
			return "Streaks"
		elseif inst.Speed.Max < 0.5 then
			return "Spheres"
		end
	end
	return "Misc"
end

local source = resolve(SOURCE_PATH)
local staging = ReplicatedStorage:FindFirstChild("VFXStaging") or Instance.new("Folder")
staging.Name = "VFXStaging"
staging.Parent = ReplicatedStorage

local used: { [string]: number } = {}
local made = {}
for _, inst in source:GetDescendants() do
	if not (inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail")) then
		continue
	end
	local category = classify(inst)
	local folder = staging:FindFirstChild(category) or Instance.new("Folder")
	folder.Name = category
	folder.Parent = staging

	local base = PREFIX .. (inst.Name ~= inst.ClassName and inst.Name or source.Name)
	base = string.gsub(base, "[^%w_]", "")
	used[base] = (used[base] or 0) + 1
	local blockName = if used[base] > 1 then `{base}{used[base]}` else base

	local block = Instance.new("Attachment")
	block.Name = blockName
	block:SetAttribute("SourceAssetId", SOURCE_ASSET_ID)
	block:SetAttribute("SourcePath", inst:GetFullName())
	if inst:IsA("ParticleEmitter") then
		block:SetAttribute("EmitCount", math.clamp(math.floor(inst.Rate * 0.25), 5, 40))
	end

	local copy = inst:Clone()
	if inst:IsA("Beam") or inst:IsA("Trail") then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "A0", "A1"
		local src0 = (inst :: any).Attachment0 :: Attachment?
		local src1 = (inst :: any).Attachment1 :: Attachment?
		if src0 and src1 then
			local offset = src1.WorldPosition - src0.WorldPosition
			a1.Position = offset
		else
			a1.Position = Vector3.new(0, 4, 0)
		end
		a0.Parent, a1.Parent = block, block;
		(copy :: any).Attachment0 = a0;
		(copy :: any).Attachment1 = a1
	end
	copy.Parent = block
	block.Parent = folder
	table.insert(made, `{category}/{blockName}`)
end

return `{#made} bloco(s) em ReplicatedStorage.VFXStaging:\n` .. table.concat(made, "\n")
