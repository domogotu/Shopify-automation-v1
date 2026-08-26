const express = require("express");
const cors = require("cors");
const { requireOwner } = require("./auth");
const { close, safeQuery } = require("./db");

const app = express();
const port = Number(process.env.PORT || 10000);
const allowedOrigins = new Set(
  String(process.env.ALLOWED_ORIGINS || "https://reeds-ledger-control-app.onrender.com")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean),
);
if (process.env.NODE_ENV !== "production") {
  allowedOrigins.add("http://localhost:8080");
  allowedOrigins.add("http://127.0.0.1:8080");
}

app.disable("x-powered-by");
app.use((req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("Cache-Control", "no-store");
  next();
});
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.has(origin)) return callback(null, true);
    return callback(new Error("ORIGIN_NOT_ALLOWED"));
  },
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "X-Owner-Passphrase"],
  maxAge: 600,
}));
app.use(express.json({ limit: "64kb" }));

const rateBuckets = new Map();
function rateLimit(req, res, next) {
  const key = req.ip || "unknown";
  const now = Date.now();
  const current = rateBuckets.get(key);
  if (!current || current.resetAt <= now) {
    rateBuckets.set(key, { count: 1, resetAt: now + 10 * 60 * 1000 });
    return next();
  }
  current.count += 1;
  if (current.count > 60) {
    return res.status(429).json({ ok: false, error: "Too many requests. Try again shortly." });
  }
  return next();
}

app.get("/api/health", (req, res) => {
  res.json({
    ok: true,
    service: "reeds-ledger-control-api",
    configured: {
      database: Boolean(process.env.DATABASE_URL),
      openai: Boolean(process.env.OPENAI_API_KEY),
      ownerAuth: Boolean(process.env.OWNER_PASSPHRASE),
    },
  });
});

app.use("/api", rateLimit, requireOwner);

app.get("/api/status", async (req, res) => {
  const [approvals, memories, decisions, executions, verifications] = await Promise.all([
    safeQuery("SELECT status, count(*)::int AS count FROM approval_requests GROUP BY status"),
    safeQuery("SELECT verification_status AS status, count(*)::int AS count FROM memories GROUP BY verification_status"),
    safeQuery("SELECT decision AS status, count(*)::int AS count FROM policy_decisions GROUP BY decision"),
    safeQuery("SELECT status, count(*)::int AS count FROM tool_executions GROUP BY status"),
    safeQuery("SELECT result AS status, count(*)::int AS count FROM verification_results GROUP BY result"),
  ]);
  res.json({ ok: true, approvals, memories, policyDecisions: decisions, executions, verifications });
});

app.get("/api/approvals", async (req, res) => {
  const result = await safeQuery(`
    SELECT approval_request_id, correlation_id, description, tool_id, destination,
           estimated_cost, records_affected, reversible, verification_method,
           rollback_method, requesting_agent, status, expires_at, created_at
      FROM approval_requests
     WHERE status = 'pending'
     ORDER BY created_at DESC
     LIMIT 100
  `);
  res.json({ ok: true, ...result });
});

app.get("/api/memory", async (req, res) => {
  const result = await safeQuery(`
    SELECT memory_id, memory_type, project_id, subject_entity, fact_or_claim,
           source_id, confidence, sensitivity, valid_from, valid_to,
           verification_status, correlation_id, created_at
      FROM memories
     WHERE sensitivity IS DISTINCT FROM 'SECRET'
     ORDER BY created_at DESC
     LIMIT 100
  `);
  res.json({ ok: true, ...result });
});

app.get("/api/credentials", (req, res) => {
  res.json({
    ok: true,
    credentials: [
      { system: "OpenAI API", location: "Render env / n8n credential", secretReadable: false },
      { system: "Postgres", location: "Render private connection / n8n credential", secretReadable: false },
      { system: "Google Sheets", location: "n8n OAuth credential", secretReadable: false },
      { system: "Google Drive", location: "n8n OAuth credential", secretReadable: false },
      { system: "Gmail", location: "n8n credential", secretReadable: false },
      { system: "Owner passphrase", location: "Render env only", secretReadable: false },
    ],
  });
});

function validateMessages(input) {
  if (!Array.isArray(input) || input.length < 1 || input.length > 30) return null;
  let total = 0;
  const messages = [];
  for (const item of input) {
    if (!item || !["user", "assistant"].includes(item.role) || typeof item.content !== "string") return null;
    const content = item.content.trim();
    if (!content || content.length > 4000) return null;
    total += content.length;
    if (total > 30000) return null;
    messages.push({ role: item.role, content });
  }
  return messages;
}

app.post("/api/chat", async (req, res) => {
  if (!process.env.OPENAI_API_KEY) {
    return res.status(503).json({ ok: false, error: "AI service is not configured." });
  }
  const messages = validateMessages(req.body && req.body.messages);
  if (!messages) {
    return res.status(400).json({ ok: false, error: "Chat messages are invalid or too large." });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: process.env.OPENAI_CHAT_MODEL || "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are the Reeds Ledger owner assistant for Dominique Reed. Give concise, practical answers about the saved Reeds architecture and current control app. Never reveal or request secret values. Never claim an action, database write, workflow run, email, deployment, or approval happened unless verified evidence is included in the conversation. Models advise; deterministic policy gates and Dominique authorize restricted actions. When uncertain, say what evidence is missing.",
          },
          ...messages,
        ],
        temperature: 0.2,
        max_tokens: 700,
      }),
      signal: controller.signal,
    });
    if (!response.ok) {
      console.error("OpenAI request failed", { status: response.status });
      return res.status(502).json({ ok: false, error: "The AI service could not answer right now." });
    }
    const data = await response.json();
    const reply = data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content;
    if (!reply) return res.status(502).json({ ok: false, error: "The AI service returned no answer." });
    return res.json({ ok: true, reply, model: data.model || process.env.OPENAI_CHAT_MODEL });
  } catch (error) {
    console.error("Chat request failed", { name: error.name || "Error" });
    return res.status(502).json({ ok: false, error: "The AI service could not answer right now." });
  } finally {
    clearTimeout(timeout);
  }
});

app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);
  const status = error.message === "ORIGIN_NOT_ALLOWED" ? 403 : 500;
  return res.status(status).json({ ok: false, error: status === 403 ? "Origin is not allowed." : "Request failed." });
});

const server = app.listen(port, "0.0.0.0", () => {
  console.log(`Reeds Ledger control API listening on ${port}`);
});

async function shutdown() {
  server.close(async () => {
    await close();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10000).unref();
}
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
