--!strict
--[[
	Números do Geppo (Sky Walk). Tabela pura: sem Instances, sem serviços.
	Lida pelo cliente, pelos testes (lune) e pelo validador de mapas.
	O som fica em SoundCatalog ("geppo").
]]

local GeppoConfig = {
	MaxAirJumps = 5,
	Cooldown = 0.22, -- segundos entre Geppos
	ImpulseY = 58, -- velocidade vertical aplicada (studs/s)
	ImpulseXZ = 42, -- velocidade horizontal na direção do WASD (studs/s)

	-- Momento do impacto do stomp (frame 2 @ 24fps) — sincroniza VFX/SFX com a animação
	ImpactDelay = 0.05,
}

return table.freeze(GeppoConfig)
