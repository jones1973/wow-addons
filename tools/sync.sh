#!/bin/bash
# tools/sync.sh
# One-way sync: shared/ -> each addon's directories
#
# Presence-based: only updates files that already exist in the addon.
# To add a shared file to an addon, copy it in manually once.
# After that, sync keeps it current.
#
# Usage:
#   ./tools/sync.sh          # sync all addons
#   ./tools/sync.sh --check  # dry run, exit 1 if anything is stale

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED_CORE="$REPO_ROOT/shared/core"
SHARED_UI="$REPO_ROOT/shared/ui"
ADDONS_DIR="$REPO_ROOT/addons"

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=true
fi

# Counters (use temp file to avoid subshell scoping)
counter_file=$(mktemp)
echo "0 0" > "$counter_file"
trap "rm -f '$counter_file'" EXIT

sync_file() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if [[ ! -f "$dst" ]]; then
        return
    fi

    if cmp -s "$src" "$dst"; then
        return
    fi

    read -r updated stale < "$counter_file"

    if $CHECK_ONLY; then
        echo "STALE: $label"
        echo "$updated $((stale + 1))" > "$counter_file"
    else
        cp "$src" "$dst"
        echo "sync: $label (updated)"
        echo "$((updated + 1)) $stale" > "$counter_file"
    fi
}

for addon_dir in "$ADDONS_DIR"/*/; do
    [[ -d "$addon_dir" ]] || continue
    addon_name="$(basename "$addon_dir")"

    # shared/core/ -> addon/core/
    if [[ -d "$SHARED_CORE" ]]; then
        while IFS= read -r src; do
            rel="${src#$SHARED_CORE/}"
            dst="${addon_dir}core/$rel"
            sync_file "$src" "$dst" "shared/core/$rel -> $addon_name/core/$rel"
        done < <(find "$SHARED_CORE" -name '*.lua' | sort)
    fi

    # shared/ui/ -> addon/ui/shared/
    if [[ -d "$SHARED_UI" ]]; then
        while IFS= read -r src; do
            rel="${src#$SHARED_UI/}"
            dst="${addon_dir}ui/shared/$rel"
            sync_file "$src" "$dst" "shared/ui/$rel -> $addon_name/ui/shared/$rel"
        done < <(find "$SHARED_UI" -name '*.lua' | sort)
    fi
done

read -r updated stale < "$counter_file"

if $CHECK_ONLY; then
    if [[ $stale -gt 0 ]]; then
        echo ""
        echo "$stale file(s) out of sync. Run ./tools/sync.sh to update."
        exit 1
    else
        echo "All shared files in sync."
        exit 0
    fi
else
    echo ""
    echo "$updated file(s) updated."
fi
