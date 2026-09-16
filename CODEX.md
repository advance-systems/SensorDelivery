# Sensor Delivery — contexto completo do projeto

Atualizado em **14/09/2026**. Este é o documento principal para continuar o desenvolvimento, preparar a demonstração e implantar o sistema no cliente. Leia-o completamente antes de alterar fontes.

## Estado executivo atual

- A **Fase 1** do painel e do aplicativo Android está funcional e o fluxo completo
  de pedido já foi validado em desenvolvimento.
- O cardápio web possui uma primeira versão visual publicada, mas ainda utiliza
  dados demonstrativos e não envia pedidos reais.
- O instalador completo **v1.3.0** foi compilado em 05/09/2026 com o APK atual
  incorporado e uma página própria de QR Code exibida depois da instalação e
  antes da conclusão do assistente.
- A instalação v1.3.0 ainda precisa ser validada de ponta a ponta em uma máquina
  ou VM Windows limpa. A compilação bem-sucedida não substitui esse teste.
- Em 14/09/2026, `http://127.0.0.1:3001/health` recusou a conexão nesta máquina,
  o serviço Windows `SensorPedidosApi` não foi encontrado na consulta e o teste
  de `https://api.sistemassensor.com.br/health` falhou durante a negociação SSL.
  Portanto, a API e o download usado pelo QR Code devem ser restabelecidos e
  validados antes da entrega ao cliente.
- A raiz `H:\Projetos\SensorDelivery` não foi reconhecida como repositório Git
  nas verificações realizadas. Não presuma que há histórico Git disponível para
  recuperar alterações.

## Aprovação obrigatória antes de alterar arquivos

Antes de criar, editar, mover, renomear ou excluir qualquer arquivo:

1. informe todos os caminhos absolutos envolvidos;
2. explique resumidamente a alteração prevista em cada um;
3. pergunte exatamente: **“Você autoriza a alteração destes arquivos?”**;
4. aguarde uma resposta afirmativa.

A autorização vale somente para os arquivos e mudanças descritos. Leituras e verificações não destrutivas não precisam de autorização.

## Visão geral

O Sensor Delivery é uma solução multiempresa composta por:

- painel administrativo Windows em Delphi FireMonkey;
- aplicativo de pedidos Android em Delphi FireMonkey;
- cardápio web responsivo em React, TypeScript, Vinext e Tailwind CSS;
- API REST em Node.js, TypeScript e Express;
- PostgreSQL;
- autenticação JWT e permissões por usuário/empresa;
- PIX por Asaas e Sicredi;
- acesso local na porta `3001` e externo por Cloudflare.

Painel e aplicativo nunca devem acessar o PostgreSQL diretamente. Todo acesso passa pela API.

## Projetos e pastas corretos

### Painel administrativo

- Projeto: `SensorDelivery.dpr` e `SensorDelivery.dproj`, na raiz.
- Principal: `uPrincipalAdmin.pas`.
- Login: `uLogin.pas`.
- Telas: `Frames/`.
- Sessão, API, navegação e componentes: `Utils/`.
- Executável de desenvolvimento: `SensorDelivery.exe`.

### Aplicativo Android atual

- Pasta: `Aplicativo/`.
- Projeto: `Aplicativo/SensorDeliveryApp.dpr` e `.dproj`.
- Principal: `Aplicativo/Forms/uPrincipal.pas`.
- Telas: `Aplicativo/Frames/`.
- Serviços: `Aplicativo/Services/`.
- Configuração implantada: `Aplicativo/sensor-delivery.ini`.
- APK gerado: `Aplicativo/Android64/Debug/SensorDeliveryApp/bin/SensorDeliveryApp.apk`.

Há um projeto móvel antigo na raiz. Use o projeto dentro de `Aplicativo/`, salvo pedido explícito em contrário.

### Cardápio web

