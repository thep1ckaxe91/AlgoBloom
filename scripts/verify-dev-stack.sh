#!/usr/bin/env bash
# Self-test script for Issue #31: verifies root docker-compose.yml core dev stack
# (PostgreSQL 16 + migrations/seed, Redis 7, Go Gateway /health, Swagger UI).
set -euo pipefail

cleanup() {
  echo "=== Tearing down verification containers ==="
  docker compose down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "=== 1. Validate docker-compose.yml (default + all profiles) ==="
docker compose config >/dev/null
docker compose --profile full config >/dev/null
echo "OK: docker compose config (default & full profile)"

echo "=== 2. Boot core dev stack (postgres, redis, gateway, swagger-ui) ==="
docker compose up -d --build --wait

echo "=== 3. Verify PostgreSQL 7 tables + seeded data ==="
TABLE_COUNT=$(docker compose exec -T postgres psql -U "${POSTGRES_USER:-algobloom}" -d "${POSTGRES_DB:-algobloom}" -tAc \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';")
echo "PostgreSQL public tables: $TABLE_COUNT"
test "$TABLE_COUNT" -eq 7

SEED_PROBLEMS=$(docker compose exec -T postgres psql -U "${POSTGRES_USER:-algobloom}" -d "${POSTGRES_DB:-algobloom}" -tAc \
  "SELECT count(*) FROM problems WHERE slug='longest-increasing-energy-chain';")
SEED_TAGS=$(docker compose exec -T postgres psql -U "${POSTGRES_USER:-algobloom}" -d "${POSTGRES_DB:-algobloom}" -tAc \
  "SELECT count(*) FROM tags;")
echo "Seeded focal problem: $SEED_PROBLEMS, seeded tags: $SEED_TAGS"
test "$SEED_PROBLEMS" -eq 1
test "$SEED_TAGS" -ge 8

echo "=== 4. Verify Redis 7 PING ==="
PONG=$(docker compose exec -T redis redis-cli ping)
echo "Redis PING: $PONG"
test "$PONG" = "PONG"

echo "=== 5. Verify Gateway GET /health ==="
HEALTH=$(curl -fsS http://localhost:"${GATEWAY_PORT:-8000}"/health)
echo "Gateway /health: $HEALTH"
echo "$HEALTH" | grep -q '"status":"ok"'
echo "$HEALTH" | grep -q '"service":"algobloom-gateway"'

echo "=== 6. Verify Swagger UI HTTP 200 ==="
SWAGGER_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:"${SWAGGER_PORT:-8080}"/)
echo "Swagger UI HTTP status: $SWAGGER_CODE"
test "$SWAGGER_CODE" -eq 200

echo "=== ALL DEV STACK CHECKS PASSED ==="
