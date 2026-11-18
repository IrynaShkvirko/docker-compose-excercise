const express = require("express");
const crypto = require("crypto");

const app = express();
app.use(express.json());

const urls = new Map(); // code -> { url, hits }
const BASE_URL = process.env.BASE_URL || "http://localhost:3000";

app.post("/shorten", (req, res) => {
  const { url } = req.body || {};
  try { new URL(url); } catch { return res.status(400).json({ error: "valid url required" }); }
  const code = crypto.randomBytes(3).toString("hex");
  urls.set(code, { url, hits: 0 });
  res.status(201).json({ code, short: `${BASE_URL}/${code}` });
});

app.get("/stats", (_req, res) => {
  res.json([...urls].map(([code, v]) => ({ code, ...v })));
});

app.get("/health", (_req, res) => res.json({ status: "ok" }));

app.get("/:code", (req, res) => {
  const entry = urls.get(req.params.code);
  if (!entry) return res.status(404).json({ error: "not found" });
  entry.hits++;
  res.redirect(entry.url);
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`listening on ${port} (${process.env.NODE_ENV || "dev"})`));