- Pasta: `SensorDeliveryWeb/`.
- Página principal: `SensorDeliveryWeb/app/page.tsx`.
- Layout e metadados: `SensorDeliveryWeb/app/layout.tsx`.
- Estilos globais: `SensorDeliveryWeb/app/globals.css`.
- Componentes de interface: `SensorDeliveryWeb/components/ui/`.
- Imagens públicas: `SensorDeliveryWeb/public/`.
- Configuração de hospedagem: `SensorDeliveryWeb/.openai/hosting.json`.
- Dependências e comandos: `SensorDeliveryWeb/package.json`.

O front-end web usa React para navegador, não React Native. O React Native não
foi usado neste projeto; o aplicativo Android existente continua em Delphi
FireMonkey. A página foi desenhada para manter a identidade visual e a experiência
do aplicativo em navegadores de computador e celular.

### API

- Pasta: `Server/`.
- Entrada: `Server/src/server.ts`.
- Rotas: `Server/src/routes/` e `Server/src/modules/`.
- Banco/migrations: `Server/src/database/`.
- Serviços: `Server/src/services/`.
- Autenticação/permissões: `Server/src/middleware/`.
- Build: `Server/dist/`.
- Configuração sensível: `Server/.env`.
- APK público: `Server/downloads/SensorDelivery.apk`.

Não edite `Server/dist/` ou `node_modules/`. Altere `Server/src/` e execute o build.

## Rede e conexão

Endereço público padrão:

```text
https://api.sistemassensor.com.br
```

Configuração esperada da API:

```env
HOST=0.0.0.0
PORT=3001
API_PUBLIC_URL=https://api.sistemassensor.com.br
HTTPS_ENABLED=false
TRUST_PROXY=true
```

O HTTPS termina no Cloudflare. Não habilite TLS interno simultaneamente sem necessidade explícita.

### Rede local

- `127.0.0.1:3001` funciona somente no computador do servidor.
- No celular, `127.0.0.1` significa o próprio celular.
- Para demonstração no mesmo Wi-Fi, use o IPv4 do notebook, por exemplo:

```text
http://192.168.1.50:3001
```

- Notebook e celular precisam estar na mesma rede.
- A rede Windows deve ser privada.
- O Firewall deve liberar TCP `3001`.
- O roteador não pode isolar clientes Wi-Fi.
- `10.0.2.15` normalmente é NAT interno do VirtualBox e não é acessível pelo celular.

### Configuração no APK

A URL é centralizada em `Utils/uApiConfig.pas`.

- Instalação nova do Android começa em `http://127.0.0.1:3001` para abrir a
  tela de indisponibilidade e permitir a configuração do IP do servidor.
- No Android, a URL escolhida é salva no `sensor-delivery.ini` da pasta de documentos do aplicativo.
- Atualizar sem desinstalar pode preservar a URL anterior.
- HTTP local é permitido pelo manifesto Android.
- A tela Conta possui campo de servidor.
- A tela **Serviço indisponível** possui o link **Configurar conexão**.
- Links implementados com `TLabel` precisam declarar `HitTest = True`, pois o
  FireMonkey cria `TLabel` com toque desabilitado por padrão.
- Nesta versão do FireMonkey, `TMemo` não possui a propriedade `TextPrompt`.
  Não grave essa propriedade em objetos `TMemo` nos arquivos `.fmx`; use um
  título ou label auxiliar. `TEdit` pode continuar usando `TextPrompt`.

Ao tocar no link, abre uma janela com o endereço atual. Um IP simples como
`192.168.1.50` é convertido em `http://192.168.1.50:3001`, salvo e testado
novamente. O endereço `127.0.0.1` no Android aponta para o próprio celular e é
usado apenas como estado inicial antes da configuração.

Arquivos relacionados:

- `Utils/uApiConfig.pas`;
- `Aplicativo/AndroidManifest.template.xml`;
- `Aplicativo/Frames/uFrameContaMobile.pas` e `.fmx`;
- `Aplicativo/Frames/uFrameSituacaoLoja.pas` e `.fmx`.

## Fase 1 concluída

### Painel

