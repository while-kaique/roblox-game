"""Modelo de gerador: copie para generate_<nome>_anim.py e troque NOME/KEYS/MARKERS.

Headless:  blender -b -P animations/scripts/generate_<nome>_anim.py
Ao vivo:   pelo MCP do Blender, p = r"<caminho deste arquivo>"
           exec(open(p, encoding="utf-8").read(), {"__file__": p})

Ângulos em graus nos eixos do ROBLOX, por junta (= CFrame.Angles; espaço da junta = o do
HumanoidRootPart em repouso: X direita, Y cima, -Z frente):
  Ombro/quadril X+   → membro vai para a FRENTE (90 = horizontal à frente)
  Ombro direito Z+   → abre o braço pelo lado (ombro ESQUERDO: Z-)
  Cotovelo X+        → dobra o antebraço para a frente
  Joelho X-          → dobra a perna para trás
  Pescoço Y+         → olha para a esquerda do personagem; Waist Y → torce o tronco
  Root ((rx, ry, rz), (px, py, pz)) → move o corpo todo (py < 0 agacha)
Confira sempre nos renders/`look` antes de exportar.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import r15_lib  # noqa: E402

NOME = "Template_Aceno"
FIM = 24  # frames @24fps
LOOP = False
PRIORIDADE = "Action"  # Idle | Movement | Action | Action2..4
MARKERS = {"Impacto": 12}  # nome → frame (vira KeyframeMarker)

KEYS = {
    0: {"RightShoulder": (0, 0, 0), "RightElbow": (0, 0, 0), "Neck": (0, 0, 0)},
    6: {"RightShoulder": (0, 0, 150), "RightElbow": (0, 0, 20), "Neck": (0, 0, -8)},
    12: {"RightShoulder": (0, 0, 165), "RightElbow": (0, 0, -25)},
    18: {"RightShoulder": (0, 0, 150), "RightElbow": (0, 0, 20)},
    24: {"RightShoulder": (0, 0, 0), "RightElbow": (0, 0, 0), "Neck": (0, 0, 0)},
}


def main():
    arm = r15_lib.build_rig()
    scene = bpy.context.scene
    scene.frame_start, scene.frame_end = 0, FIM
    for frame, poses in sorted(KEYS.items()):
        r15_lib.key(arm, frame, poses)
    r15_lib.export_json(arm, NOME, loop=LOOP, priority=PRIORIDADE, markers=MARKERS)
    if bpy.app.background:
        r15_lib.render_frames(NOME, sorted(KEYS))


main()
