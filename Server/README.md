# Sensor Delivery API — piloto Railway

Arquitetura definida em 06/10/2026: um projeto Railway por cliente, com uma
instância da mesma API e um serviço PostgreSQL próprio no mesmo ambiente.
O painel Delphi, o aplicativo Android e o cardápio web acessam apenas a API pública.
Filiais podem continuar usando empresa_id dentro do banco do cliente.

## Preparação local

Node.js 24 LTS é utilizado no Docker. As dependências permanecem no package-lock.json.

```powershell
npm ci
npm run check
npm run test:railway
npm run build
```

O build grava dist; só executar após autorização dos arquivos gerados.
Os testes usam configurações fictícias e bloqueiam consultas reais ao banco.
O Server/.env existente é local e não é modificado pela preparação.

## Implantação por cliente

1. Criar projeto e ambiente de teste do cliente no Railway.
2. Adicionar PostgreSQL e API no mesmo ambiente para conexão privada.
3. Se a origem for GitHub, configurar Root Directory como /Server e conferir
   que o arquivo de configuração utilizado seja /Server/railway.json.
   Para build Docker, o contexto é a pasta Server.
4. Criar volume na API, montado em /data. Usar UPLOADS_DIR=/data/uploads e
   DOWNLOADS_DIR=/data/downloads. O Railway fornece RAILWAY_VOLUME_MOUNT_PATH.
5. Cadastrar variáveis pelo painel Railway, tomando .env.example como referência.
   DATABASE_URL deve referenciar a conexão privada do PostgreSQL daquele projeto.
   Usar DATABASE_SSL=false na rede privada; conexões externas precisam de política
   TLS correspondente ao servidor, com verificação de certificado por padrão.
   Definir JWT_SECRET aleatório e exclusivo de pelo menos 32 caracteres.
6. Definir API_PUBLIC_URL com HTTPS e CORS_ORIGIN com as origens exatas dos sites.
   HOST=0.0.0.0, HTTPS_ENABLED=false e TRUST_PROXY=true. Railway fornece PORT.
7. Antes do primeiro deploy, restaurar somente o backup autorizado da pizzaria
   no banco de teste, preservando schema_migrations e schema_seeds.
   Não usar seeds demonstrativos nem importar cardápio automaticamente.
8. O pré-deploy executa npm run db:migrate:deploy. Falha impede a implantação.
   Revisar migrations pendentes antes de permitir esse comando.
9. O /health verifica conexão e tabelas essenciais. Ele é usado para ativar o
   deploy e não substitui monitoramento contínuo.
10. Copiar imagens autorizadas para /data/uploads e o APK validado para
    /data/downloads/SensorDelivery.apk. O pacote Docker não inclui uploads,
    APKs, backups, .env nem cardápios particulares.
11. Validar fluxo completo antes de trocar URLs do painel e aplicativo.

O pré-deploy não tem o volume montado: migrations leem SQL incluído na imagem,
sem gravar arquivos no volume. O serviço com volume pode ter breve indisponibilidade
durante novas implantações; testar esse comportamento no piloto.

## Inicialização e rotinas

Por padrão a inicialização não executa migrations, seeds nem importação.
Na produção, RUN_MIGRATIONS_ON_START, RUN_SEEDS_ON_START e IMPORT_MENU_ON_START
devem permanecer false. Em desenvolvimento podem ser ativadas explicitamente,
quando as alterações no banco forem autorizadas.

BACKGROUND_JOBS_ENABLED=false no piloto desativa o monitor de expiração PIX e
polling iFood. Ativar após revisar integrações e dados: esse monitor é necessário
para a operação normal dessas funções. Webhooks e consultas por pedido continuam
funcionando independentemente do monitor.

DRAFT_CLEANUP_ENABLED=false suspende a limpeza tanto no monitor quanto na listagem
de pedidos: a própria rotina retorna antes de consultar ou excluir dados.
Ativar exige revisar cancelar_rascunhos_antigos por empresa: a rotina elimina
rascunhos de dias anteriores, inclusive seus registros relacionados.

A API tenta conectar ao PostgreSQL antes de escutar HTTP; o número de tentativas
é DB_STARTUP_ATTEMPTS. Erro de conexão ou estrutura encerra o processo com falha.
SIGTERM/SIGINT encerram listener e pool, com limite de dez segundos.

## Acesso e importação

