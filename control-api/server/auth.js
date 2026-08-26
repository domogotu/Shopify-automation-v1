const crypto = require("node:crypto");

function constantTimeEqual(actual, expected) {
  const actualBuffer = Buffer.from(String(actual || ""));
  const expectedBuffer = Buffer.from(String(expected || ""));
  if (actualBuffer.length !== expectedBuffer.length) return false;
  return crypto.timingSafeEqual(actualBuffer, expectedBuffer);
}

function requireOwner(req, res, next) {
  const configured = process.env.OWNER_PASSPHRASE;
  if (!configured) {
    return res.status(503).json({ ok: false, error: "Owner authentication is not configured." });
  }
  if (!constantTimeEqual(req.get("X-Owner-Passphrase"), configured)) {
    return res.status(401).json({ ok: false, error: "Owner authentication failed." });
  }
  return next();
}

module.exports = { requireOwner };
