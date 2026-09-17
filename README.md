# ulisseas/.github

Organization-wide defaults for `ulisseas/*` repositories.

| Path | Purpose |
|---|---|
| `.github/workflows/ci-telemetry.yml` | Reusable workflow: exports a run's spans to Honeycomb and Grafana Cloud Traces and pushes two CI metrics to Grafana Cloud Metrics. Called from each repo's `telemetry.yml` on `workflow_run: completed`, so the exported run is already concluded. |
| `workflow-templates/` | Two starter workflows offered under **Actions → New workflow** in every org repo: `CI` (build) and `Telemetry export` (fires when CI completes and calls the reusable workflow). |
| `profile/README.md` | The organization profile shown at github.com/ulisseas. |

The credentials the reusable workflow reads (`HONEYCOMB_INGEST_KEY`, `GRAFANA_OTLP_TOKEN` and the `GRAFANA_OTLP_*` / `HONEYCOMB_DATASET` variables) are org-level Actions secrets and variables written by the private `portfolio-infra` repository's bootstrap. Public repos in this org inherit them; nothing needs to be configured per repo.

Adding a repo: create it in the org, add the **Telemetry export** template and list the repo's workflow display names under `workflow_run.workflows`. See `portfolio-infra/docs/ONBOARDING.md` for the alerting and dashboard side.
