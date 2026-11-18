# 03 – Express URL shortener (in-memory)
Run: `npm install && npm start` → http://localhost:3000 (`npm install` also creates package-lock.json for `npm ci`).
Env: `PORT` (3000), `BASE_URL`, `NODE_ENV`.
API: `POST /shorten {"url": "https://..."}`, `GET /:code`, `GET /stats`, `GET /health`.
Practice: npm ci, NODE_ENV=production, non-root `USER node`, build args.
