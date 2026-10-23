"""Sobe um arquivo para o Roblox via Open Cloud Assets API (só stdlib).

Variáveis de ambiente (ou arquivo .env na raiz do projeto, que é ignorado pelo git):
  ROBLOX_API_KEY      chave criada em create.roblox.com/credentials com permissão
                      "Assets: read + write" (e o IP liberado)
  ROBLOX_CREATOR_ID   seu userId (ou id do grupo, com --group)

Uso:
  python scripts/opencloud_upload.py assets/models/espada.fbx --type Model --name "Espada"
  python scripts/opencloud_upload.py assets/audio/vento/rajada.ogg --type Audio --name "Rajada"
  python scripts/opencloud_upload.py ui/icone.png --type Decal --name "Ícone"

Imprime o assetId no final (última linha = só o número, fácil de capturar).
Lembre: áudio tem limite mensal de uploads — prefira variar via SoundLibrary.
"""

import argparse
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
API = "https://apis.roblox.com/assets/v1"

CONTENT_TYPES = {
    ".fbx": "model/fbx",
    ".obj": "model/obj",
    ".gltf": "model/gltf+json",
    ".glb": "model/gltf-binary",
    ".rbxm": "model/x-rbxm",
    ".mp3": "audio/mpeg",
    ".ogg": "audio/ogg",
    ".wav": "audio/wav",
    ".flac": "audio/flac",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".bmp": "image/bmp",
    ".tga": "image/tga",
}


def load_env():
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            key, sep, value = line.partition("=")
            if sep and not line.lstrip().startswith("#"):
                os.environ.setdefault(key.strip(), value.strip().strip('"'))


def request(method, url, key, body=None, headers=None):
    req = urllib.request.Request(url, data=body, method=method, headers={"x-api-key": key, **(headers or {})})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code} em {url}: {e.read().decode(errors='replace')}")


def multipart(fields, file_field, file_path, content_type):
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in fields.items():
        parts.append(
            f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n'
            f"Content-Type: application/json\r\n\r\n{value}\r\n".encode()
        )
    parts.append(
        f'--{boundary}\r\nContent-Disposition: form-data; name="{file_field}"; filename="{file_path.name}"\r\n'
        f"Content-Type: {content_type}\r\n\r\n".encode()
    )
    parts.append(file_path.read_bytes())
    parts.append(f"\r\n--{boundary}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", type=Path)
    ap.add_argument("--type", required=True, choices=["Model", "Audio", "Decal", "Image", "Animation"])
    ap.add_argument("--name", required=True)
    ap.add_argument("--description", default="")
    ap.add_argument("--group", action="store_true", help="ROBLOX_CREATOR_ID é um grupo")
    ap.add_argument("--timeout", type=int, default=300)
    args = ap.parse_args()

    load_env()
    key = os.environ.get("ROBLOX_API_KEY")
    creator = os.environ.get("ROBLOX_CREATOR_ID")
    if not key or not creator:
        sys.exit("Defina ROBLOX_API_KEY e ROBLOX_CREATOR_ID (no ambiente ou em .env).")
    if not args.file.exists():
        sys.exit(f"arquivo não existe: {args.file}")

    ctype = CONTENT_TYPES.get(args.file.suffix.lower()) or mimetypes.guess_type(args.file.name)[0]
    if not ctype:
        sys.exit(f"extensão não suportada: {args.file.suffix}")

    creator_key = "groupId" if args.group else "userId"
    meta = {
        "assetType": args.type,
        "displayName": args.name[:50],
        "description": args.description[:1000],
        "creationContext": {"creator": {creator_key: creator}},
    }
    body, content_type = multipart({"request": json.dumps(meta)}, "fileContent", args.file, ctype)
    op = request("POST", f"{API}/assets", key, body, {"Content-Type": content_type})

    op_path = op.get("path") or f"operations/{op.get('operationId')}"
    print(f"enviado, operação {op_path} — aguardando moderação/processamento...")
    deadline = time.time() + args.timeout
    while not op.get("done"):
        if time.time() > deadline:
            sys.exit(f"tempo esgotado; consulte depois: GET {API}/{op_path}")
        time.sleep(2)
        op = request("GET", f"{API}/{op_path}", key)

    if "error" in op:
        sys.exit(f"falhou: {json.dumps(op['error'], ensure_ascii=False)}")
    asset = op.get("response", {})
    asset_id = asset.get("assetId")
    state = asset.get("moderationResult", {}).get("moderationState", "?")
    print(f"ok: {args.name} → rbxassetid://{asset_id} (moderação: {state})")
    print(asset_id)


if __name__ == "__main__":
    main()
