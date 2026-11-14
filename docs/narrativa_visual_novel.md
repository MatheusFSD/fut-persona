# Várzea FC: O Pregão — proposta narrativa da visual novel

Documento de narrativa para a visual novel integrada ao **Várzea FC**. O público é o autor e, depois, o designer de jogo que vai desenhar os sistemas. Os itens marcados como **mudança** alteram algo do pedido original e vêm com a justificativa.

Resumo em uma linha: **sete dias no Rio de Janeiro, vinte jogadores de 18 a 20 anos, um telão que transforma cada drible em preço e uma praça que só quer o seu domingo de volta.**

---

## 1. Premissa e tom

Há quase cinquenta anos, todo domingo tem Taça na Praça XV. Nesta semana não vai ter: o campinho do alambrado foi alugado pelo **Pregão**, um draft internacional em que 160 jogadores de 18 a 20 anos, de 32 países, passam sete dias jogando partidas-relâmpago de três minutos em campinhos espalhados pelo Rio. Enquanto isso, um telão pendurado no casarão em frente ao campo transforma cada drible em cotação. No sábado à noite, um sino toca, os clubes escolhem e os contratos são assinados ali mesmo, na pedra da praça. Você é um dos vinte jogadores do **Grupo Praça XV**: brasileiro, argentino, alemão ou francês, goleiro ou camisa 9, e tem uma semana para descobrir quanto vale. O tom é o mesmo da interface: arcade, recortado, barulhento, cheio de sol e de piada. São garotos longe de casa pela primeira vez, empolgados com tudo o que pode acontecer: fazem amizade com o rival, aprendem samba errado, se queimam de sol, se apaixonam e jogam bola como quem respira. Mas a semana cobra. Entre segunda e sábado, a euforia dá lugar a perguntas de gente grande: dinheiro e família, contrato e letra miúda, lealdade ao time ou a chance que aparece uma vez só, a vida exposta num telão. Eles enfrentam essas perguntas sem perder a energia, porque é com ela que respondem. Por baixo de tudo, a praça faz uma pergunta que o telão não sabe responder: **quanto vale um domingo?**

### Ligação com a identidade atual do jogo

| O jogo já tem | A visual novel usa assim |
| --- | --- |
| Taça Praça XV, praça carioca fictícia com cais, barca, arco, chafariz, quiosque, praia e morro | É o palco inteiro da história. Os cenários da VN são, na maioria, **renders do próprio cenário 3D**. A Taça é o que foi tirado da praça e o que volta no domingo. |
| Título do arcade: "Domingo de clássico" | É literalmente o último capítulo. O modo arcade existente passa a ser "o domingo depois da história". |
| Partidas de 3 minutos, 5x5 | Formato oficial do Pregão: "três minutos de pressão mostram mais do que noventa de conforto", diz o regulamento. |
| Reações ENTORTOU!, NA BOLA!, MILAGRE!, FOI MAL! | Viram eventos que mexem na cotação, e o telão comenta cada uma. |
| Interface de recorte de papel, balões com rabo de raio, letras de revista | Caixa de diálogo, calendário, notas de olheiro e telão da cotação são desenhados com as mesmas formas de `ui_shapes.gd`, sem imagem nova. |
| Retratos, comemorações e expressões em estilo cartum | São os sprites da VN. A comemoração de cada um vira a expressão "feliz/orgulhoso". |
| Jovens com sonhos se divertindo num torneio no Rio | É o coração do texto. A crítica ao mercado é o pano de fundo, nunca uma palestra. Regra de escrita: **para cada cena pesada, duas leves.** |

### Tema central: o seu passe só vale se você passar

Em português, "passe" é a bola que vai de um pé para o outro e também, no jargão antigo do futebol, o direito sobre o jogador: o "valor do passe". O Pregão vive dessa ambiguidade. A cotação é individual e aparece no telão com um nome só, mas **só sobe de verdade quando o protagonista joga para os outros e o time vai bem**.

Nas partidas, **o jogador controla o time inteiro**, como no arcade, e não fica preso ao protagonista. É uma decisão do autor, e é de propósito: quem joga decide, com a mão, se a bola vai para o protagonista, para o companheiro mais bem colocado ou, no Dia Misto, para o rival que hoje veste o mesmo colete. O conflito entre o individual e o coletivo deixa de ser só tema e passa pelo controle. Fora de campo, a história repete a mesma pergunta: o contrato é individual, mas a praça só se salva junto.

### Tom em seis regras

1. **Leve por padrão.** O humor nasce dos personagens (o alemão queimado de sol no primeiro dia, o portunhol, o clube dos goleiros), não de piadas sobre países.
2. **Nada de superpoderes.** Não há chute especial, time mais forte do mundo nem protagonista escolhido pelo destino. O que muda o jogo são pessoas e escolhas.
3. **O sistema é o antagonista, não um vilão.** O Índice não quer dominar o mundo; quer medir tudo. Quem o criou acredita, sinceramente, que está ajudando.
4. **Nenhuma partida "salva o campinho".** O destino da praça é decidido por escolhas e alianças, nunca pelo placar. O jogo de domingo é celebração, não final de vida ou morte.
5. **Realismo esperançoso.** As vitórias são pequenas e reais: uma cláusula num contrato, uma fita devolvida, um domingo recuperado.
6. **Dilema sem sermão.** Toda decisão de peso tem ganho real e perda real nos dois lados. O jogo nunca diz qual é a certa, e ninguém é castigado por escolher a família ou o dinheiro.

### Arco de tom: da euforia às decisões de adulto

Os jogadores têm de 18 a 20 anos e chegam empolgados com tudo o que pode acontecer. A semana não tira essa energia; muda o que eles fazem com ela. A euforia da segunda-feira vira coragem para decidir no sábado. A apresentação acompanha essa curva **sem trocar de estilo**: é sempre a mesma interface de recorte de papel, mas ela muda de temperatura.

| Capítulo | Emoção dominante | Dilemas que aparecem | Como aparece na apresentação |
| --- | --- | --- | --- |
| **1. Abertura** (Seg–Ter) | Euforia, deslumbramento, provocação entre rivais | Pequenos e engraçados: furar o toque de recolher para ir ao samba? Responder a provocação no chat? Primeiro aviso de que tudo está sendo filmado. | Paleta saturada: rosa, ciano e amarelo. O calendário entra com explosão e letras pulando ("SEGUNDA!"). O ticker mostra quase só ▲ amarelo. Música rápida, escolhas engraçadas, o telão fazendo piada ("Bom dia, ativos!"). |
| **2. Dia Misto** (Qua–Qui) | Pressão, comparação, a primeira rachadura | **Dinheiro e família:** a família de Rafa pede que ele aceite a primeira oferta; a cidade de Leon fez vaquinha; um agente oferece adiantamento a Bruno. **Exposição:** os Olhos, os vídeos virais, o vazamento, o rótulo "risco de imagem". **Individual ou coletivo:** no Dia Misto, o melhor passe é para o rival de colete, e é o pior para a cotação. | Os mesmos elementos com rasgos maiores. O ▼ em rosa-choque pisca no ticker. O celular vibra com notificações que se empilham na tela. As notas de olheiro ficam secas. Escolhas de peso ganham um carimbo próprio ("ISSO FICA"). A música ganha uma versão com baixo mais pesado. As partidas e as cenas leves continuam no mesmo ritmo, porque é ali que eles respiram. |
| **3. Fechamento** (Sex–Sáb) | Decisão, lealdade, coragem | **Contratos:** cláusula de exclusividade, direito de imagem, multa rescisória (Noé lê com você). **Lealdade ou oportunidade:** na quinta, um clube oferece pré-contrato se você não jogar o clássico de sexta; ajudar Duda pode quebrar a sua cláusula; proteger Iara ou entregá-la. **Consequência real:** o que se assina fica assinado. | Telas de escolha em preto e creme, com letras recortadas grandes e sem cor, o momento mais "Persona" do jogo. O contrato aparece como um documento recortado, com cláusulas sublinhadas que dá para ler uma a uma. O sino tem tela própria. Um caderno mostra as decisões já tomadas e quem lembra delas. |
| **4. Domingo de clássico** (Dom) | Alegria de novo, mas sabendo o preço | Viver com o que escolheu. | A cor volta toda, mais quente: laranja de sol de domingo, pipas e confetes da interface atual, a faixa "TAÇA PRAÇA XV" de volta no alambrado. A energia do Capítulo 1 retorna transformada. |

**Na prática:** os personagens enfrentam os dilemas do jeito que têm, falando rápido, brincando e jogando bola. A cena da proposta antecipada, por exemplo, acontece num racha na praia, entre um gol e outro, e não numa sala escura.

---

## 2. O mundo do Pregão

### Mudança: de "draft" para "Pregão"

No futebol não existe draft; ele é um formato norte-americano (NBA, NFL). Proponho chamar o evento de **Pregão**, a sessão de negociação da bolsa de valores. A palavra faz três coisas de uma vez: deixa a metáfora do mercado concreta, soa brasileira e amarra o evento à praça, já que a antiga Bolsa de Valores do Rio funcionou na Praça XV (vale conferir o dado antes de usar em material de divulgação). Estrangeiros e imprensa continuam dizendo "o draft" e "el draft"; os cariocas dizem "o Pregão", com uma careta.

### Como funciona

| Item | Regra no mundo da história |
| --- | --- |
| Quem organiza | **Índice**, empresa de avaliação de atletas com sede em Lisboa, financiada pelo **Consórcio dos 40**, 40 clubes de cinco continentes que contratam pelo Pregão. O rosto público é o fundador, Augusto Leal. |
| Quem participa | 160 jogadores de 32 países, convidados pelo ranking do Índice. **Idade: de 18 a 20 anos completos no credenciamento.** Quem faz 21 sai da lista ("a geração que passou"). |
| Por que só maiores de idade | Os contratos assinados no Fechamento valem na hora, em qualquer país. O credenciamento confere documento. A regra é parte da ficção, e não só um aviso. |
| Onde | Oito grupos de quatro seleções. Cada grupo tem uma **praça-sede**, onde se hospeda e onde acontece o seu Fechamento, mas joga em **rodízio por campinhos da cidade**: o Índice quer ver cada jogador com outro piso, outra torcida e outra pressão. A história acompanha o **Grupo Praça XV**. Os outros grupos aparecem no telão, no celular e nas conversas. |
| Quais seleções | Na primeira versão, Brasil, Argentina, Alemanha e França. Quando o autor criar mais seleções, o grupo da história passa a ser sorteado na escolha do protagonista (seção 4.7). |
| Formato | Sete dias. Uma partida de 3 minutos por dia, de segunda a sexta, cada dia num campo (seção 2, "Os campos do Pregão"). Sábado à noite é o **Fechamento**; domingo era da Taça. |
| Cotação | Cada jogador tem uma cotação pública, atualizada às 8h no telão, que define o piso do contrato que um clube precisa oferecer para escolhê-lo. Compõem a nota: desempenho em campo, "objetivos de olheiro", engajamento do público (curtidas, sem dinheiro nem apostas) e uma parte que o Índice não explica. |
| Câmeras | Os "Olhos" do Índice ficam nos postes da praça. Tudo o que acontece em público pode entrar na cotação. |
| Camisa obrigatória | Em público, todo jogador usa a camisa da seleção, por exigência de patrocínio. Isso também justifica por que os retratos existentes servem para quase todas as cenas. |
| Sem técnicos | **Mudança:** o Pregão não tem comissões técnicas. "Queremos ver quem lidera", diz o regulamento. Isso elimina quatro personagens que exigiriam arte e cria tensão de liderança dentro de cada seleção. |
| Cláusula de exclusividade | Durante a semana e depois de assinar, o jogador não pode disputar partidas não oficiais. Por isso a Taça foi suspensa, e é por isso que jogar no domingo vira uma decisão. |
| Fechamento | No sábado à noite, o sino da Casa do Pregão toca e os clubes escolhem em ordem. Quem não é escolhido vai para "a fila" de transferências do ano seguinte. |

