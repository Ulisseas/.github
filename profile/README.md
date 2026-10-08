# Ulisseas

Portfolio projects by the Ulisseas consulting practice: DevOps, platform engineering and Kubernetes work, published as working repositories rather than slides.

- Site status: [uptime and TLS](https://grafana.ulisseas.com/public-dashboards/dc3e15c21b8a4b2487cdf1dbab08dd64)
- CI Status across these repos: [dashboard](https://grafana.ulisseas.com/public-dashboards/f7115f765ce84b779bd8dbe1240009ab)

Every repository here reports its GitHub Actions runs as OpenTelemetry traces through the shared [`ci-telemetry`](https://github.com/ulisseas/.github/blob/main/.github/workflows/ci-telemetry.yml) workflow. New repositories start from the org's workflow templates and inherit the telemetry credentials automatically.
