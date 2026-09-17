# ulisseas/.github

Organization-wide defaults for `ulisseas/*` repositories.

| Path | Purpose |
|---|---|
| `.github/workflows/ci-telemetry.yml` | Reusable workflow: exports a run's spans to Honeycomb and Grafana Cloud Traces and pushes two CI metrics to Grafana Cloud Metrics. Called as the last job of each repo's workflow. |
| `workflow-templates/` | Starter workflow offered under **Actions → New workflow** in every org repo, with the telemetry job pre-wired. |
| `profile/README.md` | The organization profile shown at github.com/ulisseas. |

The credentials the reusable workflow reads (`HONEYCOMB_INGEST_KEY`, `GRAFANA_OTLP_TOKEN` and the `GRAFANA_OTLP_*` / `HONEYCOMB_DATASET` variables) are org-level Actions secrets and variables written by the private `portfolio-infra` repository's bootstrap. Public repos in this org inherit them; nothing needs to be configured per repo.

Adding a repo: create it in the org, pick the **CI with telemetry** template or add the `telemetry` job from it to an existing workflow. See `portfolio-infra/docs/ONBOARDING.md` for the alerting and dashboard side.