### O que está em jogo

- **Para os jogadores:** o primeiro contrato da vida, ou a volta para casa sem ele. Para alguns, a última chance pela idade.
- **Para a praça:** se o Pregão der certo, a Praça XV vira sede permanente do evento. A Taça acaba, e o campinho vira "Arena Índice".
- **Por baixo:** o segredo do Índice (seção 4, Capítulo 2). O algoritmo aprendeu o que é talento assistindo a quase cinquenta anos de **fitas VHS da Taça Praça XV**, gravadas pelo fundador do torneio. Cada jogador do Pregão é comparado a um craque anônimo da praça, que nunca recebeu nada por isso.

### Por que no Rio

Na versão oficial, "todo mundo já jogou no Rio em sonho" e a prefeitura apostou no evento como vitrine. A versão verdadeira é revelada aos poucos: o Pregão nasceu na Praça XV. Augusto Leal jogou a final da Taça de 1991 e perdeu a carreira com uma lesão no joelho aos 21 anos. Construiu o Índice para que "nenhum talento passasse despercebido de novo", usando as fitas do campinho onde ele mesmo não foi visto.

### Lugares da Praça XV

Todos já existem no cenário 3D, com nomes de ficção:

| Lugar | Uso na história |
| --- | --- |
| **Campinho do alambrado** | Partidas, treinos e a cena do alambrado, em que o lado de dentro vale e o de fora não. |
| **Casa do Pregão** (fachada inspirada no Paço) | Sede do Índice, com o telão da cotação e o sino. |
| **Cais e estação das barcas** | Chegada das delegações, conversas ao amanhecer e o turno de Vitor na barca. |
| **Arco** | Roda de samba de segunda à noite, inspirada nas rodas de segunda do Rio. Fica no Arco para reaproveitar o 3D. |
| **Quiosque do Beto** ("Cais da Bola") | QG da praça, onde guardam as fitas. |
| **Chafariz** | Dominó dos veteranos e conversas de fim de tarde. |
| **Praia e calçadão** | Treino noturno, açaí e a primeira vez que alguém de Colônia vê o mar do Rio. |
| **Morro do Cais** (fictício) | Onde moram Iara e Vitor. Aparece só como vista ao fundo. |
| **Rua lateral com ônibus** | O ônibus é dirigido por um ex-craque da Taça. |

### Os campos do Pregão

Além da Praça XV, o grupo joga em **três campos novos**, um por dia, de quarta a sexta. Cada um mostra um Rio diferente e muda o tom do dia.

**Regra de produção:** todo campo usa **exatamente o mesmo campinho da Praça XV**: gramado, marcações, gols, redes e alambrado de 4 m, com as mesmas medidas (27,2 m e 16,6 m do centro) e os mesmos colisores. Só muda o **entorno**, montado por um script próprio no padrão de `praca_xv.gd`, com peças reaproveitadas e no máximo cerca de 12 mil triângulos. Física, regras e partida não mudam. O gramado pode ganhar outra cor ou desgaste só pelo shader.

| Campo | Onde fica no Rio (ficção) | Caráter | Por que o Pregão usa | Quando entra | Entorno 3D: reaproveita / novo |
| --- | --- | --- | --- | --- | --- |
| **Praça XV** (já existe) | Centro histórico, na beira da baía | História, cais, telão, a casa do grupo | É a praça-sede: alojamento, Casa do Pregão e Fechamento | Seg, Ter, Sáb, Dom | Já pronto. |
| **Campo do Viaduto** | Zona Norte, debaixo de um viaduto de trem num bairro fictício inspirado nos subúrbios como Madureira | Barulho, trem passando a cada quatro minutos e fazendo o alambrado tremer, torcida colada na cerca, baile charme debaixo do viaduto à noite | O "teste de pressão": o Índice quer ver como cada um joga com barulho e torcida que não é dele. É o palco do **Dia Misto** | Quarta (Cap. 2) | Reaproveita casas do morro como casas de laje, quiosque como barraca de churrasquinho, postes e espectadores. Novo: pilares e tabuleiro do viaduto (caixas), um trem de seis vagões que passa, muros grafitados com cores por vértice, gramado sintético gasto (shader). |
| **Campo do Mirante** | No alto do Morro do Cais, logo acima da Praça XV | Campo da associação de moradores, gramado sintético doado, pipas, caixas-d'água e vista da baía. Lá de cima, o telão da Praça XV parece pequeno. | "Pregão na Comunidade": treino aberto e foto com patrocinador. A história mostra a hipocrisia e, ao mesmo tempo, um momento verdadeiro: Duda e as moradoras desafiam os meninos do Pregão (cena de VN) | Quinta (Cap. 2). O vazamento acontece nessa noite | Reaproveita casas e caixas-d'água do morro, a água com shader, as ilhas e o casario ao fundo. Novo: escadaria e muro de contenção, fios com pipas, varandas com bandeirinhas. |
| **Campo do Posto** | Orla da Zona Sul, num "Posto 7" fictício inspirado nas quadras da orla de Copacabana | Vitrine: arquibancada tubular, prédios de hotel, telão de LED do patrocinador, turistas, influenciadores e transmissão de TV | O **Clássico de sexta** é o jogo televisionado do Pregão: "o nosso Maracanã é na areia" | Sexta (Cap. 3) | Reaproveita praia, coqueiros, guarda-sóis, calçadão ondulado e os edifícios distantes, trazidos para perto. Novo: arquibancada (caixas), telão de LED (um retângulo com textura de viewport), estúdio de transmissão de vidro. |
| *Opcional, depois:* **Campo do Gragoatá** | Niterói, do outro lado da baía, ida de barca | Para uma expansão ou um novo grupo | — | — | Reaproveita a barca e a água. |

**Cuidado com o Mirante e o Viaduto:** mostram a cidade fora do cartão-postal com o mesmo carinho da Praça XV. Não há tiroteio, tráfico nem pobreza como cenário de drama. Quem mora ali tem nome, opinião e humor (Duda, Iara, Vitor, a associação de moradores).

---

## 3. Elenco

### 3.1 Nomes: proposta de adotar os nomes da arte

**Recomendação: usar os nomes da arte (Rafa, Douglas, Tico...) como nomes oficiais, no jogo e na VN.** Motivos:

1. **Distância de pessoas reais.** Os nomes do cadastro são homenagens fáceis de decifrar: Roni lembra Ronaldo, Basti lembra Batistuta, Zian lembra Zidane, Klas lembra Klose e Fabi lembra Fabien Barthez. Num arcade isso é charme. Numa história com romance, conflitos íntimos e famílias, associar personagens a atletas reais vivos é um risco de imagem e de direito. As referências históricas continuam como nota interna de design (atributos e estilo de jogo), não como identidade dentro da ficção.
2. **Diálogo.** Na VN, as pessoas se chamam pelo nome o tempo todo. "Santiago", "Malik" e "Noé" soam como gente; nomes de três letras feitos para o card soam como apelidos de máquina.
3. **Diversidade.** Os nomes da arte já refletem a variedade de cada país (Malik, Amadou, Noé, Emil, Jonas).
4. **Menos erro de produção.** Os arquivos já têm esses nomes. A tabela de correspondência do README deixa de ser necessária.

**Custo:** o card do HUD foi pensado para 3 a 5 letras. Proponho um campo `nome_camisa` de no máximo 7 letras, com dois apelidos: **Santiago → Santi** e **Nicolás → Nico**. Os demais cabem como estão (Douglas e Juninho têm 7). Alturas, atributos, corpos e posições continuam os do cadastro.

> Nota: Lukas (Alemanha) colide com o retrato inicial `lucas.png`. Por isso o personagem que usa `lucas.png` passa a se chamar **Vitor**.

### 3.2 Os vinte protagonistas jogáveis

Todos têm **de 18 a 20 anos**. A "comparável" é o craque da fita da Taça com quem o Índice compara cada jogador; o fio aparece no Capítulo 2. Algumas comparáveis são mulheres da Taça feminina, porque o algoritmo não separa por gênero.

**Grupos por posição.** Os quatro jogadores de cada posição formam grupos que atravessam as seleções, uma das camadas de texto da seção 4: o **Clube das Luvas** (goleiros), a **Muralha** (zagueiros), a **Canhota** (alas esquerdos), os **Herdeiros** (alas direitos) e os **Camisas 9** (atacantes).

#### Brasil: "jogar em casa pesa"
Todo mundo conhece os brasileiros, e a praça os trata como seus. A cotação deles infla com a torcida, e cair diante dela dói em dobro.

| Nome (cadastro) | Idade, origem, posição | Personalidade | Conflito pessoal | Comparável na fita |
| --- | --- | --- | --- | --- |
| **Rafa** (Ivo) | 20, Belford Roxo (RJ), goleiro | Cuida de todo mundo, faz piada de tio, conta os passos antes do tiro de meta. Trabalha de entregador de moto. | É o único "da casa": 40 parentes na praça. Uma cotação baixa vai ser vista por todos que ele conhece. | **Lucinha Paredão**, goleira da Taça feminina, 1996 |
| **Douglas** (Zeca) | 20, Salvador (BA), zagueiro | Gigante gentil, faz coração com as mãos e cozinha para todo mundo. | Trava na frente da câmera, e o Índice mede "presença". Precisa aprender a ser visto sem fingir. | **Tião Muralha**, 1983, hoje no dominó do chafariz |
| **Tico** (Cadu) | 18 (fez em março), Manaus (AM), ala esquerda | Provocador, rápido, faz a comemoração do "não tô ouvindo". É o caçula do grupo. | Ouviu a vida toda que era "pequeno demais" (1,69 m). Joga com raiva para provar algo e precisa descobrir para quem. | **Pipoca**, 1999, hoje motorista do ônibus da rua lateral |
| **Juninho** (Digu) | 20, Juiz de Fora (MG), ala direita | Desengonçado e sonhador, toca cavaquinho e inventa música sobre todo mundo. | É filho do "Júnior", promessa dos anos 1990 que não vingou, e a imprensa já o chama pelo fracasso do pai. Quer um nome próprio (o verdadeiro é Joaquim). | **Zé Lápis**, 1988, desenhava jogadas em guardanapo |
| **Cauã** (Roni) | 19, Belém (PA), atacante | Confiante e de braços cruzados. Viralizou aos 15 com um gol de 30 milhões de visualizações. | Começa com a maior cotação do grupo. Tem medo de ser só barulho e não pode ser visto jogando mal. | **Raio**, 2007 |

#### Argentina: "visitantes"
Vaiados na praça, unidos por isso. Descobrem que o Rio também sabe receber, e a rivalidade com o Brasil vira, aos poucos, outra coisa.

| Nome (cadastro) | Idade, origem, posição | Personalidade | Conflito pessoal | Comparável |
| --- | --- | --- | --- | --- |
| **Tomás** (Tano) | 20, Mendoza, goleiro | Calmo fora de campo, faz o gesto do "calma" e grita o jogo inteiro dentro dele. Acorda às 4h para a padaria do pai e anota cada chute que recebe num caderno. | Acredita em números, até os números mentirem sobre ele. | **Gringo Ferraz**, 1979, marinheiro argentino que jogou a primeira final da Taça |
| **Bruno** (Muro) | 20 (faz 21 em dezembro), Avellaneda, zagueiro | Barulhento, ri com o corpo inteiro e protege o Santiago como irmão desde o infantil. | É o último ano em que tem idade para o Pregão: agora ou nunca. Um agente oferece um adiantamento em dinheiro se ele assinar antes do sábado. Funciona como espelho de Vitor, que já passou da idade. | **Dona Cida**, zagueira de 1994, hoje vende mate na praia |
| **Mateo** (Fito) | 19, Lanús, ala esquerda | Fala pouco e comemora com "shh" para calar a torcida. Gosta escondido de funk carioca. | Funciona melhor quando é vaiado. Descobre que o silêncio virou um muro que ele mesmo construiu. | **Mudo**, 1990 |
| **Santiago** (Lito) | 20, Córdoba, ala direita | Sincero e caloroso, dedica os gols à avó, Nona Chela, e fala portunhol com entusiasmo. **Rota de romance** (seção 5). | A imprensa argentina o chama de "el heredero" e ele odeia comparações. É gay, assumido para a família e o time, discreto em público. | **Bailarino**, 1985 |
| **Nicolás / Nico** (Basti) | 20, La Plata, atacante | Irônico e cerebral, faz o gesto do "pensa". Trancou a faculdade de Medicina. | É o único que ficaria bem sem futebol, e essa liberdade assusta os outros, e a ele também. | **Doutor**, 1981 |

