# Integração PIX com Asaas

O Sensor Delivery cria um QR Code PIX exclusivo, de uso único, com validade de
5 minutos. Durante esse período o pedido permanece em
`AGUARDANDO_PAGAMENTO` e não aparece na central administrativa.

Quando o Asaas envia `PAYMENT_RECEIVED`, o pagamento passa para `APROVADO` e o
pedido para `RASCUNHO`, entrando como pedido novo. Sem pagamento em 5 minutos,
o pagamento e o pedido são cancelados.

## Configuração do servidor

Preencha no arquivo `.env` do diretório `Server`:

```env
ASAAS_API_URL=https://api-sandbox.asaas.com/v3
ASAAS_API_KEY=$aact_SEU_TOKEN_ASAAS
ASAAS_WEBHOOK_TOKEN=um-token-proprio-forte-com-mais-de-32-caracteres
```

Para produção, use `https://api.asaas.com/v3` e a chave da conta de produção.
Não utilize a API Key como token do webhook.

No painel administrativo do Asaas, cadastre um webhook de cobranças apontando
para:

```text
https://SEU_DOMINIO/api/webhooks/asaas
```

Use no webhook o mesmo valor de `ASAAS_WEBHOOK_TOKEN` e habilite pelo menos o
evento `PAYMENT_RECEIVED`.

Na configuração da empresa do Sensor Delivery, a chave PIX deve ser a chave
ativa cadastrada na mesma conta Asaas da `ASAAS_API_KEY`.

Antes de produção, valide todo o fluxo no Sandbox.
