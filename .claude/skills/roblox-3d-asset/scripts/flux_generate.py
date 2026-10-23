"""Texto → imagem 2D do objeto via Cloudflare Workers AI (Flux), só stdlib.

Env (ou .env na raiz): CF_ACCOUNT_ID, CF_API_TOKEN (token com permissão "Workers AI: Read").
Plano gratuito do Workers AI tem cota diária de "neurons" — suficiente para dezenas de imagens.

Uso:
  python flux_generate.py "espada de samurai com cabo vermelho" -o assets/models/raw/espada.jpg
(o Flux devolve JPEG)

O prompt é embrulhado num template que favorece imagem boa para image→3D:
objeto único, centralizado, fundo branco liso, luz neutra, vista 3/4, sem sombra no chão.
"""

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
MODEL = "@cf/black-forest-labs/flux-1-schnell"

TEMPLATE = (
    "{prompt}. Single isolated object, centered, full object visible, three-quarter view, "
    "plain pure white background, soft even studio lighting, no ground shadow, no text, "
    "stylized game asset, clean silhouette, high detail"
)


def load_env():
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            key, sep, value = line.partition("=")
            if sep and not line.lstrip().startswith("#"):
                os.environ.setdefault(key.strip(), value.strip().strip('"'))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("prompt")
    ap.add_argument("-o", "--out", type=Path, required=True)
    ap.add_argument("--steps", type=int, default=8, help="1-8 no flux-1-schnell")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--raw", action="store_true", help="não aplica o template de asset")
    args = ap.parse_args()

    load_env()
    account, token = os.environ.get("CF_ACCOUNT_ID"), os.environ.get("CF_API_TOKEN")
    if not account or not token:
        sys.exit("Defina CF_ACCOUNT_ID e CF_API_TOKEN (no ambiente ou em .env).")

    payload = {"prompt": args.prompt if args.raw else TEMPLATE.format(prompt=args.prompt), "steps": args.steps}
    if args.seed is not None:
        payload["seed"] = args.seed

    req = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/accounts/{account}/ai/run/{MODEL}",
        data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode(errors='replace')}")

    if not data.get("success", True) or "result" not in data:
        sys.exit(f"falhou: {json.dumps(data.get('errors', data), ensure_ascii=False)}")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(base64.b64decode(data["result"]["image"]))
    print(f"imagem salva em {args.out}")


if __name__ == "__main__":
    main()
