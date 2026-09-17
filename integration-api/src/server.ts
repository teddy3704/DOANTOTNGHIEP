import { loadConfig } from "./config.ts";
import { createPool, PostgresReadDatabase } from "./data/database.ts";
import { PostgresDevelopmentDataSource } from "./data/postgres-development-data-source.ts";
import { buildApp } from "./app.ts";

let pool: ReturnType<typeof createPool> | undefined;
try {
  const config = loadConfig();
  pool = createPool(config.databaseUrl);
  const app = await buildApp(
    config,
    new PostgresDevelopmentDataSource(new PostgresReadDatabase(pool)),
  );
  app.addHook("onClose", async () => {
    await pool?.end();
  });
  const shutdown = async () => {
    await app.close();
  };
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
  await app.listen({ host: config.host, port: config.port });
} catch {
  console.error(
    JSON.stringify({
      event: "startup_failed",
      code: "STARTUP_CONFIGURATION_OR_SERVICE_ERROR",
    }),
  );
  await pool?.end();
  process.exitCode = 1;
}
