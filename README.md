# App Studio runner image

This repository builds the common container image used by the App Studio
Actions Runner Controller scale sets.

The image deliberately contains only fleet-wide tooling:

- GitHub Actions Runner 2.337.0
- Node.js 22.23.2 and 24.20.0 in `RUNNER_TOOL_CACHE`
- Bun 1.4.2 on `PATH`, plus Bun 1.4.0 for repositories not yet upgraded

Application dependencies do not belong in this image. Each repository remains
responsible for installing its dependencies from its lockfile.

## Published image

Merges to `main` publish:

```text
ghcr.io/appstuio/runner:latest
ghcr.io/appstuio/runner:sha-<short commit>
```

Deploy an immutable digest in ARC after validating the published image. Both
`byo` and `byo-large` use this same runner image; only the large scale set adds
the Docker-in-Docker sidecar.

The checked-in [ARC deployment values](deploy/README.md) are the source of
truth for the two scale sets.

## Private GHCR access

Publishing uses this repository's `GITHUB_TOKEN`. For a private package, create
a read-only Kubernetes pull secret in `arc-runners` and reference it from both
scale-set pod templates:

See the deployment guide for the history-safe secret creation and Helm upgrade
commands.

Never commit registry credentials or other secrets to this repository or bake
them into the image.
