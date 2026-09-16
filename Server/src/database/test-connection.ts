import { database } from './connection.js';

async function testConnection(): Promise<void> {
    try {
        const result = await database.query<{
            banco: string;
            usuario: string;
            versao: string;
            horario: Date;
        }>(`
      SELECT
        current_database() AS banco,
        current_user AS usuario,
        version() AS versao,
        CURRENT_TIMESTAMP AS horario
    `);

        console.log('PostgreSQL conectado com sucesso.');
        console.log(result.rows[0]);
    } catch (error) {
        console.error('Não foi possível conectar ao PostgreSQL.');
        console.error(error);
        process.exitCode = 1;
    } finally {
        await database.end();
    }
}

void testConnection();