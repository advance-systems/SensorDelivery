# Sensor Delivery Server — SQL direto

Sem Prisma ou ORM. Usa PostgreSQL, TypeScript, Express e `pg`.

## Instalação

```sql
CREATE DATABASE sensor_delivery WITH ENCODING='UTF8' TEMPLATE=template0;
```

```bash
npm install
# copie .env.example para .env e ajuste a senha
npm run db:test
npm run db:migrate
npm run db:seed
npm run dev
```

Rotas iniciais: `GET /health` e `GET /empresas`.

Acesso inicial: `admin@sensordelivery.local` / `Sensor@123`. Troque a senha antes da produção.
