--[[
	Runner de testes fora do Studio: `lune run tests/run`
	Cada tests/*.spec.luau retorna function(t) e usa t.test / t.eq / t.near / t.ok.
	Só testa módulos PUROS (sem Instances/serviços).
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local passed, failed = 0, 0
local current = ""

local t = {}

function t.test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		print(`  FALHOU  {current} › {name}\n          {err}`)
	end
end

function t.ok(cond: any, msg: string?)
	if not cond then
		error(msg or "esperava verdadeiro", 2)
	end
end

function t.eq(actual: any, expected: any, msg: string?)
	if actual ~= expected then
		error(`{msg or ""} esperado {tostring(expected)}, veio {tostring(actual)}`, 2)
	end
end

function t.near(actual: number, expected: number, eps: number?, msg: string?)
	if math.abs(actual - expected) > (eps or 1e-6) then
		error(`{msg or ""} esperado ≈{expected}, veio {actual}`, 2)
	end
end

local files = fs.readDir("tests")
table.sort(files)
for _, file in files do
	if string.match(file, "%.spec%.luau$") then
		current = file
		local spec = require(`./{string.gsub(file, "%.luau$", "")}`)
		spec(t)
	end
end

print(`{passed} passaram, {failed} falharam`)
process.exit(if failed > 0 then 1 else 0)
