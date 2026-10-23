---
name: roblox-animation
description: Criar animações R15 (habilidades, golpes, poses) via Blender headless com Python — keyframes por script, curvas Bezier, foot-planting, export FBX e renders de verificação por frame. Use para qualquer animação corporal de personagem.
---

# Animação R15 (Blender)

Guia completo: `ANIMATION_GUIDE.md`. Gerador de referência: `animations/scripts/generate_geppo_anim.py` (rig R15, keyframes, refinamento de curvas, export FBX, renders).

## Fluxo
1. Planeje as fases em frames @24fps (antecipação → impacto → follow-through → recuperação). Anote o frame de impacto: é nele que VFX/SFX disparam (`<Feature>Config.ImpactDelay`).
2. Copie o gerador do Geppo como base: `animations/scripts/generate_<nome>_anim.py`. Troque só a tabela de keyframes e o nome do export.
3. Rode headless: `blender -b -P animations/scripts/generate_<nome>_anim.py`
4. **Verifique os renders** de cada pose-chave em `animations/exports/` (Read nas imagens). Pose errada → ajuste e rode de novo. Não entregue sem olhar.
5. Import no Studio: Animation Editor → Import FBX → publicar → `rbxassetid` no Config. (Ou mantenha procedural via Motor6D C0, como o `GeppoController` faz.)
6. Sincronize com VFX (skill roblox-vfx) e valide com Phase Freeze.

## Lições
- Motor6D do R15 fica na parte filha (`RightUpperLeg.RightHip`). Ver `GeppoController.client.luau`.
- Impacto de anime = 1–2 frames de snap (tangente quase vertical), recuperação com ease-out longo.
- Foot-planting: trave a posição absoluta do pé no impacto enquanto o root sobe.
- Com Blender MCP conectado, `look` permite inspecionar a cena ao vivo em vez de renderizar.