#### Alemanha: "a planilha"
São os únicos que leram o manual do Índice inteiro e os que mais acreditam no sistema. Por isso a revelação das fitas os atinge com mais força.

| Nome (cadastro) | Idade, origem, posição | Personalidade | Conflito pessoal | Comparável |
| --- | --- | --- | --- | --- |
| **Lukas** (Falk) | 20, Hamburgo, goleiro | Organiza horários e aplaude todo mundo. | Foi nomeado capitão pelo ranking, não pelo voto. Quer merecer o posto. | **Capitão Nono**, 1992 |
| **Jonas** (Jaro) | 20, Berlim, zagueiro | Educado e sincero. A mãe é de Madureira, e ele fala português "de mãe", com sotaque alemão e gírias de 1998. | Podia ter jogado pelo Brasil. A torcida da praça o reivindica, e ele precisa entender de onde é. | **Seu Madureira**, 1984 |
| **Emil** (Miro) | 19, Colônia, ala esquerda | Pura alegria, faz sinal de paz e quer ver tudo: samba, praia, açaí. | O Índice classifica o drible dele como "risco" e a alegria como "ineficiência". É o tema do jogo inteiro numa pessoa só. | **Pandeiro**, 1987 |
| **Felix** (Tilo) | 20, Leipzig, ala direita | Tímido e perfeccionista. Queima-se de sol no primeiro dia, piada que dura a semana inteira. | Entra em pânico com números públicos. Precisa aprender a errar na frente dos outros. | **Régua**, 1995 |
| **Leon** (Klas) | 19, Flensburg, atacante | Moicano ruivo, polegares apontando para si, fanfarrão. Nunca tinha andado de avião. | A cidade dele fez vaquinha para a viagem, e ele acha que não pode voltar de mão vazia. A bravata esconde medo. | **Fogueira**, 2001 |

#### França: "lendo as letras miúdas"
São os céticos do grupo. Chegaram como favoritos e já com preço; o arco deles é redescobrir o jogo por diversão e ler o contrato antes de todo mundo.

| Nome (cadastro) | Idade, origem, posição | Personalidade | Conflito pessoal | Comparável |
| --- | --- | --- | --- | --- |
| **Hugo** (Fabi) | 19, Bordeaux, goleiro | Sereno, de humor melancólico, joga xadrez no celular. | Foi chamado 48 horas antes porque o titular se machucou e sente que não deveria estar ali. | **Reserva**, 1997, reserva que ganhou uma final |
| **Malik** (Daro) | 20, Saint-Denis, zagueiro | Carismático e irmão mais velho do time, manda beijo para a torcida e fala por provérbios. Estuda para ser professor. | Carrega todo mundo, mas ninguém o carrega. | **Tio Bené**, 1986 |
| **Noé** (Zian) | 20, Marselha, ala esquerda | Elegante e lacônico, faz o "ok" com piscadela. Lê cada cláusula do contrato (a irmã é advogada). | Veio provar que o Índice está errado e se assusta com o quanto ele acerta sobre ele. | **Sedinha**, 1989, ala da Taça feminina |
| **Louis** (Rivo) | 19, Lyon, ala direita | Romântico e tímido, escreve cartas à mão. | Ama o clube de bairro onde joga em Lyon e não sabe se quer mesmo ser profissional. | **Saudade**, 1993 |
| **Amadou** (Enzo) | 20, Paris, atacante | Intenso e calado, desenha os prédios da praça num caderno. Estuda arquitetura. | Os pais, uma médica e um engenheiro, querem que ele termine a faculdade. O futebol é a rebeldia dele. | **Arquiteto**, 1980 |

> Cuidado de representação: os conflitos foram distribuídos para **não ligar pobreza, raça e nacionalidade**. Há entregador branco e arquiteto negro, ansiedade alemã e alegria alemã, e nenhuma piada depende de estereótipo de país. Antes de lançar, vale ter leitores de cada contexto (diáspora francesa, afro-brasileira, LGBTQIA+) revisando as rotas e as cenas pessoais.

### 3.3 Personagens novos e reaproveitados

| Personagem | Idade | Origem | Personalidade | Conflito | Papel | Arte |
| --- | --- | --- | --- | --- | --- | --- |
| **Iara Monteiro** | **22** | Morro do Cais (Rio) | Rápida e irônica, "fala quatro línguas mal e uma bem: a minha". Estuda Letras e foi zagueira da Taça feminina até os 16. | Quer ser intérprete de futebol internacional, e o Pregão é o portfólio dela. O emprego paga o semestre, e o contrato proíbe envolvimento com atletas. Ela viu as fitas e está calada. | Ponte de idiomas e acesso ao lado de dentro do Índice. **Autora do vazamento em todas as versões.** Também tem rota de romance. | Nova (polo creme com gola ciano, da equipe do Índice) |
| **Duda Ferraz** (Maria Eduarda) | **19** | Morro do Cais | Debochada, competitiva, trabalha na barraca de açaí da orla. Camisa 10 e capitã do Unidos do Cais feminino, artilheira da Taça feminina. | O Pregão não tem edição feminina ("ano que vem", diz Augusto há três anos). Quer ser vista por um clube; a mãe quer que ela faça concurso público. Joga rachas noturnos na areia contra os jogadores do Pregão, debaixo dos Olhos, para entrar nos dados do Índice. | A futebolista da história. Mostra o que o Pregão deixa de fora e organiza a final feminina da Taça no domingo. Também tem rota de romance. | Nova (camisa do Unidos do Cais) |
| **Jade Moreira** ("@jadenacancha") | **21** | Campo Grande, Zona Oeste do Rio | Rápida, engraçada, calculista quando precisa, generosa quando ninguém está filmando. Começou fazendo embaixadinhas na laje de casa e hoje é **freestyler** com 2 milhões de seguidores. | Foi contratada como **embaixadora digital do Pregão**, e o que ela posta mexe na parte de "engajamento" da cotação. Quer deixar de ser "a menina das embaixadinhas" e lançar a própria liga de 5x5 feminino. A marca pede que ela pareça "da Zona Sul", e ela esconde de onde vem. O contrato dá ao Índice os direitos da imagem dela: ela também é um ativo. | A exposição: decide quem aparece e é a voz do Clássico televisionado. Aliada improvável de Duda (ela tem a audiência, Duda tem o jogo) e rival de Mika (marketing contra jornalismo). Também tem rota de romance. | Nova (jaqueta de patrocinador sobre camisa de freestyle) |
| **Vitor Nascimento** | **23** | Morro do Cais | Quieto, seco, engraçado sem querer. Marinheiro de convés das barcas Rio–Niterói, goleiro do Unidos do Cais. | Foi cortado de uma peneira aos 17, passou da idade do Pregão e para o Índice "vale zero". Está na última fita da Taça. | **Rota de romance.** Representa quem ficou do lado de fora do alambrado. | **Reaproveita `retratos_iniciais/lucas.png`**: usa a camisa laranja de goleiro da peneira, única coisa que trouxe de lá |
| **Mika Tanaka Ribeiro** | **24** | São Paulo (Liberdade), nipo-brasileira | Barulhenta, impaciente, ex-goleira de futsal, péssima com tecnologia (a live dela sempre cai). Apresenta o canal "Linha de Fundo". | Quer transformar o canal num veículo de verdade, e a história das fitas pode ser a reportagem da carreira dela. O Índice oferece acesso exclusivo se ela "colaborar". | A imprensa: **recebe o vazamento e decide o que publicar em todas as versões.** Também tem rota de romance, em que namorar alguém que ela cobre vira um problema ético real. | Nova (jaqueta de imprensa) |
| **Augusto Leal** | 52 | Carioca da praça, mora em Lisboa | Voz mansa e precisa, generoso e convicto. | Perdeu a carreira aos 21. Comprou as fitas "para preservar" e nunca assistiu à própria final. | Antagonista: o rosto do sistema, não um vilão. | Nova (terno de linho, broche do Índice) |
| **Beto Cais** (Roberto Ademar Filho) | 38 | Praça XV | Escandaloso, engraçado, de moicano vermelho ("o cabelo do meu pai"). Dono do quiosque e técnico do Unidos do Cais. | Filho de Seu Ademar, que fundou a Taça e filmou todas as finais. Assinou um "projeto de museu" sem ler. | Mentor cômico, coração da praça. | **Reaproveita `retratos_iniciais/beto.png`** |
| **Caio Ramos** | 20 | Saúde (Rio) | Magro, cético, língua afiada. | Ganhou a Taça do ano passado e entrou no Pregão como "convidado local", golpe de marketing com camisa do Brasil emprestada. Quer provar que não é enfeite. | Rival e amigo. É reserva universal e pode entrar em qualquer time. Cúmplice de Iara. | **Reaproveita `retratos_iniciais/caio.png`** |
| **ÍNDICE** (voz) | — | — | Voz sintética e simpática do telão: "Bom dia, ativos." | — | Narrador-coro, piada recorrente e ameaça. | Nenhuma (texto no telão) |
| **Olheiros** | adultos | Seis clubes fictícios: Porto Oriental (POR), FC Rheinhafen (ALE), Club Puerto Sur (ARG), AS Calanques (FRA), Kōbe Harbour SC (JPN), Lagos Lagoon FC (NGA) | Cada clube escreve de um jeito: o alemão em números, o argentino quase em poesia. | — | Aparecem só como **notas de olheiro**, cartões recortados no estilo da interface. | Nenhuma |
| **Seu Ademar** | falecido | Praça XV | — | — | Fundou a Taça em 1979. A caligrafia dele nas etiquetas das fitas é a prova. | Nenhuma |

### 3.4 As quatro mulheres da história: função antes do romance

O elenco jogável é todo masculino, mas a história não é. Iara, Duda, Jade e Mika foram desenhadas para **funcionar sem rota romântica**. Cada uma tem objetivo próprio, um lugar no Pregão, no futebol ou no Rio, e um arco que se fecha mesmo que o jogador nunca flerte com ela.

