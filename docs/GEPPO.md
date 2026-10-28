> **⚠️ REPOSITÓRIO APOSENTADO (28/10/2026).** O certo é **https://github.com/while-kaique/babau-piece**. Leia `MIGROU-PARA-BABAU-PIECE.md` antes de qualquer coisa e migre o que houver de novo neste PC para lá.

# Geppo (Sky Walk) — estado, decisões e próximos passos

Atualizado em 23/10/2026. Código: `src/client/GeppoController.client.luau` (input → física →
animação/VFX), `src/shared/GeppoState.luau` (regras puras, testadas em
`tests/GeppoState.spec.luau`), `src/shared/GeppoConfig.luau` (todos os números),
`src/shared/GeppoVFX.luau` (efeitos). Poses: `animations/scripts/generate_geppo_anims.py`.
Pipeline de animação: [ANIMATION_GUIDE.md](../ANIMATION_GUIDE.md).

## Como joga hoje

| Ação | Resultado |
|---|---|
| 1 toque de Espaço no chão | Pulo normal do Roblox (nunca Geppo, mesmo segurando) |
| **Toque duplo** (2º toque até 0,3 s depois do 1º) | 1º Geppo do voo |
| Depois do 1º Geppo, ainda no ar | **Cada toque** de Espaço é um Geppo |
| **Segurar** o toque que disparou um Geppo | Os próximos saem sozinhos, colados no fim do atual, até acabar as cargas |
| Pousar | Recarrega as 5 cargas e volta a exigir toque duplo; segurando ao pousar **não** dispara Geppo |

Direção (lida a cada Geppo, relativa à **câmera**):

| Input | Tipo | Movimento |
|---|---|---|
| nada ou S | **Cima** | Balístico: `ImpulseY` 67,4 → sobe 11,6 studs, topo em 0,34 s |
| W | **Frente** | Dash em linha reta (gravidade anulada) por `DashTime` 0,30 s a 56 studs/s + 14,4 para cima → 16,8 studs à frente, 4,3 acima |
| D / A | **Direita / Esquerda** | Mesmo dash, para o lado da câmera; corpo fica de frente para a câmera |

Ao fim do dash sobra 35% da velocidade horizontal (`DashCarry`) e a queda começa. Um Geppo
"cima" que corta um dash herda só essa sobra (não sobe na diagonal).

Repetição segurando (`GeppoState.autoInterval`): próximo sai em `fim − 0,02 s` — dash: 0,28 s;
cima: 0,32 s (topo 0,34). Medido: no instante do próximo, a velocidade vertical ainda é
+14,4 (dash) / +3,6 (cima) — nunca começa a cair. 5 cimas seguidos ≈ 48 studs de subida.

## Animações (publicadas, conta 3465482970)

| Tipo | Gerador (`ANIMS`) | Asset |
|---|---|---|
| Cima | `GeppoCima` | 97374111326760 |
| Frente | `GeppoFrente` | 109202297432592 |
| Direita | `GeppoDireita` | 114666450546323 |
| Esquerda | `GeppoEsquerda` (espelho da direita) | 75599356215537 |

Linha do tempo comum (60 fps, trilha de 0,50 s): 0 neutro → 0,05 **encolher** (marker
`Impacto`: VFX/SFX no pé que empurra) → 0,10 **impulso** → 0,20 pose ainda em movimento →
0,30 marker **`Soltar`**: o controller para a trilha com fade de 0,15 s e a queda do Animate
assume (fim do dash = começo da queda). Prioridade Action2.

- Cima: perna direita estica para baixo, esquerda dobrada no alto, braço direito para o alto
  levemente dobrado, esquerdo reto para baixo, cabeça olha para cima.
- Frente: corpo projetado ~38°, braço direito alcança à frente, esquerdo para trás, perna
  direita chuta o ar para trás, esquerda dobrada à frente.
