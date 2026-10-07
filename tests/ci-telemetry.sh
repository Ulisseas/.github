#!/usr/bin/env bash
# Runs the `event` and `status_push` steps of ci-telemetry.yml against canned
# API responses, with stub `gh` and `curl` first on PATH. Needs bash, jq and
# yq (mikefarah v4; preinstalled on GitHub's ubuntu runners).
#   bash tests/ci-telemetry.sh [path/to/ci-telemetry.yml]
set -euo pipefail
wf="${1:-.github/workflows/ci-telemetry.yml}"
wf=$(realpath "$wf")  # the steps run from a temp dir
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
yq '.jobs.export.steps[] | select(.id == "event") | .run' "$wf" > "$tmp/event.sh"
yq '.jobs.export.steps[] | select(.id == "status_push") | .run' "$wf" > "$tmp/push.sh"
[ -s "$tmp/event.sh" ] && [ "$(cat "$tmp/event.sh")" != "null" ] || { echo "FAIL no step with id: event"; exit 1; }
[ -s "$tmp/push.sh" ] && [ "$(cat "$tmp/push.sh")" != "null" ] || { echo "FAIL no step with id: status_push"; exit 1; }
cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
# gh api <path> --jq <filter>: apply the filter to the canned run.
jq "${@: -1}" "$FAKE_RUN"
EOF
cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
# Save the --data body and answer HTTP 200.
while [ $# -gt 0 ]; do [ "$1" = "--data" ] && printf '%s' "$2" > "$CURL_BODY"; shift; done
printf 200
EOF
chmod +x "$tmp/bin/gh" "$tmp/bin/curl"
cd "$tmp"  # the steps write state.json into the cwd
export PATH="$tmp/bin:$PATH" GITHUB_REPOSITORY=ulisseas/example RUN_ID=18234567890

fail=0
fake_run() { # <status> <conclusion|null>
  local c=null; [ "$2" = null ] || c="\"$2\""
  printf '{"name":"CI","event":"push","head_branch":"main","status":"%s","conclusion":%s}' "$1" "$c" > "$tmp/run.json"
}
check() { # <action> <status> <conclusion|null> <want code> <want completed>
  fake_run "$2" "$3"; : > "$tmp/out"
  FAKE_RUN="$tmp/run.json" ACTION="$1" GITHUB_OUTPUT="$tmp/out" bash -eo pipefail "$tmp/event.sh" > /dev/null
  local got="$(sed -n 's/^code=//p' "$tmp/out")/$(sed -n 's/^completed=//p' "$tmp/out")"
  if [ "$got" = "$4/$5" ]; then echo "ok   ${1:-<none>} $2 $3 -> $got"
  else echo "FAIL ${1:-<none>} $2 $3 -> $got, want $4/$5"; fail=1; fi
}
check requested   queued      null            2 false
check requested   waiting     null            2 false
check in_progress in_progress null            3 false
check requested   completed   success         1 false  # late export: final state, no run metrics
check completed   completed   success         1 true
check completed   completed   failure         6 true
check completed   completed   timed_out       6 true
check completed   completed   startup_failure 6 true
check completed   completed   cancelled       4 true
check completed   completed   neutral         5 true
check ""          completed   success         1 true   # not a workflow_run caller: v1.0 behaviour

# A completed event for a run the API still reports in progress is an error.
fake_run in_progress null
if FAKE_RUN="$tmp/run.json" ACTION=completed GITHUB_OUTPUT="$tmp/out" bash -eo pipefail "$tmp/event.sh" > /dev/null 2>&1; then
  echo "FAIL completed event on an in-progress run must fail"; fail=1
else echo "ok   completed event on an in-progress run fails"; fi

# The status push sends both gauges with the run's labels.
CURL_BODY="$tmp/body.json" ENDPOINT=https://otlp.invalid AUTH=x REPO=ulisseas/example WORKFLOW=CI \
  BRANCH=main EVENT=push STATUS=in_progress CONCLUSION= CODE=3 bash -eo pipefail "$tmp/push.sh" > /dev/null
m='.resourceMetrics[0].scopeMetrics[0].metrics'
names=$(jq -c "[$m[].name]" "$tmp/body.json")
values=$(jq -c "[$m[].gauge.dataPoints[0].asDouble]" "$tmp/body.json")
keys=$(jq -c "[$m[0].gauge.dataPoints[0].attributes[].key]" "$tmp/body.json")
[ "$names" = '["ci_workflow_status","ci_workflow_run_id"]' ] && echo "ok   metric names" || { echo "FAIL metric names $names"; fail=1; }
[ "$values" = '[3,18234567890]' ] && echo "ok   values" || { echo "FAIL values $values"; fail=1; }
[ "$keys" = '["repo","workflow","branch","event","status","conclusion"]' ] && echo "ok   labels" || { echo "FAIL labels $keys"; fail=1; }

# Only the completed-only steps are gated on the completed event, and the live
# push must not block them when it fails.
gated=$(yq -o=json -I=0 '[.jobs.export.steps[] | select(.if == "steps.event.outputs.completed == '"'"'true'"'"'") | .name]' "$wf")
want='["Resolve run metadata and versions","Export trace to Honeycomb","Export trace to Grafana Cloud Traces","Push CI metrics to Grafana Cloud Metrics"]'
[ "$gated" = "$want" ] && echo "ok   exactly the four completed-only steps are gated" || { echo "FAIL gated steps $gated"; fail=1; }
coe=$(yq '.jobs.export.steps[] | select(.id == "status_push") | .continue-on-error' "$wf")
[ "$coe" = true ] && echo "ok   status_push continues on error" || { echo "FAIL status_push continue-on-error: $coe"; fail=1; }
exit $fail
