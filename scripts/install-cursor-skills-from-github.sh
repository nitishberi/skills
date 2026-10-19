#!/usr/bin/env bash
# Install Agent Skills from one or more GitHub repos into Cursor's global
# skill directories so every local Agent chat on this machine can use them.
#
# For Cloud Agent VMs, run `sync` from the environment `install` hook so the
# skills are baked into the environment snapshot (see
# .cursor/cloud-install-skills.sh and .cursor/skill-sources.txt).
#
# Usage:
#   scripts/install-cursor-skills-from-github.sh add <github-url> [--ref REF]
#   scripts/install-cursor-skills-from-github.sh sync
#   scripts/install-cursor-skills-from-github.sh list
#   scripts/install-cursor-skills-from-github.sh remove <github-url|owner/repo>
#
# Env:
#   CURSOR_SKILLS_DIR     default: ~/.cursor/skills
#   CURSOR_SKILL_CACHE    default: ~/.cursor/skill-cache
#   CURSOR_SKILL_SOURCES  default: ~/.cursor/skill-sources.json
#   CURSOR_AGENTS_SKILLS  default: ~/.agents/skills (also populated)
#   REPO_SKILL_SOURCES    default: <repo>/.cursor/skill-sources.txt when found

set -euo pipefail

CURSOR_SKILLS_DIR="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"
CURSOR_SKILL_CACHE="${CURSOR_SKILL_CACHE:-$HOME/.cursor/skill-cache}"
CURSOR_SKILL_SOURCES="${CURSOR_SKILL_SOURCES:-$HOME/.cursor/skill-sources.json}"
CURSOR_AGENTS_SKILLS="${CURSOR_AGENTS_SKILLS:-$HOME/.agents/skills}"
CURSOR_SKILLS_REMOVED="${CURSOR_SKILLS_REMOVED:-$HOME/.cursor/skills-removed}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_SKILL_SOURCES="${REPO_SKILL_SOURCES:-$REPO_ROOT/.cursor/skill-sources.txt}"

