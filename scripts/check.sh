#!/usr/bin/env bash
# Local health gate: shell syntax, shellcheck (if present), compose YAML sanity.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> bash -n (syntax)"
for f in entrypoint.sh setup.sh setup-gpg.sh scripts/*.sh docker/warp-terminal/entrypoint.sh; do
  [[ -f "$f" ]] || continue
  bash -n "$f"
  echo "  OK $f"
done

if command -v shellcheck >/dev/null 2>&1; then
  echo "==> shellcheck"
  # SC1091: sourced paths only exist inside the container image
  shellcheck -e SC1091 entrypoint.sh setup.sh setup-gpg.sh scripts/*.sh docker/warp-terminal/entrypoint.sh
else
  echo "==> shellcheck skipped (not installed)"
fi

echo "==> docker-compose.yml YAML"
python3 - <<'PY'
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    # Minimal duplicate-key check without PyYAML
    text = Path("docker-compose.yml").read_text()
    keys = []
    for line in text.splitlines():
        if line and not line[0].isspace() and ":" in line and not line.startswith("#"):
            keys.append(line.split(":", 1)[0].strip())
    dups = {k for k in keys if keys.count(k) > 1}
    if dups:
        print(f"ERROR: duplicate top-level keys: {sorted(dups)}", file=sys.stderr)
        sys.exit(1)
    print("  OK (no PyYAML; top-level keys unique)")
    sys.exit(0)

class UniqueKeyLoader(yaml.SafeLoader):
    pass

def construct_mapping(loader, node, deep=False):
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise ValueError(f"Duplicate key in YAML: {key!r}")
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping

UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping
)

with open("docker-compose.yml", encoding="utf-8") as f:
    data = yaml.load(f, Loader=UniqueKeyLoader)

assert "services" in data, "missing services"
assert "warp-terminal" in data["services"], "missing warp-terminal service"
assert "traefik" in data["services"], "missing traefik service"
assert "secrets" in data["services"]["warp-terminal"], "warp-terminal must declare secrets"
assert "secrets" in data["services"]["traefik"], "traefik must declare secrets (basic auth)"
print("  OK compose structure (unique keys + secrets wired)")
PY

echo "OK: warp-term-container checks passed"
