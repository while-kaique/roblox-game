> **⚠️ REPOSITÓRIO APOSENTADO (28/10/2026).** O certo é **https://github.com/while-kaique/babau-piece**. Leia `MIGROU-PARA-BABAU-PIECE.md` antes de qualquer coisa e migre o que houver de novo neste PC para lá.

# Mudanças feitas direto no Studio (não estão no git)

O Babau Piece tem módulos editados só no Studio (`ReplicatedStorage.Shared`,
`ServerScriptService.Server`, `StarterPlayerScripts.Client`). Estas mudanças vivem no place
(salvar com Ctrl+S; backup em `~/Desktop/BabauPiece.rbxl`).

## 22/10/2026 — Passos ao andar

Problema: o passo ao andar era um som avulso a cada 3,15 studs (~5 passos/s a 16 studs/s),
mais alto que o laço de correr.

- `ReplicatedStorage.Shared.Corrida`: saem `SOM_PASSO`/`VOLUME_PASSO`; entram
  `SOM_ANDAR_DURO` (74849259058998, "Footsteps Concrete Walking Loop"), `SOM_ANDAR_MACIO`
  (79517244477372, "Footsteps Grass Walking Loop"), `VOLUME_ANDAR_DURO` 0.22,
  `VOLUME_ANDAR_MACIO` 0.5 e `CHAO_MACIO` (Grass, LeafyGrass, Ground, Mud, Sand, Snow, Fabric).
  Laços de 8 passos em 3,84 s (~2,1 passos/s); volumes casados pelo pico medido
  (grama 85, concreto 192, corrida 163).
- `StarterPlayerScripts.Client.Controllers.CorridaController`: o passo avulso saiu de
  `pisar()` (que só faz poeira/câmera); em `passo()` o laço de andar faz crossfade com o de
  correr e escolhe grama/concreto pelo `FloorMaterial` (suavizado, `ANDAR_SUAVE` 8).

## 22–23/10/2026 — Animações

- `ServerStorage.AnimacoesGeradas`: KeyframeSequences dos Geppos (cópia de segurança das
  publicadas; regeráveis pelo repo).
