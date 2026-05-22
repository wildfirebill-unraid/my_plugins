#!/bin/bash
# ------------------------------------------------------------
# Orphan / Unused Docker Images Cleaner
# Standalone script — works on Unraid or any Linux with Docker
# ------------------------------------------------------------
# Usage:
#   ./cleanup-orphan-images.sh [options]
#
# Options:
#   --dangling       Remove <none>:<none> images (default: on)
#   --unused         Remove images not used by any container
#   --force          Use 'docker rmi -f'
#   --leave-tagged   Skip images that have a repository:tag
#   --log FILE       Log file path (default: /var/log/orphan-images.log)
#   --dry-run        Only list what would be removed, don't actually remove
#   --help           Show this help
# ------------------------------------------------------------
set -o pipefail

# --- Defaults ---
DO_DANGLING=1
DO_UNUSED=0
DO_FORCE=0
LEAVE_TAGGED=0
LOG_FILE="${LOG_FILE:-/var/log/orphan-images.log}"
DRY_RUN=0

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dangling)     DO_DANGLING=1; shift ;;
    --unused)       DO_UNUSED=1;   shift ;;
    --force)        DO_FORCE=1;    shift ;;
    --leave-tagged) LEAVE_TAGGED=1; shift ;;
    --log)          LOG_FILE="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=1;     shift ;;
    --help|-h)      head -30 "$0" | grep '^#' | sed 's/^# \?//'; exit 0 ;;
    *)              echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Logging ---
log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "${ts} $*" | tee -a "${LOG_FILE}"
}

# --- Dangling ---
cleanup_dangling() {
  local ids
  ids="$(docker images --filter 'dangling=true' -q 2>/dev/null)"
  ids="$(echo "${ids}" | tr -d '[:space:]')"
  [[ -z "${ids}" ]] && { log "No dangling images."; return 0; }

  local count
  count="$(echo "${ids}" | wc -w)"
  log "Found ${count} dangling image(s)."

  local flags=""
  [[ "${DO_FORCE}" -eq 1 ]] && flags="-f"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    for id in ${ids}; do
      log "  [DRY-RUN] Would remove dangling: ${id}"
    done
  else
    local removed=0
    for id in ${ids}; do
      if docker rmi ${flags} "${id}" >> "${LOG_FILE}" 2>&1; then
        log "  Removed dangling: ${id}"
        removed=$((removed + 1))
      fi
    done
    log "Removed ${removed} dangling image(s)."
  fi
}

# --- Unused ---
cleanup_unused() {
  local used_ids
  used_ids="$(docker ps -a --format '{{.ImageID}}' 2>/dev/null | sort -u)"
  local removed=0

  while IFS='|' read -r repo_tag img_id; do
    [[ "${repo_tag}" == "<none>:<none>" ]] && continue
    if [[ "${LEAVE_TAGGED}" -eq 1 ]] && [[ "${repo_tag}" != *"<none>"* ]]; then
      continue
    fi
    if echo "${used_ids}" | grep -qF "${img_id}"; then
      continue
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
      log "  [DRY-RUN] Would remove unused: ${repo_tag} (${img_id})"
    else
      local flags=""
      [[ "${DO_FORCE}" -eq 1 ]] && flags="-f"
      log "  Removing unused: ${repo_tag} (${img_id})"
      if docker rmi ${flags} "${img_id}" >> "${LOG_FILE}" 2>&1; then
        removed=$((removed + 1))
      fi
    fi
  done < <(docker images --format '{{.Repository}}:{{.Tag}}|{{.ID}}' 2>/dev/null)

  if [[ "${removed}" -eq 0 ]] && [[ "${DRY_RUN}" -eq 0 ]]; then
    log "No unused images removed."
  fi
}

# --- Main ---
log "=== Orphan image cleanup started ==="

[[ "${DO_DANGLING}" -eq 1 ]] && cleanup_dangling
[[ "${DO_UNUSED}"    -eq 1 ]] && cleanup_unused

docker builder prune -a -f >> "${LOG_FILE}" 2>&1 || :

log "=== Orphan image cleanup completed ==="
echo ""