die() { echo "error: $*" >&2; exit 1; }
# Status goes to stderr so command substitutions only capture return paths.
info() { echo "$*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

normalize_repo() {
  local raw="$1"
  raw="${raw%%#*}"
  raw="${raw%%\?*}"
  raw="${raw%/}"
  raw="${raw%.git}"

  if [[ "$raw" =~ ^https?://github\.com/([^/]+)/([^/]+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return
  fi
  if [[ "$raw" =~ ^git@github\.com:([^/]+)/([^/]+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return
  fi
  if [[ "$raw" =~ ^github\.com/([^/]+)/([^/]+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return
  fi
  if [[ "$raw" =~ ^([^/]+)/([^/]+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return
  fi
  die "not a GitHub repo reference: $1 (expected https://github.com/owner/repo or owner/repo)"
}

clone_url_for() {
  echo "https://github.com/$1.git"
}

ensure_dirs() {
  mkdir -p "$CURSOR_SKILLS_DIR" "$CURSOR_SKILL_CACHE" "$CURSOR_AGENTS_SKILLS" \
    "$(dirname "$CURSOR_SKILL_SOURCES")" "$CURSOR_SKILLS_REMOVED"
  if [[ ! -f "$CURSOR_SKILL_SOURCES" ]]; then
    echo '{"sources":[]}' >"$CURSOR_SKILL_SOURCES"
  fi
}

json_sources() {
  jq -c '.sources // []' "$CURSOR_SKILL_SOURCES"
}

write_sources() {
  local tmp
  tmp="$(mktemp)"
  printf '%s\n' "$1" | jq -c '{sources: .}' >"$tmp"
  mv "$tmp" "$CURSOR_SKILL_SOURCES"
}

append_repo_sources_file() {
  local slug="$1" ref="$2"
  local line="$slug"
  if [[ -n "$ref" ]]; then
    line="$slug@$ref"
  fi
  mkdir -p "$(dirname "$REPO_SKILL_SOURCES")"
  touch "$REPO_SKILL_SOURCES"
  if grep -qxF "$line" "$REPO_SKILL_SOURCES" 2>/dev/null; then
    return
  fi
  # Drop any older entry for the same slug (different ref).
  if grep -qE "^${slug}(@|$)" "$REPO_SKILL_SOURCES" 2>/dev/null; then
    local filtered
    filtered="$(mktemp)"
    grep -vE "^${slug}(@|$)" "$REPO_SKILL_SOURCES" >"$filtered" || true
    mv "$filtered" "$REPO_SKILL_SOURCES"
  fi
  echo "$line" >>"$REPO_SKILL_SOURCES"
  info "recorded $line in $REPO_SKILL_SOURCES"
}

remove_from_repo_sources_file() {
  local slug="$1"
  [[ -f "$REPO_SKILL_SOURCES" ]] || return 0
  local filtered
  filtered="$(mktemp)"
  grep -vE "^${slug}(@|$)" "$REPO_SKILL_SOURCES" >"$filtered" || true
  mv "$filtered" "$REPO_SKILL_SOURCES"
}

fetch_repo() {
  local slug="$1" ref="${2:-}"
  local cache_dir="$CURSOR_SKILL_CACHE/${slug//\//__}"
  local url
  url="$(clone_url_for "$slug")"

  if [[ -d "$cache_dir/.git" ]]; then
    info "updating cache $cache_dir"
    git -C "$cache_dir" fetch --depth 1 origin "${ref:-HEAD}" 2>/dev/null \
      || git -C "$cache_dir" fetch --depth 1 origin
    if [[ -n "$ref" ]]; then
      git -C "$cache_dir" checkout -q FETCH_HEAD 2>/dev/null \
        || git -C "$cache_dir" checkout -q "$ref"
    else
      git -C "$cache_dir" checkout -q FETCH_HEAD 2>/dev/null \
        || git -C "$cache_dir" pull --ff-only --depth 1
    fi
  else
    info "cloning $url -> $cache_dir"
    rm -rf "$cache_dir"
    mkdir -p "$(dirname "$cache_dir")"
    if [[ -n "$ref" ]]; then
      git clone --depth 1 --branch "$ref" "$url" "$cache_dir" \
        || git clone --depth 1 "$url" "$cache_dir"
      if [[ ! -d "$cache_dir/.git" ]]; then
        die "clone failed for $slug"
      fi
      # If branch clone failed over to default, try checkout.
      git -C "$cache_dir" checkout -q "$ref" 2>/dev/null || true
    else
      git clone --depth 1 "$url" "$cache_dir"
    fi
  fi
  echo "$cache_dir"
}

# Find skill directories: any folder that contains SKILL.md.
# Prefer nested layouts (skills/<bucket>/<name>) and flat layouts.
discover_skills() {
  local root="$1"
  find "$root" \
    -type f -name SKILL.md \
    ! -path '*/.git/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/.cursor/skills/*' \
    -print0 \
    | while IFS= read -r -d '' skill_md; do
        dirname "$skill_md"
      done
}

install_one_skill() {
  local src="$1" name="$2" slug="$3"
  local dest="$CURSOR_SKILLS_DIR/$name"
  local agents_dest="$CURSOR_AGENTS_SKILLS/$name"
  local stamp

  if [[ -e "$dest" || -L "$dest" ]]; then
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$CURSOR_SKILLS_REMOVED/$stamp"
    # Preserve previous install instead of deleting.
    mv "$dest" "$CURSOR_SKILLS_REMOVED/$stamp/$name" 2>/dev/null || true
  fi

  mkdir -p "$CURSOR_SKILLS_DIR"
  cp -a "$src" "$dest"
  # Drop nested .git if a skill folder somehow included one.
  rm -rf "$dest/.git" 2>/dev/null || true

  if [[ -e "$agents_dest" || -L "$agents_dest" ]]; then
    stamp="${stamp:-$(date -u +%Y%m%dT%H%M%SZ)}"
    mkdir -p "$CURSOR_SKILLS_REMOVED/$stamp"
    mv "$agents_dest" "$CURSOR_SKILLS_REMOVED/$stamp/agents-$name" 2>/dev/null || true
  fi
  mkdir -p "$CURSOR_AGENTS_SKILLS"
  cp -a "$src" "$agents_dest"
  rm -rf "$agents_dest/.git" 2>/dev/null || true

  info "installed $name  (from $slug) -> $dest"
}

install_from_checkout() {
  local root="$1" slug="$2"
  local count=0
  local src name

  while IFS= read -r src; do
    [[ -n "$src" ]] || continue
    name="$(basename "$src")"
    # Skip non-skill noise named SKILL.md at repo root docs, if any.
    if [[ ! -f "$src/SKILL.md" ]]; then
      continue
    fi
    install_one_skill "$src" "$name" "$slug"
    count=$((count + 1))
  done < <(discover_skills "$root")

  if [[ "$count" -eq 0 ]]; then
    die "no SKILL.md skills found in $slug"
  fi
  info "installed $count skill(s) from $slug"
}

record_source() {
  local slug="$1" ref="$2"
  local sources updated
  sources="$(json_sources)"
  updated="$(jq -c --arg slug "$slug" --arg ref "$ref" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
    map(select(.slug != $slug))
    + [{
        slug: $slug,
        ref: (if $ref == "" then null else $ref end),
        url: ("https://github.com/" + $slug),
        updatedAt: $now
      }]
    | sort_by(.slug)
  ' <<<"$sources")"
  write_sources "$updated"
  append_repo_sources_file "$slug" "$ref"
}

cmd_add() {
  local raw="${1:-}" ref=""
  shift || true
  [[ -n "$raw" ]] || die "usage: add <github-url> [--ref REF]"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ref)
        ref="${2:-}"
        [[ -n "$ref" ]] || die "--ref needs a value"
        shift 2
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done

  need_cmd git
  need_cmd jq
  ensure_dirs

  local slug cache
  slug="$(normalize_repo "$raw")"
  cache="$(fetch_repo "$slug" "$ref")"
  install_from_checkout "$cache" "$slug"
  record_source "$slug" "$ref"
  info "done. Skills are in $CURSOR_SKILLS_DIR (and $CURSOR_AGENTS_SKILLS)."
  info "Cloud VMs: commit .cursor/skill-sources.txt, then rebuild the Cloud environment so install syncs them into the snapshot."
}

parse_source_line() {
  # Formats: owner/repo  OR  owner/repo@ref  OR  https://github.com/owner/repo
  local line="$1"
  line="${line%%#*}"
  line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [[ -n "$line" ]] || return 1
  local ref=""
  if [[ "$line" == *@* && "$line" != http* ]]; then
    ref="${line##*@}"
    line="${line%@*}"
  fi
  local slug
  slug="$(normalize_repo "$line")"
  printf '%s\t%s\n' "$slug" "$ref"
}

sync_one() {
  local slug="$1" ref="$2"
  local cache
  cache="$(fetch_repo "$slug" "$ref")"
  install_from_checkout "$cache" "$slug"
  record_source "$slug" "$ref"
}

cmd_sync() {
  need_cmd git
  need_cmd jq
  ensure_dirs

  local synced=0
  declare -A seen=()

  # Prefer the repo checklist (shared across Cloud builds), then user registry.
  if [[ -f "$REPO_SKILL_SOURCES" ]]; then
    info "syncing from $REPO_SKILL_SOURCES"
    while IFS= read -r line || [[ -n "$line" ]]; do
      local parsed slug ref
      parsed="$(parse_source_line "$line" || true)"
      [[ -n "$parsed" ]] || continue
      slug="${parsed%%$'\t'*}"
      ref="${parsed#*$'\t'}"
      seen["$slug"]=1
      sync_one "$slug" "$ref"
      synced=$((synced + 1))
    done <"$REPO_SKILL_SOURCES"
  fi

  local sources
  sources="$(json_sources)"
  while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    local slug ref
    slug="$(jq -r '.slug' <<<"$row")"
    ref="$(jq -r '.ref // empty' <<<"$row")"
    [[ -n "$slug" ]] || continue
    if [[ -n "${seen[$slug]:-}" ]]; then
      continue
    fi
    sync_one "$slug" "$ref"
    synced=$((synced + 1))
  done < <(jq -c '.[]' <<<"$sources")

  if [[ "$synced" -eq 0 ]]; then
    info "no skill pack sources yet."
    info "add one with: $0 add https://github.com/owner/skills-repo"
    info "or list URLs in: $REPO_SKILL_SOURCES"
    exit 0
  fi
  info "sync complete ($synced source repo(s)). Skills live in $CURSOR_SKILLS_DIR"
}

cmd_list() {
  ensure_dirs
  info "User registry: $CURSOR_SKILL_SOURCES"
  jq -r '.sources[]? | "- \(.slug)" + (if .ref then "@\(.ref)" else "" end) + "  updated " + (.updatedAt // "?")' \
    "$CURSOR_SKILL_SOURCES" 2>/dev/null || info "(empty)"
  if [[ -f "$REPO_SKILL_SOURCES" ]]; then
    info ""
    info "Repo checklist: $REPO_SKILL_SOURCES"
    grep -vE '^\s*(#|$)' "$REPO_SKILL_SOURCES" || info "(empty)"
  fi
  info ""
  info "Installed under $CURSOR_SKILLS_DIR:"
  if compgen -G "$CURSOR_SKILLS_DIR/*/SKILL.md" >/dev/null; then
    for skill_md in "$CURSOR_SKILLS_DIR"/*/SKILL.md; do
      info "  - $(basename "$(dirname "$skill_md")")"
    done
  else
    info "  (none)"
  fi
}

cmd_remove() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || die "usage: remove <github-url|owner/repo>"
  need_cmd jq
  ensure_dirs
  local slug
  slug="$(normalize_repo "$raw")"

  local sources updated
  sources="$(json_sources)"
  updated="$(jq -c --arg slug "$slug" 'map(select(.slug != $slug))' <<<"$sources")"
  write_sources "$updated"
  remove_from_repo_sources_file "$slug"

  local cache_dir="$CURSOR_SKILL_CACHE/${slug//\//__}"
  if [[ -d "$cache_dir" ]]; then
    local stamp
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$CURSOR_SKILLS_REMOVED/$stamp"
    mv "$cache_dir" "$CURSOR_SKILLS_REMOVED/$stamp/cache-${slug//\//__}"
    info "moved cache aside (not deleted): $CURSOR_SKILLS_REMOVED/$stamp/"
  fi

  info "removed $slug from registries."
  info "Installed skill folders under $CURSOR_SKILLS_DIR were left in place (names may overlap across packs). Re-run sync or remove folders manually if you want them gone."
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    add) cmd_add "$@" ;;
    sync) cmd_sync ;;
    list) cmd_list ;;
    remove) cmd_remove "$@" ;;
    -h|--help|help|"")
      cat <<'EOF'
Install GitHub Agent Skills into Cursor globally.

  add <github-url> [--ref REF]   Fetch skills and install them
  sync                           Re-install every recorded source
  list                           Show sources and installed skills
  remove <github-url|owner/repo> Drop a source from the registries

Install targets:
  ~/.cursor/skills     Cursor (local Agents + Cloud VMs after env install)
  ~/.agents/skills     Agent Skills-compatible harnesses

Cloud: keep URLs in .cursor/skill-sources.txt and run sync from the
environment install hook (.cursor/cloud-install-skills.sh).
EOF
      [[ -n "$cmd" ]] || exit 1
      ;;
    *)
      die "unknown command: $cmd (try: add|sync|list|remove)"
      ;;
  esac
}

main "$@"
