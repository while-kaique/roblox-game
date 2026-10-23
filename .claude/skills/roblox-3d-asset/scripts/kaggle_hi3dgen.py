"""Imagem → mesh 3D high-poly com Hi3DGen rodando na GPU grátis do Kaggle.

Pré-requisitos (uma vez):
  1. Conta Kaggle com telefone verificado (necessário para GPU + internet no kernel)
  2. kaggle.com → Settings → API → "Create New Token" → salve em %USERPROFILE%\\.kaggle\\kaggle.json
  3. python -m pip install --user kaggle   (já instalado neste projeto)

Uso:
  python kaggle_hi3dgen.py assets/models/raw/espada.jpg -o assets/models/raw/espada_hi.glb

O que faz: gera um kernel com a imagem embutida (base64), dá push com GPU+internet,
espera terminar (~10-20 min na 1ª vez por causa do download de pesos), baixa o .glb.
Saída: geometria SEM textura (Hi3DGen é baseado em normais) com ~300-600k triângulos.
Depois rode blender_optimize.py para decimar e assar o normal map.

Cota: ~30 h/semana de GPU grátis no Kaggle.
"""

import argparse
import base64
import json
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

KERNEL_TEMPLATE = r'''
# Gerado por kaggle_hi3dgen.py — roda no Kaggle (GPU T4/P100)
import base64, os, subprocess, sys, glob

def sh(cmd):
    print("$", cmd, flush=True)
    subprocess.run(cmd, shell=True, check=True)

os.chdir("/kaggle/working")
if not os.path.exists("Hi3DGen"):
    sh("git clone --recursive https://github.com/Stable-X/Hi3DGen.git")
os.chdir("Hi3DGen")

# Dependências (README do Hi3DGen; sem gradio)
sh("pip install -q torch==2.4.0 torchvision==0.19.0 --index-url https://download.pytorch.org/whl/cu121")
sh("pip install -q spconv-cu120==2.3.6 xformers==0.0.27.post2")
sh("pip install -q 'diffusers>=0.28.0' accelerate kornia==0.8.0 timm==0.6.7 transformers==4.46.3 "
   "pillow tqdm scipy trimesh numpy==1.26.4 scikit-image opencv-python einops huggingface_hub")

from huggingface_hub import snapshot_download
for repo in ["Stable-X/trellis-normal-v0-1", "Stable-X/yoso-normal-v1-8-1", "ZhengPeng7/BiRefNet"]:
    snapshot_download(repo_id=repo, local_dir=os.path.join("weights", repo.split("/")[-1]))

os.environ["SPCONV_ALGO"] = "native"
sys.path.insert(0, os.getcwd())
import torch
from PIL import Image
from hi3dgen.pipelines import Hi3DGenPipeline

with open("input.png", "wb") as f:
    f.write(base64.b64decode(IMAGE_B64))

pipeline = Hi3DGenPipeline.from_pretrained("weights/trellis-normal-v0-1")
pipeline.cuda()
normal_predictor = torch.hub.load("hugoycj/StableNormal", "StableNormal_turbo", trust_repo=True,
                                  yoso_version="yoso-normal-v1-8-1", local_cache_dir="./weights")

image = pipeline.preprocess_image(Image.open("input.png").convert("RGB"), resolution=1024)
normal = normal_predictor(image, resolution=768, match_input_resolution=True, data_type="object")
normal.save("/kaggle/working/normal_preview.png")

outputs = pipeline.run(
    normal,
    seed=SEED,
    formats=["mesh"],
    preprocess_image=False,
    sparse_structure_sampler_params={"steps": 50, "cfg_strength": 3},
    slat_sampler_params={"steps": 6, "cfg_strength": 3.0},
)
mesh = outputs["mesh"][0].to_trimesh(transform_pose=True)
mesh.export("/kaggle/working/mesh.glb")
print("TRIANGLES", len(mesh.faces))

# Limpa o resto para o output baixar rápido
os.chdir("/kaggle/working")
shutil_targets = [p for p in glob.glob("/kaggle/working/*") if os.path.basename(p) not in ("mesh.glb", "normal_preview.png")]
for p in shutil_targets:
    subprocess.run(["rm", "-rf", p])
'''


def kaggle(*args, capture=False):
    cmd = [sys.executable, "-m", "kaggle", *args]
    if capture:
        return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    subprocess.run(cmd, check=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image", type=Path)
    ap.add_argument("-o", "--out", type=Path, required=True)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--timeout", type=int, default=60 * 60, help="segundos")
    args = ap.parse_args()

    if not (Path.home() / ".kaggle" / "kaggle.json").exists():
        sys.exit("Falta ~/.kaggle/kaggle.json (kaggle.com → Settings → API → Create New Token).")

    user = json.loads((Path.home() / ".kaggle" / "kaggle.json").read_text())["username"]
    slug = "hi3dgen-roblox"
    image_b64 = base64.b64encode(args.image.read_bytes()).decode()
    code = f"IMAGE_B64 = {image_b64!r}\nSEED = {args.seed}\n" + KERNEL_TEMPLATE

    work = Path(tempfile.mkdtemp(prefix="hi3dgen_"))
    (work / "kernel.py").write_text(code, encoding="utf-8")
    (work / "kernel-metadata.json").write_text(
        json.dumps(
            {
                "id": f"{user}/{slug}",
                "title": slug,
                "code_file": "kernel.py",
                "language": "python",
                "kernel_type": "script",
                "is_private": True,
                "enable_gpu": True,
                "enable_internet": True,
                "machine_shape": "NvidiaTeslaT4",
            }
        )
    )

    print(f"push do kernel {user}/{slug} ...")
    kaggle("kernels", "push", "-p", str(work))

    start = time.time()
    status = ""
    while time.time() - start < args.timeout:
        time.sleep(30)
        status = kaggle("kernels", "status", f"{user}/{slug}", capture=True).strip()
        print(f"[{int(time.time() - start)}s] {status}")
        if any(s in status.lower() for s in ("complete", "error", "cancel")):
            break

    out_dir = work / "output"
    out_dir.mkdir(exist_ok=True)
    kaggle("kernels", "output", f"{user}/{slug}", "-p", str(out_dir))

    mesh = out_dir / "mesh.glb"
    if "complete" not in status.lower() or not mesh.exists():
        log = next(out_dir.glob("*.log"), None)
        sys.exit(f"kernel falhou ({status}). Log: {log or out_dir}")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(mesh, args.out)
    preview = out_dir / "normal_preview.png"
    if preview.exists():
        shutil.copy(preview, args.out.with_name(args.out.stem + "_normal.png"))
    print(f"mesh salvo em {args.out}")


if __name__ == "__main__":
    main()
