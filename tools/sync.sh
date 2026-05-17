#!/bin/bash
# tools/sync.sh
# Targeted one-way sync: shared/ -> each addon's directories.
#
# All operations are scoped: callers pass explicit upstream paths.
# Nothing is copied, deleted, or regenerated unless named on the
# command line.
#
# Flags (combinable in one invocation; order delete -> copy -> manifest):
#
#   --files PATH [PATH...]
#       Copy each upstream path to addon-local copies that already
#       exist. Presence-based per addon (no auto-onboarding).
#
#   --delete PATH [PATH...]
#       Remove addon-local copies corresponding to each upstream path.
#
#   --manifests PATH [PATH...]
#       Regenerate the addon-local manifest corresponding to each
#       upstream files.xml template path named. Each is regenerated
#       across all addons that have the corresponding subdirectory.
#
# Sync mappings:
#   shared/core/X -> addons/<addon>/core/shared/X
#   shared/ui/X   -> addons/<addon>/ui/shared/X
#
# Manifest regen produces:
#   - Template <Script> entries kept if the addon-local file exists.
#   - Template <Include> entries kept if the included manifest exists
#     in the addon (preserved at the template author's position; this
#     is the override for "load child before parent" cases).
#   - Auto-emitted <Include> entries for any immediate-child subdir
#     containing files.xml that the template did NOT already list,
#     appended at the END so parent Scripts load before child folders.
#   - If no entries survive AND no subdirs are present, the manifest
#     is removed.
#
# Intended caller: .githooks/post-commit, after a commit touching
# shared/. Manual invocation is supported.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED_DIR="$REPO_ROOT/shared"
ADDONS_DIR="$REPO_ROOT/addons"

# ---- arg parsing ----

files=()
deletes=()
manifests=()

mode=""
for arg in "$@"; do
    case "$arg" in
        --files)     mode="files" ;;
        --delete)    mode="delete" ;;
        --manifests) mode="manifests" ;;
        --*)
            echo "unknown flag: $arg" >&2
            exit 2
            ;;
        *)
            case "$mode" in
                files)     files+=("$arg") ;;
                delete)    deletes+=("$arg") ;;
                manifests) manifests+=("$arg") ;;
                "")
                    echo "stray arg before flag: $arg" >&2
                    exit 2
                    ;;
            esac
            ;;
    esac
done

