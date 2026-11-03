# Várzea FC — Domingo de clássico

Jogo 3D de futebol de várzea para **Godot 4**, validado no **Godot 4.7.2**, com renderizador Compatibility. Escolha **Brasil, Argentina, Alemanha ou França**, com **dois uniformes por seleção**, para uma partida **5 contra 5**, de **3 minutos**. Você controla a seleção da esquerda no menu e ataca para a direita.

No menu inicial, escolha sua seleção, o adversário e o uniforme de cada lado. Escolher uma seleção que já ocupa o outro lado troca os times de lugar. Na pausa ou no fim da partida, **Trocar seleções / uniformes** volta à configuração. Os elencos são fictícios, com cinco jogadores por país e todos os biotipos e tons de pele representados para testar o sistema.

| Seleção | Uniforme 1 | Uniforme 2 |
| --- | --- | --- |
| Brasil | Amarelo, short azul, meião branco | Azul, short branco, meião azul |
| Argentina | Branco com listras celestes, short escuro | Azul-marinho com faixa celeste |
| Alemanha | Branco com faixa preta, short preto | Preto com faixa vermelha |
| França | Azul, short branco, meião vermelho | Branco com faixa azul, short azul |

Cada uniforme também define as cores do goleiro, que mantém manga comprida e camisa diferente dos jogadores de linha. São interpretações próprias das cores clássicas, sem escudos ou patrocinadores.

**Durante o desenvolvimento, execute `project.godot` no Godot com F5.** Por orientação do usuário, o executável e os ZIPs só serão atualizados ao final do projeto. Empacotamento, exportação e renovação das prévias finais ficam para essa etapa; o README acompanha as mudanças agora.

A última exportação Windows fica em **build/windows/VarzeaFC.exe**, com os recursos incluídos, e dispensa a instalação do Godot. Ela será renovada na entrega final.

A cópia de **`match_roster.json` ao lado do executável** permite mudar jogadores e uniformes sem reexportar o jogo. Se ela não existir, o jogo usa a escalação incluída no executável. Reinicie o jogo depois de editar o cadastro.

Para editar, abra **project.godot** no Godot, aguarde a importação e pressione **F5**. Na tela inicial, clique em **Entrar em campo** ou pressione **Enter**. O jogo funciona sem Blender, Python, pacotes externos ou acesso à internet.

## Controles

| Tecla | Ação |
| --- | --- |
| WASD / setas | Movimentar |
| Posição do mouse no campo | Mirar o chute e o passe, em qualquer direção |
| Shift | Correr; solte para trotar e recuperar o fôlego |
| Mouse esquerdo, com bola | Segure para carregar o chute e solte para bater |
| Mouse esquerdo, sem bola | Carrinho |
| Mouse direito, com bola | Passe rasteiro forte na direção do mouse |
| Mouse direito, sem bola | Desarme em pé |
| Clique do scroll (botão do meio) | Trocar para outro jogador de linha próximo à bola |
| V | Alternar câmera próxima / mais aberta |
| P / Esc | Pausar / continuar |
| R | Nova partida |
| M | Ligar / desligar efeitos sonoros |
| F1 | Mostrar / ocultar ajuda |
| F2 | Modo torcida: os dois times passam a jogar sozinhos |

## A partida

Há um goleiro, um zagueiro, dois alas e um atacante em cada time. A IA procura espaços, oferece opções de passe, persegue a bola e tenta desarmar. Goleiros preveem a chegada da bola, alcançam bolas baixas, mergulham para os lados, saltam, encaixam ou espalmam e repõem a bola. O círculo amarelo identifica o jogador controlado; o outro número que aparece identifica a opção de passe.

A câmera usa perspectiva, fica mais baixa e próxima, em ângulo de transmissão, e acompanha a bola suavemente pelo campo. V abre um pouco mais o enquadramento.

Quando um companheiro domina ou recupera a bola, o controle passa imediatamente a ele, inclusive ao goleiro. Sem posse, se o jogador controlado estiver a mais de 7 m da bola e um companheiro de linha estiver pelo menos 2,5 m mais próximo, a troca é automática. Uma pausa curta entre trocas evita alternâncias contínuas; a recepção da bola sempre tem prioridade. O clique do scroll permite a troca manual. Espaço, E, F, Q e Tab continuam disponíveis como atalhos de teclado.

A bola continua sendo um corpo físico durante o domínio: forças procuram mantê-la à frente do jogador, e adversários podem interceptar. Chute e passe seguem a posição do mouse projetada sobre o gramado, inclusive para os lados ou para trás. Não há correção da trajetória para o gol ou para um companheiro. A direção é registrada ao clicar para passar ou ao soltar o botão para chutar; uma seta curta e a mira indicam para onde a bola vai.

Os passes saem a 18–24 m/s, com rotação de rolamento e pouca elevação, para chegarem firmes. O controle pode passar ao companheiro na trajetória real, e também é possível tocar em espaço vazio. Chutes têm força e elevação. O fôlego limita a corrida. Carrinho que atinge um adversário sem alcançar a bola causa falta.

A carga do chute também define um arco balístico: a velocidade vertical inicial usa `sqrt(2 × gravidade × subida)`, considerando a gravidade configurada e o `gravity_scale` da bola. A subida ideal varia de 0,15 a 2,10 m acima do ponto de lançamento; gravidade, amortecimento e colisões do Godot determinam a trajetória efetiva. Em testes com a bola saindo a 0,25 m, cargas de 0,30 / 0,70 / 1,00 atingiram aproximadamente **0,38 / 1,35 / 2,06 m no centro da bola**, com primeiro quique a **3,79 / 13,99 / 19,94 m**. A mira continua escolhendo livremente a direção horizontal; o jogo não ajusta a trajetória para acertar o gol. Os passes continuam rasteiros. Os parâmetros `SHOT_MIN_RISE` e `SHOT_MAX_RISE` ficam em `scripts/match.gd`.

`tests/shot_trajectory.gd` passou em **17/17 verificações** de altura e alcance na física real, mira em diferentes direções, passes baixos, impulso único e respeito à escala de gravidade. `tests/inspect_shot_trajectory.gd` registra os percursos físicos e grava a comparação em `.runtime/shot-trajectories.png`.

Ao iniciar um passe, o destinatário interrompe a corrida de apoio e procura o ponto de encontro com a trajetória física da bola. O movimento que já estava pressionado pelo passador não faz o recebedor fugir da jogada. Ao dominar, a assistência termina e o movimento volta a responder normalmente. Para conduzir o recebedor manualmente antes do domínio, solte a direção e pressione a nova direção; trocar de jogador também cancela a assistência. A bola continua livre para ser interceptada.

