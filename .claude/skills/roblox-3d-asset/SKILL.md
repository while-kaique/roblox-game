---
name: roblox-3d-asset
description: Gerar modelos 3D para o jogo (armas, props, itens) a partir de texto — Flux (Cloudflare) → Hi3DGen (GPU Kaggle) → decimação + bake no Blender headless → upload Open Cloud — respeitando o limite de 20k triângulos do Roblox. Use quando o jogo precisar de um mesh novo.
---

# Modelo 3D a partir de texto

```
prompt → flux_generate.py → imagem → kaggle_hi3dgen.py → mesh 600k tris (sem cor)
       → blender_optimize.py → FBX ~6k tris + normal map (+ color map) → opencloud_upload.py → assetId
```
Scripts em `.claude/skills/roblox-3d-asset/scripts/`. Arquivos de trabalho em `assets/models/raw/` (ignorado pelo git); resultado final em `assets/models/<nome>/`.

## Credenciais (arquivo `.env` na raiz, ignorado pelo git)
```
CF_ACCOUNT_ID=...        # dash.cloudflare.com → Workers AI
CF_API_TOKEN=...         # token com "Workers AI: Read"
ROBLOX_API_KEY=...       # create.roblox.com/credentials → Assets read+write, IP liberado
ROBLOX_CREATOR_ID=...    # seu userId
```
Kaggle: `%USERPROFILE%\.kaggle\kaggle.json` (conta com telefone verificado para GPU+internet).
Se faltar algo, **pare e peça ao usuário** — não invente chaves.

## Passos
1. **Imagem**: `python .claude/skills/roblox-3d-asset/scripts/flux_generate.py "<objeto>" -o assets/models/raw/<nome>.jpg`
   Olhe a imagem (Read). Precisa: objeto único, inteiro, fundo liso. Senão, gere de novo com `--seed` diferente.
2. **Imagem → 3D**: `python .../kaggle_hi3dgen.py assets/models/raw/<nome>.jpg -o assets/models/raw/<nome>_hi.glb` (10–20 min; rode em background).
3. **Otimizar**: `blender -b -P .../blender_optimize.py -- assets/models/raw/<nome>_hi.glb assets/models/<nome>/<nome>.fbx --target 6000 --tex 1024 --size <studs>`
   Leia o `_report.json`: `robloxOk` precisa ser true. `--target` típico: prop pequeno 1–3k, arma 3–6k, prop grande 6–12k.
4. **Upload**: `python scripts/opencloud_upload.py assets/models/<nome>/<nome>.fbx --type Model --name "<Nome>"` e as texturas com `--type Decal` (ou use o MCP `upload_asset`).
5. **No Studio** (MCP): `insert_asset` com o id → MeshPart + `SurfaceAppearance` (`ColorMap`, `NormalMap`). Screenshot para conferir.

## Atalho sem credenciais
Blender MCP `generate_3d` (texto ou imagem → modelo texturizado, 1–3 min, pode gastar crédito do usuário) → salve como .glb → passo 3. Como já vem com cor, o script também assa o color map.

## Lições
- Hi3DGen gera só geometria (baseado em normais) → sem color map; pinte no Studio (Color/Material) ou use o atalho do generate_3d.
- UV do mesh decimado: Smart Project com ângulo 80° + margem 0.002 + `pack_islands`. Margem 0.02 deixava ~70% da textura vazia.
- `cage_extrusion` 5% da maior dimensão e `max_ray_distance=0`; validado com um plano ondulado (normal map com as listras certas).
- O Flux devolve JPEG.