| Personagem | Lugar no mundo | O que ela quer | O que ela faz no enredo em **toda** jogada | Como o arco dela termina sem romance |
| --- | --- | --- | --- | --- |
| **Iara** (22) | Dentro do Pregão: intérprete e anfitriã das delegações | Uma carreira de intérprete no futebol internacional, sem trair a praça onde cresceu | Traduz (e às vezes salva) os jogadores, vê as fitas no salão do Índice e **faz o vazamento** com a ajuda de Caio. | Assume publicamente o vazamento no Fechamento. Perde o emprego no Índice e ganha, pelo jeito como agiu, um convite de uma federação. |
| **Duda** (19) | No futebol: a melhor jogadora da praça, sem vitrine | Ser vista por um clube, ter o próprio Pregão | Desafia os jogadores do Pregão para rachas na areia; mostra ao protagonista o que é jogar sem câmera; organiza a **final feminina da Taça** no domingo. | Uma olheira do Lagos Lagoon FC, que só veio pelos meninos, vê a final de domingo. No melhor final da praça, o Índice anuncia a edição feminina com Duda na primeira lista; no outro, ela consegue um teste. |
| **Jade** (21) | Na exposição: a influenciadora oficial do Pregão | A própria liga de 5x5 feminino e uma carreira que não dependa de parecer outra pessoa | Os vídeos dela fazem a cotação do protagonista subir ou cair (um ENTORTOU! ou um tropeço viralizam já no primeiro dia). Grava os desafios de embaixadinha na praça. No vazamento, descobre que cada post dela tinha um preço na planilha do Índice. **Apresenta o Clássico de sexta** e decide se sai do roteiro. | Sai do roteiro ao vivo no Clássico, lê os nomes dos craques das fitas e mostra Campo Grande pela primeira vez. No domingo, transmite a final feminina da Taça de Duda para os 2 milhões de seguidores: é o primeiro jogo da liga dela. Renegocia ou rompe o contrato, conforme o final da praça. |
| **Mika** (24) | No Rio, como imprensa: a voz de fora do alambrado | Fazer jornalismo de verdade, e não ser porta-voz do Índice | Faz as entrevistas que mexem na cotação, investiga as fitas, **recebe o vazamento** e decide o que publicar (e o que proteger, como o vídeo de Santiago). | Publica a reportagem das fitas com as vozes da praça, recusa o acesso exclusivo e o canal dela cresce. |

**Regras de escrita para as quatro:** cada uma tem cenas em que o protagonista não é o centro (Iara negociando com a chefe, Duda brigando com a mãe sobre o concurso, Jade discutindo com a agência por causa de um post, Mika editando a matéria às 3h da manhã). Cada uma discorda do protagonista pelo menos uma vez e tem razão. O romance é algo que **acontece com elas**, não o motivo de elas existirem.

**Duda em campo:** por decisão do autor, o futebol feminino **não é jogável no arcade**. Os rachas de Duda, o desafio no Mirante e a final feminina de domingo acontecem só em cenas da VN, com texto, sprites e uma CG. Não há modelo 3D feminino no plano.

**Romance e poder.** Olheiros, Augusto e qualquer pessoa que avalia jogadores **não são românticos**, por causa da relação de poder. Iara trabalha para o Índice, mas **não avalia nem influencia a cotação**; o risco do romance é para o emprego dela, não uma pressão sobre o protagonista. Jade não avalia, mas a exposição que ela dá **mexe** na cotação. Por isso a rota dela tem uma regra explícita: quando o interesse fica mútuo, ela para de postar sobre ele ("não posto quem eu beijo"). Ela tira o poder da relação por escolha própria, e o custo dessa escolha vira o dilema da rota.

---

## 4. Estrutura da história

### 4.1 Os sete dias em quatro capítulos

Cada dia segue a mesma grade, uma estrutura de calendário inspirada em Persona e fácil de produzir:

**Manhã:** o telão atualiza a cotação e acontece uma cena do dia. **Tarde:** a partida de 3 minutos no campo do dia, com a nota do olheiro antes e o ticker depois. **Fim de tarde:** o **passeio**, em que o protagonista anda por alguns quarteirões (seção 4.2). **Noite:** encontro com quem ele escolher (romance, amizade ou investigação). No passeio, isso se faz indo até onde a pessoa está.

| Capítulo | Dias e campos | Título | O que acontece | Gancho final |
| --- | --- | --- | --- | --- |
| **1** | Seg–Ter, Praça XV | **Abertura** | Chegada de barca, credenciamento ("documento, por favor: 18 completos?"), a faixa da Taça arrancada do alambrado, os primeiros encontros, duas partidas, o primeiro vídeo viral da Jade, a primeira cotação, samba no Arco. | De madrugada, o telão da Casa do Pregão "trava" e passa imagens granuladas de várzea antiga. Beto deixa o copo cair: **"Essa fita é do meu pai."** |
| **2** | Qua no Campo do Viaduto; Qui no Campo do Mirante | **Dia Misto** | Quarta: debaixo do viaduto, o Índice embaralha os times com coletes neutros, e o rival vira parceiro. O protagonista vê a própria ficha: "COMPARÁVEL: Taça Praça XV, 1987". Quinta: "Pregão na Comunidade" no Mirante. Duda e as moradoras desafiam os meninos (cena de VN), e a investigação das fitas avança. | **Vazamento:** na madrugada de quinta, o telão mostra o painel interno ("Fator Praça", "risco de imagem", preço de cada post de Jade, comparáveis). As cotações desabam ou explodem. Augusto anuncia a "Arena Índice Praça XV": a Taça acaba. |
| **3** | Sex no Campo do Posto; Sáb na Praça XV | **Fechamento** | Sexta: o Clássico televisionado na orla (o espelho do protagonista contra ele), apresentado por Jade, sob a sombra do vazamento. Descobre-se quem vazou. Sábado: último treino, a noite do sino e as escolhas finais. | O sino toca e a caneta está na mão. |
| **4** | Dom | **Domingo de clássico** | A Taça, a última ou a primeira de uma nova fase. A partida é contra (ou ao lado do) Unidos do Cais. Epílogos. | Créditos sobre o modo arcade. |

### 4.2 Passeios: os quarteirões andáveis

Entre a partida e a noite, o protagonista **anda pelo cenário 3D** com o próprio modelo do jogo, as animações de caminhada e a câmera que segue de cima. Os passeios ficam em **poucos quarteirões, quase todos já modelados**, e servem de ponte entre as partidas e as cenas da VN.

| Área andável | Em volta de qual campo | Quarteirões | Quando | Custo |
| --- | --- | --- | --- | --- |
| **Praça XV** | Praça XV | Cerca de quatro: o lado de fora do alambrado, o chafariz e a fachada da Casa do Pregão com o telão, o Arco e o quiosque do Beto, o cais e a estação das barcas, o calçadão até a barraca de açaí da Duda e o ponto de ônibus da rua lateral | Toda a semana, inclusive na **primeira versão** | Baixo: o cenário existe. Faltam colisores simples (hoje o entorno não tem nenhum) e limites invisíveis. |
| **Orla do Posto** | Campo do Posto | Dois, em linha reta pelo calçadão: arquibancada, estúdio de transmissão da Jade, quiosques e areia | Sexta (Cap. 3) | Baixo: é um corredor e reaproveita o entorno do campo. |
| *Opcional:* **Rua do Viaduto** | Campo do Viaduto | Um: a rua debaixo do viaduto, com o baile charme à noite | Quarta (Cap. 2) | Médio. Se faltar tempo, a quarta fica só em VN. |

O **Mirante** não tem passeio: escadaria é cara de colisão e de câmera, então ele aparece só em cenas de VN e na partida.

**O que dá para fazer**

| Interação | Exemplo | Liga com |
| --- | --- | --- |
| **Conversa** | Um personagem com o balão recortado "!" em cima. Chegar perto e apertar o botão abre uma cena curta de VN (100 a 300 palavras). | Laços e falas-assinatura. |
| **Encontro de rota** | Só acontece com pessoa, lugar, horário e laço certos: Iara no Arco à noite depois do segundo encontro; Vitor no cais nos dias de turno (seg, qua, sex); Duda na barraca de açaí; Jade gravando embaixadinhas no chafariz (ter) e no estúdio do Posto (sex); Mika fazendo live na saída do campo; Santiago comendo pastel no quiosque do Beto. | Abre a cena de rota e as noites. |
| **Evento pequeno** | Um fã pede foto: aceitar dá exposição, recusar dá privacidade, e os Olhos estão vendo. O desafio de embaixadinha da Jade. O dominó dos veteranos no chafariz. Um açaí antes de dormir rende fôlego na próxima partida. | Cotação, Raiz e atributos. |
| **Telão** | Ler a cotação e o ranking por posição, ver o próprio nome subir ou cair. | Tema do jogo; não gasta ação. |
| **Recortes da Taça** | Cartões colecionáveis de lore espalhados pela praça: fotos antigas, a caligrafia de Seu Ademar, os craques das fitas. | Pistas do comparável, Raiz e investigação das fitas. |
| **Celular** | Mensagens que chegam ao passar por certos pontos (a família, o feed da Jade, a live da Mika). | Camada pessoal e rotas. |

**Regras para não virar outro jogo:** cada passeio tem **três ações**. Conversar ou entrar num evento gasta uma; andar, ler o telão e pegar recortes não gastam. Isso dá peso às escolhas sem precisar de relógio. Todo conteúdo dos passeios é escrito no **mesmo formato de roteiro** da VN, com marcações de lugar e de momento (`local: arco`, `quando: noite`, `requer: laco_iara >= 2`). O passeio só dispara as cenas. Para quem não quer andar ou está num computador fraco no navegador, há um menu **"Ir até..."** que leva direto a cada interação.

**Como os personagens aparecem no 3D:** os 20 jogadores já têm modelo 3D. Os personagens sem modelo (Iara, Duda, Jade, Mika, Vitor, Beto, Caio, Augusto) aparecem como **recortes de papel em pé**: o retrato num plano que sempre vira para a câmera, com borda branca e base de papelão. Isso combina com a interface e não pede arte nova. O protagonista anda com o próprio modelo 3D; nos sprites 2D da VN e nas CGs, ele continua fora da tela.

### 4.3 Como funciona escolher qualquer um dos vinte

Escrever a mesma história vinte vezes é inviável. A estrutura proposta é uma **trança de cinco fios**:

| Fio | Quantas versões | O que contém | Peso numa jogada |
| --- | --- | --- | --- |
| **Tronco comum** | 1 | Enredo principal, com variáveis como `{nome}`, `{selecao}`, `{espelho}`, `{capitao}` e `{comparavel}`. | ~60% |
| **Seleção** | 4 (cresce com o catálogo, seção 4.7) | Dinâmica do time, idioma e o tema de cada país (seção 3.2). | ~7% |
| **Posição** | 5 | Cenas do grupo de posição, por exemplo o Clube das Luvas ao amanhecer no cais, discutindo por que o Índice paga menos por goleiro. | ~5% |
| **Pessoal** | 20 | Três cenas por personagem na versão completa: (1) a ligação de casa, (2) o encontro com o comparável, (3) a decisão pessoal no Fechamento. Inclui as **falas-assinatura** (ver abaixo). | ~8% |
| **Rota** | 6 + amizade | Romance ou amizade escolhidos nas noites e nos passeios. | ~20% |

Para o tronco não soar genérico, há três técnicas de escrita:

1. **Falas-assinatura.** Em cerca de 10 momentos-chave por capítulo, como a primeira cotação, o primeiro gol, o vazamento ou o sino, o tronco abre espaço para **uma fala curta de cada protagonista** (20 falas de uma linha). Quando a cotação de Tico sai, ele diz "Pequeno é o número, não eu"; Felix diz "Por favor, não leiam em voz alta". Custa pouco texto e dá muita personalidade.
2. **Espelho.** Cada protagonista tem um rival fixo, da mesma posição na seleção adversária do clássico: Brasil ↔ Argentina e Alemanha ↔ França (Rafa ↔ Tomás, Leon ↔ Amadou...). O tronco tem cenas de rivalidade escritas para `{espelho}`, com uma ou duas falas próprias por par (10 pares; com seleções novas, os pares vêm da tabela de clássicos, seção 4.7). A cotação do Pregão é calculada por posição, e por isso o espelho é o concorrente direto.
3. **Falas removíveis em grupo.** Nas cenas de grupo, o protagonista é um dos quatro membros. Cada NPC tem falas marcadas como removíveis, para que a cena funcione sem ele quando ele é o protagonista. Regra prática: nenhuma informação de enredo pode depender de um único NPC do grupo.

