--[[
	VALIDADOR DE MAPA (rodar no Studio em modo edição via MCP execute_luau)

	Lê WalkSpeed/Jump do StarterPlayer, workspace.Gravity e o GeppoConfig, monta o
	grafo de plataformas alcançáveis e checa com raycasts:
	  • plataformas inalcançáveis a partir do spawn
	  • plataformas que só são alcançáveis usando Geppo
	  • becos sem saída (dá pra chegar, mas não dá pra voltar ao spawn)
	  • teto baixo (personagem não cabe / pulo limitado)
	  • bordas sobre o vazio
	  • linhas de visão: abertas demais ou fechadas demais
	Retorna um relatório em texto.

	Plataformas: partes com a tag "Platform" (CollectionService). Se não houver
	nenhuma, usa toda BasePart ancorada + CanCollide dentro de MAP_ROOT.
	Objetivos (não contam como beco): tag "Goal".
]]

local CONFIG = {
	MAP_ROOT = workspace, -- ou workspace.Map
	MIN_PLATFORM_SIZE = 2, -- studs (X e Z)
	CHARACTER_HEIGHT = 5.5, -- R15 padrão
	EYE_HEIGHT = 5,
	VOID_DEPTH = 500,
	MAX_SIGHT_SAMPLES = 40,
	SIGHT_TOO_OPEN = 0.85, -- fração de pares com visão livre
	SIGHT_TOO_CLOSED = 0.10,
	MAX_LIST = 15, -- itens listados por categoria
}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:FindFirstChild("Shared")
assert(Shared, "ReplicatedStorage.Shared não existe — o Rojo está sincronizado?")
local JumpPhysics = require(Shared.JumpPhysics)
local GeppoConfig = require(Shared.GeppoConfig)

local gravity = workspace.Gravity
local jumpVelocity = if StarterPlayer.CharacterUseJumpPower
	then StarterPlayer.CharacterJumpPower
	else JumpPhysics.velocityFromHeight(StarterPlayer.CharacterJumpHeight, gravity)

local withGeppo = {
	gravity = gravity,
	jumpVelocity = jumpVelocity,
	walkSpeed = StarterPlayer.CharacterWalkSpeed,
	airJumps = GeppoConfig.MaxAirJumps,
	airJumpVelocity = GeppoConfig.ImpulseY,
}
local noGeppo = table.clone(withGeppo)
noGeppo.airJumps = 0

-- ── Coleta de plataformas ────────────────────────────────────────────────────
type Node = { part: BasePart, min: Vector3, max: Vector3, top: number, center: Vector3, goal: boolean }

local function aabb(part: BasePart): (Vector3, Vector3)
	local cf, s = part.CFrame, part.Size / 2
	local r = cf.RightVector * s.X
	local u = cf.UpVector * s.Y
	local l = cf.LookVector * s.Z
	local ext = Vector3.new(
		math.abs(r.X) + math.abs(u.X) + math.abs(l.X),
		math.abs(r.Y) + math.abs(u.Y) + math.abs(l.Y),
		math.abs(r.Z) + math.abs(u.Z) + math.abs(l.Z)
	)
	return cf.Position - ext, cf.Position + ext
end

local parts: { BasePart } = {}
local tagged = CollectionService:GetTagged("Platform")
if #tagged > 0 then
	for _, p in tagged do
		if p:IsA("BasePart") then
			table.insert(parts, p)
		end
	end
else
	for _, p in CONFIG.MAP_ROOT:GetDescendants() do
		if
			p:IsA("BasePart")
			and p.Anchored
			and p.CanCollide
			and p.Transparency < 1
			and not p.Parent:FindFirstChildOfClass("Humanoid")
		then
			table.insert(parts, p)
		end
	end
end

