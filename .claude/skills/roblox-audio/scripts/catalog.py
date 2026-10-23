"""Mantém a biblioteca local de áudio e gera src/shared/SoundCatalog.luau.

Uso:
  python catalog.py scan      # acha arquivos novos em assets/audio/<categoria>/ e adiciona ao catalog.json
  python catalog.py build     # gera SoundCatalog.luau com os sons que já têm assetId
  python catalog.py list [categoria]
  python catalog.py set-id <nome> <assetId>   # depois de subir o arquivo

Só stdlib. O catálogo é a fonte da verdade; SoundCatalog.luau é gerado (não edite à mão).
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
AUDIO_DIR = ROOT / "assets" / "audio"
CATALOG = AUDIO_DIR / "catalog.json"
OUT_LUAU = ROOT / "src" / "shared" / "SoundCatalog.luau"
AUDIO_EXTS = {".wav", ".mp3", ".ogg", ".flac"}


def load():
    return json.loads(CATALOG.read_text(encoding="utf-8"))


def save(data):
    CATALOG.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")


def scan():
    data = load()
    known = {s["file"] for s in data["sounds"] if s.get("file")}
    names = {s["name"] for s in data["sounds"]}
    added = 0
    for path in sorted(AUDIO_DIR.rglob("*")):
        if path.suffix.lower() not in AUDIO_EXTS:
            continue
        rel = path.relative_to(AUDIO_DIR).as_posix()
        if rel in known:
            continue
        category = path.parent.name if path.parent != AUDIO_DIR else "ambiente"
        name = f"{category}_{path.stem}".lower().replace(" ", "_").replace("-", "_")
        if name in names:
            continue
        if category not in data["categories"]:
            data["categories"].append(category)
        data["sounds"].append(
            {
                "name": name,
                "category": category,
                "assetId": None,
                "file": rel,
                "tags": [category],
                "volume": 1,
                "playbackSpeed": 1,
                "pitchJitter": 0.05,
                "effects": {},
            }
        )
        names.add(name)
        added += 1
        print(f"+ {name}  ({rel})")
    save(data)
    print(f"{added} som(ns) novo(s). Sem assetId ainda: suba com scripts/opencloud_upload.py e use set-id.")


def luau_value(value, indent):
    pad = "\t" * indent
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return "{ " + ", ".join(luau_value(v, indent) for v in value) + " }"
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = [f"{pad}\t{k} = {luau_value(v, indent + 1)}," for k, v in value.items()]
        return "{\n" + "\n".join(lines) + f"\n{pad}}}"
    raise TypeError(type(value))


def build():
    data = load()
    usable = [s for s in data["sounds"] if s.get("assetId")]
    lines = [
        "-- GERADO por .claude/skills/roblox-audio/scripts/catalog.py build — não edite à mão.",
        "-- Fonte: assets/audio/catalog.json",
        "",
        "return {",
    ]
    for s in sorted(usable, key=lambda s: s["name"]):
        entry = {
            "category": s["category"],
            "assetId": s["assetId"],
            "volume": s.get("volume", 1),
            "playbackSpeed": s.get("playbackSpeed", 1),
            "pitchJitter": s.get("pitchJitter", 0),
            "tags": s.get("tags", []),
        }
        if s.get("effects"):
            entry["effects"] = s["effects"]
        lines.append(f"\t[{json.dumps(s['name'])}] = {luau_value(entry, 1)},")
    lines.append("}")
    OUT_LUAU.write_text("\n".join(lines) + "\n", encoding="utf-8")
    pending = len(data["sounds"]) - len(usable)
    print(f"SoundCatalog.luau: {len(usable)} som(ns). {pending} sem assetId (fora do catálogo do jogo).")


def list_sounds(category=None):
    for s in load()["sounds"]:
        if category and s["category"] != category:
            continue
        status = s["assetId"] or "NÃO ENVIADO"
        print(f"{s['category']:<10} {s['name']:<30} {status}  tags={','.join(s.get('tags', []))}")


def set_id(name, asset_id):
    data = load()
    for s in data["sounds"]:
        if s["name"] == name:
            s["assetId"] = int(asset_id)
            save(data)
            print(f"{name} -> {asset_id}")
            return
    sys.exit(f"som '{name}' não encontrado")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "scan":
        scan()
    elif cmd == "build":
        build()
    elif cmd == "list":
        list_sounds(sys.argv[2] if len(sys.argv) > 2 else None)
    elif cmd == "set-id":
        set_id(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
