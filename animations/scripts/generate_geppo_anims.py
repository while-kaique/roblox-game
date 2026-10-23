"""Geppo — as 4 animações (cima, frente, direita, esquerda), 60 fps, trilha de 0,50 s.

Física (GeppoConfig, Workspace.Gravity 196,2):
  Cima    balístico, ImpulseY 67,4 → topo em ~0,34 s.
  Frente / Direita / Esquerda: dash em linha reta por 0,30 s (DashTime), depois cai.
Linha do tempo comum (frames @60):
  0      neutro (entra com fade a partir da pose atual)
  3      ENCOLHER (0,05 s) — antecipação; marker "Impacto" (VFX/SFX)
  6      IMPULSO  (0,10 s) — pose principal estoura
  12     SUBIDA / PLANO (0,20 s) — mesma pose ainda indo (nunca congela)
  18     SOLTAR   (0,30 s) — marker "Soltar": o GeppoController para a trilha com fade e a
         queda do Animate assume (fim do dash = começo da queda, sem voltar ao neutro)
  30     = quadro 18 (a trilha some por fade antes de acabar)
Esquerda = espelho da direita (Right↔Left, Y/Z das rotações e X das posições trocam de sinal).
Cada tipo tem variante B (perna/braço trocados) para os Geppos seguidos alternarem — ver ANIMS.

Ângulos em graus nos eixos do Roblox (ver generate_template_anim.py). Lembretes:
  Root X- inclina o corpo para a FRENTE; Root Z- inclina para a DIREITA do personagem.
  Inclinar o corpo leva junto os membros pendurados (frente → braços/pernas vão para trás;
  direita → vão para a esquerda): compense no ombro/quadril.

Headless: blender -b --factory-startup -P animations/scripts/generate_geppo_anims.py
Ao vivo (MCP): exec(open(p).read(), {"__file__": p, "SO": "GeppoFrente"})  # só uma, sem render
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import r15_lib  # noqa: E402

FPS = 60
FIM = 30
SOLTAR = 18
MARKERS = {"Impacto": 3, "Soltar": SOLTAR}

JUNTAS = [
    "Waist",
    "Neck",
    "RightShoulder",
    "RightElbow",
    "LeftShoulder",
    "LeftElbow",
    "RightHip",
    "RightKnee",
    "RightAnkle",
    "LeftHip",
    "LeftKnee",
    "LeftAnkle",
]
NEUTRO = {j: (0, 0, 0) for j in JUNTAS}
NEUTRO["Root"] = ((0, 0, 0), (0, 0, 0))

# ── CIMA ─────────────────────────────────────────────────────────────────────────────
# Perna direita estica para baixo, esquerda dobrada no alto, braço direito para o alto
# levemente dobrado, esquerdo reto para baixo, cabeça olha para cima.
CIMA = {
    0: NEUTRO,
    3: {  # encolher: punho direito perto do ombro (caminho curto vindo de um Geppo anterior)
        "Root": ((-8, 0, 0), (0, 0.15, 0)),
        "Waist": (-12, 0, 0),
        "Neck": (-12, 0, 0),
        "RightShoulder": (75, 0, 10),
        "RightElbow": (70, 0, 0),
        "LeftShoulder": (25, 0, -8),
        "LeftElbow": (45, 0, 0),
        "RightHip": (55, 0, 0),
        "RightKnee": (-70, 0, 0),
        "RightAnkle": (-15, 0, 0),
        "LeftHip": (60, 0, 0),
        "LeftKnee": (-75, 0, 0),
        "LeftAnkle": (-15, 0, 0),
    },
    6: {
        "Root": ((0, 0, 0), (0, 0.1, 0)),
        "Waist": (5, 0, 0),
        "Neck": (28, 0, 0),
        "RightShoulder": (158, 0, 12),
        "RightElbow": (22, 0, 0),
        "LeftShoulder": (-12, 0, -6),
        "LeftElbow": (3, 0, 0),
        "RightHip": (-12, 0, 0),
        "RightKnee": (0, 0, 0),
        "RightAnkle": (-35, 0, 0),
        "LeftHip": (85, 0, 0),
        "LeftKnee": (-100, 0, 0),
        "LeftAnkle": (-20, 0, 0),
    },
    12: {
        "Root": ((0, 0, 0), (0, 0.1, 0)),
        "Waist": (7, 0, 0),
        "Neck": (35, 0, 0),
        "RightShoulder": (168, 0, 10),
        "RightElbow": (18, 0, 0),
        "LeftShoulder": (-15, 0, -6),
        "LeftElbow": (2, 0, 0),
        "RightHip": (-15, 0, 0),
        "RightKnee": (-5, 0, 0),
        "RightAnkle": (-40, 0, 0),
        "LeftHip": (90, 0, 0),
        "LeftKnee": (-105, 0, 0),
        "LeftAnkle": (-22, 0, 0),
    },
    SOLTAR: {  # perto do topo (0,34 s): braço abre para o lado para descer pela lateral
        "Root": ((0, 0, 0), (0, 0.05, 0)),
        "Waist": (3, 0, 0),
        "Neck": (22, 0, 0),
        "RightShoulder": (115, 0, 25),
        "RightElbow": (30, 0, 0),
        "LeftShoulder": (-8, 0, -8),
        "LeftElbow": (8, 0, 0),
        "RightHip": (-5, 0, 0),
        "RightKnee": (-15, 0, 0),
        "RightAnkle": (-20, 0, 0),
        "LeftHip": (55, 0, 0),
        "LeftKnee": (-70, 0, 0),
        "LeftAnkle": (-12, 0, 0),
    },
}

# ── FRENTE ───────────────────────────────────────────────────────────────────────────
# Corpo se projeta para a frente (~38°): braço direito alcança à frente, esquerdo vai para
# trás, perna direita chuta o ar para trás (é ela que "pisa": VFX no pé direito), esquerda
# dobrada à frente. Antecipação ao contrário: recua um pouco e puxa os braços para trás.
FRENTE = {
    0: NEUTRO,
    3: {
        "Root": ((6, 0, 0), (0, 0.15, 0)),
        "Waist": (-10, 0, 0),
        "Neck": (-8, 0, 0),
        "RightShoulder": (-30, 0, 10),
        "RightElbow": (40, 0, 0),
        "LeftShoulder": (-30, 0, -10),
        "LeftElbow": (40, 0, 0),
        "RightHip": (60, 0, 0),
        "RightKnee": (-80, 0, 0),
        "RightAnkle": (-15, 0, 0),
        "LeftHip": (55, 0, 0),
        "LeftKnee": (-75, 0, 0),
        "LeftAnkle": (-15, 0, 0),
    },
    6: {
        "Root": ((-30, 0, 0), (0, 0.1, 0)),
        "Waist": (-8, 0, 0),
        "Neck": (30, 0, 0),  # compensa o tronco: olha para onde vai
        "RightShoulder": (145, 0, 8),  # − 38 do tronco ≈ 107° no mundo: à frente, um pouco acima
        "RightElbow": (15, 0, 0),
        "LeftShoulder": (-15, 0, -10),
        "LeftElbow": (10, 0, 0),
        "RightHip": (-20, 0, 0),
        "RightKnee": (0, 0, 0),
        "RightAnkle": (-40, 0, 0),
        "LeftHip": (95, 0, 0),
        "LeftKnee": (-100, 0, 0),
        "LeftAnkle": (-20, 0, 0),
    },
    12: {
        "Root": ((-38, 0, 0), (0, 0.1, 0)),
        "Waist": (-6, 0, 0),
        "Neck": (38, 0, 0),
        "RightShoulder": (150, 0, 6),
        "RightElbow": (12, 0, 0),
        "LeftShoulder": (-20, 0, -10),
        "LeftElbow": (8, 0, 0),
        "RightHip": (-25, 0, 0),
        "RightKnee": (-5, 0, 0),
        "RightAnkle": (-45, 0, 0),
        "LeftHip": (100, 0, 0),
        "LeftKnee": (-105, 0, 0),
        "LeftAnkle": (-22, 0, 0),
    },
    SOLTAR: {
        "Root": ((-22, 0, 0), (0, 0.05, 0)),
        "Waist": (-3, 0, 0),
        "Neck": (22, 0, 0),
        "RightShoulder": (110, 0, 15),
        "RightElbow": (30, 0, 0),
        "LeftShoulder": (-10, 0, -12),
        "LeftElbow": (12, 0, 0),
        "RightHip": (-10, 0, 0),
        "RightKnee": (-20, 0, 0),
        "RightAnkle": (-25, 0, 0),
        "LeftHip": (60, 0, 0),
        "LeftKnee": (-70, 0, 0),
        "LeftAnkle": (-12, 0, 0),
    },
}

# ── DIREITA ──────────────────────────────────────────────────────────────────────────
# Empurra o chão com o lado ESQUERDO e salta para a direita: corpo inclina para a direita,
# ombro direito sobe e o braço direito lidera para cima/fora, braço esquerdo estica para
# baixo/fora "empurrando", perna esquerda estica para baixo/esquerda (VFX no pé esquerdo),
# direita dobra para cima. Cabeça olha para a direita e fica mais em pé que o tronco.
# Antecipação: carrega o peso no lado esquerdo (inclina um pouco para a esquerda).
DIREITA = {
    0: NEUTRO,
    3: {
        "Root": ((0, 0, 8), (0, 0.15, 0)),
        "Waist": (-8, 0, 6),
        "Neck": (-8, 0, -6),
        "RightShoulder": (40, 0, -25),
        "RightElbow": (60, 0, 0),
        "LeftShoulder": (10, 0, -30),
        "LeftElbow": (40, 0, 0),
        "RightHip": (55, 0, 5),
        "RightKnee": (-75, 0, 0),
        "RightAnkle": (-15, 0, 0),
        "LeftHip": (50, 0, -10),
        "LeftKnee": (-70, 0, 0),
        "LeftAnkle": (-15, 0, 0),
    },
    6: {
        "Root": ((0, 0, -28), (0, 0.1, 0)),
        "Waist": (0, 0, -10),
        "Neck": (5, -25, 18),
        "RightShoulder": (20, 0, 148),  # − 38 do tronco ≈ 110° no mundo: para cima/fora, longe da cabeça
        "RightElbow": (20, 0, 0),
        "LeftShoulder": (0, 0, 8),  # o tronco (38°) já joga o braço para fora: fecha p/ ~30° (empurra)
        "LeftElbow": (0, 0, 0),
        "RightHip": (75, 0, 20),
        "RightKnee": (-95, 0, 0),
        "RightAnkle": (-15, 0, 0),
        "LeftHip": (0, 0, -2),
        "LeftKnee": (0, 0, 0),
        "LeftAnkle": (-30, 0, 0),
    },
    12: {
        "Root": ((0, 0, -34), (0, 0.1, 0)),
        "Waist": (0, 0, -12),
        "Neck": (5, -28, 22),
        "RightShoulder": (25, 0, 155),
        "RightElbow": (10, 0, 0),
        "LeftShoulder": (0, 0, 12),
        "LeftElbow": (0, 0, 0),
        "RightHip": (80, 0, 22),
        "RightKnee": (-100, 0, 0),
        "RightAnkle": (-18, 0, 0),
        "LeftHip": (0, 0, -4),
        "LeftKnee": (-3, 0, 0),
        "LeftAnkle": (-35, 0, 0),
    },
    SOLTAR: {
        "Root": ((0, 0, -18), (0, 0.05, 0)),
        "Waist": (0, 0, -6),
        "Neck": (3, -15, 10),
        "RightShoulder": (20, 0, 120),
        "RightElbow": (30, 0, 0),
        "LeftShoulder": (5, 0, -2),
        "LeftElbow": (12, 0, 0),
        "RightHip": (55, 0, 12),
        "RightKnee": (-70, 0, 0),
        "RightAnkle": (-12, 0, 0),
        "LeftHip": (10, 0, -6),
        "LeftKnee": (-20, 0, 0),
        "LeftAnkle": (-20, 0, 0),
    },
}


def espelhar(keys):
    """Direita → esquerda: troca Right/Left e inverte Y/Z das rotações e X das posições."""

    def nome(j):
        if j.startswith("Right"):
            return "Left" + j[5:]
        if j.startswith("Left"):
            return "Right" + j[4:]
        return j

    def valor(v):
        if isinstance(v[0], (tuple, list)):
            (rx, ry, rz), (px, py, pz) = v
            return ((rx, -ry, -rz), (-px, py, pz))
        rx, ry, rz = v
        return (rx, -ry, -rz)

    return {f: {nome(j): valor(v) for j, v in poses.items()} for f, poses in keys.items()}


TRONCO = ("Root", "Waist", "Neck")


def trocar_membros(poses):
    """Só braços/pernas trocam de lado (espelhados); tronco e cabeça ficam como estão."""
    tronco = {j: v for j, v in poses.items() if j in TRONCO}
    membros = espelhar({0: {j: v for j, v in poses.items() if j not in TRONCO}})[0]
    return {**tronco, **membros}


# ── DIREITA B (Geppos alternados) ───────────────────────────────────────────────────
# Mesma inclinação para a direita, mas quem empurra agora é a perna DIREITA (a de dentro,
# esticada para baixo/esquerda sob o corpo; VFX no pé direito), a esquerda dobra no alto, e
# o braço ESQUERDO lidera cruzando por cima da cabeça para a direita (braçada) enquanto o
# direito empurra para baixo. Alternado com a A: "pisou com a esquerda, agora com a direita".
DIREITA_B = {
    0: NEUTRO,
    3: trocar_membros(DIREITA[3]),
    6: {
        "Root": ((0, 0, -28), (0, 0.1, 0)),
        "Waist": (0, 0, -10),
        "Neck": (5, -25, 18),
        "LeftShoulder": (20, 0, 150),  # −38 do tronco ≈ 112° no mundo, cruzando para a direita
        "LeftElbow": (25, 0, 0),
        "RightShoulder": (0, 0, 8),  # o tronco já joga para a esquerda: ~30° para baixo/esquerda
        "RightElbow": (0, 0, 0),
        "LeftHip": (75, 0, 0),
        "LeftKnee": (-95, 0, 0),
        "LeftAnkle": (-15, 0, 0),
        "RightHip": (0, 0, 6),
        "RightKnee": (0, 0, 0),
        "RightAnkle": (-30, 0, 0),
    },
    12: {
        "Root": ((0, 0, -34), (0, 0.1, 0)),
        "Waist": (0, 0, -12),
        "Neck": (5, -28, 22),
        "LeftShoulder": (25, 0, 155),
        "LeftElbow": (15, 0, 0),
        "RightShoulder": (0, 0, 12),
        "RightElbow": (0, 0, 0),
        "LeftHip": (80, 0, 0),
        "LeftKnee": (-100, 0, 0),
        "LeftAnkle": (-18, 0, 0),
        "RightHip": (0, 0, 4),
        "RightKnee": (-3, 0, 0),
        "RightAnkle": (-35, 0, 0),
    },
    SOLTAR: {
        "Root": ((0, 0, -18), (0, 0.05, 0)),
        "Waist": (0, 0, -6),
        "Neck": (3, -15, 10),
        "LeftShoulder": (20, 0, 110),
        "LeftElbow": (30, 0, 0),
        "RightShoulder": (5, 0, 2),
        "RightElbow": (12, 0, 0),
        "LeftHip": (55, 0, 0),
        "LeftKnee": (-70, 0, 0),
        "LeftAnkle": (-12, 0, 0),
        "RightHip": (10, 0, 6),
        "RightKnee": (-20, 0, 0),
        "RightAnkle": (-20, 0, 0),
    },
}

# A = 1º Geppo do voo; B = o seguinte; e alternam (GeppoController). Cima e frente: B é o
# espelho completo. Lados: B troca a perna que empurra e o braço que lidera, sem inverter a
# inclinação (DIREITA_B); a esquerda é o espelho da direita em A e em B.
ANIMS = {
    "GeppoCima": CIMA,
    "GeppoCimaB": espelhar(CIMA),
    "GeppoFrente": FRENTE,
    "GeppoFrenteB": espelhar(FRENTE),
    "GeppoDireita": DIREITA,
    "GeppoDireitaB": DIREITA_B,
    "GeppoEsquerda": espelhar(DIREITA),
    "GeppoEsquerdaB": espelhar(DIREITA_B),
}


def gerar(nome, keys):
    keys = dict(keys)
    keys[FIM] = keys[SOLTAR]
    arm = r15_lib.build_rig()
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start, scene.frame_end = 0, FIM
    for frame, poses in sorted(keys.items()):
        r15_lib.key(arm, frame, poses)
    r15_lib.export_json(arm, nome, loop=False, priority="Action2", markers=MARKERS)
    if bpy.app.background:
        r15_lib.render_frames(nome, [3, 6, 12, SOLTAR])
    return arm


so = globals().get("SO")
for nome_anim, keys_anim in ANIMS.items():
    if so is None or so == nome_anim:
        gerar(nome_anim, keys_anim)