**Nas cenas de VN, o protagonista fica fora da tela**, como em Persona. Ele só aparece como modelo 3D nos passeios e nas partidas. O retrato dele aparece apenas no canto da caixa de diálogo quando fala. Assim a VN não precisa de expressões novas para os vinte, e as CGs podem mostrar só o par romântico (seção 7). Nas escolhas, o jogador escolhe falas curtas com um **tom**: brincalhão, sério ou provocador. Cada protagonista tem um tom "natural" que rende um bônus pequeno, o que mantém a personalidade sem multiplicar o texto.

**Estrangeiros e idioma.** O texto é todo em português do Brasil. Falas em espanhol, francês ou alemão aparecem com uma expressão original e a tradução logo abaixo, em fonte menor ("¡Dale!" / *Vai!*). Para protagonistas estrangeiros, algumas falas de cariocas mudam de versão: Vitor gesticula, Iara traduz. São variantes curtas e marcadas, não cenas novas.

### 4.4 Capítulo 1 cena a cena (primeira versão)

Todo o Capítulo 1 se passa na Praça XV, então a primeira versão **não depende de nenhum campo novo**.

| ID | Cena | Fio | Cenário | Notas |
| --- | --- | --- | --- | --- |
| 1.00 | Escolha do protagonista | — | Interface | Vinte retratos, cada um com idade, cidade e "o sonho" numa linha. |
| 1.01 | **A barca das 7h10** | Tronco + seleção | Cais, manhã | Iara espera no cais com uma placa com o nome do time escrito na língua errada. Primeiro contato com os companheiros. |
| 1.02 | **Credenciamento** | Tronco | Casa do Pregão | Conferência de idade, regras (camisa, Olhos, cláusula) e Augusto no telão: "Bom dia, ativos." A live de Mika aparece no celular. |
| 1.03 | **O alambrado** | Tronco | Campo, dia | A faixa da Taça é arrancada. Primeiro encontro com Beto, Vitor e Caio. Amostra de roteiro no apêndice. |
| 1.04 | **Partida 1** | Tronco | Partida 3D | Contra a seleção do espelho, com a nota do olheiro antes. Santiago aparece aqui se o protagonista for brasileiro ou argentino. |
| 1.05 | Primeira cotação provisória | Tronco + posição | Campo, fim de tarde | Ticker e falas-assinatura. Os goleiros descobrem o "desconto de goleiro". O vídeo de Jade com o lance do protagonista (o melhor ou o pior, conforme a partida) viraliza, e a cotação dá o primeiro salto. Primeira lição do tema: o lance que viraliza é individual, mas o ticker também lê o placar. |
| P1 | **Passeio de segunda** | Passeio | Praça XV andável | Três ações. Conhecer a praça: Beto no quiosque, Jade gravando no chafariz, recortes da Taça, telão. |
| 1.06 | **Ligação de casa** | Pessoal (20) | Alojamento | Interface de celular: texto, sem retrato do familiar. |
| 1.07 | **Segunda no Arco** (noite livre A) | Tronco + rota | Arco, noite | Samba. Escolhas: Iara (de folga, contra a regra), Vitor (indo para o turno da barca), Santiago (que não sabe sambar), Duda (que desafia o protagonista para um racha na areia amanhã), Jade (que quer gravar ele sambando) ou Mika (mensagem direta ao vivo). Primeiro dilema leve: furar o toque de recolher das 23h. |
| 1.08 | **Bom dia, ativos** | Tronco + seleção | Campo, manhã | Cotação oficial às 8h e comparação dentro do time. |
| 1.09 | **Clínica por posição** | Posição (5) | Campo | Primeiro encontro do grupo de posição. |
| 1.10 | **Partida 2** | Tronco | Partida 3D | Contra outra seleção. A nota do olheiro pede algo coletivo ("o seu time completa 6 passes seguidos"). |
| 1.11 | Entrevista | Tronco | Campo | Mika, Jade ou a assessoria do Índice. Escolha de tom, com efeito na cotação e nos laços. |
| P2 | **Passeio de terça** | Passeio | Praça XV andável | Três ações. O desafio de embaixadinha da Jade no chafariz, o primeiro recorte com a caligrafia de Seu Ademar e os encontros que abrem a noite. |
| 1.12 | **Noite livre B** | Rota | Arco, praia ou cais | Iara: passeio pelo Arco "da praça de verdade" (CG). Vitor: treino noturno na praia (CG). Duda: o racha na areia, em que ela ganha e avisa que os Olhos estão filmando (cena de VN, sem CG na primeira versão). Jade: a laje que ela nunca mostra, contada por mensagem. Também é possível passar a noite com o time. |
| 1.13 | **A fita** | Tronco | Campo, noite, telão | Gancho do capítulo. Fim do Capítulo 1. |

### 4.5 Finais

O final é a soma de três camadas, o que evita escrever 3 × 2 × 5 finais completos:

**Final pessoal**, decidido pela escolha no sino, com cotação e Raiz como requisitos:

| Final | Condição em linhas gerais | Tom |
| --- | --- | --- |
| **Fechamento em alta** | Assina com a cláusula de exclusividade. | Agridoce: contrato grande, voo no domingo de manhã e a praça vista da janela do avião. |
| **Domingo de clássico** | Negocia a **"Cláusula da Praça"**: libera a Taça uma vez por ano e reverte parte das luvas para a Taça. Exige cotação alta, Raiz alta e aliados. | O final completo: contrato e domingo. |
| **Fora do Pregão** | Não assina, ou pede para sair. | Esperançoso e aberto: fica uns dias, joga a Taça, futuro sem certeza. |

**Final da praça**, decidido coletivamente pelos laços com jogadores de outras seleções e pelo que se fez com o vazamento: **"A Taça volta"** (as fitas são creditadas e devolvidas, e Augusto toca o sino para os velhos craques) ou **"O último domingo"** (a Taça acontece pela última vez antes da Arena). As duas versões usam o mesmo cenário; muda a faixa e cerca de dez falas.

**Epílogo do par:** seis rotas e uma versão sem par, cada uma com uma abertura curta para cada final pessoal. Fecha com a fala-assinatura "um ano depois" do protagonista.

### 4.6 Volume de texto estimado

Referência: cerca de 220 palavras por minuto de leitura. Os números valem para as quatro seleções atuais. Cada seleção nova soma o "pacote" da seção 4.7.

| Bloco | Primeira versão (Cap. 1) | Jogo completo |
| --- | ---: | ---: |
| Tronco (inclui os três campos novos) | 9.000 | 31.000 |
| Seleção (4) | 4 × 1.000 = 4.000 | 4 × 3.500 = 14.000 |
| Posição (5) | 5 × 800 = 4.000 | 5 × 2.500 = 12.500 |
| Pessoal (20 cenas + falas-assinatura) | 20 × 470 ≈ 9.400 | 20 × 1.400 = 28.000 |
| Rotas (6) | ≈ 7.200 (duas em 2.200 e quatro em ~700) | 6 × 7.000 = 42.000 |
| Passeios (conversas e eventos curtos) | ≈ 3.000 (cerca de 15 interações) | ≈ 10.000 |
| Finais e epílogos | — | 11.000 |
| Celular, notas de olheiro, telão, contratos, feed da Jade | 2.000 | 7.000 |
| **Total escrito** | **≈ 39.000** | **≈ 155.000** |
| **Lido numa jogada** | **≈ 16.000 (cerca de 1h15 de leitura + 2 partidas + 2 passeios: 1h30–1h45)** | **≈ 55.000 (cerca de 4h15 de leitura + 6 a 8 partidas + passeios: 5h–5h30)** |

### 4.7 Novas seleções sem reescrever o tronco

O autor vai criar mais seleções. A estrutura foi pensada para crescer **por soma**, sem tocar no tronco.

**1. O palco tem sempre quatro seleções.** Com o catálogo maior, o grupo da história é **montado na escolha do protagonista**: a seleção dele, a rival de clássico dela e mais duas sorteadas (ou escolhidas pelo jogador). As cenas, os grupos de posição (sempre quatro membros), o Dia Misto e o rodízio de campos têm sempre o mesmo tamanho, com 10 ou com 30 seleções no catálogo.

**2. O tronco nunca cita um país pelo nome.** Ele usa variáveis (`{selecao}`, `{rival_classico}`, `{grupo}`, `{espelho}`) e **pontos de encaixe**. Onde uma fala precisa ser de um país, o tronco chama o encaixe daquela seleção; se ele não existir, toca uma versão genérica escrita uma vez. Assim dá para lançar uma seleção nova antes de todas as cenas dela estarem prontas.

**3. Cada seleção nova é um "pacote" que se acrescenta:**

| Parte do pacote | O que contém | Volume |
| --- | --- | --- |
| Dados | 5 jogadores e 2 uniformes no JSON, que o jogo já suporta | — |
| Arte | 5 retratos e 5 comemorações (expressões opcionais) | 10 imagens |
| Tema | Uma frase ("jogar em casa pesa", "visitantes") e um glossário de cerca de 30 expressões no idioma | ~300 palavras |
| Rival de clássico | Uma linha numa tabela de pares. Seleções novas entram de preferência **aos pares**, e o par de clássico define os espelhos por posição. | ~500 palavras (falas de espelho) |
| Camada de seleção | Seis encaixes fixos: chegada, primeira cotação, crise do Dia Misto, véspera do clássico, Fechamento, despedida | ~3.500 palavras |
| Cinco pacotes pessoais | Ligação de casa, encontro com o comparável, decisão no Fechamento e falas-assinatura | 5 × 1.400 = 7.000 palavras |
| Cinco comparáveis | Uma linha cada sobre o craque da fita | ~150 palavras |
| Reações dos fixos | Falas curtas de Iara, Beto, Jade e Mika para o país. Se o idioma não for um dos de Iara (espanhol, francês, alemão), entra a piada pronta do tradutor de celular. | ~400 palavras |
| **Total por seleção** | | **≈ 12.000 palavras no jogo completo (≈ 3.500 no Cap. 1) e 10 imagens** |

**4. O que não muda:** tronco, rotas, finais, passeios e personagens fixos. As rotas usam `{selecao}` em poucas falas, e Santiago continua argentino em qualquer grupo: se a Argentina não for sorteada, ele aparece como jogador de outro grupo que treina na Praça XV.


---

## 5. Romance

### 5.1 Regras gerais

- **Idades:** Duda tem 19, Santiago 20, Jade 21, Iara 22, Vitor 23 e Mika 24. Os protagonistas têm de 18 a 20. **Nenhum menor de idade aparece em cena romântica, nem perto dela.** Crianças da praça só aparecem como fundo, sem fala, em cenas de futebol.
- **Classificação pretendida:** 14 anos (ClassInd) / "Teen" no itch.io. Pode haver afeto, flerte, mãos dadas, abraço, ciúme leve e beijo. **Não há** nudez, conteúdo sexual nem insinuação de sexo; uma cena que corta depois de um beijo corta para "conversaram no cais até o sol nascer". Não há álcool nas rodas de samba: "o Índice faz exame toda manhã", então é guaraná, e vira piada.
- **Consentimento na tela:** o beijo sempre vem de uma escolha do jogador ("Beijar" ou "Esperar"), depois de sinais claros do outro lado. "Esperar" nunca é punido e tem cena própria, igualmente bonita.
- **Orientação:** cada protagonista tem orientação definida pelo jogador ao escolher a rota. Os pares têm identidade própria: **Iara**, **Duda** e **Jade** se interessam por homens; **Vitor** é gay e assumido na praça; **Santiago** é gay, assumido para família e time, discreto em público; **Mika** é bissexual, dito de passagem e sem drama. Como todos os protagonistas são homens, todas as rotas ficam disponíveis para todos (exceto Santiago para ele mesmo).
- **Uma rota de cada vez:** flertar com várias pessoas é possível até sexta. Na noite de sexta acontece "a pergunta", e só uma rota segue. Não há mecânica de ciúme punitivo.
- **Homofobia:** existe como **pressão estrutural** (o rótulo "risco de imagem" do Índice, comentários anônimos lidos de passagem), nunca como violência em cena, insulto escrito por extenso ou tragédia. A narrativa fica do lado dos personagens, e **ninguém é tirado do armário à força**: a decisão de se expor é sempre de quem vive a situação. Um aviso de conteúdo opcional aparece antes do Capítulo 1.
- **Sem romance:** o jogo sempre apresenta as seis pessoas no tronco, e elas são essenciais ao enredo. O jogador pode terminar na rota de amizade do time. (Ver perguntas em aberto.)

