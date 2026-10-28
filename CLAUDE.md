> **⚠️ REPOSITÓRIO APOSENTADO (28/10/2026).** O certo é **https://github.com/while-kaique/babau-piece**. Leia `MIGROU-PARA-BABAU-PIECE.md` antes de qualquer coisa e migre o que houver de novo neste PC para lá.

# Babau Piece — Roblox (Luau + Rojo)

Responda em português. Jogo-alvo: **Babau Piece** (aberto no Studio; backup em `~/Desktop/BabauPiece.rbxl`). `Jogodokaique.rbxl` é um place de teste antigo, ignore.
Este repo cuida de **parte** do jogo: Geppo (pulo no ar), VFX, som, UIKit, física de mapas. O resto do Babau Piece (28 módulos em `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayerScripts.Client`) é editado no Studio e **não** está aqui.

**Regra de ouro do Rojo:** nunca coloque `$path` numa pasta/serviço que já existe no Babau Piece (apagaria o conteúdo). Mapeie módulo por módulo com nomes novos, como em `default.project.json`.

## Estrutura
- `src/` → código Luau sincronizado pelo **Rojo** (`default.project.json`). É a fonte da verdade: não edite scripts direto no Studio.
  - `src/shared/` → `ReplicatedStorage.Shared` (Configs puras, módulos de regra puros, VFX, UI, Sound)
  - `src/client/` → `StarterPlayer.*` (ver mapeamento no project.json)
- `tests/` → specs em lune (só módulos puros). `studio-tools/` → scripts para rodar no Studio via MCP (não são sincronizados).
- `assets/` → `audio/` (biblioteca + catalog.json), `vfx/` (blocos .rbxm → `ReplicatedStorage.VFXLibrary`), `models/`.
- `animations/` → pipeline Blender por código (rig R15 real, geradores, JSON → KeyframeSequence). Método completo: `ANIMATION_GUIDE.md`. `scripts/` → `check.ps1`, `opencloud_upload.py` (publica com a chave do `.env`).
- `docs/` → estado e decisões de cada feature (`GEPPO.md`) e mudanças feitas só no Studio (`STUDIO-FORA-DO-REPO.md`). Atualize ao mexer na feature.
- `tools/` (ignorado) → remodel/injeção antiga. **Obsoleto**, substituído pelo Rojo.

## Antes de entregar qualquer código
`powershell -ExecutionPolicy Bypass -File scripts/check.ps1 -Fix` → rojo build, selene, stylua, testes. Tem que dar "Tudo verde".
Depois: Rojo sync + `solo_playtest` via MCP + `get_runtime_logs` sem erros.

## Skills (carregue a que cobre a tarefa)
`roblox-code` · `roblox-ui` · `roblox-3d-asset` · `roblox-map` · `roblox-vfx` · `roblox-audio` · `roblox-animation` · `create-roblox-game` (orquestra várias)

Quando corrigir um erro não óbvio, registre a lição na seção "Lições" da skill correspondente.

## Ferramentas
Rokit (`rokit.toml`): rojo, selene, stylua, lune — binários em `%USERPROFILE%\.rokit\bin`. Blender 5.2 em `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`. MCPs: `robloxstudio`, `blender`.
Segredos em `.env` (ignorado): `CF_ACCOUNT_ID`, `CF_API_TOKEN`, `ROBLOX_API_KEY`, `ROBLOX_CREATOR_ID`. Kaggle em `~/.kaggle/kaggle.json`.
