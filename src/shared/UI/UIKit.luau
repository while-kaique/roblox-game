--[[
	UIKit — constrói UI a partir de specs (tabelas Luau) com regras fixas:

	  • Depth Stack: todo Panel/Button ganha sombra azulada deslocada, UIGradient
	    sutil de cima pra baixo e UIStroke de espessura constante (Theme).
	  • Botões: animação de hover/press/release automática; tamanho mínimo de toque
	    (Theme.MinTouchTarget) via UISizeConstraint.
	  • Texto: TextScaled sempre com UITextSizeConstraint (MinTextSize), pra não sumir no celular.

	Spec:
	  UIKit.build({
	    kind = "Panel" | "Button" | "Label" | "Frame",
	    name = "...",
	    size = UDim2, position = UDim2, anchor = Vector2,
	    text = "...", color = Color3, aspect = number?,  -- aspect: UIAspectRatioConstraint
	    layout = "Horizontal" | "Vertical"?, padding = number?, gap = number?,
	    minSize = Vector2?, layoutOrder = number?, round = boolean? (Frame),
	    onClick = function?,
	    children = { spec... },
	  }, parent)
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local UIKit = {}

local function lighten(c: Color3, k: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), k)
end

local function darken(c: Color3, k: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), k)
end

local function corner(parent: Instance)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, Theme.CornerRadius)
	c.Parent = parent
end

-- Aplica Depth Stack em `frame` (que precisa estar dentro de um holder sem clipping).
function UIKit.applyDepth(frame: GuiObject, baseColor: Color3)
	corner(frame)

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color =
		ColorSequence.new(lighten(baseColor, Theme.GradientTopTint), darken(baseColor, Theme.GradientBottomShade))
	gradient.Parent = frame
	frame.BackgroundColor3 = Color3.new(1, 1, 1) -- o gradiente define a cor

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = Theme.StrokeThickness
	stroke.Color = Theme.StrokeColor
	stroke.Transparency = Theme.StrokeTransparency
	stroke.Parent = frame

	local shadow = Instance.new("Frame")
	shadow.Name = "DepthShadow"
	shadow.BackgroundColor3 = Theme.ShadowColor
	shadow.BackgroundTransparency = Theme.ShadowTransparency
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(0, Theme.ShadowOffset)
	shadow.ZIndex = frame.ZIndex - 1
	corner(shadow)
	return shadow
end

local function textConstraint(label: TextLabel | TextButton, maxSize: number?)
	label.TextScaled = true
	local c = Instance.new("UITextSizeConstraint")
	c.MinTextSize = Theme.MinTextSize
	c.MaxTextSize = maxSize or 48
	c.Parent = label
end

local function animateButton(button: GuiButton, scale: UIScale)
	local quick = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local bounce = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, quick, { Scale = 1.05 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, quick, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, quick, { Scale = 0.94 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, bounce, { Scale = 1 }):Play()
	end)
end

local function applyCommon(inst: GuiObject, spec)
	inst.Name = spec.name or spec.kind
	inst.Size = spec.size or UDim2.fromScale(1, 1)
	inst.Position = spec.position or UDim2.new()
	inst.AnchorPoint = spec.anchor or Vector2.zero
	inst.BorderSizePixel = 0
	if spec.aspect then
		local a = Instance.new("UIAspectRatioConstraint")
		a.AspectRatio = spec.aspect
		a.Parent = inst
	end
	if spec.layoutOrder then
		inst.LayoutOrder = spec.layoutOrder
	end
	if spec.minSize then
		local c = Instance.new("UISizeConstraint")
		c.MinSize = spec.minSize
		c.Parent = inst
	end
end

local function applyLayout(inst: GuiObject, spec)
	if spec.padding then
		local p = Instance.new("UIPadding")
		local u = UDim.new(0, spec.padding)
		p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = u, u, u, u
		p.Parent = inst
	end
	if spec.layout then
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection[spec.layout]
		l.Padding = UDim.new(0, spec.gap or 6)
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Parent = inst
	end
end

-- Panel/Button = holder transparente (posição/tamanho) + Body (visual) + DepthShadow.
local function buildDepthHolder(spec, parent: Instance, isButton: boolean): (Frame, GuiObject)
	local holder = Instance.new("Frame")
	applyCommon(holder, spec)
	holder.BackgroundTransparency = 1
	holder:SetAttribute("UIKitKind", spec.kind)

	local body: GuiObject
	if isButton then
		local b = Instance.new("TextButton")
		b.AutoButtonColor = false
		b.Text = spec.text or ""
		b.Font = Theme.Font
		b.TextColor3 = Theme.Text
		textConstraint(b, spec.maxTextSize)
		body = b
	else
		body = Instance.new("Frame")
	end
	body.Name = "Body"
	body.Size = UDim2.fromScale(1, 1)
	body.BorderSizePixel = 0
	body.ZIndex = 2
	body.Parent = holder

	local shadow = UIKit.applyDepth(body, spec.color or (if isButton then Theme.SurfaceRaised else Theme.Surface))
	shadow.Parent = holder

	if isButton then
		local min = Instance.new("UISizeConstraint")
		min.MinSize = Vector2.new(Theme.MinTouchTarget, Theme.MinTouchTarget)
		min.Parent = holder
		local scale = Instance.new("UIScale")
		scale.Parent = holder
		animateButton(body :: TextButton, scale)
		if spec.onClick then
			(body :: TextButton).Activated:Connect(spec.onClick)
		end
	end
	applyLayout(body, spec)
	holder.Parent = parent
	return holder, body
end

function UIKit.build(spec, parent: Instance): GuiObject
	local root: GuiObject, content: GuiObject
	if spec.kind == "Panel" then
		root, content = buildDepthHolder(spec, parent, false)
	elseif spec.kind == "Button" then
		root, content = buildDepthHolder(spec, parent, true)
	elseif spec.kind == "Label" then
		local l = Instance.new("TextLabel")
		applyCommon(l, spec)
		l.BackgroundTransparency = 1
		l.Text = spec.text or ""
		l.Font = spec.font or Theme.Font
		l.TextColor3 = spec.color or Theme.Text
		textConstraint(l, spec.maxTextSize)
		l.Parent = parent
		root, content = l, l
	elseif spec.kind == "Frame" then
		local f = Instance.new("Frame")
		applyCommon(f, spec)
		f.BackgroundTransparency = if spec.color then 0 else 1
		f.BackgroundColor3 = spec.color or Color3.new()
		if spec.round then
			corner(f)
		end
		applyLayout(f, spec)
		f.Parent = parent
		root, content = f, f
	else
		error(`UIKit: kind desconhecido "{spec.kind}"`)
	end

	for _, child in spec.children or {} do
		UIKit.build(child, content)
	end
	return root
end

function UIKit.screen(name: string, playerGui: Instance): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	return gui
end

return UIKit
