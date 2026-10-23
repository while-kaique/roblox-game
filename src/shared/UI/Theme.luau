--!strict
-- Tokens visuais da UI. Mudar aqui muda o jogo inteiro.

local Theme = {
	Font = Enum.Font.GothamBold,
	BodyFont = Enum.Font.Gotham,

	Surface = Color3.fromRGB(28, 32, 44),
	SurfaceRaised = Color3.fromRGB(40, 46, 62),
	Accent = Color3.fromRGB(120, 200, 255),
	Text = Color3.fromRGB(240, 244, 255),
	TextMuted = Color3.fromRGB(160, 170, 190),

	-- Depth Stack: sombra azulada + gradiente de cima pra baixo + borda constante
	ShadowColor = Color3.fromRGB(10, 20, 45),
	ShadowTransparency = 0.45,
	ShadowOffset = 4, -- px para baixo
	GradientTopTint = 0.10, -- clareia o topo (mistura com branco)
	GradientBottomShade = 0.18, -- escurece a base
	StrokeThickness = 2,
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.82,
	CornerRadius = 10,

	-- Regras de responsividade (validadas por studio-tools/ui_audit.luau)
	MinTouchTarget = 44, -- px (Apple HIG / Material: 44-48)
	MinTextSize = 12, -- px
}

return table.freeze(Theme)
