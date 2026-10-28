---
name: roblox-map
description: Construir ou revisar mapas/fases jogáveis — gera layout a partir da física real do personagem (WalkSpeed, pulo, Geppo) e valida com raycasting (alcance entre plataformas, becos sem saída, teto baixo, quedas, linhas de visão). Use ao criar ou mudar qualquer mapa/obby/arena.
---

> **⚠️ REPOSITÓRIO APOSENTADO (28/10/2026).** O certo é **https://github.com/while-kaique/babau-piece**. Leia `MIGROU-PARA-BABAU-PIECE.md` antes de qualquer coisa e migre o que houver de novo neste PC para lá.


# Mapas jogáveis

## Física de referência (não chute números)
`src/shared/JumpPhysics.luau` + `GeppoConfig` + `StarterPlayer` (WalkSpeed/JumpHeight/JumpPower) + `workspace.Gravity`.
Para planejar, calcule no lune ou de cabeça com as fórmulas do módulo:
- altura do pulo = v0²/2g · altura com Geppo = + n·(58²/2g) ≈ +8.6 studs por Geppo
- alcance no mesmo nível = WalkSpeed · tempo no ar
Projete vãos em **3 faixas**: fácil (≤60% do alcance sem Geppo), médio (60–90%), "exige Geppo" (intencional e sinalizado).

## Construir
- Mapa dentro de `workspace.Map` (Model/Folder). Plataformas: partes ancoradas com tag `Platform` (CollectionService). Objetivos/finais: tag `Goal`.
- Construa via MCP `execute_luau` (crie partes por código, com nomes descritivos) — repetível e versionável. Para salvar o mapa no repositório: `export_rbxm` de `workspace.Map` → `assets/maps/<nome>.rbxm`.

## Validar (obrigatório)
1. `execute_luau` com o conteúdo de `studio-tools/validate_map.luau` (ajuste `CONFIG.MAP_ROOT`).
2. Leia o relatório:
   - **INALCANÇÁVEIS** → aproxime/abaixe a plataforma ou adicione degrau
   - **só com Geppo** → confirme se é intencional; senão, ajuste
   - **BECOS SEM SAÍDA** → adicione saída ou marque `Goal`
   - **TETO BAIXO** → personagem trava; suba o teto (≥ 5.5 studs livres)
   - **VAZIO** → ok em obby; em arena, coloque parede/chão
   - **Linhas de visão**: arena PvP mira 30–70%; obby pode ser aberto
3. Corrija, rode de novo até limpar. Depois, `solo_playtest` + screenshot do spawn e de 2–3 pontos críticos.

## Lições
- O modelo de alcance é conservador (velocidade horizontal = WalkSpeed, Geppo encadeado no ápice). Se o playtest mostrar que dá pra pular mais, ainda assim mantenha o mapa dentro do modelo.
- Sem tag `Platform`, o validador pega toda parte ancorada com colisão — paredes viram "plataformas". Em mapas grandes, use a tag.