if [[ ${#files[@]} -eq 0 && ${#deletes[@]} -eq 0 && ${#manifests[@]} -eq 0 ]]; then
    cat <<'EOF' >&2
usage: sync.sh [--files PATH...] [--delete PATH...] [--manifests PATH...]

  --files     PATH...   Copy each upstream path to addons that have it.
  --delete    PATH...   Remove addon-local copies of each path.
  --manifests PATH...   Regenerate the addon-local manifest for each
                        upstream files.xml template path.

Flags are combinable; operations run in order delete -> copy -> manifests.
EOF
    exit 1
fi

# Translate an upstream path (shared/<layer>/<rest>) to its addon-local
# equivalent (<addon_dir>/<layer>/shared/<rest>). Echoes empty if the
# path doesn't match a supported shape (under shared/, layer core or ui).
addon_local_path() {
    local upstream="$1"
    local addon_dir="$2"
    local rel="${upstream#shared/}"
    if [[ "$rel" == "$upstream" ]]; then
        return 0
    fi
    local layer="${rel%%/*}"
    local sub="${rel#*/}"
    if [[ "$layer" != "core" && "$layer" != "ui" ]]; then
        return 0
    fi
    echo "${addon_dir}${layer}/shared/${sub}"
}

# ---- deletes ----

if [[ ${#deletes[@]} -gt 0 ]]; then
    for upstream in "${deletes[@]}"; do
        for addon_dir in "$ADDONS_DIR"/*/; do
            [[ -d "$addon_dir" ]] || continue
            local_path="$(addon_local_path "$upstream" "$addon_dir")"
            [[ -z "$local_path" ]] && continue
            if [[ -f "$local_path" ]]; then
                rm "$local_path"
                echo "removed: ${local_path#$REPO_ROOT/}"
            fi
        done
    done
fi

# ---- copies ----

if [[ ${#files[@]} -gt 0 ]]; then
    for upstream in "${files[@]}"; do
        src="$REPO_ROOT/$upstream"
        if [[ ! -f "$src" ]]; then
            echo "skipped: $upstream (not present upstream)" >&2
            continue
        fi
        for addon_dir in "$ADDONS_DIR"/*/; do
            [[ -d "$addon_dir" ]] || continue
            local_path="$(addon_local_path "$upstream" "$addon_dir")"
            [[ -z "$local_path" ]] && continue
            if [[ -f "$local_path" ]]; then
                if ! cmp -s "$src" "$local_path"; then
                    cp "$src" "$local_path"
                    echo "updated: ${local_path#$REPO_ROOT/}"
                fi
            fi
        done
    done
fi

# ---- manifests ----

# Regenerate the manifest for one addon's directory from an upstream
# template. Two sources of entries:
#   1) Lines from the template (<Script> and <Include>), filtered by
#      presence locally, in template order.
#   2) Auto-emitted <Include> lines for immediate-child subdirs that
#      contain files.xml and weren't covered by template <Include>s,
#      appended at the end.
generate_manifest() {
    local template="$1"
    local target_dir="$2"
    local header_path="$3"
    local output="$target_dir/files.xml"

    [[ -f "$template" ]] || return 0

    local content
    content="<!-- ${header_path} (auto-generated by sync.sh -- do not edit) -->
<Ui>"

    local has_entries=false
    local template_includes=()  # subdir names already covered by template

    # Pass 1: template-driven entries.
    while IFS= read -r line; do
        case "$line" in
            *"<Ui>"*|*"</Ui>"*|*"<?xml"*|*"<!--"*) continue ;;
        esac

        if echo "$line" | grep -q '<Script file='; then
            local filename
            filename=$(echo "$line" | sed -n 's/.*file="\([^"]*\)".*/\1/p')
            local normalized="${filename//\\//}"
            if [[ -f "$target_dir/$normalized" ]]; then
                content="$content
$line"
                has_entries=true
            fi
        elif echo "$line" | grep -q '<Include file='; then
            local inc_path
            inc_path=$(echo "$line" | sed -n 's/.*file="\([^"]*\)".*/\1/p')
            local normalized="${inc_path//\\//}"
            # Include kept iff the referenced manifest exists locally.
            if [[ -f "$target_dir/$normalized" ]]; then
                content="$content
$line"
                has_entries=true
                # Track first path component so auto-Include doesn't dup it.
                local first="${normalized%%/*}"
                template_includes+=("$first")
            fi
        fi
    done < "$template"

    # Pass 2: auto-Include any subdir with files.xml not in template.
    # Sorted for stable output.
    local subdir
    while IFS= read -r subdir; do
        [[ -n "$subdir" ]] || continue
        local name
        name="$(basename "$subdir")"
        local already=false
        local t
        for t in ${template_includes[@]+"${template_includes[@]}"}; do
            if [[ "$t" == "$name" ]]; then
                already=true
                break
            fi
        done
        $already && continue
        content="$content
    <Include file=\"${name}\\files.xml\"/>"
        has_entries=true
    done < <(find "$target_dir" -mindepth 2 -maxdepth 2 -name 'files.xml' \
                 -printf '%h\n' 2>/dev/null | sort)

    content="$content
</Ui>"

    if ! $has_entries; then
        if [[ -f "$output" ]]; then
            rm "$output"
            echo "removed manifest: ${output#$REPO_ROOT/}"
        fi
        return 0
    fi

    if [[ -f "$output" ]] && echo "$content" | cmp -s "$output" -; then
        return 0
    fi

    echo "$content" > "$output"
    echo "manifest: ${output#$REPO_ROOT/}"
    return 0
}

if [[ ${#manifests[@]} -gt 0 ]]; then
    for template_path in "${manifests[@]}"; do
        if [[ "$template_path" != shared/*/files.xml ]]; then
            echo "skipped: $template_path (not an upstream files.xml path)" >&2
            continue
        fi
        rel="${template_path#shared/}"
        layer="${rel%%/*}"
        if [[ "$layer" != "core" && "$layer" != "ui" ]]; then
            echo "skipped: $template_path (unsupported layer)" >&2
            continue
        fi
        # Subpath within layer leading to the manifest's directory.
        # For shared/ui/widgets/files.xml -> sub_dir = widgets
        # For shared/ui/files.xml         -> sub_dir = ""
        rest="${rel#$layer/}"
        if [[ "$rest" == "files.xml" ]]; then
            sub_dir=""
        else
            sub_dir="${rest%/files.xml}"
        fi

        template_full="$REPO_ROOT/$template_path"

        for addon_dir in "$ADDONS_DIR"/*/; do
            [[ -d "$addon_dir" ]] || continue
            addon_name="$(basename "$addon_dir")"
            target_dir="${addon_dir}${layer}/shared"
            [[ -n "$sub_dir" ]] && target_dir="${target_dir}/${sub_dir}"
            [[ -d "$target_dir" ]] || continue

            header_relpath="${addon_name}/${layer}/shared"
            [[ -n "$sub_dir" ]] && header_relpath="${header_relpath}/${sub_dir}"
            header_relpath="${header_relpath}/files.xml"

            generate_manifest "$template_full" "$target_dir" "$header_relpath"
        done
    done
fi

exit 0
