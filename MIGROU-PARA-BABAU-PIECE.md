# ⚠️ ESTE REPOSITÓRIO FOI APOSENTADO — o certo é `while-kaique/babau-piece`

Em 28/10/2026 tudo daqui (Geppo, VFX, som, UIKit, testes, `animations/`, `studio-tools/`,
`scripts/`, as 8 skills, `docs/`) **e os 165 scripts do place Babau Piece** foram para
**https://github.com/while-kaique/babau-piece** (commit `678321e` na `master`).
Não faça commit aqui. Não edite script só no Studio.

## Se você é o Claude no outro PC e caiu aqui

1. **Pare** e avise o Kaique em uma linha: "este é o repo antigo; o certo é o babau-piece".
2. **Ache o que só existe neste PC** (não chegou ao GitHub em 28/10):
   - `git status` e `git log origin/main..HEAD` aqui (mudanças não enviadas);
   - pastas do agente de mapa: `mapas/planos/`, `mapas/estudos/`, `mapas/referencias/`,
     `docs/MAPAS.md` (citados no `IlhaInicial`); `assets/models/`, `animations/exports/`,
     arquivos `.rbxm` de animação; o backup `~/Desktop/BabauPiece.rbxl`.
3. **Clone o certo:** `git clone https://github.com/while-kaique/babau-piece.git` e trabalhe
   numa worktree (`.claude/worktrees/<branch>`), como manda o `CLAUDE.md` de lá.
4. **Copie o que achou no passo 2** para os mesmos caminhos lá, faça commit e push numa branch
   e peça ao Kaique para juntar.
5. **Sincronize o Studio pelo repo novo:** `rojo serve` dentro da worktree do babau-piece e
   Connect no plugin do Rojo. O `default.project.json` de lá mapeia tudo (Shared, Server,
   Client, Luta, Luz, MundoRepo…); o build reproduz o place 165/165.
6. **MCPs:** iguais aos daqui, no `.mcp.json` de lá (`robloxstudio` e `blender`).
