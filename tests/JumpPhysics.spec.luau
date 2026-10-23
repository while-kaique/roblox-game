local JumpPhysics = require("../src/shared/JumpPhysics")

local G = 196.2

local function params(airJumps: number)
	return {
		gravity = G,
		jumpVelocity = 50, -- JumpPower padrão
		walkSpeed = 16,
		airJumps = airJumps,
		airJumpVelocity = 58,
	}
end

return function(t)
	t.test("JumpHeight padrão (7.2) ↔ velocidade ≈ 53.1", function()
		local v = JumpPhysics.velocityFromHeight(7.2, G)
		t.near(v, 53.15, 0.01)
		t.near(JumpPhysics.apexHeight(v, G), 7.2, 1e-6)
	end)

	t.test("altura máxima soma os Geppos", function()
		local p = params(5)
		local expected = 50 ^ 2 / (2 * G) + 5 * 58 ^ 2 / (2 * G)
		t.near(JumpPhysics.maxHeight(p), expected)
	end)

	t.test("sem Geppo, 10 studs acima é inalcançável", function()
		t.eq(JumpPhysics.maxReach(params(0), 10), nil)
	end)

	t.test("com Geppo, 10 studs acima é alcançável", function()
		t.ok(JumpPhysics.maxReach(params(1), 10) ~= nil)
	end)

	t.test("mesmo nível: alcance = walkSpeed * 2v/g", function()
		t.near(JumpPhysics.maxReach(params(0), 0) :: number, 16 * 2 * 50 / G, 1e-6)
	end)

	t.test("descer aumenta o alcance", function()
		local p = params(0)
		t.ok((JumpPhysics.maxReach(p, -20) :: number) > (JumpPhysics.maxReach(p, 0) :: number))
	end)

	t.test("canReach respeita o vão", function()
		local p = params(0)
		local r = JumpPhysics.maxReach(p, 0) :: number
		t.eq(JumpPhysics.canReach(p, r - 0.1, 0), true)
		t.eq(JumpPhysics.canReach(p, r + 0.1, 0), false)
	end)
end
