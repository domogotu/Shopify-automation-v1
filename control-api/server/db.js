const { Pool } = require("pg");

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      max: 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    })
  : null;

async function query(text, values = []) {
  if (!pool) throw new Error("DATABASE_NOT_CONFIGURED");
  return pool.query(text, values);
}

async function safeQuery(text, values = []) {
  try {
    const result = await query(text, values);
    return { available: true, rows: result.rows };
  } catch (error) {
    const missingRelation = error && error.code === "42P01";
    if (!missingRelation && error.message !== "DATABASE_NOT_CONFIGURED") {
      console.error("Database query failed", { code: error.code || "UNKNOWN" });
    }
    return { available: false, rows: [] };
  }
}

async function close() {
  if (pool) await pool.end();
}

module.exports = { close, query, safeQuery };
