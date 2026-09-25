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

## Versions

The reusable workflow is released with semantic-release (`.github/workflows/release.yml`, config under `release` in `package.json`). Every squash-merged PR title is a conventional commit: `feat:` cuts a minor release, `fix:` a patch, `feat!:` or a `BREAKING CHANGE:` footer a major; `docs:`, `ci:` and `chore:` cut nothing. Each release is a `vX.Y.Z` tag on the merge commit plus a GitHub release with generated notes.

Callers pin a release by its commit SHA, with the version as a comment, like every other action in these repos (`sha_pinning_required` is on):

    uses: ulisseas/.github/.github/workflows/ci-telemetry.yml@<commit sha> # v1.0.0

Dependabot's `github-actions` updates in each caller propose the next release as a PR, so a repo adopts a change when that PR merges and can roll back by reverting it. A change that breaks callers (a renamed input or secret, a removed label) must be released as a new major. Dependabot titles action bumps `fix(deps): …`, so they release on merge; a PR titled `chore:`, `ci:` or `docs:` cuts nothing and ships with the next `fix:` or `feat:`. This repo's own `telemetry.yml` calls the workflow by its local path, so it always exports with its current code.

Adding a repo: create it in the org, add the **Telemetry export** template and list the repo's workflow display names under `workflow_run.workflows`. See `portfolio-infra/docs/ONBOARDING.md` for the alerting and dashboard side.
