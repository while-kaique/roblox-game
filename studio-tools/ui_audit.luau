--[[
	AUDITORIA RESPONSIVA DE UI (rodar durante solo_playtest, via MCP eval_client_runtime)

	Fluxo da skill roblox-ui: para cada dispositivo (celular, tablet, 1080p, 4K)
	  set_device_simulator → este script → capture_screenshot
	Checa toda UI visível no PlayerGui contra as regras do Theme:
	  • botões menores que MinTouchTarget (toque impreciso no celular)
	  • texto renderizado menor que MinTextSize
	  • elementos saindo da tela
	  • botões sobrepostos (toque ambíguo)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UI"):WaitForChild("Theme"))

local viewport = workspace.CurrentCamera.ViewportSize
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
task.wait(0.2) -- deixa o layout recalcular após trocar de dispositivo

local issues = {}
local function issue(kind: string, obj: GuiObject, detail: string)
	table.insert(issues, ("%-12s %s — %s"):format(kind, obj:GetFullName(), detail))
end

local function isVisible(obj: GuiObject): boolean
	local node: Instance? = obj
	while node and node ~= playerGui do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("ScreenGui") and not node.Enabled then
			return false
		end
		node = node.Parent
	end
	return true
end

local buttons: { GuiButton } = {}
local checked = 0
for _, obj in playerGui:GetDescendants() do
	if not obj:IsA("GuiObject") or not isVisible(obj) then
		continue
	end
	checked += 1
	local pos, size = obj.AbsolutePosition, obj.AbsoluteSize

	if obj:IsA("GuiButton") then
		table.insert(buttons, obj)
		if size.X < Theme.MinTouchTarget or size.Y < Theme.MinTouchTarget then
			issue("TOQUE", obj, ("%dx%d px < %d"):format(size.X, size.Y, Theme.MinTouchTarget))
		end
	end

	if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and obj.Text ~= "" then
		local lineCount = math.max(1, #string.split(obj.Text, "\n"))
		local rendered = obj.TextBounds.Y / lineCount
		if rendered > 0 and rendered < Theme.MinTextSize then
			issue("TEXTO", obj, ("%.0f px < %d"):format(rendered, Theme.MinTextSize))
		end
	end

	if size.X > 0 and size.Y > 0 then
		local outX = pos.X < -1 or pos.X + size.X > viewport.X + 1
		local outY = pos.Y < -60 or pos.Y + size.Y > viewport.Y + 1 -- -60: topbar com IgnoreGuiInset
		if outX or outY then
			issue(
				"FORA",
				obj,
				("pos %d,%d tam %dx%d tela %dx%d"):format(pos.X, pos.Y, size.X, size.Y, viewport.X, viewport.Y)
			)
		end
	end
end

local function overlaps(a: GuiObject, b: GuiObject): boolean
	local ap, as, bp, bs = a.AbsolutePosition, a.AbsoluteSize, b.AbsolutePosition, b.AbsoluteSize
	return ap.X < bp.X + bs.X and bp.X < ap.X + as.X and ap.Y < bp.Y + bs.Y and bp.Y < ap.Y + as.Y
end
for i = 1, #buttons do
	for j = i + 1, #buttons do
		local a, b = buttons[i], buttons[j]
		if not a:IsDescendantOf(b) and not b:IsDescendantOf(a) and overlaps(a, b) then
			issue("SOBREPOSTO", a, "colide com " .. b:GetFullName())
		end
	end
end

local header = ("Viewport %dx%d | %d elementos visíveis | %d botões | %d problema(s)"):format(
	viewport.X,
	viewport.Y,
	checked,
	#buttons,
	#issues
)
return header .. (if #issues > 0 then "\n" .. table.concat(issues, "\n") else "\nOK")
