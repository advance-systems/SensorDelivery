# Configuração de rede

O painel administrativo e o aplicativo acessam a API. Eles não devem acessar o
PostgreSQL diretamente.

## Endereço da API

Configure a seção abaixo no arquivo `sensor-delivery.ini` de cada aplicação:

```ini
[API]
BaseURL=https://api.seudominio.com
```

Também é aceito um IP público com porta, desde que o certificado contenha esse
IP nos nomes válidos do certificado:

```ini
[API]
BaseURL=https://203.0.113.10:3001
```

No Windows, o arquivo deve ficar ao lado do executável. Em Android e iOS, ele
pode ser implantado na pasta de documentos da aplicação. A variável de ambiente
`SENSOR_DELIVERY_API_URL` tem prioridade sobre o arquivo INI.

## API principal

A API usa as seguintes variáveis no arquivo `Server/.env`:

```env
HOST=0.0.0.0
PORT=3001
API_PUBLIC_URL=https://api.seudominio.com
DATABASE_URL=postgresql://usuario:senha@host-do-postgres:5432/sensor_delivery
HTTPS_ENABLED=true
TLS_KEY_PATH=certificados/privkey.pem
TLS_CERT_PATH=certificados/fullchain.pem
```

`HOST=0.0.0.0` permite receber conexões externas. O roteador, firewall e o
provedor de hospedagem também precisam liberar a porta publicada. Os caminhos
do certificado são relativos à pasta da API, mas também podem ser absolutos.
Use `TLS_CA_PATH` quando a autoridade certificadora fornecer a cadeia em um
arquivo separado e `TLS_KEY_PASSPHRASE` se a chave privada for protegida por
senha.

Quando o HTTPS terminar em um proxy reverso (Caddy, Nginx, IIS ou serviço de
nuvem), mantenha `HTTPS_ENABLED=false`, configure `TRUST_PROXY=true` e deixe o
proxy encaminhar internamente para a porta HTTP da API. Nesse cenário,
`API_PUBLIC_URL` deve continuar usando `https://`.

O painel e o aplicativo aceitam certificados emitidos por autoridades
confiáveis. Certificados autoassinados servem apenas para desenvolvimento e
precisam ser instalados como confiáveis em cada dispositivo. Em produção,
prefira um domínio com certificado válido e mantenha a porta 5432 do PostgreSQL
fechada para a internet.