- autenticação, empresas, usuários e permissões;
- categorias e produtos;
- sabores, bordas, adicionais e combos;
- valores de sabores por categoria/produto;
- configuração de loja, horários, taxa e pedido mínimo;
- alerta de novo pedido;
- central de pedidos e mudança de status;
- pedidos e clientes;
- tema escuro aplicado a campos, combos, listas e botões;
- correções de alinhamento, truncamento, rolagem e desempenho;
- tela de sabores otimizada para dezenas de registros.

### Sabores, bordas e adicionais

- Pizzas e pastéis podem ter sabores separados.
- Um sabor pode pertencer a várias categorias sem duplicação.
- Somente produtos com valor preenchido exibem o sabor no cardápio.
- Se o produto possui preço, o valor do sabor é adicional.
- Se o produto não possui preço, o valor do sabor é o preço efetivo.
- Bordas seguem o conceito de categoria/produto e valor.
- A tela de Bordas fica abaixo de Sabores no menu.
- Não há botão redundante de Sabores dentro de Bordas.
- A rolagem das bordas não deve selecionar ao soltar o dedo.
- Lanches podem possuir adicionais.
- Adicionais possuem produto, nome, preço, limite, ordem e opcionalidade.

### Aplicativo

- seleção da loja;
- cardápio carregado pela API;
- categorias, produtos e imagens remotas com fallback;
- montagem por tamanho, sabores e borda;
- adicionais e limites de sabores;
- carrinho, endereço, observação e confirmação;
- envio do pedido;
- acompanhamento e atualização de status;
- histórico e pagamento PIX;
- textos e cards ampliados;
- correções de descrições truncadas e acentuação;
- proteção contra toque acidental durante rolagem;
- ajuste do tempo de toque em sabores e bordas;
- tela moderna de indisponibilidade;
- configuração manual do servidor dentro do APK.

### Fluxo validado

Foi testado com sucesso: montar pedido, preencher dados, finalizar, receber no painel, mudar status no painel e visualizar a mudança no aplicativo. Esse marco encerrou a **Fase 1**.

## Cardápio web — primeira versão

Em 03/09/2026 foi criado o projeto `SensorDeliveryWeb`, separado do aplicativo
Android e do painel administrativo.

Tecnologias:

- React e TypeScript;
- Vinext para desenvolvimento e build;
- Tailwind CSS para o layout responsivo;
- componentes Shadcn para janelas e painéis;
- ícones Lucide;
- hospedagem pelo Sites.

Funcionalidades já implementadas:

- cabeçalho com logotipo Sensor Delivery;
- apresentação da loja, situação aberta e previsão de entrega;
- busca por nome ou descrição;
- filtros por categoria;
- cards responsivos com imagem, descrição e preço;
- categorias demonstrativas de pizzas, combos, lanches, porções e bebidas;
- janela com detalhes do produto;
- inclusão no carrinho;
- alteração de quantidades;
- cálculo do total;
- painel lateral do carrinho;
- navegação inferior para telas pequenas;
- layout adaptado para celular e computador;
- ações estruturadas para listar produtos, incluir item e consultar o carrinho
  em navegadores compatíveis.

O build foi executado com sucesso por meio de `npm run build`.

Versão privada publicada:

```text
https://sensor-delivery-web.espa-o-de-tr-7844.chatgpt.site
```

Estado atual e limites:

- os produtos da primeira versão são demonstrativos e estão definidos no
  front-end;
- as imagens foram reaproveitadas dos materiais existentes no projeto;
- ainda não há autenticação de cliente;
- ainda não há integração do cardápio com a API e o PostgreSQL;
- o botão de continuar pedido ainda não finaliza pedidos reais;
- endereço, entrega, pagamento, acompanhamento e histórico ainda precisam ser
  conectados ao fluxo real;
- a publicação atual é privada e serve para visualização e evolução do projeto.

Próxima fase recomendada para o web:

