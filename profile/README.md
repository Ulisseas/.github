# Ulisseas

Portfolio projects by the Ulisseas consulting practice: DevOps, platform engineering and Kubernetes work, published as working repositories rather than slides.

- Site: [neillshazly.com](https://neillshazly.com)
- Site status: [uptime and TLS](https://grafana.ulisseas.com/public-dashboards/dc3e15c21b8a4b2487cdf1dbab08dd64)
- CI health across these repos: [dashboard](https://grafana.ulisseas.com/public-dashboards/9c7fd71e4e3d497f8e3be636275dc4a2)

Every repository here reports its GitHub Actions runs as OpenTelemetry traces through the shared [`ci-telemetry`](https://github.com/ulisseas/.github/blob/main/.github/workflows/ci-telemetry.yml) workflow. New repositories start from the org's workflow templates and inherit the telemetry credentials automatically.