local nodes: { Node } = {}
local nodeOf: { [BasePart]: number } = {}
for _, p in parts do
	local mn, mx = aabb(p)
	if mx.X - mn.X >= CONFIG.MIN_PLATFORM_SIZE and mx.Z - mn.Z >= CONFIG.MIN_PLATFORM_SIZE then
		table.insert(nodes, {
			part = p,
			min = mn,
			max = mx,
			top = mx.Y,
			center = Vector3.new((mn.X + mx.X) / 2, mx.Y, (mn.Z + mx.Z) / 2),
			goal = CollectionService:HasTag(p, "Goal"),
		})
		nodeOf[p] = #nodes
	end
end

local lines = {}
local function out(s: string)
	table.insert(lines, s)
end
local function name(n: Node): string
	return n.part:GetFullName()
end

out(
	("Física: gravidade %.1f | pulo v0 %.1f (apex %.1f) | WalkSpeed %d | Geppo %dx v=%d"):format(
		gravity,
		jumpVelocity,
		JumpPhysics.apexHeight(jumpVelocity, gravity),
		withGeppo.walkSpeed,
		withGeppo.airJumps,
		withGeppo.airJumpVelocity
	)
)
out(
	("Altura máx: %.1f sem Geppo, %.1f com Geppo | alcance horizontal no mesmo nível: %.1f / %.1f"):format(
		JumpPhysics.maxHeight(noGeppo),
		JumpPhysics.maxHeight(withGeppo),
		JumpPhysics.maxReach(noGeppo, 0) or 0,
		JumpPhysics.maxReach(withGeppo, 0) or 0
	)
)
out(`Plataformas analisadas: {#nodes}` .. (if #tagged > 0 then " (tag Platform)" else " (auto)"))
if #nodes > 800 then
	out("AVISO: muitas plataformas; use a tag Platform para limitar a análise.")
end

-- ── Grafo de alcance ─────────────────────────────────────────────────────────
local function gap(a: Node, b: Node): number
	local dx = math.max(0, a.min.X - b.max.X, b.min.X - a.max.X)
	local dz = math.max(0, a.min.Z - b.max.Z, b.min.Z - a.max.Z)
	return math.sqrt(dx * dx + dz * dz)
end

local function buildGraph(params)
	local adj = {}
	for i, a in nodes do
		adj[i] = {}
		for j, b in nodes do
			if i ~= j and JumpPhysics.canReach(params, gap(a, b), b.top - a.top) then
				table.insert(adj[i], j)
			end
		end
	end
	return adj
end

local function bfs(adj, starts: { number }): { [number]: boolean }
	local seen, queue = {}, table.clone(starts)
	for _, s in starts do
		seen[s] = true
	end
	while #queue > 0 do
		local i = table.remove(queue, 1) :: number
		for _, j in adj[i] do
			if not seen[j] then
				seen[j] = true
				table.insert(queue, j)
			end
		end
	end
	return seen
end

-- Spawns: a própria SpawnLocation (se for plataforma) ou o que estiver logo abaixo dela
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local starts = {}
for _, sp in workspace:GetDescendants() do
	if sp:IsA("SpawnLocation") then
		local idx = nodeOf[sp]
		if not idx then
			local hit = workspace:Raycast(sp.Position, Vector3.new(0, -50, 0), rayParams)
			idx = hit and nodeOf[hit.Instance :: BasePart]
		end
		if idx then
			table.insert(starts, idx)
		end
	end
end
if #starts == 0 then
	out("ERRO: nenhuma SpawnLocation sobre uma plataforma — não dá pra analisar alcance.")
	return table.concat(lines, "\n")
end

local adjG, adjN = buildGraph(withGeppo), buildGraph(noGeppo)
local reachG, reachN = bfs(adjG, starts), bfs(adjN, starts)

-- Grafo reverso para "consegue voltar ao spawn?"
local rev = {}
for i in nodes do
	rev[i] = {}
end
for i, list in adjG do
	for _, j in list do
		table.insert(rev[j], i)
	end
end
local canReturn = bfs(rev, starts)

local function listOut(title: string, items: { string })
	out(`\n[{#items}] {title}`)
	for k = 1, math.min(#items, CONFIG.MAX_LIST) do
		out("  - " .. items[k])
	end
	if #items > CONFIG.MAX_LIST then
		out(`  ... +{#items - CONFIG.MAX_LIST}`)
	end
end

local unreachable, geppoOnly, deadEnds = {}, {}, {}
for i, n in nodes do
	if not reachG[i] then
		table.insert(unreachable, name(n))
	elseif not reachN[i] then
		table.insert(geppoOnly, name(n))
	end
	if reachG[i] and not canReturn[i] and not n.goal then
		table.insert(deadEnds, name(n))
	end
end
listOut("INALCANÇÁVEIS a partir do spawn (mesmo com Geppo)", unreachable)
listOut("só alcançáveis USANDO GEPPO (confira se é intencional)", geppoOnly)
listOut("BECOS SEM SAÍDA (chega, mas não volta ao spawn; marque com tag Goal se for objetivo)", deadEnds)

-- ── Teto e vazio ─────────────────────────────────────────────────────────────
local lowCeiling, limitedJump, voidEdges = {}, {}, {}
local apex = JumpPhysics.apexHeight(jumpVelocity, gravity)
for _, n in nodes do
	rayParams.FilterDescendantsInstances = { n.part }
	local up = workspace:Raycast(
		n.center + Vector3.new(0, 0.1, 0),
		Vector3.new(0, apex + CONFIG.CHARACTER_HEIGHT, 0),
		rayParams
	)
	if up then
		local clearance = up.Position.Y - n.top
		if clearance < CONFIG.CHARACTER_HEIGHT then
			table.insert(lowCeiling, ("%s (%.1f studs)"):format(name(n), clearance))
		else
			table.insert(limitedJump, ("%s (%.1f studs)"):format(name(n), clearance))
		end
	end
	local edges = {
		Vector3.new(n.min.X - 1, n.top, n.center.Z),
		Vector3.new(n.max.X + 1, n.top, n.center.Z),
		Vector3.new(n.center.X, n.top, n.min.Z - 1),
		Vector3.new(n.center.X, n.top, n.max.Z + 1),
	}
	local voids = 0
	for _, e in edges do
		if not workspace:Raycast(e, Vector3.new(0, -CONFIG.VOID_DEPTH, 0), rayParams) then
			voids += 1
		end
	end
	if voids > 0 then
		table.insert(voidEdges, `{name(n)} ({voids}/4 lados)`)
	end
end
rayParams.FilterDescendantsInstances = {}
listOut("TETO BAIXO: personagem não cabe em pé", lowCeiling)
listOut("teto limita o pulo (abaixo do ápice)", limitedJump)
listOut("bordas sobre o VAZIO (queda mortal — ok se intencional)", voidEdges)

-- ── Linhas de visão ──────────────────────────────────────────────────────────
local sample = {}
local step = math.max(1, math.floor(#nodes / CONFIG.MAX_SIGHT_SAMPLES))
for i = 1, #nodes, step do
	table.insert(sample, nodes[i])
end
local pairsTotal, open = 0, 0
for i = 1, #sample do
	for j = i + 1, #sample do
		local a = sample[i].center + Vector3.new(0, CONFIG.EYE_HEIGHT, 0)
		local b = sample[j].center + Vector3.new(0, CONFIG.EYE_HEIGHT, 0)
		pairsTotal += 1
		rayParams.FilterDescendantsInstances = { sample[i].part, sample[j].part }
		if not workspace:Raycast(a, b - a, rayParams) then
			open += 1
		end
	end
end
if pairsTotal > 0 then
	local frac = open / pairsTotal
	local verdict = if frac > CONFIG.SIGHT_TOO_OPEN
		then "ABERTO DEMAIS (pouca cobertura, tudo visível)"
		elseif frac < CONFIG.SIGHT_TOO_CLOSED then "FECHADO DEMAIS (labiríntico, difícil se orientar)"
		else "equilibrado"
	out(("\nLinhas de visão: %.0f%% livres em %d pares → %s"):format(frac * 100, pairsTotal, verdict))
end

return table.concat(lines, "\n")
