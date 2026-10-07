import { loadConfig } from "./config.ts";
import { createPool, PostgresReadDatabase } from "./data/database.ts";
import { PostgresDevelopmentDataSource } from "./data/postgres-development-data-source.ts";
import { buildApp } from "./app.ts";
import { GroupStudentDataSource } from "./data/group-student-data-source.ts";
import { GroupTeacherDataSource } from "./data/group-teacher-data-source.ts";
import {
  PostgresAppDatabase,
  PostgresInnovationStore,
} from "./data/innovation-store.ts";
import type { FastifyInstance } from "fastify";

let pool: ReturnType<typeof createPool> | undefined;
let app: FastifyInstance | undefined;
try {
  const config = loadConfig();
  pool = createPool(config.databaseUrl, config.databaseModel, () => {
    app?.log.error(
      { event: "database_pool_unavailable" },
      "database_pool_unavailable",
    );
  });
  const database = new PostgresReadDatabase(pool);
  const group = config.databaseModel === "group_39_20";
  const source = group
    ? new GroupStudentDataSource(database)
    : new PostgresDevelopmentDataSource(database);
  app = await buildApp(
    config,
    source,
    true,
    group ? new GroupTeacherDataSource(database) : undefined,
    group
      ? new PostgresInnovationStore(new PostgresAppDatabase(pool))
      : undefined,
  );
  app.log.info(
    {
      event: "startup_configuration_validated",
      environment: config.environment,
      databaseModel: config.databaseModel,
    },
    "startup_configuration_validated",
  );
  app.addHook("onClose", async () => {
    await pool?.end();
  });
  let shuttingDown = false;
  const shutdown = () => {
    if (shuttingDown) return;
    shuttingDown = true;
    void app!.close().catch(() => {
      app!.log.error({ event: "shutdown_failed" }, "shutdown_failed");
      process.exitCode = 1;
    });
  };
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
  await app.ready();
  await source.health();
  app.log.info(
    {
      event: "startup_readiness_verified",
      database: "reachable",
      application: "ready",
      routes: "registered",
    },
    "startup_readiness_verified",
  );
  await app.listen({ host: config.host, port: config.port });
} catch {
  const failure = {
    event: "startup_failed",
    code: "STARTUP_CONFIGURATION_OR_SERVICE_ERROR",
  };
  if (app) app.log.error(failure, "startup_failed");
  else {
    // Configuration can fail before Fastify/Pino exists. Bootstrap emits the same
    // fixed structured status, never an exception/environment representation.
    process.stderr.write(
      JSON.stringify({
        level: 50,
        service: "dlu-lms-support-api",
        ...failure,
      }) + "\n",
    );
  }
  await pool?.end().catch(() => {});
  process.exitCode = 1;
}
