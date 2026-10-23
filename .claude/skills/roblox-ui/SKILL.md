---
name: roblox-ui
description: Criar ou alterar interface (HUD, menus, lojas, botões) com UIKit — Depth Stack automático, animação de botões, e auditoria responsiva em 4 resoluções (celular → 4K) com screenshots via MCP. Use para qualquer trabalho de UI/UX.
---

# UI/UX

## Construir
- Toda UI sai de uma **spec** (tabela Luau) passada para `UIKit.build(spec, parent)` — `src/shared/UI/UIKit.luau`. Exemplo real: `src/client/HUD.client.luau`.
- Tokens visuais em `src/shared/UI/Theme.luau`. Mude cor/borda/sombra lá, nunca inline.
- Kinds: `Panel` (fundo com profundidade), `Button` (profundidade + animação + toque mínimo), `Label`, `Frame` (contêiner/layout).
- **Depth Stack** é automático em Panel/Button: sombra azulada deslocada `ShadowOffset` px, `UIGradient` de cima (clareado) pra baixo (escurecido), `UIStroke` de espessura constante. Não recrie à mão.
- Animação de botão é automática (hover 1.05, press 0.94, release com Back). Para animações de entrada de tela, use TweenService no holder (posição/`UIScale`), nunca no `Body`.
- **Babau Piece usa tamanhos em pixels (Offset)** para HUD (Hotbar 52 px, barras, TP). Siga isso: Scale deixa a peça gigante no 4K e desproporcional ao resto. Para telas baixas (`ViewportSize.Y < 500`), troque para uma versão compacta (ver `GeppoHUD.client.luau`). Scale só para telas cheias/menus.
- Texto sempre `TextScaled` + `UITextSizeConstraint` (o UIKit faz). Não use `TextSize` fixo.

## Prévia + auditoria (obrigatório antes de dar UI como pronta)
1. Sync (Rojo) e `solo_playtest`.
2. Para cada dispositivo — use `capture_device_matrix` se disponível; senão, em loop:
   - `set_device_simulator` (celular ~ iPhone 1170x2532 paisagem, tablet ~ iPad, desktop 1920x1080, 4K 3840x2160)
   - `eval_client_runtime` com o conteúdo de `studio-tools/ui_audit.luau`
   - `capture_screenshot` e **olhe** a imagem
3. Corrija tudo que o relatório marcar:
   - `TOQUE` botão < 44 px → aumente Scale/minSize
   - `TEXTO` < 12 px → aumente o contêiner ou MinTextSize
   - `FORA` → AnchorPoint/Position errados ou tamanho Scale > 1
   - `SOBREPOSTO` → layout/padding
4. Repita até os 4 dispositivos saírem `OK` e os screenshots estarem legíveis. Volte o simulador ao normal e pare o playtest.

## Lições
- `UIKit.applyDepth` coloca a sombra no *holder* (irmão do Body) — por isso todo Panel/Button tem holder transparente + `Body`. Filhos da spec vão no `Body`.
- `IgnoreGuiInset=false` por padrão: a topbar do Roblox ocupa ~58 px no topo.
- Babau Piece: `CharacterAutoLoads=false` → no menu não existe personagem. HUD de gameplay: `gui.Enabled = player.Character ~= nil` (+ CharacterAdded/Removing), senão aparece por cima do menu.
- Ocupação da base da tela no Babau: Hotbar 10–76 px, barras XP/vida à esquerda, TP à direita. Elementos novos no centro-baixo: acima de 88 px.
- Presets do simulador que funcionam: `iphone_14` (LandscapeLeft), `ipad_6th_generation`, `hd_1080`, e 4K = `hd_1080` + `resolution 3840x2160` (só `resolution` sem `deviceId` dá erro).
- `TouchGui` (controles do Roblox) aparece como "FORA" na auditoria — ignore.
