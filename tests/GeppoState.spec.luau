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

	t.test("impulso segue o MoveDirection", function()
		local x, y, z = GeppoState.impulse(GeppoConfig, 1, 0)
		t.eq(x, GeppoConfig.ImpulseXZ)
		t.eq(y, GeppoConfig.ImpulseY)
		t.eq(z, 0)
		local _, y2 = GeppoState.impulse(GeppoConfig, 0, 0)
		t.eq(y2, GeppoConfig.ImpulseY, "parado ainda sobe")
	end)
end