1. definir a URL da API por configuração de ambiente;
2. carregar empresa, loja, categorias, produtos, imagens e disponibilidade pela API;
3. reutilizar as regras de tamanhos, sabores, bordas, adicionais e combos;
4. implementar cadastro ou identificação do cliente;
5. implementar endereço, taxa de entrega, pedido mínimo e horários;
6. finalizar e enviar o pedido pela mesma API usada pelo aplicativo;
7. implementar acompanhamento de status e PIX;
8. testar em celular, computador e redes externas;
9. definir domínio e política de acesso para publicação ao cliente.

Comandos em `SensorDeliveryWeb/`:

```powershell
npm install
npm run dev
npm run build
```

Não edite arquivos gerados em `SensorDeliveryWeb/dist/` nem dependências em
`SensorDeliveryWeb/node_modules/`. As alterações devem ser realizadas nos fontes.

## API e banco

- PostgreSQL acessado com `pg` e SQL direto; não há ORM.
- O sistema é multiempresa; não fixe IDs de empresa.
- Consultas devem respeitar empresa ativa e permissões.
- Migrations devem ser cumulativas e seguras.
- Não apagar, recriar ou restaurar banco sem pedido explícito.
- Não publicar a porta `5432`.

Comandos em `Server/`:

```powershell
npm install
npm run db:test
npm run db:migrate
npm run db:seed
npm run dev
npm run build
npm start
```

Validação:

```text
http://127.0.0.1:3001/health
https://api.sistemassensor.com.br/health
```

Esperado: HTTP 200, `status: online` e `banco: conectado`.

## Problema conhecido do serviço Windows

Em 02/09/2026, `SensorPedidosApi` estava parado e registrado com um caminho antigo:

```text
E:\Projetos\Web\sensor_pedidos\ServerNodePedidos\deploy\SensorPedidosApi.exe
```

A API foi iniciada manualmente em `Server/`, restaurando o `/health` local, público e o download do APK.

Em 14/09/2026, uma nova verificação encontrou o `/health` local recusando conexão
e não retornou registro para `SensorPedidosApi`. O `/health` público também não
pôde ser validado por falha SSL. Trate o serviço e o acesso público como
**indisponíveis até nova comprovação**, mesmo que tenham funcionado anteriormente.

Antes da implantação é obrigatório:

- corrigir o serviço para a pasta real instalada;
- definir inicialização automática;
- aguardar PostgreSQL ou repetir a conexão com atraso;
- testar recuperação após reinício;
- eliminar a dependência de `npm start` manual.

## Compilação do painel

Exemplo com Delphi 12 Athens:

```powershell
& cmd.exe /d /c 'call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat" && dcc32.exe SensorDelivery.dpr'
```

Se o EXE estiver aberto, compile em pasta temporária, feche somente o processo do Sensor Delivery, copie o novo EXE e compare hashes.

## Compilação Android

Em `Aplicativo/`:

```powershell
& cmd.exe /d /c 'call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat" && msbuild SensorDeliveryApp.dproj "/t:Clean;Build" /p:Config=Debug /p:Platform=Android64'
```

O projeto aponta para um JDK 17 removido. Em 02/09/2026 o Deploy funcionou, sem editar o projeto, com:

```powershell
& cmd.exe /d /c 'call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat" && msbuild SensorDeliveryApp.dproj /t:Deploy /p:Config=Debug /p:Platform=Android64 "/p:JAVA_TOOL=C:\Program Files\Eclipse Adoptium\jdk-21.0.7.6-hotspot\bin\java.exe"'
```

Pendências:

- corrigir de forma controlada a configuração permanente do JDK;
- criar assinatura Release própria;
- guardar chave e senhas fora do repositório;
- gerar AAB assinado para a Play Store.

## APK atual

Gerado em 02/09/2026:

- `Distribuicao/APK/SensorDeliveryApp-atual.apk`;
- `Distribuicao/ENTREGA-CLIENTE-FASE1-2026-08-28/SensorDeliveryApp-Fase1-2026-08-28.apk`;
- `Server/downloads/SensorDelivery.apk`;
- download: `https://api.sistemassensor.com.br/downloads/SensorDelivery.apk`;
- tamanho: `15.906.921` bytes;
- SHA-256: `A6B98BCBEECA0E49990AD56838B2F3A1E6D048924247B9D324BB3CDC196C7778`;
- assinatura JAR verificada;
- Android64 compilado sem erros.

