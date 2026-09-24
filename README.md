# ulisseas/.github

Organization-wide defaults for `ulisseas/*` repositories.

| Path | Purpose |
|---|---|
| `.github/workflows/ci-telemetry.yml` | Reusable workflow: exports a run's spans to Honeycomb and Grafana Cloud Traces and pushes CI metrics to Grafana Cloud Metrics (`ci_workflow_duration_seconds`, `ci_workflow_result`, labelled `repo`, `workflow`, `branch`, `event` (the trigger: `push`, `pull_request`, `workflow_dispatch`, `schedule`, …), `conclusion`, `version`, `deployed_version`; and, for deploys, `ci_deploy_lead_time_seconds`). Called from each repo's `telemetry.yml` on `workflow_run: completed`, so the exported run is already concluded. |
| `workflow-templates/` | Two starter workflows offered under **Actions → New workflow** in every org repo: `CI` (build) and `Telemetry export` (fires when CI completes and calls the reusable workflow). |
| `profile/README.md` | The organization profile shown at github.com/ulisseas. |

Every exported run carries two version labels on its metrics and sets `service.version` on its spans: `version` is the release tag pointing exactly at the run's commit (empty if untagged), and `deployed_version` is what a deploy run actually shipped, read from a one-line artifact named `deployed-version` if the run uploaded one. They differ on a rollback. Repos that tag releases get `version` for free; only deploying workflows need to upload the artifact.

A deploy run (conclusion `success` with a non-empty `deployed_version`) also emits `ci_deploy_lead_time_seconds`, the DORA lead time for changes: run completion time minus the head commit's timestamp, labelled `repo`, `workflow`, `branch`, `deployed_version`. It is a lower bound when a release bundles several commits, since only the newest commit's time is used.

The credentials the reusable workflow reads (`HONEYCOMB_INGEST_KEY`, `GRAFANA_OTLP_TOKEN` and the `GRAFANA_OTLP_*` / `HONEYCOMB_DATASET` variables) are org-level Actions secrets and variables written by the private `portfolio-infra` repository's bootstrap. Public repos in this org inherit them; nothing needs to be configured per repo.

Adding a repo: create it in the org, add the **Telemetry export** template and list the repo's workflow display names under `workflow_run.workflows`. See `portfolio-infra/docs/ONBOARDING.md` for the alerting and dashboard side.
