# Bancos de recebimento PIX

Cada empresa escolhe no cadastro qual provedor receberá seus novos pagamentos
PIX: `Asaas` ou `Sicredi`. O provedor utilizado fica gravado no pagamento, por
isso uma alteração no cadastro da empresa não interfere em cobranças pendentes.

## Sicredi

O Sicredi utiliza OAuth2 `client_credentials`. Preencha o `.env` do servidor
com as URLs e credenciais fornecidas durante a homologação:

```env
SICREDI_AUTH_URL=https://api-pix.sicredi.com.br/oauth/token
SICREDI_API_URL=https://api-pix.sicredi.com.br/api/v3
SICREDI_CLIENT_ID=SEU_CLIENT_ID
SICREDI_CLIENT_SECRET=SEU_CLIENT_SECRET
```

As URLs podem variar conforme o ambiente ou contrato; use exatamente as
informadas pelo Sicredi. A chave PIX é cadastrada na tela Configurações do
Sensor Delivery e deve pertencer à conta associada às credenciais.

Depois de definir `API_PUBLIC_URL` com o endereço HTTPS público da API, registre
os webhooks de todas as empresas que usam Sicredi:

```powershell
cd Server
npm run sicredi:webhook
```

O callback utilizado será:

```text
https://SEU_DOMINIO/api/webhooks/sicredi
```

O callback recebido não é aceito como prova isolada do pagamento. Antes de
liberar o pedido, o servidor consulta a cobrança pelo `txid` na API autenticada
do Sicredi e exige o status `CONCLUIDA`.

## Asaas

A configuração existente do Asaas continua válida para empresas que mantiverem
esse banco selecionado. Consulte `INTEGRACAO_ASAAS.md`.

## Regra do pedido

Nos dois provedores, a cobrança vale por 300 segundos. Enquanto aguarda, o
pedido fica em `AGUARDANDO_PAGAMENTO` e não aparece na central. Pagamento
confirmado muda o pedido para `RASCUNHO`; na expiração, ele é cancelado.