### 5.2 As seis rotas

São quatro mulheres e dois homens, um deles jogador. Cada rota liga o romance a uma parte diferente do Pregão: **Iara, a organização por dentro; Duda, o futebol que o Pregão não vê; Jade, a exposição; Vitor, quem passou da idade; Santiago, a privacidade dos atletas; Mika, a imprensa.** Todas giram em torno do mesmo evento, o vazamento, visto de seis ângulos. Cada rota também carrega um dilema de adulto (seção 1), para que o romance não seja um intervalo da história e sim parte das decisões.

#### Iara Monteiro (22): "Traduzir é escolher"
- **Começo:** no credenciamento, ela traduz errado de propósito uma frase desastrada do protagonista para a imprensa e o salva.
- **Desenvolvimento:** samba proibido para a equipe; passeio pelo Arco "da praça de verdade", com os nomes dos campeões riscados na pedra (CG da primeira versão); ela ensina a ler o telão ("a terceira coluna ninguém explica"); pede ajuda para copiar algo.
- **Virada:** no vazamento, o protagonista é o único que sabe que foi ela. Proteger, convencer a se entregar ou entregar? Ela não precisa dele para decidir; precisa saber de que lado ele está.
- **Clímax:** no Fechamento, ela é a intérprete oficial do discurso de Augusto e traduz a verdade nas quatro línguas. Beijo no cais quando o sino toca (CG).
- **Integração com o jogo:** o laço com Iara acelera os laços com estrangeiros e libera a "Leitura do Índice": ver as notas de olheiro antes das partidas.
- **Se o protagonista for estrangeiro:** a rota fica mais sobre idioma (ela ensina gírias e ele ensina a palavra dele para "saudade").

#### Duda Ferraz (19): "Racha"
- **Começo:** no samba de segunda, ela ouve o protagonista se gabar e o desafia para um racha na areia: "Três contra três, sem telão. Quero ver quanto tu vale sem plateia."
- **Desenvolvimento:** ela ganha o primeiro racha, e ninguém o deixa esquecer. Ele passa a treinar com ela à noite: ela ensina o jogo de areia, ele conta como é uma peneira por dentro. Há o turno na barraca de açaí, a briga dela com a mãe sobre o concurso e a descoberta de que ela usa os Olhos de propósito, para entrar nos dados do Índice.
- **Dilema de adulto:** jogar racha com ela quebra a cláusula de exclusividade. Continuar arrisca a cotação dele; parar fecha a única vitrine dela. Lealdade ou oportunidade, dos dois lados.
- **Virada:** o painel vazado mostra que o Índice tem 41 minutos de Duda gravados e classificados como "ruído". Ela fica furiosa com o sistema e com ele, por ainda querer assinar.
- **Clímax:** no domingo, é ela quem joga a final, a da Taça feminina, e ele fica do lado de fora do alambrado, torcendo. Os papéis se invertem. Beijo depois do apito, com a medalha ainda no pescoço dela (CG).
- **Integração com o jogo:** os rachas dão bônus de técnica e fôlego, e o laço com Duda pesa no final da praça.
- **Se o protagonista for estrangeiro:** ela aprende palavrões em quatro línguas mais rápido que ele aprende "valeu", e a rota vira uma disputa de quem ensina mais.

#### Jade Moreira (21): "Não posto quem eu beijo"
- **Começo:** depois da primeira partida, o vídeo dela com o lance do protagonista viraliza e a cotação dele salta (ou despenca, se o lance foi o tropeço). No passeio de terça, ela o desafia para uma disputa de embaixadinhas no chafariz, ao vivo. Ela ganha e propõe uma "collab".
- **Desenvolvimento:** a série de vídeos com ele faz o engajamento subir, e cada post aparece no feed do celular. Longe da câmera, ela mostra a laje em Campo Grande onde aprendeu, por mensagem e depois ao vivo, e conta da liga que quer criar. Ela tem uma piada pronta para cada situação e só para de fazer piada quando desliga o celular. A primeira vez que ela faz isso na frente dele é o momento-chave da rota.
- **Dilema de adulto:** quando o interesse fica mútuo, ela aplica a própria regra e para de postar sobre ele. A cotação dele perde o impulso de engajamento justo na semana do Fechamento. Ele aceita o custo, pede que ela continue "só trabalho" ou termina a collab. É exposição contra intimidade, e nenhuma resposta é punida pelo roteiro.
- **Virada:** o vazamento mostra a planilha com o preço de cada post dela para o Índice. A agência pede um vídeo contra Iara, e ela tem que escolher.
- **Clímax:** no Clássico de sexta, transmitido do estúdio dela no Campo do Posto, ela sai do roteiro ao vivo. O beijo vem depois, numa foto que ela tira e não posta (CG enquadrada como a tela do celular, com o protagonista de capuz e de costas).
- **Integração com o jogo:** o laço com Jade mexe na parte de engajamento da cotação e nos eventos de exposição dos passeios. Escolhas "postar / não postar" aparecem no celular.
- **Relação com outras personagens:** começa em atrito com Mika (marketing contra jornalismo) e com Duda ("tu filma futebol, eu jogo"). Termina aliada das duas, em qualquer rota.

#### Vitor Nascimento (23): "O lado de fora do alambrado"
- **Começo:** a bola do aquecimento cai do lado de fora, e ele devolve de primeira por cima de quatro metros de cerca (apêndice).
- **Desenvolvimento:** treino noturno na praia, onde ele ensina a cair ("o goleiro que não sabe cair não levanta"); ganha-se um atributo (CG da primeira versão). Viagem no convés da barca no turno dele, ao pôr do sol. Na fita, ele se vê aos 17.
- **Virada:** no vazamento, Vitor é acusado porque foi visto perto da Casa do Pregão. É uma rota sobre confiança: o protagonista acredita nele antes de saber a verdade?
- **Clímax:** no domingo, joga a Taça ao lado ou contra o protagonista. Beijo atrás do alambrado depois do apito, do lado de fora, onde ele sempre esteve (CG).
- **Integração com o jogo:** bônus de reflexos e técnica nos treinos noturnos. Se o protagonista for goleiro, Vitor entra no Clube das Luvas e a rota ganha cenas extras.
- **Epílogo:** sem conto de fadas. No melhor final, ele vira organizador da Taça e guardião das fitas; nos outros, ganha uma peneira de verdade.

#### Santiago (20): "Clássico"
- **Começo:** depende da seleção do protagonista. Brasileiro: um drible humilhante na primeira partida e um sorriso de desculpas. Argentino: o companheiro que já sabe que ele está apaixonado antes dele mesmo. Alemão ou francês: a roda de samba, onde ele pede ajuda porque "tenho pés de Córdoba".
- **Desenvolvimento:** no Dia Misto, debaixo do viaduto, os dois caem no mesmo time e a química em campo vira bônus de dupla. Passar para ele é o melhor lance, e a cotação de quem passa sobe menos. Açaí na orla e portunhol contra "espanholês".
- **Virada:** um dos Olhos flagra os dois de mãos dadas no cais, e o painel vazado mostra "risco de imagem" ao lado do nome dele. O escândalo é do sistema, não deles. Mika tem o vídeo e não publica.
- **Clímax:** o clássico de sexta, um contra o outro com tudo em jogo (ou lado a lado, se o protagonista for argentino). Depois, a escolha é dele: falar em público, nos próprios termos, ou não. Os dois caminhos são válidos e o jogo não empurra nenhum. Beijo no Arco (CG).
- **Se o protagonista for Santiago:** a rota não aparece, e as outras cinco seguem disponíveis.
- **Cuidado:** a rota inteira foi pensada para não terminar em tragédia nem em exposição forçada. O epílogo é à distância ("a gente se vê no próximo clássico").

#### Mika Tanaka Ribeiro (24): "Fora de quadro"
- **Começo:** na primeira versão, só aparece pelo celular, na live "Linha de Fundo". O protagonista pode responder no chat e trocar mensagens diretas. O encontro em pessoa, no Capítulo 2, é uma revelação ("Você é bem mais baixo que no telão").
- **Desenvolvimento:** a entrevista com perguntas incômodas; ela investiga as fitas com o protagonista; futsal noturno em que ela, ex-goleira, defende os chutes dele.
- **Virada:** ela recebe o vazamento. Publicar tudo, incluindo o vídeo de Santiago, para ter a matéria da vida? A rota é sobre a linha ética que ela escolhe e sobre o fato de que namorar alguém que se cobre exige se afastar da cobertura.
- **Clímax:** publica a história das fitas com as vozes da praça e deixa de fora o que não é dela publicar. Beijo na noite em que o telão apaga (CG).
- **Integração com o jogo:** as entrevistas com Mika têm mais efeito na cotação, para o bem e para o mal.

### 5.3 Amizades (não românticas)
Beto, Caio, o espelho, o grupo de posição e os companheiros de seleção têm laços próprios. Iara, Duda, Jade e Mika também podem ser só amigas: os arcos delas acontecem do mesmo jeito (seção 3.4). Eles alimentam o **final da praça**: o vazamento só vira justiça se jogadores de seleções diferentes se juntarem. O romance é o fio emocional; a amizade entre rivais é o fio político.

---

## 6. Ganchos para mecânicas

O que a história pede da jogabilidade, para o designer detalhar:

**Valor e progresso**
1. **Cotação (o "valor do passe") por protagonista:** número público com ▲▼, atualizado depois de cada partida e de manhã. É individual, mas a história pede que **dependa do coletivo** (gancho 7). Sobe com gol, assistência, ENTORTOU!, NA BOLA!, MILAGRE! e cumprimento de objetivos; cai com FOI MAL!, gol sofrido em momentos-chave e certas escolhas públicas. Uma parte vem do **engajamento** (vídeos de Jade, eventos de exposição nos passeios).
2. **Raiz:** medida escondida, ou quase, do laço com a praça. Sobe com escolhas, tempo com os moradores e respeito pela Taça. Junto com a cotação, decide o final pessoal.
3. **Laços:** cerca de 14 medidores (seis pares românticos, Beto, Caio, espelho, grupo de posição, time). Jogar para os companheiros em campo também conta. Faixas destravam cenas. Laços com jogadores de **outras** seleções alimentam o final da praça.
4. **Estado de romance:** afinidade → encontro → compromisso (uma rota a partir de sexta).
5. **Atributos:** cenas de treino e de rota dão bônus pequenos (+1 a +3) aos sete atributos existentes, dentro do limite. O treino de queda com Vitor rende reflexos, e os rachas com Duda rendem técnica e fôlego, por exemplo.

**Dilemas de adulto (Capítulos 2 e 3)**
- **Proposta antecipada:** um clube oferece contrato com prazo ("até meia-noite") e uma condição, como não jogar o clássico. Aceitar garante o futuro e trai o time.
- **Individual ou coletivo:** um patrocinador oferece um "bônus de artilharia" se o protagonista marcar no próximo jogo, enquanto a nota do olheiro pede jogo coletivo. Como o jogador controla o time inteiro, ele resolve o dilema com a mão: forçar a bola no protagonista ou dar ao companheiro livre.
- **Exposição ou intimidade:** postar ou não postar com Jade; aceitar ou recusar a foto com o fã debaixo dos Olhos.
- **Dinheiro e família:** adiantamentos de agentes, mensagens da família pedindo que ele aceite logo. Aceitar cria uma dívida que aparece de novo no Fechamento.
- **Contrato legível:** tela do contrato com cláusulas que dá para ler e negociar (exclusividade, imagem, multa, "Cláusula da Praça"). Ler com Noé ou Iara revela o que a letra miúda esconde.
- **Exposição:** algumas escolhas acontecem "debaixo dos Olhos" (marcadas na tela). O que é feito em público mexe na cotação e pode voltar no vazamento.
- **Consequências que ficam:** um caderno guarda as decisões de peso e quem lembra delas. NPCs se referem a elas depois.

