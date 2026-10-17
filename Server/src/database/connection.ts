import 'dotenv/config';
import { Pool, type PoolClient, type QueryResultRow } from 'pg';
import { databaseConfig } from '../config/env.js';

export const database = new Pool(databaseConfig(process.env));
database.on('error', () => {
    console.error('Erro inesperado na conexão PostgreSQL.');
});

export async function query<T extends QueryResultRow>(
    sql: string, params: unknown[] = [],
): Promise<T[]> {
    const result = await database.query<T>(sql, params);
    return result.rows;
}

export async function transaction<T>(
    callback: (client: PoolClient) => Promise<T>,
): Promise<T> {
    const client = await database.connect();
    try {
        await client.query('BEGIN');
        const result = await callback(client);
        await client.query('COMMIT');
        return result;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}
