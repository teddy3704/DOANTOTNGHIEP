import pg from "pg";
import type { QueryResultRow } from "pg";

export function createPool(databaseUrl: string): pg.Pool {
  // Explicit allowlist: URI query options cannot override TLS or session settings.
  let url: URL;
  try {
    url = new URL(databaseUrl);
  } catch {
    throw new Error("CONFIG_DATABASE_INVALID");
  }
  if (
    !["postgres:", "postgresql:"].includes(url.protocol) ||
    !url.hostname.endsWith(".neon.tech") ||
    url.pathname !== "/lms_mobile_learning" ||
    !url.username ||
    !url.password ||
    (url.port && url.port !== "5432")
  ) {
    throw new Error("CONFIG_DATABASE_INVALID");
  }
  let user: string;
  let password: string;
  try {
    user = decodeURIComponent(url.username);
    password = decodeURIComponent(url.password);
  } catch {
    throw new Error("CONFIG_DATABASE_INVALID");
  }
  const pool = new pg.Pool({
    host: url.hostname,
    port: 5432,
    user,
    password,
    database: "lms_mobile_learning",
    ssl: { rejectUnauthorized: true },
    enableChannelBinding: true,
    max: 4,
    idleTimeoutMillis: 10000,
    connectionTimeoutMillis: 15000,
    statement_timeout: 10000,
    query_timeout: 12000,
    application_name: "dlu-student-support-development",
  });
  pool.on("error", () => {
    console.error(JSON.stringify({ event: "database_pool_unavailable" }));
  });
  return pool;
}

export interface ReadDatabase {
  read<T extends QueryResultRow>(
    sql: string,
    values?: readonly unknown[],
  ): Promise<T[]>;
}

export class PostgresReadDatabase implements ReadDatabase {
  private readonly pool: pg.Pool;
  constructor(pool: pg.Pool) {
    this.pool = pool;
  }
  async read<T extends QueryResultRow>(
    sql: string,
    values: readonly unknown[] = [],
  ): Promise<T[]> {
    const client = await this.pool.connect();
    let discard = false;
    try {
      await client.query("BEGIN READ ONLY");
      await client.query("SET LOCAL statement_timeout = '10s'");
      const result = await client.query<T>(sql, [...values]);
      await client.query("COMMIT");
      return result.rows;
    } catch (error) {
      await client.query("ROLLBACK").catch(() => {
        discard = true;
      });
      throw error;
    } finally {
      client.release(discard);
    }
  }
}