O acesso mestre não tem senha padrão e fica desativado, mesmo que o e-mail
coincida com o administrador inicial. Usar usuários reais da pizzaria, alterando
qualquer senha inicial antes da produção. Se necessário, habilitar explicitamente
ADMIN_MASTER_ENABLED=true com ADMIN_MASTER_EMAIL e ADMIN_MASTER_SENHA exclusivos
(senha de pelo menos 16 caracteres). Esse acesso administra todo o banco do cliente.

A rota de manutenção agora é POST /api/importar-anota-ai. Exige token de
administrador com acesso ao cardápio e ALLOW_MENU_IMPORT=true. Mantê-la desabilitada
na produção; o arquivo particular do cardápio não é enviado na imagem Docker.
O importador legado requer MENU_IMPORT_PATH e utiliza DATABASE_URL, sem credencial
local embutida. Importação manual ainda requer autorização de dados e empresa alvo.

## PIX

Cada cliente configura suas próprias credenciais Asaas/Sicredi e chave PIX.
Usar sandbox/homologação antes de credenciais reais. Os callbacks são:
- /api/webhooks/asaas — exige ASAAS_WEBHOOK_TOKEN;
- /api/webhooks/sicredi — confirma recebimento consultando a API autenticada do provedor.

Atualizar o endereço dos callbacks no provedor para API_PUBLIC_URL daquele cliente.
Não executar sicredi:webhook antes de autorizar a alteração externa.
Validar criação, consulta, confirmação, expiração e repetição de callbacks.

## Backup e piloto

Configurar backups do volume PostgreSQL e do volume da API. Manter também exportação
lógica externa protegida. Testar restauração em ambiente separado, incluindo imagens.
Nunca sobrescrever o banco atual ou de produção para realizar um ensaio.

Há histórico de migrations e seeds com dados de demonstração e ajuste de logotipo
específico (024_fix_logo_permanente.sql). Eles não são um cadastro genérico de novos
clientes. O piloto deve preservar o histórico restaurado. Antes de provisionar
um cliente vazio, revisar separadamente migrations históricas e cadastro inicial.

A credencial local removida do importador pode existir no histórico Git:
trocar essa credencial antes de reutilizá-la fora do desenvolvimento. Imagens
particulares já versionadas continuam no histórico; .dockerignore apenas impede
sua inclusão no contexto Docker, não as remove do repositório.

Pendências após a preparação local: build Docker real, criação dos serviços Railway,
backup/restauração autorizados, transferência de imagens/APK, configuração de PIX,
monitoramento contínuo e testes reais de painel/celular. A hospedagem depende de internet.

Referências:
- https://docs.railway.com/deployments/pre-deploy-command
- https://docs.railway.com/volumes
- https://docs.railway.com/deployments/healthchecks
- https://docs.railway.com/networking/private-networking

## Banco local para testes

O ambiente local utiliza SENSOR_DELIVERY_TESTE, usuário PostgreSQL próprio e
.env.test (ignorado pelo Git). A API de testes escuta na porta 3031.
O banco SENSOR_DELIVERY e a configuração .env existentes são preservados.

Executar a preparação somente com autorização de criação do banco e do arquivo:

```powershell
$env:TSX_DISABLE_CACHE='1'
npm run db:prepare:local
npm run db:check:local
# Iniciar depois de restaurar e revisar os dados:
npm run dev:test
```

A preparação padrão cria um banco vazio, pois foi solicitada a restauração dos
dados reais do cliente Railway. Ela recusa banco, usuário ou .env.test existentes.
Para um ambiente separado com demonstração, a opção --demo aplica migrations e
seeds; não utilizá-la junto de uma restauração real.

Backup solicitado: projeto Railway Sensor Delivery, serviço Postgres, ambiente
production. Confirmar a pizzaria e as contagens antes do dump. O banco remoto não
tem proxy TCP público; usar SSH autorizado. Falta autorização dos arquivos do
backup e das chaves SSH antes de criá-los. Não abrir porta pública para esse fim.

Restaurar somente no banco local vazio, com --no-owner --no-acl e transação única.
Não usar --clean, não recriar o banco atual nem alterar o banco Railway. Verificar
as contagens e o histórico de migrations. O backup lógico não inclui imagens
do volume da API. Credenciais de integração podem existir no banco restaurado;
manter rotinas desligadas e revisar antes de testar PIX/iFood.