**Partidas pedidas pela história**
6. **Nota de olheiro antes da partida:** um a três objetivos curtos, apresentados como cartão recortado. Há três tipos, e às vezes eles se contradizem de propósito: **individuais** ("3 desarmes limpos", "1 MILAGRE"), **coletivos** ("o seu time completa 6 passes seguidos", "não sofrer gol nos últimos 60 s") e **mistos** ("participe de 2 gols do time").
7. **Controle do time inteiro (decisão do autor) e o conflito individual × coletivo:** o jogador controla todo o time, com a troca de jogador do arcade, e não fica preso ao protagonista. A história pede que:
   - a partida registre separadamente os **eventos do protagonista** (gols, passes, desarmes, defesas, reações);
   - conte a **participação** dele nas jogadas do time: o passe que vira gol de outro, a bola recuperada que o time aproveita, a bola que ele recebe de um companheiro;
   - o **resultado e a atuação do time** pesem sobre a cotação individual, de modo que um gol do protagonista numa derrota valha menos que uma assistência numa vitória;
   - o **individualismo tenha custo visível**: chute forçado com o protagonista quando um companheiro estava livre aparece na nota do olheiro e nos laços com o time;
   - o resultado seja legível depois da partida, no ticker e nas falas ("o Índice gostou do teu passe, cara").
   O desenho do sistema fica com o designer; a história só precisa que **o melhor para o protagonista e o melhor para o time nem sempre coincidam**, e que jogar para o time compense na semana, mesmo quando custa no lance.
8. **Partidas especiais e campos:** cada partida carrega o **entorno do campo do dia** (Praça XV, Viaduto, Mirante, Posto), com campo e regras iguais. **Dia Misto** no Viaduto (coletes neutros; hoje o modelo 3D é escolhido por time, e isso pode exigir modelo por jogador), **Clássico** televisionado no Posto (o protagonista contra o espelho) e **Domingo** contra o **Unidos do Cais** (Vitor, Beto, Caio e dois moradores sem retrato, usando a silhueta com número que o HUD já tem). O desafio de Duda e a final feminina são **só cenas de VN**: o futebol feminino não é jogável no arcade.
9. **Retorno da partida para a história:** placar, estatísticas do protagonista e objetivos cumpridos, para o roteiro ramificar ("se perdeu o clássico...").
10. **Pular partida** (simulação rápida) para quem só quer a história, e o inverso para quem só quer jogar.

**Interface e mundo**
11. **Calendário** com dia e período (manhã, tarde, noite) e escolha da noite livre. Inclui a **temperatura da interface por capítulo:** os mesmos elementos de recorte com paleta, rasgos, ticker e música mudando conforme o arco de tom (seção 1). Isso pode ser um "perfil visual" por capítulo, sem imagens novas.
12. **Celular:** mensagens de casa, live da Mika, feed da Jade (com escolhas "postar / não postar") e mensagens diretas, sem imagem nova.
13. **Telão / ticker** no cenário 3D, na fachada da Casa do Pregão. A faixa do alambrado troca entre "PREGÃO PRAÇA XV" e "TAÇA PRAÇA XV".
14. **Sobreposições de emoção:** raio, gota de suor, interrogação e veia de raiva desenhados em código sobre o retrato, para quem não tem expressões (Alemanha e França).
15. **Escolhas com tom:** brincalhão, sério ou provocador, com bônus para o tom natural de cada protagonista.
16. **Fitas VHS (opcional):** replays de partidas antigas no próprio motor, com uniforme do Unidos do Cais e filtro de VHS.
17. **Destravamentos no arcade:** terminar rotas libera o Unidos do Cais como time, uniformes e Vitor jogável.
18. **Conforto:** salvar e carregar, avanço automático, pular texto lido, histórico, velocidade do texto e avisos de conteúdo.

**Passeios (seção 4.2)**
19. **Andar no cenário** com o modelo do protagonista, câmera de acompanhamento, colisores simples e limites invisíveis. Botão de interagir perto de pontos marcados com o balão "!".
20. **Três ações por passeio**; andar, ler o telão e pegar recortes não gastam ação.
21. **Gatilhos de cena por lugar, momento e condição** (`local`, `quando`, `requer`), lidos do mesmo roteiro da VN.
22. **Recortes de papel em pé** para personagens sem modelo 3D (retrato num plano voltado para a câmera).
23. **Recortes da Taça:** coleção de cartões de lore, guardada no save.
24. **Menu "Ir até..."** como atalho e como acessibilidade.

**Catálogo de seleções (seção 4.7)**
25. **Montagem do grupo** na escolha do protagonista: a seleção dele, a rival e mais duas.
26. **Tabela de clássicos** (pares de rivais), que define os espelhos.
27. **Encaixes por seleção com versão genérica**, para lançar seleções novas aos poucos.

---

## 7. Plano de produção

### 7.1 O que reaproveitar (custo zero de arte nova)