O primeiro toque amortiza passes rápidos. O bloqueio curto após o chute vale apenas para quem acabou de soltar a bola, permitindo recepções e interceptações imediatas. Desarmes limpos, em pé ou de carrinho, transferem o domínio ao vencedor e amortecem a bola em vez de chutá-la para longe. Durante a bola rolando, a condução usa forças, impulsos e colisões nativas, sem congelar, teleportar ou prender a bola como filha do personagem.

Gols exigem a bola inteira além da linha, dentro das traves. O jogo possui placar, comemoração, saída após o gol, lateral, escanteio, tiro de meta, falta com bola parada, pausa e estatísticas finais. Ao sair pela lateral ou linha de fundo, a bola continua na física pelo intervalo de **OUT_DURATION** (atualmente **1,5 s**), podendo bater no alambrado. A câmera acompanha a saída e a cobrança já fica decidida pelo último toque, mesmo se a bola voltar para dentro. Só depois ela é posicionada para a reposição. O relógio para durante esse intervalo, nas cobranças e nas comemorações. Não há impedimento, cartões, prorrogação ou disputa de pênaltis.

Nas **faltas, escanteios, tiros de meta e laterais**, o cobrador já recebe a posse, é selecionado quando pertence ao seu time e fica com a bola parada nos pés. Depois da preparação curta, a cobrança aguarda **mouse direito para passar** ou **esquerdo para carregar e soltar o chute**, apontando o mouse na direção desejada. Não é necessário andar para dominar, e WASD/Shift não conduzem a bola antes da cobrança. Ela só é solta no contato da animação, com impulso físico. O tiro de meta usa o goleiro. Adversários e companheiros dão espaço; a IA cobra normalmente e o modo torcida também cobra pelo seu time. A saída inicial mantém a contagem regressiva seguida de bola rolando. P/Esc pausa e retoma também a saída da bola e a cobrança preparada.

O campo tem gramado verde bem cuidado, faixas suaves de corte e 2.600 pequenos tufos de folhas triangulares, desenhados com um único `MultiMeshInstance3D`. As traves têm a rede de fundo inclinada e as duas redes laterais completas, com fios horizontais e verticais. O **alambrado low poly fecha os quatro lados**, a 27,2 m do centro nas linhas de fundo e 16,6 m nas laterais, com 4 m de altura. Tem postes quadrados, três travessas horizontais e fios diagonais formando losangos vazados. Os quatro painéis usam malhas leves, sem textura transparente; postes e travessas compartilham um `MultiMesh`. Quatro caixas de colisão nativas contêm a bola fora das linhas, com espaço atrás dos gols. O entorno agora forma uma praça carioca fictícia com casario, cais, orla e praia; veja a seção Praça XV abaixo. Os efeitos de apito e batida de bola são sintetizados no próprio Godot.

Prévias: `qa/campo-alambrado-completo.png`, `qa/campo-alambrado-detalhe.png`, `qa/campo-escanteio-pronto.png`, `qa/campo-tiro-de-meta-pronto.png` e `qa/campo-falta-pronta.png`. A saída com espera de dois segundos está em `qa/campo-bola-fora.gif`.

## Goleiros: previsão, estados e contato das mãos

Os dois goleiros têm um controlador próprio em **`scripts/goalkeeper.gd`**. A previsão acompanha a velocidade atual da bola, a gravidade, o amortecimento do ar e uma aproximação dos quiques no chão, em passos de 1/120 s e horizonte de 1,8 s. Ela estima o ponto e o tempo de travessia diante do goleiro e verifica se a bola segue para a região do gol. Não prevê futuras intervenções de outros jogadores nem altera a trajetória real. O posicionamento acompanha esse ponto; a reação demora 0,12 s, e a tentativa é iniciada quando faltam até 0,34 s para a chegada. Deslocamento, salto e alcance dos braços são limitados, permitindo gols quando não há tempo ou alcance suficiente.

Os estados são **posicionar, preparar, alcançar, mergulhar, saltar, encaixar, segurar, repor e recuperar**. A `AnimationTree` tem sete novos estados `Keeper*`; as poses originais de base ficam em `scripts/goalkeeper_poses.gd` e são compartilhadas por altura. Os movimentos usam os mesmos 65 ossos, sem alterar malhas, pesos ou hierarquia. Dois `TwoBoneIK3D` ajustam os braços ao alvo; outros dois mantêm os pés apoiados ao abaixar o corpo para uma defesa rasteira. O salto desloca o `CharacterBody3D` com gravidade, e o mergulho combina impulso lateral, elevação e inclinação visual do corpo. A cápsula de colisão abaixa junto com o corpo ao agachar ou mergulhar, evitando uma barreira invisível na altura da postura em pé.

**A previsão só escolhe a tentativa; a defesa exige contato próximo das luvas.** A cada passo da física, o jogo lê as mãos depois da IK e verifica o percurso relativo entre a bola e cada luva. Os volumes têm os raios reais configurados de 0,22 m para a bola e 0,16 m para a luva; a soma de 0,38 m é a distância máxima de contato entre seus centros. A verificação contínua também detecta uma bola rápida que atravessa a luva entre dois quadros. A recuperação genérica por proximidade da cápsula não captura chutes em direção ao goleiro. Impactos comuns no corpo continuam pertencendo à física e não geram uma defesa com as mãos.

Bolas com velocidade inferior a 20 m/s podem ser encaixadas quando a defesa não é um mergulho. Depois do contato, um impulso amortece a bola e uma força com amortecimento e compensação da gravidade a mantém junto às mãos. Ela continua como `RigidBody3D`, sem congelamento, teleporte ou mudança de pai. Bolas mais rápidas e mergulhos produzem uma espalmada com impulso para fora do gol e para o lado. O aviso **MILAGRE!** e o som de defesa acompanham o contato confirmado.

Ao encaixar pelo seu time, o controle passa ao goleiro. **Mouse direito repõe a bola; o esquerdo permite um arremesso carregado**, sempre na direção indicada pelo mouse. A bola sai aos 0,22 s da animação do braço, uma única vez. A IA e o modo torcida repõem automaticamente após segurar a bola por um breve intervalo. Fora da área de atuação das mãos, o goleiro pode voltar ao controle com os pés. Pausa congela previsão, salto, pose e contato; menu, reposição, falta e nova partida limpam os estados anteriores.

