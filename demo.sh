#!/usr/bin/env bash
#
# Booth driver. One short command per scenario, so you are never typing a long
# path while people are watching.
#
#   ./demo.sh check      preflight
#   ./demo.sh 01         run scenario 01
#   ./demo.sh 05         run scenario 05 against all three connection modes
#   ./demo.sh all        run site.yml
#   ./demo.sh plan       site.yml --check --diff
#   ./demo.sh clean      teardown
#   ./demo.sh list       list the scenarios
#
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

need_env() {
  if [[ -z "${AAP_HOSTNAME:-}" || -z "${AAP_PASSWORD:-}" ]]; then
    cat >&2 <<'MSG'
AAP_HOSTNAME and AAP_PASSWORD must be set. For example:

  export AAP_HOSTNAME=https://aap.example.com
  export AAP_USERNAME=admin
  export AAP_PASSWORD='...'
  export DEMO_PREFIX=TechGenie
MSG
    exit 1
  fi
}

scenario_file() {
  local match
  match=$(find playbooks -maxdepth 1 -name "$1-*.yml" | head -1)
  if [[ -z "$match" ]]; then
    echo "No scenario '$1'. Try ./demo.sh list" >&2
    exit 1
  fi
  echo "$match"
}

case "${1:-list}" in
  list|"")
    echo "Scenarios:"
    for f in playbooks/*.yml; do
      printf '  %-6s %s\n' "$(basename "$f" | cut -d- -f1)" "$(basename "$f" .yml)"
    done
    echo
    echo "  all    site.yml (apply everything)"
    echo "  plan   site.yml --check --diff (change nothing, show what would happen)"
    echo "  clean  teardown.yml"
    ;;

  check)
    need_env
    ansible-playbook playbooks/00-preflight.yml
    ;;

  # Scenario 05 is only interesting as a comparison, so run all three modes.
  05)
    need_env
    for group in aap_local aap_http_direct aap_http_persistent; do
      echo
      echo "──────────────────── $group ────────────────────"
      ansible-playbook playbooks/05-connection-modes.yml -l "$group"
    done
    echo
    echo "Compare the 'Elapsed' line from each run above."
    ;;

  all)
    need_env
    ansible-playbook site.yml "${@:2}"
    ;;

  plan)
    need_env
    ansible-playbook site.yml --check --diff "${@:2}"
    ;;

  clean)
    need_env
    ansible-playbook teardown.yml
    ;;

  *)
    need_env
    ansible-playbook "$(scenario_file "$1")" "${@:2}"
    ;;
esac