Hash da entrega:

```text
Distribuicao/ENTREGA-CLIENTE-FASE1-2026-08-28/SensorDeliveryApp-Fase1-2026-08-28.apk.sha256.txt
```

Antes de anunciar outro APK, confirme data, tamanho, hash, assinatura e igualdade com o download público.

## Play Store

- Cadastro planejado como pessoa física.
- Não há confirmação registrada de que o cadastro tenha sido concluído.
- Fora da Play Store, o Android continuará mostrando avisos normais de instalação externa.
- Não existe forma legítima de eliminar todos os avisos de segurança de um APK externo.
- A publicação exigirá AAB/Release assinado, ícones, capturas, política de privacidade e questionários.

## Instalador, distribuição e backup

Materiais estão em `Distribuicao/`, `InstalacaoNotebook/` e `ServicoWindows/`. Instruções principais:

- `Distribuicao/DESINSTALACAO-E-NOVA-INSTALACAO-FASE1.md`;
- `Distribuicao/COMO-REINSTALAR-LIMPO.md`;
- `Distribuicao/ENTREGA-CLIENTE-FASE1-2026-08-28/`.

O instalador deve incluir painel, API, PostgreSQL/pré-requisitos, banco autorizado, serviço Windows, Firewall TCP 3001, `.env`, atalhos e documentação.

### Instalador completo v1.3.0

Fonte do Inno Setup:

```text
Distribuicao/Instalador-Painel-SensorDelivery/SensorDelivery-Painel.iss
```

Arte do QR Code:

```text
Distribuicao/Instalador-Painel-SensorDelivery/SensorDelivery-App-QRCode.bmp
```

Pacote incorporado pelo instalador:

```text
Distribuicao/SensorDelivery-Instalador-Cliente-Fase1-2026-08-28/
```

O APK incorporado fica em:

```text
Distribuicao/SensorDelivery-Instalador-Cliente-Fase1-2026-08-28/Servidor/downloads/SensorDelivery.apk
```

Esse APK foi substituído pela versão atual e teve igualdade de SHA-256 confirmada
com `Distribuicao/APK/SensorDeliveryApp-atual.apk`:

```text
A6B98BCBEECA0E49990AD56838B2F3A1E6D048924247B9D324BB3CDC196C7778
```

Instalador gerado:

```text
Distribuicao/SensorDelivery-Instalacao-Completa-v1.3.0-2026-09-05.exe
```

- tamanho: `98.844.733` bytes;
- SHA-256: `ED19178DA7E3277A06814A0081E4A2C202990DBCF1FA7D34BC66354C2AF84EF4`;
- hash registrado em
  `Distribuicao/SensorDelivery-Instalacao-Completa-v1.3.0-2026-09-05.exe.sha256.txt`;
- compilado com Inno Setup 6 e compressão `lzma2/ultra64`;
- diretório padrão: `C:\SistemasSensor\SensorDelivery`;
- requer Windows de 64 bits e privilégios administrativos.

Ao finalizar a configuração do sistema, o instalador apresenta uma página própria
chamada **Aplicativo Sensor Delivery**, antes da tela final. Ela contém um QR Code
e um link clicável apontando para:

```text
https://api.sistemassensor.com.br/downloads/SensorDelivery.apk
```

A primeira tentativa colocou o QR Code diretamente na página final nativa do
Inno Setup, mas os controles ficaram ocultos. A versão definitiva usa
`CreateCustomPage(wpInstalling, ...)`, garantindo uma etapa própria após a
instalação. Sempre utilize o executável cujo hash começa por `ED19178D`; uma
compilação anterior da mesma versão tinha implementação defeituosa e outro hash.

O QR Code depende do endereço público estar operacional. Ter o APK dentro do
instalador garante que o servidor instalado possua o arquivo em `downloads`, mas
não garante sozinho que o domínio público ou o túnel Cloudflare estejam ativos.

