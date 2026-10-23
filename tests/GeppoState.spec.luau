local GeppoConfig = require("../src/shared/GeppoConfig")
local GeppoState = require("../src/shared/GeppoState")

return function(t)
	t.test("não pula no chão", function()
		local s = GeppoState.new(GeppoConfig)
		t.eq(GeppoState.tryJump(s, 10), false)
	end)

	t.test("consome cargas até zerar", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		local now = 0
		for _ = 1, GeppoConfig.MaxAirJumps do
			t.eq(GeppoState.tryJump(s, now), true)
			now += GeppoConfig.Cooldown
		end
		t.eq(s.airJumpsLeft, 0)
		t.eq(GeppoState.tryJump(s, now + 10), false, "sem cargas")
	end)

	t.test("respeita cooldown", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		t.eq(GeppoState.tryJump(s, 1), true)
		t.eq(GeppoState.tryJump(s, 1 + GeppoConfig.Cooldown * 0.5), false)
		t.eq(GeppoState.tryJump(s, 1 + GeppoConfig.Cooldown), true)
	end)

	t.test("pousar recarrega", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		GeppoState.tryJump(s, 0)
		GeppoState.onGrounded(s)
		t.eq(s.airJumpsLeft, GeppoConfig.MaxAirJumps)
		t.eq(s.isMidAir, false)
	end)

	t.test("um toque só não é Geppo", function()
		local s = GeppoState.new(GeppoConfig)
		t.eq(GeppoState.tap(s, 5), false)
	end)

	t.test("toque duplo dentro da janela é Geppo", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.tap(s, 5)
		t.eq(GeppoState.tap(s, 5 + GeppoConfig.DoubleTapWindow), true)
	end)

	t.test("toque duplo lento não é Geppo", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.tap(s, 5)
		t.eq(GeppoState.tap(s, 5 + GeppoConfig.DoubleTapWindow + 0.05), false)
	end)

	t.test("o par é consumido: 3º toque não dispara de novo, 4º sim", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.tap(s, 1)
		t.eq(GeppoState.tap(s, 1.1), true)
		t.eq(GeppoState.tap(s, 1.2), false)
		t.eq(GeppoState.tap(s, 1.3), true)
	end)

	t.test("1º Geppo pede toque duplo; depois, no ar, um toque basta", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		t.eq(GeppoState.press(s, 1), false, "1 toque no ar sem Geppo antes = nada")
		t.eq(GeppoState.press(s, 1.1), true, "toque duplo")
		GeppoState.tryJump(s, 1.1)
		t.eq(GeppoState.press(s, 3), true, "toque único depois do 1º Geppo")
		GeppoState.tryJump(s, 3)
		t.eq(GeppoState.press(s, 5), true)
	end)

	t.test("pousar volta a exigir toque duplo", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		GeppoState.tryJump(s, 0)
		GeppoState.onGrounded(s)
		GeppoState.onAirborne(s)
		t.eq(GeppoState.press(s, 10), false)
	end)

	t.test("no chão um toque nunca é Geppo", function()
		local s = GeppoState.new(GeppoConfig)
		t.eq(GeppoState.press(s, 1), false)
	end)

	local G = 196.2

	t.test("próximo automático sai colado no fim do atual", function()
		local cima = GeppoState.autoInterval(GeppoConfig, "Up", G)
		local topo = GeppoConfig.ImpulseY / G
		t.ok(cima < topo and cima > topo - 0.05, "antes do topo, bem perto")
		local dash = GeppoState.autoInterval(GeppoConfig, "Forward", G)
		t.ok(dash < GeppoConfig.DashTime and dash > GeppoConfig.DashTime - 0.05, "antes do fim do dash")
		t.eq(GeppoState.autoInterval(GeppoConfig, "Right", G), dash)
		t.ok(math.min(cima, dash) >= GeppoConfig.Cooldown, "nunca menor que o cooldown")
	end)

	t.test("segurar: espera o fim do tipo atual e gasta todas as cargas", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		GeppoState.tryJump(s, 0, "Forward")
		GeppoState.holdStart(s)
		local dash = GeppoState.autoInterval(GeppoConfig, "Forward", G)
		t.eq(GeppoState.autoReady(s, dash - 0.01, G), false, "ainda no dash")
		t.eq(GeppoState.autoReady(s, dash, G), true, "fim do dash")
		local now, feitos = 0, 1
		for _ = 1, 400 do
			now += 1 / 60
			if GeppoState.autoReady(s, now, G) and GeppoState.tryJump(s, now, "Up") then
				feitos += 1
			end
		end
		t.eq(feitos, GeppoConfig.MaxAirJumps, "gasta todas as cargas")
		t.eq(s.autoRepeat, false, "sem carga desarma")
	end)

	t.test("segurar não atravessa o pouso", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		GeppoState.tryJump(s, 0)
		GeppoState.holdStart(s)
		GeppoState.onGrounded(s)
		GeppoState.onAirborne(s)
		t.eq(GeppoState.autoReady(s, 10, G), false)
	end)

	t.test("soltar desarma", function()
		local s = GeppoState.new(GeppoConfig)
		GeppoState.onAirborne(s)
		GeppoState.tryJump(s, 0)
		GeppoState.holdStart(s)
		GeppoState.holdEnd(s)
		t.eq(GeppoState.autoReady(s, 10, G), false)
	end)

	t.test("classifica a direção pelo input da câmera", function()
		t.eq(GeppoState.classify(GeppoConfig, 0, 0), "Up")
		t.eq(GeppoState.classify(GeppoConfig, 0.1, -0.1), "Up", "zona morta")
		t.eq(GeppoState.classify(GeppoConfig, 1, 0), "Forward")
		t.eq(GeppoState.classify(GeppoConfig, -1, 0), "Up", "trás = para cima")
		t.eq(GeppoState.classify(GeppoConfig, 0, 1), "Right")
		t.eq(GeppoState.classify(GeppoConfig, 0, -1), "Left")
		t.eq(GeppoState.classify(GeppoConfig, 0.707, 0.707), "Forward", "diagonal empata na frente")
		t.eq(GeppoState.classify(GeppoConfig, 0.3, -0.9), "Left")
	end)

	t.test("para cima é balístico e reto", function()
		local x, y, z, dash = GeppoState.velocity(GeppoConfig, "Up", 0, -1, 1, 0)
		t.eq(x, 0)
		t.eq(y, GeppoConfig.ImpulseY)
		t.eq(z, 0)
		t.eq(dash, false)
	end)

	t.test("+35% de altura no Geppo para cima", function()
		local g = 196.2
		local antes = 58 ^ 2 / (2 * g)
		t.near(GeppoConfig.ImpulseY ^ 2 / (2 * g) / antes, 1.35, 0.005)
	end)

	t.test("dashes seguem a câmera e sobem pouco", function()
		-- câmera olhando para -Z, direita = +X
		local fx, fy, fz, dash = GeppoState.velocity(GeppoConfig, "Forward", 0, -1, 1, 0)
		t.eq(dash, true)
		t.eq(fx, 0)
		t.eq(fz, -GeppoConfig.DashSpeed)
		t.eq(fy, GeppoConfig.DashRise)
		t.ok(fy < GeppoConfig.ImpulseY, "sobe menos que o de cima")
		local rx, _, rz = GeppoState.velocity(GeppoConfig, "Right", 0, -1, 1, 0)
		t.eq(rx, GeppoConfig.DashSpeed)
		t.eq(rz, 0)
		local lx = GeppoState.velocity(GeppoConfig, "Left", 0, -1, 1, 0)
		t.eq(lx, -GeppoConfig.DashSpeed)
	end)
end
