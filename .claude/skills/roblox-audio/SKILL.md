---
name: roblox-audio
description: Adicionar sons e efeitos sonoros a habilidades, UI e ambiente usando a biblioteca local categorizada (assets/audio) e o SoundLibrary — variando sons já enviados em vez de gastar a cota mensal de upload de áudio. Use sempre que algo precisar de som.
---

# Áudio

## Ordem de preferência (economiza a cota de upload)
1. **Reusar + modular em jogo**: `SoundLibrary.play(nome, parent, { playbackSpeed, volume, pitchJitter, effects = { Reverb = {...}, Equalizer = {...}, Distortion = {...}, PitchShift = {...} } })`. Camadas: `SoundLibrary.layer({a, b}, parent)`.
2. **Combinar arquivos locais** num SFX novo (`audio_mix.py`) e subir **1** arquivo.
3. Último caso: arquivo novo da internet → só com licença livre; anote a fonte nas `tags`.

## Biblioteca
- Arquivos: `assets/audio/<categoria>/<arquivo>.wav|ogg|mp3` (categorias: tiro, explosao, passos, vento, impacto, ui, magia, ambiente).
- Fonte da verdade: `assets/audio/catalog.json`. Gerado (não editar): `src/shared/SoundCatalog.luau`.
- Comandos (`.claude/skills/roblox-audio/scripts/`):
  - `python catalog.py scan` → registra arquivos novos
  - `python catalog.py list [categoria]`
  - `python scripts/opencloud_upload.py <arquivo> --type Audio --name "<nome>"` → `python catalog.py set-id <nome> <assetId>`
  - `python catalog.py build` → regenera `SoundCatalog.luau` (rode o `check.ps1` depois)

## Criar SFX combinando (stdlib, só WAV)
```
python .claude/skills/roblox-audio/scripts/audio_mix.py -o assets/audio/impacto/novo.wav \
  --layer assets/audio/explosao/boom.wav:speed=0.8:gain=-2 \
  --layer assets/audio/vento/rajada.wav:offset=0.08:gain=-6:fadeout=0.3 \
  --normalize -1 --trim 1.2
```
Camada: `speed`, `gain` (dB), `offset` (s), `fadein`, `fadeout`, `reverse`. MP3/OGG → converta para WAV antes (ffmpeg não está instalado; peça ao usuário ou use WAV).

## Sincronizar com a ação
Toque o som no mesmo frame do impacto visual (ex.: `GeppoConfig.ImpactDelay`). Parent no `HumanoidRootPart`/parte da ação para o som ser 3D; UI → `SoundService`.

## Lições
- O som do Geppo é `geppo` (vento): EQ Low/Mid +5, High 0, PlaybackSpeed 1.05.
