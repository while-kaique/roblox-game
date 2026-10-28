---
name: create-roblox-game
description: Orquestrador para features grandes ou um jogo/modo novo — pesquisa do gênero e do loop principal, plano de tarefas, execução em ordem chamando as skills especializadas (code, 3d-asset, animation, vfx, audio, ui, map) e playtest final via MCP. Use quando o pedido envolver várias áreas ao mesmo tempo (ex.: "cria uma arma nova completa", "faz um modo arena").
---

> **⚠️ REPOSITÓRIO APOSENTADO (28/10/2026).** O certo é **https://github.com/while-kaique/babau-piece**. Leia `MIGROU-PARA-BABAU-PIECE.md` antes de qualquer coisa e migre o que houver de novo neste PC para lá.


# Orquestrador

## 1. Pesquisa (curta)
- Gênero e referências: 2–3 jogos Roblox populares do gênero (WebSearch se necessário). O que prende o jogador?
- Defina o **core loop** em 1 frase (ex.: "pular entre ilhas com Geppo → coletar orbes → comprar mais cargas").
- Liste o que já existe no projeto e pode ser reaproveitado (Geppo, UIKit, SoundLibrary, VFXBlocks, JumpPhysics).

## 2. Plano
Escreva a lista de tarefas, uma por skill, com critério de pronto:
| # | Tarefa | Skill | Pronto quando |
|---|---|---|---|
| 1 | números + regras | roblox-code | specs verdes no `check.ps1` |
| 2 | modelo 3D | roblox-3d-asset | `robloxOk`, aparece no Studio |
| 3 | animação | roblox-animation | renders das poses conferidos |
| 4 | VFX | roblox-vfx | Phase Freeze 0.1/0.5/1.0 aprovados |
| 5 | som | roblox-audio | toca no frame do impacto |
| 6 | UI | roblox-ui | auditoria OK nos 4 dispositivos |
| 7 | mapa | roblox-map | validador sem pendências |
Mostre o plano ao usuário antes de executar tarefas que gastam créditos/cota (geração 3D, upload).

## 3. Execução (nesta ordem)
Regras → modelo → animação → VFX → som → UI → mapa. Cada etapa: carregue a skill, siga o fluxo dela, rode `scripts/check.ps1` ao tocar em código.

## 4. Playtest final (MCP)
1. Confirme que o Rojo está sincronizado (`get_project_structure` mostra `ReplicatedStorage.Shared` atualizado).
2. `solo_playtest` → exercite a feature (`simulate_keyboard_input` / `simulate_mouse_input`) → `capture_screenshot`.
3. `get_runtime_logs`: **zero erros** dos nossos scripts. Warnings: explique ou corrija.
4. Se envolver servidor/replicação: `multiplayer_playtest` com 2 clientes.
5. Pare o playtest. Resuma ao usuário o que foi feito, o que foi verificado e o que ficou pendente.

## Ao final
Se algo deu errado e foi corrigido, registre a lição na seção "Lições" da skill responsável.
