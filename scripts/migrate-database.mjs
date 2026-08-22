import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';

const requireFromN8n = createRequire('/usr/local/lib/node_modules/n8n/package.json');
const { Client } = requireFromN8n('pg');

const schema = 'automation_os';
const migrationsDirectory = '/opt/shopify-automation/database/migrations';

const requiredEnvironment = [
  'PGHOST',
  'PGPORT',
  'PGDATABASE',
  'PGUSER',
  'PGPASSWORD',
  'SHOPIFY_STORE_DOMAIN',
  'SHOPIFY_STORE_NAME',
];

for (const key of requiredEnvironment) {
  if (!process.env[key]) throw new Error(`Required environment variable ${key} is missing`);
}

const client = new Client({
  host: process.env.PGHOST,
  port: Number(process.env.PGPORT),
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  ssl: process.env.PGSSLMODE === 'require' ? { rejectUnauthorized: false } : false,
  application_name: 'shopify-automation-os-migrator',
  connectionTimeoutMillis: 15000,
  statement_timeout: 120000,
});

const checksum = (contents) => crypto.createHash('sha256').update(contents).digest('hex');

async function applyMigrations() {
  await client.connect();
  await client.query("SELECT pg_advisory_lock(hashtext('shopify_automation_os_migrations'))");

  try {
    await client.query(`CREATE SCHEMA IF NOT EXISTS ${schema}`);
    await client.query(`
      CREATE TABLE IF NOT EXISTS ${schema}.schema_migrations (
        version text PRIMARY KEY,
        filename text NOT NULL,
        checksum_sha256 text NOT NULL,
        applied_at timestamptz NOT NULL DEFAULT now()
      )
    `);

    const files = (await fs.readdir(migrationsDirectory))
      .filter((file) => /^\d+_.+\.sql$/.test(file))
      .sort();

    for (const filename of files) {
      const version = filename.split('_', 1)[0];
      const sql = await fs.readFile(path.join(migrationsDirectory, filename), 'utf8');
      const digest = checksum(sql);
      const existing = await client.query(
        `SELECT filename, checksum_sha256 FROM ${schema}.schema_migrations WHERE version = $1`,
        [version],
      );

      if (existing.rowCount === 1) {
        if (existing.rows[0].filename !== filename || existing.rows[0].checksum_sha256 !== digest) {
          throw new Error(`Applied migration ${version} does not match repository checksum`);
        }
        console.log(`Skipping verified migration ${filename}`);
        continue;
      }

      console.log(`Applying migration ${filename}`);
      await client.query('BEGIN');
      try {
        await client.query(`SET LOCAL search_path TO ${schema}, public`);
        await client.query(sql);
        await client.query(
          `INSERT INTO ${schema}.schema_migrations (version, filename, checksum_sha256) VALUES ($1, $2, $3)`,
          [version, filename, digest],
        );
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      }
    }

    await client.query('BEGIN');
    try {
      await client.query(`SET LOCAL search_path TO ${schema}, public`);
      const storeResult = await client.query(
        `INSERT INTO stores (shop_domain, display_name, currency_code, timezone, active)
         VALUES ($1, $2, 'USD', 'America/Los_Angeles', true)
         ON CONFLICT (shop_domain) DO UPDATE
         SET display_name = EXCLUDED.display_name, updated_at = now()
         RETURNING id`,
        [process.env.SHOPIFY_STORE_DOMAIN, process.env.SHOPIFY_STORE_NAME],
      );
      await client.query(
        `INSERT INTO suppliers (store_id, supplier_type, external_account_id, name, status)
         VALUES ($1, 'CJ_DROPSHIPPING', $2, 'CJdropshipping', 'ACTIVE')
         ON CONFLICT (store_id, supplier_type, external_account_id) DO UPDATE
         SET name = EXCLUDED.name, status = EXCLUDED.status, updated_at = now()`,
        [storeResult.rows[0].id, process.env.CJ_ACCOUNT_ID || 'CJ5748386'],
      );
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }

    const verification = await client.query(
      `SELECT
         (SELECT count(*)::int FROM ${schema}.schema_migrations) AS migration_count,
         (SELECT count(*)::int FROM ${schema}.stores) AS store_count,
         (SELECT count(*)::int FROM ${schema}.knowledge_categories) AS category_count`,
    );
    console.log(`Database foundation verified: ${JSON.stringify(verification.rows[0])}`);
  } finally {
    await client.query("SELECT pg_advisory_unlock(hashtext('shopify_automation_os_migrations'))").catch(() => {});
    await client.end();
  }
}

applyMigrations().catch((error) => {
  console.error(`Database migration failed: ${error.message}`);
  process.exit(1);
});
