import fs from 'node:fs/promises';
import path from 'node:path';
import { database } from './connection.js';

export async function executarSeeds(): Promise<void> {
    await database.query(`
    CREATE TABLE IF NOT EXISTS schema_seeds (
      arquivo VARCHAR(255) PRIMARY KEY,
      executado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);

    const seedsDirectory = path.resolve(
        process.cwd(),
        'database',
        'seeds',
    );

    const arquivos = (await fs.readdir(seedsDirectory))
        .filter((arquivo) => arquivo.endsWith('.sql'))
        .sort();

    for (const arquivo of arquivos) {
        const seedExecutado = await database.query(
            `
        SELECT arquivo
        FROM schema_seeds
        WHERE arquivo = $1
      `,
            [arquivo],
        );

        if (seedExecutado.rowCount) {
            console.log(`Seed já executado: ${arquivo}`);
            continue;
        }

        const caminho = path.join(seedsDirectory, arquivo);
        const sql = await fs.readFile(caminho, 'utf8');

        const client = await database.connect();

        try {
            await client.query(sql);

            await client.query(
                `
          INSERT INTO schema_seeds (arquivo)
          VALUES ($1)
        `,
                [arquivo],
            );

            console.log(`Seed executado: ${arquivo}`);
        } catch (error) {
            console.error(`Erro no seed ${arquivo}:`, error);
            throw error;
        } finally {
            client.release();
        }
    }
}

if (process.argv[1]?.endsWith('seed.ts') || process.argv[1]?.endsWith('seed.js')) {
    executarSeeds()
        .catch((error) => {
            console.error('Falha ao executar seeds:', error);
            process.exitCode = 1;
        })
        .finally(async () => {
            await database.end();
        });
}