| Asset existente | Uso na VN |
| --- | --- |
| 20 retratos | Expressão "neutra" de todos, e retrato do protagonista na caixa de diálogo. |
| 20 comemorações | Expressão "feliz/orgulhoso". Algumas servem para momentos específicos: o coração de Douglas, o "shh" de Mateo, o "calma" de Tomás, o beijo de Malik. |
| 20 expressões (raiva e surpresa, Brasil e Argentina) | Exatamente para o que foram feitas. |
| 3 retratos iniciais (beto, caio, lucas) | Beto, Caio e Vitor. |
| Cenário 3D da Praça XV | Cenários da VN por render (ver abaixo) e **área andável** dos passeios. |
| Campinho (gramado, marcações, gols, redes, alambrado, colisores) | Base idêntica dos três campos novos; só o entorno muda. |
| Peças do entorno (casas do morro, caixas-d'água, coqueiros, guarda-sóis, calçadão, postes, bancos, quiosque, espectadores, água) | Montagem dos entornos do Viaduto, do Mirante e do Posto. |
| 20 modelos 3D dos jogadores e animações de locomoção | Protagonista e companheiros andando nos passeios. |
| Formas da interface (`ui_shapes.gd`, `ui_flags.gd`) | Caixa de diálogo, nomes, calendário, telão, notas de olheiro, celular, transições. |
| Motor de partida, reações, câmeras e modo torcida | Partidas da história; o modo torcida serve para assistir aos jogos de outros times. |
| Efeitos sonoros sintetizados | Bipes curtos por personagem no lugar de dublagem (opcional). |

**Cenários por render do 3D:** um script de ferramenta posiciona a câmera no cenário existente e grava capturas em 1920×1080, em horários diferentes (dia, fim de tarde, noite, com ajuste de iluminação). Um filtro leve de posterização e contorno aproxima o 3D low poly do traço 2D dos personagens. Custa trabalho de código, não geração de imagem, e garante que o cenário da VN é o mesmo do jogo.

### 7.2 Imagens novas

| Item | Primeira versão | Jogo completo (acumulado) |
| --- | ---: | ---: |
| Iara: base, alegre, corada, triste | 4 | 4 |
| Vitor: alegre, corado, triste (base = `lucas.png`) | 3 | 3 |
| Augusto: base, abatido | 1 | 2 |
| Duda: base, alegre, corada, raiva | 1 (só a base) | 4 |
| Jade: base, alegre, corada, triste | 1 (só a base) | 4 |
| Mika: base, alegre, corada, triste | 0 (aparece só no celular) | 4 |
| Santiago: corado, triste | 0 | 2 |
| Beto: rindo, triste | 0 | 2 |
| Caio: raiva, rindo | 0 | 2 |
| CGs de romance (primeiro momento e beijo, por rota) | 2 (Iara no Arco, Vitor na praia) | 12 |
| CGs de história (fita no telão, sino do Fechamento) | 0 | 2 |
| Cenários interiores gerados (Casa do Pregão por dentro, alojamento) | 2 | 4 (com convés da barca e estúdio da Jade) |
| **Total gerado por IA** | **14** | **47** |
| Renders do cenário 3D | ~7 (só Praça XV) | ~20 (com 2 a 3 por campo novo) |
| *Opcional:* raiva e surpresa para Alemanha e França | — | +20 |
| *Por seleção nova:* retratos e comemorações | — | +10 cada |

### 7.2b Cenários 3D novos e passeios (código, sem imagem gerada)

Tudo aqui é modelado por código, como a Praça XV (`SurfaceTool`, cores por vértice, peças reaproveitadas), sem texturas baixadas e sem Blender.

| Item | Reaproveita | Novo | Alvo | Capítulo |
| --- | --- | --- | --- | --- |
| Entorno **Campo do Viaduto** | Campinho inteiro, casas do morro, quiosque, postes, espectadores | Viaduto, trem animado em linha reta, muros grafitados, gramado gasto (shader) | ≤ 12 mil triângulos | 2 |
| Entorno **Campo do Mirante** | Campinho inteiro, casas e caixas-d'água do morro, água, ilhas, casario ao fundo | Escadaria, muro de contenção, fios com pipas, bandeirinhas | ≤ 12 mil triângulos | 2 |
| Entorno **Campo do Posto** | Campinho inteiro, praia, coqueiros, guarda-sóis, calçadão, edifícios | Arquibancada, telão de LED, estúdio de vidro | ≤ 12 mil triângulos | 3 |
| **Passeio Praça XV** | Cenário inteiro | Colisores simples, limites, pontos de interação, recortes em pé | — | 1 (primeira versão) |
| **Passeio Orla do Posto** | Entorno do Posto | Colisores, corredor do calçadão | — | 3 |
| *Opcional:* **Passeio Rua do Viaduto** | Entorno do Viaduto | Colisores, uma rua | — | 2 |

Os entornos são malhas geradas no próprio jogo e pesam pouco no download (bem menos de 1 MB cada). O custo deles é **tempo de modelagem**, não tamanho. Ordem sugerida: Posto primeiro (é quase todo reaproveitado e é o palco do clímax), depois Mirante e Viaduto.

**Regras para as CGs:** como o protagonista pode ser qualquer um dos vinte, **nenhuma CG mostra o rosto dele**. São enquadramentos em primeira pessoa (o par olhando para a câmera) ou o protagonista de costas, de **moletom com capuz do Unidos do Cais** emprestado. O moletom aparece na história como presente da praça e serve para os vinte. Por isso basta uma CG por momento, não vinte.

**Consistência das personagens novas:** gerar primeiro o retrato-base no mesmo enquadramento, fundo transparente e traço dos existentes, usando um retrato aprovado como referência de estilo. Só depois de aprovado, derivar as expressões **editando o retrato-base**, e não gerando do zero. As CGs ficam por último, com o retrato-base como referência. Roupas fixas e simples (polo do Índice, jaqueta de imprensa, camisa laranja) ajudam a manter a consistência.

**Música:** 3 faixas em loop na primeira versão (dia na praça, noite e romance, tensão) e 5 no jogo completo, em OGG Vorbis, de fonte CC0 ou encomendada. Sem dublagem.

### 7.3 Técnica no Godot 4.7 e itch.io

- **Diálogos em dados:** escrever num formato de roteiro em texto simples, como o do apêndice, e converter para JSON com um script de ferramenta do Godot. Cada fala tem ID estável (útil para tradução futura), quem fala, expressão, texto, condição opcional, efeitos e saltos. Não precisa de plugin.
- **Imagens da VN:** importar os sprites a 1024 px com compressão **Lossy (WebP)**, sem mipmaps, porque em 2D eles não fazem falta: cerca de 100 a 150 KB cada. Hoje os retratos entram a 512 px e as comemorações a 768 px. Vale padronizar uma importação única compartilhada entre HUD e VN para não duplicar arquivos.
- **Web:** o jogo já usa o renderizador Compatibility, que é o necessário para HTML5. Exportar sem threads evita depender de SharedArrayBuffer no itch.io. As telas da VN são 2D e leves; o risco de desempenho no navegador é a partida 3D (gramado com 2.600 tufos, praça com 25 mil triângulos, redes), e vale prever uma opção de qualidade para a web. Carregar recursos por capítulo. O salvamento em `user://` vai para o armazenamento do navegador; avisar que limpar os dados do site apaga o save.
- **Passeios no navegador:** o passeio carrega só o entorno, sem a partida, e por isso é mais leve que o jogo. Os recortes em pé usam texturas que já estão carregadas. O menu "Ir até..." garante que a história funciona mesmo se o passeio ficar pesado na web.
- **Tamanho estimado da primeira versão:** o conteúdo novo soma cerca de **10 a 15 MB** (aproximadamente 2 MB de imagens geradas, 2 MB de renders, 5 MB de música, menos de 0,5 MB de texto, e o restante na reimportação dos sprites). Somado ao jogo atual e ao motor, o download para Windows deve ficar na casa de **60 a 90 MB compactado**, e o build web um pouco menor. São números para conferir no primeiro export, porque o motor sozinho pesa dezenas de MB.

### 7.4 Primeira versão para lançar: "Capítulo 1: Abertura"

- Os vinte protagonistas jogáveis e as quatro seleções atuais.
- Segunda e terça, tudo na Praça XV: 13 cenas, 2 partidas da história, 2 passeios andáveis e 2 noites livres. **Nenhum campo novo.**
- Partidas com o time inteiro sob controle e a cotação já reagindo ao coletivo (pelo menos uma nota de olheiro coletiva).
- Seis rotas apresentadas: Iara e Vitor com dois encontros e uma CG cada; Duda com o desafio e o primeiro racha (VN); Jade com o vídeo viral e o desafio de embaixadinhas; Santiago como rival ou amigo; Mika pelo celular.
- O tom do Capítulo 1 é euforia, com os primeiros sinais de pressão (toque de recolher, câmeras, viral, primeira cotação).
- O gancho da fita.
- O modo arcade continua como está, acessível pelo menu.
- Cerca de 39 mil palavras escritas, 1h30 a 1h45 por jogada, 14 imagens geradas, 7 renders e 3 músicas.

**Ordem sugerida:** (1) motor da VN e conversor de roteiro; (2) passeio da Praça XV (colisores, interação, recortes em pé, menu "Ir até..."); (3) Capítulo 1 completo com **um** protagonista, como fatia vertical; (4) as quatro camadas de seleção e as cinco de posição; (5) as vinte cenas pessoais e falas-assinatura; (6) arte e CGs; (7) testes de leitura com outras pessoas e lançamento.

**Fica para depois:** Capítulos 2 a 4; os três campos novos (Posto, Mirante, Viaduto) e o passeio da Orla; Duda, Jade, Mika e Santiago completos; fitas VHS no motor; Dia Misto com times misturados; Unidos do Cais no arcade; finais e epílogos; expressões de Alemanha e França; seleções novas em pacotes; tradução para inglês.

### 7.5 Riscos

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Volume de texto (155 mil palavras no total, mais cerca de 12 mil por seleção nova) | O maior risco do projeto | Lançar em capítulos; manter a proporção da trança; falas-assinatura curtas em vez de cenas inteiras por personagem; seleções novas com encaixe genérico até o pacote ficar pronto. |
| Passeios crescerem até virar outro jogo | Meses de trabalho em sistema em vez de história | Poucos quarteirões, três ações por passeio, só conversas e eventos curtos, nada de missões ou inventário; o menu "Ir até..." como rede de segurança. |
| Tempo de modelagem dos três campos | Atraso dos Capítulos 2 e 3 | Mesmo campinho, entornos com peças reaproveitadas e teto de triângulos; o Capítulo 1 não depende de nenhum deles. |
| Controle do time inteiro esconder o protagonista | O jogador não perceber o que conta para a cotação | Nota de olheiro clara antes da partida, ticker que explica depois, falas dos companheiros sobre o passe. O designer decide os detalhes. |
| Texto gerado com ajuda de IA soar genérico | Personagens iguais | Este documento como guia de voz; revisão humana de todo diálogo; ler as falas-assinatura em voz alta. |
| Dilemas pesados matando a energia | Jogo vira drama cinza | Arco de tom da seção 1, regra "duas leves para cada pesada", dilemas apresentados em cenas com movimento (racha, praia, samba). |
| Personagens femininas virarem só par romântico | Contraria o pedido do autor e empobrece a história | Seção 3.4: arcos completos sem rota, cenas sem o protagonista no centro, discordâncias com razão. |
| Consistência da arte nova | Iara, Duda, Jade e Mika "mudando de rosto" | Base aprovada primeiro, expressões por edição, poucas roupas fixas, CGs sem o rosto do protagonista. |
| Representação (LGBTQIA+, diásporas, Rio) | Erros que ferem e viram polêmica | Regras da seção 5.1, leitores de sensibilidade, nenhuma piada de país, avisos de conteúdo. |
| Ligação com atletas reais | Risco de imagem e de direito | Adotar os nomes da arte; referências históricas só como nota interna. |
| Desempenho da partida 3D no navegador | Build web injogável em máquinas fracas | Opção de qualidade, testar cedo no itch e, no pior caso, web só com a VN e a simulação das partidas. |
| Mudança de nomes no jogo existente | Testes e cadastro quebrando | Fazer a troca num único passo, com `nome_camisa` para o HUD, antes de começar o roteiro. |
| Espaços reais (Praça XV, rodas de samba de segunda, subúrbio, morro, orla) | Representar mal lugares com história, ou reduzir morro e subúrbio a estereótipo | Manter nomes fictícios (Morro do Cais, Campo do Viaduto, Posto 7, Casa do Pregão), citar as referências reais só como inspiração e seguir a regra dos campos (seção 2). |

---

## 8. Perguntas em aberto para o autor

1. **Nomes:** aprova os nomes da arte como oficiais, com `nome_camisa` (Santi, Nico) no HUD? O card aguenta 7 letras?
2. **"Pregão" no lugar de "draft":** gosta da troca? Título de trabalho: *Várzea FC: O Pregão*, com a frase "Quanto vale um domingo?".
3. **Romance para o jogador:** o romance existe no tronco e as seis pessoas são centrais ao enredo. Mas o jogador **pode** terminar sem par, na rota de amizade, ou você quer que todo final tenha par?
4. **Rotas:** seis rotas (quatro mulheres com papel próprio, dois homens, um deles jogador) é a mistura certa? Quer mais uma rota entre jogadores (Malik é um bom candidato) ou um personagem não binário no elenco fixo? Se sim, pode entrar como membro da equipe do Índice ou da praça, escrito com o mesmo cuidado, e não como cota.
5. **Jade:** o nome e a profissão (freestyler e influenciadora oficial do Pregão) funcionam? A rede social dela deve ser fictícia, sem marca real, como o resto do jogo?
6. **Protagonista fora da tela:** concorda que, na VN, o protagonista só aparece na caixa de diálogo e nunca nas CGs, aparecendo em 3D apenas nos passeios e nas partidas?
7. **Campos:** os três campos (Viaduto, Mirante, Posto) e a ordem quarta, quinta, sexta servem? Algum lugar do Rio que você gostaria mais do que um deles?
8. **Passeios:** cabe o passeio da Praça XV já na primeira versão, ou prefere lançar o Capítulo 1 só com o menu "Ir até..." e trazer os passeios no Capítulo 2? A Rua do Viaduto entra ou fica de fora?
9. **Seleções novas:** você pretende criar as seleções aos pares (cada uma com a sua rival de clássico)? Já tem uma lista? Isso define os espelhos.
10. **Unidos do Cais:** topa um quinto time no arcade (JSON e uniforme, com retratos de Vitor, Beto e Caio e duas silhuetas)?
11. **Tom crítico:** a crítica ao mercado (cotação, câmeras, fitas usadas sem crédito, posts com preço) está na medida, ou você quer a história mais leve ainda?
12. **Modelo de lançamento:** Capítulo 1 gratuito e jogo completo pago, ou tudo gratuito? Isso muda quanto vale investir em CGs, campos e música.
13. **Idiomas:** lançamento só em português do Brasil? Quer manter IDs de fala prontos para inglês e espanhol?
14. **Augusto:** prefere com rosto (uma imagem nova) ou só como voz e silhueta no telão (zero imagens, mais frio)?
15. **Lugares reais:** pode citar Belford Roxo, Madureira, Campo Grande e as cidades de origem dos estrangeiros, mantendo os lugares do jogo com nomes fictícios?
16. **Peso dos dilemas:** os dilemas de dinheiro, família, contrato e exposição estão no tamanho certo para a classificação 14+ e para a energia que você quer, ou prefere algum mais leve (por exemplo, sem dívida com agente)?

---

## Apêndice: amostra de roteiro (cena 1.03, "O alambrado")

Formato de escrita proposto: texto simples, convertido para JSON. Colchetes são condições, chaves são variáveis e `>` é narração.

```
# 1.03 O alambrado            [tronco]   cenario: campo_dia   musica: praca_dia
> Do lado de fora do alambrado, um homem de moicano vermelho discute com dois
> seguranças de colete do Índice. Entre eles, uma faixa enrolada:
> TAÇA PRAÇA XV — DOMINGO TEM.
BETO (neutro): Quase cinquenta anos, rapaz. Nem Copa do Mundo tirou esse domingo da gente.
SEGURANÇA: Ordem da organização, senhor. Semana que vem o senhor pendura de novo.
BETO (raiva*): Semana que vem. Tá bom. Vou avisar o domingo.
> A bola do aquecimento passa por cima da cerca.
[posicao == goleiro]  > Foi você que espalmou para o lado errado.
[senao]               > Foi o seu passe, forte demais.
> Ela quica duas vezes na pedra e para no pé de um rapaz de camisa laranja,
> encostado no alambrado como quem estava ali antes do alambrado.
VITOR (neutro): Tua?
> Ele não devolve com a mão. Levanta a bola com o peito do pé, deixa cair e bate
> de primeira por cima dos quatro metros de cerca. Ela desce nos seus pés como entrega.
[posicao == goleiro]  VITOR: Goleiro que não sabe usar o pé não dura na várzea. No Pregão, dizem que dura.
[senao]               VITOR: Domina com a direita, parceiro. A esquerda tá de enfeite.
[estrangeiro]         > Você não entende a frase inteira. Entende "parceiro" e entende o sorriso torto.
ESCOLHA
  - (brincalhão) "Valeu. Você joga aqui?"           -> raiz +1, vitor +1
  - (provocador) "Ninguém pediu dica."              -> vitor +1 se tom_natural == provocador
  - (sério)      "Isso foi um chute de profissional." -> vitor +2
VITOR: Jogava. Domingo. (aponta a faixa com o queixo) Agora tô de folga, parece.
IARA (fora de cena, megafone): {SELECAO}! AQUECIMENTO EM DOIS MINUTOS! E NINGUÉM CONVERSA COM A CERCA!
VITOR: Vai lá. Tão te cotando.
> Assinatura: [tico] "Cotando? Eu? Ele nem me viu correr ainda."  [felix] "...Cotando agora? Já?"
```

\* *Beto não tem expressão de raiva: usar o retrato com a sobreposição "veia de raiva" (gancho 14).*
