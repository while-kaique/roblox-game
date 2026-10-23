--[[
	HUD: cargas de Geppo restantes (lê o atributo "GeppoCharges" do personagem).
	Construído com UIKit → Depth Stack + regras de responsividade automáticas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIKit = require(Shared:WaitForChild("UI"):WaitForChild("UIKit"))
local Theme = require(Shared.UI:WaitForChild("Theme"))
local GeppoConfig = require(Shared:WaitForChild("GeppoConfig"))

local player = Players.LocalPlayer
local gui = UIKit.screen("GeppoHUD", player:WaitForChild("PlayerGui"))

local pips = {}
for i = 1, GeppoConfig.MaxAirJumps do
	pips[i] = {
		kind = "Frame",
		name = `Pip{i}`,
		size = UDim2.fromScale(0.14, 0.7),
		aspect = 1,
		color = Theme.Accent,
		round = true,
		layoutOrder = i,
	}
end

local panel = UIKit.build({
	kind = "Panel",
	name = "GeppoCharges",
	anchor = Vector2.new(0.5, 1),
	position = UDim2.new(0.5, 0, 1, -88), -- logo acima da Hotbar do Babau Piece (10 + 66 px + folga)
	-- Tamanho em pixels, como o resto da UI do Babau Piece (Scale deixava o HUD gigante no 4K)
	size = UDim2.fromOffset(200, 46),
	padding = 6,
	layout = "Horizontal",
	gap = 6,
	children = {
		{
			kind = "Label",
			name = "Title",
			text = "GEPPO",
			size = UDim2.fromScale(0.3, 0.8),
			layoutOrder = 0,
		},
		{
			kind = "Frame",
			name = "Pips",
			size = UDim2.fromScale(0.65, 1),
			layout = "Horizontal",
			gap = 4,
			layoutOrder = 1,
			children = pips,
		},
	},
}, gui)

-- Telas baixas (celular em paisagem): versão compacta para não encostar nas barras de XP/vida
local camera = workspace.CurrentCamera
local function fitToScreen()
	local compact = camera.ViewportSize.Y < 500
	panel.Size = if compact then UDim2.fromOffset(150, 36) else UDim2.fromOffset(200, 46)
end
fitToScreen()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)

local pipsFrame = panel:WaitForChild("Body"):WaitForChild("Pips")
local fade = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function render(character: Model)
	local charges = character:GetAttribute("GeppoCharges") or GeppoConfig.MaxAirJumps
	for i = 1, GeppoConfig.MaxAirJumps do
		local pip = pipsFrame:FindFirstChild(`Pip{i}`) :: Frame
		TweenService:Create(pip, fade, { BackgroundTransparency = if i <= charges then 0 else 0.8 }):Play()
	end
end

-- Babau Piece usa CharacterAutoLoads=false: sem personagem = jogador ainda no menu → HUD oculto
gui.Enabled = player.Character ~= nil
player.CharacterRemoving:Connect(function()
	gui.Enabled = false
end)

local function bind(character: Model)
	gui.Enabled = true
	render(character)
	character:GetAttributeChangedSignal("GeppoCharges"):Connect(function()
		render(character)
	end)
end

if player.Character then
	bind(player.Character)
end
player.CharacterAdded:Connect(bind)
