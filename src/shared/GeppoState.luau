--!strict
--[[
	Regras do Geppo sem dependência do Roblox (testável com `lune run tests`).
	O cliente só traduz eventos do Humanoid para estas chamadas.
]]

export type Config = {
	MaxAirJumps: number,
	Cooldown: number,
	ImpulseY: number,
	ImpulseXZ: number,
}

export type State = {
	config: Config,
	airJumpsLeft: number,
	lastJumpTime: number,
	isMidAir: boolean,
}

local GeppoState = {}

function GeppoState.new(config: Config): State
	return {
		config = config,
		airJumpsLeft = config.MaxAirJumps,
		lastJumpTime = -math.huge,
		isMidAir = false,
	}
end

function GeppoState.onGrounded(state: State)
	state.airJumpsLeft = state.config.MaxAirJumps
	state.isMidAir = false
end

function GeppoState.onAirborne(state: State)
	state.isMidAir = true
end

-- Tolerância para erro de ponto flutuante (1.22 - 1 = 0.2199999...)
local EPSILON = 1e-9

function GeppoState.canJump(state: State, now: number): boolean
	return state.isMidAir and state.airJumpsLeft > 0 and now - state.lastJumpTime >= state.config.Cooldown - EPSILON
end

-- Consome um Geppo. Retorna false se não for permitido agora.
function GeppoState.tryJump(state: State, now: number): boolean
	if not GeppoState.canJump(state, now) then
		return false
	end
	state.lastJumpTime = now
	state.airJumpsLeft -= 1
	return true
end

-- Velocidade resultante dado o MoveDirection (x, z) do Humanoid.
function GeppoState.impulse(config: Config, moveX: number, moveZ: number): (number, number, number)
	return moveX * config.ImpulseXZ, config.ImpulseY, moveZ * config.ImpulseXZ
end

return GeppoState
