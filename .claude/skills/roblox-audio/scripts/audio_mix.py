"""Combina e modula WAVs locais em um novo SFX (só stdlib).

Use quando a variação em jogo (SoundLibrary: PlaybackSpeed/efeitos) não bastar
e valer a pena gastar 1 upload. Entrada: WAV PCM 8/16/24-bit, mono ou estéreo.
(MP3/OGG: converta antes, ex. `ffmpeg -i x.mp3 x.wav`, se tiver ffmpeg.)

Exemplo — explosão grave + rajada de vento atrasada 80 ms:
  python audio_mix.py -o assets/audio/explosao/geppo_heavy.wav \
      --layer assets/audio/explosao/boom.wav:speed=0.8:gain=-2 \
      --layer assets/audio/vento/rajada.wav:offset=0.08:gain=-6:fadeout=0.3 \
      --normalize -1 --trim 1.2

Opções por camada (separadas por ':'):
  speed=F    reamostra (muda pitch e duração juntos; 0.8 = mais grave/lento)
  gain=dB    volume
  offset=s   começa depois de s segundos
  fadein=s / fadeout=s
  reverse    toca de trás pra frente
"""

import argparse
import array
import math
import sys
import wave

RATE = 44100


def read_wav(path):
    with wave.open(path, "rb") as w:
        ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    if width == 1:
        samples = [(b - 128) / 128 for b in raw]
    elif width == 2:
        a = array.array("h", raw)
        if sys.byteorder == "big":
            a.byteswap()
        samples = [s / 32768 for s in a]
    elif width == 3:
        samples = [int.from_bytes(raw[i : i + 3], "little", signed=True) / 8388608 for i in range(0, len(raw), 3)]
    else:
        sys.exit(f"{path}: WAV de {width * 8} bits não suportado")
    if ch > 1:  # downmix para mono
        samples = [sum(samples[i : i + ch]) / ch for i in range(0, len(samples), ch)]
    if rate != RATE:
        samples = resample(samples, rate / RATE)
    return samples


def resample(samples, step):
    """step > 1 encurta (mais agudo). Interpolação linear."""
    out = []
    pos = 0.0
    last = len(samples) - 1
    while pos < last:
        i = int(pos)
        frac = pos - i
        out.append(samples[i] * (1 - frac) + samples[i + 1] * frac)
        pos += step
    return out


def parse_layer(spec):
    parts = spec.split(":")
    # permite "C:/caminho/arquivo.wav" no Windows
    if len(parts) > 1 and len(parts[0]) == 1 and parts[1].startswith(("/", "\\")):
        parts = [parts[0] + ":" + parts[1]] + parts[2:]
    opts = {"path": parts[0], "speed": 1.0, "gain": 0.0, "offset": 0.0, "fadein": 0.0, "fadeout": 0.0, "reverse": False}
    for p in parts[1:]:
        if p == "reverse":
            opts["reverse"] = True
            continue
        key, _, value = p.partition("=")
        if key not in opts:
            sys.exit(f"opção desconhecida na camada: {key}")
        opts[key] = float(value)
    return opts


def render_layer(o):
    s = read_wav(o["path"])
    if o["speed"] != 1:
        s = resample(s, o["speed"])
    if o["reverse"]:
        s.reverse()
    g = 10 ** (o["gain"] / 20)
    n = len(s)
    fi, fo = int(o["fadein"] * RATE), int(o["fadeout"] * RATE)
    for i in range(n):
        k = g
        if fi and i < fi:
            k *= i / fi
        if fo and i >= n - fo:
            k *= (n - i) / fo
        s[i] *= k
    return [0.0] * int(o["offset"] * RATE) + s


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--layer", action="append", required=True)
    ap.add_argument("--normalize", type=float, default=None, help="pico alvo em dBFS (ex. -1)")
    ap.add_argument("--trim", type=float, default=None, help="corta em N segundos (com fade de 20 ms)")
    args = ap.parse_args()

    layers = [render_layer(parse_layer(spec)) for spec in args.layer]
    mix = [0.0] * max(len(l) for l in layers)
    for l in layers:
        for i, v in enumerate(l):
            mix[i] += v

    if args.trim:
        mix = mix[: int(args.trim * RATE)]
        tail = min(int(0.02 * RATE), len(mix))
        for i in range(tail):
            mix[len(mix) - tail + i] *= 1 - i / tail

    peak = max((abs(v) for v in mix), default=0)
    if args.normalize is not None and peak > 0:
        k = 10 ** (args.normalize / 20) / peak
        mix = [v * k for v in mix]
    elif peak > 1:
        print(f"aviso: pico {20 * math.log10(peak):+.1f} dBFS, limitando para evitar clipping")
        mix = [v / peak for v in mix]

    out = array.array("h", (max(-32768, min(32767, int(v * 32767))) for v in mix))
    if sys.byteorder == "big":
        out.byteswap()
    with wave.open(args.out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(out.tobytes())
    print(f"{args.out}: {len(mix) / RATE:.2f}s, {len(layers)} camada(s)")


if __name__ == "__main__":
    main()