`tests/goalkeeper.gd` passou em **76/76 verificações**, incluindo defesas baixas, mergulhos para os dois lados e saltos nos dois times, distância física das luvas, apoio dos pés, cápsula do corpo durante o mergulho, encaixe com a bola livre, reposição automática e manual, impulso único, previsão comparada com voo real, passagem rápida entre quadros, gol fora de alcance, bola acima do travessão, pausa e reinício. Também passou uma partida completa até o apito final. `tests/inspect_goalkeeper.gd` registra seis vistas antes e no contato, em **`.runtime/goalkeeper-defenses.png`**, sem renovar as prévias finais, o executável ou os ZIPs. Os principais ajustes são `REACTION_SECONDS`, `COMMIT_SECONDS`, `DIVE_SPEED` e `GLOVE_RADIUS`.

## Praça XV: entorno fictício no Rio

O campinho agora fica na **Taça Praça XV**, em uma praça carioca fictícia que reúne o centro histórico, a orla com praia e uma vista de subúrbio. A composição aproxima esses lugares para o jogo; não reproduz a geografia real. O nome do torneio aparece na faixa junto ao campo, no menu e na HUD.

O entorno tem fachadas inspiradas no Paço, um arco com passagem realmente aberta e comércio ao fundo, chafariz de pedra, estação das barcas com relógio, cais e uma barca na água. Há casario colonial com sacadas, uma rua lateral com ônibus, morro com casas e caixas-d'água, edifícios distantes e ilhas na baía. Do outro lado, praia, coqueiros, guarda-sóis e calçadão com desenho ondulado. Bancos, postes de iluminação, quiosque e espectadores completam a praça.

**Gramado, tufos, marcações, gols e alambrados permanecem como estavam**, inclusive suas medidas, materiais e colisões. O novo piso contorna o campo sem se sobrepor a ele; os prédios ficam fora da área cercada. O entorno não acrescenta colisores nem altera a física, as regras ou o gerador aleatório da partida. A iluminação anterior foi mantida; apenas a cor de fundo do céu mudou.

Tudo foi modelado por código, com `SurfaceTool`, `ArrayMesh`, cores por vértice e recursos nativos, sem Blender MCP, bibliotecas externas ou texturas baixadas. São **19 lotes de malha, com 25.753 triângulos**. As malhas permanecem estáticas; a água usa um shader leve cujo relógio acompanha a câmera lenta e congela na pausa.

Para editar o cenário, use **`scripts/praca_xv.gd`**. As funções `_paco`, `_arco`, `_fountain`, `_ferry_terminal`, `_waterfront`, `_beach` e `_suburb` organizam os elementos e suas posições. `scripts/stadium.gd`, em `_neighborhood`, adiciona o bairro. O piso está em `assets/shaders/praca_stone.gdshader`; a água, em `assets/shaders/rio_water.gdshader`.

