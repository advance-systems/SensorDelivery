# Guia de Implantação: Railway (API & PostgreSQL) + Vercel (Frontends)

Este guia contém o passo a passo completo para publicar o **Sensor Delivery** em ambiente de produção utilizando **Railway (Plano Hobby)** e **Vercel (Plano Free)**.

---

## Arquitetura em Produção

```
┌─────────────────────────────────┐       ┌─────────────────────────────────┐
│       Vercel (Plano Free)       │       │       Vercel (Plano Free)       │
│    SensorDeliveryAdminWeb       │       │       SensorDeliveryWeb         │
│ (Painel Administrativo - Vite)  │       │       (Cardápio Online)         │
└────────────────┬────────────────┘       └────────────────┬────────────────┘
                 │                                         │
                 │ HTTPS (CORS liberado)                   │ HTTPS
                 ▼                                         ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                          Railway (Plano Hobby)                            │
│                                                                           │
│  ┌─────────────────────────────────┐    Internal/SSL   ┌───────────────┐  │
│  │          API Express            │ ───────────────── │  PostgreSQL   │  │
│  │   (sensor-delivery-server)      │                   │   Database    │  │
│  └─────────────────────────────────┘                   └───────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Configuração no Railway (API e Banco de Dados)

### Passo 1.1: Criar o Projeto e o Banco PostgreSQL
1. Acesse seu painel do [Railway](https://railway.com/) e clique em **+ New Project**.
2. Selecione **Provision PostgreSQL**.
3. Aguarde o banco ser inicializado.
4. Clique no card do **Postgres** -> aba **Variables** para ver que a variável `DATABASE_URL` já foi gerada automaticamente.

### Passo 1.2: Criar o Serviço da API Node.js
1. No mesmo projeto do Railway, clique em **+ Create** / **New Service** -> **GitHub Repo** (ou use a CLI do Railway).
2. Selecione o repositório do projeto.
3. Clique no serviço criado e acesse a aba **Settings**:
   - **Root Directory**: preencha com `/Server` ou `Server`.
   - **Build Command**: `npm run build`
   - **Start Command**: `npm run start`
   - **Public Networking**: Clique em **Generate Domain** para obter a URL pública (ex: `https://sensor-delivery-api-production.up.railway.app`).
4. Acesse a aba **Variables** e adicione:
   - `DATABASE_URL` = `${{Postgres.DATABASE_URL}}` *(utiliza a referência automática do Railway)*
   - `DATABASE_SSL` = `true`
   - `JWT_SECRET` = `gere_uma_chave_secreta_longa_e_segura_com_mais_de_32_caracteres`
   - `CORS_ORIGIN` = `*` *(ou especifique os domínios da Vercel quando criados)*
   - `NODE_ENV` = `production`
   - `API_PUBLIC_URL` = `https://<seu-dominio-gerado-no-railway>.up.railway.app`

### Passo 1.3: Rodar as Migrations e Seeds no Banco
Você pode executar as migrations e seeds de duas formas:
- **Opção A (Via Railway CLI no seu terminal local):**
  ```powershell
  # Na pasta Server:
  railway login
  railway link
  railway run npm run db:migrate
  railway run npm run db:seed
  ```
- **Opção B (Via aba "Deploy" / terminal do Railway):**
  Acesse o serviço da API no Railway -> clique na aba **Deployments** / **CLI/Shell** e execute:
  ```bash
  npm run db:migrate
  npm run db:seed
  ```

### Passo 1.4: Testar a API
Abra no navegador:
`https://<seu-app-railway>.up.railway.app/health`

Deve retornar:
```json
{
  "status": "online",
  "sistema": "Sensor Delivery",
  "banco": "conectado"
}
```

---

## 2. Configuração na Vercel (Frontends)

### Passo 2.1: Publicar o Painel Admin (`SensorDeliveryAdminWeb`)
1. Acesse o [Dashboard da Vercel](https://vercel.com/) e clique em **Add New...** -> **Project**.
2. Importe o repositório do GitHub.
3. Na tela de configuração:
   - **Project Name**: `sensor-delivery-admin` (ou o nome de sua preferência)
   - **Framework Preset**: `Vite`
   - **Root Directory**: clique em **Edit** e selecione `SensorDeliveryAdminWeb`.
4. Em **Environment Variables**, adicione:
   - **Key**: `VITE_API_URL`
   - **Value**: `https://<seu-app-railway>.up.railway.app/api`
5. Clique em **Deploy**.

> **Nota:** O arquivo `SensorDeliveryAdminWeb/vercel.json` já configurado garante que todas as rotas internas (`/pedidos`, `/cardapio`, `/login`) funcionem sem erro 404 ao atualizar a página.

---

### Passo 2.2: Publicar o Cardápio Web (`SensorDeliveryWeb`)
1. Na Vercel, clique em **Add New...** -> **Project**.
2. Selecione o mesmo repositório do GitHub.
3. Na tela de configuração:
   - **Project Name**: `sensor-delivery-cardapio` (ou o nome de sua preferência)
   - **Root Directory**: selecione `SensorDeliveryWeb`.
4. Clique em **Deploy**.

---

## 3. Checklist de Validação Final

- [ ] `GET https://<api-railway>/health` respondendo `{ "status": "online", "banco": "conectado" }`.
- [ ] Acessar `https://<admin-vercel>.vercel.app/login` e efetuar login com o usuário padrão (ou cadastrado via seed).
- [ ] Navegar pelas abas do Painel Admin (Central de Pedidos, Cardápio, Configurações).
- [ ] Acessar o Cardápio Web na Vercel e verificar carregamento dos produtos.
