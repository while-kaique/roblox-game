---
name: roblox-vfx
description: Criar, coletar e validar efeitos visuais — biblioteca de blocos de VFX extraídos do Toolbox (esferas, feixes, chamas, ondas de choque…) e validação por Phase Freeze (congela o efeito em t=0.1/0.5/1.0s e tira screenshots). Use para qualquer efeito de habilidade, impacto ou ambiente.
---

# VFX

## Montar efeitos
- Código de efeito sempre usa `src/shared/VFXUtil.luau`: `ghostPart`, `tween`, `cleanup`, `delay`, `track`. **Nunca** `TweenService:Create` / `Debris` / `task.delay` direto num efeito — quebra o Phase Freeze.
- Reaproveite blocos: `VFXBlocks.play("Sparks", "Nome", cframe, { emit, scale, color })` (`src/shared/VFXBlocks.luau`). `VFXBlocks.list()` mostra o que existe.
- Referência de qualidade: `src/shared/GeppoVFX.luau` e a seção 7 do `ANIMATION_GUIDE.md` (técnicas Twist VFX: LightEmission=1, Speed 0.01 + VelocityPerpendicular, Speed alto + Drag alto, VelocityParallel, Circular easing, ZOffset).

## Coletar blocos do Toolbox
1. MCP `search_assets` (ex.: "shockwave vfx", "fire particles") → `preview_asset` / `get_asset_thumbnail` → escolha só o que tiver licença livre e sem scripts estranhos.
2. `insert_asset` → renomeie para `Workspace.InsertedVFX`. **Apague qualquer Script/LocalScript que vier junto.**
3. `execute_luau` com `studio-tools/extract_vfx.luau` (ajuste `SOURCE_PATH`, `SOURCE_ASSET_ID`).
4. Revise as categorias em `ReplicatedStorage.VFXStaging`; mova o que foi mal classificado.
5. Para cada bloco: `export_rbxm` → `assets/vfx/<Categoria>/<Nome>.rbxm`. Depois apague `VFXStaging` e `InsertedVFX`. O Rojo sincroniza em `ReplicatedStorage.VFXLibrary`.
6. Crie/atualize `assets/vfx/CREDITS.md` com nome, assetId e autor.

## Validar com Phase Freeze (obrigatório para efeito novo/alterado)
1. Sync + `solo_playtest`.
2. Para PHASE em 0.1, 0.5, 1.0:
   - `eval_client_runtime` com `studio-tools/vfx_phase_freeze.luau` (`MODE="capture"`, `PHASE`, `EFFECT="geppo"` ou `"block:Categoria/Nome"`)
   - `capture_screenshot` → olhe
3. `MODE="release"` no fim.
4. Critérios: t=0.1 impacto legível (flash/forma principal clara), t=0.5 dissipando sem cortes bruscos nem bordas pretas, t=1.0 praticamente limpo (nada "preso" no ar). Compare as 3 imagens como sequência.

## Lições
- Partículas presas a Attachment no pé se movem com o personagem; o freeze ancora o HumanoidRootPart durante a captura.
- `VFXUtil.cleanup` respeita o freeze — se algo some durante o congelamento, alguém usou Debris direto.
- Babau Piece: o jogo abre no menu (sem personagem). Antes do freeze, clique em "Zarpar" (`simulate_mouse_input` ~ centro do card grande) e espere `LocalPlayer.Character`.
- O controlador de câmera do Babau sobrescreve a câmera; `FRAME_CAMERA=false` (padrão).
- Referência validada (Geppo, 2026-10-22): t=0.1 → 18 instâncias (highlight + anel + rajadas); t=0.5 → 5 (anéis quase transparentes); t=1.0 → 1 invisível. Use como régua para efeitos novos.
