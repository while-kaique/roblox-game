--!strict
--[[
	Física de pulo pura, usada pelo validador de mapas (studio-tools/validate_map.luau)
	e pelos testes. Modelo: pulo normal + Geppos encadeados no ápice, velocidade
	horizontal constante = WalkSpeed (conservador: ignora o ImpulseXZ do Geppo).
]]

export type Params = {
	gravity: number, -- workspace.Gravity
	jumpVelocity: number, -- velocidade inicial do pulo do Humanoid
	walkSpeed: number,
	airJumps: number, -- quantos Geppos o jogador pode usar
	airJumpVelocity: number, -- ImpulseY do Geppo
}

local JumpPhysics = {}

-- Converte JumpHeight (UseJumpPower=false) em velocidade inicial.
function JumpPhysics.velocityFromHeight(jumpHeight: number, gravity: number): number
	return math.sqrt(2 * gravity * jumpHeight)
end

function JumpPhysics.apexHeight(velocity: number, gravity: number): number
	return velocity * velocity / (2 * gravity)
end

-- Altura máxima alcançável usando o pulo e todos os Geppos.
function JumpPhysics.maxHeight(p: Params): number
	return JumpPhysics.apexHeight(p.jumpVelocity, p.gravity)
		+ p.airJumps * JumpPhysics.apexHeight(p.airJumpVelocity, p.gravity)
end

-- Tempo no ar para pousar `dh` studs acima (dh < 0 = abaixo) do ponto de partida.
-- Retorna nil se a altura for inalcançável.
function JumpPhysics.airTime(p: Params, dh: number): number?
	local peak = JumpPhysics.maxHeight(p)
	if dh > peak then
		return nil
	end
	local rise = p.jumpVelocity / p.gravity + p.airJumps * (p.airJumpVelocity / p.gravity)
	local fall = math.sqrt(2 * (peak - dh) / p.gravity)
	return rise + fall
end

-- Distância horizontal máxima (borda a borda) para um alvo `dh` studs acima.
function JumpPhysics.maxReach(p: Params, dh: number): number?
	local t = JumpPhysics.airTime(p, dh)
	return if t then t * p.walkSpeed else nil
end

function JumpPhysics.canReach(p: Params, horizontalGap: number, dh: number): boolean
	local reach = JumpPhysics.maxReach(p, dh)
	return reach ~= nil and horizontalGap <= reach
end

return JumpPhysics
