import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: "tsx ./prisma/seed.ts",
  },
  datasource: {
    // Plain process.env read (not the `env()` helper) so `prisma generate`
    // and `next build` don't hard-fail in environments where DATABASE_URL
    // isn't set yet (e.g. before the Vercel env var is configured).
    // Actual query execution still needs it, enforced in src/lib/prisma.ts.
    url: process.env.DATABASE_URL,
  },
});
