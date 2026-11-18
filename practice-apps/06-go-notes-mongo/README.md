# 06 – Go notes API + MongoDB
Run: `go mod tidy && go run .` (needs MongoDB on localhost:27017). `go mod tidy` creates go.sum.
Env: `MONGO_URI` (mongodb://localhost:27017), `MONGO_DB` (notes), `PORT` (8080).
API: `GET/POST /notes`, `DELETE /notes/{id}`, `GET /health`.
Practice: multi-stage build (golang -> distroless/scratch, CGO_ENABLED=0), compare image sizes.
