# ⚠️ ESTE REPOSITÓRIO FOI APOSENTADO — o certo é `while-kaique/babau-piece`

Em 28/10/2026 tudo daqui (Geppo, VFX, som, UIKit, testes, `animations/`, `studio-tools/`,
`scripts/`, as 8 skills, `docs/`) **e os 165 scripts do place Babau Piece** foram para
**https://github.com/while-kaique/babau-piece** (commits `678321e` e `6e62920` na `master`).
Não faça commit aqui. Não edite script só no Studio.

## Se você é o Claude no outro PC e caiu aqui

1. **Pare** e avise o Kaique em uma linha: "este é o repo antigo; o certo é o babau-piece".
2. **PRIMEIRO, o kit v4 do mapa (urgente):** o place na nuvem não tem as 34 malhas do kit v4
   (Fachada…, Telhado…, Lampiao…, Poco…) nem os 12 MaterialVariants `Babau*`; sem eles a Vila Babau
   vira cubos. Neste PC, no Studio com o place que tem o kit (ou `~/Desktop/BabauPiece.rbxl`):
   exportar `ServerStorage.KitIlhaInicial` e `MaterialService` como `.rbxm` para
   `assets/mapa/` do babau-piece, e devolver os dois ao place (Ctrl+S / Alt+P). Conferir depois na
   lista de versões que o kit está salvo.
3. **Ache o resto que só existe neste PC** (não chegou ao GitHub em 28/10):
   - `git status` e `git log origin/main..HEAD` aqui (mudanças não enviadas);
   - pastas do agente de mapa: `mapas/planos/`, `mapas/estudos/`, `mapas/referencias/`,
     `docs/MAPAS.md` (citados no `IlhaInicial`); `assets/models/`, `animations/exports/`,
     arquivos `.rbxm` de animação; o backup `~/Desktop/BabauPiece.rbxl`.
4. **Clone o certo:** `git clone https://github.com/while-kaique/babau-piece.git` e trabalhe
   numa worktree (`.claude/worktrees/<branch>`), como manda o `CLAUDE.md` de lá.
5. **Copie o que achou nos passos 2 e 3** para os mesmos caminhos lá, faça commit e push numa branch
   e peça ao Kaique para juntar.
6. **Sincronize o Studio pelo repo novo:** `rojo serve` dentro da worktree do babau-piece e
   Connect no plugin do Rojo. O `default.project.json` de lá mapeia tudo (Shared, Server,
   Client, Luta, Luz, MundoRepo…); o build reproduz o place 165/165.
7. **MCPs:** iguais aos daqui, no `.mcp.json` de lá (`robloxstudio` e `blender`).
