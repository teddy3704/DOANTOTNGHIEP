import pg from "pg";
import type { QueryResultRow } from "pg";

export function createPool(
  databaseUrl: string,
  model: "current_22_10" | "group_39_20" = "current_22_10",
  onUnavailable: () => void = () => {},
): pg.Pool {
  const databaseName =
    model === "group_39_20"
      ? "lms_mobile_learning_candidate"
      : "lms_mobile_learning";
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
    url.pathname !== "/" + databaseName ||
    (model === "group_39_20" &&
      !/^ep-soft-waterfall-b32kjeu0(?:-pooler)?\./.test(url.hostname)) ||
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
    database: databaseName,
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
    // Driver errors include endpoint/credential context. Emit only a fixed event
    // through the caller's structured logger, never the error object itself.
    onUnavailable();
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
