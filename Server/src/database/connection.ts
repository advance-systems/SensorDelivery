import "dotenv/config";
import { Pool, type PoolClient, type QueryResultRow } from "pg";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
    throw new Error("DATABASE_URL não foi configurada.");
}

const isLocalhost = connectionString.includes('localhost') || connectionString.includes('127.0.0.1');
const useSsl = process.env.DATABASE_SSL === 'false'
    ? false
    : (process.env.DATABASE_SSL === 'true' || (process.env.NODE_ENV === 'production' && !isLocalhost));

export const database = new Pool({
    connectionString,
    max: Number(process.env.DB_POOL_MAX ?? 20),
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    ssl: useSsl ? { rejectUnauthorized: false } : undefined,
});

database.on("error", (error) => {
    console.error("Erro inesperado no database PostgreSQL:", error)
});

export async function query<T extends QueryResultRow>(
    sql: string,
    params: unknown[] = [],
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
