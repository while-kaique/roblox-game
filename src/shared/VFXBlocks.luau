--[[
	Blocos de VFX reutilizáveis vindos de ReplicatedStorage.VFXLibrary
	(sincronizado de assets/vfx/<Categoria>/<Nome>.rbxm pelo Rojo).

	Cada bloco é um Attachment com ParticleEmitters/Beams/Trails dentro, extraído
	por studio-tools/extract_vfx.luau. Categorias: Spheres, Beams, Trails, Flames,
	Smoke, Sparks, Shockwaves, Streaks, Misc.

	VFXBlocks.play("Sparks", "BlueBurst", cframe, { emit = 20, lifetime = 1 })
	VFXBlocks.list() → { Sparks = {"BlueBurst", ...}, ... }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXUtil = require(script.Parent.VFXUtil)

export type Options = {
	emit: number?, -- partículas por emitter (padrão: atributo EmitCount do bloco ou 15)
	lifetime: number?, -- segundos até limpar (padrão: maior Lifetime.Max + 0.2)
	scale: number?, -- multiplica Size das partículas
	color: Color3?, -- sobrescreve a cor
}

local VFXBlocks = {}

local function library(): Instance
	return ReplicatedStorage:WaitForChild("VFXLibrary")
end

function VFXBlocks.get(category: string, name: string): Instance
	local cat = library():FindFirstChild(category)
	assert(cat, `VFXBlocks: categoria "{category}" não existe`)
	local block = cat:FindFirstChild(name)
	assert(block, `VFXBlocks: bloco "{category}/{name}" não existe`)
	return block
end

function VFXBlocks.list(): { [string]: { string } }
	local result = {}
	for _, cat in library():GetChildren() do
		local names = {}
		for _, block in cat:GetChildren() do
			table.insert(names, block.Name)
		end
		table.sort(names)
		result[cat.Name] = names
	end
	return result
end

local function scaleSequence(seq: NumberSequence, k: number): NumberSequence
	local kps = {}
	for _, kp in seq.Keypoints do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * k, kp.Envelope * k))
	end
	return NumberSequence.new(kps)
end

-- Toca o bloco num ponto fixo do mundo. Retorna o Part-âncora (já com cleanup agendado).
function VFXBlocks.play(category: string, name: string, cframe: CFrame, opts: Options?): BasePart
	local o: Options = opts or {}
	local anchor = VFXUtil.ghostPart({ Transparency = 1, Size = Vector3.one * 0.2, CFrame = cframe })
	local block = VFXBlocks.get(category, name):Clone()
	block.Parent = anchor
	-- Attachment só funciona com pai BasePart: sobe A0/A1 dos Beams/Trails para o âncora
	for _, child in block:GetChildren() do
		if child:IsA("Attachment") then
			child.Parent = anchor
		end
	end

	local maxLife = 0
	for _, inst in block:GetDescendants() do
		if inst:IsA("ParticleEmitter") then
			if o.scale then
				inst.Size = scaleSequence(inst.Size, o.scale)
			end
			if o.color then
				inst.Color = ColorSequence.new(o.color)
			end
			maxLife = math.max(maxLife, inst.Lifetime.Max)
			inst.Enabled = false
			inst:Emit(o.emit or block:GetAttribute("EmitCount") or 15)
		elseif inst:IsA("Beam") or inst:IsA("Trail") then
			inst.Enabled = true
			maxLife = math.max(maxLife, 0.5)
		end
	end
	VFXUtil.cleanup(anchor, o.lifetime or maxLife + 0.2)
	return anchor
end

return VFXBlocks
