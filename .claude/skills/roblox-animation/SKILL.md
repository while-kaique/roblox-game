---
name: roblox-animation
description: Criar animações R15 (habilidades, golpes, poses) via Blender com Python — rig R15 idêntico ao do Roblox, keyframes por script nos eixos do Roblox, export JSON → KeyframeSequence no Studio via MCP (sem FBX nem Animation Editor), preview por cinemática direta e renders de verificação. Use para qualquer animação corporal de personagem.
---

> **⚠️ REPOSITÓRIO APOSENTADO (28/10/2026).** O certo é **https://github.com/while-kaique/babau-piece**. Leia `MIGROU-PARA-BABAU-PIECE.md` antes de qualquer coisa e migre o que houver de novo neste PC para lá.


# Animação R15 (Blender → Studio)

Guia completo do método (passo a passo, eixos, checklist, problemas): `ANIMATION_GUIDE.md`.
Exemplo vivo: `docs/GEPPO.md` + `animations/scripts/generate_geppo_anims.py`.

## Peças
- `animations/rig/r15_rig.json` → rig R15 real (pivôs das juntas, tamanhos), medido no Studio.
- `animations/scripts/r15_lib.py` → `build_rig()`, `key(arm, frame, {junta: (rx, ry, rz)})`,
  `export_json(...)`, `render_frames(...)`. Bones = nomes das JUNTAS do Roblox (Root, Waist,
  Neck, RightShoulder, RightElbow, RightWrist, RightHip, RightKnee, RightAnkle, Left*).
- `animations/scripts/generate_template_anim.py` → modelo de gerador (copie e troque KEYS).
- `animations/scripts/anim_to_luau.py <nome> [--t s]` → `build/anim_import_<nome>.luau`.
- `studio-tools/anim_import.luau` → monta `ServerStorage.AnimacoesGeradas.<nome>` e posa o
  boneco `Workspace.AnimPreview` no tempo pedido.

## Fluxo
1. Planeje as fases em frames @24fps (antecipação → impacto → follow-through → recuperação).
   O frame de impacto vira marker (`MARKERS = {"Impacto": f}`) → VFX/SFX por
   `track:GetMarkerReachedSignal("Impacto")`.
2. `cp generate_template_anim.py generate_<nome>_anim.py`; troque NOME/FIM/LOOP/KEYS/MARKERS.
   Eixos e sinais (graus, = `CFrame.Angles`) estão no docstring do modelo.
3. Rode: ao vivo pelo MCP do Blender (`exec(open(p).read(), {"__file__": p})`, depois `look`
   com `mode="frames"`) ou headless `blender -b --factory-startup -P <script>` (renders em
   `animations/exports/<nome>_fNN.png` — leia as imagens).
4. Suba o servidor local (background): `python -m http.server 8765 --bind 127.0.0.1 --directory
   animations/exports` — o execute_luau roda como plugin e lê localhost, então o script fica com
   ~5 KB em vez de colar o JSON (~30 KB). `python animations/scripts/anim_to_luau.py <nome> --t <s>`
   → Read do `.luau` gerado → `execute_luau` (modo edição) → `selection view` em
   `Workspace.AnimPreview` → `capture_screenshot`. No fim, `--mode clear`.
5. Teste tocando de verdade no playtest: servidor clona a KeyframeSequence para
   ReplicatedStorage; cliente `KeyframeSequenceProvider:RegisterKeyframeSequence(seq)` (id
   temporário). Meça suavidade com um amostrador no Heartbeat: ângulo do membro por quadro (Δ°)
   e `TimePosition@WeightCurrent` das trilhas. Para foto: `track.TimePosition = t;
   AdjustSpeed(0)`, desligue as ScreenGuis e prenda a câmera com `BindToRenderStep`
   (prioridade > Last) — o Babau Piece tem câmera própria que sobrescreve CFrame.
6. Publicar (conta dona do jogo, userId 3465482970, senão não toca): `export_rbxm` da
   KeyframeSequence → `python scripts/opencloud_upload.py build/<nome>.rbxm --type Animation
   --name <nome>` (chave no `.env`, escopo asset read/write; volta "Approved" em segundos).
   O `upload_asset` do MCP falha ("Unknown error"); use o script. Ids do Geppo vão em
   `GeppoConfig.Animations`; os do resto do jogo em `Shared.Assets` (editado no Studio).
   Várias variações (ex.: os 4 Geppos): um gerador com uma tabela de KEYS por animação e
   `espelhar()` para o lado oposto (`generate_geppo_anims.py`).

## Lições
- O R15 atual usa **AnimationConstraint** (não Motor6D) com RigAttachments de rotação
  identidade: Pose.CFrame = Transform no eixo do HumanoidRootPart, pivô no attachment.
  Código que procura `Motor6D` (ex.: `LowerTorso.Root`) não acha nada.
- Em modo edição o AnimationConstraint não é resolvido (é física): escrever `Transform` não
  move o boneco. O preview usa cinemática direta com as partes ancoradas.
- Blender: nunca `wm.read_factory_settings` no Blender aberto (recarrega addons e derruba o MCP).
  `transform_apply()` aplica posição por padrão — passe `location=False`.
- Rotações em QUATERNION: Euler no espaço de um bone inclinado (ombro) interpola fora do eixo e
  o braço "rebola" no meio do movimento.
- `RegisterKeyframeSequence` fica no `KeyframeSequenceProvider` (não no AnimationClipProvider).
- Impacto de anime = 1–2 frames de snap (chaves bem próximas), recuperação com ease-out longo.
- Foot-planting: trave a posição absoluta do pé no impacto enquanto o root sobe.
- O antigo `generate_geppo_anim.py` usa um rig aproximado e FBX; para animação nova use o r15_lib.
- Animação que reinicia rápido (Geppo): `Play` numa trilha que já toca volta ao quadro 0 na hora
  (corte). Use duas trilhas alternadas com crossfade (`GeppoController`). Fade maior no
  encadeado (0,10) faz a trilha nova passar pela antecipação quase sem peso: 57°→34°/quadro.
- Não termine uma animação de ação no neutro (identidade): a pose de baixo (queda do Animate tem
  braços erguidos) não é o neutro, e o fim vira "desce e sobe de novo". Marker "Soltar" +
  `track:Stop(fade)` → mistura direto com a animação de baixo.
- `grep_scripts` do MCP pode estar desatualizado logo após o Rojo sincronizar; confirme com
  `get_script_source`.
- Inclinar o corpo pelo Root leva junto os membros pendurados (frente → braços/pernas vão para
  trás; lado → vão para o lado oposto). Some/subtraia a inclinação no ombro/quadril, senão um
  braço que devia "empurrar para baixo" sobe até a horizontal. Braço colado na cabeça some atrás
  do cabelo na câmera: deixe ~110° no mundo, não 130°+.
- Pose lateral só faz sentido com o corpo de lado para o movimento: o AutoRotate padrão vira o
  boneco para onde ele anda. No dash do Geppo: AutoRotate off + girar o root para a frente da
  câmera (lerp no Heartbeat) enquanto durar.