Para recompilar:

```powershell
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' /Qp 'Distribuicao\Instalador-Painel-SensorDelivery\SensorDelivery-Painel.iss'
```

Depois de recompilar, recalcule o SHA-256, atualize o `.sha256.txt` e teste numa
máquina limpa. Não reutilize o hash acima se o executável for recompilado.

Histórico:

- foi preparada entrega com os dados da máquina de desenvolvimento;
- em VM limpa, `initdb` falhou com `-1073741515`;
- o instalador precisa incluir/corrigir os pré-requisitos do PostgreSQL;
- foi solicitada compressão Ultra64;
- a VM era VirtualBox com IP NAT `10.0.2.15`;
- teste com celular deve usar bridge ou IP acessível na LAN;
- já foi solicitado backup do projeto.
- o instalador v1.3.0 foi compilado sem erros, mas não foi executado nesta máquina
  para evitar alterações nos serviços e no banco de desenvolvimento;
- ainda é necessário confirmar visualmente a página do QR Code e testar a leitura
  pelo celular no fluxo completo do instalador.

Antes de mudanças estruturais, faça backup datado e verificável. Proteja backups com banco ou segredos.

## Padrões de interface

### Painel

- tema escuro;
- campos próximos de `$FF152439`, borda `$FF2A405B`;
- foco roxo `$FF8C63FF`;
- texto principal `$FFF4F7FB`;
- texto secundário `$FF9CAABC` / `$FF8795A8`;
- reutilizar `TfraSensorButton` e `uSensorIcons`;
- combos e dropdowns não podem abrir com fundo branco;
- evitar truncamento, desalinhamento e botões colados ao rodapé;
- preservar `Utils/uNavegacaoCampos.pas` e `Utils/uCursorCamposAdmin.pas`.

### Aplicativo

- cards legíveis em telas pequenas;
- nomes e descrições importantes sem truncamento;
- imagens assíncronas com timeout e fallback;
- nenhuma requisição por item ao montar listas;
- não bloquear a thread visual;
- rolagem não pode acionar seleção;
- mensagens modernas e sem mojibake;
- indisponibilidade deve aparecer rapidamente e permitir reconfiguração.

## UTF-8 e Delphi

- manter `.pas`, `.fmx`, `.json`, `.md` e configurações em UTF-8;
- não converter em massa para Windows-1252;
- procurar `Ã`, `Â` e `�`;
- se o compilador corromper literal acentuado, usar composição explícita:

```pascal
'Ver card' + Char($00E1) + 'pio'
'Ver hor' + Char($00E1) + 'rios'
```

## Segurança

- não documentar senhas, tokens, JWT secrets ou chaves bancárias;
- não exibir o conteúdo integral de `Server/.env`;
- não gravar segredos em fontes;
- validar permissões também na API;
- não sobrescrever banco ou `.env` silenciosamente;
- não limpar/restaurar/reinstalar sem autorização;
- não usar `git reset --hard` nem descartar mudanças do usuário.

## Pendências prioritárias

### Antes da demonstração

- [ ] corrigir `SensorPedidosApi` e remover o caminho antigo `E:`;
- [ ] garantir início automático da API após reiniciar;
- [ ] liberar TCP 3001 para rede privada;
- [ ] descobrir o IPv4 do notebook da demonstração;
- [ ] testar `http://IP-DO-NOTEBOOK:3001/health` no celular;
- [ ] instalar o APK atual e testar **Configurar conexão**;
- [ ] testar painel e celular juntos, inclusive sem internet;
- [ ] fazer pedido completo e acompanhar todos os status;
- [ ] criar backup final antes de ir ao cliente.

### Antes da instalação no cliente

