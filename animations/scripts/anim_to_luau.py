"""Gera o studio-tools/anim_import.luau pronto para uma animação → build/anim_import_<nome>.luau.

    python animations/scripts/anim_to_luau.py <nome> [--t 0.25] [--mode import|clear] [--embed]

Padrão: o script busca o .anim.json no servidor local (fica pequeno, ~5 KB):
    python -m http.server 8765 --bind 127.0.0.1 --directory animations/exports
--embed cola o JSON dentro do script (sem servidor; ~30 KB para 0,5 s @ 60 fps).
O arquivo gerado vai inteiro no execute_luau do MCP (Studio em modo edição).
"""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("nome")
    ap.add_argument("--t", type=float, default=0, help="tempo do preview (s); -1 = último quadro")
    ap.add_argument("--mode", default="import", choices=["import", "clear"])
    ap.add_argument("--embed", action="store_true", help="cola o JSON no script")
    args = ap.parse_args()

    json_path = ROOT / "animations" / "exports" / f"{args.nome}.anim.json"
    trocas = {
        "__ANIM_NOME__": args.nome,
        'local MODE = "import"': f'local MODE = "{args.mode}"',
        "local PREVIEW_T = 0 ": f"local PREVIEW_T = {args.t} ",
    }
    if args.mode == "import":
        data = json_path.read_text(encoding="utf-8")
        json.loads(data)  # falha cedo se o JSON estiver quebrado
        if args.embed:
            if "]==]" in data:
                raise SystemExit("JSON contém ]==]; não dá para embutir")
            trocas["__ANIM_JSON__"] = data
    src = (ROOT / "studio-tools" / "anim_import.luau").read_text(encoding="utf-8")
    for antigo, novo in trocas.items():
        if antigo not in src:
            raise SystemExit(f"anim_import.luau mudou: não achei {antigo!r}")
        src = src.replace(antigo, novo, 1)
    out = ROOT / "build" / f"anim_import_{args.nome}.luau"
    out.parent.mkdir(exist_ok=True)
    out.write_text(src, encoding="utf-8")
    print(f"{out} ({len(src) // 1024} KB)")


if __name__ == "__main__":
    main()
