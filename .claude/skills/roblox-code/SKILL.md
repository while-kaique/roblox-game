---
name: roblox-code
description: Escrever ou alterar código Luau do jogo (mecânicas, habilidades, regras, configs) com o pipeline pré-Studio de 4 passos (rojo build, selene, stylua, testes lune). Use para qualquer mudança em src/ ou tests/.
---

# Engenharia de código Luau

## Onde cada coisa vive
| O quê | Onde | Regra |
|---|---|---|
| Números (dano, cooldown, velocidade, preço) | `src/shared/<Feature>Config.luau` | tabela pura + `table.freeze`, nada de Instance |
| Regras/estado | `src/shared/<Feature>State.luau` | **puro**: sem `game`, sem Instance, recebe config e tempo por parâmetro → testável no lune |
| Efeitos | `src/shared/<Feature>VFX.luau` | usa `VFXUtil` (tween/cleanup/delay) para o Phase Freeze funcionar |
| Cliente | `src/client/*.client.luau` | só liga input/Humanoid → State → VFX/animação |
| Servidor | `src/server/*.server.luau` | (crie a pasta e mapeie em `default.project.json` quando precisar) |
| Testes | `tests/<Módulo>.spec.luau` | `return function(t) t.test(...) end` |

Mapeamento Rojo em `default.project.json`. **O Babau Piece já tem 28+ módulos em `ReplicatedStorage.Shared` que NÃO estão neste repo.** Por isso `Shared` é mapeado módulo a módulo (`$className: Folder` + `$ignoreUnknownInstances: true`). Nunca troque por `"$path": "src/shared"` — o Rojo apagaria os módulos do jogo. Arquivo novo em `src/shared/` → adicione a entrada no project.json.
Sem o plugin do Rojo conectado: `rojo build scripts/mcp-sync.project.json -o build/GeppoSync.rbxm` → MCP `import_rbxm` (e mova as peças com `execute_luau`).

## Fluxo
1. Números novos → Config. Lógica nova → módulo puro + spec em `tests/`.
2. Rode o pipeline: `powershell -ExecutionPolicy Bypass -File scripts/check.ps1 -Fix`
   - `rojo build` (estrutura), `selene` (lint com API real do Roblox), `stylua` (formato), `lune run tests/run`
   - Só siga com tudo verde.
3. Sync: o usuário roda `rojo serve` e conecta o plugin no Studio (ou rode `rojo serve` em background e peça para ele clicar em Connect).
4. Playtest via MCP: `solo_playtest` → (Babau: clique em "Zarpar" no menu) → `get_runtime_logs` → procure erros/warnings dos seus scripts. Para input: `simulate_keyboard_input`. Mudanças no código só valem depois de parar e reiniciar o playtest.
   - Para medir comportamento rápido (pulo, efeitos), instale um gravador com `eval_client_runtime` (`_G.Rec` + Heartbeat), aja, e leia depois — a latência entre chamadas MCP é maior que um pulo.
5. Pare o playtest antes de editar de novo.

## Lições (não repita)
- **Enum é `Enum.ParticleOrientation`**, não `ParticleEmitterOrientation` (o v3.0 do Geppo quebrava por isso; o selene pega se `roblox.yml` estiver atualizado — `check.ps1` gera se faltar).
- Motor6D no R15 vive **dentro da parte filha** (`RightUpperLeg.RightHip`), nunca em `RightFoot.Parent`.
- Comparação de tempo com float: use tolerância (`1.22 - 1 = 0.2199999…`). Ver `GeppoState.canJump`.
- `table.freeze` só congela o 1º nível.
- Lune `require` é relativo ao arquivo (`"../src/shared/X"`); módulos testados não podem dar `require(script.Parent...)`.
- Rokit instala as ferramentas em `%USERPROFILE%\.rokit\bin` (já no PATH do usuário; em shells antigos, prefixe o PATH como o `check.ps1` faz).
