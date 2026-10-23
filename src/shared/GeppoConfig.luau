--!strict
--[[
	Números do Geppo (Sky Walk). Tabela pura: sem Instances, sem serviços.
	Lida pelo cliente, pelos testes (lune) e pelo validador de mapas.
	O som fica em SoundCatalog ("geppo").

	Ativação: toque DUPLO de Espaço (1 toque = pulo normal). A direção vem do input relativo
	à câmera no momento do toque: nada/S = para cima, W = frente, A/D = lados.
]]

local GeppoConfig = {
	MaxAirJumps = 5,
	Cooldown = 0.22, -- segundos entre Geppos
	DoubleTapWindow = 0.3, -- 2º toque de Espaço até isso depois do 1º = Geppo
	-- Segurar o Espaço que disparou um Geppo = os próximos saem sozinhos colados no FIM do atual
	-- (fim do dash / topo do de cima), menos esta antecipação: aproveita 100% da distância sem
	-- começar a cair. Até acabar as cargas; pousar ou soltar desarma. (GeppoState.autoInterval)
	AutoRepeatLead = 0.02,
	InputDeadzone = 0.3, -- abaixo disso (input 0–1) é Geppo para cima

	-- Para cima: balístico. +35% de altura por Geppo (22/10): 58 → 58·√1,35 ≈ 67,4
	-- (sobe 8,6 → 11,6 studs; topo em 0,34 s com gravidade 196,2).
	ImpulseY = 67.4,

	-- Frente e lados: linha reta por DashTime (gravidade anulada), depois cai. 56 × 0,3 =
	-- 16,8 studs ≈ +35% do alcance horizontal antigo (42 studs/s até o topo ≈ 12,4).
	DashTime = 0.3,
	DashSpeed = 56, -- studs/s na direção
	-- studs/s para cima durante o dash: 4,3 studs por dash (+20% em 23/10: segurando para o lado
	-- quase não subia), ainda bem menos que os 11,6 do de cima.
	DashRise = 14.4,
	DashCarry = 0.35, -- fração da velocidade horizontal que sobra ao soltar (não para seco)

	-- Momento do impacto (marker "Impacto" das animações, 0,05 s) — sincroniza VFX/SFX
	ImpactDelay = 0.05,

	-- Animações (animations/scripts/generate_geppo_anims.py). Teste de uma versão nova sem
	-- publicar: id temporário no atributo "GeppoAnim<Tipo>Teste" do personagem (vence este).
	-- Publicadas em 23/10/2026 via Open Cloud (conta 3465482970).
	Animations = {
		Up = "rbxassetid://97374111326760", -- GeppoCima
		Forward = "rbxassetid://109202297432592", -- GeppoFrente
		Right = "rbxassetid://114666450546323", -- GeppoDireita
		Left = "rbxassetid://75599356215537", -- GeppoEsquerda
	},
	AnimFadeIn = 0.05, -- entrada a partir da queda (encolher aparece inteiro)
	-- Geppo seguido: crossfade mais longo, a trilha nova passa pelo encolher quase sem peso
	-- (com 0,05 o braço ia do alto ao encolher em 2 quadros: 57°/quadro).
	AnimChainFade = 0.1,
	AnimReleaseFade = 0.15, -- no marker "Soltar" (0,30 s = fim do dash): mistura com a queda
	AnimFadeOut = 0.12, -- ao pousar
}

return table.freeze(GeppoConfig)