- Direita: corpo inclina para a direita, braço/perna esquerdos esticados "empurrando o chão"
  para baixo/esquerda, braço direito lidera para cima/fora, perna direita dobrada, cabeça
  olha para onde vai. Esquerda = espelho.

Encadeado: duas trilhas por tipo e crossfade (0,10 s; 0,05 entrando da queda). As 4 são
pré-carregadas ao nascer (`ContentProvider:PreloadAsync`).

## Decisões (e por quê)

- **InputBegan, não JumpRequest** no teclado: o JumpRequest repete enquanto o Espaço está
  apertado e um pulo comum virava Geppo. Celular: JumpRequest com pausa mínima de 0,12 s.
- **"Segurando" = `UIS:IsKeyDown` a cada quadro**: num teste chegou um InputEnded falso
  0,23 s depois do aperto.
- **Dash por `LinearVelocity`** (World, força infinita) ligado/desligado — linha reta sem
  pêndulo, como pedido; sem setar velocidade a cada quadro.
- **AutoRotate desligado no dash** e root girando para a frente da câmera: o padrão do Roblox
  vira o boneco para onde ele anda e a inclinação lateral viraria inclinação para a frente.
- **Animação não volta ao neutro**: a queda do Animate tem braços erguidos; voltar ao neutro
  fazia o braço descer e subir de novo. Marker `Soltar` + fade resolve.
- **Duas trilhas alternadas**: `Play` numa trilha que já toca volta ao quadro 0 (corte).
- O R15 do jogo usa **AnimationConstraint**, não Motor6D (a v3 animava C0 de Motor6D e não
  mexia nada).

## Histórico

- 22/10: animação "Projeção" (cima) substitui a v3 procedural quebrada; publicação manual.
- 22–23/10: chave Open Cloud no `.env`; publicação automática; pipeline Blender → Studio.
- 23/10: toque duplo; +35% de distância (cima 8,6 → 11,6 studs; dash 16,8 studs); 4 tipos
  direcionais com animações próprias; um toque no ar após o 1º Geppo; segurar repete colado
  no fim; dash sobe +20% (3,6 → 4,3 studs); pré-carregamento das animações.

## Em andamento / próximos passos

1. **Alternar perna e braço a cada Geppo encadeado** (pedido 23/10, EM ANDAMENTO).
   - Feito: gerador com variantes B (`GeppoCimaB`/`GeppoFrenteB` = espelho completo;
     `GeppoDireitaB` = mesma inclinação, troca perna que empurra e braço que lidera — o
     esquerdo cruza por cima da cabeça; `GeppoEsquerdaB` = espelho dela). `GeppoDireitaB`
     revisada no Blender.
   - Falta: gerar/revisar as outras B, publicar as 4, `GeppoConfig.Animations` com par A/B por
     tipo, alternância no controller (1º do voo = A, reset ao pousar), pé do VFX por variante
     (Cima/Frente B: pé esquerdo; Direita B: pé direito; Esquerda B: pé esquerdo), testes e
     playtest.
2. **Geppos mais longos, menos "metralhadora" ao segurar** (pedido 23/10, A ESCLARECER):
   "aumente a duração total em ao menos 25%". Ao segurar hoje sai um a cada 0,28–0,32 s.
   Dúvidas antes de mexer: (a) a frase "um a cada 1/5 segundo" — 0,2 s seria mais rápido que
   hoje; provavelmente ~0,35–0,4 s ou 1,5 s? (b) mais duração mantendo a distância (mais lento)
   ou aumentando a distância junto? Para o dash: `DashTime` 0,30 → 0,375 (+25%); para o cima,
   mais tempo até o topo exige mais `ImpulseY` (mais altura) ou gravidade reduzida durante o
   Geppo. As animações (marker `Soltar` em 0,30) precisam acompanhar.
3. `CorridaController` (Studio): `inclinarCorpo`/`olharCabeca` procuram Motor6D e estão mortos
   no rig atual — o usuário ainda não pediu correção.
4. Testar no celular (toque duplo e segurar no botão de pulo) — não testado.
