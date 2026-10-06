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

let pool: ReturnType<typeof createPool> | undefined;
try {
  const config = loadConfig();
  pool = createPool(config.databaseUrl, config.databaseModel);
  const database = new PostgresReadDatabase(pool);
  const group = config.databaseModel === "group_39_20";
  const app = await buildApp(
    config,
    group
      ? new GroupStudentDataSource(database)
      : new PostgresDevelopmentDataSource(database),
    true,
    group ? new GroupTeacherDataSource(database) : undefined,
    group
      ? new PostgresInnovationStore(new PostgresAppDatabase(pool))
      : undefined,
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
