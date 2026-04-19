#!/usr/bin/env bash
# Tests for ~/.routes/routes.json merge behaviour in get_routes.sh

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR_TEST="$(mktemp -d)"

cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

echo "Running test_user_routes_merge..."

# ── helper: source get_routes.sh with a controlled HOME ──────────────────────
load_routes() {
    local fake_home="$1"
    HOME="$fake_home" source "$ROOT_DIR/routing/get_routes.sh"
}

# ── Test 1: no user routes file → repo routes still work ─────────────────────
(
    load_routes "$TMPDIR_TEST"
    out=$(get_address ha-backup 2>/dev/null) || { echo "  [FAIL] no user file: get_address failed"; exit 1; }
    [[ "$out" == *@*:* ]] || { echo "  [FAIL] no user file: unexpected format: $out"; exit 1; }
    echo "  [OK] no user routes file — repo routes available"
)

# ── Test 2: valid user routes file → user route is accessible ────────────────
(
    mkdir -p "$TMPDIR_TEST/valid/.routes"
    cat > "$TMPDIR_TEST/valid/.routes/routes.json" <<'EOF'
{
  "my-custom-host": {
    "username": "user",
    "hostroute": "custom.example.com",
    "reachable_via_tailscale": "no",
    "hosttype": "pc"
  }
}
EOF
    load_routes "$TMPDIR_TEST/valid"
    out=$(get_address my-custom-host 2>/dev/null) || { echo "  [FAIL] valid user file: get_address failed"; exit 1; }
    [[ "$out" == "user@custom.example.com:no" ]] || { echo "  [FAIL] valid user file: unexpected: $out"; exit 1; }
    # Repo routes must still work too
    out2=$(get_address ha-backup 2>/dev/null) || { echo "  [FAIL] valid user file: repo route lost"; exit 1; }
    echo "  [OK] valid user routes file — user and repo routes both available"
)

# ── Test 3: invalid JSON in user file → warning, repo routes still work ──────
(
    mkdir -p "$TMPDIR_TEST/broken/.routes"
    echo "{ this is not valid json }" > "$TMPDIR_TEST/broken/.routes/routes.json"
    warn=$(HOME="$TMPDIR_TEST/broken" source "$ROOT_DIR/routing/get_routes.sh" 2>&1 >/dev/null)
    [[ "$warn" == *"invalid JSON"* ]] || { echo "  [FAIL] broken file: expected warning, got: $warn"; exit 1; }

    load_routes "$TMPDIR_TEST/broken"
    out=$(get_address ha-backup 2>/dev/null) || { echo "  [FAIL] broken file: repo route unavailable after bad user file"; exit 1; }
    [[ "$out" == *@*:* ]] || { echo "  [FAIL] broken file: unexpected format: $out"; exit 1; }
    echo "  [OK] broken user routes file — warning emitted, repo routes still available"
)

# ── Test 4: user route overrides a repo route ─────────────────────────────────
(
    mkdir -p "$TMPDIR_TEST/override/.routes"
    cat > "$TMPDIR_TEST/override/.routes/routes.json" <<'EOF'
{
  "ha-backup": {
    "username": "custom-user",
    "hostroute": "overridden.example.com",
    "reachable_via_tailscale": "no",
    "hosttype": "ha"
  }
}
EOF
    load_routes "$TMPDIR_TEST/override"
    out=$(get_address ha-backup 2>/dev/null) || { echo "  [FAIL] override: get_address failed"; exit 1; }
    [[ "$out" == "custom-user@overridden.example.com:no" ]] || { echo "  [FAIL] override: user route did not take precedence: $out"; exit 1; }
    echo "  [OK] user route overrides repo route correctly"
)

echo "test_user_routes_merge: done"
