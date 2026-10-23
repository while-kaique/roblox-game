--!strict
--[[
	Regras do Geppo sem dependência do Roblox (testável com `lune run tests`).
	O cliente só traduz eventos do Humanoid/input para estas chamadas.
]]

export type Config = {
	MaxAirJumps: number,
	Cooldown: number,
	DoubleTapWindow: number,
	AutoRepeatLead: number,
	DashTime: number,
	InputDeadzone: number,
	ImpulseY: number,
	DashSpeed: number,
	DashRise: number,
}

export type Kind = "Up" | "Forward" | "Right" | "Left"

export type State = {
	config: Config,
	airJumpsLeft: number,
	lastJumpTime: number,
	lastTapTime: number,
	isMidAir: boolean,
	autoRepeat: boolean, -- Espaço segurado depois de disparar um Geppo
	lastKind: Kind, -- tipo do último Geppo (define quando o próximo automático sai)
}

local GeppoState = {}

function GeppoState.new(config: Config): State
	return {
		config = config,
		airJumpsLeft = config.MaxAirJumps,
		lastJumpTime = -math.huge,
		lastTapTime = -math.huge,
		isMidAir = false,
		autoRepeat = false,
		lastKind = "Up",
	}
end

function GeppoState.onGrounded(state: State)
	state.airJumpsLeft = state.config.MaxAirJumps
	state.isMidAir = false
	-- Segurando ao pousar não vira Geppo na próxima queda: só um novo toque duplo arma.
	state.autoRepeat = false
end

function GeppoState.onAirborne(state: State)
	state.isMidAir = true
end

-- Tolerância para erro de ponto flutuante (1.22 - 1 = 0.2199999...)
local EPSILON = 1e-9

-- Um toque de Espaço. true = fechou um toque duplo (o par é consumido: o 3º toque começa
-- um par novo, então segurar/martelar não dispara Geppo a cada toque).
function GeppoState.tap(state: State, now: number): boolean
	local double = now - state.lastTapTime <= state.config.DoubleTapWindow + EPSILON
	state.lastTapTime = if double then -math.huge else now
	return double
end

-- Um toque de Espaço vira Geppo? O 1º do voo precisa de toque duplo (1 toque = pulo normal);
-- depois de um Geppo, até pousar, qualquer toque já é Geppo (sem martelar duplo no ar).
function GeppoState.press(state: State, now: number): boolean
	if state.isMidAir and state.airJumpsLeft < state.config.MaxAirJumps then
		state.lastTapTime = -math.huge
		return true
	end
	return GeppoState.tap(state, now)
end

function GeppoState.canJump(state: State, now: number): boolean
	return state.isMidAir and state.airJumpsLeft > 0 and now - state.lastJumpTime >= state.config.Cooldown - EPSILON
end

-- Consome um Geppo. Retorna false se não for permitido agora.
function GeppoState.tryJump(state: State, now: number, kind: Kind?): boolean
	if not GeppoState.canJump(state, now) then
		return false
	end
	state.lastJumpTime = now
	state.airJumpsLeft -= 1
	state.lastKind = kind or "Up"
	return true
end

-- Quanto o Geppo de um tipo "dura" até o ponto em que o próximo automático deve sair: o fim
-- do dash (frente/lados) ou o topo do balístico (cima, ImpulseY / gravidade), menos a
-- antecipação. Nem corta o avanço cedo nem deixa começar a cair.
function GeppoState.autoInterval(config: Config, kind: Kind, gravity: number): number
	local fim = if kind == "Up" then config.ImpulseY / gravity else config.DashTime
	return fim - config.AutoRepeatLead
end

-- Segurar: o toque que disparou um Geppo arma a repetição; soltar desarma.
function GeppoState.holdStart(state: State)
	state.autoRepeat = state.airJumpsLeft > 0
end

function GeppoState.holdEnd(state: State)
	state.autoRepeat = false
end

-- Chamar todo quadro enquanto armado: true = hora do próximo Geppo automático. Acabou a
-- carga, desarma (não fica esperando o pouso para disparar).
function GeppoState.autoReady(state: State, now: number, gravity: number): boolean
	if not state.autoRepeat then
		return false
	end
	if state.airJumpsLeft <= 0 or not state.isMidAir then
		state.autoRepeat = false
		return false
	end
	local intervalo = GeppoState.autoInterval(state.config, state.lastKind, gravity)
	return now - state.lastJumpTime >= intervalo - EPSILON
end

-- Tipo do Geppo pelo input relativo à câmera: forward = MoveDirection · frente da câmera,
-- right = MoveDirection · direita da câmera (no plano). Trás conta como "para cima".
function GeppoState.classify(config: Config, forward: number, right: number): Kind
	if math.max(math.abs(forward), math.abs(right)) < config.InputDeadzone then
		return "Up"
	end
	if math.abs(forward) >= math.abs(right) then
		return if forward > 0 then "Forward" else "Up"
	end
	return if right > 0 then "Right" else "Left"
end

-- Velocidade do Geppo. (lookX, lookZ) e (rightX, rightZ) = frente e direita da câmera no
-- plano, unitárias. Retorna vx, vy, vz e se é dash (linha reta sem gravidade).
function GeppoState.velocity(
	config: Config,
	kind: Kind,
	lookX: number,
	lookZ: number,
	rightX: number,
	rightZ: number
): (number, number, number, boolean)
	if kind == "Up" then
		return 0, config.ImpulseY, 0, false
	end
	local dx, dz = lookX, lookZ
	if kind == "Right" then
		dx, dz = rightX, rightZ
	elseif kind == "Left" then
		dx, dz = -rightX, -rightZ
	end
	return dx * config.DashSpeed, config.DashRise, dz * config.DashSpeed, true
end

return GeppoState
