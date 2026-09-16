import fs from 'node:fs/promises';
import path from 'node:path';
import { database } from './connection.js';

async function executarMigrations(): Promise<void> {
  await database.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      arquivo VARCHAR(255) PRIMARY KEY,
      executado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const migrationsDirectory = path.resolve(
    process.cwd(),
    'database',
    'migrations',
  );

  const arquivos = (await fs.readdir(migrationsDirectory))
    .filter((arquivo) => arquivo.endsWith('.sql'))
    .sort();

  for (const arquivo of arquivos) {
    const migrationExecutada = await database.query(
      `
        SELECT arquivo
        FROM schema_migrations
        WHERE arquivo = $1
      `,
      [arquivo],
    );

    if (migrationExecutada.rowCount) {
      console.log(`Migration já executada: ${arquivo}`);
      continue;
    }

    const caminho = path.join(migrationsDirectory, arquivo);
    const sql = await fs.readFile(caminho, 'utf8');

    const client = await database.connect();

    try {
      await client.query(sql);

      await client.query(
        `
          INSERT INTO schema_migrations (arquivo)
          VALUES ($1)
        `,
        [arquivo],
      );

      console.log(`Migration executada: ${arquivo}`);
    } catch (error) {
      console.error(`Erro na migration ${arquivo}:`, error);
      throw error;
    } finally {
      client.release();
    }
  }
}

executarMigrations()
  .catch((error) => {
    console.error('Falha ao executar migrations:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await database.end();
  });