- [ ] corrigir `initdb -1073741515` e incluir pré-requisitos;
- [ ] testar instalador em VM Windows limpa;
- [ ] validar desinstalação e reinstalação pelos `.md` existentes;
- [ ] confirmar restauração do banco autorizado;
- [ ] verificar serviço, PostgreSQL, API, painel e Firewall após reinício;
- [ ] validar imagens e uploads no celular;
- [x] gerar o instalador v1.3.0 com compressão Ultra64, APK e QR Code;
- [x] guardar o instalador v1.3.0, o APK atual e respectivos hashes;
- [ ] executar o instalador v1.3.0 em VM limpa e confirmar visualmente a página do QR Code;
- [ ] ler o QR Code com um celular e concluir o download do APK pelo domínio público;

### Antes da produção pública

- [ ] concluir cadastro da Play Store;
- [ ] criar chave de produção;
- [ ] gerar e testar APK/AAB Release;
- [ ] preparar política de privacidade e ficha da loja;
- [ ] garantir disponibilidade permanente da API;
- [ ] configurar serviço/túnel com recuperação automática;
- [ ] revisar logs, backup do banco e recuperação de desastre;
- [ ] trocar credenciais iniciais no cliente.

### Cardápio web

- [x] criar o projeto React responsivo com o visual do aplicativo;
- [x] implementar busca, categorias, produtos, detalhes e carrinho local;
- [x] validar a compilação da primeira versão;
- [x] publicar uma versão privada para avaliação;
- [ ] substituir os dados demonstrativos por dados reais da API;
- [ ] implementar personalização completa dos produtos;
- [ ] implementar identificação, endereço e confirmação do cliente;
- [ ] enviar pedidos reais e acompanhar seus status;
- [ ] integrar pagamento PIX;
- [ ] configurar domínio e acesso de produção;
- [ ] executar testes completos de responsividade e fluxo de compra.

## Diagnóstico rápido de “Serviço indisponível”

1. veja a URL em **Configurar conexão**;
2. teste `http://127.0.0.1:3001/health` no servidor;
3. teste `http://IP-DO-NOTEBOOK:3001/health` no celular;
4. confirme Node/API e PostgreSQL ativos;
5. confirme `HOST=0.0.0.0` e `PORT=3001`;
6. confira Firewall, rede privada e isolamento Wi-Fi;
7. para acesso externo, teste o `/health` público;
8. HTTP 502 público normalmente significa API/origem parada.

## Validação do instalador e do QR Code

1. confira se o instalador usado possui SHA-256
   `ED19178DA7E3277A06814A0081E4A2C202990DBCF1FA7D34BC66354C2AF84EF4`;
2. execute em Windows de 64 bits, preferencialmente numa VM limpa;
3. confirme a instalação de PostgreSQL, banco, API, painel, serviço e Firewall;
4. depois da etapa de instalação, confirme a página **Aplicativo Sensor Delivery**;
5. confira se o QR Code está centralizado e legível;
6. leia o QR Code com o celular e confirme que ele aponta para
   `https://api.sistemassensor.com.br/downloads/SensorDelivery.apk`;
7. conclua o download e compare tamanho/hash do APK quando possível;
8. se o QR abrir mas o download falhar, teste primeiro o `/health` público e o
   caminho `/downloads/SensorDelivery.apk` diretamente no navegador;
9. se o domínio estiver indisponível, corrija o serviço/túnel/SSL antes de gerar
   outro QR Code; o conteúdo do QR atual já aponta para o endereço oficial.

## Fluxo obrigatório para próximas tarefas

1. ler este arquivo;
2. cumprir a autorização antes de qualquer gravação;
3. identificar painel, aplicativo, API, banco ou instalador;
4. procurar implementações reutilizáveis com `rg`;
5. fazer alterações pequenas e localizadas;
6. preservar multiempresa, permissões, tema e UTF-8;
7. validar proporcionalmente:
   - API: build, banco e endpoint;
   - painel: compilação Win32 e tela;
   - Android: Clean/Build, Deploy, assinatura, tamanho e hash;
   - instalador: VM limpa, reinício, serviço, desinstalação e reinstalação;
   - web: build, responsividade, integração com a API, carrinho e envio do pedido;
8. informar arquivos alterados, testes e pendências reais.