Referências arquitetônicas: [Praça XV — Secretaria de Cultura do RJ](https://cultura.rj.gov.br/praca-xv/) e [Paço Imperial — Visite Museus](https://visite.museus.gov.br/instituicoes/centro-cultural-do-patrimonio-paco-imperial/). As formas e a disposição do cenário são interpretações próprias em low poly.

`tests/praca_xv.gd` passou em **46/46 verificações**, incluindo limite de geometria, ausência de sobreposição com o campo, preservação do gramado e cercas, posição da barca sobre a água e relógio do shader. Também foram conferidas cinco vistas renderizadas e uma partida completa até o apito final. `tests/inspect_praca.gd` grava somente imagens temporárias em `.runtime`; as prévias finais, o executável e os ZIPs continuam reservados para o fim do projeto.

## Redes com ondulação por shader

Os dois gols têm redes que cedem no ponto da batida, fazem uma onda amortecida e voltam ao repouso. O fundo inclinado e as duas laterais se deformam, com as bordas presas ao quadro e ao chão. A amplitude depende da velocidade real da bola; contatos lentos e repetidos são filtrados.

A batida é recebida dos seis `StaticBody3D` existentes, inclusive depois de o gol ser contabilizado. O shader só anima a aparência; a bola continua usando os mesmos colisores nativos. A posição do contato é projetada no painel correspondente. Uma senoide amortecida, com atraso pela distância, propaga a perturbação. O tempo vem do delta da física: a rede acompanha a câmera lenta, congela na pausa e se limpa no menu ou na reposição.

São **duas instâncias de uma malha compartilhada**, uma por gol, com 10.044 vértices e uma superfície por instância. Os fios têm segmentos de até 20 cm e usam tiras cruzadas opacas, sem textura ou transparência. Cada gol tem material independente e até quatro impactos ativos. A CPU atualiza apenas os pequenos conjuntos de uniforms; não reconstrói a geometria por quadro. Quando a vibração acaba, o controlador para de receber atualizações de física. Funciona no renderizador Compatibility/OpenGL usado pelo jogo.

Ajustes visuais em `assets/shaders/goal_net.gdshader`: `wave_speed` (propagação), `frequency` (oscilação), `damping` (amortecimento) e `net_color`. Em `scripts/goal_net.gd`: `SPEED_TO_AMPLITUDE`, `MAX_AMPLITUDE`, `IMPACT_RADIUS`, `HIT_SECONDS` e `MAX_HITS`.

Prévia com impactos físicos no fundo e na lateral: `qa/rede-shader.gif`. Capturas: `qa/rede-shader-repouso.png` e `qa/rede-shader-onda.png`.

## Sons e câmera juicy

Chutes, passes, carrinhos, defesas, traves e gols agora usam sons próprios em camadas. São três variantes por impacto, com pequena variação de afinação, oito vozes espaciais para permitir sobreposição, apitos separados e um barramento com limitador nativo. A torcida tem ambiente discreto e reações maiores para trave, defesa e gol. O volume ambiente diminui na pausa; impactos e gritos ativos são interrompidos. **M silencia todos os sons imediatamente**, preservando os efeitos visuais.

Chutes fortes têm um breve recuo da lente; traves, defesas, desarmes e gols dão pulsos leves, com amortecimento completo em menos de meio segundo. O acompanhamento da bola e a câmera aberta do V continuam funcionando. Os raios de mira usam uma segunda câmera que não renderiza, com a projeção estável antes dos efeitos: o mesmo pixel continua apontando para o mesmo alvo no campo durante o tremor e o pulso de FOV. Pausa congela a câmera e sua animação; menu e reposição limpam os efeitos anteriores. A física e as regras não são alteradas.

`scripts/juice.gd` reúne os sons e os ajustes: `SFX_VOLUME_DB`, `CROWD_VOLUME_DB`, `camera_strength` (0 desliga somente o movimento da câmera), `CAMERA` e `FOV_PUNCH`. A variação de áudio usa seu próprio gerador aleatório, sem consumir o da IA. Os 26 WAVs originais somam aproximadamente 787 KB e são compartilhados entre eventos. Foram gerados sem amostras ou downloads por `python3 tools/build_juicy_audio.py`; o jogo pronto usa somente recursos nativos do Godot.

Prévia do áudio realmente mixado pelo Godot: `qa/juicy-sons.wav` (apito, passes, chutes, trave, defesa, desarme e gol). Prévia de câmera: `qa/juicy-camera.gif`. Medições dos arquivos: `docs/juicy_audio_manifest.json`.

## Carrinho cinematográfico

Um carrinho que ganha a bola dispara um zoom no contato, giro de 14 graus no eixo Y, inclinação de 5 graus e leve rotação lateral, com tremor curto. A entrada leva 0,14 s; o mundo fica a 30% da velocidade por 0,75 s, medidos sem a escala de tempo. Depois, a velocidade normal volta e a câmera desfaz zoom e rotações em 0,35 s. Vale para os dois times. Bote em pé, tentativa sem contato e bola já dominada pelo próprio jogador não disparam a sequência. Nas faltas de carrinho, a mesma câmera destaca o contato com o adversário.

Nas faltas de carrinho, o jogador atingido usa `Hit_Knockback` para cair e `LayToIdle` para levantar, ambos originais do segundo pack UAL. A queda preserva o esqueleto e a altura do cadastro. O jogo para a bola e o relógio, mostra a queda no local do contato com a reação FOI MAL e só depois prepara a falta, com posse pronta. O jogador que deu o carrinho termina sua animação. A velocidade das duas animações usa `FALL_RATE` em `scripts/footballer.gd`. Prévia: `qa/falta-carrinho.gif`.

A pausa congela a sequência e a queda; reposição, menu, gol e saída da cena restauram a velocidade. O efeito não se acumula com outro carrinho. A projeção da mira continua estável. Os ajustes ficam em `scripts/slide_moment.gd`: `SLOW_SECONDS`, `SLOW_SCALE`, `RETURN_SECONDS`, `ZOOM_FOV`, `ORBIT_DEGREES`, `PITCH_DEGREES` e `ROLL_DEGREES`. `slide_cinematic_enabled` em `scripts/juice.gd` desliga a sequência completa.

Prévia: `qa/carrinho-cinematico.gif`.

## Três animações de chute

Segurar o botão esquerdo apenas carrega a força: a preparação do chute começa **ao soltar**. O indicador mostra FRACO, MÉDIO ou FORTE. A bola sai no contato do pé, com um único impulso, seguindo a direção registrada ao soltar o clique.

| Tipo | Força | Tempo segurando, aproximadamente | Contato após soltar | Animação completa | Câmera por trás |
| --- | --- | --- | --- | --- | --- |
| Fraco | Abaixo de 0,55 | Menos de 0,375 s | 0,19 s | 0,54 s | Não |
| Médio | 0,55 a menos de 0,85 | 0,375 a menos de 0,825 s | 0,22 s | 0,64 s | Não |
| Forte | A partir de 0,85 | A partir de 0,825 s | 0,27 s | 0,82 s | Sim |

O fraco preserva `custom/shot`. Médio e forte são ações novas, criadas no **Blender 5.2 pelo servidor local Blender MCP**, sobre os mesmos 65 ossos: `Kick_Medium` e `Kick_Strong`. Têm transferência rápida de peso, recuo da perna, giro do quadril e tronco, braços em contrapeso, batida, continuidade e recuperação. O forte amplia os gestos. Uma compensação na pelve mantém o pé esquerdo de apoio no lugar. As animações acompanham a altura do cadastro e compartilham o cache por altura.

Os modelos, vértices, pesos, UVs, malhas e ossos de repouso não foram alterados. O jogo carrega somente `assets/animations/kicks.res`, cerca de 86 KB; o Blender não é necessário para jogar. O arquivo editável é `tools/source/chutes.blend`, com a cena separada `Varzea_KickStudio`, e o GLB de origem fica em `tools/source/kicks_authored.glb`.

Para editar manualmente, abra o `.blend` no Blender e ajuste as ações. O marcador CONTACT define a saída da bola; ANTICIPATION e FOLLOW_THROUGH identificam as fases. Com o servidor Blender MCP conectado, `python3 tools/blender_mcp.py --script tools/export_kicks.py` exporta as edições e os marcadores sem recriar as poses. Depois, execute `godot --headless --path . --script res://tools/extract_kicks.gd`. O extrator inclui o tempo CONTACT no recurso do Godot, e o jogador lê esse dado para sincronizar a física. `tools/author_kicks.py` recria as poses originais desta entrega; use esse arquivo somente quando quiser reconstruí-las.

Prévia em velocidade normal: `qa/chutes-3-tipos.gif`. Dados: `docs/kick_animation_manifest.json`. O comportamento vale também para IA e cobranças.

## Câmera do chute, trave e rede em etapas

A câmera por trás do chutador continua exclusiva do **chute forte** (força a partir de 0,85). A entrada leva 0,22 s, fica 9 m atrás e a 4,8 m de altura, alinhada à direção real do impulso. O primeiro destaque usa 0,75 s de câmera lenta a 30% da velocidade. Ao acabar esse tempo, a velocidade volta ao normal e **a câmera segue a bola**, sem retornar automaticamente ao enquadramento de transmissão.

A sequência responde aos eventos reais:

- **Chute para fora:** conserva a espera de `OUT_DURATION` e faz retorno suave da câmera, como antes.
- **Trave:** a colisão nativa aproxima a lente da bola e da trave, com inclinação lateral de 3 graus e câmera lenta. Entre os destaques a bola pode viajar em velocidade normal, acompanhada pela câmera.
- **Trave e volta ao campo, defesa ou domínio:** a sequência retorna suavemente à câmera normal, desfazendo inclinação e lente.
- **Trave e gol, ou gol direto:** o contato físico com a rede dispara outro close em câmera lenta, mostrando a bola e a deformação dos fios. O ponto de vista parte da pose atual, sem voltar à câmera normal entre as etapas.

O gol é contabilizado quando a bola cruza a linha inteira, mas o texto GOOOL, a onda de letras e a comemoração dos jogadores aguardam **0,75 s em tempo real de close da rede**. Só depois começam os 2,8 s completos da animação de gol, com retorno suave da câmera. Um contato seguinte na rede não reinicia a contagem. Impactos muito próximos preservam uma entrada legível do chute e da trave antes de mostrar a rede.

Os closes de trave e rede também podem aparecer em chutes médios ou fracos: a restrição ao forte vale para o movimento inicial por trás do chutador. Não há previsão de resultado, replay que reposiciona a bola ou correção da trajetória. Pausa congela câmera, animações e contagem do gol; P/Esc funciona também durante o close e a comemoração. Menu, nova partida e reposição limpam as etapas pendentes. Se um gol válido não tocar fisicamente a rede, existe uma espera limitada para liberar a comemoração, sem inventar uma batida no shader.

Ajustes em `scripts/shot_moment.gd`: `ENTER_SHOT_SECONDS`, `BACK_DISTANCE`, `CAMERA_HEIGHT`, `SHOT_FOV`, `IMPACT_ENTER` e `MAX_FLIGHT_SECONDS`. Em `scripts/match.gd`, `GOAL_NET_HOLD` controla os 0,75 s antes do HUD e `GOAL_NET_WAIT_LIMIT` limita a espera por contato na rede. `shot_cinematic_enabled` em `scripts/juice.gd` liga ou desliga as câmeras de chute. Carrinho e falta mantêm seu próprio diretor e têm prioridade durante a bola rolando.

Validação: `tests/shot_sequence.gd` verifica as transições e a contagem; `tests/shot_sequence_live.gd` usa a bola física em gol direto, trave com volta ao campo e trave seguida de gol. A opção `--realtime-sequence` permite conferir os 0,75 s com relógio real. As imagens temporárias de inspeção ficam em `.runtime`, sem renovar os pacotes ou prévias finais.

## Bola expressiva

Chutes fortes (carga a partir de 0,85) deixam um rastro fino de núcleo creme e borda ciano, construído com os pontos por onde o `RigidBody3D` realmente passou. A cauda tem até 2 m, guarda somente 0,11 s do caminho e emite por até 0,75 s enquanto a bola está rápida. Ela para em colisões, defesas e domínio, e o restante desaparece suavemente. Passes e chutes comuns não ativam esse rastro.

Chutes, passes, desarmes, defesas, traves e recepções rápidas também geram pequenos traços de impacto no ponto do contato, por 0,16 a 0,22 s, com o centro livre para a bola continuar visível. O efeito combina com os recortes do HUD e funciona com o áudio desligado. Contatos repetidos são agrupados, e o domínio lento não gera flashes contínuos. Pausa congela os efeitos; reposição, menu e fim da partida limpam os dados antigos.

`scripts/ball_fx.gd` concentra os ajustes: `TRAIL_SECONDS`, `TRAIL_MEMORY`, `TRAIL_LENGTH`, `TRAIL_MIN_SPEED`, `MAX_POINTS` e `MAX_CONTACTS`. O rastro usa um único `ImmediateMesh`, sem textura ou colisão, com teste de profundidade. A geometria tem no máximo 16 pontos e 180 vértices, e há no máximo seis marcas de contato simultâneas. São efeitos cosméticos, sem alterar a trajetória ou a velocidade física.

Prévia: `qa/bola-expressiva.gif`. Capturas: `qa/bola-contato-passe.png`, `qa/bola-contato-chute.png`, `qa/bola-rastro.png` e `qa/bola-contato-trave.png`.

## HUD e menus arcade

A interface mistura arcade dos anos 80 com recortes gráficos inspirados em Persona: preto e creme, rosa, ciano e amarelo, painéis inclinados, sombras deslocadas e retículas. O menu tem título em movimento, letreiro rolante, botão pulsante e as bandeiras das quatro seleções nos cartões e nas opções. O placar também usa bandeiras e numerais pixelados; o cartão do jogador conserva nome, posição, biotipo e altura. Fôlego, carga de chute, minimapa, pausa, ajuda e resultado seguem a mesma identidade.

Ao marcar um gol, cada letra de **GOOOL!** entra de baixo para cima com atraso e oscilação, formando uma onda. A comemoração tem faixa diagonal, um impacto inicial de luz, raios e confetes, além da bandeira e do nome de quem marcou. Ela termina junto com os 2,8 segundos da comemoração e dá lugar à saída de bola. Os efeitos ficam na camada 2D e não alteram câmera, física, placar ou tempo de jogo.

Tudo é desenhado com `Control`, `CanvasItem`, `StyleBoxFlat`, `OptionButton` e fontes do sistema, sem plugin. Os numerais 5×7 e as quatro bandeiras pixeladas são desenhos originais em código. Cada bandeira é uma textura de 64×40 gerada uma vez e compartilhada. A tipografia de destaque procura Impact, Arial Black ou DejaVu Sans no sistema; arquivos de fontes do Windows não são redistribuídos. O layout é escalado junto com os controles nativos e foi conferido em 960×600, 1600×900 e 1024×768.

Prévias: `qa/arcade-menu.png`, `qa/arcade-bandeiras.png`, `qa/arcade-partida.png`, `qa/arcade-chute.png`, `qa/arcade-pausa.png` e `qa/arcade-resultado.png`. A comemoração animada está em `qa/arcade-gol.gif`. `scripts/hud.gd` desenha e anima a interface; `scripts/ui_flags.gd` fornece as bandeiras compartilhadas.

### Reações no local da jogada

Os lances ganham etiquetas 2D no ponto do campo em que aconteceram, com recortes, ponteiro, entrada elástica, oscilação e saída suave. A posição é reprojetada a cada quadro: a etiqueta acompanha a câmera, mas permanece no local do evento quando o jogador vai embora. Avisos gerais, como modo torcida e saída de bola, continuam no topo.

| Lance | Reação |
| --- | --- |
| Carrinho limpo na bola | NA BOLA! |
| Desarme de adversário em pé | É NOSSA! |
| Impacto físico em poste ou travessão | NA TRAVEEE! |
| Goleiro domina um chute adversário | MILAGRE! |
| Chute com carga alta | WOOOOW! |
| Falta | FOI MAL! |
| Lateral / escanteio / tiro de meta | SAIU! / NO CANTO! / PRA FORA! |

Faltas e reposições mostram também o tipo da cobrança e a seleção que a ganhou. Há no máximo quatro etiquetas simultâneas, com duração de 1,1 a 1,6 segundos e supressão de contatos repetidos próximos. Elas pausam com a partida, são ocultadas fora da câmera e são limpas no gol, na saída ou ao trocar a partida. Colisões com chão e rede não geram aviso de trave; somente os seis corpos físicos existentes dos postes e travessões recebem essa identificação. Os efeitos não recebem cliques nem modificam a física.

Prévia animada: `qa/reacao-na-bola.gif`. Capturas: `qa/reacao-na-bola.png`, `qa/reacao-na-traveee.png`, `qa/reacao-woooow.png`, `qa/reacao-milagre.png`, `qa/reacao-foi-mal.png` e `qa/reacao-saiu.png`.

## Personagens e os dois ZIPs

### Cadastro e montagem da partida

Os jogadores são montados ao carregar **`data/match_roster.json`**. Cada registro contém nome, tipo de corpo, altura em metros, tom de pele, tipo e cor de cabelo, time e posição. Nome, número, biotipo e altura aparecem no cartão do jogador. O cadastro é convertido em objetos `FootballPlayerData`, um `Resource` nativo do Godot; os recursos visuais e animações ficam compartilhados.

```json
{
  "id": "brasil_4",
  "nome": "Davi",
  "tipo_corpo": "magro",
  "altura": 1.65,
  "cor_pele": 4,
  "tipo_cabelo": "cacheado",
  "cor_cabelo": "preto",
  "time": "brasil",
  "posicao": "ala_direita",
  "numero": 7
}
```

`cor_pele` aceita os cinco tons de **0 (clara) a 4 (negra retinta)**, passando por morena clara, morena e negra. `tipo_cabelo` aceita `careca`, `raspado`, `curto`, `cacheado` e `moicano`. São estilos de pintura do couro cabeludo sobre a geometria existente, sem acrescentar peças ou vértices. A cor pode ser `preto`, `castanho`, `loiro`, `ruivo`, `grisalho` ou um hexadecimal como `#704029`. `tipo_corpo` aceita somente `normal`, `magro` e `parrudo`.

**`altura` é um número em metros**, independente do biotipo: por exemplo, `1.65` com `normal` ou `1.95` com `parrudo`. O cadastro aceita de **1,20 a 2,30 m**, com precisão de centímetros. No JSON, use ponto decimal e não coloque o número entre aspas. Os vinte jogadores já têm alturas variadas. Para arquivos antigos sem o atributo, a altura padrão é 1,78 m; os antigos `baixo_magro`/`baixo_parrudo` (ou índices 3/4) são convertidos para `magro`/`parrudo` com 1,53 m. Uma altura explícita sempre prevalece.

As posições são `goleiro`, `zagueiro`, `ala_esquerda`, `ala_direita` e `atacante`. O carregador organiza o time pela posição, independentemente da ordem dos registros no arquivo, e verifica que há um jogador por posição em cada time. A posição de goleiro também define a roupa; não depende do índice visual do objeto.

O modelo-base fica no bloco `times` do mesmo JSON. Cada time contém uma lista `uniformes` com `id`, `nome`, `camisa`, `short`, `meiao`, `detalhe`, `camisa_goleiro`, `short_goleiro` e `meiao_goleiro`. `padrao` aceita `liso`, `listras_verticais` ou `faixa_peito`, usando `cor_secundaria` para o desenho da camisa. O bloco `partida` escolhe os dois times e os uniformes iniciais:

```json
"partida": [
  {"time": "brasil", "uniforme": "titular"},
  {"time": "argentina", "uniforme": "titular"}
]
```

O catálogo guarda vinte perfis e monta somente os dez jogadores da partida. Trocar o uniforme reutiliza os mesmos perfis, malhas, máscaras e animações; cores e listras são parâmetros do shader, sem texturas novas. O leitor também aceita o cadastro antigo de dois times com cores diretamente no time. Jogadores de linha usam **camiseta de manga curta, short, meião e chuteiras**. Goleiros usam **manga comprida, camisa de cor diferente, short e luvas claras**. A pele do rosto é uma única cor, sem olhos, sobrancelhas, boca ou detalhes fotográficos pintados. As sombras vêm da própria geometria e iluminação 3D.

### Recursos compartilhados e tamanho

As combinações não criam uma textura completa por jogador. Há **duas malhas-base, duas máscaras de regiões de 256 × 256 e um shader compartilhado**. As máscaras identificam pele, cabeça, camiseta, gola fechada, short, meião, chuteira, mão e a faixa que alterna entre braço descoberto e manga do goleiro. A gola tem acabamento estreito na cor da camisa, e o peito permanece inteiramente coberto. Cores e cabelo são parâmetros pequenos de material. Materiais idênticos são reutilizados; nome, número e biotipo não duplicam bitmaps nem materiais. Os clipes de futebol e os de chute/passe/desarme também são compartilhados por altura de esqueleto.

Os GLBs passaram de aproximadamente **1,96 MB juntos para 604 KB**, uma redução de cerca de **69% nas malhas empacotadas**, retirando fotos antigas e clipes de armas não usados. As duas máscaras somam aproximadamente **78 KB**. Vértices, índices, UVs, pesos, ossos e os quatro morphs de corpo permanecem idênticos. Isso é uma economia nos recursos dos personagens; o executável também contém o motor Godot.

`scripts/player_data.gd` define os registros; `roster_loader.gd` lê a escalação; `player_appearance.gd` compartilha modelos, máscaras e materiais. `tools/prepare_players.py` reconstrói as máscaras e compacta os GLBs, preservando as fontes em `tools/source/appearance_bases/`. Arquivos antigos e cópias de autoria ficam sob `tools/source/`, ignorado na exportação. A escalação JSON é incluída no executável.

### Biotipos

Há três tipos de corpo: **normal, magro e parrudo**, combináveis com qualquer altura do cadastro. Não há uma categoria separada para jogadores baixos ou altos. O cartão mostra, por exemplo, **PARRUDO / 1,72 m**. Os dois modelos originais continuam distintos e ambos possuem todas as combinações.

As quatro *shape keys* (morphs) existentes nos GLBs continuam como bases internas para combinar biotipo e altura contínua, deformando apenas os vértices existentes. A diferença entre as bases baixas e as originais permite encurtar ou alongar o corpo, inclusive no biotipo normal, preservando o tamanho da cabeça. Não há subdivisão, remalha, partes adicionadas, vértices extras ou ossos novos. Índices dos triângulos, UVs, índices dos ossos e pesos de skinning foram preservados. O modelo `hero` continua com **1.838 vértices e 866 triângulos**; o `enemy_a` com **1.840 vértices e 868 triângulos**, em qualquer biotipo e altura.

Magros têm seções menores de tronco e membros; parrudos têm mais volume em peito, ombros, braços e pernas. A altura é calibrada pela distância entre sola e topo da cabeça na pose de referência de cada modelo; poses com joelhos ou coluna dobrados podem reduzir a altura aparente. Os mesmos 65 ossos mantêm nomes, hierarquia e rotações. As translações de repouso, os vínculos inversos da pele e as translações das animações são ajustados juntos; não se usa escala do objeto para simular a altura. As cápsulas de colisão e os números acompanham o porte. Modelos, máscaras e materiais permanecem compartilhados; animações ajustadas são reutilizadas por modelo e altura. Corrida, fôlego, chute, passe e domínio usam as mesmas regras para todos os biotipos.

`scripts/body_types.gd` aplica os biotipos e adapta as animações. `tools/build_body_types.py` reconstrói as deformações com o Blender instalado, preservando cópias dos GLBs anteriores em `tools/source/body_bases/`. Para reconstruir:

```powershell
blender --background --factory-startup --python tools/build_body_types.py
python tools/prepare_players.py
```

O Blender também reimporta os resultados e valida vértices, pesos, shape keys e ossos. O relatório está em `docs/body_types_manifest.json`. Prévias das combinações de altura e corpo: `qa/altura-brasil.png`, `qa/altura-argentina.png`, `qa/altura-Jog_Fwd_Loop.png`, `qa/altura-shot.png` e `qa/altura-Slide_Loop.png`. O cartão atualizado está em `qa/altura-cartao.png`.

### Origem dos recursos

Os arquivos foram localizados em `C:\Users\Matheus\Documents\hotline rio`. O projeto original continua separado.

- **Characters_psx_1.2 (2).zip**: pack principal de personagens. Foram reaproveitados `hero.glb`, o protagonista do Hotline Rio (`Character_01.fbx`), e `enemy_a.glb` (`Character_04.fbx`). Brasil e Alemanha usam `hero`; Argentina e França usam `enemy_a`. São duas malhas diferentes, já adaptadas ao mesmo esqueleto pelo projeto anterior.
- **Characters_Extras_01 (1).zip**: pack adicional localizado e catalogado; não foi necessário usar outro personagem dele.
- **Universal Animation Library[Standard].zip**: extraído o `Unreal-Godot/UAL1_Standard.glb`. Foram usados `Idle_Loop`, `Walk_Loop`, `Jog_Fwd_Loop`, `Sprint_Loop` e `Jump_Land`; `Death01` também está na biblioteca extraída.
- **Universal Animation Library 2[Standard].zip**: extraído o `Unreal-Godot/UAL2_Standard.glb`. Foram usados `Slide_Start`, `Slide_Loop`, `Slide_Exit` e `Yes`; `Hit_Knockback` e `LayToIdle` fazem a queda e a recuperação após falta de carrinho. `Shield_Dash` também está disponível na biblioteca.

**Os packs não contêm chute ou passe de futebol.** Chute fraco, passe e bote foram criados com novas chaves de rotação sobre a pose do próprio esqueleto UAL, em `scripts/footballer.gd`. Os novos chutes médio e forte foram animados no Blender MCP e estão em `assets/animations/kicks.res`. O contato com a bola acontece no instante do chute. O carrinho usa a sequência real do segundo pack. Trote e corrida rápida usam clipes distintos do primeiro.

As novas máscaras foram pintadas nas UVs originais, usando a pose de referência e a influência dos ossos para localizar braços, pernas, mãos e cabeça. Pele, cabelo e uniformes acompanham a deformação do esqueleto, inclusive no carrinho. As fotos originais não são usadas no material do jogo.

O inventário **completo das animações dos dois ZIPs**, a lista de FBXs dos dois packs de personagens e seus caminhos internos estão em `docs/asset_inventory.json`. As bibliotecas de animação são de **Quaternius, CC0**; os textos originais estão em `docs/UAL1_License.txt` e `docs/UAL2_License.txt`. Essa licença refere-se às animações. Os modelos PSX mantêm a origem dos packs fornecidos pelo usuário.

## Árvore de animação dos jogadores

Os dez jogadores usam **`AnimationTree` com máquina de estados**. A locomoção mistura parado, caminhada, trote e corrida em um **`AnimationNodeBlendSpace1D`**, pela velocidade horizontal real: 0, 1,5, 4,5 e 7,4 m/s. Os quatro ciclos usam uma linha de tempo normalizada de um segundo e sincronização independente; uma taxa comum, calculada pela duração original dos clipes e pelos pesos da mistura, preserva a cadência e a fase dos passos. Isso evita o congelamento da locomoção observado com o modo cíclico na configuração de atualização manual usada pelo projeto. Chutes fraco, médio e forte, passe, bote, as três etapas do carrinho, impacto, queda, recuperação e comemoração têm estados próprios. As transições duram 0,10 s; a entrada dos chutes médio e forte usa 0,035 s.

Abra **`scenes/player_animation.tscn`** no editor e selecione o nó **AnimationTree** para editar o grafo; dentro de **States**, abra **Locomotion** para ajustar os pontos de velocidade. O recurso fica em **`assets/animations/player_tree.tres`**. O `AnimationPlayer` continua armazenando as bibliotecas compartilhadas, mas a árvore controla a reprodução durante a partida. `scripts/player_animation.gd` fornece os parâmetros e o controle dos estados; `scripts/footballer.gd` mantém as regras das ações e a movimentação física.

A árvore avança pelo delta da física, acompanha a câmera lenta e para na pausa. No contato de chute ou passe, um `AnimationNodeTimeSeek` aplica a pose do instante de contato antes do impulso da bola. Cada jogador possui seus próprios parâmetros e reprodução; o grafo e as bibliotecas continuam compartilhados. Reposições limpam os estados e as misturas anteriores. Alturas, biotipos, tempos de contato e regras de posse permanecem os mesmos.

`tests/animation_tree.gd` passou em **117/117 verificações** da mistura efetiva dos ossos nos dez jogadores, transições, pausa, interrupção por falta, reinício, independência entre jogadores, sequência do carrinho e os três chutes com impulso único na pose de contato. Também passaram os testes de regressão, controles, posse, cobranças, chutes, quedas, câmeras, biotipos e alturas, além de uma partida completa até o apito final. `tests/inspect_animation_tree.gd` renderiza as poses em `.runtime/animation-tree-locomotion.png` e `.runtime/animation-tree-actions.png`, sem atualizar as prévias finais. Para reconstruir o grafo padrão por código, execute `godot --headless --path . --script res://tools/build_animation_tree.gd`; esse comando substitui ajustes manuais no recurso.

A regressão de locomoção em `tests/locomotion.gd` passou em **92/92 verificações**: acompanha o relógio e o deslocamento efetivo dos pés ao longo de vários quadros, em seis velocidades nos dez jogadores, além de troca de velocidade, pausa e movimento real por teclado. Esse teste detecta ciclos congelados mesmo quando a mistura de poses está correta. Para conferir a sequência renderizada, execute `godot --path . --script res://tests/inspect_animation_tree.gd -- --record-locomotion`; seis instantes do movimento ficam em `.runtime/locomotion-motion.png`.

## Física e organização

- `CharacterBody3D`, cápsulas e `move_and_slide()` para os dez jogadores.
- `RigidBody3D`, `SphereShape3D`, `PhysicsMaterial` e detecção contínua para a bola.
- `StaticBody3D` e formas nativas para chão, postes e contenção da rede.
- `Area3D` para detectar entrada nos gols, com conferência da travessia completa da esfera.
- `apply_central_force()` na condução e `apply_central_impulse()` nos chutes, passes e desarmes.
- `AnimationTree`, máquina de estados, `BlendSpace1D`, `AnimationPlayer`, `AnimationLibrary` e `Skeleton3D` para os movimentos.
- `GPUParticles3D` para a poeira; `AudioStreamWAV` para os efeitos.

`scenes/main.tscn` é a cena de entrada. O campo e os jogadores são montados ao executar: `scripts/stadium.gd` cria o cenário; `match.gd` cuida da partida, IA e bola; `footballer.gd` do jogador; `hud.gd` da interface. Não há extensão de física ou dependência de plugin.

## Reconstrução e testes

Os recursos necessários para jogar já estão prontos. Para reconstruir a biblioteca a partir dos GLBs extraídos:

```powershell
godot --headless --path . --script res://tools/extract_animations.gd
```

Para reconstruir as máscaras e otimizar os modelos, use Python com Pillow: `python tools/prepare_players.py`. Para mudar apenas o elenco, os tons, o cabelo ou as cores do uniforme, basta editar os registros e as cores do time no JSON e executar novamente o projeto.

Validação executada no Godot 4.7.2:

```powershell
godot --headless --path . --fixed-fps 60 --script res://tests/regression.gd
godot --headless --path . --fixed-fps 60 --script res://tests/animation_tree.gd
godot --headless --path . --fixed-fps 60 --script res://tests/locomotion.gd
godot --headless --path . --fixed-fps 60 --script res://tests/control_camera.gd
godot --headless --path . --fixed-fps 60 --script res://tests/pitch_aim.gd
godot --headless --path . --fixed-fps 60 --script res://tests/shot_trajectory.gd
godot --headless --path . --fixed-fps 60 --script res://tests/goalkeeper.gd
godot --headless --path . --fixed-fps 60 --script res://tests/possession.gd
godot --headless --path . --fixed-fps 60 --script res://tests/body_types.gd
godot --headless --path . --fixed-fps 60 --script res://tests/appearance.gd
godot --headless --path . --fixed-fps 60 --script res://tests/player_heights.gd
godot --headless --path . --fixed-fps 60 --script res://tests/national_teams.gd
godot --headless --path . --fixed-fps 60 --script res://tests/arcade_ui.gd
godot --headless --path . --fixed-fps 60 --script res://tests/local_reactions.gd
godot --headless --path . --fixed-fps 60 --script res://tests/restarts_fence.gd
godot --headless --path . --fixed-fps 60 --script res://tests/juice.gd
godot --headless --path . --fixed-fps 60 --script res://tests/ball_fx.gd
godot --headless --path . --fixed-fps 60 --script res://tests/slide_moment.gd
godot --headless --path . --fixed-fps 60 --script res://tests/foul_fall.gd
godot --headless --path . --fixed-fps 60 --script res://tests/shot_moment.gd
godot --headless --path . --fixed-fps 60 --script res://tests/shot_sequence.gd
godot --headless --path . --fixed-fps 60 --script res://tests/shot_sequence_live.gd
godot --headless --path . --fixed-fps 60 --script res://tests/kick_variants.gd
godot --headless --path . --fixed-fps 60 --script res://tests/goal_net.gd
godot --headless --path . --fixed-fps 60 --script res://tests/praca_xv.gd
godot --headless --path . --max-fps 60 --script res://tests/capture_slide_moment.gd
godot --headless --path . --fixed-fps 60 --script res://tests/full_match.gd
godot --path . --script res://tests/capture.gd
godot --path . --script res://tests/capture_bodies.gd
godot --path . --script res://tests/capture_appearance.gd
godot --path . --script res://tests/capture_heights.gd
godot --path . --script res://tests/capture_arcade.gd -- --record-goal
godot --path . --script res://tests/capture_reactions.gd -- --record-reaction
godot --path . --fixed-fps 20 --script res://tests/capture_fence_restarts.gd -- --record-out
godot --headless --path . --max-fps 60 --script res://tests/capture_juice_audio.gd
godot --path . --fixed-fps 30 --script res://tests/capture_juice_camera.gd
godot --path . --fixed-fps 30 --script res://tests/capture_ball_fx.gd
```

A regressão cobre os modelos, clipes, movimentação, corrida, fôlego, domínio, passe, chute, desarmes, troca de jogador, gol físico, contagem única de gol, reposições, pausa e término de partida. Os testes adicionais cobrem mouse, ações contextuais, carga de chute, troca automática, câmera, gramado, redes laterais, mira no campo e velocidade e direção dos passes. A recepção e a posse têm 27 verificações próprias. Os biotipos têm 84 verificações de malha, topologia, pesos, ossos, vínculos, translações das animações, onze poses de futebol, altura e apoio dos pés. A montagem por cadastro e o compartilhamento visual têm outras 72 verificações. O teste de altura tem 186 verificações, incluindo os três corpos em cinco alturas nos dois modelos, medidas reais, cabeça, animações compartilhadas e migração de cadastros antigos. As seleções têm 1700 verificações dos 48 confrontos e combinações de uniformes e da troca no menu. A interface arcade tem outras 28 verificações de bandeiras, transições, gol em onda e layout. As reações locais têm 29 verificações, incluindo impacto real na trave, posse, faltas, projeção com a câmera, expiração e limpeza. Alambrado e cobranças têm outras 36 verificações de contenção, espera, posse pronta e comandos reais de mouse. Sons e câmera juicy têm outras 32 verificações de mistura, eventos e estabilidade da mira. A bola expressiva tem outras 22 verificações de rastro e contato sem alterar a física. O carrinho cinematográfico acrescenta 27 verificações e um teste com relógio real. A falta com queda acrescenta outras 55 verificações da sequência, câmera, pausa, duas equipes, alturas e reposição. A câmera de chute tem 67 verificações de direção, posição, prioridades, tempo, pausa, limites, mira e cobrança. As três variantes acrescentam 148 verificações de clique real, preparação, contato, câmera restrita ao forte, braços, apoio e preservação do esqueleto. O shader da rede acrescenta outras 37 verificações e uma prova de renderização por comparação de pixels. A sequência de chute, trave e rede tem 35 verificações de estados e 15 de integração com a bola física; o HUD também confere a espera antes do gol. O entorno da Praça XV acrescenta 46 verificações de geometria, preservação do campo e animação da água, além das inspeções de imagem. O teste de partida completa deixa as duas IAs jogar até o apito final. As capturas de interface, modelos e ações ficam em `qa/`.
